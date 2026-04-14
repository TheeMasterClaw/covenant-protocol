// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskMarket} from "../interfaces/ITaskMarket.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TaskMarket
 * @notice Marketplace for creating and managing tasks within covenants
 */
contract TaskMarket is ITaskMarket, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private _nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => uint256[]) public tasksByCovenant;
    mapping(address => uint256[]) public tasksByAssignee;

    constructor() Ownable(msg.sender) {
        _nextTaskId = 1;
    }

    /// @inheritdoc ITaskMarket
    function createTask(
        uint256 covenantId,
        uint256 reward,
        address rewardToken,
        uint256 deadline,
        bytes32 metadataHash
    ) external payable nonReentrant returns (uint256 taskId) {
        if (covenantId == 0) revert InvalidCovenant();
        if (reward == 0) revert InvalidReward();
        if (deadline <= block.timestamp) revert InvalidDeadline();

        if (rewardToken == address(0)) {
            if (msg.value != reward) revert InvalidReward();
        }

        taskId = _nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            covenantId: covenantId,
            creator: msg.sender,
            assignee: address(0),
            reward: reward,
            rewardToken: rewardToken,
            deadline: deadline,
            status: 0,
            metadataHash: metadataHash
        });

        tasksByCovenant[covenantId].push(taskId);

        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), reward);
        }

        emit TaskCreated(taskId, covenantId, msg.sender, reward);
    }

    /// @inheritdoc ITaskMarket
    function assignTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        if (task.id == 0 || task.status != 0) revert TaskNotOpen();
        if (block.timestamp > task.deadline) revert DeadlinePassed();

        task.assignee = msg.sender;
        task.status = 1;
        tasksByAssignee[msg.sender].push(taskId);

        emit TaskAssigned(taskId, msg.sender);
    }

    /// @inheritdoc ITaskMarket
    function submitTask(uint256 taskId, bytes32 proofHash) external {
        Task storage task = tasks[taskId];
        if (task.id == 0 || task.status != 1) revert TaskNotAssigned();
        if (task.assignee != msg.sender) revert UnauthorizedTaskAction();

        task.status = 2;
        emit TaskSubmitted(taskId, proofHash);
    }

    /// @inheritdoc ITaskMarket
    function completeTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0 || task.status != 2) revert TaskNotSubmitted();
        if (task.creator != msg.sender) revert UnauthorizedTaskAction();

        task.status = 3;

        if (task.rewardToken == address(0)) {
            (bool success, ) = payable(task.assignee).call{value: task.reward}("");
            if (!success) revert InvalidReward();
        } else {
            IERC20(task.rewardToken).safeTransfer(task.assignee, task.reward);
        }

        emit TaskCompleted(taskId, task.assignee, task.reward);
    }

    /// @inheritdoc ITaskMarket
    function disputeTask(uint256 taskId) external returns (uint256 disputeId) {
        Task storage task = tasks[taskId];
        if (task.id == 0 || task.status != 2) revert TaskNotSubmitted();
        if (task.creator != msg.sender && task.assignee != msg.sender) revert UnauthorizedTaskAction();

        task.status = 4;
        disputeId = uint256(keccak256(abi.encodePacked(taskId, block.timestamp, msg.sender)));

        emit TaskDisputed(taskId, disputeId);
    }

    /// @inheritdoc ITaskMarket
    function cancelTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotOpen();
        if (task.creator != msg.sender) revert UnauthorizedTaskAction();
        if (task.status != 0) revert TaskNotOpen();

        task.status = 5;

        if (task.rewardToken == address(0)) {
            (bool success, ) = payable(task.creator).call{value: task.reward}("");
            if (!success) revert InvalidReward();
        } else {
            IERC20(task.rewardToken).safeTransfer(task.creator, task.reward);
        }

        emit TaskCancelled(taskId);
    }

    /// @inheritdoc ITaskMarket
    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }

    /// @inheritdoc ITaskMarket
    function getTasksByCovenant(uint256 covenantId) external view returns (uint256[] memory) {
        return tasksByCovenant[covenantId];
    }

    /// @inheritdoc ITaskMarket
    function getTasksByAssignee(address assignee) external view returns (uint256[] memory) {
        return tasksByAssignee[assignee];
    }

    receive() external payable {}
}