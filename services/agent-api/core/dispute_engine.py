import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional
from collections import Counter


class DisputeEngine:
    """Coordinates AI-assisted dispute resolution across agent frameworks."""

    def __init__(self, registry):
        self.registry = registry
        self._sessions: Dict[str, Dict[str, Any]] = {}

    async def create_session(
        self,
        dispute_id: str,
        covenant_address: str,
        evidence_hash: str,
        juror_pool: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        jurors = juror_pool or []
        if not jurors:
            # Auto-select agents with dispute_resolution capability
            candidates = self.registry.find_by_capabilities(["dispute_resolution"])
            jurors = [a["id"] for a in candidates[:11]]

        session_id = str(uuid.uuid4())
        self._sessions[session_id] = {
            "id": session_id,
            "dispute_id": dispute_id,
            "covenant_address": covenant_address,
            "evidence_hash": evidence_hash,
            "jurors": [{"agent_id": j, "status": "pending", "vote": None} for j in jurors],
            "status": "created",
            "created_at": datetime.utcnow().isoformat(),
            "resolved_at": None,
            "final_verdict": None,
            "confidence": 0.0,
        }
        return self._sessions[session_id]

    async def submit_vote(
        self,
        session_id: str,
        juror_id: str,
        verdict: str,
        reasoning_hash: str,
    ) -> Dict[str, Any]:
        session = self._sessions.get(session_id)
        if not session:
            raise ValueError("Session not found")

        for juror in session["jurors"]:
            if juror["agent_id"] == juror_id:
                juror["status"] = "voted"
                juror["vote"] = {
                    "verdict": verdict,
                    "reasoning_hash": reasoning_hash,
                    "timestamp": datetime.utcnow().isoformat(),
                }
                break
        else:
            raise ValueError("Juror not found in session")

        return session

    async def resolve_session(self, session_id: str) -> Dict[str, Any]:
        session = self._sessions.get(session_id)
        if not session:
            raise ValueError("Session not found")

        votes = [j["vote"]["verdict"] for j in session["jurors"] if j.get("vote")]
        if not votes:
            raise ValueError("No votes submitted")

        verdict_counts = Counter(votes)
        majority_verdict, count = verdict_counts.most_common(1)[0]
        confidence = count / len(votes)

        session["status"] = "resolved"
        session["resolved_at"] = datetime.utcnow().isoformat()
        session["final_verdict"] = majority_verdict
        session["confidence"] = confidence
        return session

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        return self._sessions.get(session_id)
