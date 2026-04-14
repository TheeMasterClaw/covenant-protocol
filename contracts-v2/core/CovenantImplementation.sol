// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantImplementation} from "../interfaces/ICovenantImplementation.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantImplementation
 * @notice Main covenant logic implementation
 */
contract CovenantImplementation is ICovenantImplementation, Initializable, Pausable, ReentrancyGuard {
    address public factory;
    address public creator;
    uint256 public covenantId;
    CovenantState public state;
    bytes32 public metadataHash;
    uint256 public createdAt;

    modifier onlyFactory() {
        if (msg.sender != factory) revert Unauthorized();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert Unauthorized();
        _;
    }

    modifier validTransition(CovenantState newState) {
        if (!_isValidTransition(state, newState)) revert InvalidStateTransition();
        _;
    }

    function initialize(address _creator, uint256 _covenantId, bytes calldata params) external initializer {
        if (_creator == address(0)) revert Unauthorized();
        factory = msg.sender;
        creator = _creator;
        covenantId = _covenantId;
        state = CovenantState.Draft;
        createdAt = block.timestamp;

        if (params.length >= 32) {
            metadataHash = bytes32(params[0:32]);
        }

        emit CovenantInitialized(factory, creator, covenantId);
    }

    /// @inheritdoc ICovenantImplementation
    function activate() external onlyCreator validTransition(CovenantState.Active) whenNotPaused {
        CovenantState oldState = state;
        state = CovenantState.Active;
        emit CovenantStateChanged(uint8(oldState), uint8(state));
    }

    /// @inheritdoc ICovenantImplementation
    function pause() external onlyCreator {
        _pause();
        CovenantState oldState = state;
        state = CovenantState.Paused;
        emit CovenantStateChanged(uint8(oldState), uint8(state));
    }

    /// @inheritdoc ICovenantImplementation
    function resolve() external onlyCreator validTransition(CovenantState.Resolved) whenNotPaused {
        CovenantState oldState = state;
        state = CovenantState.Resolved;
        emit CovenantStateChanged(uint8(oldState), uint8(state));
    }

    /// @inheritdoc ICovenantImplementation
    function terminate() external onlyFactory validTransition(CovenantState.Terminated) {
        CovenantState oldState = state;
        state = CovenantState.Terminated;
        emit CovenantStateChanged(uint8(oldState), uint8(state));
    }

    function unpause() external onlyCreator {
        _unpause();
        if (state == CovenantState.Paused) {
            CovenantState oldState = state;
            state = CovenantState.Active;
            emit CovenantStateChanged(uint8(oldState), uint8(state));
        }
    }

    function _isValidTransition(CovenantState from, CovenantState to) internal pure returns (bool) {
        if (from == CovenantState.Draft) return to == CovenantState.Active || to == CovenantState.Terminated;
        if (from == CovenantState.Active) return to == CovenantState.Paused || to == CovenantState.Resolved || to == CovenantState.Terminated;
        if (from == CovenantState.Paused) return to == CovenantState.Active || to == CovenantState.Resolved || to == CovenantState.Terminated;
        if (from == CovenantState.Resolved) return to == CovenantState.Terminated;
        return false;
    }

    receive() external payable {}
    fallback() external payable {}
}