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
