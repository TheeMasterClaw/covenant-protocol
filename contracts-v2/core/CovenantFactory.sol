// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantFactory} from "../interfaces/ICovenantFactory.sol";
import {ICovenantRegistry} from "../interfaces/ICovenantRegistry.sol";
import {CovenantProxy} from "./CovenantProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/**
 * @title CovenantFactory
 * @notice Factory for creating deterministic covenant proxies
 */
contract CovenantFactory is ICovenantFactory, Ownable, ReentrancyGuard {
    address public implementation;
    address public registry;

    constructor(address _implementation, address _registry) Ownable(msg.sender) {
        if (_implementation == address(0)) revert InvalidImplementation();
        if (_registry == address(0)) revert InvalidRegistry();
        implementation = _implementation;
        registry = _registry;
    }

    /// @inheritdoc ICovenantFactory
    function createCovenant(bytes32 salt, bytes calldata initData) external nonReentrant returns (address proxy) {
        proxy = _deployProxy(salt, initData);

        address creator = msg.sender;
        uint256 covenantId = ICovenantRegistry(registry).register(proxy, creator);

        (bool success, ) = proxy.call(initData);
        if (!success) revert CovenantCreationFailed();

        emit CovenantCreated(proxy, implementation, creator, salt);
    }

    /// @inheritdoc ICovenantFactory
    function predictCovenantAddress(bytes32 salt, bytes calldata initData) external view returns (address predicted) {
        bytes memory proxyBytecode = abi.encodePacked(
            type(CovenantProxy).creationCode,
            abi.encode(implementation, initData, address(this))
        );
        predicted = Create2.computeAddress(salt, keccak256(proxyBytecode));
    }

    /// @inheritdoc ICovenantFactory
    function setImplementation(address newImplementation) external onlyOwner {
        if (newImplementation == address(0)) revert InvalidImplementation();
        address oldImplementation = implementation;
        implementation = newImplementation;
        emit ImplementationUpdated(oldImplementation, newImplementation);
    }

    /// @inheritdoc ICovenantFactory
    function setRegistry(address newRegistry) external onlyOwner {
        if (newRegistry == address(0)) revert InvalidRegistry();
        address oldRegistry = registry;
        registry = newRegistry;
        emit RegistryUpdated(oldRegistry, newRegistry);
    }

    function _deployProxy(bytes32 salt, bytes calldata initData) internal returns (address proxy) {
        proxy = address(new CovenantProxy{salt: salt}(implementation, initData, address(this)));
    }
}