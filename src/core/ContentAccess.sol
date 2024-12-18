// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IContentAccess.sol";

contract ContentAccess is IContentAccess {
    struct AccessInfo {
        bool hasAccess;
        uint256 expiryTimestamp;
    }

    mapping(uint256 => mapping(address => AccessInfo)) private contentAccess;

    event AccessGranted(address indexed user, uint256 indexed tokenId, uint256 expiryTimestamp);
    event AccessRevoked(address indexed user, uint256 indexed tokenId);

    function grantAccess(address user, uint256 tokenId) external override {
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: 0});
        emit AccessGranted(user, tokenId, 0);
    }

    function grantTimedAccess(address user, uint256 tokenId, uint256 expiryTimestamp) external override {
        require(expiryTimestamp > block.timestamp, "Invalid expiry timestamp");
        contentAccess[tokenId][user] = AccessInfo({hasAccess: true, expiryTimestamp: expiryTimestamp});
        emit AccessGranted(user, tokenId, expiryTimestamp);
    }

    function revokeAccess(address user, uint256 tokenId) external override {
        delete contentAccess[tokenId][user];
        emit AccessRevoked(user, tokenId);
    }

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
