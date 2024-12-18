// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRoyaltyManager {
    /// @notice Configures the royalty percentages.
    /// @param authorFee Percentage allocated to the author (0–100).
    /// @param platformFee Percentage allocated to the platform (0–100).
    /// @param secondaryRoyalty Percentage allocated as royalties for secondary sales (0–10).
    function setFees(uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty) external;

    /// @notice Handles royalty distribution for a primary sale.
    /// @param salePrice The total sale price of the token.
    /// @param author The address of the author. If empty, the platform acts as the author.
    function distributePrimarySale(uint256 salePrice, address author) external payable;

    /// @notice Handles royalty distribution for a secondary sale.
    /// @param salePrice The total sale price of the token.
    /// @param author The address of the author. If empty, the platform acts as the author.
    function distributeSecondarySale(uint256 salePrice, address author) external payable;

    /// @notice Calculates the royalties for a secondary sale.
    /// @param salePrice The total sale price.
    /// @return authorRoyalty The calculated royalty share for the author.
    /// @return platformRoyalty The calculated royalty share for the platform.
    function calculateSecondaryRoyalties(uint256 salePrice)
        external
        view
        returns (uint256 authorRoyalty, uint256 platformRoyalty);

    /// @notice Updates the platform's donation fee.
    /// @param platformDonationFee The new donation fee (0–100).
    function updatePlatformDonationFee(uint256 platformDonationFee) external;

    /// @notice Returns the current royalty configuration.
    /// @return authorFee The percentage allocated to the author.
    /// @return platformFee The percentage allocated to the platform.
    /// @return secondaryRoyalty The percentage allocated as royalties for secondary sales.
    function getRoyaltyConfig()
        external
        view
        returns (uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty);
}
