import pytest
from httpx import AsyncClient, ASGITransport
from src.api.main import app

@pytest.mark.asyncio
async def test_process_input_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/agent/process", json={
            "input": "Help me optimize my supply chain",
            "session_id": "test-123"
        })

    assert response.status_code == 200
    data = response.json()
    assert "ambiguity_score" in data
