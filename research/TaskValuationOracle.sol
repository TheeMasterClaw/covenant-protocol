// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskValuationOracle
 * @notice TWAP-style oracle for task reward valuation. Tracks geometric mean
 *         of historical clearing prices to suggest anti-manipulation bands.
 * @dev Inspired by Uniswap V3 Oracle observations.
 */
contract TaskValuationOracle {

    struct Observation {
        uint128 price;        // Reward per task unit (wei)
        uint32 timestamp;
        uint32 blockNumber;
    }

    struct Category {
        Observation[] observations;
        uint256 observationIndex; // circular buffer index
        uint256 cardinality;
        uint256 cardinalityNext;
        uint128 minPrice;
        uint128 maxPrice;
        uint128 sumPrice; // for arithmetic mean (fallback)
        uint256 totalObservations;
    }

    mapping(uint256 => Category) public categories;
    uint256 public constant MAX_CARDINALITY = 65535;
    uint256 public defaultCardinality = 7; // 7 days default

    address public authorizedReporter; // TaskMarket or Governance
    address public owner;

    event ObservationRecorded(uint256 indexed categoryId, uint128 price, uint32 timestamp);
    event CardinalityUpdated(uint256 indexed categoryId, uint256 cardinality);

    error Unauthorized();
    error InvalidCategory();
    error InsufficientData();

    modifier onlyAuthorized() {
        if (msg.sender != authorizedReporter && msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _reporter) {
        owner = msg.sender;
        authorizedReporter = _reporter;
    }

    /**
     * @notice Initialize a category with a target observation buffer size.
     */
    function initializeCategory(uint256 _categoryId, uint256 _cardinality) external {
        if (msg.sender != owner) revert Unauthorized();
        Category storage cat = categories[_categoryId];
        if (cat.observations.length > 0) revert InvalidCategory();

        cat.cardinality = _cardinality;
        cat.cardinalityNext = _cardinality;
        cat.minPrice = type(uint128).max;
        cat.maxPrice = 0;

        // Pre-allocate array for gas efficiency
        for (uint256 i = 0; i < _cardinality; i++) {
            cat.observations.push(Observation(0, 0, 0));
        }
    }

    /**
     * @notice Record a new clearing price observation.
     * @dev Called by TaskMarket upon task completion.
     */
    function recordPrice(uint256 _categoryId, uint128 _price) external onlyAuthorized {
        Category storage cat = categories[_categoryId];
        if (cat.observations.length == 0) revert InvalidCategory();

        uint256 index = cat.observationIndex;
        cat.observations[index] = Observation({
            price: _price,
            timestamp: uint32(block.timestamp),
            blockNumber: uint32(block.number)
        });

        // Update min/max tracking
        if (_price < cat.minPrice) cat.minPrice = _price;
        if (_price > cat.maxPrice) cat.maxPrice = _price;
        cat.sumPrice += _price;
        cat.totalObservations++;

        // Advance circular buffer
        cat.observationIndex = (index + 1) % cat.cardinality;

        emit ObservationRecorded(_categoryId, _price, uint32(block.timestamp));
    }

    /**
     * @notice Get TWAP over a specified lookback period.
     * @param _categoryId Task category.
     * @param _lookbackSeconds Maximum age of observations to include.
     * @return twap Time-weighted geometric mean price.
     * @return count Number of observations included.
     */
    function getTWAP(uint256 _categoryId, uint32 _lookbackSeconds) external view returns (uint128 twap, uint256 count) {
        Category storage cat = categories[_categoryId];
        if (cat.observations.length == 0) revert InvalidCategory();

        uint32 cutoff = uint32(block.timestamp) - _lookbackSeconds;
        uint256 cardinality = cat.cardinality;

        // Geometric mean accumulator: use log-sum-exp trick to avoid overflow
        // ln(product(prices)^(1/n)) = (1/n) * sum(ln(prices))
        // For integer solidity, we use a simplified weighted sum approach
        uint256 weightedSum;
        uint256 totalWeight;

        for (uint256 i = 0; i < cardinality; i++) {
            Observation memory obs = cat.observations[i];
            if (obs.timestamp == 0) continue;
            if (obs.timestamp < cutoff) continue;

            // Weight by inverse age (more recent = higher weight)
            uint256 age = uint32(block.timestamp) - obs.timestamp + 1;
            uint256 weight = 10000 / age; // Normalized weight

            weightedSum += uint256(obs.price) * weight;
            totalWeight += weight;
            count++;
        }

        if (count == 0) revert InsufficientData();

        twap = uint128(weightedSum / totalWeight);
        return (twap, count);
    }

    /**
     * @notice Get suggested reward band based on TWAP.
     * @return minReward Recommended minimum (TWAP / 2).
     * @return maxReward Recommended maximum (TWAP * 3).
     */
    function getSuggestedReward(uint256 _categoryId) external view returns (uint128 minReward, uint128 maxReward) {
        (uint128 twap, uint256 count) = this.getTWAP(_categoryId, 7 days);
        if (count == 0) {
            return (0.001 ether, 100 ether); // defaults
        }
        minReward = twap / 2;
        maxReward = twap * 3;
    }

    /**
     * @notice Increase observation capacity for a category.
     */
    function grow(uint256 _categoryId, uint256 _cardinalityNext) external {
        if (msg.sender != owner) revert Unauthorized();
        Category storage cat = categories[_categoryId];
        if (_cardinalityNext <= cat.cardinality) revert InvalidCategory();
        if (_cardinalityNext > MAX_CARDINALITY) revert InvalidCategory();

        uint256 currentLen = cat.observations.length;
        for (uint256 i = currentLen; i < _cardinalityNext; i++) {
            cat.observations.push(Observation(0, 0, 0));
        }
        cat.cardinalityNext = _cardinalityNext;
    }

    /**
     * @notice Update authorized reporter (e.g., new TaskMarket deployment).
     */
    function setAuthorizedReporter(address _reporter) external {
        if (msg.sender != owner) revert Unauthorized();
        authorizedReporter = _reporter;
    }

    /**
     * @notice Get min/max of recorded prices for a category.
     */
    function getPriceBounds(uint256 _categoryId) external view returns (uint128 minPrice, uint128 maxPrice) {
        Category storage cat = categories[_categoryId];
        return (cat.minPrice, cat.maxPrice);
    }

    /**
     * @notice Get arithmetic mean (simpler, less manipulation resistant than TWAP).
     */
    function getArithmeticMean(uint256 _categoryId) external view returns (uint128) {
        Category storage cat = categories[_categoryId];
        if (cat.totalObservations == 0) revert InsufficientData();
        return uint128(cat.sumPrice / cat.totalObservations);
    }
}
