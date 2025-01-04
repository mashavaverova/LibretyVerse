// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// @title IAuthorManager
// @notice Interface for managing Author: Firstname Lastname on the platform.
interface IAuthorManager {
    /// @notice Set donation targets and percentages for an author
    /// @param target The address of the donation target
    /// @param percentage The percentage of the author's share to allocate to the target
    function setDonationTarget(address target, uint256 percentage) external;

    /// @notice Remove a donation target for the author
    /// @param target The address of the donation target to remove
    function removeDonationTarget(address target) external;

    /// @notice Allows the author to withdraw their balance
    function withdraw() external;

    /// @notice Deposit royalties into an author's account
    /// @param author The address of the author
    /// @param amount The amount to deposit
    function deposit(address author, uint256 amount) external payable;

    /// @notice Retrieve donation targets and their respective percentages for an author
    /// @param author The address of the author
    /// @return targets Array of donation target addresses
    /// @return percentages Array of percentages for each target
    function getAuthorDonationTargets(address author)
        external
        view
        returns (address[] memory targets, uint256[] memory percentages);
}
