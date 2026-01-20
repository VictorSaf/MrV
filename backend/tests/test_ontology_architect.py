import pytest
from src.agents.nodes.ontology_architect import OntologyArchitect
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_generates_domain_ontology():
    architect = OntologyArchitect(use_llm=False)
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
