"""Main COVENANT SDK class."""

from web3 import Web3
from eth_account import Account
from typing import Optional

from .types import SdkConfig, ContractAddresses, EthereumAddress
from .exceptions import ProviderError
from .utils import validate_address
from .contracts import (
    CovenantFactory,
    CovenantRegistry,
    TaskMarket,
    DisputeDAO,
    DisputeResolution,
    DisputeAppeal,
    ReputationStake,
    CovenantGovernor,
    ERC20,
)


class CovenantSDK:
    """Main SDK class for interacting with COVENANT Protocol."""

    def __init__(self, config: SdkConfig):
        self.config = config
        self._w3 = Web3(Web3.HTTPProvider(config.rpc_url))
        
        if not self._w3.is_connected():
            raise ProviderError(f"Failed to connect to {config.rpc_url}")
        
        # Set up account if private key provided
        self._account: Optional[Account] = None
        if config.private_key:
            self._account = Account.from_key(config.private_key)
            self._w3.eth.default_account = self._account.address

        # Initialize contracts
        addrs = config.contract_addresses
        self.covenant_factory = CovenantFactory(addrs.covenant_factory, self._w3)
        self.covenant_registry = CovenantRegistry(addrs.covenant_registry, self._w3)
        self.task_market = TaskMarket(addrs.task_market, self._w3)
        self.dispute_dao = DisputeDAO(addrs.dispute_dao, self._w3)
        self.dispute_resolution = DisputeResolution(addrs.dispute_resolution, self._w3)
        self.dispute_appeal = DisputeAppeal(addrs.dispute_appeal, self._w3)
        self.reputation_stake = ReputationStake(addrs.reputation_stake, self._w3)
        self.covenant_governor = CovenantGovernor(addrs.covenant_governor, self._w3)

    @property
    def w3(self) -> Web3:
        """Get the Web3 instance."""
        return self._w3

    def get_address(self) -> str:
        """Get the connected account address."""
        if not self._account:
            raise ProviderError("No private key configured")
        return self._account.address

    def get_balance(self, address: Optional[str] = None) -> int:
        """Get the balance of an address."""
        addr = address or self.get_address()
        return self._w3.eth.get_balance(addr)

    def get_block_number(self) -> int:
        """Get the current block number."""
        return self._w3.eth.block_number

    def get_chain_id(self) -> int:
        """Get the chain ID."""
        return self._w3.eth.chain_id

    def get_erc20(self, address: EthereumAddress) -> ERC20:
        """Get an ERC20 token contract wrapper."""
        return ERC20(validate_address(address), self._w3)
