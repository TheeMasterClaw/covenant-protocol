"""Utility functions for the COVENANT SDK."""

from web3 import Web3
from eth_utils import is_address, to_checksum_address, keccak as eth_keccak
from eth_abi import encode
from .exceptions import ValidationError
from .types import EthereumAddress


def validate_address(address: str) -> EthereumAddress:
    """Validate and return a checksummed Ethereum address."""
    if not is_address(address):
        raise ValidationError(f"Invalid Ethereum address: {address}")
    return EthereumAddress(to_checksum_address(address))


def validate_bytes32(value: str) -> str:
    """Validate a bytes32 hex string."""
    if not isinstance(value, str) or not value.startswith("0x") or len(value) != 66:
        raise ValidationError(f"Invalid bytes32 value: {value}")
    return value.lower()


def is_valid_address(address: str) -> bool:
    """Check if a string is a valid Ethereum address."""
    return is_address(address)


def to_bytes32(value: str) -> str:
    """Encode a string to bytes32."""
    encoded = encode(["string"], [value])
    padded = encoded.ljust(32, b"\x00")
    return "0x" + padded[:32].hex()


def from_bytes32(value: str) -> str:
    """Decode a bytes32 hex string to a Python string."""
    validate_bytes32(value)
    raw = bytes.fromhex(value[2:])
    return raw.decode("utf-8").replace("\x00", "")


def keccak256(value: str) -> str:
    """Compute keccak256 hash of a string."""
    return "0x" + eth_keccak(text=value).hex()


def parse_ether(value: str) -> int:
    """Convert an ether string to wei."""
    try:
        return Web3.to_wei(value, "ether")
    except Exception as e:
        raise ValidationError(f"Failed to parse ether: {value}", e)


def format_ether(value: int) -> str:
    """Convert wei to an ether string."""
    return Web3.from_wei(value, "ether")


def parse_units(value: str, decimals: int) -> int:
    """Convert a decimal string to wei with the given number of decimals."""
    try:
        return int(float(value) * (10 ** decimals))
    except Exception as e:
        raise ValidationError(f"Failed to parse units: {value}", e)


def format_units(value: int, decimals: int) -> str:
    """Convert wei to a decimal string with the given number of decimals."""
    return str(value / (10 ** decimals))


def encode_initialize_data(creator: str, covenant_id: int, params: bytes) -> str:
    """Encode initialize function data."""
    w3 = Web3()
    return w3.eth.contract(abi=[
        {"type": "function", "name": "initialize", "inputs": [
            {"name": "creator", "type": "address"},
            {"name": "covenantId", "type": "uint256"},
            {"name": "params", "type": "bytes"}
        ]}
    ]).encodeABI(fn_name="initialize", args=[creator, covenant_id, params])


class TxReceipt:
    """Wrapper for transaction receipts with a wait method."""

    def __init__(self, tx_hash: str, w3: Web3):
        self.tx_hash = tx_hash
        self._w3 = w3

    def wait(self) -> dict:
        """Wait for the transaction receipt."""
        receipt = self._w3.eth.wait_for_transaction_receipt(self.tx_hash)
        return dict(receipt)
