// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPlatformAdmin.sol";
import "forge-std/console.sol"; // Import console.log

contract PlatformAdmin is AccessControl, IPlatformAdmin {
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN_ROLE");

    mapping(address => bool) private verifiedAuthors; // Tracks verified authors
    mapping(address => uint256) public platformDonations; // Platform donation percentages for each target
    mapping(address => bool) private isDonationTarget; // Check if an address is already a donation target

    address[] private donationTargets; // List of platform donation target addresses

    event DonationTargetSet(address indexed target, uint256 percentage);
    event DonationTargetsUpdated(address[] targets);
    event AuthorVerified(address indexed author);
    event AuthorRevoked(address indexed author);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Assign the default admin role to the contract creator
        _grantRole(PLATFORM_ADMIN_ROLE, msg.sender); // Assign platform admin role to the contract creator
    }

    // Modifier to restrict functions to platform admin only
    modifier onlyPlatformAdmin() {
        console.log("Checking PLATFORM_ADMIN_ROLE for:", msg.sender);
        console.log("Role status:", hasRole(PLATFORM_ADMIN_ROLE, msg.sender));
        _checkRole(PLATFORM_ADMIN_ROLE, msg.sender);
        _;
    }

    // Verify an author, only callable by a platform admin
    function verifyAuthor(address author) external onlyPlatformAdmin {
        require(!verifiedAuthors[author], "Author already verified");
        verifiedAuthors[author] = true;
        emit AuthorVerified(author);
    }

    // Revoke an author's verified status, only callable by a platform admin
    function revokeAuthor(address author) external onlyPlatformAdmin {
        require(verifiedAuthors[author], "Author not verified");
        verifiedAuthors[author] = false;
        emit AuthorRevoked(author);
    }

    // Check if an address is a verified author
    function isVerifiedAuthor(address author) external view returns (bool) {
        return verifiedAuthors[author];
    }

    // Set platform donation target for a specific address with a percentage
    function setDonationTarget(address target, uint256 percentage) external onlyPlatformAdmin {
        console.log("Starting setDonationTarget function...");
        console.log("Sender address:", msg.sender);
        console.log("Target address:", target);
        console.log("Percentage:", percentage);

        // Explicitly check if msg.sender has PLATFORM_ADMIN_ROLE
        require(hasRole(PLATFORM_ADMIN_ROLE, msg.sender), "Caller does not have PLATFORM_ADMIN_ROLE");
        console.log("Caller verified as PLATFORM_ADMIN_ROLE.");

        // Validate inputs
        require(target != address(0), "Invalid donation target");
        require(percentage <= 100, "Percentage cannot exceed 100");

        // Check if target already exists
        require(!isDonationTarget[target], "Target already exists");

        console.log("Adding target to donation targets...");
        donationTargets.push(target);
        isDonationTarget[target] = true;
        platformDonations[target] = percentage;

        console.log("Donation target added successfully:");
        console.log("Target address:", target);
        console.log("Percentage assigned:", percentage);

        emit DonationTargetSet(target, percentage);
        console.log("Event DonationTargetSet emitted.");
    }

    // Get all platform donation targets and their respective percentages
    function getPlatformDonationTargets() external view returns (address[] memory, uint256[] memory) {
        uint256 len = donationTargets.length;
        address[] memory targets = donationTargets;
        uint256[] memory percentages = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            percentages[i] = platformDonations[targets[i]];
        }

        return (targets, percentages);
    }

    event DonationTargetRemoved(address indexed target);

    function setDonationTargets(address[] calldata newDonationTargets) external onlyPlatformAdmin {
        require(newDonationTargets.length <= 3, "Too many donation targets");
        console.log("Starting setDonationTargets function...");
        console.log("New donation targets length:", newDonationTargets.length);

        // Log current donation targets before reset
        console.log("Current donation targets before reset:");
        for (uint256 i = 0; i < donationTargets.length; i++) {
            console.log("Target:", donationTargets[i]);
        }

        // Reset donation targets and emit removal events
        console.log("Resetting current donation targets...");
        for (uint256 i = 0; i < donationTargets.length; i++) {
            emit DonationTargetRemoved(donationTargets[i]);
            console.log("Removed donation target:", donationTargets[i]);
            isDonationTarget[donationTargets[i]] = false;
            platformDonations[donationTargets[i]] = 0;
        }
        delete donationTargets;

        // Add new donation targets
        console.log("Adding new donation targets...");
        for (uint256 i = 0; i < newDonationTargets.length; i++) {
            address target = newDonationTargets[i];
            console.log("Processing target:", target);

            require(target != address(0), "Invalid target address");

            if (!isDonationTarget[target]) {
                donationTargets.push(target);
                isDonationTarget[target] = true;
                platformDonations[target] = 0;
                console.log("Added target:", target);
            } else {
                console.log("Target already exists, skipping:", target);
            }
        }

        // Log final donation targets
        console.log("Final donation targets:");
        for (uint256 i = 0; i < donationTargets.length; i++) {
            console.log("Target:", donationTargets[i]);
        }

        emit DonationTargetsUpdated(newDonationTargets);
        console.log("Donation targets updated successfully.");
    }

    // Get the current donation target list
    function getDonationTargets() external view returns (address[] memory) {
        return donationTargets;
    }

    // Get all donation targets and their respective donation percentages
    function getDonationTargetsAndPercentages() external view returns (address[] memory, uint256[] memory) {
        uint256 len = donationTargets.length;
        address[] memory targets = new address[](len);
        uint256[] memory percentages = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            targets[i] = donationTargets[i];
            percentages[i] = platformDonations[donationTargets[i]];
        }

        return (targets, percentages);
    }

    function addPlatformAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "Invalid admin address");
        grantRole(PLATFORM_ADMIN_ROLE, admin);
    }

    function removePlatformAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "Invalid admin address");
        revokeRole(PLATFORM_ADMIN_ROLE, admin);
    }

    function getValidAuthor(address author) external view returns (address) {
        if (verifiedAuthors[author]) {
            return author; // Return the author if verified
        } else {
            return msg.sender; // Fallback to platform admin if not verified
        }
    }
}
