"""Exception classes for the COVENANT SDK."""


class CovenantSDKError(Exception):
    """Base exception for all COVENANT SDK errors."""

    def __init__(self, message: str, code: str = "UNKNOWN", cause: Exception = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.cause = cause


class ContractCallError(CovenantSDKError):
    """Raised when a smart contract call fails."""

    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message, "CONTRACT_CALL_ERROR", cause)


class TransactionError(CovenantSDKError):
    """Raised when a transaction fails."""

    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message, "TRANSACTION_ERROR", cause)


class ValidationError(CovenantSDKError):
    """Raised when input validation fails."""

    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message, "VALIDATION_ERROR", cause)


class InsufficientFundsError(CovenantSDKError):
    """Raised when there are insufficient funds for a transaction."""

    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message, "INSUFFICIENT_FUNDS_ERROR", cause)


class ProviderError(CovenantSDKError):
    """Raised when provider connection fails."""

    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message, "PROVIDER_ERROR", cause)
