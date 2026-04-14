// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantProxy} from "../interfaces/ICovenantProxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

/**
 * @title CovenantProxy
 * @notice EIP-1967 proxy for covenant instances
 */
contract CovenantProxy is ICovenantProxy, Proxy {
    error ProxyAlreadyInitialized();

    /// @notice The admin address responsible for upgrades
    address public immutable admin;

    constructor(address _logic, bytes memory _data, address _admin) payable {
        if (_admin == address(0)) revert InvalidImplementation();
        admin = _admin;
        ERC1967Utils.upgradeToAndCall(_logic, _data);
    }

    /// @inheritdoc ICovenantProxy
    function upgradeToAndCall(address newImplementation, bytes calldata data) external {
        if (msg.sender != admin) revert UnauthorizedUpgrade();
        if (newImplementation == address(0)) revert InvalidImplementation();
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    /// @inheritdoc ICovenantProxy
    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @inheritdoc ICovenantProxy
    function changeAdmin(address newAdmin) external {
        if (msg.sender != admin) revert UnauthorizedUpgrade();
        if (newAdmin == address(0)) revert InvalidImplementation();
        ERC1967Utils.changeAdmin(newAdmin);
    }

    /**
     * @dev Returns the current implementation address
     */
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /// @notice Fallback to delegate calls to the implementation
    receive() external payable {
        _fallback();
    }
}