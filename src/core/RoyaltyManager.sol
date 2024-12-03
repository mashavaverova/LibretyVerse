// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../libraries/RoyaltyLib.sol";

/// @title RoyaltyManager
/// @notice Manages and updates royalty percentages for authors, platforms, and donations, including ERC-2981 compatibility.
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

    /// @notice Event emitted when royalty fees are updated.
    /// @param authorFee The updated percentage for the author.
    /// @param platformFee The updated percentage for the platform.
    /// @param donationFee The updated percentage for donations.
    event FeesUpdated(uint256 authorFee, uint256 platformFee, uint256 donationFee);

    /// @notice Event emitted when royalties are calculated.
    /// @param salePrice The total sale price of the NFT/book.
    /// @param authorRoyalty The calculated royalty for the author.
    /// @param platformRoyalty The calculated royalty for the platform.
    /// @param donationRoyalty The calculated royalty for donations.
    event RoyaltyCalculated(
        uint256 salePrice,
        uint256 authorRoyalty,
        uint256 platformRoyalty,
        uint256 donationRoyalty
    );

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

        emit FeesUpdated(_authorFee, _platformFee, _donationFee);
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
        require(
            _authorFee <= 100 && _platformFee <= 100 && _donationFee <= 100,
            "RoyaltyManager: Fee percentages must not exceed 100%"
        );

        authorFee = _authorFee;
        platformFee = _platformFee;
        donationFee = _donationFee;

        emit FeesUpdated(_authorFee, _platformFee, _donationFee);
    }

    /// @notice Calculates royalty splits for a given sale price.
    /// @param salePrice The total sale price of the NFT/book.
    /// @return authorRoyalty The calculated royalty for the author.
    /// @return platformRoyalty The calculated royalty for the platform.
    /// @return donationRoyalty The calculated royalty for donations.
    function calculateRoyaltySplit(uint256 salePrice)
        external
        returns (
            uint256 authorRoyalty,
            uint256 platformRoyalty,
            uint256 donationRoyalty
        )
    {
        (authorRoyalty, platformRoyalty, donationRoyalty) = RoyaltyLib.calculateRoyaltySplit(
            salePrice,
            authorFee,
            platformFee,
            donationFee
        );

        emit RoyaltyCalculated(salePrice, authorRoyalty, platformRoyalty, donationRoyalty);

        return (authorRoyalty, platformRoyalty, donationRoyalty);
    }

    /// @notice Returns royalty information compatible with ERC-2981.
    /// @param salePrice The total sale price for which royalty needs to be calculated.
    /// @return receiver The address to receive the royalty (admin address for now).
    /// @return royaltyAmount The amount of royalty to be paid.
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 authorRoyalty = (salePrice * authorFee) / 100;
        return (admin, authorRoyalty); // Replace `admin` with the actual author address if dynamic.
    }
}
