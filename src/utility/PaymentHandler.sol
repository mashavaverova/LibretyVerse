// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPaymentHandler.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IAuthorManager.sol";
import "../interfaces/IPlatformAdmin.sol";
import "../interfaces/IContentAccess.sol";

/// @title PaymentHandler
/// @notice Handles payments, royalty distribution, and content access grants
contract PaymentHandler is IPaymentHandler, ReentrancyGuard {
    IRoyaltyManager public royaltyManager;
    IAuthorManager public authorManager;
    IPlatformAdmin public platformAdmin;
    IContentAccess public contentAccess;

    // Balances for authors: token -> author -> balance
    mapping(address => mapping(address => uint256)) private authorBalances;

    event PaymentProcessed(address indexed payer, uint256 tokenId, uint256 price, address token);
    event DonationSent(address indexed target, uint256 amount, address token);
    event AuthorWithdrawn(address indexed author, uint256 amount, address indexed token);

    constructor(address _royaltyManager, address _authorManager, address _platformAdmin, address _contentAccess) {
        royaltyManager = IRoyaltyManager(_royaltyManager);
        authorManager = IAuthorManager(_authorManager);
        platformAdmin = IPlatformAdmin(_platformAdmin);
        contentAccess = IContentAccess(_contentAccess);
    }

    function processPayment(uint256 tokenId, uint256 price, address paymentToken, address author)
        external
        payable
        nonReentrant
    {
        require(price > 0, "Invalid payment amount");

        address resolvedAuthor = platformAdmin.getValidAuthor(author);
        require(resolvedAuthor != address(0), "Invalid author");

        if (paymentToken == address(0)) {
            require(msg.value == price, "Incorrect ETH value");
        } else {
            require(IERC20(paymentToken).transferFrom(msg.sender, address(this), price), "ERC20 transfer failed");
        }

        // Retrieve royalty configuration
        (uint256 authorFee, uint256 platformFee,) = royaltyManager.getRoyaltyConfig();

        // Calculate shares
        uint256 authorShare = (price * authorFee) / 100;
        uint256 platformShare = (price * platformFee) / 100;

        // Distribute donations from author's share
        uint256 authorDonations = _distributeAuthorDonations(resolvedAuthor, authorShare, paymentToken);
        uint256 remainingAuthorShare = authorShare - authorDonations;
        authorBalances[paymentToken][resolvedAuthor] += remainingAuthorShare;

        // Distribute donations from platform's share
        uint256 platformDonations = _distributePlatformDonations(platformShare, paymentToken);
        uint256 remainingPlatformShare = platformShare - platformDonations;

        // Send remaining platform share to RoyaltyManager
        if (paymentToken == address(0)) {
            payable(address(royaltyManager)).transfer(remainingPlatformShare);
        } else {
            IERC20(paymentToken).transfer(address(royaltyManager), remainingPlatformShare);
        }

        // Grant content access
        contentAccess.grantAccess(msg.sender, tokenId);

        emit PaymentProcessed(msg.sender, tokenId, price, paymentToken);
    }

    /// @notice Allows authors to withdraw their balance
    /// @param paymentToken Address of the ERC20 token to withdraw, or address(0) for ETH
    function withdraw(address paymentToken) external nonReentrant {
        uint256 balance = authorBalances[paymentToken][msg.sender];
        require(balance > 0, "No balance to withdraw");
        authorBalances[paymentToken][msg.sender] = 0;

        if (paymentToken == address(0)) {
            (bool success,) = msg.sender.call{value: balance}("");
            require(success, "ETH transfer failed");
        } else {
            require(IERC20(paymentToken).transfer(msg.sender, balance), "ERC20 transfer failed");
        }

        emit AuthorWithdrawn(msg.sender, balance, paymentToken);
    }

    /// @notice Distribute author's donation targets
    function _distributeAuthorDonations(address author, uint256 authorShare, address paymentToken)
        internal
        returns (uint256 totalDonations)
    {
        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (authorShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                if (paymentToken == address(0)) {
                    payable(targets[i]).transfer(donationAmount);
                } else {
                    IERC20(paymentToken).transfer(targets[i], donationAmount);
                }
                totalDonations += donationAmount;
                emit DonationSent(targets[i], donationAmount, paymentToken);
            }
        }
        return totalDonations;
    }

    /// @notice Get author's balance
    /// @param paymentToken Address of the token, or address(0) for ETH
    /// @param author Address of the author
    function getAuthorBalance(address paymentToken, address author) external view returns (uint256) {
        return authorBalances[paymentToken][author];
    }

    receive() external payable {}

    function _distributePlatformDonations(uint256 platformShare, address paymentToken)
        internal
        returns (uint256 totalDonations)
    {
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getPlatformDonationTargets();

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (platformShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                if (paymentToken == address(0)) {
                    payable(targets[i]).transfer(donationAmount);
                } else {
                    IERC20(paymentToken).transfer(targets[i], donationAmount);
                }
                totalDonations += donationAmount;
                emit DonationSent(targets[i], donationAmount, paymentToken);
            }
        }
        return totalDonations;
    }
}
