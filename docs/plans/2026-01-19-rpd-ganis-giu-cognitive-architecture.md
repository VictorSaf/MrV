# Rpd Ganis GIU - Emergent Cognitive Architecture Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform MrVAgent into a revolutionary "tabula rasa" project management system that generates domain-specific ontologies, logic, and KPIs through natural language interaction, eliminating rigid templates in favor of emergent cognitive architecture.

**Architecture:** Multi-agent council system using LangGraph for cyclic state management, Graphiti/Zep for temporal knowledge graphs, hybrid episodic-semantic memory, and generative UI for dynamic interface adaptation. The system employs Socratic cold-start algorithms, schema-last induction, and metacognitive reasoning to co-create project methodologies with users.

**Tech Stack:** Swift/SwiftUI (existing), LangChain/LangGraph (Python backend), Graphiti/Zep (knowledge graphs), Claude 3.5 Sonnet + Gemini 1.5 Pro (model router pattern), Neo4j/PostgreSQL (hybrid memory), React/Vue (generative UI components)

---

## Phase 1: Foundation & Core Architecture

### Task 1.1: Create Backend Service Architecture

**Files:**
- Create: `backend/src/core/__init__.py`
- Create: `backend/src/core/config.py`
- Create: `backend/requirements.txt`
- Create: `backend/pyproject.toml`

**Step 1: Write the failing test**

```python
# backend/tests/test_config.py
import pytest
from src.core.config import AppConfig

def test_config_loads_environment():
    config = AppConfig()
    assert config.langchain_api_key is not None
    assert config.claude_api_key is not None
    assert config.gemini_api_key is not None
```

**Step 2: Run test to verify it fails**

Run: `cd backend && pytest tests/test_config.py::test_config_loads_environment -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'src.core.config'"

**Step 3: Write minimal implementation**

```python
# backend/src/core/config.py
from pydantic_settings import BaseSettings
from typing import Optional

class AppConfig(BaseSettings):
    langchain_api_key: str
    claude_api_key: str
    gemini_api_key: str
    openai_api_key: Optional[str] = None
    neo4j_uri: str = "bolt://localhost:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: str

    class Config:
        env_file = ".env"
        case_sensitive = False

# backend/requirements.txt
langchain==0.1.0
langchain-core==0.1.0
langgraph==0.0.40
langchain-anthropic==0.1.1
langchain-google-genai==0.0.6
pydantic-settings==2.1.0
neo4j==5.15.0
graphiti-core==0.3.0
fastapi==0.108.0
uvicorn==0.25.0
```

**Step 4: Run test to verify it passes**

Run: `cd backend && pytest tests/test_config.py::test_config_loads_environment -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/core/ backend/requirements.txt backend/tests/
git commit -m "feat: add backend configuration system with environment management

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.2: Implement LangGraph State Machine Foundation

**Files:**
- Create: `backend/src/agents/state.py`
- Create: `backend/src/agents/graph.py`
- Test: `backend/tests/test_graph_state.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_graph_state.py
import pytest
from src.agents.state import AgentState, StateNode
from src.agents.graph import CognitiveGraph

def test_state_transitions():
    graph = CognitiveGraph()
    initial_state = AgentState(
        current_node=StateNode.AMBIGUITY_SCANNER,
        user_input="Help me fix my supply chain",
        ambiguity_score=0.8
    )

    next_node = graph.determine_transition(initial_state)
    assert next_node == StateNode.SOCRATIC_INTERROGATOR
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_graph_state.py::test_state_transitions -v`
Expected: FAIL with "cannot import name 'AgentState'"

**Step 3: Write minimal implementation**

```python
# backend/src/agents/state.py
from enum import Enum
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

class StateNode(str, Enum):
    AMBIGUITY_SCANNER = "ambiguity_scanner"
    SOCRATIC_INTERROGATOR = "socratic_interrogator"
    ONTOLOGY_ARCHITECT = "ontology_architect"
    STRATEGY_MOTOR = "strategy_motor"
    EXECUTOR = "executor"
    REFLECTOR = "reflector"

class AgentState(BaseModel):
    current_node: StateNode
    user_input: str
    conversation_history: List[Dict[str, str]] = Field(default_factory=list)
    ambiguity_score: float = 0.0
    domain_ontology: Optional[Dict[str, Any]] = None
    project_logic: Optional[Dict[str, Any]] = None
    kpis: Optional[List[Dict[str, Any]]] = None
    error_message: Optional[str] = None

# backend/src/agents/graph.py
from typing import Literal
from langgraph.graph import StateGraph, END
from .state import AgentState, StateNode

class CognitiveGraph:
    def __init__(self):
        self.graph = self._build_graph()

    def determine_transition(self, state: AgentState) -> StateNode:
        """Determine next node based on state"""
        if state.current_node == StateNode.AMBIGUITY_SCANNER:
            if state.ambiguity_score > 0.7:
                return StateNode.SOCRATIC_INTERROGATOR
            else:
                return StateNode.ONTOLOGY_ARCHITECT

        elif state.current_node == StateNode.SOCRATIC_INTERROGATOR:
            # After clarification, re-scan
            return StateNode.AMBIGUITY_SCANNER

        elif state.current_node == StateNode.ONTOLOGY_ARCHITECT:
            return StateNode.STRATEGY_MOTOR

        elif state.current_node == StateNode.STRATEGY_MOTOR:
            return StateNode.EXECUTOR

        elif state.current_node == StateNode.EXECUTOR:
            return StateNode.REFLECTOR

        elif state.current_node == StateNode.REFLECTOR:
            # Check if optimization needed
            return StateNode.STRATEGY_MOTOR  # or END

        return END

    def _build_graph(self) -> StateGraph:
        workflow = StateGraph(AgentState)

        # Add nodes (implement in next task)
        workflow.add_node("ambiguity_scanner", self._ambiguity_scanner_node)
        workflow.add_node("socratic_interrogator", self._socratic_interrogator_node)
        workflow.add_node("ontology_architect", self._ontology_architect_node)
        workflow.add_node("strategy_motor", self._strategy_motor_node)
        workflow.add_node("executor", self._executor_node)
        workflow.add_node("reflector", self._reflector_node)

        # Add conditional edges
        workflow.set_entry_point("ambiguity_scanner")

        return workflow.compile()

    # Placeholder node functions (implement in subsequent tasks)
    async def _ambiguity_scanner_node(self, state: AgentState) -> AgentState:
        return state

    async def _socratic_interrogator_node(self, state: AgentState) -> AgentState:
        return state

    async def _ontology_architect_node(self, state: AgentState) -> AgentState:
        return state

    async def _strategy_motor_node(self, state: AgentState) -> AgentState:
        return state

    async def _executor_node(self, state: AgentState) -> AgentState:
        return state

    async def _reflector_node(self, state: AgentState) -> AgentState:
        return state
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_graph_state.py::test_state_transitions -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/ backend/tests/test_graph_state.py
git commit -m "feat: implement LangGraph cyclic state machine foundation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.3: Implement Ambiguity Scanner Node

**Files:**
- Modify: `backend/src/agents/graph.py:39-40`
- Create: `backend/src/agents/nodes/ambiguity_scanner.py`
- Test: `backend/tests/test_ambiguity_scanner.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_ambiguity_scanner.py
import pytest
from src.agents.nodes.ambiguity_scanner import AmbiguityScanner
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_ambiguity_scanner_high_entropy():
    scanner = AmbiguityScanner()
    state = AgentState(
        current_node=StateNode.AMBIGUITY_SCANNER,
        user_input="Help me with my business"
    )

    result = await scanner.analyze(state)
    assert result.ambiguity_score > 0.7
    assert "business" in result.conversation_history[-1]["analysis"]

