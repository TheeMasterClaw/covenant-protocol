"""ABI definitions for COVENANT Protocol contracts."""

COVENANT_FACTORY_ABI = [
    {"type": "event", "name": "CovenantCreated", "inputs": [{"name": "proxy", "type": "address", "indexed": True}, {"name": "implementation", "type": "address", "indexed": True}, {"name": "creator", "type": "address", "indexed": True}, {"name": "salt", "type": "bytes32", "indexed": False}]},
    {"type": "event", "name": "ImplementationUpdated", "inputs": [{"name": "oldImplementation", "type": "address", "indexed": True}, {"name": "newImplementation", "type": "address", "indexed": True}]},
    {"type": "event", "name": "RegistryUpdated", "inputs": [{"name": "oldRegistry", "type": "address", "indexed": True}, {"name": "newRegistry", "type": "address", "indexed": True}]},
    {"type": "error", "name": "InvalidImplementation"},
    {"type": "error", "name": "InvalidRegistry"},
    {"type": "error", "name": "InvalidInitializer"},
    {"type": "error", "name": "CovenantCreationFailed"},
    {"type": "function", "name": "createCovenant", "stateMutability": "nonpayable", "inputs": [{"name": "salt", "type": "bytes32"}, {"name": "initData", "type": "bytes"}], "outputs": [{"name": "proxy", "type": "address"}]},
    {"type": "function", "name": "predictCovenantAddress", "stateMutability": "view", "inputs": [{"name": "salt", "type": "bytes32"}, {"name": "initData", "type": "bytes"}], "outputs": [{"name": "predicted", "type": "address"}]},
    {"type": "function", "name": "implementation", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address"}]},
    {"type": "function", "name": "registry", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address"}]},
    {"type": "function", "name": "setImplementation", "stateMutability": "nonpayable", "inputs": [{"name": "newImplementation", "type": "address"}], "outputs": []},
    {"type": "function", "name": "setRegistry", "stateMutability": "nonpayable", "inputs": [{"name": "newRegistry", "type": "address"}], "outputs": []},
]

COVENANT_REGISTRY_ABI = [
    {"type": "event", "name": "CovenantRegistered", "inputs": [{"name": "covenantId", "type": "uint256", "indexed": True}, {"name": "proxy", "type": "address", "indexed": True}, {"name": "creator", "type": "address", "indexed": True}]},
    {"type": "event", "name": "CovenantDeregistered", "inputs": [{"name": "covenantId", "type": "uint256", "indexed": True}, {"name": "proxy", "type": "address", "indexed": True}]},
    {"type": "error", "name": "OnlyFactory"},
    {"type": "error", "name": "AlreadyRegistered"},
    {"type": "error", "name": "CovenantNotFound"},
    {"type": "error", "name": "InvalidCovenantId"},
    {"type": "function", "name": "register", "stateMutability": "nonpayable", "inputs": [{"name": "proxy", "type": "address"}, {"name": "creator", "type": "address"}], "outputs": [{"name": "covenantId", "type": "uint256"}]},
    {"type": "function", "name": "deregister", "stateMutability": "nonpayable", "inputs": [{"name": "covenantId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "getCovenant", "stateMutability": "view", "inputs": [{"name": "covenantId", "type": "uint256"}], "outputs": [{"type": "address"}]},
    {"type": "function", "name": "getCovenantId", "stateMutability": "view", "inputs": [{"name": "proxy", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "getCovenantsByCreator", "stateMutability": "view", "inputs": [{"name": "creator", "type": "address"}], "outputs": [{"type": "uint256[]"}]},
    {"type": "function", "name": "totalCovenants", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "factory", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address"}]},
]

COVENANT_IMPLEMENTATION_ABI = [
    {"type": "event", "name": "CovenantInitialized", "inputs": [{"name": "factory", "type": "address", "indexed": True}, {"name": "creator", "type": "address", "indexed": True}, {"name": "covenantId", "type": "uint256", "indexed": True}]},
    {"type": "event", "name": "CovenantStateChanged", "inputs": [{"name": "oldState", "type": "uint8", "indexed": True}, {"name": "newState", "type": "uint8", "indexed": True}]},
    {"type": "error", "name": "AlreadyInitialized"},
    {"type": "error", "name": "Unauthorized"},
    {"type": "error", "name": "InvalidStateTransition"},
    {"type": "function", "name": "initialize", "stateMutability": "nonpayable", "inputs": [{"name": "creator", "type": "address"}, {"name": "covenantId", "type": "uint256"}, {"name": "params", "type": "bytes"}], "outputs": []},
    {"type": "function", "name": "activate", "stateMutability": "nonpayable", "inputs": [], "outputs": []},
    {"type": "function", "name": "pause", "stateMutability": "nonpayable", "inputs": [], "outputs": []},
    {"type": "function", "name": "resolve", "stateMutability": "nonpayable", "inputs": [], "outputs": []},
    {"type": "function", "name": "terminate", "stateMutability": "nonpayable", "inputs": [], "outputs": []},
    {"type": "function", "name": "state", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint8"}]},
    {"type": "function", "name": "creator", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address"}]},
    {"type": "function", "name": "covenantId", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
]

TASK_MARKET_ABI = [
    {"type": "event", "name": "TaskCreated", "inputs": [{"name": "taskId", "type": "uint256", "indexed": True}, {"name": "covenantId", "type": "uint256", "indexed": True}, {"name": "creator", "type": "address", "indexed": True}, {"name": "reward", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "TaskAssigned", "inputs": [{"name": "taskId", "type": "uint256", "indexed": True}, {"name": "assignee", "type": "address", "indexed": True}]},
    {"type": "event", "name": "TaskSubmitted", "inputs": [{"name": "taskId", "type": "uint256", "indexed": True}, {"name": "proofHash", "type": "bytes32", "indexed": False}]},
    {"type": "event", "name": "TaskCompleted", "inputs": [{"name": "taskId", "type": "uint256", "indexed": True}, {"name": "assignee", "type": "address", "indexed": True}, {"name": "reward", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "TaskDisputed", "inputs": [{"name": "taskId", "type": "uint256", "indexed": True}, {"name": "disputeId", "type": "uint256", "indexed": True}]},
    {"type": "error", "name": "InvalidCovenant"},
    {"type": "error", "name": "InvalidReward"},
    {"type": "error", "name": "InvalidDeadline"},
    {"type": "error", "name": "TaskNotOpen"},
    {"type": "error", "name": "TaskNotAssigned"},
    {"type": "error", "name": "TaskNotSubmitted"},
    {"type": "error", "name": "UnauthorizedTaskAction"},
    {"type": "error", "name": "DeadlinePassed"},
    {"type": "function", "name": "createTask", "stateMutability": "payable", "inputs": [{"name": "covenantId", "type": "uint256"}, {"name": "reward", "type": "uint256"}, {"name": "rewardToken", "type": "address"}, {"name": "deadline", "type": "uint256"}, {"name": "metadataHash", "type": "bytes32"}], "outputs": [{"name": "taskId", "type": "uint256"}]},
    {"type": "function", "name": "assignTask", "stateMutability": "nonpayable", "inputs": [{"name": "taskId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "submitTask", "stateMutability": "nonpayable", "inputs": [{"name": "taskId", "type": "uint256"}, {"name": "proofHash", "type": "bytes32"}], "outputs": []},
    {"type": "function", "name": "completeTask", "stateMutability": "nonpayable", "inputs": [{"name": "taskId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "disputeTask", "stateMutability": "nonpayable", "inputs": [{"name": "taskId", "type": "uint256"}], "outputs": [{"name": "disputeId", "type": "uint256"}]},
    {"type": "function", "name": "cancelTask", "stateMutability": "nonpayable", "inputs": [{"name": "taskId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "getTask", "stateMutability": "view", "inputs": [{"name": "taskId", "type": "uint256"}], "outputs": [{"type": "tuple", "components": [{"name": "id", "type": "uint256"}, {"name": "covenantId", "type": "uint256"}, {"name": "creator", "type": "address"}, {"name": "assignee", "type": "address"}, {"name": "reward", "type": "uint256"}, {"name": "rewardToken", "type": "address"}, {"name": "deadline", "type": "uint256"}, {"name": "status", "type": "uint8"}, {"name": "metadataHash", "type": "bytes32"}]}]},
    {"type": "function", "name": "getTasksByCovenant", "stateMutability": "view", "inputs": [{"name": "covenantId", "type": "uint256"}], "outputs": [{"type": "uint256[]"}]},
    {"type": "function", "name": "getTasksByAssignee", "stateMutability": "view", "inputs": [{"name": "assignee", "type": "address"}], "outputs": [{"type": "uint256[]"}]},
]

REPUTATION_STAKE_ABI = [
    {"type": "event", "name": "Staked", "inputs": [{"name": "account", "type": "address", "indexed": True}, {"name": "amount", "type": "uint256", "indexed": False}, {"name": "unlockTime", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "Unstaked", "inputs": [{"name": "account", "type": "address", "indexed": True}, {"name": "amount", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "Slashed", "inputs": [{"name": "account", "type": "address", "indexed": True}, {"name": "amount", "type": "uint256", "indexed": False}, {"name": "reason", "type": "bytes32", "indexed": False}]},
    {"type": "error", "name": "InsufficientStake"},
    {"type": "error", "name": "StakeLocked"},
    {"type": "error", "name": "InvalidAmount"},
    {"type": "error", "name": "TransferFailed"},
    {"type": "function", "name": "stake", "stateMutability": "nonpayable", "inputs": [{"name": "amount", "type": "uint256"}, {"name": "lockDuration", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "unstake", "stateMutability": "nonpayable", "inputs": [{"name": "amount", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "slash", "stateMutability": "nonpayable", "inputs": [{"name": "account", "type": "address"}, {"name": "amount", "type": "uint256"}, {"name": "reason", "type": "bytes32"}], "outputs": []},
    {"type": "function", "name": "getStakeInfo", "stateMutability": "view", "inputs": [{"name": "account", "type": "address"}], "outputs": [{"type": "tuple", "components": [{"name": "amount", "type": "uint256"}, {"name": "stakedAt", "type": "uint256"}, {"name": "unlockTime", "type": "uint256"}, {"name": "locked", "type": "bool"}]}]},
    {"type": "function", "name": "totalStaked", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "getStakeToken", "stateMutability": "view", "inputs": [], "outputs": [{"type": "address"}]},
]

DISPUTE_DAO_ABI = [
    {"type": "event", "name": "ParamsUpdated", "inputs": [{"name": "paramName", "type": "bytes32", "indexed": False}, {"name": "oldValue", "type": "uint256", "indexed": False}, {"name": "newValue", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "TreasuryWithdrawal", "inputs": [{"name": "token", "type": "address", "indexed": True}, {"name": "recipient", "type": "address", "indexed": True}, {"name": "amount", "type": "uint256", "indexed": False}]},
    {"type": "error", "name": "InvalidParam"},
    {"type": "error", "name": "UnauthorizedUpdate"},
    {"type": "function", "name": "updateParams", "stateMutability": "nonpayable", "inputs": [{"name": "params", "type": "tuple", "components": [{"name": "minStake", "type": "uint256"}, {"name": "votingPeriod", "type": "uint256"}, {"name": "quorum", "type": "uint256"}, {"name": "appealThreshold", "type": "uint256"}]}], "outputs": []},
    {"type": "function", "name": "getParams", "stateMutability": "view", "inputs": [], "outputs": [{"type": "tuple", "components": [{"name": "minStake", "type": "uint256"}, {"name": "votingPeriod", "type": "uint256"}, {"name": "quorum", "type": "uint256"}, {"name": "appealThreshold", "type": "uint256"}]}]},
    {"type": "function", "name": "withdrawTreasury", "stateMutability": "nonpayable", "inputs": [{"name": "token", "type": "address"}, {"name": "recipient", "type": "address"}, {"name": "amount", "type": "uint256"}], "outputs": []},
]

DISPUTE_RESOLUTION_ABI = [
    {"type": "event", "name": "DisputeResolved", "inputs": [{"name": "disputeId", "type": "uint256", "indexed": True}, {"name": "outcome", "type": "uint8", "indexed": False}, {"name": "detailsHash", "type": "bytes32", "indexed": False}]},
    {"type": "event", "name": "ResolutionExecuted", "inputs": [{"name": "disputeId", "type": "uint256", "indexed": True}]},
    {"type": "error", "name": "DisputeNotFound"},
    {"type": "error", "name": "DisputeAlreadyResolved"},
    {"type": "error", "name": "InvalidOutcome"},
    {"type": "error", "name": "ExecutionFailed"},
    {"type": "function", "name": "resolveDispute", "stateMutability": "nonpayable", "inputs": [{"name": "disputeId", "type": "uint256"}, {"name": "outcome", "type": "uint8"}, {"name": "detailsHash", "type": "bytes32"}], "outputs": []},
    {"type": "function", "name": "executeResolution", "stateMutability": "nonpayable", "inputs": [{"name": "disputeId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "getResolution", "stateMutability": "view", "inputs": [{"name": "disputeId", "type": "uint256"}], "outputs": [{"name": "outcome", "type": "uint8"}, {"name": "detailsHash", "type": "bytes32"}, {"name": "executed", "type": "bool"}]},
    {"type": "function", "name": "canAppeal", "stateMutability": "view", "inputs": [{"name": "disputeId", "type": "uint256"}], "outputs": [{"type": "bool"}]},
]

DISPUTE_APPEAL_ABI = [
    {"type": "event", "name": "AppealFiled", "inputs": [{"name": "appealId", "type": "uint256", "indexed": True}, {"name": "disputeId", "type": "uint256", "indexed": True}, {"name": "appellant", "type": "address", "indexed": True}, {"name": "bond", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "AppealResolved", "inputs": [{"name": "appealId", "type": "uint256", "indexed": True}, {"name": "status", "type": "uint8", "indexed": False}]},
    {"type": "error", "name": "AppealNotAllowed"},
    {"type": "error", "name": "AppealPeriodExpired"},
    {"type": "error", "name": "InsufficientAppealBond"},
    {"type": "error", "name": "AppealAlreadyResolved"},
    {"type": "function", "name": "fileAppeal", "stateMutability": "payable", "inputs": [{"name": "disputeId", "type": "uint256"}], "outputs": [{"name": "appealId", "type": "uint256"}]},
    {"type": "function", "name": "resolveAppeal", "stateMutability": "nonpayable", "inputs": [{"name": "appealId", "type": "uint256"}, {"name": "status", "type": "uint8"}], "outputs": []},
    {"type": "function", "name": "getAppeal", "stateMutability": "view", "inputs": [{"name": "appealId", "type": "uint256"}], "outputs": [{"type": "tuple", "components": [{"name": "appealId", "type": "uint256"}, {"name": "disputeId", "type": "uint256"}, {"name": "appellant", "type": "address"}, {"name": "bond", "type": "uint256"}, {"name": "appealedAt", "type": "uint256"}, {"name": "status", "type": "uint8"}]}]},
    {"type": "function", "name": "getAppealsByDispute", "stateMutability": "view", "inputs": [{"name": "disputeId", "type": "uint256"}], "outputs": [{"type": "uint256[]"}]},
    {"type": "function", "name": "getAppealPeriod", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "getAppealBond", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
]

COVENANT_GOVERNOR_ABI = [
    {"type": "event", "name": "ProposalCreated", "inputs": [{"name": "proposalId", "type": "uint256", "indexed": True}, {"name": "proposer", "type": "address", "indexed": True}, {"name": "description", "type": "string", "indexed": False}]},
    {"type": "event", "name": "VoteCast", "inputs": [{"name": "proposalId", "type": "uint256", "indexed": True}, {"name": "voter", "type": "address", "indexed": True}, {"name": "support", "type": "uint8", "indexed": False}, {"name": "votes", "type": "uint256", "indexed": False}]},
    {"type": "event", "name": "ProposalExecuted", "inputs": [{"name": "proposalId", "type": "uint256", "indexed": True}]},
    {"type": "error", "name": "InvalidProposal"},
    {"type": "error", "name": "VotingNotStarted"},
    {"type": "error", "name": "VotingEnded"},
    {"type": "function", "name": "propose", "stateMutability": "nonpayable", "inputs": [{"name": "target", "type": "address"}, {"name": "callData", "type": "bytes"}, {"name": "description", "type": "string"}], "outputs": [{"name": "proposalId", "type": "uint256"}]},
    {"type": "function", "name": "castVote", "stateMutability": "nonpayable", "inputs": [{"name": "proposalId", "type": "uint256"}, {"name": "support", "type": "uint8"}], "outputs": []},
    {"type": "function", "name": "execute", "stateMutability": "nonpayable", "inputs": [{"name": "proposalId", "type": "uint256"}], "outputs": []},
    {"type": "function", "name": "getProposal", "stateMutability": "view", "inputs": [{"name": "proposalId", "type": "uint256"}], "outputs": [{"type": "tuple", "components": [{"name": "id", "type": "uint256"}, {"name": "proposer", "type": "address"}, {"name": "description", "type": "string"}, {"name": "callData", "type": "bytes"}, {"name": "target", "type": "address"}, {"name": "forVotes", "type": "uint256"}, {"name": "againstVotes", "type": "uint256"}, {"name": "abstainVotes", "type": "uint256"}, {"name": "startTime", "type": "uint256"}, {"name": "endTime", "type": "uint256"}, {"name": "executed", "type": "bool"}, {"name": "canceled", "type": "bool"}]}]},
    {"type": "function", "name": "quorum", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
]

ERC20_ABI = [
    {"type": "function", "name": "name", "stateMutability": "view", "inputs": [], "outputs": [{"type": "string"}]},
    {"type": "function", "name": "symbol", "stateMutability": "view", "inputs": [], "outputs": [{"type": "string"}]},
    {"type": "function", "name": "decimals", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint8"}]},
    {"type": "function", "name": "totalSupply", "stateMutability": "view", "inputs": [], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "balanceOf", "stateMutability": "view", "inputs": [{"name": "account", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "transfer", "stateMutability": "nonpayable", "inputs": [{"name": "recipient", "type": "address"}, {"name": "amount", "type": "uint256"}], "outputs": [{"type": "bool"}]},
    {"type": "function", "name": "allowance", "stateMutability": "view", "inputs": [{"name": "owner", "type": "address"}, {"name": "spender", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"type": "function", "name": "approve", "stateMutability": "nonpayable", "inputs": [{"name": "spender", "type": "address"}, {"name": "amount", "type": "uint256"}], "outputs": [{"type": "bool"}]},
    {"type": "function", "name": "transferFrom", "stateMutability": "nonpayable", "inputs": [{"name": "sender", "type": "address"}, {"name": "recipient", "type": "address"}, {"name": "amount", "type": "uint256"}], "outputs": [{"type": "bool"}]},
]
