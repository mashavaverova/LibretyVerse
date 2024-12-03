// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title IPaymentHandler
/// @notice Interface for managing payments and withdrawals for NFTs.
interface IPaymentHandler {
    /// @notice Processes payments for a specific token.
    /// @param tokenId The ID of the token being purchased.
    /// @param amount The payment amount.
    /// @param token The address of the ERC-20 token used for payment (use address(0) for native currency).
    function processPayment(uint256 tokenId, uint256 amount, address token) external;

    /// @notice Withdraws accumulated funds to a recipient address.
    /// @param recipient The address receiving the withdrawn funds.
    /// @param amount The amount to withdraw.
    function withdraw(address recipient, uint256 amount) external;

    /// @notice Retrieves the contract balance for a specific token.
    /// @param token The address of the token (use address(0) for native currency).
    /// @return balance The balance of the contract for the specified token.
    function getBalance(address token) external view returns (uint256 balance);

    /// @notice Retrieves payment details for a specific token ID.
    /// @param tokenId The ID of the token.
    /// @return totalPaid The total amount paid for the token.
    /// @return lastPayment The amount of the last payment made.
    function getPaymentDetails(uint256 tokenId) external view returns (uint256 totalPaid, uint256 lastPayment);
}