@pytest.mark.asyncio
async def test_ambiguity_scanner_low_entropy():
    scanner = AmbiguityScanner()
    state = AgentState(
        current_node=StateNode.AMBIGUITY_SCANNER,
        user_input="Create a Gantt chart for construction project starting March 1st with 5 phases"
    )

    result = await scanner.analyze(state)
    assert result.ambiguity_score < 0.5
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_ambiguity_scanner.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'src.agents.nodes.ambiguity_scanner'"

**Step 3: Write minimal implementation**

```python
# backend/src/agents/nodes/ambiguity_scanner.py
from typing import List, Set
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from ..state import AgentState

class AmbiguityScanner:
    """
    Analyzes user input for ambiguity and entropy.
    Calculates ambiguity score based on:
    - Vague terms (e.g., "fix", "improve", "optimize")
    - Missing context (domain, constraints, objectives)
    - Undefined metrics
    """

    VAGUE_TERMS: Set[str] = {
        "fix", "improve", "optimize", "better", "help", "manage",
        "handle", "deal with", "work on", "something", "stuff"
    }

    def __init__(self, model: str = "claude-3-5-sonnet-20241022"):
        self.llm = ChatAnthropic(model=model, temperature=0.3)
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", """You are an ambiguity detection system. Analyze user input and identify:
1. Vague terms lacking specificity
2. Missing domain context
3. Undefined objectives or constraints
4. Unclear success metrics

Return a JSON with:
- ambiguity_factors: list of identified ambiguities
- missing_context: list of missing information
- clarity_score: 0-1 (0=totally ambiguous, 1=crystal clear)
"""),
            ("user", "{input}")
        ])

    async def analyze(self, state: AgentState) -> AgentState:
        """Analyze input and calculate ambiguity score"""

        # Lexical analysis
        lexical_score = self._calculate_lexical_ambiguity(state.user_input)

        # LLM-based semantic analysis
        chain = self.prompt | self.llm
        response = await chain.ainvoke({"input": state.user_input})

        # Parse LLM response (simplified - should use structured output)
        semantic_score = 0.8  # Placeholder

        # Combined ambiguity score
        ambiguity_score = (lexical_score + semantic_score) / 2

        # Update state
        state.ambiguity_score = ambiguity_score
        state.conversation_history.append({
            "role": "system",
            "analysis": f"Ambiguity detected: {ambiguity_score:.2f}",
            "content": response.content
        })

        return state

    def _calculate_lexical_ambiguity(self, text: str) -> float:
        """Calculate ambiguity based on word analysis"""
        words = text.lower().split()
        vague_count = sum(1 for word in words if word in self.VAGUE_TERMS)

        # High vagueness = high ambiguity
        if len(words) == 0:
            return 1.0

        vague_ratio = vague_count / len(words)

        # Short input = higher ambiguity
        length_penalty = max(0, 1 - len(words) / 20)

        return min(1.0, vague_ratio * 2 + length_penalty * 0.5)
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_ambiguity_scanner.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/nodes/ambiguity_scanner.py backend/tests/test_ambiguity_scanner.py
git commit -m "feat: implement ambiguity scanner for entropy analysis

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.4: Implement Socratic Interrogator Node

**Files:**
- Create: `backend/src/agents/nodes/socratic_interrogator.py`
- Test: `backend/tests/test_socratic_interrogator.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_socratic_interrogator.py
import pytest
from src.agents.nodes.socratic_interrogator import SocraticInterrogator
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_generates_clarifying_questions():
    interrogator = SocraticInterrogator()
    state = AgentState(
        current_node=StateNode.SOCRATIC_INTERROGATOR,
        user_input="Help me fix my supply chain",
        ambiguity_score=0.85,
        conversation_history=[]
    )

    result = await interrogator.generate_questions(state)
    questions = result.conversation_history[-1]["questions"]

    assert len(questions) >= 2
    assert any("cost" in q.lower() or "speed" in q.lower() for q in questions)
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_socratic_interrogator.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/agents/nodes/socratic_interrogator.py
from typing import List
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field
from ..state import AgentState

class ClarifyingQuestions(BaseModel):
    questions: List[str] = Field(description="List of clarifying questions")
    reasoning: str = Field(description="Why these questions matter")

class SocraticInterrogator:
    """
    Generates clarifying questions using Socratic method to reduce ambiguity.
    Focuses on:
    - Domain identification
    - Objective clarification
    - Constraint discovery
    - Success criteria definition
    """

    def __init__(self, model: str = "claude-3-5-sonnet-20241022"):
        self.llm = ChatAnthropic(model=model, temperature=0.7)
        self.parser = JsonOutputParser(pydantic_object=ClarifyingQuestions)

        self.prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a Socratic questioner helping users clarify vague project goals.

Generate 2-4 essential questions that will:
1. Identify the specific domain/industry
2. Clarify the primary objective (cost, speed, quality, resilience?)
3. Discover constraints (budget, time, resources)
4. Define success metrics

Use open-ended questions. Avoid yes/no questions.
Be concise and focused.

