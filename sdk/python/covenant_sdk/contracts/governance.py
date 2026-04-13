"""Governance contract wrappers."""

from typing import Dict
from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress, Proposal
from ..abis import COVENANT_GOVERNOR_ABI
from ..utils import TxReceipt


class CovenantGovernor(BaseContract):
    """Wrapper for the CovenantGovernor contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, COVENANT_GOVERNOR_ABI, w3)

    def propose(self, target: EthereumAddress, call_data: str, description: str) -> TxReceipt:
        """Create a new governance proposal."""
        return self._send_transaction("propose", target, call_data, description)

    def cast_vote(self, proposal_id: int, support: int) -> TxReceipt:
        """Cast a vote on a proposal."""
        return self._send_transaction("castVote", proposal_id, support)

    def execute(self, proposal_id: int) -> TxReceipt:
        """Execute a passed proposal."""
        return self._send_transaction("execute", proposal_id)

    def get_proposal(self, proposal_id: int) -> Proposal:
        """Get proposal details."""
        result = self._call("getProposal", proposal_id)
        return Proposal(
            id=result[0],
            proposer=result[1],
            description=result[2],
            call_data=result[3],
            target=result[4],
            for_votes=result[5],
            against_votes=result[6],
            abstain_votes=result[7],
            start_time=result[8],
            end_time=result[9],
            executed=result[10],
            canceled=result[11]
        )

    def get_votes(self, account: EthereumAddress) -> int:
        """Get voting power for an account."""
        return self._call("getVotes", account)

    def quorum(self) -> int:
        """Get the quorum requirement."""
        return self._call("quorum")
