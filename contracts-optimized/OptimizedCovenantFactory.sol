// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title OptimizedCovenantFactory
 * @notice Gas-optimized factory using CREATE2 + minimal proxies (EIP-1167)
 * @dev Reduces deployment cost by ~50% compared to full contract deployment
 */
contract OptimizedCovenantFactory {
    
    // ============ State Variables ============
    
    address[] public covenants;
    mapping(address => uint40) public covenantCreationTime;
    mapping(bytes32 => address) public agentPairToCovenant;
    
    address public immutable implementation;
    address public feeRecipient;
    address public owner;
    
    uint16 public protocolFeeBps = 100;
    uint128 public minimumStake = 0.01 ether;
    uint256 private saltCounter;
    
    // ============ Events ============
    
    event CovenantCreated(
        address indexed covenantAddress,
        address indexed initiator,
        address indexed counterparty,
        bytes32 covenantType,
        uint128 stakeAmount,
        uint40 timestamp
    );
    
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
    
    constructor(address _implementation, address _feeRecipient) {
        if (_feeRecipient == address(0)) revert InvalidAgentAddress();
        if (_implementation == address(0)) revert InvalidAgentAddress();
        implementation = _implementation;
        owner = msg.sender;
        feeRecipient = _feeRecipient;
    }
    
    // ============ External Functions ============
    
    function createCovenant(
        address _counterparty,
        bytes32 _covenantType,
        string calldata _termsIPFSHash,
        uint256 _duration
    ) external payable returns (address covenantAddress) {
        
        if (_counterparty == address(0) || _counterparty == msg.sender) {
            revert InvalidAgentAddress();
        }
        
        if (msg.value < minimumStake) {
            revert InsufficientStake();
        }
        
        bytes32 pairHash = keccak256(abi.encodePacked(
            msg.sender < _counterparty ? msg.sender : _counterparty,
            msg.sender < _counterparty ? _counterparty : msg.sender
        ));
        
        if (agentPairToCovenant[pairHash] != address(0)) {
            revert CovenantAlreadyExists();
        }
        
        uint128 protocolFee = uint128((msg.value * protocolFeeBps) / 10000);
        uint128 stakeAmount = uint128(msg.value) - protocolFee;
        
        // Transfer protocol fee
        (bool feeSuccess, ) = feeRecipient.call{value: protocolFee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Deploy minimal proxy using CREATE2
        bytes32 salt = bytes32(++saltCounter);
        covenantAddress = Clones.cloneDeterministic(implementation, salt);
        
        // Initialize with value
        IInitializable(payable(covenantAddress)).initialize{value: stakeAmount}(
            msg.sender,
            _counterparty,
            _covenantType,
            _termsIPFSHash,
            _duration,
            stakeAmount,
            feeRecipient,
            protocolFeeBps
        );
        
        covenants.push(covenantAddress);
        covenantCreationTime[covenantAddress] = uint40(block.timestamp);
        agentPairToCovenant[pairHash] = covenantAddress;
        
        emit CovenantCreated(
            covenantAddress,
            msg.sender,
            _counterparty,
            _covenantType,
            stakeAmount,
            uint40(block.timestamp)
        );
        
        return covenantAddress;
    }
    
    function predictCovenantAddress(uint256 _salt) external view returns (address) {
        return Clones.predictDeterministicAddress(
            implementation,
            bytes32(_salt),
            address(this)
        );
    }
    
    function getCovenantCount() external view returns (uint256) {
        return covenants.length;
    }
    
    function getCovenants(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (address[] memory) 
    {
        uint256 end = _offset + _limit;
        uint256 len = covenants.length;
        if (end > len) {
            end = len;
        }
        if (_offset >= end) {
            return new address[](0);
        }
        
        address[] memory result = new address[](end - _offset);
        unchecked {
            for (uint256 i = _offset; i < end; ++i) {
                result[i - _offset] = covenants[i];
            }
        }
        
        return result;
    }
    
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
        feeRecipient = _newRecipient;
    }
    
    function setProtocolFee(uint16 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee too high");
        protocolFeeBps = _newFeeBps;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

interface IInitializable {
    function initialize(
        address _initiator,
        address _counterparty,
        bytes32 _covenantType,
        string calldata _termsIPFSHash,
        uint256 _duration,
        uint128 _stakeAmount,
        address _feeRecipient,
        uint16 _protocolFeeBps
    ) external payable;
}