{format_instructions}
"""),
            ("user", "User input: {input}\n\nAmbiguity score: {ambiguity_score}")
        ])

    async def generate_questions(self, state: AgentState) -> AgentState:
        """Generate clarifying questions based on ambiguous input"""

        chain = self.prompt | self.llm | self.parser

        result = await chain.ainvoke({
            "input": state.user_input,
            "ambiguity_score": state.ambiguity_score,
            "format_instructions": self.parser.get_format_instructions()
        })

        # Add to conversation history
        state.conversation_history.append({
            "role": "assistant",
            "type": "clarification",
            "questions": result["questions"],
            "reasoning": result["reasoning"]
        })

        return state
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_socratic_interrogator.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/nodes/socratic_interrogator.py backend/tests/test_socratic_interrogator.py
git commit -m "feat: implement Socratic interrogator for requirement elicitation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 2: Knowledge Graph & Memory System

### Task 2.1: Setup Neo4j and Graphiti Integration

**Files:**
- Create: `backend/src/memory/graph_store.py`
- Create: `backend/docker-compose.yml`
- Test: `backend/tests/test_graph_store.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_graph_store.py
import pytest
from src.memory.graph_store import TemporalKnowledgeGraph
from datetime import datetime

@pytest.mark.asyncio
async def test_create_entity_relationship():
    graph = TemporalKnowledgeGraph()

    # Create entities
    task_a = await graph.create_entity("Task", {"name": "Task Alpha", "deadline": "2026-02-01"})
    task_b = await graph.create_entity("Task", {"name": "Task Beta", "deadline": "2026-02-15"})

    # Create relationship
    rel = await graph.create_relationship(
        task_a, "BLOCKS", task_b,
        valid_from=datetime.now()
    )

    assert rel is not None
    assert rel["type"] == "BLOCKS"
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_graph_store.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/docker-compose.yml
version: '3.8'

services:
  neo4j:
    image: neo4j:5.15
    ports:
      - "7474:7474"  # HTTP
      - "7687:7687"  # Bolt
    environment:
      - NEO4J_AUTH=neo4j/testpassword
      - NEO4J_PLUGINS=["apoc"]
    volumes:
      - neo4j_data:/data

volumes:
  neo4j_data:

# backend/src/memory/graph_store.py
from typing import Dict, Any, Optional
from datetime import datetime
from neo4j import AsyncGraphDatabase, AsyncDriver
from graphiti_core import Graphiti
from ..core.config import AppConfig

class TemporalKnowledgeGraph:
    """
    Temporal Knowledge Graph using Neo4j + Graphiti.
    Stores project entities with time-aware relationships.
    """

    def __init__(self, config: Optional[AppConfig] = None):
        self.config = config or AppConfig()
        self.driver: Optional[AsyncDriver] = None
        self.graphiti: Optional[Graphiti] = None

    async def connect(self):
        """Initialize connections"""
        self.driver = AsyncGraphDatabase.driver(
            self.config.neo4j_uri,
            auth=(self.config.neo4j_user, self.config.neo4j_password)
        )

        # Initialize Graphiti for temporal operations
        self.graphiti = Graphiti(neo4j_driver=self.driver)

    async def create_entity(
        self,
        entity_type: str,
        properties: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new entity node"""
        async with self.driver.session() as session:
            query = f"""
            CREATE (e:{entity_type})
            SET e = $properties
            SET e.created_at = datetime()
            SET e.id = randomUUID()
            RETURN e
            """
            result = await session.run(query, properties=properties)
            record = await result.single()
            return dict(record["e"])

    async def create_relationship(
        self,
        from_entity: Dict[str, Any],
        rel_type: str,
        to_entity: Dict[str, Any],
        properties: Optional[Dict[str, Any]] = None,
        valid_from: Optional[datetime] = None,
        valid_until: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Create temporal relationship between entities"""
        properties = properties or {}
        properties["valid_from"] = valid_from or datetime.now()
        if valid_until:
            properties["valid_until"] = valid_until

        async with self.driver.session() as session:
            query = f"""
            MATCH (from) WHERE from.id = $from_id
            MATCH (to) WHERE to.id = $to_id
            CREATE (from)-[r:{rel_type}]->(to)
            SET r = $properties
            RETURN r
            """
            result = await session.run(
                query,
                from_id=from_entity["id"],
                to_id=to_entity["id"],
                properties=properties
            )
            record = await result.single()
            return {"type": rel_type, **dict(record["r"])}

    async def query_dependencies(self, entity_id: str) -> list:
        """Find all entities this entity depends on"""
        async with self.driver.session() as session:
            query = """
            MATCH (e)-[r:BLOCKS|DEPENDS_ON]->(dep)
            WHERE e.id = $entity_id
            AND (r.valid_until IS NULL OR r.valid_until > datetime())
            RETURN dep, r
            """
            result = await session.run(query, entity_id=entity_id)
            records = await result.values()
            return records

    async def close(self):
        """Close connections"""
        if self.driver:
            await self.driver.close()
```

**Step 4: Run test to verify it passes**

Run: `docker-compose up -d neo4j && pytest backend/tests/test_graph_store.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/memory/graph_store.py backend/docker-compose.yml backend/tests/test_graph_store.py
git commit -m "feat: implement temporal knowledge graph with Neo4j and Graphiti

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2.2: Implement Hybrid Memory System

**Files:**
- Create: `backend/src/memory/hybrid_memory.py`
- Create: `backend/src/memory/vector_store.py`
- Test: `backend/tests/test_hybrid_memory.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_hybrid_memory.py
import pytest
from src.memory.hybrid_memory import HybridMemory

@pytest.mark.asyncio
async def test_episodic_memory_retrieval():
    memory = HybridMemory()
    await memory.initialize()

    # Store episodic memory (conversation)
    await memory.store_episodic("User asked about supply chain optimization focusing on cost reduction")

    # Retrieve similar episodes
    results = await memory.retrieve_episodic("What did we discuss about supply chain?")

    assert len(results) > 0
    assert "cost reduction" in results[0]["content"].lower()

@pytest.mark.asyncio
async def test_semantic_memory_reasoning():
    memory = HybridMemory()
    await memory.initialize()

    # Store semantic fact
    task_a = await memory.store_semantic_entity("Task", {"name": "Design Phase"})
    task_b = await memory.store_semantic_entity("Task", {"name": "Development Phase"})

    await memory.store_semantic_relationship(task_a, "PRECEDES", task_b)

    # Query causal chain
    chain = await memory.get_causal_chain(task_b["id"])

    assert len(chain) > 0
    assert any("Design Phase" in str(item) for item in chain)
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_hybrid_memory.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/memory/vector_store.py
from typing import List, Dict, Any
from langchain_community.vectorstores import Chroma
from langchain_anthropic import AnthropicEmbeddings
from langchain_core.documents import Document

class EpisodicMemory:
    """Vector-based episodic memory for conversation history"""

    def __init__(self, collection_name: str = "rpd_episodes"):
        self.embeddings = AnthropicEmbeddings()
        self.vectorstore = Chroma(
            collection_name=collection_name,
            embedding_function=self.embeddings,
            persist_directory="./chroma_db"
        )

    async def store(self, content: str, metadata: Optional[Dict] = None):
        """Store episodic memory"""
        doc = Document(page_content=content, metadata=metadata or {})
        await self.vectorstore.aadd_documents([doc])

    async def retrieve(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Retrieve similar episodes"""
        docs = await self.vectorstore.asimilarity_search(query, k=k)
        return [{"content": doc.page_content, "metadata": doc.metadata} for doc in docs]

# backend/src/memory/hybrid_memory.py
from typing import List, Dict, Any, Optional
from .vector_store import EpisodicMemory
from .graph_store import TemporalKnowledgeGraph

class HybridMemory:
    """
    Hybrid memory system combining:
    - Episodic memory (vector DB) for conversation/linguistic nuance
    - Semantic memory (knowledge graph) for structured relationships
    """

    def __init__(self):
        self.episodic = EpisodicMemory()
        self.semantic = TemporalKnowledgeGraph()

    async def initialize(self):
        """Initialize both memory systems"""
        await self.semantic.connect()

    # Episodic operations
    async def store_episodic(self, content: str, metadata: Optional[Dict] = None):
        """Store conversational memory"""
        await self.episodic.store(content, metadata)

    async def retrieve_episodic(self, query: str, k: int = 5) -> List[Dict[str, Any]]:
        """Retrieve similar conversations"""
        return await self.episodic.retrieve(query, k)

    # Semantic operations
    async def store_semantic_entity(self, entity_type: str, properties: Dict) -> Dict:
        """Store structured entity"""
        return await self.semantic.create_entity(entity_type, properties)

    async def store_semantic_relationship(
        self,
        from_entity: Dict,
        rel_type: str,
        to_entity: Dict,
        properties: Optional[Dict] = None
    ) -> Dict:
        """Store structured relationship"""
        return await self.semantic.create_relationship(
            from_entity, rel_type, to_entity, properties
        )

    async def get_causal_chain(self, entity_id: str) -> List[Dict]:
        """Get dependency chain for entity"""
        return await self.semantic.query_dependencies(entity_id)

    async def close(self):
        """Cleanup connections"""
        await self.semantic.close()
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_hybrid_memory.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/memory/ backend/tests/test_hybrid_memory.py
git commit -m "feat: implement hybrid episodic-semantic memory system

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 3: Ontology Generation & Schema Induction

### Task 3.1: Implement Ontology Architect Node

**Files:**
- Create: `backend/src/agents/nodes/ontology_architect.py`
- Create: `backend/src/ontology/schema_generator.py`
- Test: `backend/tests/test_ontology_architect.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_ontology_architect.py
import pytest
from src.agents.nodes.ontology_architect import OntologyArchitect
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_generates_domain_ontology():
    architect = OntologyArchitect()
    state = AgentState(
        current_node=StateNode.ONTOLOGY_ARCHITECT,
        user_input="Optimize supply chain for electronics manufacturing",
        conversation_history=[
            {"role": "user", "clarification": "Focus on cost reduction"},
            {"role": "user", "clarification": "Physical goods, not digital"}
        ]
    )

    result = await architect.generate_ontology(state)
    ontology = result.domain_ontology

    assert ontology is not None
    assert "entities" in ontology
    assert any(e["type"] == "Supplier" for e in ontology["entities"])
    assert any(e["type"] == "Inventory" for e in ontology["entities"])
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_ontology_architect.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/ontology/schema_generator.py
from typing import Dict, Any, List
from pydantic import BaseModel, Field

class EntitySchema(BaseModel):
    type: str
    properties: Dict[str, Any]
    description: str

class RelationshipSchema(BaseModel):
    from_entity: str
    to_entity: str
    type: str
    properties: Dict[str, Any] = Field(default_factory=dict)

class DomainOntology(BaseModel):
    domain: str
    entities: List[EntitySchema]
    relationships: List[RelationshipSchema]
    logic_rules: List[str] = Field(default_factory=list)

# backend/src/agents/nodes/ontology_architect.py
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from ..state import AgentState
from ...ontology.schema_generator import DomainOntology

class OntologyArchitect:
    """
    Generates domain-specific ontologies from clarified user input.
    Creates entity types, relationships, and logical rules dynamically.

    This is "Schema-Last" - the schema emerges from conversation,
    not from predefined templates.
    """

    def __init__(self, model: str = "claude-3-5-sonnet-20241022"):
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

    async def generate_ontology(self, state: AgentState) -> AgentState:
        """Generate domain ontology from conversation"""

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

        # Parse into ontology
        ontology = result

        # Store in state
        state.domain_ontology = ontology

        # Add to conversation
        state.conversation_history.append({
            "role": "assistant",
            "type": "ontology",
            "content": f"Generated domain ontology with {len(ontology['entities'])} entities"
        })

        return state
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_ontology_architect.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/nodes/ontology_architect.py backend/src/ontology/ backend/tests/test_ontology_architect.py
git commit -m "feat: implement dynamic ontology generation via schema induction

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3.2: Implement KPI Fabrication System

**Files:**
- Create: `backend/src/agents/nodes/kpi_fabricator.py`
- Test: `backend/tests/test_kpi_fabricator.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_kpi_fabricator.py
import pytest
from src.agents.nodes.kpi_fabricator import KPIFabricator
from src.agents.state import AgentState

@pytest.mark.asyncio
async def test_fabricates_custom_kpis():
    fabricator = KPIFabricator()
    state = AgentState(
        user_input="I want the team to be less stressed",
        domain_ontology={
            "entities": [
                {"type": "Task", "properties": {"status": "str", "assignee": "str"}}
            ]
        }
    )

    result = await fabricator.fabricate_kpis(state)
    kpis = result.kpis

    assert len(kpis) > 0
    assert any("stress" in kpi["name"].lower() or "sentiment" in kpi["name"].lower() for kpi in kpis)
    assert all("measurement_method" in kpi for kpi in kpis)
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_kpi_fabricator.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/agents/nodes/kpi_fabricator.py
from typing import List, Dict, Any
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

    def __init__(self, model: str = "claude-3-5-sonnet-20241022"):
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

    async def fabricate_kpis(self, state: AgentState) -> AgentState:
        """Generate custom KPIs from user goals"""

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

        # Add to conversation
        state.conversation_history.append({
            "role": "assistant",
            "type": "kpis",
            "content": f"Created {len(state.kpis)} custom KPIs"
        })

        return state
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_kpi_fabricator.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/nodes/kpi_fabricator.py backend/tests/test_kpi_fabricator.py
git commit -m "feat: implement KPI fabrication for dynamic metric generation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 4: Multi-Agent Council Architecture

### Task 4.1: Implement Council Agent System

**Files:**
- Create: `backend/src/agents/council/optimist.py`
- Create: `backend/src/agents/council/pessimist.py`
- Create: `backend/src/agents/council/historian.py`
- Create: `backend/src/agents/council/synthesizer.py`
- Create: `backend/src/agents/council/council_manager.py`
- Test: `backend/tests/test_council.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_council.py
import pytest
from src.agents.council.council_manager import CouncilManager
from src.agents.state import AgentState

@pytest.mark.asyncio
async def test_council_deliberation():
    council = CouncilManager()
    state = AgentState(
        user_input="Launch product in 2 months",
        domain_ontology={
            "entities": [{"type": "Milestone", "properties": {"date": "str"}}]
        }
    )

    result = await council.deliberate(state)

    # Should have perspectives from all agents
    assert "optimist_view" in result.project_logic
    assert "pessimist_view" in result.project_logic
    assert "synthesis" in result.project_logic
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_council.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/agents/council/optimist.py
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate

class OptimistAgent:
    """Generates ambitious, creative plans"""

    def __init__(self):
        self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.8)
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", "You are an optimistic strategist. Propose ambitious plans that maximize opportunity and innovation. Ignore constraints temporarily."),
            ("user", "{input}")
        ])

    async def plan(self, state: dict) -> str:
        chain = self.prompt | self.llm
        response = await chain.ainvoke({"input": str(state)})
        return response.content

# backend/src/agents/council/pessimist.py
class PessimistAgent:
    """Identifies risks and failure modes"""

    def __init__(self):
        self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.3)
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", "You are a risk analyst. Identify all possible failure modes, resource gaps, and worst-case scenarios. Be thorough and skeptical."),
            ("user", "{input}")
        ])

    async def critique(self, state: dict, optimist_plan: str) -> str:
        chain = self.prompt | self.llm
        response = await chain.ainvoke({
            "input": f"State: {state}\n\nProposed Plan: {optimist_plan}"
        })
        return response.content

# backend/src/agents/council/historian.py
class HistorianAgent:
    """Ensures consistency with past decisions"""

    def __init__(self, memory):
        self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.2)
        self.memory = memory
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", "You verify consistency with past decisions and documentation. Check for contradictions."),
            ("user", "{input}\n\nPast decisions: {history}")
        ])

    async def verify(self, state: dict) -> str:
        # Retrieve relevant history
        history = await self.memory.retrieve_episodic(str(state), k=3)
        history_text = "\n".join([h["content"] for h in history])

        chain = self.prompt | self.llm
        response = await chain.ainvoke({
            "input": str(state),
            "history": history_text
        })
        return response.content

# backend/src/agents/council/synthesizer.py
class SynthesizerAgent:
    """Combines perspectives into balanced plan"""

    def __init__(self):
        self.llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.5)
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", "You synthesize diverse viewpoints into a balanced, executable plan. Balance ambition with pragmatism."),
            ("user", """Optimist view: {optimist}

Pessimist view: {pessimist}

Historian view: {historian}

Create synthesis:""")
        ])

    async def synthesize(self, optimist: str, pessimist: str, historian: str) -> str:
        chain = self.prompt | self.llm
        response = await chain.ainvoke({
            "optimist": optimist,
            "pessimist": pessimist,
            "historian": historian
        })
        return response.content

# backend/src/agents/council/council_manager.py
from typing import Dict
from ..state import AgentState
from .optimist import OptimistAgent
from .pessimist import PessimistAgent
from .historian import HistorianAgent
from .synthesizer import SynthesizerAgent
from ...memory.hybrid_memory import HybridMemory

class CouncilManager:
    """Orchestrates multi-agent deliberation"""

    def __init__(self):
        self.memory = HybridMemory()
        self.optimist = OptimistAgent()
        self.pessimist = PessimistAgent()
        self.historian = HistorianAgent(self.memory)
        self.synthesizer = SynthesizerAgent()

    async def deliberate(self, state: AgentState) -> AgentState:
        """Run council deliberation process"""

        # 1. Optimist proposes
        optimist_view = await self.optimist.plan(state.dict())

        # 2. Pessimist critiques
        pessimist_view = await self.pessimist.critique(state.dict(), optimist_view)

        # 3. Historian verifies
        historian_view = await self.historian.verify(state.dict())

        # 4. Synthesizer combines
        synthesis = await self.synthesizer.synthesize(
            optimist_view,
            pessimist_view,
            historian_view
        )

        # Store in state
        state.project_logic = {
            "optimist_view": optimist_view,
            "pessimist_view": pessimist_view,
            "historian_view": historian_view,
            "synthesis": synthesis
        }

        return state
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_council.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/agents/council/ backend/tests/test_council.py
git commit -m "feat: implement multi-agent council for balanced decision-making

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 5: Swift/Backend Integration

### Task 5.1: Create FastAPI Backend Service

**Files:**
- Create: `backend/src/api/main.py`
- Create: `backend/src/api/routes/agent.py`
- Create: `backend/src/api/websocket.py`
- Test: `backend/tests/test_api.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_api.py
import pytest
from httpx import AsyncClient
from src.api.main import app

@pytest.mark.asyncio
async def test_process_input_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/agent/process", json={
            "input": "Help me optimize my supply chain",
            "session_id": "test-123"
        })

    assert response.status_code == 200
    data = response.json()
    assert "ambiguity_score" in data
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_api.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# backend/src/api/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import agent

