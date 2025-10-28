// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title EquityToken
 * @dev Token ERC20 con capacidad de minteo controlado y soporte para Permit (EIP-2612)
 * Solo el contrato Campaign puede mintear tokens basado en el capital levantado
 * Incluye ERC20Permit para aprobaciones sin gas mediante firmas
 * @author Ledgit (https://github.com/0xledgit)
 */
contract EquityToken is ERC20, ERC20Permit, ERC20Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

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
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @dev Retorna el supply máximo del token
     */
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    /**
     * @dev Retorna cuántos tokens aún pueden ser minteados
     */
    function remainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    /**
     * @dev Override requerido por Solidity para herencia múltiple
     * ERC20 y ERC20Permit tienen funciones conflictivas
     */
    function nonces(
        address owner
    ) public view virtual override(ERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    /**
     * @dev Override de decimales para tokens de equity(entero)
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

}
