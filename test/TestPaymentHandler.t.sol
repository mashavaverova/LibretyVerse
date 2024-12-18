// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/utility/PaymentHandler.sol";
import "../src/interfaces/IPaymentHandler.sol";
import "../src/interfaces/IRoyaltyManager.sol";
import "../src/interfaces/IAuthorManager.sol";
import "../src/interfaces/IPlatformAdmin.sol";
import "../src/interfaces/IContentAccess.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 Token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

// Mock contracts
/// @title MockRoyaltyManager
/// @notice Mock implementation of IRoyaltyManager for testing PaymentHandler.
/// @dev Ensures the platform and author share add up to 100%, and donation logic is handled separately.
contract MockRoyaltyManager is IRoyaltyManager {
    /// @notice Simulates royalty configuration
    /// Author Share: 50%, Platform Share: 50%, Secondary Royalties: 10%
    function getRoyaltyConfig() external pure override returns (uint256, uint256, uint256) {
        return (50, 50, 10); // Author = 50%, Platform = 50%, SecondaryRoyalty = 10%
    }

    function setFees(uint256, uint256, uint256) external override {}

    function distributePrimarySale(uint256, address) external payable override {}

    function distributeSecondarySale(uint256, address) external payable override {}

    function calculateSecondaryRoyalties(uint256 salePrice) external pure override returns (uint256, uint256) {
        uint256 royalty = (salePrice * 10) / 100; // 10% royalty for secondary sales
        return (royalty, royalty); // Split evenly between author and platform
    }

    function updatePlatformDonationFee(uint256) external override {}

    /// @notice Allows the contract to accept ETH (for platform share in tests)
    receive() external payable {}
}

// MockAuthorManager: Implements IAuthorManager
contract MockAuthorManager is IAuthorManager {
    function getAuthorDonationTargets(address) external pure override returns (address[] memory, uint256[] memory) {
        address[] memory targets = new address[](1);
        uint256[] memory percentages = new uint256[](1);
        targets[0] = address(0x123);
        percentages[0] = 10; // 10% donation
        return (targets, percentages);
    }

    function setDonationTarget(address, uint256) external override {}
    function removeDonationTarget(address) external override {}
    function withdraw() external override {}
    function deposit(address, uint256) external payable override {}
}

contract MockPlatformAdmin is IPlatformAdmin {
    address[] public platformDonationTargets;
    uint256[] public platformDonationPercentages;

    constructor() {
        // Set mock platform donation targets
        platformDonationTargets.push(address(0x234)); // Example platform donation target
        platformDonationPercentages.push(6); // 6% of the platform share as a donation
    }

    function getValidAuthor(address author) external pure override returns (address) {
        return author;
    }

    function verifyAuthor(address) external override {}

    function revokeAuthor(address) external override {}

    function isVerifiedAuthor(address) external pure override returns (bool) {
        return true;
    }

    function setDonationTargets(address[] calldata) external override {}

    function getDonationTargets() external pure override returns (address[] memory) {
        address[] memory emptyTargets = new address[](0);
        return emptyTargets;
    }

    function getPlatformDonationTargets() external view override returns (address[] memory, uint256[] memory) {
        return (platformDonationTargets, platformDonationPercentages);
    }
}

/// @title MockContentAccess
/// @notice A mock implementation of the IContentAccess interface for testing purposes
contract MockContentAccess is IContentAccess {
    // Internal mappings to simulate access control
    mapping(address => mapping(uint256 => bool)) private _access;
    mapping(address => mapping(uint256 => uint256)) private _timedAccess;

    /// @notice Grants access to a user for specific content
    function grantAccess(address user, uint256 tokenId) external override {
        _access[user][tokenId] = true;
    }

    /// @notice Grants time-limited access to a user for specific content
    function grantTimedAccess(address user, uint256 tokenId, uint256 expiryTimestamp) external override {
        _access[user][tokenId] = true;
        _timedAccess[user][tokenId] = expiryTimestamp;
    }

    /// @notice Revokes access to specific content
    function revokeAccess(address user, uint256 tokenId) external override {
        _access[user][tokenId] = false;
        _timedAccess[user][tokenId] = 0;
    }

    /// @notice Checks if a user has access to specific content
    function checkAccess(address user, uint256 tokenId) external view override returns (bool hasAccess) {
        return _access[user][tokenId];
    }

    /// @notice Checks if a user has time-limited access to specific content
    function checkTimedAccess(address user, uint256 tokenId)
        external
        view
        override
        returns (bool hasAccess, uint256 expiryTimestamp)
    {
        hasAccess = _access[user][tokenId];
        expiryTimestamp = _timedAccess[user][tokenId];
        return (hasAccess, expiryTimestamp);
    }
}

