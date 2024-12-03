// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title ICrossChainBridge
/// @notice Interface for transferring NFTs across blockchain networks.
interface ICrossChainBridge {
    /// @notice Initiates the transfer of an NFT to another blockchain.
    /// @param tokenId The ID of the token to transfer.
    /// @param targetChain The target blockchain address or identifier.
    function transferNFT(uint256 tokenId, address targetChain) external;

    /// @notice Handles the receipt of an NFT from another blockchain.
    /// @param tokenId The ID of the token being received.
    /// @param owner The address of the new owner on the receiving chain.
    function receiveNFT(uint256 tokenId, address owner) external;

    /// @notice Checks the transfer status of a token.
    /// @param tokenId The ID of the token to query.
    /// @return inTransit True if the token is currently in transit, false otherwise.
    function getTransferStatus(uint256 tokenId) external view returns (bool inTransit);

    /// @notice Emitted when an NFT transfer is initiated.
    /// @param tokenId The ID of the token being transferred.
    /// @param sender The address of the sender initiating the transfer.
    /// @param targetChain The target blockchain address or identifier.
    event NFTTransferInitiated(uint256 indexed tokenId, address indexed sender, address targetChain);

    /// @notice Emitted when an NFT is received from another blockchain.
    /// @param tokenId The ID of the token being received.
    /// @param owner The address of the new owner on the receiving chain.
    /// @param sourceChain The source blockchain address or identifier.
    event NFTReceived(uint256 indexed tokenId, address indexed owner, address sourceChain);
}
