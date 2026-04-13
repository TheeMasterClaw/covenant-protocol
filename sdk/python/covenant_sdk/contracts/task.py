"""Task contract wrappers."""

from typing import List, Dict
from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress, Bytes32, TaskStatus
from ..abis import TASK_MARKET_ABI
from ..utils import TxReceipt


class TaskMarket(BaseContract):
    """Wrapper for the TaskMarket contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, TASK_MARKET_ABI, w3)

    def create_task(
        self,
        covenant_id: int,
        reward: int,
        reward_token: EthereumAddress,
        deadline: int,
        metadata_hash: Bytes32,
        value: int = 0
    ) -> TxReceipt:
        """Create a new task."""
        return self._send_transaction(
            "createTask",
            covenant_id,
            reward,
            reward_token,
            deadline,
            metadata_hash,
            value=value
        )

    def assign_task(self, task_id: int) -> TxReceipt:
        """Assign a task to the caller."""
        return self._send_transaction("assignTask", task_id)

    def submit_task(self, task_id: int, proof_hash: Bytes32) -> TxReceipt:
        """Submit completed task proof."""
        return self._send_transaction("submitTask", task_id, proof_hash)

    def complete_task(self, task_id: int) -> TxReceipt:
        """Mark a task as completed."""
        return self._send_transaction("completeTask", task_id)

    def dispute_task(self, task_id: int) -> TxReceipt:
        """Dispute a task."""
        return self._send_transaction("disputeTask", task_id)

    def cancel_task(self, task_id: int) -> TxReceipt:
        """Cancel a task."""
        return self._send_transaction("cancelTask", task_id)

    def get_task(self, task_id: int) -> Dict:
        """Get task details."""
        result = self._call("getTask", task_id)
        return {
            "id": result[0],
            "covenant_id": result[1],
            "creator": result[2],
            "assignee": result[3],
            "reward": result[4],
            "reward_token": result[5],
            "deadline": result[6],
            "status": TaskStatus(result[7]),
            "metadata_hash": result[8],
        }

    def get_tasks_by_covenant(self, covenant_id: int) -> List[int]:
        """Get all tasks for a covenant."""
        return self._call("getTasksByCovenant", covenant_id)

    def get_tasks_by_assignee(self, assignee: EthereumAddress) -> List[int]:
        """Get all tasks assigned to an address."""
        return self._call("getTasksByAssignee", assignee)
