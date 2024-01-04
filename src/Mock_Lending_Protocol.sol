// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLendingProtocol is Pausable {
    IERC20 public mockUSDT;
    
    address public admin;
    uint256 public constant MIN_INTEREST_RATE = 1e16; // 1% per year
    uint256 public constant MAX_INTEREST_RATE = 1e17; // 10% per year
    uint256 public interestRate = MIN_INTEREST_RATE; // Default to min, can be set within valid range
    mapping(address => bool) public whitelistedCollaterals;
    mapping(address => uint256) public lenderBalances;
    mapping(address => uint256) public lenderInterestEarned;
    mapping(address => uint256) public borrowTimestamps;
    mapping(address => uint256) public borrowedAmounts;
    mapping(address => IERC20) public collateralTokens;
    mapping(address => uint256) public collateralAmounts;

    event LiquidityAdded(address indexed lender, uint256 amount);
    event LiquidityRemoved(address indexed lender, uint256 amount);
    event CollateralDeposited(address indexed borrower, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount);
    event InterestPaid(address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed borrower, uint256 amount);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    constructor(IERC20 _mockUSDT) {
        admin = msg.sender;
        mockUSDT = _mockUSDT;
    }

    function whitelistCollateral(IERC20 token) external onlyAdmin {
        whitelistedCollaterals[address(token)] = true;
    }

    function depositLiquidity(uint256 amount) external {
        _transferFrom(msg.sender, amount);
        lenderBalances[msg.sender] += amount;
        emit LiquidityAdded(msg.sender, amount);
    }

    function withdrawLiquidity(uint256 amount) external {
        require(lenderBalances[msg.sender] >= amount, "Insufficient balance");

        // Calculate interest before withdrawal
        uint256 interest = calculateInterest(msg.sender);
        require(mockUSDT.balanceOf(address(this)) >= amount + interest, "Insufficient liquidity");
        lenderBalances[msg.sender] -= amount;
        lenderInterestEarned[msg.sender] += interest;
        
        // Transfer principal and interest
        _transfer(msg.sender, amount);
        _transfer(msg.sender, interest);
        
        emit LiquidityRemoved(msg.sender, amount);
    }

    function depositCollateral(IERC20 token, uint256 amount) external {
        require(whitelistedCollaterals[address(token)], "Token not whitelisted");

        _transferFrom(msg.sender, amount);
        collateralTokens[msg.sender] = token;
        collateralAmounts[msg.sender] += amount;
        emit CollateralDeposited(msg.sender, amount);
     }

    function borrow(uint256 amount) external {
        require(collateralAmounts[msg.sender] > 0, "Insufficient collateral");
        
        // Simple interest calculation
        uint256 loanAvailable = calculateLoanAvailable(msg.sender);
        require(amount <= loanAvailable, "Borrow amount exceeds limit");
        borrowedAmounts[msg.sender] += amount;
        borrowTimestamps[msg.sender] = block.timestamp;
        
        _transfer(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    function repayInterest() external {
        uint256 interest = calculateInterest(msg.sender);
        borrowedAmounts[msg.sender] -= interest;
        _transferFrom(msg.sender, interest);
        emit InterestPaid(msg.sender, interest);
    }

    function withdrawCollateral() external {
        require(borrowedAmounts[msg.sender] == 0, "Loan outstanding");

        uint256 amountToWithdraw = collateralAmounts[msg.sender];
        collateralAmounts[msg.sender] = 0;

        IERC20 collateral = collateralTokens[msg.sender];
        collateral.transfer(msg.sender, amountToWithdraw);
        emit CollateralWithdrawn(msg.sender, amountToWithdraw);
    }

    function setInterestRate(uint256 _interestRate) external onlyAdmin {
        require(_interestRate >= MIN_INTEREST_RATE && _interestRate <= MAX_INTEREST_RATE, "Interest rate out of bounds");
        interestRate = _interestRate;
    }

    function pauseContract() external onlyAdmin {
        _pause();
        // Add any necessary pause logic
    }

    function unpauseContract() external onlyAdmin {
        // Add any necessary unpause logic
        _unpause();
    }

    function _transferFrom(address sender, uint256 amount) internal {
        mockUSDT.transferFrom(sender, address(this), amount);
    }

    function _transfer(address recipient, uint256 amount) internal {
        mockUSDT.transfer(recipient, amount);
    }

    function calculateLoanAvailable(address borrower) internal view returns (uint256) {
        // Assuming a simple collateral valuation of 1:1 for calculation purposes
        return collateralAmounts[borrower];
    }

    function calculateInterest(address user) public view returns (uint256) {
        if (borrowTimestamps[user] == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - borrowTimestamps[user];
        return borrowedAmounts[user] * interestRate * timeElapsed / (365 days);
    }
}
