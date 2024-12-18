// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../libraries/MetadataLib.sol";

// @title ILibretyNFT
// @notice Interface for managing NFT minting, metadata retrieval, and book management.
interface ILibretyNFT {
    /// @notice Mints a new NFT with the specified metadata and maximum number of copies.
    /// @param metadata The metadata associated with the NFT.
    /// @param maxCopies The maximum number of copies for this NFT.
    /// @param price The price of the NFT in wei.
    function mintNFT(MetadataLib.Metadata memory metadata, uint256 maxCopies, uint256 price) external;

    /// @notice Mints a new copy of an existing book.
    /// @param bookId The ID of the book to mint a copy for.
    function mintCopy(uint256 bookId) external payable;

    /// @notice Retrieves metadata for a specific token ID.
    /// @param tokenId The ID of the token to retrieve metadata for.
    /// @return metadata The metadata associated with the token.
    function getMetadata(uint256 tokenId) external view returns (MetadataLib.Metadata memory metadata);

    /// @notice Retrieves information about a book by its ID.
    /// @param bookId The ID of the book to retrieve.
    /// @return metadata The metadata associated with the book.
    /// @return maxCopies The maximum number of copies for the book.
    /// @return mintedCopies The number of copies already minted for the book.
    /// @return price The price of the book in wei.
    /// @return author The address of the book's author.
    function getBook(uint256 bookId)
        external
        view
        returns (
            MetadataLib.Metadata memory metadata,
            uint256 maxCopies,
            uint256 mintedCopies,
            uint256 price,
            address author
        );

    /// @notice Updates the address of the content access contract.
    /// @param newContentAccess The address of the new content access contract.
    function updateContentAccess(address newContentAccess) external;

    /// @notice Updates the address of the royalty manager contract.
    /// @param newRoyaltyManager The address of the new royalty manager contract.
    function updateRoyaltyManager(address newRoyaltyManager) external;

    /// @notice Updates the address of the payment handler contract.
    /// @param newPaymentHandler The address of the new payment handler contract.
    function updatePaymentHandler(address newPaymentHandler) external;
}