app = FastAPI(title="Rpd Ganis GIU API")

# CORS for Swift app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(agent.router, prefix="/api/agent", tags=["agent"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# backend/src/api/routes/agent.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
from ...agents.graph import CognitiveGraph
from ...agents.state import AgentState, StateNode
from ...memory.hybrid_memory import HybridMemory

router = APIRouter()

# In-memory session storage (use Redis in production)
sessions: Dict[str, AgentState] = {}

class ProcessRequest(BaseModel):
    input: str
    session_id: str

class ProcessResponse(BaseModel):
    session_id: str
    ambiguity_score: Optional[float] = None
    questions: Optional[list] = None
    ontology: Optional[Dict[str, Any]] = None
    kpis: Optional[list] = None
    message: str

@router.post("/process", response_model=ProcessResponse)
async def process_input(request: ProcessRequest):
    """Process user input through cognitive graph"""

    # Get or create session
    if request.session_id not in sessions:
        sessions[request.session_id] = AgentState(
            current_node=StateNode.AMBIGUITY_SCANNER,
            user_input=request.input,
            conversation_history=[]
        )
    else:
        state = sessions[request.session_id]
        state.user_input = request.input

    # Run through graph
    graph = CognitiveGraph()
    memory = HybridMemory()
    await memory.initialize()

    try:
        # Process through nodes
        state = sessions[request.session_id]

        # Run ambiguity scanner
        from ...agents.nodes.ambiguity_scanner import AmbiguityScanner
        scanner = AmbiguityScanner()
        state = await scanner.analyze(state)

        # If high ambiguity, run interrogator
        questions = None
        if state.ambiguity_score > 0.7:
            from ...agents.nodes.socratic_interrogator import SocraticInterrogator
            interrogator = SocraticInterrogator()
            state = await interrogator.generate_questions(state)
            questions = state.conversation_history[-1].get("questions", [])

        # Store updated state
        sessions[request.session_id] = state

        return ProcessResponse(
            session_id=request.session_id,
            ambiguity_score=state.ambiguity_score,
            questions=questions,
            message="Input processed successfully"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await memory.close()
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_api.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/api/ backend/tests/test_api.py
git commit -m "feat: create FastAPI backend service with agent endpoints

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 5.2: Create Swift Backend Client

**Files:**
- Create: `MrVAgent/Services/Backends/RpdBackendService.swift`
- Create: `MrVAgent/Models/RpdModels.swift`
- Modify: `MrVAgent/ViewModels/ChatViewModel.swift`

**Step 1: Write the failing test**

```swift
// MrVAgent/Tests/RpdBackendServiceTests.swift
import XCTest
@testable import MrVAgent

final class RpdBackendServiceTests: XCTestCase {
    func testProcessInputRequest() async throws {
        let service = RpdBackendService()

        let response = try await service.processInput(
            input: "Help me optimize my workflow",
            sessionId: "test-session"
        )

        XCTAssertNotNil(response.ambiguityScore)
        XCTAssertNotNil(response.message)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter RpdBackendServiceTests`
Expected: FAIL with "cannot find 'RpdBackendService'"

**Step 3: Write minimal implementation**

```swift
// MrVAgent/Models/RpdModels.swift
import Foundation

struct ProcessInputRequest: Codable {
    let input: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case input
        case sessionId = "session_id"
    }
}

struct ProcessInputResponse: Codable {
    let sessionId: String
    let ambiguityScore: Double?
    let questions: [String]?
    let ontology: [String: AnyCodable]?
    let kpis: [KPI]?
    let message: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case ambiguityScore = "ambiguity_score"
        case questions
        case ontology
        case kpis
        case message
    }
}

struct KPI: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let measurementMethod: String
    let dataSource: String
    let optimizationDirection: String

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case measurementMethod = "measurement_method"
        case dataSource = "data_source"
        case optimizationDirection = "optimization_direction"
    }
}

// Helper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

// MrVAgent/Services/Backends/RpdBackendService.swift
import Foundation

enum RpdBackendError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
}

actor RpdBackendService {
    private let baseURL: String
    private let session: URLSession
    private var sessionId: String

    init(baseURL: String = "http://localhost:8001") {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.sessionId = UUID().uuidString
    }

    func processInput(input: String, sessionId: String? = nil) async throws -> ProcessInputResponse {
        let useSessionId = sessionId ?? self.sessionId

        guard let url = URL(string: "\(baseURL)/api/agent/process") else {
            throw RpdBackendError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ProcessInputRequest(input: input, sessionId: useSessionId)
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RpdBackendError.serverError(0)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw RpdBackendError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            let processResponse = try decoder.decode(ProcessInputResponse.self, from: data)

            return processResponse

        } catch let error as DecodingError {
            throw RpdBackendError.decodingError(error)
        } catch {
            throw RpdBackendError.networkError(error)
        }
    }

    func resetSession() {
        self.sessionId = UUID().uuidString
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter RpdBackendServiceTests`
Expected: PASS (with backend running)

**Step 5: Commit**

```bash
git add MrVAgent/Services/Backends/ MrVAgent/Models/RpdModels.swift MrVAgent/Tests/
git commit -m "feat: create Swift client for Rpd backend service

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 6: Generative UI Implementation

### Task 6.1: Create Dynamic UI Component System

**Files:**
- Create: `MrVAgent/FluidReality/GenerativeComponents/DynamicDashboard.swift`
- Create: `MrVAgent/FluidReality/GenerativeComponents/KPIWidget.swift`
- Create: `MrVAgent/FluidReality/GenerativeComponents/OntologyVisualization.swift`

**Step 1: Write the failing test**

```swift
// MrVAgent/Tests/GenerativeUITests.swift
import XCTest
import SwiftUI
@testable import MrVAgent

final class GenerativeUITests: XCTestCase {
    func testDynamicDashboardCreation() {
        let kpis = [
            KPI(name: "Velocity", description: "Team speed",
                measurementMethod: "Tasks/week", dataSource: "Task system",
                optimizationDirection: "maximize")
        ]

        let dashboard = DynamicDashboard(kpis: kpis)

        XCTAssertEqual(dashboard.widgets.count, 1)
        XCTAssertEqual(dashboard.widgets[0].title, "Velocity")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter GenerativeUITests`
Expected: FAIL with "cannot find type 'DynamicDashboard'"

**Step 3: Write minimal implementation**

```swift
// MrVAgent/FluidReality/GenerativeComponents/KPIWidget.swift
import SwiftUI

struct KPIWidget: View, Identifiable {
    let id = UUID()
    let kpi: KPI
    @State private var currentValue: Double = 0
    @State private var isAnimating = false

    var title: String { kpi.name }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(kpi.name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(currentValue))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(kpi.optimizationDirection == "maximize" ? .green : .red)

                Image(systemName: kpi.optimizationDirection == "maximize" ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(kpi.optimizationDirection == "maximize" ? .green : .red)
            }

            // Description
            Text(kpi.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)

            // Measurement method
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 10))
                Text(kpi.measurementMethod)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            // Simulate data update
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                currentValue = Double.random(in: 0...100)
            }
        }
    }
}

