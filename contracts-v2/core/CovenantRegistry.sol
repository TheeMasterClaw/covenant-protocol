// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantRegistry} from "../interfaces/ICovenantRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CovenantRegistry
 * @notice On-chain registry for covenant instances
 */
contract CovenantRegistry is ICovenantRegistry, Ownable {
    /// @notice The factory address allowed to register covenants
    address public factory;

    /// @notice Counter for covenant IDs
    uint256 private _nextCovenantId;

    /// @notice Mapping from covenant ID to proxy address
    mapping(uint256 => address) private _covenants;

    /// @notice Mapping from proxy address to covenant ID
    mapping(address => uint256) private _covenantIds;

    /// @notice Mapping from creator to their covenant IDs
    mapping(address => uint256[]) private _creatorCovenants;

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    constructor(address _factory) Ownable(msg.sender) {
        if (_factory == address(0)) revert InvalidCovenantId();
        factory = _factory;
        _nextCovenantId = 1;
    }

    /// @inheritdoc ICovenantRegistry
    function register(address proxy, address creator) external onlyFactory returns (uint256 covenantId) {
        if (proxy == address(0) || creator == address(0)) revert InvalidCovenantId();
        if (_covenantIds[proxy] != 0) revert AlreadyRegistered();

        covenantId = _nextCovenantId++;
        _covenants[covenantId] = proxy;
        _covenantIds[proxy] = covenantId;
        _creatorCovenants[creator].push(covenantId);

        emit CovenantRegistered(covenantId, proxy, creator);
    }

    /// @inheritdoc ICovenantRegistry
    function deregister(uint256 covenantId) external onlyFactory {
        address proxy = _covenants[covenantId];
        if (proxy == address(0)) revert CovenantNotFound();

        delete _covenantIds[proxy];
        delete _covenants[covenantId];

        emit CovenantDeregistered(covenantId, proxy);
    }

    /// @inheritdoc ICovenantRegistry
    function getCovenant(uint256 covenantId) external view returns (address) {
        return _covenants[covenantId];
    }

    /// @inheritdoc ICovenantRegistry
    function getCovenantId(address proxy) external view returns (uint256) {
        return _covenantIds[proxy];
    }

    /// @inheritdoc ICovenantRegistry
    function getCovenantsByCreator(address creator) external view returns (uint256[] memory) {
        return _creatorCovenants[creator];
    }

    /// @inheritdoc ICovenantRegistry
    function totalCovenants() external view returns (uint256) {
        return _nextCovenantId - 1;
    }

    /**
     * @notice Updates the factory address
     * @param newFactory The new factory address
     */
    function setFactory(address newFactory) external onlyOwner {
        if (newFactory == address(0)) revert InvalidCovenantId();
        factory = newFactory;
    }
}