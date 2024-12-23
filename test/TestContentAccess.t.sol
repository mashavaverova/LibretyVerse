// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/ContentAccess.sol";

contract ContentAccessTest is Test {
    ContentAccess contentAccess;

    address user = address(0x123);
    uint256 tokenId = 1;

    event AccessGranted(address indexed user, uint256 indexed tokenId, uint256 expiryTimestamp);
    event AccessRevoked(address indexed user, uint256 indexed tokenId);

    function setUp() public {
        contentAccess = new ContentAccess();
    }

    // Test granting permanent access
    function testGrantAccess() public {
        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, tokenId, 0);

        contentAccess.grantAccess(user, tokenId);

        (bool hasAccess, uint256 expiryTimestamp) = contentAccess.checkTimedAccess(user, tokenId);
        assertTrue(hasAccess, "User should have access");
        assertEq(expiryTimestamp, 0, "Expiry timestamp should be 0 for permanent access");
    }

    // Test granting timed access
    function testGrantTimedAccess() public {
        uint256 expiryTimestamp = block.timestamp + 1 days;

        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, tokenId, expiryTimestamp);

        contentAccess.grantTimedAccess(user, tokenId, expiryTimestamp);

        (bool hasAccess, uint256 expiry) = contentAccess.checkTimedAccess(user, tokenId);
        assertTrue(hasAccess, "User should have timed access");
        assertEq(expiry, expiryTimestamp, "Expiry timestamp should match the one provided");
    }

    // Test revoking access
    function testRevokeAccess() public {
        contentAccess.grantAccess(user, tokenId); // Grant access first
        contentAccess.revokeAccess(user, tokenId);

        (bool hasAccess,) = contentAccess.checkTimedAccess(user, tokenId);
        assertFalse(hasAccess, "User access should be revoked");
    }

    // Test permanent access check
    function testCheckAccessPermanent() public {
        contentAccess.grantAccess(user, tokenId);

        bool hasAccess = contentAccess.checkAccess(user, tokenId);
        assertTrue(hasAccess, "User should have permanent access");
    }

    // Test timed access check
    function testCheckAccessTimed() public {
        uint256 expiryTimestamp = block.timestamp + 1 days;
        contentAccess.grantTimedAccess(user, tokenId, expiryTimestamp);

        bool hasAccess = contentAccess.checkAccess(user, tokenId);
        assertTrue(hasAccess, "User should have timed access before expiry");

        // Simulate time passing
        vm.warp(block.timestamp + 2 days);

        hasAccess = contentAccess.checkAccess(user, tokenId);
        assertFalse(hasAccess, "User should not have timed access after expiry");
    }

    // Test invalid expiry timestamp
    function testGrantTimedAccessInvalidExpiry() public {
        uint256 invalidExpiry = block.timestamp - 1;

        vm.expectRevert("Invalid expiry timestamp");
        contentAccess.grantTimedAccess(user, tokenId, invalidExpiry);
    }

    // Test event for revoking access
    function testRevokeAccessEvent() public {
        contentAccess.grantAccess(user, tokenId);

        vm.expectEmit(true, true, false, false);
        emit AccessRevoked(user, tokenId);

        contentAccess.revokeAccess(user, tokenId);
    }



    function testGrantAccessTwice() public {
        contentAccess.grantAccess(user, tokenId);

        // Grant access again
        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, tokenId, 0);

        contentAccess.grantAccess(user, tokenId);

        (bool hasAccess, uint256 expiryTimestamp) = contentAccess.checkTimedAccess(user, tokenId);
        assertTrue(hasAccess, "User should still have access");
        assertEq(expiryTimestamp, 0, "Expiry timestamp should remain 0 for permanent access");
    }

    function testGrantTimedAccessOverwritesPermanentAccess() public {
        contentAccess.grantAccess(user, tokenId); // Grant permanent access

        uint256 expiryTimestamp = block.timestamp + 1 days;

        // Grant timed access
        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, tokenId, expiryTimestamp);

        contentAccess.grantTimedAccess(user, tokenId, expiryTimestamp);

        (bool hasAccess, uint256 expiry) = contentAccess.checkTimedAccess(user, tokenId);
        assertTrue(hasAccess, "User should have timed access");
        assertEq(expiry, expiryTimestamp, "Expiry timestamp should be updated");
    }

    function testRevokeNonExistentAccess() public {
        vm.expectEmit(true, true, false, false);
        emit AccessRevoked(user, tokenId);

        contentAccess.revokeAccess(user, tokenId);

        (bool hasAccess,) = contentAccess.checkTimedAccess(user, tokenId);
        assertFalse(hasAccess, "User access should still be revoked");
    }


    function testGrantTimedAccessTwice() public {
        uint256 initialExpiryTimestamp = block.timestamp + 1 days;
        contentAccess.grantTimedAccess(user, tokenId, initialExpiryTimestamp);

        uint256 newExpiryTimestamp = block.timestamp + 2 days;

        // Grant timed access again
        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, tokenId, newExpiryTimestamp);

        contentAccess.grantTimedAccess(user, tokenId, newExpiryTimestamp);

        (bool hasAccess, uint256 expiry) = contentAccess.checkTimedAccess(user, tokenId);
        assertTrue(hasAccess, "User should have updated timed access");
        assertEq(expiry, newExpiryTimestamp, "Expiry timestamp should be updated");
    }

    function testCheckAccessForNonExistentUser() public view{
        bool hasAccess = contentAccess.checkAccess(user, tokenId);
        assertFalse(hasAccess, "User should not have access");
    }
    function testCheckTimedAccessForNonExistentUser() public view {
        (bool hasAccess, uint256 expiryTimestamp) = contentAccess.checkTimedAccess(user, tokenId);
        assertFalse(hasAccess, "User should not have timed access");
        assertEq(expiryTimestamp, 0, "Expiry timestamp should be 0");
    }

    function testGrantAccessWithZeroTokenId() public {
        uint256 zeroTokenId = 0;

        vm.expectEmit(true, true, true, true);
        emit AccessGranted(user, zeroTokenId, 0);

        contentAccess.grantAccess(user, zeroTokenId);

        (bool hasAccess, uint256 expiryTimestamp) = contentAccess.checkTimedAccess(user, zeroTokenId);
        assertTrue(hasAccess, "User should have access to token ID 0");
        assertEq(expiryTimestamp, 0, "Expiry timestamp should be 0 for permanent access");
    }


}
