// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantImplementation
 * @notice Interface for the main covenant implementation logic
 */
interface ICovenantImplementation {
    /// @notice Emitted when the covenant is initialized
    event CovenantInitialized(address indexed factory, address indexed creator, uint256 indexed covenantId);

    /// @notice Emitted when the covenant state changes
    event CovenantStateChanged(uint8 indexed oldState, uint8 indexed newState);

    /// @notice Thrown when the covenant is already initialized
    error AlreadyInitialized();

    /// @notice Thrown when the caller is not authorized
    error Unauthorized();

    /// @notice Thrown when an invalid state transition is attempted
    error InvalidStateTransition();

    enum CovenantState {
        Draft,
        Active,
        Paused,
        Resolved,
        Terminated
    }

    /**
     * @notice Initializes the covenant with the provided parameters
     * @param creator The creator of the covenant
     * @param covenantId The unique identifier for the covenant
     * @param params Encoded initialization parameters
     */
    function initialize(address creator, uint256 covenantId, bytes calldata params) external;

    /**
     * @notice Activates the covenant
     */
    function activate() external;

    /**
     * @notice Pauses the covenant
     */
    function pause() external;

    /**
     * @notice Resolves the covenant
     */
    function resolve() external;

    /**
     * @notice Terminates the covenant
     */
    function terminate() external;

    /**
     * @notice Returns the current state of the covenant
     * @return The current state
     */
    function state() external view returns (CovenantState);

    /**
     * @notice Returns the creator of the covenant
     * @return The creator address
     */
    function creator() external view returns (address);

    /**
     * @notice Returns the unique covenant identifier
     * @return The covenant ID
     */
    function covenantId() external view returns (uint256);
}
