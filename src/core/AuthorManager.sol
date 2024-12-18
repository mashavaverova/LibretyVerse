// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./PlatformAdmin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAuthorManager.sol";

contract AuthorManager is IAuthorManager, ReentrancyGuard {
    PlatformAdmin public platformAdminContract;

    // Author donation management
    mapping(address => mapping(address => uint256)) public authorDonations; // Author-specific donations
    mapping(address => address[]) public authorDonationTargets; // List of author's donation targets

    mapping(address => uint256) public authorBalances; // Balance tracking for authors

    event AuthorDonationTargetSet(address indexed author, address indexed target, uint256 percentage);
    event AuthorDonationTargetRemoved(address indexed author, address indexed target);
    event AuthorWithdrawn(address indexed author, uint256 amount);

    constructor(address _platformAdminContract) {
        require(_platformAdminContract != address(0), "Invalid PlatformAdmin contract");
        platformAdminContract = PlatformAdmin(_platformAdminContract);
    }

    /// @inheritdoc IAuthorManager
    function setDonationTarget(address target, uint256 percentage) external override {
        address author = msg.sender;
        require(target != address(0), "Invalid donation target");
        require(percentage <= 100, "Percentage cannot exceed 100%");

        // Limit to 3 targets
        require(authorDonationTargets[author].length < 3, "Cannot have more than 3 donation targets");

        authorDonations[author][target] = percentage;

        if (!_isTargetExists(author, target)) {
            authorDonationTargets[author].push(target);
        }

        emit AuthorDonationTargetSet(author, target, percentage);
    }

    /// @inheritdoc IAuthorManager
    function removeDonationTarget(address target) external override {
        address author = msg.sender;
        require(_isTargetExists(author, target), "Target does not exist");

        _removeTarget(author, target);
        authorDonations[author][target] = 0;

        emit AuthorDonationTargetRemoved(author, target);
    }

    /// @inheritdoc IAuthorManager
    function withdraw() external override nonReentrant {
        address author = platformAdminContract.getValidAuthor(msg.sender); // Resolves platform admin fallback
        uint256 balance = authorBalances[author];
        require(balance > 0, "No balance to withdraw");

        authorBalances[author] = 0;
        payable(author).transfer(balance);

        emit AuthorWithdrawn(author, balance);
    }

    /// @inheritdoc IAuthorManager
    function deposit(address author, uint256 amount) external payable override {
        require(amount > 0, "Invalid deposit amount");
        require(msg.value == amount, "Mismatched ETH amount");

        address resolvedAuthor = platformAdminContract.getValidAuthor(author);
        authorBalances[resolvedAuthor] += amount;
    }

    /// @inheritdoc IAuthorManager
    function getAuthorDonationTargets(address author)
        external
        view
        override
        returns (address[] memory targets, uint256[] memory percentages)
    {
        address resolvedAuthor = platformAdminContract.getValidAuthor(author);
        uint256 len = authorDonationTargets[resolvedAuthor].length;

        targets = new address[](len);
        percentages = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address target = authorDonationTargets[resolvedAuthor][i];
            targets[i] = target;
            percentages[i] = authorDonations[resolvedAuthor][target];
        }
    }

    /// @notice Internal function to check if a target exists
    function _isTargetExists(address author, address target) internal view returns (bool) {
        for (uint256 i = 0; i < authorDonationTargets[author].length; i++) {
            if (authorDonationTargets[author][i] == target) {
                return true;
            }
        }
        return false;
    }

    /// @notice Internal function to remove a target
    function _removeTarget(address author, address target) internal {
        uint256 length = authorDonationTargets[author].length;

        for (uint256 i = 0; i < length; i++) {
            if (authorDonationTargets[author][i] == target) {
                authorDonationTargets[author][i] = authorDonationTargets[author][length - 1];
                authorDonationTargets[author].pop();
                break;
            }
        }
    }
}
