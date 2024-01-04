// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Mock_Lending_Protocol.sol";
import "../src/MockUSDT.sol";

contract LendingProtocolDeployment is Script {

    MockUSDT public mockUSDT;
    MockLendingProtocol public lendingProtocol;

    function setUp() public {
        // We can add any setup logic that we want to implement here
    }

    function run() public {
        vm.startBroadcast(); // Start broadcasting
        // Deploy the MockUSDT token contract
        mockUSDT = new MockUSDT();
        console.log("MockUSDT deployed at:", address(mockUSDT));
        // Once MockUSDT is deployed, you'll want to pass its address to the LendingProtocol constructor
        lendingProtocol = new MockLendingProtocol(IERC20(address(mockUSDT)));
        console.log("MockLendingProtocol deployed at:", address(lendingProtocol));
        vm.stopBroadcast(); // Stop broadcasting
    }
}

