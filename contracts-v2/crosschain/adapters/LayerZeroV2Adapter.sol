// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICovenantBridge } from "../../interfaces/ICovenantBridge.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LayerZeroV2Adapter
 * @notice LayerZero v2 integration for COVENANT cross-chain messaging
 * @dev Implements ICovenantBridge interface for standardized messaging
 *      Reference: https://layerzero.network/v2
 * 
 * Key Features:
 * - DVN (Decentralized Verifier Network) support for agent attestations
 * - M-of-N verification for high-value reputation transfers
 * - Native support for Ethereum, X Layer, Base, Arbitrum, Optimism
 * 
 * Chain Mappings:
 * - Ethereum: 30101
 * - X Layer: 30274
 * - Base: 30184
 * - Arbitrum: 30110
 * - Optimism: 30111
 */
contract LayerZeroV2Adapter is ICovenantBridge, Ownable {
    
    // LayerZero Endpoint V2 interface
    address public immutable lzEndpoint;
    address public immutable covenantBridge;
    
    // Chain ID mappings: Covenant chain ID => LayerZero EID
    mapping(uint16 => uint32) public lzChainIds;
    mapping(uint32 => uint16) public covenantChainIds;
    
    // DVN configuration for security levels
    struct DVNConfig {
        address[] requiredDVNs;
        address[] optionalDVNs;
        uint8 optionalDVNThreshold;
        uint64 confirmations;
    }
    mapping(uint16 => DVNConfig) public dvnConfigs;
    
    // Message tracking
    mapping(uint256 => uint8) public messageStatuses;
    mapping(bytes32 => uint256) public lzGuidToMessageId;
    
    // Events
    event DVNConfigUpdated(uint16 indexed chainId, uint256 requiredDVNCount, uint256 optionalDVNCount);
    
    modifier onlyBridge() {
        require(msg.sender == covenantBridge, "LZAdapter: unauthorized");
        _;
    }
    
    constructor(
        address _lzEndpoint,
        address _covenantBridge,
        address _owner
    ) Ownable(_owner) {
        lzEndpoint = _lzEndpoint;
        covenantBridge = _covenantBridge;
        
        // Initialize chain mappings
        lzChainIds[1] = 30101;      // Ethereum
        lzChainIds[196] = 30274;    // X Layer
        lzChainIds[8453] = 30184;   // Base
        lzChainIds[42161] = 30110;  // Arbitrum
        lzChainIds[10] = 30111;     // Optimism
        
        // Reverse mappings
        covenantChainIds[30101] = 1;
        covenantChainIds[30274] = 196;
        covenantChainIds[30184] = 8453;
        covenantChainIds[30110] = 42161;
        covenantChainIds[30111] = 10;
    }
    
    /**
     * @notice Send message via LayerZero v2
     * @param targetChain Covenant chain ID
     * @param payload Message payload (encoded agent attestation/reputation data)
     * @return messageId Unique message identifier
     */
    function sendMessage(
        uint16 targetChain,
        bytes calldata payload
    ) external payable override onlyBridge returns (uint256 messageId) {
        uint32 lzEid = lzChainIds[targetChain];
        require(lzEid != 0, "LZAdapter: unsupported chain");
        
        // Build messaging params with DVN options
        bytes memory options = _buildDVNOptions(targetChain, payload.length);
        
        // Encode receiver address
        bytes memory receiver = abi.encodePacked(covenantBridge);
        
        // Quote fee
        (uint256 nativeFee, ) = quoteMessage(targetChain, payload);
        require(msg.value >= nativeFee, "LZAdapter: insufficient fee");
        
        // Send via LayerZero (simplified - actual implementation uses LZ libraries)
        bytes32 guid = _sendViaLayerZero(lzEid, receiver, payload, options, nativeFee);
        
        messageId = uint256(guid);
        lzGuidToMessageId[guid] = messageId;
        messageStatuses[messageId] = 0; // Pending
        
        emit MessageSent(messageId, targetChain, payload);
        
        // Refund excess
        if (msg.value > nativeFee) {
            payable(msg.sender).transfer(msg.value - nativeFee);
        }
    }
    
    /**
     * @notice Receive message from LayerZero (called by LZ Endpoint)
     * @param origin Origin information from LayerZero
     * @param guid Message GUID
     * @param message Message payload
     */
    function lzReceive(
        Origin calldata origin,
        bytes32 guid,
        bytes calldata message,
        address executor,
        bytes calldata extraData
    ) external payable {
        require(msg.sender == lzEndpoint, "LZAdapter: unauthorized endpoint");
        
        uint16 sourceChain = covenantChainIds[origin.srcEid];
        require(sourceChain != 0, "LZAdapter: unsupported source");
        require(origin.sender == bytes32(uint256(uint160(covenantBridge))), "LZAdapter: unauthorized sender");
        
        uint256 messageId = lzGuidToMessageId[guid];
        if (messageId == 0) {
            messageId = uint256(guid);
            lzGuidToMessageId[guid] = messageId;
        }
        
        messageStatuses[messageId] = 1; // Delivered
        
        // Forward to CovenantBridge
        (bool success, ) = covenantBridge.call(
            abi.encodeWithSelector(
                ICovenantBridge.receiveMessage.selector,
                sourceChain,
                message
            )
        );
        require(success, "LZAdapter: bridge receive failed");
        
        emit MessageReceived(messageId, sourceChain, message);
    }
    
    /**
     * @notice Quote fee for cross-chain message
     * @param targetChain Covenant chain ID
     * @param payload Message payload
     * @return nativeFee Fee in native token
     * @return lzTokenFee Fee in LZ token (usually 0)
     */
    function quoteMessage(
        uint16 targetChain,
        bytes calldata payload
    ) public view returns (uint256 nativeFee, uint256 lzTokenFee) {
        uint32 lzEid = lzChainIds[targetChain];
        require(lzEid != 0, "LZAdapter: unsupported chain");
        
        // Simplified quoting - actual implementation calls LZ endpoint
        bytes memory options = _buildDVNOptions(targetChain, payload.length);
        
        // Base fee + calldata fee + DVN verification fee
        uint256 baseFee = 0.001 ether;
        uint256 calldataFee = payload.length * 20 gwei;
        uint256 dvnFee = dvnConfigs[targetChain].requiredDVNs.length * 0.0005 ether;
        
        nativeFee = baseFee + calldataFee + dvnFee;
        lzTokenFee = 0;
    }
    
    /**
     * @notice Set DVN configuration for a chain
     * @param chainId Covenant chain ID
     * @param config DVN configuration struct
     */
    function setDVNConfig(uint16 chainId, DVNConfig calldata config) external onlyOwner {
        require(lzChainIds[chainId] != 0, "LZAdapter: unsupported chain");
        dvnConfigs[chainId] = config;
        emit DVNConfigUpdated(chainId, config.requiredDVNs.length, config.optionalDVNs.length);
    }
    
    /**
     * @notice Build DVN options for message execution
     */
    function _buildDVNOptions(uint16 targetChain, uint256 payloadLength) internal view returns (bytes memory) {
        // Options format: executor gas + DVN threshold config
        // Default: 200k gas for execution
        uint256 gasLimit = 200000;
        
        // Pack options (simplified - actual LZ v2 uses specific encoding)
        return abi.encodePacked(
            uint16(1), // option type: executor gas
            gasLimit,
            dvnConfigs[targetChain].confirmations
        );
    }
    
    /**
     * @notice Internal send function (placeholder for actual LZ integration)
     */
    function _sendViaLayerZero(
        uint32 dstEid,
        bytes memory receiver,
        bytes calldata message,
        bytes memory options,
        uint256 nativeFee
    ) internal returns (bytes32 guid) {
        // Actual implementation calls: lzEndpoint.send{value: nativeFee}(...)
        // This is a placeholder returning deterministic guid
        guid = keccak256(abi.encodePacked(dstEid, receiver, message, block.timestamp));
        return guid;
    }
    
    // Required interface stubs
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external override {}
    function addSupportedChain(uint16 chainId, address adapter) external override {}
    function getMessageStatus(uint256 messageId) external view override returns (uint8) {
        return messageStatuses[messageId];
    }
    
    // Origin struct for LayerZero v2
    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }
    
    receive() external payable {}
}
