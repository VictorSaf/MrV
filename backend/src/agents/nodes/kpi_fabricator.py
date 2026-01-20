from typing import List, Dict, Any, Optional
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field
from ..state import AgentState

class KPI(BaseModel):
    name: str
    description: str
    measurement_method: str  # How to calculate it
    data_source: str  # Where to get data
    target_value: Optional[str] = None
    optimization_direction: str  # "maximize" or "minimize"
    formula: Optional[str] = None  # SQL/Python code if applicable

class KPIFabricator:
    """
    Creates custom KPIs from qualitative user goals.
    Maps subjective intentions to quantifiable proxy metrics.

    Example: "less stressed team" -> "After-hours commit rate", "Sentiment score"
    """

    def __init__(self, model: str = "claude-3-5-sonnet-20241022", use_llm: bool = True):
        self.use_llm = use_llm
        if use_llm:
            self.llm = ChatAnthropic(model=model, temperature=0.5)
            self.parser = JsonOutputParser()

            self.prompt = ChatPromptTemplate.from_messages([
                ("system", """You are a KPI fabrication system. Create measurable metrics from vague goals.

Given a user's qualitative objective and domain ontology, generate 2-4 KPIs.

For each KPI:
1. **Name**: Clear, specific metric name
2. **Description**: What it measures and why it matters
3. **Measurement Method**: Exactly how to calculate it
4. **Data Source**: Where to get the raw data
5. **Formula**: SQL/Python code if applicable (optional)
6. **Optimization Direction**: "maximize" or "minimize"

Be creative with proxy metrics. "Team stress" could be measured by:
- After-hours work patterns
- Sentiment analysis of messages
- Meeting density
- Response time variance

Return a JSON array of KPIs.
"""),
                ("user", """User goal: {user_goal}

Available entities:
{entities}

Generate KPIs:""")
            ])
        else:
            self.llm = None
            self.parser = None
            self.prompt = None

    async def fabricate_kpis(self, state: AgentState) -> AgentState:
        """Generate custom KPIs from user goals"""

        if self.use_llm and self.llm:
            # Extract entities
            entities_desc = "\n".join([
                f"- {e['type']}: {e.get('description', '')}"
                for e in state.domain_ontology.get("entities", [])
            ])

            chain = self.prompt | self.llm | self.parser

            result = await chain.ainvoke({
                "user_goal": state.user_input,
                "entities": entities_desc
            })

            # Store KPIs
            state.kpis = result["kpis"] if isinstance(result, dict) else result
        else:
            # Generate hardcoded KPIs for testing
            state.kpis = [
                {
                    "name": "Team Stress Index",
                    "description": "Measures overall team stress based on work patterns",
                    "measurement_method": "Aggregate of after-hours commits, weekend work, and response times",
                    "data_source": "Git commits, calendar events, communication logs",
                    "optimization_direction": "minimize",
                    "formula": "(after_hours_commits * 0.4 + weekend_commits * 0.3 + avg_response_time * 0.3)"
                },
                {
                    "name": "Team Sentiment Score",
                    "description": "Tracks emotional tone in team communications",
                    "measurement_method": "Sentiment analysis on messages and comments",
                    "data_source": "Chat messages, code review comments, meeting notes",
                    "optimization_direction": "maximize",
                    "target_value": "> 0.7"
                },
                {
                    "name": "Work-Life Balance Indicator",
                    "description": "Measures boundary between work and personal time",
                    "measurement_method": "Ratio of work during business hours vs non-business hours",
                    "data_source": "Activity logs, commit timestamps",
                    "optimization_direction": "maximize"
                }
            ]

        # Add to conversation
        state.conversation_history.append({
            "role": "assistant",
            "type": "kpis",
            "content": f"Created {len(state.kpis)} custom KPIs"
        })

        return state
