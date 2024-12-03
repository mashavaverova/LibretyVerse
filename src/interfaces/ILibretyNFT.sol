// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../libraries/MetadataLib.sol";

/// @title ILibretyNFT
/// @notice Interface for managing NFT minting and metadata retrieval.
interface ILibretyNFT {
    /// @notice Mints a new NFT with the specified metadata and maximum number of copies.
    /// @param metadata The metadata associated with the NFT.
    /// @param maxCopies The maximum number of copies for this NFT.
    function mintNFT(MetadataLib.Metadata memory metadata, uint256 maxCopies) external;

    /// @notice Retrieves metadata for a specific token ID.
    /// @param tokenId The ID of the token to query.
    /// @return metadata The metadata associated with the token.
    function getMetadata(uint256 tokenId) external view returns (MetadataLib.Metadata memory metadata);
}
