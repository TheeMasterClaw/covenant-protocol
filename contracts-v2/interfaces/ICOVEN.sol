// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title ICOVEN
 * @notice Interface for the COVEN token contract
 */
interface ICOVEN is IERC20, IERC20Permit {
    struct Tokenomics {
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 inflationRate;
        uint256 lastMintTime;
    }

    event InflationMinted(uint256 amount, uint256 timestamp);
    event StakingContractUpdated(address indexed stakingContract);

    error MaxSupplyReached();
    error InflationNotDue();
    error InvalidInflationRate();

    function mintInflation() external returns (uint256 amount);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function setStakingContract(address stakingContract) external;
    function getTokenomics() external view returns (Tokenomics memory);
}
