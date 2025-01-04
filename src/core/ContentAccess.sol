// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IContentAccess.sol";

/**
 * @title ContentAccess
 * @dev Manages access permissions for content using token-based authorization.
 * @notice Created by @mashavaverova
 */
contract ContentAccess is IContentAccess {

    /**
     * @notice Struct representing access information for a user.
     * @dev Contains access status and an optional expiry timestamp.
     * @param hasAccess Boolean indicating if the user has access.
     * @param expiryTimestamp Unix timestamp when access expires (0 for unlimited).
     */
    struct AccessInfo {
        bool hasAccess;
        uint256 expiryTimestamp;
    }
    /**
     * @notice Mapping to track access permissions.
     * @dev contentAccess[tokenId][user] maps to AccessInfo for the user's access to a specific token.
     */
    mapping(uint256 => mapping(address => AccessInfo)) private contentAccess;

    /** Events */
    event AccessGranted(address indexed user, uint256 indexed tokenId, uint256 expiryTimestamp);
    event AccessRevoked(address indexed user, uint256 indexed tokenId);

/* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Grants unlimited access to a user for a specific token.
     * @param user Address of the user to grant access.
     * @param tokenId ID of the token the access applies to.
     */
    function grantAccess(address user, uint256 tokenId) external override {
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: 0});
        emit AccessGranted(user, tokenId, 0);
    }

    /**
     * @notice Grants timed access to a user for a specific token.
     * @param user Address of the user to grant access.
     * @param tokenId ID of the token the access applies to.
     * @param expiryTimestamp Unix timestamp when the access expires.
     */
    function grantTimedAccess(address user, uint256 tokenId, uint256 expiryTimestamp) external override {
        require(expiryTimestamp > block.timestamp, "Invalid expiry timestamp");
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: expiryTimestamp});
        emit AccessGranted(user, tokenId, expiryTimestamp);
    }

    /**
     * @notice Revokes access from a user for a specific token.
     * @param user Address of the user whose access is revoked.
     * @param tokenId ID of the token the access applies to.
     */
    function revokeAccess(address user, uint256 tokenId) external override {
        delete contentAccess[tokenId][user];
        emit AccessRevoked(user, tokenId);
    }

/* =======================================================
                      View Functions
   ======================================================= */

    /**
     * @notice Checks if a user has access to a specific token.
     * @param user Address of the user to check.
     * @param tokenId ID of the token to check access for.
     * @return hasAccess Boolean indicating if the user has access.
     */
    function checkAccess(address user, uint256 tokenId) external view override returns (bool hasAccess) {
        AccessInfo memory accessInfo = contentAccess[tokenId][user];
        if (!accessInfo.hasAccess) {
            return false;
        }
        if (accessInfo.expiryTimestamp == 0 || accessInfo.expiryTimestamp > block.timestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice Checks if a user has timed access to a specific token.
     * @param user Address of the user to check.
     * @param tokenId ID of the token to check access for.
     * @return hasAccess Boolean indicating if the user has access.
     * @return expiryTimestamp Unix timestamp when the access expires.
     */
    function checkTimedAccess(address user, uint256 tokenId)
        external
        view
        override
        returns (bool hasAccess, uint256 expiryTimestamp)
    {
        AccessInfo memory accessInfo = contentAccess[tokenId][user];
        hasAccess =
            accessInfo.hasAccess && (accessInfo.expiryTimestamp == 0 || accessInfo.expiryTimestamp > block.timestamp);
        expiryTimestamp = accessInfo.expiryTimestamp;
    }
}
