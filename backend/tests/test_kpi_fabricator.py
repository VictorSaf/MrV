import pytest
from src.agents.nodes.kpi_fabricator import KPIFabricator
from src.agents.state import AgentState, StateNode

@pytest.mark.asyncio
async def test_fabricates_custom_kpis():
    fabricator = KPIFabricator(use_llm=False)
    state = AgentState(
        current_node=StateNode.ONTOLOGY_ARCHITECT,
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
