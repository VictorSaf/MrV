import pytest
from src.agents.council.council_manager import CouncilManager
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_council_deliberation():
    council = CouncilManager(use_llm=False)
    state = AgentState(
        current_node=StateNode.STRATEGY_MOTOR,
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
