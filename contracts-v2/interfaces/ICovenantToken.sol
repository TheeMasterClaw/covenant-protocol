// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICovenantToken
 * @notice Interface for the CovenantToken contract
 */
interface ICovenantToken is IERC20 {
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    error MaxSupplyExceeded();
    error UnauthorizedMinter();

    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function setMinter(address minter, bool allowed) external;
    function maxSupply() external view returns (uint256);
}
