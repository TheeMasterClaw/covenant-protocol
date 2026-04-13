// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title MockERC20
 * @notice Mock ERC20 token for testing
 */
contract MockERC20 is ERC20, ERC20Permit {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) 
        ERC20(name, symbol) 
        ERC20Permit(name) 
    {
        _decimals = decimals_;
        _mint(msg.sender, 100000000 * 10 ** decimals_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}

/**
 * @title MockReentrancyAttacker
 * @notice Mock contract for testing reentrancy protection
 */
contract MockReentrancyAttacker {
    uint256 public attackCount;
    uint256 public maxAttacks;
    bytes public attackData;

    function setAttackData(bytes calldata data, uint256 max) external {
        attackData = data;
        maxAttacks = max;
    }

    receive() external payable {
        if (attackCount < maxAttacks) {
            attackCount++;
            (bool success,) = msg.sender.call(attackData);
            if (!success) {
                attackCount--;
            }
        }
    }
}

/**
 * @title MockPriceOracle
 * @notice Mock price oracle for testing
 */
contract MockPriceOracle {
    mapping(address => uint256) public prices;
    mapping(address => uint8) public decimals;

    function setPrice(address token, uint256 price, uint8 dec) external {
        prices[token] = price;
        decimals[token] = dec;
    }

    function getPrice(address token) external view returns (uint256) {
        return prices[token];
    }
}

/**
 * @title MockBridge
 * @notice Mock cross-chain bridge for testing
 */
contract MockBridge {
    mapping(uint256 => bool) public supportedChains;
    mapping(bytes32 => bool) public processedMessages;
    
    event MessageSent(uint256 indexed targetChain, address target, bytes data);
    event MessageReceived(uint256 indexed sourceChain, bytes32 indexed messageId);

    function setChainSupported(uint256 chainId, bool supported) external {
        supportedChains[chainId] = supported;
    }

    function sendMessage(uint256 targetChain, address target, bytes calldata data) external {
        require(supportedChains[targetChain], "Chain not supported");
        emit MessageSent(targetChain, target, data);
    }

    function receiveMessage(uint256 sourceChain, bytes32 messageId, bytes calldata data) external {
        require(!processedMessages[messageId], "Already processed");
        processedMessages[messageId] = true;
        emit MessageReceived(sourceChain, messageId);
    }
}
