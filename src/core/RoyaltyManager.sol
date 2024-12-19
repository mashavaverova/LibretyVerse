// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../libraries/RoyaltyLib.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IPlatformAdmin.sol";
import "../interfaces/IAuthorManager.sol"; // Import the interface
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol"; // Import console.log

contract RoyaltyManager is IRoyaltyManager, ReentrancyGuard {
    uint256 public authorFee; // Primary sale author share
    uint256 public platformFee; // Primary sale platform share
    uint256 public secondaryRoyalty; // Secondary sale royalty percentage
    uint256 public platformDonationFee; // Platform donation fee (applies to platform share)

    IPlatformAdmin public platformAdmin; // PlatformAdmin contract
    IAuthorManager public authorManager; // Use the IAuthorManager interface

    event RoyaltiesCalculated(uint256 salePrice, uint256 authorShare, uint256 platformShare, uint256 totalDonations);
    event SecondaryRoyaltiesCalculated(uint256 salePrice, uint256 authorRoyalty, uint256 platformRoyalty);
    event FeesUpdated(uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty);

    constructor(
        address _platformAdmin,
        address _authorManager,
        uint256 _authorFee,
        uint256 _platformFee,
        uint256 _secondaryRoyalty
    ) {
        require(_authorFee + _platformFee == 100, "Fees must sum to 100%");
        require(_secondaryRoyalty <= 10, "Secondary royalty too high");
        require(_platformAdmin != address(0) && _authorManager != address(0), "Invalid contract addresses");

        platformAdmin = IPlatformAdmin(_platformAdmin);
        authorManager = IAuthorManager(_authorManager); // Use the interface here
        authorFee = _authorFee;
        platformFee = _platformFee;
        secondaryRoyalty = _secondaryRoyalty;

        emit FeesUpdated(_authorFee, _platformFee, _secondaryRoyalty);
    }

    /// @notice Set fees for author, platform, and secondary royalties
    function setFees(uint256 _authorFee, uint256 _platformFee, uint256 _secondaryRoyalty) external override {
        require(msg.sender == address(platformAdmin), "Only PlatformAdmin");
        require(_authorFee + _platformFee == 100, "Fees must sum to 100%");
        require(_secondaryRoyalty <= 10, "Secondary royalty too high");

        authorFee = _authorFee;
        platformFee = _platformFee;
        secondaryRoyalty = _secondaryRoyalty;

        emit FeesUpdated(_authorFee, _platformFee, _secondaryRoyalty);
    }

    /// @notice Calculate royalties for a primary sale and distribute them
    function distributePrimarySale(uint256 salePrice, address author) external payable override nonReentrant {

    require(salePrice > 0, "Invalid sale price");

    // Resolving the author's address
    address resolvedAuthor = platformAdmin.getValidAuthor(author);
    require(resolvedAuthor != address(0), "Invalid resolved author address");
    require(resolvedAuthor != address(this), "Cannot transfer to contract address");

    // Validate the platform admin address
    require(address(platformAdmin) != address(0), "Invalid platform admin address");
    require(address(platformAdmin) != address(this), "Cannot transfer to contract address");

    // Split the sale price
    uint256 authorShare = (salePrice * authorFee) / 100;
    uint256 platformShare = (salePrice * platformFee) / 100;

    // Distribute donations from author's share
    uint256 authorDonations = distributeAuthorDonations(resolvedAuthor, authorShare);
    uint256 remainingAuthorShare = authorShare - authorDonations;
    uint256 platformDonations = distributePlatformDonations(platformShare);

    uint256 remainingPlatformShare = platformShare - platformDonations;

    // Transfer remaining funds
    (bool authorTransferSuccess,) = payable(resolvedAuthor).call{value: remainingAuthorShare}("");
    require(authorTransferSuccess, "Author transfer failed");

    (bool platformTransferSuccess,) = payable(address(platformAdmin)).call{value: remainingPlatformShare}("");
    require(platformTransferSuccess, "Platform transfer failed");

    emit RoyaltiesCalculated(salePrice, authorShare, platformShare, authorDonations + platformDonations);
}


    /// @notice Distribute donations from the author's share
    function distributeAuthorDonations(address author, uint256 authorShare) internal returns (uint256 totalDonations) {
        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (authorShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                (bool success,) = payable(targets[i]).call{value: donationAmount}("");
                require(success, "Author donation transfer failed");
                totalDonations += donationAmount;
            }
        }
        return totalDonations;
    }

    /// @notice Distribute donations from the platform's share
    function distributePlatformDonations(uint256 platformShare) internal returns (uint256 totalDonations) {
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getPlatformDonationTargets();

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (platformShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                (bool success,) = payable(targets[i]).call{value: donationAmount}("");
                require(success, "Platform donation transfer failed");
                totalDonations += donationAmount;
            }
        }
        return totalDonations;
    }

    /// @notice Calculate secondary royalties for a sale
    function calculateSecondaryRoyalties(uint256 salePrice)
        public
        view
        override
        returns (uint256 authorRoyalty, uint256 platformRoyalty)
      {
        // Validate inputs
        require(salePrice > 0, "Invalid sale price");
        require(secondaryRoyalty > 0 && secondaryRoyalty <= 100, "Invalid secondary royalty percentage");

        // Calculate royalties
        authorRoyalty = (salePrice * secondaryRoyalty) / 100;
        platformRoyalty = authorRoyalty; // Assumes a 50/50 split between author and platform
    }


    /// @notice Distribute secondary sale royalties
    function distributeSecondarySale(uint256 salePrice, address author) external payable override nonReentrant {
        require(salePrice > 0, "Invalid sale price");
        address resolvedAuthor = platformAdmin.getValidAuthor(author);

        (uint256 authorRoyalty, uint256 platformRoyalty) = calculateSecondaryRoyalties(salePrice);

         // Safely transfer royalties
        (bool authorTransferSuccess,) = payable(resolvedAuthor).call{value: authorRoyalty}("");
        require(authorTransferSuccess, "Author royalty transfer failed");

        (bool platformTransferSuccess,) = payable(address(platformAdmin)).call{value: platformRoyalty}("");
        require(platformTransferSuccess, "Platform royalty transfer failed");

        emit SecondaryRoyaltiesCalculated(salePrice, authorRoyalty, platformRoyalty);
    }

    /// @notice Update platform donation fee
    function updatePlatformDonationFee(uint256 _platformDonationFee) external override {
        require(msg.sender == address(platformAdmin), "Only PlatformAdmin");
        require(_platformDonationFee <= 100, "Donation fee too high");
        platformDonationFee = _platformDonationFee;
    }

    /// @notice Get the royalty configuration
    function getRoyaltyConfig()
        public
        view
        returns (uint256 _authorFee, uint256 _platformFee, uint256 _secondaryRoyalty)
    {
        return (authorFee, platformFee, secondaryRoyalty);
    }
}
