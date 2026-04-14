# COVENANT Oracle Integration Architecture
## ReputationOracle.sol + TaskReview.sol Multi-Oracle Stack

## Architecture Overview

```
+-------------------------------------------------------------+
|                       COVENANT Protocol                     |
+-------------------------------------------------------------+
|  TaskReview.sol            ReputationOracle.sol             |
|  + submitDeliverable()     + submitVerification()           |
|  + markDeliverableVerified()+ getTaskVerificationStatus()   |
|  + submitReview()          + getData()                      |
|  + submitOracleReview()                                     |
+-------------------------------------------------------------+
                              ^
                              |
        +---------+-----------+-----------+---------+
        |         |           |           |         |
   +----v----+ +--v----+  +---v----+ +---v----+ +--v----+
   |Chainlink| |  UMA  |  |Reclaim | |Tellor  | | API3  |
   |Functions| |   OO  |  |Protocol| |        | | Pyth  |
   +----+----+ +--+----+  +---+----+ +---+----+ +--+----+
        |         |            |          |         |
     API calls  Image      TLS proofs  Scrapes  Price
     Sentiment  review     API verif.           data
```

## Flow: Agent Task Completion with Oracle Verification

### Step 1: Agent Submits Deliverable
```solidity
taskReview.submitDeliverable(taskId, ipfsContentHash);
```

### Step 2: Oracle Verification
Each oracle adapter calls ReputationOracle.submitVerification() with proof.

### Step 3: TaskReview Marks Verified
```solidity
taskReview.markDeliverableVerified(
    taskId,
    IReputationOracle.OracleType.ReclaimProtocol,
    85,
    oracleDataHash
);
```

### Step 4: Reviews Enabled
Once fullyVerified is true, reviewers can submit ratings.

---

## Oracle Adapter Contracts

### A. Chainlink Functions Adapter
Best for: API call verification, sentiment analysis, complex computation

```solidity
contract CovenantChainlinkAdapter is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    IReputationOracle public reputationOracle;
    bytes32 public donId;
    uint64 public subscriptionId;
    uint32 public gasLimit = 300000;
    mapping(bytes32 => uint256) public pendingTasks;

    constructor(address router, address reputationOracleAddress, bytes32 _donId, uint64 _subscriptionId)
        FunctionsClient(router) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        donId = _donId;
        subscriptionId = _subscriptionId;
    }

    function requestVerification(uint256 taskId, string memory source, bytes memory secrets, string[] memory args)
        external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addSecretsReference(secrets);
        req.setArgs(args);
        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donId);
        pendingTasks[requestId] = taskId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        uint256 taskId = pendingTasks[requestId];
        require(taskId != 0, "Unknown request");
        if (err.length == 0) {
            (bytes32 dataHash, uint8 confidence) = abi.decode(response, (bytes32, uint8));
            reputationOracle.submitVerification(dataHash, confidence, abi.encodePacked(requestId),
                IReputationOracle.OracleType.ChainlinkFunctions, taskId);
        }
        delete pendingTasks[requestId];
    }
}
```

### B. UMA Optimistic Oracle Adapter
Best for: Image/document quality review, subjective task assessment

```solidity
contract CovenantUMAAdapter {
    OptimisticOracleV3Interface public uma;
    IReputationOracle public reputationOracle;
    mapping(bytes32 => uint256) public assertionToTask;
    mapping(bytes32 => bytes32) public assertionToDataHash;

    constructor(address umaAddress, address reputationOracleAddress) {
        uma = OptimisticOracleV3Interface(umaAddress);
        reputationOracle = IReputationOracle(reputationOracleAddress);
    }

    function assertDeliverableQuality(uint256 taskId, bytes32 contentHash, string memory claim, uint256 bond)
        external returns (bytes32 assertionId) {
        assertionToDataHash[keccak256(abi.encodePacked(taskId, contentHash))] = contentHash;
        assertionId = uma.assertTruth(
            abi.encodePacked(claim),
            address(this),
            address(this),
            address(0),
            7200,
            uma.getMinimumBond(address(uma.defaultCurrency())),
            uma.defaultIdentifier(),
            bytes32(0)
        );
        assertionToTask[assertionId] = taskId;
    }

    function settleAndVerify(bytes32 assertionId) external {
        uma.settleAssertion(assertionId);
        bool verified = uma.getAssertion(assertionId).settlementResolution;
        uint256 taskId = assertionToTask[assertionId];
        bytes32 dataHash = assertionToDataHash[keccak256(abi.encodePacked(taskId))];
        if (verified) {
            reputationOracle.submitVerification(dataHash, 90, abi.encodePacked(assertionId),
                IReputationOracle.OracleType.UMAOptimisticOracle, taskId);
        }
    }
}
```

### C. Reclaim Protocol Adapter
Best for: Private API verification, Twitter/X data, HTTPS scraping

```solidity
interface IReclaimVerifier {
    function verifyProof(bytes calldata proof, bytes32[] calldata expectedClaimHashes) external view returns (bool);
}

contract CovenantReclaimAdapter {
    IReputationOracle public reputationOracle;
    IReclaimVerifier public reclaimVerifier;

    constructor(address reputationOracleAddress, address reclaimAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        reclaimVerifier = IReclaimVerifier(reclaimAddress);
    }

    function verifyAndSubmit(uint256 taskId, bytes32 dataHash, bytes calldata proof,
        bytes32[] calldata expectedClaimHashes, uint8 confidence) external {
        bool valid = reclaimVerifier.verifyProof(proof, expectedClaimHashes);
        require(valid, "Invalid Reclaim proof");
        reputationOracle.submitVerification(dataHash, confidence, proof,
            IReputationOracle.OracleType.ReclaimProtocol, taskId);
    }
}
```

