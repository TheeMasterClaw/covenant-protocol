// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPassport} from "../../interfaces/IPassport.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title CovenantPassport
 * @notice Gitcoin Passport-style sybil resistance with verifiable credentials
 * @dev Uses Ethereum Attestation Service (EAS) compatible stamps
 */
contract CovenantPassport is IPassport, Ownable, ReentrancyGuard, EIP712 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ============ Constants ============
    
    uint256 public constant MAX_SCORE = 100;
    uint256 public constant THRESHOLD_DEFAULT = 50;
    uint256 public constant STAMP_EXPIRY = 180 days;
    
    // Stamp weights (out of 100)
    uint256 public constant WEIGHT_TWITTER = 15;
    uint256 public constant WEIGHT_GITHUB = 15;
    uint256 public constant WEIGHT_ENS = 10;
    uint256 public constant WEIGHT_POAP = 10;
    uint256 public constant WEIGHT_LENS = 10;
    uint256 public constant WEIGHT_COINBASE = 20;
    uint256 public constant WEIGHT_WORLDCOIN = 25;
    uint256 public constant WEIGHT_GUILD = 5;
    uint256 public constant WEIGHT_BRIGHTID = 20;
    
    // ============ State ============
    
    
    struct Passport {
        Stamp[] stamps;
        uint256 score;
        uint256 lastUpdated;
        bool isVerified;
        uint256 reputationStake; // COVEN staked for score boost
    }
    
    mapping(address => Passport) public passports;
    mapping(bytes32 => bool) public validProviders;
    mapping(bytes32 => uint256) public providerWeights;
    mapping(address => bool) public verifiers;
    mapping(bytes32 => bool) public usedHashes; // Prevent replay attacks
    
    address public covenToken;
    uint256 public verificationThreshold;
    uint256 public reputationBoostRate; // COVEN per point of boost
    
    // Scoring parameters
    uint256 public similarityPenalty; // Penalty for similar passports
    mapping(address => mapping(address => uint256)) public similarityScores;
    
    // ============ Events ============
    
    
    // ============ Errors ============
    
    
    // ============ Constructor ============
    
    constructor(address _covenToken) 
        EIP712("CovenantPassport", "1") 
        Ownable(msg.sender) 
    {
        covenToken = _covenToken;
        verificationThreshold = THRESHOLD_DEFAULT;
        reputationBoostRate = 100e18; // 100 COVEN per boost point
        similarityPenalty = 5000; // 50% penalty for high similarity
        
        // Initialize providers
        _addProvider(keccak256("twitter"), WEIGHT_TWITTER);
        _addProvider(keccak256("github"), WEIGHT_GITHUB);
        _addProvider(keccak256("ens"), WEIGHT_ENS);
        _addProvider(keccak256("poap"), WEIGHT_POAP);
        _addProvider(keccak256("lens"), WEIGHT_LENS);
        _addProvider(keccak256("coinbase"), WEIGHT_COINBASE);
        _addProvider(keccak256("worldcoin"), WEIGHT_WORLDCOIN);
        _addProvider(keccak256("guild"), WEIGHT_GUILD);
        _addProvider(keccak256("brightid"), WEIGHT_BRIGHTID);
    }
    
    // ============ Administration ============
    
    function addProvider(bytes32 provider, uint256 weight) external onlyOwner {
        _addProvider(provider, weight);
    }
    
    function removeProvider(bytes32 provider) external onlyOwner {
        validProviders[provider] = false;
        emit ProviderRemoved(provider);
    }
    
    function addVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }
    
    function removeVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }
    
    function setThreshold(uint256 threshold) external onlyOwner {
        if (threshold > MAX_SCORE) revert InvalidProvider();
        verificationThreshold = threshold;
    }
    
    function setReputationBoostRate(uint256 rate) external onlyOwner {
        reputationBoostRate = rate;
    }
    
    // ============ Stamp Management ============
    
    /**
     * @notice Add a verified stamp to passport
     * @param provider Provider identifier hash
     * @param credentialHash Hash of credential data
     * @param signature Verifier signature
     */
    function addStamp(
        bytes32 provider,
        bytes32 credentialHash,
        bytes calldata signature
    ) external nonReentrant {
        if (!validProviders[provider]) revert InvalidProvider();
        if (usedHashes[credentialHash]) revert HashAlreadyUsed();
        
        // Verify signature from authorized verifier
        bytes32 digest = keccak256(abi.encodePacked(
            msg.sender,
            provider,
            credentialHash,
            block.timestamp / 1 days // Daily nonce
        ));
        address signer = digest.toEthSignedMessageHash().recover(signature);
        if (!verifiers[signer]) revert UnauthorizedVerifier();
        
        usedHashes[credentialHash] = true;
        
        Passport storage passport = passports[msg.sender];
        
        // Check if stamp already exists
        for (uint i = 0; i < passport.stamps.length; i++) {
            if (passport.stamps[i].provider == provider) {
                revert StampAlreadyExists();
            }
        }
        
        passport.stamps.push(Stamp({
            provider: provider,
            issuanceDate: block.timestamp,
            expirationDate: block.timestamp + STAMP_EXPIRY,
            hash: credentialHash,
            verified: true
        }));
        
        _recalculateScore(msg.sender);
        
        emit StampAdded(msg.sender, provider, providerWeights[provider], credentialHash);
    }
    
    /**
     * @notice Remove a stamp from passport
     */
    function removeStamp(bytes32 provider) external {
        Passport storage passport = passports[msg.sender];
        
        for (uint i = 0; i < passport.stamps.length; i++) {
            if (passport.stamps[i].provider == provider) {
                // Remove by swapping with last and popping
                passport.stamps[i] = passport.stamps[passport.stamps.length - 1];
                passport.stamps.pop();
                _recalculateScore(msg.sender);
                emit StampRemoved(msg.sender, provider);
                return;
            }
        }
        
        revert StampNotFound();
    }
    
    /**
     * @notice Batch verify stamps (for initial migration/updates)
     */
    function batchVerifyStamps(
        address[] calldata users,
        bytes32[] calldata providers,
        bytes32[] calldata hashes
    ) external onlyOwner {
        require(users.length == providers.length && providers.length == hashes.length);
        
        for (uint i = 0; i < users.length; i++) {
            if (!validProviders[providers[i]]) continue;
            if (usedHashes[hashes[i]]) continue;
            
            Passport storage passport = passports[users[i]];
            
            passport.stamps.push(Stamp({
                provider: providers[i],
                issuanceDate: block.timestamp,
                expirationDate: block.timestamp + STAMP_EXPIRY,
                hash: hashes[i],
                verified: true
            }));
            
            usedHashes[hashes[i]] = true;
            _recalculateScore(users[i]);
            
            emit StampAdded(users[i], providers[i], providerWeights[providers[i]], hashes[i]);
        }
    }
    
    // ============ Reputation Staking ============
    
    /**
     * @notice Stake COVEN to boost passport score
     */
    function stakeReputation(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidStake();
        
        // Transfer COVEN to this contract
        (bool success, ) = covenToken.call(
            abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount)
        );
        if (!success) revert InvalidStake();
        
        Passport storage passport = passports[msg.sender];
        passport.reputationStake += amount;
        
        // Boost = amount / reputationBoostRate (capped at 20 points)
        uint256 boost = amount / reputationBoostRate;
        if (boost > 20) boost = 20;
        
        _recalculateScore(msg.sender);
        
        emit ReputationStaked(msg.sender, amount, boost);
    }
    
    /**
     * @notice Unstake reputation COVEN
     */
    function unstakeReputation(uint256 amount) external nonReentrant {
        Passport storage passport = passports[msg.sender];
        if (amount > passport.reputationStake) revert InvalidStake();
        
        passport.reputationStake -= amount;
        _recalculateScore(msg.sender);
        
        (bool success, ) = covenToken.call(
            abi.encodeWithSelector(0xa9059cbb, msg.sender, amount)
        );
        if (!success) revert InvalidStake();
        
        emit ReputationUnstaked(msg.sender, amount);
    }
    
    // ============ Score Calculation ============
    
    function _recalculateScore(address user) internal {
        Passport storage passport = passports[user];
        uint256 score = 0;
        
        // Sum valid stamp weights
        for (uint i = 0; i < passport.stamps.length; i++) {
            Stamp storage stamp = passport.stamps[i];
            if (stamp.verified && block.timestamp < stamp.expirationDate) {
                score += providerWeights[stamp.provider];
            }
        }
        
        // Add reputation boost
        uint256 boost = passport.reputationStake / reputationBoostRate;
        if (boost > 20) boost = 20;
        score += boost;
        
        // Cap at MAX_SCORE
        if (score > MAX_SCORE) score = MAX_SCORE;
        
        // Apply similarity penalty (simplified)
        // In production, this would compare credential hashes across users
        
        passport.score = score;
        passport.lastUpdated = block.timestamp;
        passport.isVerified = score >= verificationThreshold;
        
        emit ScoreUpdated(user, score);
        
        if (passport.isVerified) {
            emit PassportVerified(user, score);
        }
    }
    
    // ============ View Functions ============
    
    function getScore(address user) external view returns (uint256) {
        return passports[user].score;
    }
    
    function isVerified(address user) external view returns (bool) {
        return passports[user].isVerified && block.timestamp < _getEarliestExpiry(user);
    }
    
    function getStamps(address user) external view returns (Stamp[] memory) {
        return passports[user].stamps;
    }
    
    function getRewardMultiplier(address user) external view returns (uint256) {
        uint256 score = passports[user].score;
        if (score < verificationThreshold) return 0;
        
        // Quadratic reward curve
        // At threshold: 1x, At max: 2x
        uint256 normalizedScore = (score * 10000) / MAX_SCORE;
        return 10000 + ((normalizedScore * normalizedScore) / 10000);
    }
    
    function _getEarliestExpiry(address user) internal view returns (uint256) {
        Passport storage passport = passports[user];
        uint256 earliest = type(uint256).max;
        
        for (uint i = 0; i < passport.stamps.length; i++) {
            if (passport.stamps[i].expirationDate < earliest) {
                earliest = passport.stamps[i].expirationDate;
            }
        }
        
        return earliest;
    }
    
    function _addProvider(bytes32 provider, uint256 weight) internal {
        validProviders[provider] = true;
        providerWeights[provider] = weight;
        emit ProviderAdded(provider, weight);
    }
}