// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// @title IPlatformAdmin
// @notice Interface for managing administrative tasks on the platform.
interface IPlatformAdmin {
    // @notice Verifies an author, granting them permission to mint NFTs.
    // @param author The address of the author to verify.
    function verifyAuthor(address author) external;

    // @notice Revokes verification from an author, removing their minting rights.
    // @param author The address of the author to revoke.
    function revokeAuthor(address author) external;

    // @notice Checks if an address is a verified author.
    // @param author The address to check.
    // @return isVerified True if the address is a verified author, false otherwise.
    function isVerifiedAuthor(address author) external view returns (bool isVerified);

    // @notice Sets the list of donation target addresses for the platform.
    // @param donationAddresses An array of addresses representing donation targets.
    function setDonationTargets(address[] calldata donationAddresses) external;

    // @notice Retrieves the current list of donation target addresses.
    // @return donationTargets An array of addresses representing donation targets.
    function getDonationTargets() external view returns (address[] memory donationTargets);

    // @notice Retrieves donation targets and their respective percentages.
    // @return targets An array of addresses representing donation targets.
    // @return percentages An array of uint256 representing donation percentages for each target.
    function getPlatformDonationTargets() external view returns (address[] memory, uint256[] memory);

    // @notice Retrieves the address of a valid author.
    // @param author The address of the author to retrieve.
    // @return validAuthor The address of the valid author.
    function getValidAuthor(address author) external view returns (address);
}
