"""Tokenomics contract wrappers."""

from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress
from ..abis import ERC20_ABI
from ..utils import TxReceipt


class ERC20(BaseContract):
    """Wrapper for ERC20 token contracts."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, ERC20_ABI, w3)

    def name(self) -> str:
        """Get the token name."""
        return self._call("name")

    def symbol(self) -> str:
        """Get the token symbol."""
        return self._call("symbol")

    def decimals(self) -> int:
        """Get the token decimals."""
        return self._call("decimals")

    def total_supply(self) -> int:
        """Get the total token supply."""
        return self._call("totalSupply")

    def balance_of(self, account: EthereumAddress) -> int:
        """Get the balance of an account."""
        return self._call("balanceOf", account)

    def transfer(self, recipient: EthereumAddress, amount: int) -> TxReceipt:
        """Transfer tokens to a recipient."""
        return self._send_transaction("transfer", recipient, amount)

    def allowance(self, owner: EthereumAddress, spender: EthereumAddress) -> int:
        """Get the allowance of a spender."""
        return self._call("allowance", owner, spender)

    def approve(self, spender: EthereumAddress, amount: int) -> TxReceipt:
        """Approve a spender."""
        return self._send_transaction("approve", spender, amount)

    def transfer_from(self, sender: EthereumAddress, recipient: EthereumAddress, amount: int) -> TxReceipt:
        """Transfer tokens from a sender to a recipient."""
        return self._send_transaction("transferFrom", sender, recipient, amount)
