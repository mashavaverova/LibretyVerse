// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/PlatformAdmin.sol";

contract PlatformAdminTest is Test {
    PlatformAdmin platformAdmin;

    address deployer = address(this); // Test contract is the deployer
    address admin = address(0x123); // Test admin address
    address target1 = address(0x111); // Donation target 1
    address target2 = address(0x222); // Donation target 2

    address badass = address(0xBAD);

    event DonationTargetSet(address indexed target, uint256 percentage);
    event DonationTargetRemoved(address indexed target);
    event DonationTargetsUpdated(address[] targets);
    event AuthorVerified(address indexed author);
    event AuthorRevoked(address indexed author);

    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    function setUp() public {
        platformAdmin = new PlatformAdmin();

        if (platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), admin)) {
            vm.prank(deployer);
            platformAdmin.removePlatformAdmin(admin);
        }

        console.log("Deployer address:", deployer);
        console.log("Admin address:", admin);

        assertFalse(
            platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), admin),
            "Admin should not have PLATFORM_ADMIN_ROLE"
        );
        assertTrue(
            platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), deployer),
            "Deployer should have PLATFORM_ADMIN_ROLE"
        );
    }

    /// @notice Test adding a valid donation target
    function testAddDonationTarget() public {
        vm.startPrank(deployer);

        uint256 percentage = 40;
        console.log("Adding a donation target...");
        vm.expectEmit(true, true, false, true);
        emit DonationTargetSet(target1, percentage);

        platformAdmin.setDonationTarget(target1, percentage);

        // Verify the target and percentage
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getDonationTargetsAndPercentages();
        assertEq(targets.length, 1, "Should have 1 donation target");
        assertEq(targets[0], target1, "Target address mismatch");
        assertEq(percentages[0], percentage, "Percentage mismatch");

        vm.stopPrank();
    }

    /// @notice Test adding a duplicate donation target
    function testAddDuplicateDonationTarget() public {
        vm.startPrank(deployer);

        uint256 percentage = 40;
        platformAdmin.setDonationTarget(target1, percentage);

        console.log("Attempting to add duplicate target...");
        vm.expectRevert("Target already exists");
        platformAdmin.setDonationTarget(target1, 60);

        // Verify target list remains unchanged
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getDonationTargetsAndPercentages();
        assertEq(targets.length, 1, "Duplicate target should not be added");
        assertEq(percentages[0], percentage, "Percentage should remain the same");

        vm.stopPrank();
    }

    /// @notice Test setting a donation target with invalid inputs
    function testSetDonationTargetInvalidInputs() public {
        vm.startPrank(deployer);

        console.log("Testing invalid donation target address...");
        vm.expectRevert("Invalid donation target");
        platformAdmin.setDonationTarget(address(0), 20);

        console.log("Testing invalid donation percentage...");
        vm.expectRevert("Percentage cannot exceed 100");
        platformAdmin.setDonationTarget(target1, 101);

        vm.stopPrank();
    }

    /// @notice Test resetting and adding multiple donation targets
    function testResetAndAddDonationTargets() public {
        vm.startPrank(deployer);

        address[] memory emptyTargets = new address[](0);
        address[] memory initialTargets = new address[](2);
        initialTargets[0] = target1;
        initialTargets[1] = target2;

        console.log("Setting initial donation targets...");
        platformAdmin.setDonationTargets(initialTargets);

        // Verify initial targets
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getDonationTargetsAndPercentages();
        assertEq(targets.length, 2, "Two targets should be set");
        assertEq(targets[0], target1, "First target mismatch");
        assertEq(targets[1], target2, "Second target mismatch");
        assertEq(percentages[0], 0, "First target percentage should be 0");
        assertEq(percentages[1], 0, "Second target percentage should be 0");

        console.log("Resetting donation targets...");

        vm.expectEmit(true, false, false, true);
        emit DonationTargetRemoved(target1);
        emit DonationTargetRemoved(target2);

        platformAdmin.setDonationTargets(emptyTargets);

        // Verify targets are removed
        (targets, percentages) = platformAdmin.getDonationTargetsAndPercentages();
        assertEq(targets.length, 0, "All targets should be removed");

        vm.stopPrank();
    }

    function testSetDonationTargetUnauthorized() public {
        console.log("Testing unauthorized access to setDonationTarget...");
        console.log("Badass address:", badass);

        // Confirm that 'badass' does NOT have PLATFORM_ADMIN_ROLE
        assertFalse(
            platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), badass),
            "Badass should not have PLATFORM_ADMIN_ROLE"
        );

        console.log("Attempting unauthorized call...");

        // Start prank as 'badass' and expect a revert
        vm.startPrank(badass);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, badass, platformAdmin.PLATFORM_ADMIN_ROLE()
            )
        );

        // This call should fail because 'badass' does not have PLATFORM_ADMIN_ROLE
        platformAdmin.setDonationTarget(target1, 30);

        vm.stopPrank(); // Stop the prank
    }

    /// @notice Test verifying and revoking an author
    function testVerifyAndRevokeAuthor() public {
        vm.startPrank(deployer);
        address author = address(0x333);

        console.log("Verifying an author...");
        vm.expectEmit(true, true, false, true);
        emit AuthorVerified(author);
        platformAdmin.verifyAuthor(author);

        assertTrue(platformAdmin.isVerifiedAuthor(author), "Author should be verified");

        console.log("Revoking the author...");
        vm.expectEmit(true, true, false, true);
        emit AuthorRevoked(author);
        platformAdmin.revokeAuthor(author);

        assertFalse(platformAdmin.isVerifiedAuthor(author), "Author should no longer be verified");

        vm.stopPrank();
    }

    /// @notice Test adding and removing PLATFORM_ADMIN_ROLE
    function testManagePlatformAdminRole() public {
        console.log("Adding a new platform admin...");
        vm.prank(deployer);
        platformAdmin.addPlatformAdmin(admin);

        assertTrue(
            platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), admin), "Admin should have PLATFORM_ADMIN_ROLE"
        );

        console.log("Removing platform admin role...");
        vm.prank(deployer);
        platformAdmin.removePlatformAdmin(admin);

        assertFalse(platformAdmin.hasRole(platformAdmin.PLATFORM_ADMIN_ROLE(), admin), "Admin role should be removed");
    }

    function testDefaultAdminRoleAssigned() public view {
        bytes32 defaultAdminRole = platformAdmin.DEFAULT_ADMIN_ROLE();
        assertTrue(platformAdmin.hasRole(defaultAdminRole, deployer), "Deployer should have DEFAULT_ADMIN_ROLE");
    }

    function testPlatformAdminRoleAssigned() public view {
        bytes32 platformAdminRole = platformAdmin.PLATFORM_ADMIN_ROLE();
        assertTrue(platformAdmin.hasRole(platformAdminRole, deployer), "Deployer should have PLATFORM_ADMIN_ROLE");
    }

    function testVerifyAuthorWithAdminRole() public {
        address author = address(0x456);

        // Verify with authorized account
        console.log("Testing verifyAuthor with deployer");
        platformAdmin.verifyAuthor(author);
        assertTrue(platformAdmin.isVerifiedAuthor(author), "Author should be verified by PLATFORM_ADMIN_ROLE");

        // Test unauthorized access
        console.log("Testing verifyAuthor with admin (unauthorized)");
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, admin, platformAdmin.PLATFORM_ADMIN_ROLE()
            )
        );
        vm.prank(admin); // Apply prank immediately before the function call
        platformAdmin.verifyAuthor(author);
    }

    function testRevokeAuthorWithAdminRole() public {
        address author = address(0x789);

        // Verify the author first
        platformAdmin.verifyAuthor(author);
        console.log("Author verified:", platformAdmin.isVerifiedAuthor(author));

        // Revoke the author with an authorized account
        platformAdmin.revokeAuthor(author);
        console.log("Author revoked:", !platformAdmin.isVerifiedAuthor(author));

        // Test unauthorized access
        console.log("Testing revokeAuthor with admin (unauthorized)");
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, admin, platformAdmin.PLATFORM_ADMIN_ROLE()
            )
        );
        vm.prank(admin); // Apply prank immediately before the function call
        platformAdmin.revokeAuthor(author);
    }

    function testPrankIsolated() public {
        vm.prank(admin); // Simulate the admin as the caller
        console.log("Expected msg.sender: admin (0x123)");
        console.log("Actual msg.sender in test:", msg.sender);
    }

    function testGrantRoleAndPrank() public {
        bytes32 platformAdminRole = platformAdmin.PLATFORM_ADMIN_ROLE();

        // Grant admin the role
        platformAdmin.grantRole(platformAdminRole, admin);

        // Verify the role is granted
        assertTrue(platformAdmin.hasRole(platformAdminRole, admin), "Admin should have PLATFORM_ADMIN_ROLE");

        // Prank and test
        vm.prank(admin);

        address[] memory newTargets = new address[](2);
        newTargets[0] = address(0xABC);
        newTargets[1] = address(0xDEF);

        platformAdmin.setDonationTargets(newTargets);
    }

    function testSetDonationTargets() public {
        // Properly declare and initialize the targets array
        address[] memory newTargets = new address[](2);
        newTargets[0] = address(0xABC); // Example address 1
        newTargets[1] = address(0xDEF); // Example address 2

        // Set donation targets with an authorized account
        console.log("Setting donation targets with deployer (authorized)");
        platformAdmin.setDonationTargets(newTargets);

        // Retrieve and verify the donation targets
        address[] memory returnedTargets = platformAdmin.getDonationTargets();
        assertEq(returnedTargets.length, 2, "Donation targets length should match");
        assertEq(returnedTargets[0], address(0xABC), "First target should match");
        assertEq(returnedTargets[1], address(0xDEF), "Second target should match");

        // Test unauthorized access
        console.log("Testing setDonationTargets with admin (unauthorized)");

        // Apply `vm.prank` correctly and call `setDonationTargets`
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, admin, platformAdmin.PLATFORM_ADMIN_ROLE()
            )
        );
        platformAdmin.setDonationTargets(newTargets);
        vm.stopPrank();

        // Ensure that the targets remain unchanged after unauthorized access
        address[] memory unchangedTargets = platformAdmin.getDonationTargets();
        assertEq(unchangedTargets.length, 2, "Donation targets length should remain unchanged");
        assertEq(unchangedTargets[0], address(0xABC), "First target should remain unchanged");
        assertEq(unchangedTargets[1], address(0xDEF), "Second target should remain unchanged");
    }

    function testGetDonationTargets() public {
        // Declare and initialize the donation targets array
        address[] memory initialTargets = new address[](3);
        initialTargets[0] = address(0xAAA); // Example address 1
        initialTargets[1] = address(0xBBB); // Example address 2
        initialTargets[2] = address(0xCCC); // Example address 3

        // Set the donation targets with the deployer (authorized)
        console.log("Setting donation targets with deployer (authorized)");
        platformAdmin.setDonationTargets(initialTargets);

        // Verify the returned targets match the set targets
        address[] memory retrievedTargets = platformAdmin.getDonationTargets();
        assertEq(retrievedTargets.length, 3, "Donation targets length should match");
        assertEq(retrievedTargets[0], address(0xAAA), "First target should match");
        assertEq(retrievedTargets[1], address(0xBBB), "Second target should match");
        assertEq(retrievedTargets[2], address(0xCCC), "Third target should match");

        // Test the behavior with an empty donation targets array
        address[] memory emptyTargets = new address[](0);
        console.log("Setting empty donation targets with deployer (authorized)");
        platformAdmin.setDonationTargets(emptyTargets);

        // Verify that no donation targets are returned
        address[] memory retrievedEmptyTargets = platformAdmin.getDonationTargets();
        assertEq(retrievedEmptyTargets.length, 0, "Donation targets should be empty");
    }

    function testSetSingleDonationTarget() public {
        // Declare and initialize the donation targets array with one address
        address[] memory singleTarget = new address[](1);
        singleTarget[0] = address(0x123);

        // Set the single donation target with the deployer (authorized)
        console.log("Setting single donation target with deployer (authorized)");
        platformAdmin.setDonationTargets(singleTarget);

        // Verify the returned target matches the set target
        address[] memory retrievedTarget = platformAdmin.getDonationTargets();
        assertEq(retrievedTarget.length, 1, "Donation targets length should be 1");
        assertEq(retrievedTarget[0], address(0x123), "The single target should match");
    }

    function testSetDonationTargetsExceedingLimit() public {
        // Declare and initialize an array with more than 3 addresses
        address[] memory tooManyTargets = new address[](4);
        tooManyTargets[0] = address(0x111);
        tooManyTargets[1] = address(0x222);
        tooManyTargets[2] = address(0x333);
        tooManyTargets[3] = address(0x444);

        // Attempt to set the donation targets and expect a revert
        console.log("Testing setDonationTargets with too many addresses");
        vm.expectRevert("Too many donation targets");
        platformAdmin.setDonationTargets(tooManyTargets);
    }

    function testSetDonationTargetsAtLimit() public {
        // Declare and initialize an array with exactly 3 addresses
        address[] memory threeTargets = new address[](3);
        threeTargets[0] = address(0x111);
        threeTargets[1] = address(0x222);
        threeTargets[2] = address(0x333);

        // Set the donation targets with the deployer (authorized)
        console.log("Setting donation targets with exactly 3 addresses");
        platformAdmin.setDonationTargets(threeTargets);

        // Verify the returned targets match the set targets
        address[] memory retrievedTargets = platformAdmin.getDonationTargets();
        assertEq(retrievedTargets.length, 3, "Donation targets length should be 3");
        assertEq(retrievedTargets[0], address(0x111), "First target should match");
        assertEq(retrievedTargets[1], address(0x222), "Second target should match");
        assertEq(retrievedTargets[2], address(0x333), "Third target should match");
    }

    function testRemoveOldDonationTargets() public {
        // Set initial donation targets
        address[] memory initialTargets = new address[](2);
        initialTargets[0] = address(0xABC);
        initialTargets[1] = address(0xDEF);

        platformAdmin.setDonationTargets(initialTargets);

        // Verify initial targets
        address[] memory retrievedTargets = platformAdmin.getDonationTargets();
        assertEq(retrievedTargets.length, 2, "Initial donation targets length mismatch");

        // Set new donation targets, removing one
        address[] memory newTargets = new address[](1);
        newTargets[0] = address(0xABC);

        platformAdmin.setDonationTargets(newTargets);

        // Verify updated targets
        address[] memory updatedTargets = platformAdmin.getDonationTargets();
        assertEq(updatedTargets.length, 1, "Updated donation targets length mismatch");
        assertEq(updatedTargets[0], address(0xABC), "Remaining target mismatch");

        // Check that removed target's percentage is cleared
        uint256 percentage = platformAdmin.platformDonations(address(0xDEF));
        assertEq(percentage, 0, "Removed target percentage should be 0");
    }

    function testEventEmissionOnSetDonationTargets() public {
        // Declare and initialize the donation targets array
        address[] memory newTargets = new address[](2);
        newTargets[0] = address(0xABC);
        newTargets[1] = address(0xDEF);

        // Expect the event to be emitted
        vm.expectEmit(true, true, true, true);
        emit DonationTargetsUpdated(newTargets);

        // Call the function
        platformAdmin.setDonationTargets(newTargets);
    }

    function testEmptyDonationTargets() public {
        address[] memory emptyTargets = platformAdmin.getDonationTargets();
        assertEq(emptyTargets.length, 0, "Donation targets should be empty initially");

        address[] memory noTargets = new address[](0);
        platformAdmin.setDonationTargets(noTargets);

        address[] memory retrievedTargets = platformAdmin.getDonationTargets();
        assertEq(retrievedTargets.length, 0, "Donation targets should remain empty");
    }

    function testAuthorVerifiedEvent() public {
        address author = address(0x456);

        // Expect the event with indexed parameter
        vm.expectEmit(true, false, false, false); // `author` is indexed
        emit AuthorVerified(author);

        // Trigger the function
        platformAdmin.verifyAuthor(author);

        // Assert the state change
        assertTrue(platformAdmin.isVerifiedAuthor(author), "Author should be verified");
    }

    function testAuthorRevokedEvent() public {
        address author = address(0x456);

        // Verify the author first
        platformAdmin.verifyAuthor(author);

        // Expect the event with indexed parameter
        vm.expectEmit(true, false, false, false); // `author` is indexed
        emit AuthorRevoked(author);

        // Trigger the function
        platformAdmin.revokeAuthor(author);

        // Assert the state change
        assertFalse(platformAdmin.isVerifiedAuthor(author), "Author should be revoked");
    }

    function testGetPlatformDonationTargets() public {
        platformAdmin.setDonationTarget(target1, 30);
        platformAdmin.setDonationTarget(target2, 70);

        console.log("Retrieving platform donation targets...");
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getDonationTargetsAndPercentages();

        // Verify targets and percentages
        assertEq(targets.length, 2, "Should have 2 donation targets");
        assertEq(targets[0], target1, "First target mismatch");
        assertEq(targets[1], target2, "Second target mismatch");
        assertEq(percentages[0], 30, "First target percentage mismatch");
        assertEq(percentages[1], 70, "Second target percentage mismatch");
    }

    function testResetDonationTargets() public {
        console.log("Adding initial donation targets...");
        platformAdmin.setDonationTarget(target1, 40);
        platformAdmin.setDonationTarget(target2, 60);

        console.log("Resetting donation targets...");
        address[] memory emptyTargets = new address[](0);
        platformAdmin.setDonationTargets(emptyTargets);

        // Verify targets are reset
        address[] memory targets = platformAdmin.getDonationTargets();
        assertEq(targets.length, 0, "All donation targets should be cleared");
    }

    function testExactThreeDonationTargets() public {
        address[] memory targets = new address[](3);
        targets[0] = address(0x111);
        targets[1] = address(0x222);
        targets[2] = address(0x333);

        console.log("Setting exactly 3 donation targets...");
        platformAdmin.setDonationTargets(targets);

        // Verify the targets are set correctly
        address[] memory returnedTargets = platformAdmin.getDonationTargets();
        assertEq(returnedTargets.length, 3, "Should have exactly 3 donation targets");
        assertEq(returnedTargets[0], targets[0], "First target mismatch");
        assertEq(returnedTargets[1], targets[1], "Second target mismatch");
        assertEq(returnedTargets[2], targets[2], "Third target mismatch");
    }

    function testCombinationAddAndSet() public {
        console.log("Adding donation targets individually...");
        platformAdmin.setDonationTarget(target1, 50);
        platformAdmin.setDonationTarget(target2, 50);

        console.log("Resetting donation targets with a new list...");
        address[] memory newTargets = new address[](1);
        newTargets[0] = address(0x333);

        platformAdmin.setDonationTargets(newTargets);

        // Verify the new list overwrites the previous targets
        address[] memory targets = platformAdmin.getDonationTargets();
        assertEq(targets.length, 1, "Should only have 1 target after reset");
        assertEq(targets[0], address(0x333), "New target mismatch");
    }
}
