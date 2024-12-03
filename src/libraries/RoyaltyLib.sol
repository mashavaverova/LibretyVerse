// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


/// @title RoyaltyLib
/// @notice Provides reusable logic for royalty calculations.
library RoyaltyLib {
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
        require(
            authorFee + platformFee + donationFee == 100,
            "RoyaltyLib: Fees must sum to 100%"
        );

        authorRoyalty = (salePrice * authorFee) / 100;
        platformRoyalty = (salePrice * platformFee) / 100;
        donationRoyalty = (salePrice * donationFee) / 100;

        return (authorRoyalty, platformRoyalty, donationRoyalty);
    }
}
