// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IRoyaltyManager {
    /// @notice Configures the royalty percentages.
    /// @param authorFee Percentage allocated to the author (0–100).
    /// @param platformFee Percentage allocated to the platform (0–100).
    /// @param donationFee Percentage allocated to donations (0–100).
    function setRoyaltyConfig(uint256 authorFee, uint256 platformFee, uint256 donationFee) external;

    /// @notice Handles royalty distribution for a primary sale.
    /// @param tokenId The ID of the token being sold.
    /// @param salePrice The total sale price of the token.
    function distributePrimarySale(uint256 tokenId, uint256 salePrice) external;

    /// @notice Handles royalty distribution for a secondary sale.
    /// @param tokenId The ID of the token being resold.
    /// @param salePrice The total sale price of the token.
    function distributeSecondarySale(uint256 tokenId, uint256 salePrice) external;

    /// @notice Returns the current royalty configuration.
    /// @return authorFee The percentage allocated to the author.
    /// @return platformFee The percentage allocated to the platform.
    /// @return donationFee The percentage allocated to donations.
    function getRoyaltyConfig() external view returns (uint256 authorFee, uint256 platformFee, uint256 donationFee);

    /// @notice Calculates the royalties for a given sale price.
    /// @param salePrice The total sale price.
    /// @return authorRoyalty The calculated royalty for the author.
    /// @return platformRoyalty The calculated royalty for the platform.
    /// @return donationRoyalty The calculated royalty for donations.
    function calculateRoyalties(uint256 salePrice)
        external
        view
        returns (uint256 authorRoyalty, uint256 platformRoyalty, uint256 donationRoyalty);
}
