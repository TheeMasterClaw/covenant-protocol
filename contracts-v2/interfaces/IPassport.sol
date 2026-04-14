// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPassport {
    struct Stamp {
        bytes32 provider;
        uint256 issuanceDate;
        uint256 expirationDate;
        bytes32 hash;
        bool verified;
    }
    
    event StampAdded(address indexed user, bytes32 indexed provider, uint256 weight, bytes32 hash);
    event StampRemoved(address indexed user, bytes32 indexed provider);
    event PassportVerified(address indexed user, uint256 score);
    event ScoreUpdated(address indexed user, uint256 newScore);
    event ProviderAdded(bytes32 indexed provider, uint256 weight);
    event ProviderRemoved(bytes32 indexed provider);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event ReputationStaked(address indexed user, uint256 amount, uint256 boost);
    event ReputationUnstaked(address indexed user, uint256 amount);
    
    error InvalidProvider();
    error StampAlreadyExists();
    error StampNotFound();
    error StampExpired();
    error InvalidSignature();
    error HashAlreadyUsed();
    error UnauthorizedVerifier();
    error InsufficientScore();
    error InvalidStake();
    
    function addStamp(bytes32 provider, bytes32 credentialHash, bytes calldata signature) external;
    function removeStamp(bytes32 provider) external;
    function stakeReputation(uint256 amount) external;
    function unstakeReputation(uint256 amount) external;
    function getScore(address user) external view returns (uint256);
    function isVerified(address user) external view returns (bool);
    function getStamps(address user) external view returns (Stamp[] memory);
    function getRewardMultiplier(address user) external view returns (uint256);
}
