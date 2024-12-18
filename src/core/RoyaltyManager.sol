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
        console.log("Starting distributePrimarySale...");
        console.log("Sale Price:", salePrice);
        console.log("Caller Address:", msg.sender);
        console.log("Author Address Provided:", author);
        console.log("Contract Balance Before:", address(this).balance);

        require(salePrice > 0, "Invalid sale price");

        // Resolving the author's address
        address resolvedAuthor = platformAdmin.getValidAuthor(author);
        console.log("Resolved Author Address:", resolvedAuthor);

        // Split the sale price
        uint256 authorShare = (salePrice * authorFee) / 100;
        uint256 platformShare = (salePrice * platformFee) / 100;
        console.log("Author Fee Percentage:", authorFee);
        console.log("Platform Fee Percentage:", platformFee);
        console.log("Initial Author Share:", authorShare);
        console.log("Initial Platform Share:", platformShare);

        // Distribute donations from author's share
        uint256 authorDonations = distributeAuthorDonations(resolvedAuthor, authorShare);
        console.log("Donations from Author's Share:", authorDonations);

        uint256 remainingAuthorShare = authorShare - authorDonations;
        console.log("Remaining Author Share After Donations:", remainingAuthorShare);

        // Distribute donations from platform's share
        uint256 platformDonations = distributePlatformDonations(platformShare);
        console.log("Donations from Platform's Share:", platformDonations);

        uint256 remainingPlatformShare = platformShare - platformDonations;
        console.log("Remaining Platform Share After Donations:", remainingPlatformShare);

        // Transfer remaining funds
        console.log("Transferring Remaining Author Share:", remainingAuthorShare, "to:", resolvedAuthor);
        payable(resolvedAuthor).transfer(remainingAuthorShare);

        console.log(
            "Transferring Remaining Platform Share:",
            remainingPlatformShare,
            "to Platform Admin at:",
            address(platformAdmin)
        );
        payable(address(platformAdmin)).transfer(remainingPlatformShare);

        emit RoyaltiesCalculated(salePrice, authorShare, platformShare, authorDonations + platformDonations);
        console.log("RoyaltiesCalculated Event Emitted:");
        console.log("  Sale Price:", salePrice);
        console.log("  Total Author Share:", authorShare);
        console.log("  Total Platform Share:", platformShare);
        console.log("  Total Donations:", authorDonations + platformDonations);

        console.log("Contract Balance After:", address(this).balance);
        console.log("distributePrimarySale Completed.");
    }

    /// @notice Distribute donations from the author's share
    function distributeAuthorDonations(address author, uint256 authorShare) internal returns (uint256 totalDonations) {
        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (authorShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                payable(targets[i]).transfer(donationAmount);
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
                payable(targets[i]).transfer(donationAmount);
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
        require(salePrice > 0, "Invalid sale price");

        authorRoyalty = (salePrice * secondaryRoyalty) / 100;
        platformRoyalty = (salePrice * secondaryRoyalty) / 100;
    }

    /// @notice Distribute secondary sale royalties
    function distributeSecondarySale(uint256 salePrice, address author) external payable override nonReentrant {
        require(salePrice > 0, "Invalid sale price");
        address resolvedAuthor = platformAdmin.getValidAuthor(author);

        (uint256 authorRoyalty, uint256 platformRoyalty) = calculateSecondaryRoyalties(salePrice);

        payable(resolvedAuthor).transfer(authorRoyalty);
        payable(address(platformAdmin)).transfer(platformRoyalty);

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
