"""Reputation contract wrappers."""

from typing import Dict
from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress, Bytes32, StakeInfo
from ..abis import REPUTATION_STAKE_ABI
from ..utils import TxReceipt


class ReputationStake(BaseContract):
    """Wrapper for the ReputationStake contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, REPUTATION_STAKE_ABI, w3)

    def stake(self, amount: int, lock_duration: int) -> TxReceipt:
        """Stake reputation tokens."""
        return self._send_transaction("stake", amount, lock_duration)

    def unstake(self, amount: int) -> TxReceipt:
        """Unstake reputation tokens."""
        return self._send_transaction("unstake", amount)

    def slash(self, account: EthereumAddress, amount: int, reason: Bytes32) -> TxReceipt:
        """Slash a user's stake."""
        return self._send_transaction("slash", account, amount, reason)

    def get_stake_info(self, account: EthereumAddress) -> StakeInfo:
        """Get stake information for an account."""
        result = self._call("getStakeInfo", account)
        return StakeInfo(
            amount=result[0],
            staked_at=result[1],
            unlock_time=result[2],
            locked=result[3]
        )

    def total_staked(self) -> int:
        """Get the total amount staked."""
        return self._call("totalStaked")

    def get_stake_token(self) -> EthereumAddress:
        """Get the stake token address."""
        return self._call("getStakeToken")
