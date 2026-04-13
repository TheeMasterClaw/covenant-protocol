// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantProxy
 * @notice Interface for the EIP-1967 proxy used by covenants
 */
interface ICovenantProxy {
    /// @notice Thrown when the caller is not authorized to upgrade the proxy
    error UnauthorizedUpgrade();

    /// @notice Thrown when an invalid implementation is provided
    error InvalidImplementation();

    /**
     * @notice Upgrades the proxy to a new implementation
     * @param newImplementation The address of the new implementation
     * @param data Optional initialization data
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external;

    /**
     * @notice Returns the current implementation address
     * @return The implementation address
     */
    function implementation() external view returns (address);

    /**
     * @notice Returns the admin address responsible for upgrades
     * @return The admin address
     */
    function admin() external view returns (address);

    /**
     * @notice Changes the admin of the proxy
     * @param newAdmin The new admin address
     */
    function changeAdmin(address newAdmin) external;
}
