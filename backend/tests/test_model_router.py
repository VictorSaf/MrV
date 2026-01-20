import pytest
from src.routing.model_router import ModelRouter, TaskType

def test_router_selects_appropriate_model():
    router = ModelRouter()

    # Ambiguity scanning needs fast, cheap model
    model = router.select_model(TaskType.AMBIGUITY_SCAN, complexity_score=0.3)
    assert model in ["claude-3-haiku-20240307", "gpt-4o-mini"]

    # Council deliberation needs powerful model
    model = router.select_model(TaskType.COUNCIL_DELIBERATION, complexity_score=0.9)
    assert model in ["claude-3-5-sonnet-20241022", "gpt-4o"]

    # Ontology generation needs creative model
    model = router.select_model(TaskType.ONTOLOGY_GENERATION, complexity_score=0.7)
    assert model in ["claude-3-5-sonnet-20241022", "gemini-2.0-flash-exp"]

def test_router_considers_cost():
    router = ModelRouter(cost_threshold=0.01)

    # Should prefer cheaper models when cost-conscious
    model = router.select_model(TaskType.AMBIGUITY_SCAN, complexity_score=0.5)
    assert "haiku" in model.lower() or "mini" in model.lower()
