// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenFactory is ERC20 {
    bool private initialized;
    uint256 public initialSupply; 
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {}

    function initialize(uint256 _initialSupply) external {
        require(!initialized, "Already initialized");
        initialized = true;
        initialSupply = _initialSupply;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}