// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ComplianceRegistry
 * @notice Stores on-chain compliance attestations without PII
 * @dev Only authorized oracle addresses can update statuses
 */
contract ComplianceRegistry {
    
    struct ComplianceStatus {
        bool sanctionsClear;
        bool kycVerified;
        bool travelRuleCompliant;
        uint8 riskScore;        // 0-100
        uint40 expiry;          // Unix timestamp
        uint16 jurisdiction;    // ISO 3166-1 numeric code
        bool isActive;
    }
    
    mapping(address => ComplianceStatus) public statuses;
    mapping(address => bool) public authorizedOracles;
    mapping(bytes32 => bool) public usedNullifiers;
    
    address public admin;
    
    event StatusUpdated(address indexed user, uint8 riskScore, uint40 expiry);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    
    modifier onlyOracle() {
        require(authorizedOracles[msg.sender], "Not authorized oracle");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function updateStatus(
        address _user,
        ComplianceStatus calldata _status
    ) external onlyOracle {
        require(_status.expiry > block.timestamp, "Expired status");
        statuses[_user] = _status;
        emit StatusUpdated(_user, _status.riskScore, _status.expiry);
    }
    
    function updateStatusWithZKProof(
        address _user,
        ComplianceStatus calldata _status,
        bytes32 _nullifierHash,
        bytes calldata /* _zkProof */
    ) external onlyOracle {
        require(!usedNullifiers[_nullifierHash], "Nullifier reused");
        require(_status.expiry > block.timestamp, "Expired status");
        
        // ZK proof verification would be delegated to verifier contract
        // require(zkVerifier.verify(_zkProof, ...), "Invalid proof");
        
        usedNullifiers[_nullifierHash] = true;
        statuses[_user] = _status;
        emit StatusUpdated(_user, _status.riskScore, _status.expiry);
    }
    
    function isCompliant(address _user) external view returns (bool) {
        ComplianceStatus memory s = statuses[_user];
        return s.isActive && 
               s.sanctionsClear && 
               s.kycVerified && 
               s.expiry > block.timestamp &&
               s.riskScore <= 50; // Medium risk or lower
    }
    
    function isTravelRuleCompliant(address _user) external view returns (bool) {
        ComplianceStatus memory s = statuses[_user];
        return s.isActive && s.travelRuleCompliant && s.expiry > block.timestamp;
    }
    
    function addOracle(address _oracle) external onlyAdmin {
        authorizedOracles[_oracle] = true;
        emit OracleAdded(_oracle);
    }
    
    function removeOracle(address _oracle) external onlyAdmin {
        authorizedOracles[_oracle] = false;
        emit OracleRemoved(_oracle);
    }
    
    function transferAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }
}
