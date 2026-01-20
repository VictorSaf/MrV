import pytest
from src.agents.nodes.socratic_interrogator import SocraticInterrogator
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_generates_clarifying_questions():
    interrogator = SocraticInterrogator(use_llm=False)
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