// MrVAgent/FluidReality/GenerativeComponents/DynamicDashboard.swift
import SwiftUI

struct DynamicDashboard: View {
    let kpis: [KPI]

    var widgets: [KPIWidget] {
        kpis.map { KPIWidget(kpi: $0) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(widgets) { widget in
                    widget
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .background(Color.black.opacity(0.8))
    }
}

// MrVAgent/FluidReality/GenerativeComponents/OntologyVisualization.swift
import SwiftUI

struct OntologyNode: Identifiable {
    let id = UUID()
    let type: String
    let properties: [String: String]
    var position: CGPoint
}

struct OntologyVisualization: View {
    let ontology: [String: AnyCodable]?
    @State private var nodes: [OntologyNode] = []

    var body: some View {
        ZStack {
            // Connections
            ForEach(0..<nodes.count - 1, id: \.self) { index in
                Path { path in
                    path.move(to: nodes[index].position)
                    path.addLine(to: nodes[index + 1].position)
                }
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            }

            // Nodes
            ForEach(nodes) { node in
                VStack {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(node.type.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )

                    Text(node.type)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .position(node.position)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
        .onAppear {
            generateNodes()
        }
    }

    private func generateNodes() {
        // Parse ontology and create visual nodes
        guard let ont = ontology,
              let entities = ont["entities"] as? [[String: Any]] else { return }

        let centerX: CGFloat = 400
        let centerY: CGFloat = 300
        let radius: CGFloat = 150

        for (index, entity) in entities.enumerated() {
            guard let type = entity["type"] as? String else { continue }

            let angle = (2 * .pi / Double(entities.count)) * Double(index)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)

            let node = OntologyNode(
                type: type,
                properties: [:],
                position: CGPoint(x: x, y: y)
            )
            nodes.append(node)
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter GenerativeUITests`
Expected: PASS

**Step 5: Commit**

```bash
git add MrVAgent/FluidReality/GenerativeComponents/ MrVAgent/Tests/GenerativeUITests.swift
git commit -m "feat: implement generative UI with dynamic dashboard and KPI widgets

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 7: Integration & Testing

### Task 7.1: Integrate Rpd Backend into Main View

**Files:**
- Modify: `MrVAgent/Views/MainView.swift`
- Modify: `MrVAgent/ViewModels/ChatViewModel.swift`
- Create: `MrVAgent/ViewModels/RpdViewModel.swift`

**Step 1: Write the failing test**

```swift
// MrVAgent/Tests/RpdIntegrationTests.swift
import XCTest
@testable import MrVAgent

final class RpdIntegrationTests: XCTestCase {
    @MainActor
    func testRpdViewModelProcessing() async throws {
        let viewModel = RpdViewModel()

        await viewModel.processInput("Help me optimize my supply chain")

        XCTAssertTrue(viewModel.ambiguityScore > 0)
        XCTAssertFalse(viewModel.isProcessing)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter RpdIntegrationTests`
Expected: FAIL with "cannot find 'RpdViewModel'"

**Step 3: Write minimal implementation**

```swift
// MrVAgent/ViewModels/RpdViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class RpdViewModel: ObservableObject {
    @Published var currentInput: String = ""
    @Published var ambiguityScore: Double = 0.0
    @Published var clarifyingQuestions: [String] = []
    @Published var currentOntology: [String: AnyCodable]?
    @Published var kpis: [KPI] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var conversationHistory: [ConversationMessage] = []

    private let backendService: RpdBackendService
    private var sessionId: String

    init() {
        self.backendService = RpdBackendService()
        self.sessionId = UUID().uuidString
    }

    func processInput(_ input: String) async {
        guard !input.isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        currentInput = input

        // Add user message
        conversationHistory.append(ConversationMessage(
            role: .user,
            content: input
        ))

        do {
            let response = try await backendService.processInput(
                input: input,
                sessionId: sessionId
            )

            // Update state
            if let score = response.ambiguityScore {
                ambiguityScore = score
            }

            if let questions = response.questions {
                clarifyingQuestions = questions

                // Add questions to conversation
                conversationHistory.append(ConversationMessage(
                    role: .assistant,
                    content: "I need some clarification:",
                    questions: questions
                ))
            }

            if let ontology = response.ontology {
                currentOntology = ontology
            }

            if let kpisData = response.kpis {
                kpis = kpisData
            }

            // Add response message
            conversationHistory.append(ConversationMessage(
                role: .assistant,
                content: response.message
            ))

        } catch {
            errorMessage = "Failed to process input: \(error.localizedDescription)"

            conversationHistory.append(ConversationMessage(
                role: .system,
                content: "Error: \(error.localizedDescription)"
            ))
        }

        isProcessing = false
    }

    func answerClarification(_ answer: String) async {
        await processInput(answer)
    }

    func reset() {
        currentInput = ""
        ambiguityScore = 0.0
        clarifyingQuestions = []
        currentOntology = nil
        kpis = []
        conversationHistory = []
        sessionId = UUID().uuidString
        Task {
            await backendService.resetSession()
        }
    }
}

struct ConversationMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    var questions: [String]? = nil

    enum Role {
        case user
        case assistant
        case system
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter RpdIntegrationTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MrVAgent/ViewModels/RpdViewModel.swift MrVAgent/Tests/RpdIntegrationTests.swift
git commit -m "feat: integrate Rpd cognitive backend with Swift ViewModel

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 7.2: Create Rpd Mode View

**Files:**
- Create: `MrVAgent/Views/RpdModeView.swift`
- Modify: `MrVAgent/Views/MainView.swift`

**Step 1: Create the view implementation**

```swift
// MrVAgent/Views/RpdModeView.swift
import SwiftUI

struct RpdModeView: View {
    @StateObject private var viewModel = RpdViewModel()
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rpd Ganis GIU")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Emergent Cognitive Architecture")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Ambiguity indicator
                if viewModel.ambiguityScore > 0 {
                    HStack(spacing: 8) {
                        Text("Ambiguity:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        AmbiguityIndicator(score: viewModel.ambiguityScore)
                    }
                }

                Button(action: { viewModel.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color.black.opacity(0.8))

            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Conversation
                    ForEach(viewModel.conversationHistory) { message in
                        ConversationBubble(message: message, viewModel: viewModel)
                    }

                    // KPI Dashboard
                    if !viewModel.kpis.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Generated KPIs")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            DynamicDashboard(kpis: viewModel.kpis)
                        }
                    }

                    // Ontology Visualization
                    if let ontology = viewModel.currentOntology {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Domain Ontology")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            OntologyVisualization(ontology: ontology)
                                .frame(height: 400)
                        }
                    }
                }
                .padding(.vertical, 20)
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Describe your project or goal...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)

                Button(action: {
                    Task {
                        await viewModel.processInput(inputText)
                        inputText = ""
                    }
                }) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || viewModel.isProcessing)
            }
            .padding(20)
            .background(Color.black.opacity(0.9))
        }
        .background(Color.black)
    }
}

