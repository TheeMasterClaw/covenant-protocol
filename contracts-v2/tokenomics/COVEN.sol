// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICOVEN} from "../interfaces/ICOVEN.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title COVEN
 * @notice Main governance token for the COVENANT protocol with inflation minting
 */
contract COVEN is ICOVEN, ERC20Burnable, ERC20Permit, Ownable {
    uint256 public maxSupply;
    uint256 public totalMinted;
    uint256 public inflationRate; // basis points per year
    uint256 public lastMintTime;
    address public stakingContract;

    uint256 public constant ANNUAL_BASIS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _inflationRate
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        inflationRate = _inflationRate;
        lastMintTime = block.timestamp;
        totalMinted = 0;
    }

    /// @inheritdoc ICOVEN
    function mintInflation() external returns (uint256 amount) {
        if (block.timestamp < lastMintTime + 30 days) revert InflationNotDue();
        if (totalSupply() >= maxSupply) revert MaxSupplyReached();

        uint256 timeElapsed = block.timestamp - lastMintTime;
        amount = (totalSupply() * inflationRate * timeElapsed) / (ANNUAL_BASIS * SECONDS_PER_YEAR);

        if (totalSupply() + amount > maxSupply) {
            amount = maxSupply - totalSupply();
        }
        if (amount == 0) revert InflationNotDue();

        totalMinted += amount;
        lastMintTime = block.timestamp;

        address recipient = stakingContract != address(0) ? stakingContract : owner();
        _mint(recipient, amount);

        emit InflationMinted(amount, block.timestamp);
    }

    /// @inheritdoc ICOVEN
    function burn(uint256 amount) public override(ERC20Burnable, ICOVEN) {
        super.burn(amount);
    }

    /// @inheritdoc ICOVEN
    function burnFrom(address account, uint256 amount) public override(ERC20Burnable, ICOVEN) {
        super.burnFrom(account, amount);
    }

    /// @inheritdoc ICOVEN
    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
        emit StakingContractUpdated(_stakingContract);
    }

    /// @inheritdoc ICOVEN
    function getTokenomics() external view returns (Tokenomics memory) {
        return Tokenomics({
            maxSupply: maxSupply,
            totalMinted: totalMinted,
            inflationRate: inflationRate,
            lastMintTime: lastMintTime
        });
    }

    function _update(address from, address to, uint256 value) internal override(ERC20) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }
}