// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeJury
 * @notice Interface for the DisputeJury contract
 */
interface IDisputeJury {
    struct Juror {
        address account;
        uint256 stake;
        uint256 selectionScore;
        bool active;
    }

    event JurorRegistered(address indexed account, uint256 stake);
    event JurorSelected(uint256 indexed disputeId, address indexed juror);
    event JurorSlashed(address indexed account, uint256 amount);

    error InsufficientJurorStake();
    error JurorAlreadyRegistered();
    error JurorNotFound();
    error SelectionFailed();

    function registerJuror(uint256 stake) external;
    function unregisterJuror() external;
    function selectJury(uint256 disputeId, uint256 jurySize) external returns (address[] memory jurors);
    function slashJuror(address juror, uint256 amount) external;
    function getJuror(address account) external view returns (Juror memory);
    function getJurorsForDispute(uint256 disputeId) external view returns (address[] memory);
}
