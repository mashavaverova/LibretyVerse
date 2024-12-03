// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title IContentAccess
/// @notice Interface for managing access to content tied to NFTs.
interface IContentAccess {
    /// @notice Grants access to content for a specific token.
    /// @param user The address of the user being granted access.
    /// @param tokenId The ID of the token for which access is granted.
    function grantAccess(address user, uint256 tokenId) external;

    /// @notice Grants time-limited access to content for a specific token.
    /// @param user The address of the user being granted access.
    /// @param tokenId The ID of the token for which access is granted.
    /// @param expiryTimestamp The timestamp when access expires.
    function grantTimedAccess(address user, uint256 tokenId, uint256 expiryTimestamp) external;

    /// @notice Revokes access to content for a specific token.
    /// @param user The address of the user whose access is being revoked.
    /// @param tokenId The ID of the token for which access is revoked.
    function revokeAccess(address user, uint256 tokenId) external;

    /// @notice Checks if a user has access to specific content.
    /// @param user The address of the user being checked.
    /// @param tokenId The ID of the token being queried.
    /// @return hasAccess True if the user has access, false otherwise.
    function checkAccess(address user, uint256 tokenId) external view returns (bool hasAccess);

    /// @notice Checks if a user has time-limited access to specific content.
    /// @param user The address of the user being checked.
    /// @param tokenId The ID of the token being queried.
    /// @return hasAccess True if the user has access, false otherwise.
    /// @return expiryTimestamp The timestamp when access expires.
    function checkTimedAccess(address user, uint256 tokenId)
        external
        view
        returns (bool hasAccess, uint256 expiryTimestamp);
}
