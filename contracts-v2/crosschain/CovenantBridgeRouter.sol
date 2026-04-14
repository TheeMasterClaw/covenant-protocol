// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICovenantBridge } from "../interfaces/ICovenantBridge.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantBridgeRouter
 * @notice Router for selecting optimal bridge adapter based on message value and urgency
 * @dev Implements value-at-risk based routing for cost/optimization
 * 
 * Routing Strategy:
 * - High value (>$1000): LayerZero v2 (3+ DVNs)
 * - Medium value ($100-1000): LayerZero v2 (2 DVNs) or Axelar
 * - Low value (<$100): Hyperlane (lowest cost)
 * - Time-critical: Across Protocol intent-based
 * - Maximum redundancy: Multi-bridge dispatch
 */
contract CovenantBridgeRouter is ICovenantBridge, Ownable, ReentrancyGuard {
    
    enum BridgeType { NONE, LAYERZERO, HYPERLANE, AXELAR, WORMHOLE, ERC5164 }
    
    struct BridgeInfo {
        address adapter;
        BridgeType bridgeType;
        uint256 minValue;
        uint256 maxValue;
        bool active;
    }
    
    mapping(uint16 => mapping(BridgeType => BridgeInfo)) public chainBridges;
    mapping(uint16 => BridgeType[]) public chainBridgePriority;
    
    address public covenantBridge;
    uint256 public defaultBridgeThreshold;
    
    // Value tiers for routing (in wei)
    uint256 public constant LOW_VALUE_MAX = 0.1 ether;     // <$300
    uint256 public constant MEDIUM_VALUE_MAX = 1 ether;     // <$3000
    uint256 public constant HIGH_VALUE_MAX = 10 ether;      // <$30000
    
    event BridgeRegistered(uint16 indexed chainId, BridgeType bridgeType, address adapter);
    event BridgeDeregistered(uint16 indexed chainId, BridgeType bridgeType);
    event MessageRouted(uint256 indexed messageId, uint16 targetChain, BridgeType bridgeType, uint256 value);
    
    modifier onlyCovenantBridge() {
        require(msg.sender == covenantBridge, "Router: unauthorized");
        _;
    }
    
    constructor(address _covenantBridge, address _owner) Ownable(_owner) {
        covenantBridge = _covenantBridge;
        defaultBridgeThreshold = 0.5 ether;
    }
    
    /**
     * @notice Route message to optimal bridge based on value
     * @param targetChain Destination chain ID
     * @param payload Message payload
     * @return messageId Unique message identifier
     */
    function routeMessage(
        uint16 targetChain,
        bytes calldata payload
    ) external payable nonReentrant returns (uint256 messageId) {
        return _routeByValue(targetChain, payload, msg.value);
    }
    
    /**
     * @notice Route message with explicit value specification
     * @param targetChain Destination chain ID
     * @param payload Message payload
     * @param valueAtRisk Value at risk for routing decision
     * @return messageId Unique message identifier
     */
    function routeMessageWithValue(
        uint16 targetChain,
        bytes calldata payload,
        uint256 valueAtRisk
    ) external payable nonReentrant returns (uint256 messageId) {
        return _routeByValue(targetChain, payload, valueAtRisk);
    }
    
    /**
     * @notice Route to specific bridge (admin override)
     * @param targetChain Destination chain ID
     * @param payload Message payload
     * @param bridgeType Specific bridge to use
     * @return messageId Unique message identifier
     */
    function routeToBridge(
        uint16 targetChain,
        bytes calldata payload,
        BridgeType bridgeType
    ) external payable onlyOwner nonReentrant returns (uint256 messageId) {
        BridgeInfo memory info = chainBridges[targetChain][bridgeType];
        require(info.active, "Router: bridge not active");
        
        return _sendViaBridge(targetChain, payload, info);
    }
    
    /**
     * @notice Send message via all active bridges (maximum redundancy)
     * @param targetChain Destination chain ID
     * @param payload Message payload
     * @return messageIds Array of message IDs from each bridge
     */
    function routeViaAllBridges(
        uint16 targetChain,
        bytes calldata payload
    ) external payable onlyOwner nonReentrant returns (uint256[] memory messageIds) {
        BridgeType[] storage bridges = chainBridgePriority[targetChain];
        messageIds = new uint256[](bridges.length);
        
        uint256 valuePerBridge = msg.value / bridges.length;
        
        for (uint i = 0; i < bridges.length; i++) {
            BridgeInfo memory info = chainBridges[targetChain][bridges[i]];
            if (info.active) {
                messageIds[i] = _sendViaBridge(targetChain, payload, info);
            }
        }
    }
    
    /**
     * @notice Internal routing logic based on value
     */
    function _routeByValue(
        uint16 targetChain,
        bytes calldata payload,
        uint256 valueAtRisk
    ) internal returns (uint256 messageId) {
        BridgeType selectedBridge;
        
        if (valueAtRisk <= LOW_VALUE_MAX) {
            selectedBridge = BridgeType.HYPERLANE; // Lowest cost
        } else if (valueAtRisk <= MEDIUM_VALUE_MAX) {
            selectedBridge = BridgeType.LAYERZERO; // Balanced
        } else {
            selectedBridge = BridgeType.AXELAR; // Higher security
        }
        
        // Check if preferred bridge is active, fall back if not
        BridgeInfo memory info = chainBridges[targetChain][selectedBridge];
        if (!info.active) {
            selectedBridge = _findFallbackBridge(targetChain);
            info = chainBridges[targetChain][selectedBridge];
        }
        
        require(info.active, "Router: no active bridge");
        
        return _sendViaBridge(targetChain, payload, info);
    }
    
    /**
     * @notice Send message via specific bridge adapter
     */
    function _sendViaBridge(
        uint16 targetChain,
        bytes calldata payload,
        BridgeInfo memory info
    ) internal returns (uint256 messageId) {
        // Forward to adapter with all received value
        (bool success, bytes memory returnData) = info.adapter.call{value: msg.value}(
            abi.encodeWithSelector(
                ICovenantBridge.sendMessage.selector,
                targetChain,
                payload
            )
        );
        
        require(success, "Router: bridge send failed");
        
        // Parse messageId from return data
        messageId = abi.decode(returnData, (uint256));
        
        emit MessageRouted(messageId, targetChain, info.bridgeType, msg.value);
    }
    
    /**
     * @notice Find fallback bridge if primary is inactive
     */
    function _findFallbackBridge(uint16 targetChain) internal view returns (BridgeType) {
        BridgeType[] storage bridges = chainBridgePriority[targetChain];
        
        for (uint i = 0; i < bridges.length; i++) {
            if (chainBridges[targetChain][bridges[i]].active) {
                return bridges[i];
            }
        }
        
        return BridgeType.NONE;
    }
    
    /**
     * @notice Register bridge adapter for a chain
     * @param chainId Target chain ID
     * @param bridgeType Type of bridge
     * @param adapter Adapter contract address
     * @param minValue Minimum value for this bridge
     * @param maxValue Maximum value for this bridge
     */
    function registerBridge(
        uint16 chainId,
        BridgeType bridgeType,
        address adapter,
        uint256 minValue,
        uint256 maxValue
    ) external onlyOwner {
        require(adapter != address(0), "Router: invalid adapter");
        
        chainBridges[chainId][bridgeType] = BridgeInfo({
            adapter: adapter,
            bridgeType: bridgeType,
            minValue: minValue,
            maxValue: maxValue,
            active: true
        });
        
        // Add to priority list if not already there
        BridgeType[] storage bridges = chainBridgePriority[chainId];
        bool exists = false;
        for (uint i = 0; i < bridges.length; i++) {
            if (bridges[i] == bridgeType) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            bridges.push(bridgeType);
        }
        
        emit BridgeRegistered(chainId, bridgeType, adapter);
    }
    
    /**
     * @notice Deregister bridge adapter
     */
    function deregisterBridge(uint16 chainId, BridgeType bridgeType) external onlyOwner {
        chainBridges[chainId][bridgeType].active = false;
        emit BridgeDeregistered(chainId, bridgeType);
    }
    
    /**
     * @notice Set default bridge threshold
     */
    function setDefaultThreshold(uint256 threshold) external onlyOwner {
        defaultBridgeThreshold = threshold;
    }
    
    /**
     * @notice Get active bridges for a chain
     */
    function getActiveBridges(uint16 chainId) external view returns (BridgeType[] memory) {
        BridgeType[] storage allBridges = chainBridgePriority[chainId];
        uint256 activeCount = 0;
        
        for (uint i = 0; i < allBridges.length; i++) {
            if (chainBridges[chainId][allBridges[i]].active) {
                activeCount++;
            }
        }
        
        BridgeType[] memory active = new BridgeType[](activeCount);
        uint256 idx = 0;
        for (uint i = 0; i < allBridges.length; i++) {
            if (chainBridges[chainId][allBridges[i]].active) {
                active[idx++] = allBridges[i];
            }
        }
        
        return active;
    }
    
    // Required interface stubs
    function sendMessage(uint16 targetChain, bytes calldata payload) external payable override returns (uint256) {
        return this.routeMessage{value: msg.value}(targetChain, payload);
    }
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external override {}
    function addSupportedChain(uint16 chainId, address adapter) external override {}
    function getMessageStatus(uint256 messageId) external view override returns (uint8) { return 0; }
    
    receive() external payable {}
}
