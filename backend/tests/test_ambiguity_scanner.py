import pytest
from src.agents.nodes.ambiguity_scanner import AmbiguityScanner
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_ambiguity_scanner_high_entropy():
    scanner = AmbiguityScanner(use_llm=False)
    state = AgentState(
        current_node=StateNode.AMBIGUITY_SCANNER,
        user_input="Help me with my business"
    )

    result = await scanner.analyze(state)
    assert result.ambiguity_score > 0.7
    assert "Ambiguity" in result.conversation_history[-1]["analysis"]

@pytest.mark.asyncio
async def test_ambiguity_scanner_low_entropy():
    scanner = AmbiguityScanner(use_llm=False)
    state = AgentState(
        current_node=StateNode.AMBIGUITY_SCANNER,
        user_input="Create a Gantt chart for construction project starting March 1st with 5 phases"
    )

    result = await scanner.analyze(state)
    assert result.ambiguity_score < 0.5
