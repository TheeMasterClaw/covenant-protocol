import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_list_agents_empty():
    response = client.get("/agents")
    assert response.status_code == 200
    assert response.json() == []


def test_register_agent():
    agent_data = {
        "name": "Test Agent",
        "agent_type": "covenant",
        "description": "A test agent",
        "capabilities": ["monitoring", "alerting"],
        "config": {"api_key": "test123"},
        "owner": "0x1234567890123456789012345678901234567890",
    }
    response = client.post("/agents", json=agent_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == agent_data["name"]
    assert data["agent_type"] == agent_data["agent_type"]
    assert "id" in data


def test_get_agent_not_found():
    response = client.get("/agents/non-existent-id")
    assert response.status_code == 404
