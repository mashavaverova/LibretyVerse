// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol"; // For Foundry testing framework
import "../src/core/PaymentManager.sol";

contract PaymentManagerTest is Test {
    PaymentManager public paymentManager;

    address public admin = address(0xA1); // Default admin
    address public treasury = address(0xB1); // Treasury address
    address public fundsManager = address(0xC1); // Initial funds manager
    address public user = address(0xD1); // User sending funds

    function setUp() public {
        // Deploy the PaymentManager contract
        paymentManager = new PaymentManager(admin, treasury, fundsManager);

        // Set up initial balances
        vm.deal(user, 100 ether); // Give user 100 ETH
        vm.deal(address(paymentManager), 10 ether); // Give PaymentManager 10 ETH
    }

    function testConstructor() public view {
        // Ensure the admin and funds manager roles are set
        assertTrue(paymentManager.hasRole(paymentManager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(paymentManager.hasRole(paymentManager.FUNDS_MANAGER_ROLE(), fundsManager));

        // Ensure the treasury address is set
        assertEq(paymentManager.platformTreasury(), treasury);
    }

    function testReceiveFunds() public {
        // Check initial balance
        assertEq(address(paymentManager).balance, 10 ether);

        // Send funds
        vm.prank(user); // Simulate a transaction from the user
        (bool success,) = address(paymentManager).call{value: 5 ether}("");
        assertTrue(success);

        // Verify balance updated
        assertEq(address(paymentManager).balance, 15 ether);
    }

    function testTransferFunds() public {
        uint256 initialTreasuryBalance = treasury.balance;

        // Transfer funds
        vm.prank(fundsManager); // Simulate transaction from the funds manager
        paymentManager.transferFunds(payable(treasury), 5 ether, "Transfer to treasury");

        // Check balances
        assertEq(address(paymentManager).balance, 5 ether);
        assertEq(treasury.balance, initialTreasuryBalance + 5 ether);
    }


    function testWithdrawToTreasury() public {
        uint256 initialTreasuryBalance = treasury.balance;

        // Withdraw funds to treasury
        vm.prank(fundsManager);
        paymentManager.withdrawToTreasury();

        // Check balances
        assertEq(address(paymentManager).balance, 0);
        assertEq(treasury.balance, initialTreasuryBalance + 10 ether);
    }

    function testAddFundsManager() public {
        address newFundsManager = address(0xE1);

        // Add a new funds manager
        vm.prank(admin); // Only admin can add a funds manager
        paymentManager.addFundsManager(newFundsManager);

        // Verify role granted
        assertTrue(paymentManager.hasRole(paymentManager.FUNDS_MANAGER_ROLE(), newFundsManager));
    }

    function testRemoveFundsManager() public {
        // Remove the initial funds manager
        vm.prank(admin);
        paymentManager.removeFundsManager(fundsManager);

        // Verify role revoked
        assertFalse(paymentManager.hasRole(paymentManager.FUNDS_MANAGER_ROLE(), fundsManager));
    }

    function testUpdateTreasury() public {
        address newTreasury = address(0xF1);

        // Update the treasury address
        vm.prank(admin);
        paymentManager.updateTreasury(newTreasury);

        // Verify treasury updated
        assertEq(paymentManager.platformTreasury(), newTreasury);
    }

    function testGetFundsManagers() public {
        // Verify initial funds manager
        address[] memory fundsManagers = paymentManager.getFundsManagers();
        assertEq(fundsManagers.length, 1);
        assertEq(fundsManagers[0], fundsManager);

        // Add a new funds manager
        address newFundsManager = address(0xE1);
        vm.prank(admin);
        paymentManager.addFundsManager(newFundsManager);

        // Verify both funds managers
        fundsManagers = paymentManager.getFundsManagers();
        assertEq(fundsManagers.length, 2);
        assertEq(fundsManagers[1], newFundsManager);
    }










    function testTransferFundsUnauthorized() public {
        vm.expectRevert(abi.encodeWithSignature(
    "AccessControlUnauthorizedAccount(address,bytes32)",
    address(this), // Caller address
    paymentManager.FUNDS_MANAGER_ROLE() // Expected role
));
paymentManager.transferFunds(payable(treasury), 5 ether, "Unauthorized transfer");
    }


    function testUnauthorizedAddFundsManager() public {
        vm.expectRevert(abi.encodeWithSignature(
    "AccessControlUnauthorizedAccount(address,bytes32)",
            address(this), // Caller address
            paymentManager.DEFAULT_ADMIN_ROLE() // Expected role
        ));
        paymentManager.addFundsManager(address(0xE1));
    }
}
