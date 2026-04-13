import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_create_coordination_session():
    # First register an agent
    agent_data = {
        "name": "Coordinator Agent",
        "agent_type": "task",
        "description": "A coordinator agent",
        "capabilities": ["coordination"],
        "config": {},
        "owner": "0x1234567890123456789012345678901234567890",
    }
    agent_response = client.post("/agents", json=agent_data)
    agent_id = agent_response.json()["id"]

    # Create coordination session
    coord_data = {
        "name": "Test Session",
        "description": "A test coordination session",
        "objective": "Complete test task",
        "agent_ids": [agent_id],
        "context": {"priority": "high"},
    }
    response = client.post("/coordinations", json=coord_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == coord_data["name"]
    assert data["status"] == "created"


def test_list_coordination_sessions():
    response = client.get("/coordinations")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
