// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeDAO} from "../interfaces/IDisputeDAO.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DisputeDAO
 * @notice Governance parameters for the dispute layer
 */
contract DisputeDAO is IDisputeDAO, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    DisputeParams public params;

    constructor() Ownable(msg.sender) {
        params = DisputeParams({
            minStake: 1 ether,
            votingPeriod: 7 days,
            quorum: 1000, // basis points (10%)
            appealThreshold: 5000 // basis points (50%)
        });
    }

    /// @inheritdoc IDisputeDAO
    function updateParams(DisputeParams calldata newParams) external onlyOwner {
        if (newParams.votingPeriod == 0 || newParams.quorum == 0 || newParams.quorum > 10000) {
            revert InvalidParam();
        }

        uint256 oldMinStake = params.minStake;
        uint256 oldVotingPeriod = params.votingPeriod;
        uint256 oldQuorum = params.quorum;
        uint256 oldAppealThreshold = params.appealThreshold;

        params = newParams;

        if (oldMinStake != newParams.minStake) emit ParamsUpdated("minStake", oldMinStake, newParams.minStake);
        if (oldVotingPeriod != newParams.votingPeriod) emit ParamsUpdated("votingPeriod", oldVotingPeriod, newParams.votingPeriod);
        if (oldQuorum != newParams.quorum) emit ParamsUpdated("quorum", oldQuorum, newParams.quorum);
        if (oldAppealThreshold != newParams.appealThreshold) emit ParamsUpdated("appealThreshold", oldAppealThreshold, newParams.appealThreshold);
    }

    /// @inheritdoc IDisputeDAO
    function getParams() external view returns (DisputeParams memory) {
        return params;
    }

    /// @inheritdoc IDisputeDAO
    function withdrawTreasury(address token, address recipient, uint256 amount) external onlyOwner nonReentrant {
        if (token == address(0)) {
            (bool success, ) = payable(recipient).call{value: amount}("");
            if (!success) revert InvalidParam();
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
        emit TreasuryWithdrawal(token, recipient, amount);
    }

    receive() external payable {}
}
