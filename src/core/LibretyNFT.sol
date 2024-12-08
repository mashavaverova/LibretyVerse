// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IContentAccess.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../libraries/MetadataLib.sol";

/// @title LibretyNFT
/// @notice Manages minting of books as NFTs, copy limits, and metadata retrieval.
contract LibretyNFT is ERC721, AccessControl {
    using MetadataLib for MetadataLib.Metadata;

    // Constants for roles
    bytes32 public constant AUTHOR_ROLE = keccak256("AUTHOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // State variables
    uint256 private _bookIdCounter; // Tracks book IDs
    uint256 private _tokenIdCounter; // Tracks token IDs
    IContentAccess public contentAccess; // Content access contract
    IRoyaltyManager public royaltyManager; // Royalty manager contract

    struct Book {
        MetadataLib.Metadata metadata; // Book metadata
        uint256 maxCopies;             // Maximum number of copies
        uint256 mintedCopies;          // Number of minted copies
    }

    // Mappings
    mapping(uint256 => Book) private books; // Maps bookId to Book
    mapping(uint256 => uint256) private tokenToBookId; // Maps tokenId to bookId

    // Events
    event BookMinted(uint256 indexed bookId, address indexed author, string title, uint256 maxCopies);
    event CopyMinted(uint256 indexed bookId, uint256 indexed tokenId, address indexed recipient);

    /// @notice Constructor
    /// @param _name The name of the NFT collection.
    /// @param _symbol The symbol of the NFT collection.
    /// @param _contentAccess The address of the content access contract.
    /// @param _royaltyManager The address of the royalty manager contract.
    constructor(
        string memory _name,
        string memory _symbol,
        address _contentAccess,
        address _royaltyManager
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        contentAccess = IContentAccess(_contentAccess);
        royaltyManager = IRoyaltyManager(_royaltyManager);
    }

        /// @notice Resolves interface conflicts by overriding supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mints a new book NFT.
    /// @param metadata The metadata associated with the book.
    /// @param maxCopies The maximum number of copies for the book.
    function mintNFT(MetadataLib.Metadata memory metadata, uint256 maxCopies) external onlyRole(AUTHOR_ROLE) {
        // Validate metadata
        (string memory field, string memory reason) = metadata.validateMetadata();
        require(bytes(field).length == 0, reason);

        // Increment book ID and store book metadata
        uint256 bookId = _bookIdCounter;
        _bookIdCounter++;
        books[bookId] = Book(metadata, maxCopies, 0);

        // Configure royalties for the book
        royaltyManager.setRoyaltyConfig(80, 10, 10); // Example: 80% author, 10% platform, 10% donation

        emit BookMinted(bookId, msg.sender, metadata.title, maxCopies);
    }

    /// @notice Mints a copy of an existing book.
    /// @param bookId The ID of the book.
    function mintCopy(uint256 bookId) external {
        Book storage book = books[bookId];
        require(book.maxCopies > 0, "Book does not exist");
        require(book.mintedCopies < book.maxCopies, "Max copies reached");

        // Increment token ID and mint the NFT
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        book.mintedCopies++;
        tokenToBookId[tokenId] = bookId;
        _mint(msg.sender, tokenId);

        // Grant content access to the buyer
        contentAccess.grantAccess(msg.sender, tokenId);

        emit CopyMinted(bookId, tokenId, msg.sender);
    }

    /// @notice Retrieves metadata for a specific token.
    /// @param tokenId The token ID.
    /// @return The metadata associated with the token.
    function getMetadata(uint256 tokenId) external view returns (MetadataLib.Metadata memory) {
        uint256 bookId = tokenToBookId[tokenId];
        require(books[bookId].maxCopies > 0, "Invalid token ID");
        return books[bookId].metadata;
    }

    /// @notice Grants the author role to a user.
    /// @param author The address to be granted the author role.
    function grantAuthorRole(address author) external onlyRole(ADMIN_ROLE) {
        grantRole(AUTHOR_ROLE, author);
    }

    /// @notice Revokes the author role from a user.
    /// @param author The address to have the author role revoked.
    function revokeAuthorRole(address author) external onlyRole(ADMIN_ROLE) {
        revokeRole(AUTHOR_ROLE, author);
    }

    /// @notice Updates the content access contract address.
    /// @param newContentAccess The new content access contract address.
    function updateContentAccess(address newContentAccess) external onlyRole(ADMIN_ROLE) {
        contentAccess = IContentAccess(newContentAccess);
    }

    /// @notice Updates the royalty manager contract address.
    /// @param newRoyaltyManager The new royalty manager contract address.
    function updateRoyaltyManager(address newRoyaltyManager) external onlyRole(ADMIN_ROLE) {
        royaltyManager = IRoyaltyManager(newRoyaltyManager);
    }
}
