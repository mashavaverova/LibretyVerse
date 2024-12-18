// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IPaymentHandler
/// @notice Interface for the PaymentHandler contract, handling payments, royalty distribution, and content access
interface IPaymentHandler {
    /// @notice Process payment for content purchase
    /// @param tokenId The ID of the content/NFT
    /// @param price The total price to pay
    /// @param paymentToken Address of the ERC20 token used, or address(0) for ETH
    /// @param author Address of the author
    function processPayment(uint256 tokenId, uint256 price, address paymentToken, address author) external payable;

    /// @notice Allows authors to withdraw their balance
    /// @param paymentToken Address of the ERC20 token to withdraw, or address(0) for ETH
    function withdraw(address paymentToken) external;

    /// @notice Get author's balance
    /// @param paymentToken Address of the token, or address(0) for ETH
    /// @param author Address of the author
    /// @return The balance of the author for the specified token
    function getAuthorBalance(address paymentToken, address author) external view returns (uint256);
}
