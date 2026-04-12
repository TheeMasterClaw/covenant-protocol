// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Pausable
 * @notice Emergency pause functionality for critical operations
 * @dev Contracts can inherit from this to pause/unpause functionality
 */
abstract contract Pausable {
    bool public paused;
    address public pauser;
    
    event Paused(address account);
    event Unpaused(address account);
    event PauserTransferred(address indexed previousPauser, address indexed newPauser);
    
    error ContractPaused();
    error ContractNotPaused();
    error NotPauser();
    
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }
    
    modifier whenPaused() {
        if (!paused) revert ContractNotPaused();
        _;
    }
    
    modifier onlyPauser() {
        if (msg.sender != pauser) revert NotPauser();
        _;
    }
    
    constructor() {
        pauser = msg.sender;
    }
    
    function pause() public virtual onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public virtual onlyPauser whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    function transferPauser(address newPauser) public virtual onlyPauser {
        require(newPauser != address(0), "Invalid pauser address");
        address oldPauser = pauser;
        pauser = newPauser;
        emit PauserTransferred(oldPauser, newPauser);
    }
}
