"""Base contract wrapper class."""

from typing import Any, Optional, Dict, List
from web3 import Web3
from web3.contract import Contract
from eth_typing import ChecksumAddress

from ..types import EthereumAddress, TransactionReceipt
from ..exceptions import ContractCallError, TransactionError
from ..utils import validate_address, TxReceipt


class BaseContract:
    """Base class for all contract wrappers."""

    def __init__(self, address: EthereumAddress, abi: List[Dict], w3: Web3):
        self._w3 = w3
        self._address = validate_address(address)
        self._contract: Contract = w3.eth.contract(
            address=ChecksumAddress(self._address),
            abi=abi
        )

    @property
    def address(self) -> EthereumAddress:
        """Get the contract address."""
        return self._address

    def _call(self, method: str, *args) -> Any:
        """Call a read-only contract method."""
        try:
            func = getattr(self._contract.functions, method)
            return func(*args).call()
        except Exception as e:
            raise ContractCallError(f"Call to {method} failed: {str(e)}", e)

    def _send_transaction(self, method: str, *args, value: int = 0, **kwargs) -> TxReceipt:
        """Send a transaction to the contract."""
        try:
            func = getattr(self._contract.functions, method)
            tx = func(*args)
            tx_hash = tx.transact({"value": value, **kwargs})
            return TxReceipt(tx_hash.hex(), self._w3)
        except Exception as e:
            raise TransactionError(f"Transaction {method} failed: {str(e)}", e)

    def on_event(self, event_name: str, callback, from_block: int = 0):
        """Subscribe to a contract event."""
        event = getattr(self._contract.events, event_name)
        filter_obj = event.create_filter(fromBlock=from_block)
        # Note: In production, you'd use a proper event listener
        return filter_obj