### D. Tellor Adapter
Best for: Web scraping, community-verified data, long-tail queries

```solidity
contract CovenantTellorAdapter {
    IReputationOracle public reputationOracle;
    ITellor public tellor;
    mapping(bytes32 => uint256) public queryIdToTask;

    constructor(address reputationOracleAddress, address tellorAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        tellor = ITellor(tellorAddress);
    }

    function requestScrapeVerification(uint256 taskId, bytes32 queryId, uint256 tip) external {
        queryIdToTask[queryId] = taskId;
        tellor.tipQuery(queryId, tip, "");
    }

    function verifyFromTellor(bytes32 queryId, bytes32 dataHash, uint256 timestamp) external {
        uint256 taskId = queryIdToTask[queryId];
        require(taskId != 0, "Unknown query");
        (bool retrieved, uint256 value, uint256 retrievedTime) = tellor.getDataBefore(queryId, timestamp);
        require(retrieved && retrievedTime > 0, "No data available");
        uint8 confidence = uint8(value > 100 ? 100 : value);
        reputationOracle.submitVerification(dataHash, confidence, abi.encodePacked(queryId, retrievedTime),
            IReputationOracle.OracleType.Tellor, taskId);
    }
}
```

### E. API3 Adapter
Best for: Financial data verification, enterprise API validation

```solidity
contract CovenantAPI3Adapter {
    IReputationOracle public reputationOracle;
    constructor(address reputationOracleAddress) { reputationOracle = IReputationOracle(reputationOracleAddress); }

    function verifyFinancialData(uint256 taskId, bytes32 dataHash, address dapiProxy, int224 expectedMin, int224 expectedMax)
        external {
        (int224 value, uint32 timestamp) = IAPI3Proxy(dapiProxy).read();
        require(value >= expectedMin && value <= expectedMax, "Value out of range");
        require(block.timestamp - timestamp < 1 hours, "Stale data");
        reputationOracle.submitVerification(dataHash, 95, abi.encodePacked(value, timestamp),
            IReputationOracle.OracleType.API3, taskId);
    }
}
```

### F. Pyth Network Adapter
Best for: Low-latency financial verification, MEV-sensitive tasks

```solidity
contract CovenantPythAdapter {
    IReputationOracle public reputationOracle;
    IPyth public pyth;

    constructor(address reputationOracleAddress, address pythAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        pyth = IPyth(pythAddress);
    }

    function verifyPriceData(uint256 taskId, bytes32 dataHash, bytes32 priceFeedId,
        bytes[] calldata priceUpdateData, int64 expectedMin, int64 expectedMax) external payable {
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        PythStructs.Price memory price = pyth.parsePriceFeedUpdates{value: fee}(
            priceUpdateData, singleFeedId(priceFeedId), uint64(block.timestamp) - 300, uint64(block.timestamp) + 60)[0].price;
        require(price.price >= expectedMin && price.price <= expectedMax, "Price out of range");
        require(price.confidence * 10 < uint64(price.price), "Too much uncertainty");
        reputationOracle.submitVerification(dataHash, 98,
            abi.encodePacked(price.price, price.confidence, price.publishTime),
            IReputationOracle.OracleType.PythNetwork, taskId);
    }

    function singleFeedId(bytes32 id) internal pure returns (bytes32[] memory) {
        bytes32[] memory arr = new bytes32[](1); arr[0] = id; return arr;
    }
}
```

---

## Recommended Stack by Task Type

| Task Type | Primary Oracle | Secondary Oracle | Cost Est. |
|-----------|---------------|------------------|-----------|
| API Calls | Reclaim | Chainlink Functions | $0.10-0.50 |
| Image/Doc | UMA OO | Chainlink Functions | $0.20-0.75 |
| Social Sentiment | Reclaim (Twitter) | Chainlink Functions | $0.10-0.50 |
| Web Scraping | Tellor | Reclaim (if HTTPS) | $0.10-0.20 |
| Financial Analysis | API3 | Pyth Network | $0.01-0.05 |

---

## Gas Cost Estimates (Arbitrum, 2025)

| Operation | Gas Units | Cost @ 0.1 gwei | Cost @ 0.01 gwei |
|-----------|-----------|-----------------|------------------|
| submitDeliverable | ~45,000 | $0.0015 | $0.00015 |
| submitVerification | ~85,000 | $0.0028 | $0.00028 |
| markDeliverableVerified | ~120,000 | $0.0040 | $0.00040 |
| submitReview | ~95,000 | $0.0032 | $0.00032 |
| UMA assertTruth | ~250,000 | $0.0083 | $0.00083 |
| Chainlink callback | ~180,000 | $0.0060 | $0.00060 |
| Reclaim verifyProof | ~150,000 | $0.0050 | $0.00050 |
| Tellor tipQuery | ~80,000 | $0.0027 | $0.00027 |

Prices assume ETH ~3000 USD.
