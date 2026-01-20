from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from ..state import AgentState
from ...ontology.schema_generator import DomainOntology, EntitySchema, RelationshipSchema

class OntologyArchitect:
    """
    Generates domain-specific ontologies from clarified user input.
    Creates entity types, relationships, and logical rules dynamically.

    This is "Schema-Last" - the schema emerges from conversation,
    not from predefined templates.
    """

    def __init__(self, model: str = "claude-3-5-sonnet-20241022", use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model=model, temperature=0.4)
            self.parser = JsonOutputParser(pydantic_object=DomainOntology)

            self.prompt = ChatPromptTemplate.from_messages([
                ("system", """You are an ontology architect. Generate a domain-specific ontology.

Based on the user's clarified requirements, create:

1. **Entities**: Core objects/concepts in this domain
   - Type name (e.g., "Supplier", "Task", "Risk")
   - Properties (what data should we track?)
   - Description

2. **Relationships**: How entities connect
   - Source entity type
   - Target entity type
   - Relationship type (e.g., "BLOCKS", "SUPPLIES_TO", "DEPENDS_ON")
   - Properties (e.g., lead_time, cost)

3. **Logic Rules**: Domain-specific constraints
   - "Task B cannot start until Task A completes"
   - "Inventory must maintain 2-week buffer"

Be creative. Don't use generic "Task/Project" unless that's truly the domain.
The ontology should reflect THIS specific problem space.

{format_instructions}
"""),
                ("user", """Original input: {original_input}

Clarifications:
{clarifications}

Generate domain ontology:""")
            ])
        else:
            self.llm = None
            self.parser = None
            self.prompt = None

    async def generate_ontology(self, state: AgentState) -> AgentState:
        """Generate domain ontology from conversation"""

        if self.use_llm and self.llm:
            # Extract clarifications from history
            clarifications = "\n".join([
                f"- {msg.get('clarification', msg.get('content', ''))}"
                for msg in state.conversation_history
                if msg.get("role") == "user"
            ])

            chain = self.prompt | self.llm | self.parser

            result = await chain.ainvoke({
                "original_input": state.user_input,
                "clarifications": clarifications,
                "format_instructions": self.parser.get_format_instructions()
            })

            ontology = result
        else:
            # Generate simple hardcoded ontology for testing
            ontology = {
                "domain": "electronics supply chain",
                "entities": [
                    {
                        "type": "Supplier",
                        "properties": {"name": "str", "lead_time": "int", "cost_per_unit": "float"},
                        "description": "Provider of raw materials or components"
                    },
                    {
                        "type": "Inventory",
                        "properties": {"sku": "str", "quantity": "int", "location": "str"},
                        "description": "Stock of materials or finished goods"
                    },
                    {
                        "type": "Order",
                        "properties": {"order_id": "str", "quantity": "int", "delivery_date": "date"},
                        "description": "Purchase order from supplier or customer"
                    }
                ],
                "relationships": [
                    {
                        "from_entity": "Supplier",
                        "to_entity": "Inventory",
                        "type": "SUPPLIES_TO",
                        "properties": {"lead_time": "int"}
                    },
                    {
                        "from_entity": "Order",
                        "to_entity": "Inventory",
                        "type": "AFFECTS",
                        "properties": {"quantity_change": "int"}
                    }
                ],
                "logic_rules": [
                    "Inventory level must stay above safety stock threshold",
                    "Orders must be placed lead_time days before needed"
                ]
            }

        # Store in state
        state.domain_ontology = ontology

        # Add to conversation
        state.conversation_history.append({
            "role": "assistant",
            "type": "ontology",
            "content": f"Generated domain ontology with {len(ontology['entities'])} entities"
        })

        return state