struct AmbiguityIndicator: View {
    let score: Double

    private var color: Color {
        if score > 0.7 { return .red }
        if score > 0.4 { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(String(format: "%.0f%%", score * 100))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ConversationBubble: View {
    let message: ConversationMessage
    let viewModel: RpdViewModel

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        message.role == .user ?
                        Color.blue.opacity(0.6) :
                        Color.white.opacity(0.1)
                    )
                    .cornerRadius(12)

                // Questions
                if let questions = message.questions {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            Button(action: {
                                Task {
                                    await viewModel.answerClarification(question)
                                }
                            }) {
                                Text(question)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.purple.opacity(0.3))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: 500)

            if message.role != .user {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    RpdModeView()
}
```

**Step 2: Update MainView to include Rpd mode**

```swift
// MrVAgent/Views/MainView.swift (add to existing)
// Add new enum case
enum ViewMode {
    case fluid
    case chat
    case rpd  // New mode
}

// Add button in view
Button(action: { viewMode = .rpd }) {
    Text("Rpd Mode")
}

// Add case in switch
case .rpd:
    RpdModeView()
```

**Step 3: Test the view**

Run: `swift build && open MrVAgent.app`
Expected: App builds and Rpd mode is accessible

**Step 4: Commit**

```bash
git add MrVAgent/Views/RpdModeView.swift MrVAgent/Views/MainView.swift
git commit -m "feat: create Rpd mode view with conversation and dynamic UI

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 8: Model Router & Optimization

### Task 8.1: Implement Intelligent Model Router

**Files:**
- Create: `backend/src/routing/model_router.py`
- Test: `backend/tests/test_model_router.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_model_router.py
import pytest
from src.routing.model_router import IntelligentModelRouter, TaskType

def test_route_based_on_task_type():
    router = IntelligentModelRouter()

    # Gemini for large context
    model = router.select_model(
        input_text="Analyze these 1000 documents...",
        task_type=TaskType.INGESTION
    )
    assert "gemini" in model.lower()

    # Claude for code generation
    model = router.select_model(
        input_text="Write Python function",
        task_type=TaskType.CODE_GENERATION
    )
    assert "claude" in model.lower()
```

**Step 2: Run test to verify it fails**

Run: `pytest backend/tests/test_model_router.py -v`
Expected: FAIL

**Step 3: Write minimal implementation**

```python
# backend/src/routing/model_router.py
from enum import Enum
from typing import Dict, Optional
from dataclasses import dataclass
import time

class TaskType(str, Enum):
    CONVERSATION = "conversation"
    INGESTION = "ingestion"  # Reading large docs
    CODE_GENERATION = "code_generation"
    REASONING = "reasoning"
    CLARIFICATION = "clarification"

@dataclass
class ModelPerformance:
    success_count: int = 0
    failure_count: int = 0
    avg_response_time: float = 0.0
    total_calls: int = 0

class IntelligentModelRouter:
    """
    Routes requests to optimal model based on:
    - Task type
    - Input length
    - Historical performance
    - Cost optimization
    """

    MODEL_CAPABILITIES = {
        "gemini-1.5-pro": {
            "max_context": 2_000_000,
            "strengths": [TaskType.INGESTION],
            "cost_per_1k": 0.002
        },
        "claude-3-5-sonnet-20241022": {
            "max_context": 200_000,
            "strengths": [TaskType.CODE_GENERATION, TaskType.REASONING],
            "cost_per_1k": 0.003
        },
        "gpt-4o": {
            "max_context": 128_000,
            "strengths": [TaskType.CONVERSATION],
            "cost_per_1k": 0.0025
        }
    }

    def __init__(self):
        self.performance: Dict[str, ModelPerformance] = {
            model: ModelPerformance() for model in self.MODEL_CAPABILITIES
        }

    def select_model(
        self,
        input_text: str,
        task_type: TaskType,
        current_model: Optional[str] = None
    ) -> str:
        """Select optimal model for task"""

        input_length = len(input_text.split())

        # Large context -> Gemini
        if input_length > 50_000:
            return "gemini-1.5-pro"

        # Task-specific routing
        if task_type == TaskType.CODE_GENERATION or task_type == TaskType.REASONING:
            return "claude-3-5-sonnet-20241022"

        if task_type == TaskType.INGESTION:
            return "gemini-1.5-pro"

        if task_type == TaskType.CONVERSATION:
            # Use performance history
            return self._select_by_performance(current_model)

        # Default
        return current_model or "claude-3-5-sonnet-20241022"

    def _select_by_performance(self, current_model: Optional[str]) -> str:
        """Select based on historical performance"""
        if not current_model:
            return "claude-3-5-sonnet-20241022"

        perf = self.performance[current_model]

        # If current model is performing well, stick with it
        if perf.total_calls > 0:
            success_rate = perf.success_count / perf.total_calls
            if success_rate > 0.9:
                return current_model

        # Otherwise, try alternative
        alternatives = [m for m in self.MODEL_CAPABILITIES if m != current_model]
        return alternatives[0] if alternatives else current_model

    def record_success(self, model: str, response_time: float):
        """Record successful call"""
        perf = self.performance[model]
        perf.success_count += 1
        perf.total_calls += 1
        perf.avg_response_time = (
            (perf.avg_response_time * (perf.total_calls - 1) + response_time)
            / perf.total_calls
        )

    def record_failure(self, model: str):
        """Record failed call"""
        perf = self.performance[model]
        perf.failure_count += 1
        perf.total_calls += 1
```

**Step 4: Run test to verify it passes**

Run: `pytest backend/tests/test_model_router.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add backend/src/routing/ backend/tests/test_model_router.py
git commit -m "feat: implement intelligent model router with performance tracking

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Summary & Execution Options

This implementation plan transforms MrVAgent into the "Rpd Ganis GIU" system described in the PDF through 8 phases:

1. **Foundation**: LangGraph state machine, ambiguity detection, Socratic questioning
2. **Memory**: Temporal knowledge graphs (Neo4j/Graphiti) + hybrid episodic-semantic memory
3. **Ontology**: Dynamic schema generation and KPI fabrication
4. **Council**: Multi-agent deliberation system (Optimist/Pessimist/Historian/Synthesizer)
5. **Integration**: FastAPI backend + Swift client
6. **Generative UI**: Dynamic dashboards, KPI widgets, ontology visualization
7. **Testing**: End-to-end integration tests
8. **Optimization**: Intelligent model routing (Gemini/Claude/GPT-4o)

**Key Architectural Decisions:**
- Python backend (LangChain/LangGraph) for AI orchestration
- Swift frontend (existing MrVAgent) for native macOS experience
- Neo4j for temporal knowledge graphs (causal reasoning)
- Hybrid memory: Vector DB (episodic) + Graph DB (semantic)
- Model router pattern: Gemini for ingestion, Claude for reasoning
- Generative UI: SwiftUI components generated dynamically

**Next Steps:**
1. Create Python backend environment: `cd backend && python -m venv venv && pip install -r requirements.txt`
2. Start Neo4j: `docker-compose up -d neo4j`
3. Start FastAPI: `uvicorn src.api.main:app --reload`
4. Run Swift app with Rpd mode enabled

---

**Plan complete and saved to `docs/plans/2026-01-19-rpd-ganis-giu-cognitive-architecture.md`.**

**Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach would you like to use?**
