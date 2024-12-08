// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title PlatformAdmin
/// @notice Provides administrative controls for the platform.
contract PlatformAdmin is AccessControl {
    // Role for platform administrators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // State variables
    mapping(address => bool) private verifiedAuthors;
    address[] private donationTargets;

    // Events
    event AuthorVerified(address indexed author);
    event AuthorRevoked(address indexed author);
    event DonationTargetsUpdated(address[] newDonationTargets);

    constructor() {
        // Grant the deployer the default admin role and admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Verifies an author, granting them permission to mint NFTs.
    /// @param author The address to be verified.
    function verifyAuthor(address author) external onlyRole(ADMIN_ROLE) {
        verifiedAuthors[author] = true;
        emit AuthorVerified(author);
    }

    /// @notice Revokes verification from an author.
    /// @param author The address to revoke.
    function revokeAuthor(address author) external onlyRole(ADMIN_ROLE) {
        verifiedAuthors[author] = false;
        emit AuthorRevoked(author);
    }

    /// @notice Checks if an address is a verified author.
    /// @param author The address to check.
    /// @return True if the author is verified, false otherwise.
    function isVerifiedAuthor(address author) external view returns (bool) {
        return verifiedAuthors[author];
    }

    /// @notice Updates the donation target addresses.
    /// @param newDonationTargets The new donation target addresses.
    function setDonationTargets(address[] calldata newDonationTargets) external onlyRole(ADMIN_ROLE) {
        donationTargets = newDonationTargets;
        emit DonationTargetsUpdated(newDonationTargets);
    }

    /// @notice Retrieves the current donation target addresses.
    /// @return The list of donation target addresses.
    function getDonationTargets() external view returns (address[] memory) {
        return donationTargets;
    }
}
