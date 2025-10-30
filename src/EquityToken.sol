// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title EquityToken
 * @dev ERC20 token with controlled minting and Permit support (EIP-2612)
 * Only the Campaign contract can mint tokens based on raised capital
 * Includes ERC20Permit for gasless approvals via signatures
 * @author Ledgit (https://github.com/0xledgit)
 */
contract EquityToken is ERC20, ERC20Permit, ERC20Votes {
    uint256 public maxSupply;
    address public campaign;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        address _campaign
    ) ERC20(name, symbol) ERC20Permit(name) ERC20Votes() {
        require(_maxSupply > 0, "Max supply must be greater than 0");
        require(_campaign != address(0), "Invalid campaign address");

        maxSupply = _maxSupply;
        campaign = _campaign;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == campaign, "Only campaign can mint");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @dev Returns the maximum token supply
     */
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    /**
     * @dev Returns how many tokens can still be minted
     */
    function remainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    /**
     * @dev Override required by Solidity for multiple inheritance
     * ERC20 and ERC20Permit have conflicting functions
     */
    function nonces(
        address owner
    ) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);

        if (to != address(0) && delegates(to) == address(0)) {
            _delegate(to, to);
        }
    }

    /**
     * @dev Override decimals for equity tokens (integer)
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

}
