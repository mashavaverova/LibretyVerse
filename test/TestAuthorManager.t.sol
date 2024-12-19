// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/AuthorManager.sol";
import "../src/core/PlatformAdmin.sol";
import "../src/interfaces/IAuthorManager.sol";

contract AuthorManagerTest is Test {
    AuthorManager public authorManager;
    PlatformAdmin public platformAdmin;

    address public deployer = address(0xDEAD);
    address public author = address(0xAAA);
    address public target1 = address(0x123);
    address public target2 = address(0x456);
    address public target3 = address(0x789);

    uint256 public depositAmount = 1 ether;

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(author, 100 ether);

        // Deploy PlatformAdmin and AuthorManager
        platformAdmin = new PlatformAdmin();
        authorManager = new AuthorManager(address(platformAdmin));

        // Assign valid author
        platformAdmin.grantRole(platformAdmin.PLATFORM_ADMIN_ROLE(), deployer);
        platformAdmin.grantRole(platformAdmin.PLATFORM_ADMIN_ROLE(), author);
    }

    // Test setDonationTarget: More than 3 targets
    function testSetDonationTargetLimitExceeded() public {
        vm.startPrank(author);

        authorManager.setDonationTarget(target1, 10);
        authorManager.setDonationTarget(target2, 20);
        authorManager.setDonationTarget(target3, 30);

        vm.expectRevert("Cannot have more than 3 donation targets");
        authorManager.setDonationTarget(address(0x999), 40);

        vm.stopPrank();
    }

    // Test setDonationTarget: Invalid target or percentage
    function testSetDonationTargetInvalidInput() public {
        vm.startPrank(author);

        vm.expectRevert("Invalid donation target");
        authorManager.setDonationTarget(address(0), 10);

        vm.expectRevert("Percentage cannot exceed 100%");
        authorManager.setDonationTarget(target1, 101);

        vm.stopPrank();
    }

    // Test removeDonationTarget: Happy path
    function testRemoveDonationTarget() public {
        vm.startPrank(author);

        authorManager.setDonationTarget(target1, 50);
        authorManager.removeDonationTarget(target1);

        (address[] memory targets,) = authorManager.getAuthorDonationTargets(author);
        assertEq(targets.length, 0, "Donation target should be removed");

        vm.stopPrank();
    }

    // Test removeDonationTarget: Non-existent target
    function testRemoveNonExistentDonationTarget() public {
        vm.startPrank(author);

        vm.expectRevert("Target does not exist");
        authorManager.removeDonationTarget(target1);

        vm.stopPrank();
    }

    // Test withdraw: No balance
    function testWithdrawNoBalance() public {
    // Mock the getValidAuthor function to return the author address
    vm.mockCall(

        address(platformAdmin),
        abi.encodeWithSelector(platformAdmin.getValidAuthor.selector, author),
        abi.encode(author)
    );

    // Ensure the author has no balance
    uint256 authorBalance = authorManager.authorBalances(author);
    assertEq(authorBalance, 0, "Author balance should be zero");

    // Expect revert due to "No balance to withdraw"
    vm.expectRevert("No balance to withdraw");
    vm.startPrank(author);
    authorManager.withdraw();
    vm.stopPrank();
}


    // Test deposit: Invalid amount
    function testDepositInvalidAmount() public {
        vm.startPrank(deployer);

        vm.expectRevert("Invalid deposit amount");
        authorManager.deposit(author, 0);

        vm.expectRevert("Mismatched ETH amount");
        authorManager.deposit{value: 1 ether}(author, 2 ether);

        vm.stopPrank();
    }

    // Test getAuthorDonationTargets: Empty targets
    function testGetAuthorDonationTargetsEmpty() public view {
        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        assertEq(targets.length, 0, "Targets should be empty");
        assertEq(percentages.length, 0, "Percentages should be empty");
    }

    function testDeposit() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 10 ether);

        // Mock getValidAuthor to resolve correctly
        vm.mockCall(
            address(platformAdmin),
            abi.encodeWithSelector(platformAdmin.getValidAuthor.selector, author),
            abi.encode(author)
        );

        authorManager.deposit{value: 5 ether}(author, 5 ether);

        uint256 balance = authorManager.authorBalances(author);
        assertEq(balance, 5 ether, "Deposit balance mismatch");

        vm.stopPrank();
    }

    function testSetDonationTarget() public {
        vm.startPrank(author);

        // Mock getValidAuthor
        vm.mockCall(
            address(platformAdmin),
            abi.encodeWithSelector(platformAdmin.getValidAuthor.selector, author),
            abi.encode(author)
        );

        authorManager.setDonationTarget(target1, 50);
        authorManager.setDonationTarget(target2, 30);

        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        assertEq(targets.length, 2, "Should have two targets");
        assertEq(targets[0], target1, "First target mismatch");
        assertEq(percentages[0], 50, "First target percentage mismatch");
        assertEq(targets[1], target2, "Second target mismatch");
        assertEq(percentages[1], 30, "Second target percentage mismatch");

        vm.stopPrank();
    }

    function testWithdraw() public {
        // Set the AuthorManager contract with some ETH to simulate the deposit
        vm.deal(address(authorManager), depositAmount);

        // Mock getValidAuthor to resolve to the correct author address
        vm.mockCall(
            address(platformAdmin),
            abi.encodeWithSelector(platformAdmin.getValidAuthor.selector, author),
            abi.encode(author)
        );

        // Step 1: Deposit ETH to the author's account
        vm.prank(deployer);
        authorManager.deposit{value: depositAmount}(author, depositAmount);

        // Verify that the balance is updated
        uint256 authorBalance = authorManager.authorBalances(author);
        assertEq(authorBalance, depositAmount, "Author balance should be updated after deposit");

        // Step 2: Withdraw the ETH
        vm.startPrank(author); // Simulate the author calling the function
        uint256 balanceBefore = author.balance;

        authorManager.withdraw();

        // Verify that the author's balance increased
        uint256 balanceAfter = author.balance;
        assertEq(balanceAfter - balanceBefore, depositAmount, "Withdraw amount mismatch");

        vm.stopPrank();
    }
}
