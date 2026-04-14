// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICovenantBridge } from "../../interfaces/ICovenantBridge.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC5164Adapter
 * @notice ERC-5164 standard adapter for COVENANT
 * @dev Provides bridge-agnostic messaging following EIP-5164
 *      This adapter wraps any ERC-5164 compliant dispatcher/executor
 *      for standardized cross-chain execution.
 * 
 * Key Features:
 * - Bridge-agnostic architecture
 * - Standardized MessageDispatcher / MessageExecutor interfaces
 * - Future-proof as bridges upgrade
 */
contract ERC5164Adapter is ICovenantBridge, Ownable {
    
    address public immutable dispatcher;
    address public immutable covenantBridge;
    
    mapping(bytes32 => uint256) public messageIdToCovenantId;
    mapping(uint16 => uint256) public covenantToEipChainId;
    mapping(uint256 => uint16) public eipToCovenantChainId;
    
    // Message tracking
    mapping(uint256 => uint8) public messageStatuses;
    
    modifier onlyBridge() {
        require(msg.sender == covenantBridge, "ERC5164: unauthorized");
        _;
    }
    
    constructor(
        address _dispatcher,
        address _covenantBridge,
        address _owner
    ) Ownable(_owner) {
        dispatcher = _dispatcher;
        covenantBridge = _covenantBridge;
        
        // Chain ID mappings
        covenantToEipChainId[1] = 1;        // Ethereum
        covenantToEipChainId[196] = 196;    // X Layer
        covenantToEipChainId[8453] = 8453;  // Base
        covenantToEipChainId[42161] = 42161; // Arbitrum
        covenantToEipChainId[10] = 10;      // Optimism
        
        // Reverse mappings
        eipToCovenantChainId[1] = 1;
        eipToCovenantChainId[196] = 196;
        eipToCovenantChainId[8453] = 8453;
        eipToCovenantChainId[42161] = 42161;
        eipToCovenantChainId[10] = 10;
    }
    
    /**
     * @notice Send message via ERC-5164 dispatcher
     * @param targetChain Covenant chain ID
     * @param payload Message payload
     * @return messageId Unique message identifier
     */
    function sendMessage(
        uint16 targetChain,
        bytes calldata payload
    ) external payable override onlyBridge returns (uint256 messageId) {
        uint256 eipChainId = covenantToEipChainId[targetChain];
        require(eipChainId != 0, "ERC5164: unsupported chain");
        
        // ERC-5164 dispatch (simplified)
        bytes32 dispatchedId = _dispatchMessage(eipChainId, covenantBridge, payload);
        
        messageId = uint256(dispatchedId);
        messageIdToCovenantId[dispatchedId] = messageId;
        messageStatuses[messageId] = 0; // Pending
        
        emit MessageSent(messageId, targetChain, payload);
    }
    
    /**
     * @notice ERC-5164 executor callback
     * @param sourceChainId EIP chain ID of source
     * @param sender Sender address on source chain
     * @param target Target address on destination
     * @param data Message data
     */
    function executeMessage(
        uint256 sourceChainId,
        address sender,
        address target,
        bytes calldata data
    ) external {
        require(sender == covenantBridge, "ERC5164: unauthorized sender");
        require(target == address(this), "ERC5164: invalid target");
        
        uint16 covenantChainId = eipToCovenantChainId[sourceChainId];
        require(covenantChainId != 0, "ERC5164: unknown source chain");
        
        bytes32 messageHash = keccak256(abi.encodePacked(sourceChainId, data));
        uint256 messageId = uint256(messageHash);
        messageStatuses[messageId] = 1; // Delivered
        
        // Forward to CovenantBridge
        (bool success, ) = covenantBridge.call(
            abi.encodeWithSelector(
                ICovenantBridge.receiveMessage.selector,
                covenantChainId,
                data
            )
        );
        require(success, "ERC5164: bridge receive failed");
        
        emit MessageReceived(messageId, covenantChainId, data);
    }
    
    /**
     * @notice Add chain mapping
     * @param covenantChainId Covenant protocol chain ID
     * @param eipChainId EIP-155 chain ID
     */
    function addChainMapping(uint16 covenantChainId, uint256 eipChainId) external onlyOwner {
        covenantToEipChainId[covenantChainId] = eipChainId;
        eipToCovenantChainId[eipChainId] = covenantChainId;
    }
    
    /**
     * @notice Internal dispatch function (placeholder for actual ERC-5164 integration)
     */
    function _dispatchMessage(
        uint256 eipChainId,
        address target,
        bytes calldata data
    ) internal returns (bytes32 messageId) {
        // Actual implementation calls: IERC5164Dispatcher(dispatcher).dispatchMessage(eipChainId, target, data)
        messageId = keccak256(abi.encodePacked(eipChainId, target, data, block.timestamp));
        return messageId;
    }
    
    // Required interface stubs
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external override {}
    function addSupportedChain(uint16 chainId, address adapter) external override {}
    function getMessageStatus(uint256 messageId) external view override returns (uint8) {
        return messageStatuses[messageId];
    }
    
    receive() external payable {}
}
