// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library RoyaltyLib {
    error InvalidFeeConfiguration(string reason);

    function calculateRoyalties(uint256 salePrice, uint256 authorFee, uint256 platformFee, uint256 donationFee)
        internal
        pure
        returns (uint256 authorRoyalty, uint256 platformRoyalty, uint256 donationRoyalty)
    {
        validateFees(authorFee, platformFee, donationFee);

        authorRoyalty = (salePrice * authorFee) / 100;
        platformRoyalty = (salePrice * platformFee) / 100;
        donationRoyalty = (salePrice * donationFee) / 100;

        // emit RoyaltiesCalculated(authorRoyalty, platformRoyalty, donationRoyalty);

        return (authorRoyalty, platformRoyalty, donationRoyalty);
    }

    function validateFees(uint256 authorFee, uint256 platformFee, uint256 donationFee) internal pure {
        if (authorFee + platformFee + donationFee != 100) {
            revert InvalidFeeConfiguration("Fees must sum to 100%");
        }
        if (authorFee > 100 || platformFee > 100 || donationFee > 100) {
            revert InvalidFeeConfiguration("Individual fees exceed 100%");
        }
    }
}
