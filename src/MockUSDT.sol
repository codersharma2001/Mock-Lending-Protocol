// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDT is ERC20 {
    // Set the initial supply and the token details such as name and symbol.
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** 6); // 1 million tokens, 6 decimals

    // The constructor calls ERC20's constructor to set the token's name and symbol
    constructor() ERC20("Mock USD Tether", "mUSDT") {
        // Mint the initial supply to the deployer of the contract
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Function to mint tokens. This mimics the role of a central issuer in the case of USDT.
    // In a real scenario, this function should have proper access control to prevent anyone from minting tokens.
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /// @notice Overrides the ERC20 decimal function to set it to 6 for USDT
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    // Optionally create a function to burn tokens if required for your testing purposes
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
