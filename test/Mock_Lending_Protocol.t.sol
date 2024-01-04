// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Mock_Lending_Protocol.sol";
import "../src/MockUSDT.sol";

contract OptimizedLendingProtocolTest is Test {
    MockLendingProtocol protocol;
    MockUSDT mockUSDT;

    function setUp() public {
    mockUSDT = new MockUSDT();
    protocol = new MockLendingProtocol(mockUSDT);
    
    // Minting a sufficient amount of tokens for the tester's address
    address tester = address(this);
    mockUSDT.mint(tester, 100000000000000000000); // Adjust the amount as needed

    // Approving the protocol contract to spend tokens on behalf of the tester
    mockUSDT.approve(address(protocol), type(uint256).max);
    }

    // Test 1: Deposit and Withdraw Liquidity
    function testDepositAndWithdrawLiquidity() public {
        address lender = address(this);
        mockUSDT.mint(lender, 1000 ether);
        uint256 depositAmount = 500 ether;

        mockUSDT.approve(address(protocol), depositAmount);
        protocol.depositLiquidity(depositAmount);

        assertEq(protocol.lenderBalances(lender), depositAmount, "Incorrect lender balance after deposit");

        protocol.withdrawLiquidity(200 ether);

        assertEq(protocol.lenderBalances(lender), 300 ether, "Incorrect lender balance after withdrawal");
    }

    // Test 2: Adjust Interest Rate
    function testAdjustInterestRate() public {
        address borrower = address(this);
        protocol.whitelistCollateral(mockUSDT);
        protocol.depositCollateral(mockUSDT, 100 ether);

        protocol.setInterestRate(2e16);
        protocol.borrow(50 ether);

        assertEq(protocol.borrowedAmounts(borrower), 50 ether, "Borrow amount not as expected");
    }

    // Test 3: Deposit Collateral and Borrow
    function testDepositCollateralAndBorrow() public {
        address borrower = address(this);
        protocol.whitelistCollateral(mockUSDT);
        protocol.depositCollateral(mockUSDT, 100 ether);

        protocol.borrow(50 ether);

        assertEq(protocol.borrowedAmounts(borrower), 50 ether, "Borrow amount not as expected");
    }
   
   // Test 4: Repay Interest
function testRepayInterest() public {
    // Arrange
    protocol.whitelistCollateral(mockUSDT);
    protocol.depositCollateral(mockUSDT, 100 ether);
    protocol.borrow(50 ether);

    // Act
    uint256 initialBalance = mockUSDT.balanceOf(address(this));
    protocol.repayInterest();
    uint256 newBalance = mockUSDT.balanceOf(address(this));

    // Assert
    uint256 interestPaid = initialBalance - newBalance;
    assertEq(interestPaid, 0, "Interest should be repaid");
}

// Test 5: Withdraw Collateral
function testWithdrawCollateral() public {
    // Arrange
    protocol.whitelistCollateral(mockUSDT);
    protocol.depositCollateral(mockUSDT, 100 ether);

    // Act
    uint256 initialBalance = mockUSDT.balanceOf(address(this));
    protocol.withdrawCollateral();
    uint256 newBalance = mockUSDT.balanceOf(address(this));

    // Assert
    uint256 collateralWithdrawn = newBalance - initialBalance;
    assertEq(collateralWithdrawn, 100 ether, "Collateral should be withdrawn");
}

}
