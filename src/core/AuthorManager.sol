// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./PlatformAdmin.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAuthorManager.sol";

/**
 * @title AuthorManager
 * @dev Manages donations, balances, and withdrawal functionalities for authors on the platform.
 */
contract AuthorManager is IAuthorManager, ReentrancyGuard {
    PlatformAdmin public platformAdminContract;

    /**
     * @notice Tracks specific donation percentages from authors to targets.
     * @dev authorDonations[author][target] = percentage.
     */
    mapping(address => mapping(address => uint256)) public authorDonations;

    /**
     * @notice Tracks a list of donation targets for each author.
     */
    mapping(address => address[]) public authorDonationTargets;

    /**
     * @notice Tracks the ETH balance of each author.
     */
    mapping(address => uint256) public authorBalances;

    /** @notice Events */
    event AuthorDonationTargetSet(address indexed author, address indexed target, uint256 percentage);
    event AuthorDonationTargetRemoved(address indexed author, address indexed target);
    event AuthorWithdrawn(address indexed author, uint256 amount);

    /**
     * @param _platformAdminContract The address of the PlatformAdmin contract.
     * @dev Initializes the contract with the PlatformAdmin instance.
     */
    constructor(address _platformAdminContract) {
        require(_platformAdminContract != address(0), "Invalid PlatformAdmin contract");
        platformAdminContract = PlatformAdmin(_platformAdminContract);
    }


/* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Allows an author to set a donation target with a percentage allocation.
     * @param target The address of the donation target.
     * @param percentage The percentage of donations allocated to the target (max 100%).
     * @dev Limited to a maximum of 3 donation targets per author.
     */
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

    /**
     * @notice Allows an author to remove a previously set donation target.
     * @param target The address of the donation target to be removed.
     * @dev The target must exist in the author's donation targets.
     */
    function removeDonationTarget(address target) external override {
        address author = msg.sender;
        require(_isTargetExists(author, target), "Target does not exist");

        _removeTarget(author, target);
        authorDonations[author][target] = 0;

        emit AuthorDonationTargetRemoved(author, target);
    }

    /**
     * @notice Allows an author to withdraw their accumulated ETH balance.
     * @dev Prevents reentrancy attacks using the ReentrancyGuard.
     */
    function withdraw() external override nonReentrant {
    address author = platformAdminContract.getValidAuthor(msg.sender); // Resolves platform admin fallback
    require(author != address(0), "Invalid author address");
    require(author != address(this), "Cannot withdraw to the contract address");

    uint256 balance = authorBalances[author];
    require(balance > 0, "No balance to withdraw");

    authorBalances[author] = 0;
    (bool success,) = payable(author).call{value: balance}("");
    require(success, "ETH transfer failed");

    emit AuthorWithdrawn(author, balance);
}

    /**
     * @notice Allows deposits for an author by transferring ETH to the contract.
     * @param author The address of the author to credit.
     * @param amount The amount of ETH being deposited.
     * @dev Ensures the deposited ETH matches the specified amount.
     */
    function deposit(address author, uint256 amount) external payable override {
        require(amount > 0, "Invalid deposit amount");
        require(msg.value == amount, "Mismatched ETH amount");

        address resolvedAuthor = platformAdminContract.getValidAuthor(author);
        authorBalances[resolvedAuthor] += amount;
    }

    /**
     * @notice Retrieves the donation targets and their corresponding percentages for an author.
     * @param author The address of the author whose donation targets are being queried.
     * @return targets The list of donation target addresses.
     * @return percentages The list of percentage allocations for each target.
     */
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
/* =======================================================
                     Internal Functions
   ======================================================= */

     /**
     * @notice Checks if a donation target exists for an author.
     * @param author The address of the author.
     * @param target The address of the target to check.
     * @return exists True if the target exists, false otherwise.
     */
    function _isTargetExists(address author, address target) internal view returns (bool) {
        for (uint256 i = 0; i < authorDonationTargets[author].length; i++) {
            if (authorDonationTargets[author][i] == target) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Removes a donation target for an author.
     * @param author The address of the author.
     * @param target The address of the target to remove.
     * @dev Updates the target list by replacing the target with the last entry and removing the last entry.
     */
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
