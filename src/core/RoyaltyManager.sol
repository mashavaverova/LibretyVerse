// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IPlatformAdmin.sol";
import "../interfaces/IAuthorManager.sol"; 
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol"; 

/**
 * @title RoyaltyManager
 * @dev Handles the calculation and distribution of royalties for primary and secondary sales, including donations.
 * @notice Created by @mashavaverova
 */

contract RoyaltyManager is IRoyaltyManager, ReentrancyGuard {
      /**
     * @notice Primary sale author share as a percentage.
     */
    uint256 public authorFee;

    /**
     * @notice Primary sale platform share as a percentage.
     */
    uint256 public platformFee;

    /**
     * @notice Secondary sale royalty percentage (applies to both author and platform).
     */
    uint256 public secondaryRoyalty;

    /**
     * @notice Platform donation fee (applies to platform's share).
     */
    uint256 public platformDonationFee;

    /**
     * @notice Reference to the PlatformAdmin contract.
     */
    IPlatformAdmin public platformAdmin;

    /**
     * @notice Reference to the AuthorManager contract.
     */
    IAuthorManager public authorManager; 

    /** @notice Events */
    event RoyaltiesCalculated(uint256 salePrice, uint256 authorShare, uint256 platformShare, uint256 totalDonations);
    event SecondaryRoyaltiesCalculated(uint256 salePrice, uint256 authorRoyalty, uint256 platformRoyalty);
    event FeesUpdated(uint256 authorFee, uint256 platformFee, uint256 secondaryRoyalty);

    /**
     * @notice Constructor to initialize the contract with platform admin, author manager, and royalty settings.
     * @param _platformAdmin Address of the PlatformAdmin contract.
     * @param _authorManager Address of the AuthorManager contract.
     * @param _authorFee Primary sale author share percentage.
     * @param _platformFee Primary sale platform share percentage.
     * @param _secondaryRoyalty Secondary sale royalty percentage.
     */
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

    /* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Updates the royalty configuration for primary and secondary sales.
     * @param _authorFee New author fee percentage.
     * @param _platformFee New platform fee percentage.
     * @param _secondaryRoyalty New secondary royalty percentage.
     * @dev Only callable by the PlatformAdmin contract.
     */
    function setFees(uint256 _authorFee, uint256 _platformFee, uint256 _secondaryRoyalty) external override {
        require(msg.sender == address(platformAdmin), "Only PlatformAdmin");
        require(_authorFee + _platformFee == 100, "Fees must sum to 100%");
        require(_secondaryRoyalty <= 10, "Secondary royalty too high");

        authorFee = _authorFee;
        platformFee = _platformFee;
        secondaryRoyalty = _secondaryRoyalty;

        emit FeesUpdated(_authorFee, _platformFee, _secondaryRoyalty);
    }

    /**
     * @notice Distributes primary sale royalties and donations.
     * @param salePrice The total sale price.
     * @param author The address of the author.
     * @dev Splits royalties and handles donations for both the author and platform.
     */
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
    /**
     * @notice Distributes secondary sale royalties.
     * @param salePrice The total sale price.
     * @param author The address of the author.
     */
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

    /**
     * @notice Updates the platform donation fee.
     * @param _platformDonationFee New platform donation fee percentage.
     * @dev Only callable by the PlatformAdmin contract.
     */
    function updatePlatformDonationFee(uint256 _platformDonationFee) external override {
        require(msg.sender == address(platformAdmin), "Only PlatformAdmin");
        require(_platformDonationFee <= 100, "Donation fee too high");
        platformDonationFee = _platformDonationFee;
    }

/* =======================================================
                      Internal Functions
   ======================================================= */

    /**
     * @notice Distributes donations from the author's share to their specified donation targets.
     * @param author Address of the author whose donations are being distributed.
     * @param authorShare The total share allocated to the author.
     * @return totalDonations The total amount donated from the author's share.
     * @dev Uses the AuthorManager contract to retrieve donation targets and percentages.
     */
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

    /**
     * @notice Distributes donations from the platform's share to the platform's specified donation targets.
     * @param platformShare The total share allocated to the platform.
     * @return totalDonations The total amount donated from the platform's share.
     * @dev Uses the PlatformAdmin contract to retrieve donation targets and percentages.
     */
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

/* =======================================================
                      View Functions
   ======================================================= */

    /**
     * @notice Calculates secondary royalties for a sale.
     * @param salePrice The total sale price.
     * @return authorRoyalty The royalty allocated to the author.
     * @return platformRoyalty The royalty allocated to the platform.
     * @dev Assumes a 50/50 split of secondary royalties between the author and the platform.
     */
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

    /**
     * @notice Retrieves the current royalty configuration.
     * @return _authorFee The author fee percentage.
     * @return _platformFee The platform fee percentage.
     * @return _secondaryRoyalty The secondary royalty percentage.
     */
    function getRoyaltyConfig()
        public
        view
        returns (uint256 _authorFee, uint256 _platformFee, uint256 _secondaryRoyalty)
    {
        return (authorFee, platformFee, secondaryRoyalty);
    }
}
