// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts-optimized/OptimizedCovenantFactory.sol";
import "./ComplianceRegistry.sol";

/**
 * @title VerifiedCovenantFactory
 * @notice Covenant factory requiring compliance credentials for institutional/verified pools
 * @dev Extends OptimizedCovenantFactory with on-chain compliance checks
 */
contract VerifiedCovenantFactory is OptimizedCovenantFactory {
    
    ComplianceRegistry public complianceRegistry;
    uint256 public travelRuleThreshold = 1000 * 10**18; // e.g., $1000 equivalent
    
    event TravelRuleEnforced(address indexed initiator, address indexed counterparty, uint256 amount);
    
    constructor(
        address _implementation,
        address _feeRecipient,
        address _complianceRegistry
    ) OptimizedCovenantFactory(_implementation, _feeRecipient) {
        complianceRegistry = ComplianceRegistry(_complianceRegistry);
    }
    
    function createCovenant(
        address _counterparty,
        bytes32 _covenantType,
        string calldata _termsIPFSHash,
        uint256 _duration
    ) external payable override returns (address covenantAddress) {
        
        // Both parties must be compliant
        require(
            complianceRegistry.isCompliant(msg.sender),
            "Initiator not compliant"
        );
        require(
            complianceRegistry.isCompliant(_counterparty),
            "Counterparty not compliant"
        );
        
        // Travel Rule check for high-value covenants
        if (msg.value >= travelRuleThreshold) {
            require(
                complianceRegistry.isTravelRuleCompliant(msg.sender),
                "Travel Rule required"
            );
            require(
                complianceRegistry.isTravelRuleCompliant(_counterparty),
                "Counterparty Travel Rule required"
            );
            
            emit TravelRuleEnforced(msg.sender, _counterparty, msg.value);
        }
        
        return super.createCovenant(
            _counterparty,
            _covenantType,
            _termsIPFSHash,
            _duration
        );
    }
    
    function setTravelRuleThreshold(uint256 _newThreshold) external onlyOwner {
        travelRuleThreshold = _newThreshold;
    }
    
    function setComplianceRegistry(address _newRegistry) external onlyOwner {
        complianceRegistry = ComplianceRegistry(_newRegistry);
    }
}
