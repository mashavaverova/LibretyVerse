// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPaymentHandler.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IAuthorManager.sol";
import "../interfaces/IPlatformAdmin.sol";
import "../interfaces/IContentAccess.sol";

/**
 * @title PaymentHandler
 * @dev Handles payments, royalty distribution, donations, and granting content access for NFTs.
 * @notice created by @mashavaverova
 */
contract PaymentHandler is IPaymentHandler, ReentrancyGuard {
        using SafeERC20 for IERC20;

  /**
     * @notice Reference to the RoyaltyManager contract.
     */
    IRoyaltyManager public royaltyManager;

    /**
     * @notice Reference to the AuthorManager contract.
     */
    IAuthorManager public authorManager;

    /**
     * @notice Reference to the PlatformAdmin contract.
     */
    IPlatformAdmin public platformAdmin;

    /**
     * @notice Reference to the ContentAccess contract.
     */
    IContentAccess public contentAccess;

    /**
     * @notice Mapping of author balances by payment token.
     * @dev authorBalances[token][author] = balance.
     */
    mapping(address => mapping(address => uint256)) private authorBalances;

   /** @notice Events */
    event PaymentProcessed(address indexed payer, uint256 tokenId, uint256 price, address token);
    event DonationSent(address indexed target, uint256 amount, address token);
    event AuthorWithdrawn(address indexed author, uint256 amount, address indexed token);

    /**
     * @notice Constructor to initialize the contract.
     * @param _royaltyManager Address of the RoyaltyManager contract.
     * @param _authorManager Address of the AuthorManager contract.
     * @param _platformAdmin Address of the PlatformAdmin contract.
     * @param _contentAccess Address of the ContentAccess contract.
     */
    constructor(address _royaltyManager, address _authorManager, address _platformAdmin, address _contentAccess) {
        royaltyManager = IRoyaltyManager(_royaltyManager);
        authorManager = IAuthorManager(_authorManager);
        platformAdmin = IPlatformAdmin(_platformAdmin);
        contentAccess = IContentAccess(_contentAccess);
    }

    /* =======================================================
                     External Functions
   ======================================================= */

    /**
     * @notice Processes a payment, distributes royalties and donations, and grants content access.
     * @param tokenId The ID of the token associated with the payment.
     * @param price The payment amount.
     * @param paymentToken The address of the payment token (address(0) for ETH).
     * @param author The address of the author.
     * @dev Ensures proper distribution of royalties and donations.
     */
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
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), price);
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
            (bool success,) = payable(address(royaltyManager)).call{value: remainingPlatformShare}("");
            require(success, "ETH transfer to RoyaltyManager failed");
        } else {
            IERC20(paymentToken).safeTransfer(address(royaltyManager), remainingPlatformShare);
        }

        // Grant content access
        contentAccess.grantAccess(msg.sender, tokenId);

        emit PaymentProcessed(msg.sender, tokenId, price, paymentToken);
    }

    /**
     * @notice Allows authors to withdraw their balance.
     * @param paymentToken The address of the payment token to withdraw (address(0) for ETH).
     * @dev Ensures the withdrawal amount is available and valid.
     */
    function withdraw(address paymentToken) external nonReentrant {
        uint256 balance = authorBalances[paymentToken][msg.sender];
        require(balance > 0, "No balance to withdraw");
        authorBalances[paymentToken][msg.sender] = 0;

        if (paymentToken == address(0)) {
            (bool success,) = payable(msg.sender).call{value: balance}("");
            require(success, "ETH withdrawal failed");
        } else {
            IERC20(paymentToken).safeTransfer(msg.sender, balance);
        }

        emit AuthorWithdrawn(msg.sender, balance, paymentToken);
    }

    /**
     * @notice Retrieves an author's balance for a specific token.
     * @param paymentToken The address of the payment token (address(0) for ETH).
     * @param author The address of the author.
     * @return The author's balance in the specified payment token.
     */
    function getAuthorBalance(address paymentToken, address author) external view returns (uint256) {
        return authorBalances[paymentToken][author];
    }

/* =======================================================
                      Internal Functions
   ======================================================= */

    /**
     * @notice Internal function to distribute donations from an author's share.
     * @param author The address of the author.
     * @param authorShare The share allocated to the author.
     * @param paymentToken The address of the payment token (address(0) for ETH).
     * @return totalDonations The total amount donated from the author's share.
     */    
    function _distributeAuthorDonations(address author, uint256 authorShare, address paymentToken)
        internal
        returns (uint256 totalDonations)
    {
        (address[] memory targets, uint256[] memory percentages) = authorManager.getAuthorDonationTargets(author);

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (authorShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                if (paymentToken == address(0)) {
                    (bool success,) = payable(targets[i]).call{value: donationAmount}("");
                    require(success, "ETH donation failed");
                } else {
                    IERC20(paymentToken).safeTransfer(targets[i], donationAmount);
                }
                totalDonations += donationAmount;
                emit DonationSent(targets[i], donationAmount, paymentToken);
            }
        }
        return totalDonations;
    }

    /**
     * @notice Internal function to distribute donations from the platform's share.
     * @param platformShare The share allocated to the platform.
     * @param paymentToken The address of the payment token (address(0) for ETH).
     * @return totalDonations The total amount donated from the platform's share.
     */
    function _distributePlatformDonations(uint256 platformShare, address paymentToken)
        internal
        returns (uint256 totalDonations)
    {
        (address[] memory targets, uint256[] memory percentages) = platformAdmin.getPlatformDonationTargets();

        for (uint256 i = 0; i < targets.length; i++) {
            uint256 donationAmount = (platformShare * percentages[i]) / 100;
            if (donationAmount > 0) {
                if (paymentToken == address(0)) {
                    (bool success,) = payable(targets[i]).call{value: donationAmount}("");
                    require(success, "ETH donation failed");
                } else {
                    IERC20(paymentToken).safeTransfer(targets[i], donationAmount);
                }
                totalDonations += donationAmount;
                emit DonationSent(targets[i], donationAmount, paymentToken);
            }
        }
        return totalDonations;
    }

    /* =======================================================
                     Fallback Function
   ======================================================= */
    /**
     * @notice Fallback function to handle ETH transfers to the contract.
     */
    receive() external payable {}
}
