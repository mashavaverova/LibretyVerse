// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IPlatformAdmin.sol";
import "../interfaces/IPaymentHandler.sol";

/// @title CrossChainBridge
/// @notice Enables NFTs to be transferred across blockchain networks.
contract CrossChainBridge is AccessControl {
    // Role for bridge administrators
    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");

    // State variables
    IERC721 public nftContract; // NFT contract to interact with
    IPlatformAdmin public platformAdmin; // Platform admin contract
    IPaymentHandler public paymentHandler; // Optional payment handler

    // Mapping to track in-transit tokens
    mapping(uint256 => bool) private inTransit;

    // Events
    event NFTTransferInitiated(uint256 indexed tokenId, address indexed sender, address targetChain);
    event NFTReceived(uint256 indexed tokenId, address indexed newOwner, address sourceChain);

    /// @notice Constructor to initialize the contract.
    /// @param _nftContract Address of the NFT contract.
    /// @param _platformAdmin Address of the platform admin contract.
    /// @param _paymentHandler Address of the payment handler (optional, use address(0) if not needed).
    constructor(address _nftContract, address _platformAdmin, address _paymentHandler) {
        require(_nftContract != address(0), "CrossChainBridge: Invalid NFT contract address");
        require(_platformAdmin != address(0), "CrossChainBridge: Invalid PlatformAdmin address");

        nftContract = IERC721(_nftContract);
        platformAdmin = IPlatformAdmin(_platformAdmin);
        paymentHandler = IPaymentHandler(_paymentHandler);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BRIDGE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Initiates the transfer of an NFT to another blockchain.
    /// @param tokenId The ID of the token to transfer.
    /// @param targetChain The target blockchain address or identifier.
    function transferNFT(uint256 tokenId, address targetChain) external payable {
        require(targetChain != address(0), "CrossChainBridge: Invalid target chain");
        require(!inTransit[tokenId], "CrossChainBridge: Token already in transit");
        require(nftContract.ownerOf(tokenId) == msg.sender, "CrossChainBridge: Not the token owner");

        // Optionally process bridging fee
        if (address(paymentHandler) != address(0)) {
            paymentHandler.processPayment{value: msg.value}(tokenId, msg.value, address(0));
        }

        // Mark token as in transit
        inTransit[tokenId] = true;

        // Transfer the NFT to the bridge contract
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        emit NFTTransferInitiated(tokenId, msg.sender, targetChain);
    }

    /// @notice Handles the receipt of an NFT from another blockchain.
    /// @param tokenId The ID of the token being received.
    /// @param newOwner The address of the new owner on the receiving chain.
    /// @param sourceChain The source blockchain address or identifier.
    function receiveNFT(uint256 tokenId, address newOwner, address sourceChain) external onlyRole(BRIDGE_ADMIN_ROLE) {
        require(newOwner != address(0), "CrossChainBridge: Invalid new owner address");
        require(inTransit[tokenId], "CrossChainBridge: Token not in transit");

        // Mark token as no longer in transit
        inTransit[tokenId] = false;

        // Transfer the NFT to the new owner
        nftContract.transferFrom(address(this), newOwner, tokenId);

        emit NFTReceived(tokenId, newOwner, sourceChain);
    }

    /// @notice Checks the transfer status of a token.
    /// @param tokenId The ID of the token to query.
    /// @return inTransitStatus True if the token is currently in transit, false otherwise.
    function getTransferStatus(uint256 tokenId) external view returns (bool inTransitStatus) {
        return inTransit[tokenId];
    }
}
