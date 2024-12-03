// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../libraries/RoyaltyLib.sol";

/// @title RoyaltyManager
/// @notice Manages and updates royalty percentages for authors, platforms, and donations.
contract RoyaltyManager {
    uint256 public authorFee;
    uint256 public platformFee;
    uint256 public donationFee;

    address public admin;

    /// @dev Ensures only the admin can call restricted functions.
    modifier onlyAdmin() {
        require(msg.sender == admin, "RoyaltyManager: Not admin");
        _;
    }

    /// @notice Initializes the royalty manager with default percentages.
    /// @param _authorFee The initial percentage for the author.
    /// @param _platformFee The initial percentage for the platform.
    /// @param _donationFee The initial percentage for donations.
    constructor(uint256 _authorFee, uint256 _platformFee, uint256 _donationFee) {
        require(
            _authorFee + _platformFee + _donationFee == 100,
            "RoyaltyManager: Fees must sum to 100%"
        );
        authorFee = _authorFee;
        platformFee = _platformFee;
        donationFee = _donationFee;
        admin = msg.sender;
    }

    /// @notice Updates the royalty percentages.
    /// @param _authorFee The new percentage for the author.
    /// @param _platformFee The new percentage for the platform.
    /// @param _donationFee The new percentage for donations.
    function setFees(
        uint256 _authorFee,
        uint256 _platformFee,
        uint256 _donationFee
    ) external onlyAdmin {
        require(
            _authorFee + _platformFee + _donationFee == 100,
            "RoyaltyManager: Fees must sum to 100%"
        );
        authorFee = _authorFee;
        platformFee = _platformFee;
        donationFee = _donationFee;
    }

    /// @notice Calculates royalty splits for a given sale price.
    /// @param salePrice The total sale price of the NFT/book.
    /// @return authorRoyalty The calculated royalty for the author.
    /// @return platformRoyalty The calculated royalty for the platform.
    /// @return donationRoyalty The calculated royalty for donations.
    function calculateRoyaltySplit(uint256 salePrice)
        external
        view
        returns (
            uint256 authorRoyalty,
            uint256 platformRoyalty,
            uint256 donationRoyalty
        )
    {
        return
            RoyaltyLib.calculateRoyaltySplit(
                salePrice,
                authorFee,
                platformFee,
                donationFee
            );
    }
}