contract PaymentHandlerTest is Test {
    PaymentHandler paymentHandler;
    MockRoyaltyManager royaltyManager;
    MockAuthorManager authorManager;
    MockPlatformAdmin platformAdmin;
    MockContentAccess contentAccess;
    MockERC20 token;

    address author = address(0x1);
    address buyer = address(0x2);
    address donationTarget = address(0x123);
    address platformDonationTarget = address(0x234);

    function setUp() public {
        royaltyManager = new MockRoyaltyManager();
        authorManager = new MockAuthorManager();
        platformAdmin = new MockPlatformAdmin();
        contentAccess = new MockContentAccess();
        paymentHandler = new PaymentHandler(
            address(royaltyManager), address(authorManager), address(platformAdmin), address(contentAccess)
        );
        token = new MockERC20();
        token.transfer(buyer, 1000 ether);
    }

    /// @notice Test successful payment with ETH
    function testProcessPaymentWithETH() public {
        uint256 price = 100 ether;

        console.log("=== Test Start: testProcessPaymentWithETH ===");

        // Step 1: Fund the buyer
        vm.deal(buyer, price);
        console.log("Funding buyer with ETH. Balance:", buyer.balance);

        // Step 2: Call processPayment
        vm.prank(buyer);
        paymentHandler.processPayment{value: price}(1, price, address(0), author);

        // Step 3: Check balances
        uint256 authorBalance = paymentHandler.getAuthorBalance(address(0), author);
        uint256 donationTargetBalance = donationTarget.balance;
        uint256 platformDonationBalance = platformDonationTarget.balance;

        console.log("Author Balance:", authorBalance);
        console.log("Donation Target Balance:", donationTargetBalance);
        console.log("Platform Donation Target Balance:", platformDonationBalance);

        // Assertions
        assertEq(authorBalance, 45 ether, "Author balance incorrect!");
        assertEq(donationTargetBalance, 5 ether, "Donation target balance incorrect!");
        assertEq(platformDonationBalance, 3 ether, "Platform donation target balance incorrect!");

        console.log("=== Test End: testProcessPaymentWithETH ===");
    }

    /// @notice Test successful payment with ERC20
    function testProcessPaymentWithERC20() public {
        uint256 price = 100 ether;

        console.log("=== Test Start: testProcessPaymentWithERC20 ===");

        // Step 1: Approve PaymentHandler
        vm.startPrank(buyer);
        token.approve(address(paymentHandler), price);
        vm.stopPrank();

        // Step 2: Call processPayment
        vm.prank(buyer);
        paymentHandler.processPayment(1, price, address(token), author);

        // Step 3: Check balances
        uint256 authorBalance = paymentHandler.getAuthorBalance(address(token), author);
        uint256 donationTargetBalance = token.balanceOf(donationTarget);
        uint256 platformDonationBalance = token.balanceOf(platformDonationTarget);

        console.log("Author Balance:", authorBalance);
        console.log("Donation Target Balance:", donationTargetBalance);
        console.log("Platform Donation Target Balance:", platformDonationBalance);

        // Assertions
        assertEq(authorBalance, 45 ether, "Author balance incorrect!");
        assertEq(donationTargetBalance, 5 ether, "Donation target balance incorrect!");
        assertEq(platformDonationBalance, 3 ether, "Platform donation target balance incorrect!");

        console.log("=== Test End: testProcessPaymentWithERC20 ===");
    }

    /// @notice Test author withdrawal in ETH
    function testWithdrawETH() public {
        uint256 price = 100 ether;

        vm.deal(buyer, price);
        vm.prank(buyer);
        paymentHandler.processPayment{value: price}(1, price, address(0), author);

        uint256 balanceBefore = author.balance;
        vm.prank(author);
        paymentHandler.withdraw(address(0));
        uint256 balanceAfter = author.balance;

        assertEq(balanceAfter - balanceBefore, 45 ether, "Author withdrawal incorrect!");
    }

    /// @notice Test author withdrawal in ERC20
    function testWithdrawERC20() public {
        uint256 price = 100 ether;

        vm.startPrank(buyer);
        token.approve(address(paymentHandler), price);
        paymentHandler.processPayment(1, price, address(token), author);
        vm.stopPrank();

        uint256 balanceBefore = token.balanceOf(author);
        vm.prank(author);
        paymentHandler.withdraw(address(token));
        uint256 balanceAfter = token.balanceOf(author);

        assertEq(balanceAfter - balanceBefore, 45 ether, "Author withdrawal incorrect!");
    }
}
