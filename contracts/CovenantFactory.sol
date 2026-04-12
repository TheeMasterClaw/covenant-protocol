// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./utils/Pausable.sol";
import "./AgentCovenant.sol";

/**
 * @title CovenantFactory
 * @notice Factory for creating new covenant agreements
 * @dev Deploys AgentCovenant instances and tracks them
 * Includes ReentrancyGuard and Pausable for security
 */
contract CovenantFactory is ReentrancyGuard, Pausable {
    
    // ============ State Variables ============
    
    /// @notice Array of all deployed covenants
    address[] public covenants;
    
    /// @notice Mapping from covenant address to creation timestamp
    mapping(address => uint256) public covenantCreationTime;
    
    /// @notice Mapping from agent pair to covenant address
    mapping(bytes32 => address) public agentPairToCovenant;
    
    /// @notice Protocol fee recipient (treasury)
    address public feeRecipient;
    
    /// @notice Protocol fee in basis points (100 = 1%)
    uint256 public protocolFeeBps = 100;
    
    /// @notice Minimum stake required to create covenants (in wei)
    uint256 public minimumStake = 0.01 ether;
    
    /// @notice Contract owner
    address public owner;
    
    // ============ Events ============
    
    event CovenantCreated(
        address indexed covenantAddress,
        address indexed initiator,
        address indexed counterparty,
        bytes32 covenantType,
        uint256 stakeAmount,
        uint256 timestamp
    );
    
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);
    event MinimumStakeUpdated(uint256 oldStake, uint256 newStake);
    
    // ============ Errors ============
    
    error InvalidAgentAddress();
    error CovenantAlreadyExists();
    error InsufficientStake();
    error Unauthorized();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _feeRecipient) {
        if (_feeRecipient == address(0)) revert InvalidAgentAddress();
        owner = msg.sender;
        feeRecipient = _feeRecipient;
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Create a new covenant between two agents
     * @param _counterparty The other agent in the covenant
     * @param _covenantType Type of covenant (TASK, ALLIANCE, ESCROW, etc.)
     * @param _termsIPFSHash IPFS hash of detailed terms
     * @param _duration Duration of the covenant in seconds
     * @return covenantAddress Address of the newly created covenant
     */
    function createCovenant(
        address _counterparty,
        bytes32 _covenantType,
        string calldata _termsIPFSHash,
        uint256 _duration
    ) external payable whenNotPaused nonReentrant returns (address covenantAddress) {
        
        if (_counterparty == address(0) || _counterparty == msg.sender) {
            revert InvalidAgentAddress();
        }
        
        if (msg.value < minimumStake) {
            revert InsufficientStake();
        }
        
        // Check if covenant already exists between these agents
        bytes32 pairHash = keccak256(abi.encodePacked(
            msg.sender < _counterparty ? msg.sender : _counterparty,
            msg.sender < _counterparty ? _counterparty : msg.sender
        ));
        
        if (agentPairToCovenant[pairHash] != address(0)) {
            revert CovenantAlreadyExists();
        }
        
        // Calculate protocol fee
        uint256 protocolFee = (msg.value * protocolFeeBps) / 10000;
        uint256 stakeAmount = msg.value - protocolFee;
        
        // Transfer protocol fee
        (bool feeSuccess, ) = feeRecipient.call{value: protocolFee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Deploy new covenant
        AgentCovenant newCovenant = new AgentCovenant{
            value: stakeAmount
        }(
            msg.sender,
            _counterparty,
            _covenantType,
            _termsIPFSHash,
            _duration,
            stakeAmount,
            feeRecipient,
            protocolFeeBps
        );
        
        covenantAddress = address(newCovenant);
        covenants.push(covenantAddress);
        covenantCreationTime[covenantAddress] = block.timestamp;
        agentPairToCovenant[pairHash] = covenantAddress;
        
        emit CovenantCreated(
            covenantAddress,
            msg.sender,
            _counterparty,
            _covenantType,
            stakeAmount,
            block.timestamp
        );
        
        return covenantAddress;
    }
    
    /**
     * @notice Get total number of covenants created
     */
    function getCovenantCount() external view returns (uint256) {
        return covenants.length;
    }
    
    /**
     * @notice Get all covenants (with pagination)
     * @param _offset Starting index
     * @param _limit Maximum number to return
     */
    function getCovenants(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (address[] memory) 
    {
        uint256 end = _offset + _limit;
        if (end > covenants.length) {
            end = covenants.length;
        }
        
        address[] memory result = new address[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            result[i - _offset] = covenants[i];
        }
        
        return result;
    }
    
    /**
     * @notice Check if a covenant exists between two agents
     */
    function covenantExists(address _agent1, address _agent2) 
        external 
        view 
        returns (bool) 
    {
        bytes32 pairHash = keccak256(abi.encodePacked(
            _agent1 < _agent2 ? _agent1 : _agent2,
            _agent1 < _agent2 ? _agent2 : _agent1
        ));
        return agentPairToCovenant[pairHash] != address(0);
    }
    
    // ============ Admin Functions ============
    
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        emit FeeRecipientUpdated(feeRecipient, _newRecipient);
        feeRecipient = _newRecipient;
    }
    
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee too high"); // Max 10%
        emit ProtocolFeeUpdated(protocolFeeBps, _newFeeBps);
        protocolFeeBps = _newFeeBps;
    }
    
    function setMinimumStake(uint256 _newMinimum) external onlyOwner {
        emit MinimumStakeUpdated(minimumStake, _newMinimum);
        minimumStake = _newMinimum;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}
