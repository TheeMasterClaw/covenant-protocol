// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantFactory
 * @notice Interface for the CovenantFactory contract
 */
interface ICovenantFactory {
    /// @notice Emitted when a new covenant proxy is deployed
    event CovenantCreated(address indexed proxy, address indexed implementation, address indexed creator, bytes32 salt);

    /// @notice Emitted when the implementation is updated
    event ImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when the registry is updated
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry);

    /// @notice Thrown when an invalid implementation is provided
    error InvalidImplementation();

    /// @notice Thrown when an invalid registry is provided
    error InvalidRegistry();

    /// @notice Thrown when an invalid initializer is provided
    error InvalidInitializer();

    /// @notice Thrown when a covenant creation fails
    error CovenantCreationFailed();

    /**
     * @notice Creates a new covenant proxy with the provided salt and initialization data
     * @param salt The salt used for deterministic deployment
     * @param initData The initialization data for the covenant
     * @return proxy The address of the deployed proxy
     */
    function createCovenant(bytes32 salt, bytes calldata initData) external returns (address proxy);

    /**
     * @notice Predicts the address of a covenant proxy before deployment
     * @param salt The salt used for deterministic deployment
     * @param initData The initialization data for the covenant
     * @return predicted The predicted address of the proxy
     */
    function predictCovenantAddress(bytes32 salt, bytes calldata initData) external view returns (address predicted);

    /**
     * @notice Returns the current implementation address
     * @return The implementation address
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns the registry address
     * @return The registry address
     */
    function registry() external view returns (address);

    /**
     * @notice Updates the implementation address
     * @param newImplementation The new implementation address
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice Updates the registry address
     * @param newRegistry The new registry address
     */
    function setRegistry(address newRegistry) external;
}
