// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantRegistry
 * @notice Interface for the CovenantRegistry contract
 */
interface ICovenantRegistry {
    /// @notice Emitted when a covenant is registered
    event CovenantRegistered(uint256 indexed covenantId, address indexed proxy, address indexed creator);

    /// @notice Emitted when a covenant is deregistered
    event CovenantDeregistered(uint256 indexed covenantId, address indexed proxy);

    /// @notice Thrown when the caller is not the factory
    error OnlyFactory();

    /// @notice Thrown when a covenant is already registered
    error AlreadyRegistered();

    /// @notice Thrown when a covenant is not found
    error CovenantNotFound();

    /// @notice Thrown when an invalid ID is provided
    error InvalidCovenantId();

    /**
     * @notice Registers a new covenant in the registry
     * @param proxy The address of the covenant proxy
     * @param creator The address of the covenant creator
     * @return covenantId The unique identifier assigned to the covenant
     */
    function register(address proxy, address creator) external returns (uint256 covenantId);

    /**
     * @notice Deregisters a covenant from the registry
     * @param covenantId The unique identifier of the covenant
     */
    function deregister(uint256 covenantId) external;

    /**
     * @notice Returns the covenant proxy address for a given ID
     * @param covenantId The unique identifier of the covenant
     * @return The proxy address
     */
    function getCovenant(uint256 covenantId) external view returns (address);

    /**
     * @notice Returns the covenant ID for a given proxy address
     * @param proxy The proxy address
     * @return The covenant ID
     */
    function getCovenantId(address proxy) external view returns (uint256);

    /**
     * @notice Returns all covenant IDs created by a specific address
     * @param creator The creator address
     * @return An array of covenant IDs
     */
    function getCovenantsByCreator(address creator) external view returns (uint256[] memory);

    /**
     * @notice Returns the total number of registered covenants
     * @return The total count
     */
    function totalCovenants() external view returns (uint256);

    /**
     * @notice Returns the factory address
     * @return The factory address
     */
    function factory() external view returns (address);
}
