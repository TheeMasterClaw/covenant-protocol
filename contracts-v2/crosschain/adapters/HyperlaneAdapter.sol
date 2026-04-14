// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICovenantBridge } from "../../interfaces/ICovenantBridge.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title HyperlaneAdapter
 * @notice Hyperlane integration for COVENANT cross-chain messaging
 * @dev Lower cost option for high-frequency agent attestations
 *      Reference: https://docs.hyperlane.xyz
 * 
 * Key Features:
 * - Permissionless deployment to X Layer and other chains
 * - ISM (Interchain Security Module) flexibility for custom verification
 * - Lowest cost for high-frequency agent attestations
 * - Supports Ethereum, X Layer, Base, Arbitrum, Optimism
 */
contract HyperlaneAdapter is ICovenantBridge, Ownable {
    
    address public immutable mailbox;
    address public immutable covenantBridge;
    address public interchainSecurityModule;
    
    // Hyperlane domain mapping (Hyperlane uses uint32 domain IDs)
    mapping(uint16 => uint32) public hyperlaneDomains;
    mapping(uint32 => uint16) public covenantChainIds;
    
    // Message tracking
    mapping(uint256 => uint8) public messageStatuses;
    mapping(bytes32 => uint256) public hyperlaneIdToMessageId;
    
    // Events
    event ISMUpdated(address indexed ism);
    
    modifier onlyBridge() {
        require(msg.sender == covenantBridge, "Hyperlane: unauthorized");
        _;
    }
    
    constructor(
        address _mailbox,
        address _covenantBridge,
        address _owner
    ) Ownable(_owner) {
        mailbox = _mailbox;
        covenantBridge = _covenantBridge;
        
        // Initialize domain mappings
        hyperlaneDomains[1] = 1;        // Ethereum
        hyperlaneDomains[196] = 196;    // X Layer
        hyperlaneDomains[8453] = 8453;  // Base
        hyperlaneDomains[42161] = 42161; // Arbitrum
        hyperlaneDomains[10] = 10;      // Optimism
        
        // Reverse mappings
        covenantChainIds[1] = 1;
        covenantChainIds[196] = 196;
        covenantChainIds[8453] = 8453;
        covenantChainIds[42161] = 42161;
        covenantChainIds[10] = 10;
    }
    
    /**
     * @notice Send message via Hyperlane mailbox
     * @param targetChain Covenant chain ID
     * @param payload Message payload (encoded agent attestation/reputation data)
     * @return messageId Unique message identifier
     */
    function sendMessage(
        uint16 targetChain,
        bytes calldata payload
    ) external payable override onlyBridge returns (uint256 messageId) {
        uint32 destination = hyperlaneDomains[targetChain];
        require(destination != 0, "Hyperlane: unsupported chain");
        
        // Quote dispatch fee
        uint256 fee = quoteMessage(targetChain, payload);
        require(msg.value >= fee, "Hyperlane: insufficient fee");
        
        bytes32 recipient = _addressToBytes32(covenantBridge);
        
        // Dispatch message via Hyperlane mailbox (simplified)
        bytes32 hyperlaneId = _dispatchHyperlane(destination, recipient, payload, fee);
        
        messageId = uint256(hyperlaneId);
        hyperlaneIdToMessageId[hyperlaneId] = messageId;
        messageStatuses[messageId] = 0; // Pending
        
        emit MessageSent(messageId, targetChain, payload);
        
        // Refund excess
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }
    
    /**
     * @notice Handle message from Hyperlane (called by Mailbox)
     * @param origin Domain ID of source chain
     * @param sender Address of sender on source chain
     * @param message Message payload
     */
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external payable {
        require(msg.sender == mailbox, "Hyperlane: unauthorized mailbox");
        require(_bytes32ToAddress(sender) == covenantBridge, "Hyperlane: unauthorized sender");
        
        uint16 sourceChain = covenantChainIds[origin];
        require(sourceChain != 0, "Hyperlane: unsupported origin");
        
        bytes32 messageHash = keccak256(abi.encodePacked(origin, message));
        uint256 messageId = uint256(messageHash);
        messageStatuses[messageId] = 1; // Delivered
        
        // Forward to CovenantBridge
        (bool success, ) = covenantBridge.call(
            abi.encodeWithSelector(
                ICovenantBridge.receiveMessage.selector,
                sourceChain,
                message
            )
        );
        require(success, "Hyperlane: bridge receive failed");
        
        emit MessageReceived(messageId, sourceChain, message);
    }
    
    /**
     * @notice Quote fee for Hyperlane dispatch
     * @param targetChain Covenant chain ID
     * @param payload Message payload
     * @return fee Fee in native token
     */
    function quoteMessage(
        uint16 targetChain,
        bytes calldata payload
    ) public view returns (uint256 fee) {
        uint32 destination = hyperlaneDomains[targetChain];
        require(destination != 0, "Hyperlane: unsupported chain");
        
        // Hyperlane fees are typically very low
        // Base fee + calldata overhead
        uint256 baseFee = 0.0001 ether;
        uint256 calldataFee = payload.length * 5 gwei;
        
        return baseFee + calldataFee;
    }
    
    /**
     * @notice Set custom ISM for agent verification
     * @param _ism Address of the Interchain Security Module
     */
    function setInterchainSecurityModule(address _ism) external onlyOwner {
        interchainSecurityModule = _ism;
        emit ISMUpdated(_ism);
    }
    
    /**
     * @notice Add support for a new chain
     * @param covenantChainId Covenant protocol chain ID
     * @param hyperlaneDomain Hyperlane domain ID
     */
    function addChainMapping(uint16 covenantChainId, uint32 hyperlaneDomain) external onlyOwner {
        hyperlaneDomains[covenantChainId] = hyperlaneDomain;
        covenantChainIds[hyperlaneDomain] = covenantChainId;
    }
    
    /**
     * @notice Internal dispatch function (placeholder for actual Hyperlane integration)
     */
    function _dispatchHyperlane(
        uint32 destination,
        bytes32 recipient,
        bytes calldata message,
        uint256 fee
    ) internal returns (bytes32 messageId) {
        // Actual implementation calls: mailbox.dispatch{value: fee}(destination, recipient, message)
        messageId = keccak256(abi.encodePacked(destination, recipient, message, block.timestamp));
        return messageId;
    }
    
    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
    
    function _bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
    
    // Required interface stubs
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external override {}
    function addSupportedChain(uint16 chainId, address adapter) external override {}
    function getMessageStatus(uint256 messageId) external view override returns (uint8) {
        return messageStatuses[messageId];
    }
    
    receive() external payable {}
}
