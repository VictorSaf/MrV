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
