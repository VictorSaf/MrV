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
