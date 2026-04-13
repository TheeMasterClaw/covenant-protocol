"""Dispute contract wrappers."""

from typing import Dict, List
from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress, Bytes32, DisputeParams, ResolutionOutcome, AppealStatus
from ..abis import DISPUTE_DAO_ABI, DISPUTE_RESOLUTION_ABI, DISPUTE_APPEAL_ABI
from ..utils import TxReceipt


class DisputeDAO(BaseContract):
    """Wrapper for the DisputeDAO contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, DISPUTE_DAO_ABI, w3)

    def update_params(self, params: DisputeParams) -> TxReceipt:
        """Update dispute parameters."""
        param_tuple = (params.min_stake, params.voting_period, params.quorum, params.appeal_threshold)
        return self._send_transaction("updateParams", param_tuple)

    def get_params(self) -> DisputeParams:
        """Get current dispute parameters."""
        result = self._call("getParams")
        return DisputeParams(
            min_stake=result[0],
            voting_period=result[1],
            quorum=result[2],
            appeal_threshold=result[3]
        )

    def withdraw_treasury(self, token: EthereumAddress, recipient: EthereumAddress, amount: int) -> TxReceipt:
        """Withdraw funds from the treasury."""
        return self._send_transaction("withdrawTreasury", token, recipient, amount)


class DisputeResolution(BaseContract):
    """Wrapper for the DisputeResolution contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, DISPUTE_RESOLUTION_ABI, w3)

    def resolve_dispute(self, dispute_id: int, outcome: ResolutionOutcome, details_hash: Bytes32) -> TxReceipt:
        """Resolve a dispute with an outcome."""
        return self._send_transaction("resolveDispute", dispute_id, outcome.value, details_hash)

    def execute_resolution(self, dispute_id: int) -> TxReceipt:
        """Execute a resolved dispute."""
        return self._send_transaction("executeResolution", dispute_id)

    def get_resolution(self, dispute_id: int) -> Dict:
        """Get resolution details."""
        result = self._call("getResolution", dispute_id)
        return {
            "outcome": ResolutionOutcome(result[0]),
            "details_hash": result[1],
            "executed": result[2],
        }

    def can_appeal(self, dispute_id: int) -> bool:
        """Check if a dispute can be appealed."""
        return self._call("canAppeal", dispute_id)


class DisputeAppeal(BaseContract):
    """Wrapper for the DisputeAppeal contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, DISPUTE_APPEAL_ABI, w3)

    def file_appeal(self, dispute_id: int, value: int = 0) -> TxReceipt:
        """File an appeal for a dispute."""
        return self._send_transaction("fileAppeal", dispute_id, value=value)

    def resolve_appeal(self, appeal_id: int, status: AppealStatus) -> TxReceipt:
        """Resolve an appeal."""
        return self._send_transaction("resolveAppeal", appeal_id, status.value)

    def get_appeal(self, appeal_id: int) -> Dict:
        """Get appeal details."""
        result = self._call("getAppeal", appeal_id)
        return {
            "appeal_id": result[0],
            "dispute_id": result[1],
            "appellant": result[2],
            "bond": result[3],
            "appealed_at": result[4],
            "status": AppealStatus(result[5]),
        }

    def get_appeals_by_dispute(self, dispute_id: int) -> List[int]:
        """Get all appeals for a dispute."""
        return self._call("getAppealsByDispute", dispute_id)

    def get_appeal_period(self) -> int:
        """Get the appeal period duration."""
        return self._call("getAppealPeriod")

    def get_appeal_bond(self) -> int:
        """Get the required appeal bond."""
        return self._call("getAppealBond")
