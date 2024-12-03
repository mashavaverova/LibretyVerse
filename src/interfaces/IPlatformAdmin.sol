// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title IPlatformAdmin
/// @notice Interface for managing administrative tasks on the platform.
interface IPlatformAdmin {
    /// @notice Verifies an author, granting them permission to mint NFTs.
    /// @param author The address of the author to verify.
    function verifyAuthor(address author) external;

    /// @notice Revokes verification from an author, removing their minting rights.
    /// @param author The address of the author to revoke.
    function revokeAuthor(address author) external;

    /// @notice Checks if an address is a verified author.
    /// @param author The address to check.
    /// @return isVerified True if the address is a verified author, false otherwise.
    function isVerifiedAuthor(address author) external view returns (bool isVerified);

    /// @notice Sets the list of donation target addresses for the platform.
    /// @param donationAddresses An array of addresses representing donation targets.
    function setDonationTargets(address[] calldata donationAddresses) external;

    /// @notice Retrieves the current list of donation targets.
    /// @return An array of addresses representing donation targets.
    function getDonationTargets() external view returns (address[] memory);

    /// @notice Emitted when an author is verified.
    /// @param author The address of the verified author.
    event AuthorVerified(address indexed author);

    /// @notice Emitted when an author is revoked.
    /// @param author The address of the revoked author.
    event AuthorRevoked(address indexed author);

    /// @notice Emitted when donation targets are updated.
    /// @param donationAddresses The updated array of donation target addresses.
    event DonationTargetsUpdated(address[] donationAddresses);
}
