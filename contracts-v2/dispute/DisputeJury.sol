// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeJury} from "../interfaces/IDisputeJury.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DisputeJury
 * @notice Jury selection and management for disputes
 */
contract DisputeJury is IDisputeJury, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    mapping(address => Juror) public jurors;
    mapping(uint256 => address[]) public disputeJuries;
    address[] public jurorList;

    uint256 public constant MIN_STAKE = 1000e18; // 1000 tokens

    constructor(address _stakeToken) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
    }

    /// @inheritdoc IDisputeJury
    function registerJuror(uint256 stake) external nonReentrant {
        if (stake < MIN_STAKE) revert InsufficientJurorStake();
        if (jurors[msg.sender].active) revert JurorAlreadyRegistered();

        stakeToken.safeTransferFrom(msg.sender, address(this), stake);

        jurors[msg.sender] = Juror({
            account: msg.sender,
            stake: stake,
            selectionScore: stake,
            active: true
        });
        jurorList.push(msg.sender);

        emit JurorRegistered(msg.sender, stake);
    }

    /// @inheritdoc IDisputeJury
    function unregisterJuror() external nonReentrant {
        Juror storage juror = jurors[msg.sender];
        if (!juror.active) revert JurorNotFound();

        stakeToken.safeTransfer(msg.sender, juror.stake);
        juror.active = false;
        juror.stake = 0;
    }

    /// @inheritdoc IDisputeJury
    function selectJury(uint256 disputeId, uint256 jurySize) external onlyOwner returns (address[] memory selected) {
        if (jurySize == 0 || jurySize > jurorList.length) revert SelectionFailed();

        uint256 activeCount = 0;
        for (uint256 i = 0; i < jurorList.length; ) {
            if (jurors[jurorList[i]].active) activeCount++;
            unchecked { ++i; }
        }
        if (jurySize > activeCount) revert SelectionFailed();

        selected = new address[](jurySize);
        uint256 selectedCount = 0;
        uint256 nonce = 0;

        while (selectedCount < jurySize) {
            uint256 index = uint256(keccak256(abi.encodePacked(disputeId, block.timestamp, nonce))) % jurorList.length;
            address candidate = jurorList[index];
            if (jurors[candidate].active) {
                bool alreadySelected = false;
                for (uint256 j = 0; j < selectedCount; ) {
                    if (selected[j] == candidate) {
                        alreadySelected = true;
                        break;
                    }
                    unchecked { ++j; }
                }
                if (!alreadySelected) {
                    selected[selectedCount] = candidate;
                    selectedCount++;
                    emit JurorSelected(disputeId, candidate);
                }
            }
            nonce++;
            if (nonce > jurorList.length * 100) revert SelectionFailed();
        }

        disputeJuries[disputeId] = selected;
    }

    /// @inheritdoc IDisputeJury
    function slashJuror(address juror, uint256 amount) external onlyOwner {
        Juror storage j = jurors[juror];
        if (!j.active) revert JurorNotFound();
        if (j.stake < amount) revert InsufficientJurorStake();

        j.stake -= amount;
        j.selectionScore = j.stake;
        stakeToken.safeTransfer(owner(), amount);

        emit JurorSlashed(juror, amount);
    }

    /// @inheritdoc IDisputeJury
    function getJuror(address account) external view returns (Juror memory) {
        return jurors[account];
    }

    /// @inheritdoc IDisputeJury
    function getJurorsForDispute(uint256 disputeId) external view returns (address[] memory) {
        return disputeJuries[disputeId];
    }
}
