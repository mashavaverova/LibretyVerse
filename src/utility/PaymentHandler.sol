// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPaymentHandler.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IContentAccess.sol";
import "../interfaces/ILibretyNFT.sol";

/// @title PaymentHandler
/// @notice Handles payments, royalty distribution, and content access grants.
contract PaymentHandler is IPaymentHandler, ReentrancyGuard {
    IRoyaltyManager public royaltyManager;
    IContentAccess public contentAccess;
    ILibretyNFT public libretyNFT;

    mapping(address => mapping(address => uint256)) private balances; // token -> recipient -> amount
    mapping(string => address) public authorAddresses;

    event PaymentProcessed(uint256 indexed tokenId, uint256 amount, address indexed token);
    event RoyaltiesDistributed(uint256 indexed tokenId, uint256 authorAmount, uint256 platformAmount, uint256 donationAmount);
    event Withdrawal(address indexed recipient, uint256 amount, address indexed token);

    constructor(address _royaltyManager, address _contentAccess, address _libretyNFT) {
        royaltyManager = IRoyaltyManager(_royaltyManager);
        contentAccess = IContentAccess(_contentAccess);
        libretyNFT = ILibretyNFT(_libretyNFT);
    }

    function registerAuthor(string memory author, address wallet) external {
        require(wallet != address(0), "PaymentHandler: Invalid address");
        authorAddresses[author] = wallet;
    }

    function processPayment(uint256 tokenId, uint256 amount, address token) external payable override nonReentrant {
        if (token == address(0)) {
            require(msg.value == amount, "PaymentHandler: Incorrect value sent");
        } else {
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "PaymentHandler: Transfer failed");
        }

        (uint256 authorFee, uint256 platformFee, uint256 donationFee) = royaltyManager.calculateRoyalties(amount);

        MetadataLib.Metadata memory metadata = libretyNFT.getMetadata(tokenId);
        address authorAddress = authorAddresses[metadata.author];
        require(authorAddress != address(0), "PaymentHandler: Author address not registered");

        balances[token][authorAddress] += authorFee;
        balances[token][msg.sender] += platformFee;
        balances[token][address(this)] += donationFee;

        contentAccess.grantAccess(msg.sender, tokenId);

        emit PaymentProcessed(tokenId, amount, token);
        emit RoyaltiesDistributed(tokenId, authorFee, platformFee, donationFee);
    }

    function withdraw(address recipient, uint256 amount) external override nonReentrant {
        address token = msg.sender;
        require(balances[token][recipient] >= amount, "PaymentHandler: Insufficient balance");

        balances[token][recipient] -= amount;

        if (token == address(0)) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "PaymentHandler: Transfer failed");
        } else {
            require(IERC20(token).transfer(recipient, amount), "PaymentHandler: Transfer failed");
        }

        emit Withdrawal(recipient, amount, token);
    }

    function getBalance(address token) external view override returns (uint256 balance) {
        return balances[token][msg.sender];
    }

    function getPaymentDetails(uint256 /* tokenId */) external pure override returns (uint256 totalPaid, uint256 lastPayment) {
        return (0, 0);
    }
}
