// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantToken} from "../interfaces/ICovenantToken.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CovenantToken
 * @notice ERC20 governance token for the COVENANT protocol
 */
contract CovenantToken is ICovenantToken, ERC20Burnable, ERC20Permit, Ownable {
    uint256 public maxSupply;
    mapping(address => bool) public minters;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        if (!minters[msg.sender]) revert UnauthorizedMinter();
        _;
    }

    /// @inheritdoc ICovenantToken
    function mint(address to, uint256 amount) external onlyMinter {
        if (totalSupply() + amount > maxSupply) revert MaxSupplyExceeded();
        _mint(to, amount);
        emit Minted(to, amount);
    }

    /// @inheritdoc ICovenantToken
    function burn(uint256 amount) public override(ERC20Burnable, ICovenantToken) {
        super.burn(amount);
        emit Burned(msg.sender, amount);
    }

    /// @inheritdoc ICovenantToken
    function burnFrom(address account, uint256 amount) public override(ERC20Burnable, ICovenantToken) {
        super.burnFrom(account, amount);
        emit Burned(account, amount);
    }

    /// @inheritdoc ICovenantToken
    function setMinter(address minter, bool allowed) external onlyOwner {
        minters[minter] = allowed;
    }

    // Override required by Solidity
    function _update(address from, address to, uint256 value) internal override(ERC20) {
        super._update(from, to, value);
    }
}
