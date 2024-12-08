// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title ContentAccess
/// @notice Manages user access to content tied to NFTs.
contract ContentAccess {
    // Access storage
    struct AccessInfo {
        bool hasAccess;
        uint256 expiryTimestamp; // 0 for permanent access
    }

    mapping(uint256 => mapping(address => AccessInfo)) private contentAccess; // tokenId -> user -> access info

    // Events
    event AccessGranted(address indexed user, uint256 indexed tokenId, uint256 expiryTimestamp);
    event AccessRevoked(address indexed user, uint256 indexed tokenId);

    /// @notice Grants permanent access to a specific token.
    /// @param user The address of the user.
    /// @param tokenId The ID of the token.
    function grantAccess(address user, uint256 tokenId) external {
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: 0});
        emit AccessGranted(user, tokenId, 0);
    }

    /// @notice Grants time-limited access to a specific token.
    /// @param user The address of the user.
    /// @param tokenId The ID of the token.
    /// @param expiryTimestamp The timestamp when access expires.
    function grantTimedAccess(address user, uint256 tokenId, uint256 expiryTimestamp) external {
        require(expiryTimestamp > block.timestamp, "Invalid expiry timestamp");
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: expiryTimestamp});
        emit AccessGranted(user, tokenId, expiryTimestamp);
    }

    /// @notice Revokes access to a specific token.
    /// @param user The address of the user.
    /// @param tokenId The ID of the token.
    function revokeAccess(address user, uint256 tokenId) external {
        delete contentAccess[tokenId][user];
        emit AccessRevoked(user, tokenId);
    }

    /// @notice Checks if a user has access to specific content.
    /// @param user The address of the user.
    /// @param tokenId The ID of the token.
    /// @return hasAccess True if the user has access, false otherwise.
    function checkAccess(address user, uint256 tokenId) external view returns (bool hasAccess) {
        AccessInfo memory accessInfo = contentAccess[tokenId][user];
        if (!accessInfo.hasAccess) {
            return false;
        }
        if (accessInfo.expiryTimestamp == 0 || accessInfo.expiryTimestamp > block.timestamp) {
            return true;
        }
        return false;
    }

    /// @notice Checks if a user has time-limited access to specific content.
    /// @param user The address of the user.
    /// @param tokenId The ID of the token.
    /// @return hasAccess True if the user has access, false otherwise.
    /// @return expiryTimestamp The expiry timestamp of the access.
    function checkTimedAccess(address user, uint256 tokenId)
        external
        view
        returns (bool hasAccess, uint256 expiryTimestamp)
    {
        AccessInfo memory accessInfo = contentAccess[tokenId][user];
        hasAccess = accessInfo.hasAccess && 
                    (accessInfo.expiryTimestamp == 0 || accessInfo.expiryTimestamp > block.timestamp);
        expiryTimestamp = accessInfo.expiryTimestamp;
    }
}

