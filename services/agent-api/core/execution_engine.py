import asyncio
import os
import sqlite3
import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from core.blockchain import (
    get_on_chain_intent,
    submit_intent_on_chain,
    verify_execution_on_chain,
)


class ExecutionEngine:
    """Coordinates autonomous covenant execution across AI frameworks."""

    def __init__(self, registry, coordinator):
        self.registry = registry
        self.coordinator = coordinator
        self._db_path = os.path.expanduser("~/.covenant/intents/intents.db")
        os.makedirs(os.path.dirname(self._db_path), exist_ok=True)
        self._init_db()

    def _init_db(self) -> None:
        with sqlite3.connect(self._db_path) as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS intents (
                    id TEXT PRIMARY KEY,
                    covenant_address TEXT NOT NULL,
                    condition_id TEXT,
                    executor_agent_id TEXT,
                    proof_hash TEXT,
                    stake_amount REAL,
                    status TEXT,
                    tx_hash TEXT,
                    submitted_at TEXT,
                    verified_at TEXT,
                    validation_data TEXT
                )
                """
            )
            conn.commit()

    def _db_insert(self, record: Dict[str, Any]) -> None:
        with sqlite3.connect(self._db_path) as conn:
            conn.execute(
                """
                INSERT INTO intents
                (id, covenant_address, condition_id, executor_agent_id, proof_hash,
                 stake_amount, status, tx_hash, submitted_at, verified_at, validation_data)
                VALUES
                (:id, :covenant_address, :condition_id, :executor_agent_id, :proof_hash,
                 :stake_amount, :status, :tx_hash, :submitted_at, :verified_at, :validation_data)
                """,
                record,
            )
            conn.commit()

    def _db_update(self, intent_id: str, fields: Dict[str, Any]) -> None:
        with sqlite3.connect(self._db_path) as conn:
            sets = ", ".join(f"{k} = :{k}" for k in fields.keys())
            sql = f"UPDATE intents SET {sets} WHERE id = :intent_id"
            params = dict(fields)
            params["intent_id"] = intent_id
            conn.execute(sql, params)
            conn.commit()

    def _db_get(self, intent_id: str) -> Optional[Dict[str, Any]]:
        with sqlite3.connect(self._db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                "SELECT * FROM intents WHERE id = ?", (intent_id,)
            ).fetchone()
            if not row:
                return None
            return dict(row)

    def _db_get_by_covenant(self, covenant_address: str) -> Optional[Dict[str, Any]]:
        with sqlite3.connect(self._db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                "SELECT * FROM intents WHERE covenant_address = ? ORDER BY submitted_at DESC LIMIT 1",
                (covenant_address,),
            ).fetchone()
            if not row:
                return None
            return dict(row)

    async def submit_intent(
        self,
        covenant_address: str,
        condition_id: str,
        executor_agent_id: str,
        proof_hash: str,
        stake_amount: float = 0.0,
    ) -> Dict[str, Any]:
        agent = self.registry.get(executor_agent_id)
        if not agent:
            raise ValueError("Executor agent not found")

        wallet = agent.get("wallet_address")
        if not wallet:
            raise ValueError("Executor agent has no wallet_address")

        ph = proof_hash or ("0x" + "0" * 64)

        loop = asyncio.get_event_loop()
        tx_hash = await loop.run_in_executor(
            None,
            lambda: submit_intent_on_chain(
                covenant_address=covenant_address,
                proof_hash=ph,
                value_eth=stake_amount,
            ),
        )

        intent_id = str(uuid.uuid4())
        record = {
            "id": intent_id,
            "covenant_address": covenant_address,
            "condition_id": condition_id,
            "executor_agent_id": executor_agent_id,
            "proof_hash": ph,
            "stake_amount": stake_amount,
            "status": "submitted",
            "tx_hash": tx_hash,
            "submitted_at": datetime.utcnow().isoformat(),
            "verified_at": None,
            "validation_data": None,
        }
        await loop.run_in_executor(None, self._db_insert, record)
        return record

    async def verify_intent(self, intent_id: str, validation_data: str) -> Dict[str, Any]:
        loop = asyncio.get_event_loop()
        intent = await loop.run_in_executor(None, self._db_get, intent_id)
        if not intent:
            raise ValueError("Intent not found")

        tx_hash = await loop.run_in_executor(
            None,
            lambda: verify_execution_on_chain(
                covenant_address=intent["covenant_address"],
                proof_hash=intent["proof_hash"] or ("0x" + "0" * 64),
                validation_data=validation_data.encode(),
            ),
        )

        updates = {
            "status": "verified",
            "verified_at": datetime.utcnow().isoformat(),
            "validation_data": validation_data,
            "tx_hash": tx_hash,
        }
        await loop.run_in_executor(None, self._db_update, intent_id, updates)
        intent.update(updates)
        return intent

    async def verify_intent_by_covenant(
        self,
        covenant_address: str,
        proof_hash: str,
        validation_data: str = "",
    ) -> Dict[str, Any]:
        loop = asyncio.get_event_loop()
        intent = await loop.run_in_executor(None, self._db_get_by_covenant, covenant_address)
        if not intent:
            raise ValueError("Intent not found for covenant")

        ph = proof_hash or intent.get("proof_hash") or ("0x" + "0" * 64)
        tx_hash = await loop.run_in_executor(
            None,
            lambda: verify_execution_on_chain(
                covenant_address=covenant_address,
                proof_hash=ph,
                validation_data=validation_data.encode(),
            ),
        )

        updates = {
            "status": "verified",
            "verified_at": datetime.utcnow().isoformat(),
            "validation_data": validation_data,
            "tx_hash": tx_hash,
        }
        await loop.run_in_executor(None, self._db_update, intent["id"], updates)
        intent.update(updates)
        return intent

    async def monitor_conditions(self, covenant_address: str) -> Dict[str, Any]:
        """Poll or subscribe to covenant condition status."""
        loop = asyncio.get_event_loop()
        on_chain = await loop.run_in_executor(None, get_on_chain_intent, covenant_address)
        conditions_met = False
        if on_chain:
            conditions_met = on_chain.get("executed", False)
        return {
            "covenant_address": covenant_address,
            "monitored_at": datetime.utcnow().isoformat(),
            "conditions_met": conditions_met,
            "on_chain_intent": on_chain,
        }

    async def get_intent(self, intent_id: str) -> Optional[Dict[str, Any]]:
        loop = asyncio.get_event_loop()
        intent = await loop.run_in_executor(None, self._db_get, intent_id)
        if intent:
            on_chain = await loop.run_in_executor(
                None, get_on_chain_intent, intent["covenant_address"]
            )
            intent["on_chain_state"] = on_chain
        return intent
