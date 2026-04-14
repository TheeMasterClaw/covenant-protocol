// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBonding {
    struct BondType {
        address principalToken;
        address quoteToken;
        bool isLpToken;
        uint256 baseDiscount;
        uint256 maxCapacity;
        uint256 capacityUsed;
        uint256 vestingTerm;
        uint256 totalBonded;
        bool active;
        uint256 lpFee;
    }
    
    struct Bond {
        uint256 bondTypeId;
        uint256 principalAmount;
        uint256 covenAmount;
        uint256 vestedAmount;
        uint256 lastClaimTime;
        uint256 vestingEnd;
    }
    
    event BondTypeCreated(uint256 indexed bondTypeId, address principalToken, bool isLpToken, uint256 baseDiscount, uint256 maxCapacity, uint256 vestingTerm);
    event BondDeposited(uint256 indexed bondId, address indexed depositor, uint256 principalAmount, uint256 covenAmount, uint256 discount);
    event BondClaimed(uint256 indexed bondId, address indexed claimant, uint256 amount);
    event PriceUpdated(address indexed token, uint256 price);
    event TreasuryUpdated(address indexed newTreasury);
    event RevenueDeposited(address indexed token, uint256 amount);
    
    error InvalidBondType();
    error BondInactive();
    error InsufficientCapacity();
    error InvalidDiscount();
    error InvalidVestingTerm();
    error NoRewardsToClaim();
    error BondNotMatured();
    error UnauthorizedPriceUpdater();
    
    function addBondType(address principalToken, address quoteToken, bool isLpToken, uint256 baseDiscount, uint256 maxCapacity, uint256 vestingTerm, uint256 lpFee) external returns (uint256 bondTypeId);
    function setBondActive(uint256 bondTypeId, bool active) external;
    function updatePrice(address token, uint256 price) external;
    function deposit(uint256 bondTypeId, uint256 principalAmount, uint256 maxSlippage) external returns (uint256 bondId);
    function claim(uint256 bondId) external returns (uint256 amount);
    function claimAll() external returns (uint256 totalAmount);
    function depositRevenue(address token, uint256 amount) external;
    function bondPrice(uint256 bondTypeId) external view returns (uint256 price);
    function maxPayout(uint256 bondTypeId) external view returns (uint256);
    function claimableAmount(uint256 bondId) external view returns (uint256);
    function getUserBonds(address user) external view returns (uint256[] memory);
    function getBondInfo(uint256 bondId) external view returns (Bond memory);
    function getBondTypeInfo(uint256 bondTypeId) external view returns (BondType memory);
   
    function treasury() external view returns (address);
}
