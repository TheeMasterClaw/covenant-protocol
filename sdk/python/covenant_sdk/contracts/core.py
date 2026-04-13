"""Core contract wrappers."""

from typing import List
from web3 import Web3

from .base import BaseContract
from ..types import EthereumAddress, Bytes32
from ..abis import COVENANT_FACTORY_ABI, COVENANT_REGISTRY_ABI
from ..utils import TxReceipt


class CovenantFactory(BaseContract):
    """Wrapper for the CovenantFactory contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, COVENANT_FACTORY_ABI, w3)

    def create_covenant(self, salt: Bytes32, init_data: str, value: int = 0) -> TxReceipt:
        """Create a new covenant proxy."""
        return self._send_transaction("createCovenant", salt, init_data, value=value)

    def predict_covenant_address(self, salt: Bytes32, init_data: str) -> EthereumAddress:
        """Predict the address of a covenant proxy before deployment."""
        return self._call("predictCovenantAddress", salt, init_data)

    def implementation(self) -> EthereumAddress:
        """Get the current implementation address."""
        return self._call("implementation")

    def registry(self) -> EthereumAddress:
        """Get the registry address."""
        return self._call("registry")

    def set_implementation(self, new_implementation: EthereumAddress) -> TxReceipt:
        """Update the implementation address."""
        return self._send_transaction("setImplementation", new_implementation)

    def set_registry(self, new_registry: EthereumAddress) -> TxReceipt:
        """Update the registry address."""
        return self._send_transaction("setRegistry", new_registry)


class CovenantRegistry(BaseContract):
    """Wrapper for the CovenantRegistry contract."""

    def __init__(self, address: EthereumAddress, w3: Web3):
        super().__init__(address, COVENANT_REGISTRY_ABI, w3)

    def register(self, proxy: EthereumAddress, creator: EthereumAddress) -> TxReceipt:
        """Register a new covenant in the registry."""
        return self._send_transaction("register", proxy, creator)

    def deregister(self, covenant_id: int) -> TxReceipt:
        """Deregister a covenant from the registry."""
        return self._send_transaction("deregister", covenant_id)

    def get_covenant(self, covenant_id: int) -> EthereumAddress:
        """Get the covenant proxy address for a given ID."""
        return self._call("getCovenant", covenant_id)

    def get_covenant_id(self, proxy: EthereumAddress) -> int:
        """Get the covenant ID for a given proxy address."""
        return self._call("getCovenantId", proxy)

    def get_covenants_by_creator(self, creator: EthereumAddress) -> List[int]:
        """Get all covenant IDs created by a specific address."""
        return self._call("getCovenantsByCreator", creator)

    def total_covenants(self) -> int:
        """Get the total number of registered covenants."""
        return self._call("totalCovenants")

    def factory(self) -> EthereumAddress:
        """Get the factory address."""
        return self._call("factory")
