// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPlatformAdmin.sol";
import "forge-std/console.sol"; 

/**
 * @title PlatformAdmin
 * @dev Manages platform administration, including author verification, donation targets, and admin roles.
 * @notice created by @mashavaverova
 */

contract PlatformAdmin is AccessControl, IPlatformAdmin {
    /**
     * @notice Role identifier for platform admins.
     */
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN_ROLE");

    /**
     * @notice Tracks verified authors.
     */
    mapping(address => bool) private verifiedAuthors;

    /**
     * @notice Tracks platform donation percentages for each target.
     */
    mapping(address => uint256) public platformDonations;

    /**
     * @notice Checks if an address is already a donation target.
     */
    mapping(address => bool) private isDonationTarget;

    /**
     * @notice List of platform donation target addresses.
     */
    address[] private donationTargets;

    /** @notice Events */
    event DonationTargetSet(address indexed target, uint256 percentage);
    event DonationTargetsUpdated(address[] targets);
    event AuthorVerified(address indexed author);
    event AuthorRevoked(address indexed author);
    event DonationTargetRemoved(address indexed target);

    /**
     * @notice Constructor to initialize roles for the platform admin.
     * @dev Grants the default admin role and platform admin role to the deployer.
     */

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Assign the default admin role to the contract creator
        _grantRole(PLATFORM_ADMIN_ROLE, msg.sender); // Assign platform admin role to the contract creator
    }


/* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Verifies an author.
     * @param author Address of the author to verify.
     * @dev Only callable by platform admins.
     */
    function verifyAuthor(address author) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(!verifiedAuthors[author], "Author already verified");
        verifiedAuthors[author] = true;
        emit AuthorVerified(author);
    }

    /**
     * @notice Revokes verification from an author.
     * @param author Address of the author to revoke.
     * @dev Only callable by platform admins.
     */
    function revokeAuthor(address author) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(verifiedAuthors[author], "Author not verified");
        verifiedAuthors[author] = false;
        emit AuthorRevoked(author);
    }

    /**
     * @notice Sets a platform donation target with a specific percentage.
     * @param target Address of the donation target.
     * @param percentage Percentage of donations allocated to the target.
     * @dev Only callable by platform admins.
     */
    function setDonationTarget(address target, uint256 percentage) external onlyRole(PLATFORM_ADMIN_ROLE) {
   
        require(hasRole(PLATFORM_ADMIN_ROLE, msg.sender), "Caller does not have PLATFORM_ADMIN_ROLE");
        require(target != address(0), "Invalid donation target");
        require(percentage <= 100, "Percentage cannot exceed 100");
        require(!isDonationTarget[target], "Target already exists");

        donationTargets.push(target);
        isDonationTarget[target] = true;
        platformDonations[target] = percentage;

        emit DonationTargetSet(target, percentage);
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

    /**
     * @notice Updates the platform donation targets.
     * @param newDonationTargets Array of new donation target addresses.
     * @dev Only callable by platform admins. Limits to 3 donation targets.
     */
    function setDonationTargets(address[] calldata newDonationTargets) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newDonationTargets.length <= 3, "Too many donation targets");
        // Log current donation targets before reset
        for (uint256 i = 0; i < donationTargets.length; i++) {
        }
        for (uint256 i = 0; i < donationTargets.length; i++) {
        
        emit DonationTargetRemoved(donationTargets[i]);
        
            isDonationTarget[donationTargets[i]] = false;
            platformDonations[donationTargets[i]] = 0;
        }
        delete donationTargets;

        for (uint256 i = 0; i < newDonationTargets.length; i++) {
        address target = newDonationTargets[i];
        require(!isDonationTarget[target], "Duplicate target");
        require(target != address(0), "Invalid target address");
        donationTargets.push(target);
        isDonationTarget[target] = true;
        platformDonations[target] = 0; // Set initial percentage
    }
        emit DonationTargetsUpdated(newDonationTargets);
    }

    /**
     * @notice Adds a new platform admin.
     * @param admin Address of the new platform admin.
     * @dev Only callable by the default admin role.
     */
    function addPlatformAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "Invalid admin address");
        grantRole(PLATFORM_ADMIN_ROLE, admin);
    }

    /**
     * @notice Removes a platform admin.
     * @param admin Address of the platform admin to remove.
     * @dev Only callable by the default admin role.
     */
    function removePlatformAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "Invalid admin address");
        revokeRole(PLATFORM_ADMIN_ROLE, admin);
    }

    /* =======================================================
                      View Functions
   ======================================================= */
     /**
     * @notice Checks if an address is a verified author.
     * @param author Address to check.
     * @return True if the address is a verified author, otherwise false.
     */
    function isVerifiedAuthor(address author) external view returns (bool) {
        return verifiedAuthors[author];
    }

    /**
     * @notice Retrieves the current donation targets.
     * @return Array of donation target addresses.
     */
    function getDonationTargets() external view returns (address[] memory) {
        return donationTargets;
    }

    /**
     * @notice Retrieves donation targets and their respective percentages.
     * @return targets Array of donation target addresses.
     * @return percentages Array of donation percentages for each target.
     */
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
      /**
     * @notice Retrieves a valid author address or defaults to the sender.
     * @param author Address to check.
     * @return Address of the verified author or the sender.
     */
    function getValidAuthor(address author) external view returns (address) {
        if (verifiedAuthors[author]) {
            return author; // Return the author if verified
        } else {
            return msg.sender; // Fallback to platform admin if not verified
        }
    }
}
