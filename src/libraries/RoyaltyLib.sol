// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title RoyaltyLib
/// @notice Provides reusable logic for royalty calculations.
library RoyaltyLib {
    error InvalidFeeConfiguration(string reason);

   // event RoyaltiesCalculated(uint256 authorRoyalty, uint256 platformRoyalty, uint256 donationRoyalty);


    /// @notice Calculates royalty splits based on sale price and fee percentages.
    /// @param salePrice The total sale price.
    /// @param authorFee Percentage allocated to the author (0–100).
    /// @param platformFee Percentage allocated to the platform (0–100).
    /// @param donationFee Percentage allocated to donations (0–100).
    /// @return authorRoyalty The amount for the author.
    /// @return platformRoyalty The amount for the platform.
    /// @return donationRoyalty The amount for donations.
    function calculateRoyaltySplit(
        uint256 salePrice,
        uint256 authorFee,
        uint256 platformFee,
        uint256 donationFee
    )
        internal
        pure
        returns (
            uint256 authorRoyalty,
            uint256 platformRoyalty,
            uint256 donationRoyalty
        )
    {
        validateFees(authorFee, platformFee, donationFee);

        authorRoyalty = (salePrice * authorFee) / 100;
        platformRoyalty = (salePrice * platformFee) / 100;
        donationRoyalty = (salePrice * donationFee) / 100;

    //    emit RoyaltiesCalculated(authorRoyalty, platformRoyalty, donationRoyalty);

        return (authorRoyalty, platformRoyalty, donationRoyalty);
    }

    /// @notice Validates the provided royalty fee percentages.
    /// @param authorFee Percentage allocated to the author.
    /// @param platformFee Percentage allocated to the platform.
    /// @param donationFee Percentage allocated to donations.
    function validateFees(
        uint256 authorFee,
        uint256 platformFee,
        uint256 donationFee
    ) internal pure {
        if (authorFee + platformFee + donationFee != 100) {
            revert InvalidFeeConfiguration("Fees must sum to 100%");
        }
        if (authorFee > 100 || platformFee > 100 || donationFee > 100) {
            revert InvalidFeeConfiguration("Individual fees exceed 100%");
        }
    }
}
