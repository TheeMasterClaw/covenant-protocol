// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBonding} from "../../interfaces/IBonding.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CovenantBonding
 * @notice OlympusDAO-style bonding for protocol-owned liquidity
 * @dev Supports liquidity bonds, reserve bonds, and revenue bonds
 */
contract CovenantBonding is IBonding, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Constants ============
    
    uint256 public constant PRICE_PRECISION = 1e6;
    uint256 public constant BOND_PRECISION = 10000;
    uint256 public constant MAX_DISCOUNT = 2500;    // 25% max discount
    uint256 public constant MIN_DISCOUNT = 500;     // 5% min discount
    uint256 public constant VESTING_PRECISION = 1e6;
    
    // ============ State ============
    
    IERC20 public immutable covenToken;
    address public treasury;
    
    struct BondType {
        address principalToken;     // Token accepted for bond
        address quoteToken;         // Paired token for LP bonds (address(0) for reserves)
        bool isLpToken;             // Whether principal is an LP token
        uint256 baseDiscount;       // Base discount in basis points
        uint256 maxCapacity;        // Max principal accepted
        uint256 capacityUsed;       // Principal already bonded
        uint256 vestingTerm;        // Vesting duration in seconds
        uint256 totalBonded;        // Total bonds of this type
        bool active;                // Whether this bond type is active
        uint256 lpFee;              // LP fee tier (for pricing)
    }
    
    struct Bond {
        uint256 bondTypeId;         // Which bond type
        uint256 principalAmount;    // Amount of principal deposited
        uint256 covenAmount;        // Total COVEN to be received
        uint256 vestedAmount;       // Amount already vested/claimed
        uint256 lastClaimTime;      // Last claim timestamp
        uint256 vestingEnd;         // When vesting completes
    }
    
    mapping(uint256 => BondType) public bondTypes;
    mapping(uint256 => Bond) public bonds;
    mapping(address => uint256[]) public userBonds;
    
    uint256 public nextBondTypeId;
    uint256 public nextBondId;
    uint256 public totalBondedValue;    // Total protocol-owned value
    
    // Pricing oracles (simplified - in production use Chainlink/AMM)
    mapping(address => uint256) public tokenPrices; // Price in USD, 6 decimals
    mapping(address => bool) public priceUpdaters;
    
    // Revenue bond integration
    mapping(address => uint256) public accumulatedRevenue;
    address[] public revenueTokens;
    
    // ============ Events ============
    
    event BondTypeCreated(
        uint256 indexed bondTypeId,
        address principalToken,
        bool isLpToken,
        uint256 baseDiscount,
        uint256 maxCapacity,
        uint256 vestingTerm
    );
    event BondDeposited(
        uint256 indexed bondId,
        address indexed depositor,
        uint256 principalAmount,
        uint256 covenAmount,
        uint256 discount
    );
    event BondClaimed(
        uint256 indexed bondId,
        address indexed claimant,
        uint256 amount
    );
    event PriceUpdated(address indexed token, uint256 price);
    event TreasuryUpdated(address indexed newTreasury);
    event RevenueDeposited(address indexed token, uint256 amount);
    
    // ============ Errors ============
    
    error InvalidBondType();
    error BondInactive();
    error InsufficientCapacity();
    error InvalidDiscount();
    error InvalidVestingTerm();
    error NoRewardsToClaim();
    error BondNotMatured();
    error UnauthorizedPriceUpdater();
    
    // ============ Constructor ============
    
    function coven() external view returns (address) {
        return address(covenToken);
    }

    constructor(address _coven, address _treasury) Ownable(msg.sender) {
        covenToken = IERC20(_coven);
        treasury = _treasury;
        nextBondTypeId = 1;
        nextBondId = 1;
        priceUpdaters[msg.sender] = true;
    }
    
    // ============ Administration ============
    
    function addBondType(
        address principalToken,
        address quoteToken,
        bool isLpToken,
        uint256 baseDiscount,
        uint256 maxCapacity,
        uint256 vestingTerm,
        uint256 lpFee
    ) external onlyOwner returns (uint256 bondTypeId) {
        if (baseDiscount < MIN_DISCOUNT || baseDiscount > MAX_DISCOUNT) revert InvalidDiscount();
        if (vestingTerm < 1 days || vestingTerm > 30 days) revert InvalidVestingTerm();
        
        bondTypeId = nextBondTypeId++;
        bondTypes[bondTypeId] = BondType({
            principalToken: principalToken,
            quoteToken: quoteToken,
            isLpToken: isLpToken,
            baseDiscount: baseDiscount,
            maxCapacity: maxCapacity,
            capacityUsed: 0,
            vestingTerm: vestingTerm,
            totalBonded: 0,
            active: true,
            lpFee: lpFee
        });
        
        emit BondTypeCreated(bondTypeId, principalToken, isLpToken, baseDiscount, maxCapacity, vestingTerm);
    }
    
    function setBondActive(uint256 bondTypeId, bool active) external onlyOwner {
        bondTypes[bondTypeId].active = active;
    }
    
    function updatePrice(address token, uint256 price) external {
        if (!priceUpdaters[msg.sender]) revert UnauthorizedPriceUpdater();
        tokenPrices[token] = price;
        emit PriceUpdated(token, price);
    }
    
    function addPriceUpdater(address updater) external onlyOwner {
        priceUpdaters[updater] = true;
    }
    
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }
    
    // ============ Bonding Functions ============
    
    /**
     * @notice Deposit principal tokens to receive discounted COVEN
     * @param bondTypeId The type of bond
     * @param principalAmount Amount of principal to deposit
     * @param maxSlippage Max acceptable discount decrease in bps
     * @return bondId The created bond ID
     */
    function deposit(
        uint256 bondTypeId,
        uint256 principalAmount,
        uint256 maxSlippage
    ) external nonReentrant returns (uint256 bondId) {
        BondType storage bt = bondTypes[bondTypeId];
        if (bt.principalToken == address(0)) revert InvalidBondType();
        if (!bt.active) revert BondInactive();
        if (principalAmount == 0) revert InsufficientCapacity();
        if (bt.capacityUsed + principalAmount > bt.maxCapacity) revert InsufficientCapacity();
        
        // Calculate bond price and COVEN payout
        (uint256 bondPrice, uint256 covenAmount, uint256 discount) = _calculateBondPayout(
            bondTypeId,
            principalAmount
        );
        
        // Check slippage
        uint256 expectedDiscount = bt.baseDiscount;
        if (discount < expectedDiscount - maxSlippage) revert InvalidDiscount();
        
        bondId = nextBondId++;
        bonds[bondId] = Bond({
            bondTypeId: bondTypeId,
            principalAmount: principalAmount,
            covenAmount: covenAmount,
            vestedAmount: 0,
            lastClaimTime: block.timestamp,
            vestingEnd: block.timestamp + bt.vestingTerm
        });
        
        userBonds[msg.sender].push(bondId);
        bt.capacityUsed += principalAmount;
        bt.totalBonded += principalAmount;
        
        // Calculate value in USD for tracking
        uint256 principalValue = (principalAmount * tokenPrices[bt.principalToken]) / PRICE_PRECISION;
        if (bt.isLpToken) {
            principalValue = principalValue * 2; // LP tokens represent 2x value
        }
        totalBondedValue += principalValue;
        
        // Transfer principal from user
        IERC20(bt.principalToken).safeTransferFrom(msg.sender, treasury, principalAmount);
        
        emit BondDeposited(bondId, msg.sender, principalAmount, covenAmount, discount);
    }
    
    /**
     * @notice Claim vested COVEN from a bond
     */
    function claim(uint256 bondId) external nonReentrant returns (uint256 amount) {
        Bond storage bond = bonds[bondId];
        if (bond.covenAmount == 0) revert InvalidBondType();
        if (!_isBondOwner(bondId)) revert UnauthorizedPriceUpdater();
        
        amount = _claimableAmount(bondId);
        if (amount == 0) revert NoRewardsToClaim();
        
        bond.vestedAmount += amount;
        bond.lastClaimTime = block.timestamp;
        
        coven.safeTransfer(msg.sender, amount);
        
        emit BondClaimed(bondId, msg.sender, amount);
    }
    
    /**
     * @notice Claim all vested COVEN across all user bonds
     */
    function claimAll() external nonReentrant returns (uint256 totalAmount) {
        uint256[] memory userBondIds = userBonds[msg.sender];
        
        for (uint i = 0; i < userBondIds.length; i++) {
            uint256 amount = _claimableAmount(userBondIds[i]);
            if (amount > 0) {
                Bond storage bond = bonds[userBondIds[i]];
                bond.vestedAmount += amount;
                bond.lastClaimTime = block.timestamp;
                totalAmount += amount;
                emit BondClaimed(userBondIds[i], msg.sender, amount);
            }
        }
        
        if (totalAmount == 0) revert NoRewardsToClaim();
        coven.safeTransfer(msg.sender, totalAmount);
    }
    
    /**
     * @notice Deposit revenue for revenue bonds
     */
    function depositRevenue(address token, uint256 amount) external {
        if (amount == 0) return;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        accumulatedRevenue[token] += amount;
        emit RevenueDeposited(token, amount);
    }
    
    /**
     * @notice Create a revenue bond using accumulated protocol revenue
     * @dev Converts revenue directly to COVEN for strategic buyers
     */
    function createRevenueBond(
        address revenueToken,
        uint256 revenueAmount,
        uint256 covenAmount
    ) external onlyOwner {
        if (accumulatedRevenue[revenueToken] < revenueAmount) revert InsufficientCapacity();
        accumulatedRevenue[revenueToken] -= revenueAmount;
        
        // Revenue bonds go to treasury as reserves
        IERC20(revenueToken).safeTransfer(treasury, revenueAmount);
        
        // COVEN is minted/transferred for revenue bond buyer
        // In production, this would be a specific buyer address
    }
    
    // ============ View Functions ============
    
    function bondPrice(uint256 bondTypeId) external view returns (uint256 price) {
        (price,,) = _calculateBondPayout(bondTypeId, 1e18);
    }
    
    function maxPayout(uint256 bondTypeId) external view returns (uint256) {
        BondType storage bt = bondTypes[bondTypeId];
        uint256 remainingCapacity = bt.maxCapacity - bt.capacityUsed;
        (,uint256 payout,) = _calculateBondPayout(bondTypeId, remainingCapacity);
        return payout;
    }
    
    function claimableAmount(uint256 bondId) external view returns (uint256) {
        return _claimableAmount(bondId);
    }
    
    function getUserBonds(address user) external view returns (uint256[] memory) {
        return userBonds[user];
    }
    
    function getBondInfo(uint256 bondId) external view returns (Bond memory) {
        return bonds[bondId];
    }
    
    function getBondTypeInfo(uint256 bondTypeId) external view returns (BondType memory) {
        return bondTypes[bondTypeId];
    }
    
    // ============ Internal Functions ============
    
    function _calculateBondPayout(
        uint256 bondTypeId,
        uint256 principalAmount
    ) internal view returns (uint256 bondPrice, uint256 covenAmount, uint256 discount) {
        BondType storage bt = bondTypes[bondTypeId];
        
        // Get market price of COVEN in principal token terms
        uint256 covenUsdPrice = tokenPrices[address(coven)];
        uint256 principalUsdPrice = tokenPrices[bt.principalToken];
        
        if (covenUsdPrice == 0 || principalUsdPrice == 0) {
            return (0, 0, 0);
        }
        
        // Principal value in USD
        uint256 principalValue = (principalAmount * principalUsdPrice) / PRICE_PRECISION;
        
        // For LP tokens, value is 2x (both sides of pool)
        if (bt.isLpToken) {
            principalValue = principalValue * 2;
        }
        
        // Dynamic discount based on capacity utilization
        uint256 utilization = (bt.capacityUsed * BOND_PRECISION) / bt.maxCapacity;
        discount = bt.baseDiscount - ((bt.baseDiscount - MIN_DISCOUNT) * utilization) / BOND_PRECISION;
        
        // Bond price = market price * (1 - discount)
        uint256 marketPrice = (covenUsdPrice * PRICE_PRECISION) / principalUsdPrice;
        bondPrice = (marketPrice * (BOND_PRECISION - discount)) / BOND_PRECISION;
        
        // COVEN amount = principal value / bond price
        covenAmount = (principalValue * PRICE_PRECISION) / (bondPrice > 0 ? bondPrice : 1);
        
        // Adjust for decimals
        uint256 principalDecimals = IERC20Metadata(bt.principalToken).decimals();
        uint256 covenDecimals = IERC20Metadata(address(covenToken)).decimals();
        if (principalDecimals > covenDecimals) {
            covenAmount = covenAmount / (10 ** (principalDecimals - covenDecimals));
        } else if (covenDecimals > principalDecimals) {
            covenAmount = covenAmount * (10 ** (covenDecimals - principalDecimals));
        }
    }
    
    function _claimableAmount(uint256 bondId) internal view returns (uint256) {
        Bond storage bond = bonds[bondId];
        if (bond.covenAmount == 0) return 0;
        if (bond.vestedAmount >= bond.covenAmount) return 0;
        if (block.timestamp >= bond.vestingEnd) {
            return bond.covenAmount - bond.vestedAmount;
        }
        
        uint256 timeElapsed = block.timestamp - bond.lastClaimTime;
        uint256 totalVestingTime = bond.vestingEnd - (bond.vestingEnd - bondTypes[bond.bondTypeId].vestingTerm);
        if (totalVestingTime == 0) return 0;
        
        uint256 vestingProgress = (timeElapsed * bond.covenAmount) / bondTypes[bond.bondTypeId].vestingTerm;
        uint256 maxClaimable = bond.vestedAmount + vestingProgress;
        
        if (maxClaimable > bond.covenAmount) {
            return bond.covenAmount - bond.vestedAmount;
        }
        return vestingProgress;
    }
    
    function _isBondOwner(uint256 bondId) internal view returns (bool) {
        uint256[] memory ids = userBonds[msg.sender];
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == bondId) return true;
        }
        return false;
    }
}
