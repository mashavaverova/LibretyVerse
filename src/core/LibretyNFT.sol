// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IContentAccess.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IPaymentHandler.sol";
import "../libraries/MetadataLib.sol";

contract LibretyNFT is ERC721, AccessControl {
    using MetadataLib for MetadataLib.Metadata;

    // Roles
    bytes32 public constant AUTHOR_ROLE = keccak256("AUTHOR_ROLE");
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN_ROLE");

    // Counter for books and tokens
    uint256 private _bookIdCounter;
    uint256 private _tokenIdCounter;

    // Dependencies
    IContentAccess public contentAccess;
    IRoyaltyManager public royaltyManager;
    IPaymentHandler public paymentHandler;

    // Book and token tracking
    struct Book {
        MetadataLib.Metadata metadata;
        uint256 maxCopies;
        uint256 mintedCopies;
        uint256 price;
        address author;
    }

    mapping(uint256 => Book) private books; // bookId => Book
    mapping(uint256 => uint256) private tokenToBookId; // tokenId => bookId

    // Events
    event BookCreated(uint256 indexed bookId, string title, address indexed author, uint256 price, uint256 maxCopies);
    event TokenMinted(uint256 indexed bookId, uint256 indexed tokenId, address indexed recipient);
    event ContentAccessUpdated(address indexed newContentAccess);
    event RoyaltyManagerUpdated(address indexed newRoyaltyManager);
    event PaymentHandlerUpdated(address indexed newPaymentHandler);

    constructor(
        string memory name,
        string memory symbol,
        address contentAccessAddress,
        address royaltyManagerAddress,
        address paymentHandlerAddress
    ) ERC721(name, symbol) {
        require(contentAccessAddress != address(0), "Invalid ContentAccess address");
        require(royaltyManagerAddress != address(0), "Invalid RoyaltyManager address");
        require(paymentHandlerAddress != address(0), "Invalid PaymentHandler address");

        contentAccess = IContentAccess(contentAccessAddress);
        royaltyManager = IRoyaltyManager(royaltyManagerAddress);
        paymentHandler = IPaymentHandler(paymentHandlerAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PLATFORM_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Creates a new book with metadata and pricing details
    function createBook(
        MetadataLib.Metadata memory metadata,
        uint256 maxCopies,
        uint256 price
    ) external onlyRole(AUTHOR_ROLE) {
        require(maxCopies > 0, "Max copies must be > 0");
        require(price > 0, "Price must be > 0");

        metadata.validateMetadata(); // Validate metadata
        uint256 bookId = _bookIdCounter++;
        books[bookId] = Book(metadata, maxCopies, 0, price, msg.sender);

        emit BookCreated(bookId, metadata.title, msg.sender, price, maxCopies);
    }

    /// @notice Creates a new book as a platform admin on behalf of an author
    function createBookByAdmin(
        address author,
        MetadataLib.Metadata memory metadata,
        uint256 maxCopies,
        uint256 price
    ) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(hasRole(AUTHOR_ROLE, author), "Provided address is not an author");
        require(maxCopies > 0, "Max copies must be > 0");
        require(price > 0, "Price must be > 0");

        metadata.validateMetadata(); // Validate metadata
        uint256 bookId = _bookIdCounter++;
        books[bookId] = Book(metadata, maxCopies, 0, price, author);

        emit BookCreated(bookId, metadata.title, author, price, maxCopies);
    }

    /// @notice Mints a copy of an existing book
    function mintCopy(uint256 bookId) external payable {
        Book storage book = books[bookId];
        require(book.maxCopies > 0, "Book does not exist");
        require(book.mintedCopies < book.maxCopies, "All copies minted");
        require(msg.value >= book.price, "Insufficient payment");

        uint256 tokenId = _tokenIdCounter++;
        book.mintedCopies++;
        tokenToBookId[tokenId] = bookId;

        // Process payments
        try paymentHandler.processPayment{value: msg.value}(bookId, book.price, address(0), book.author) {
            // Success
        } catch {
            revert("PaymentHandler call failed");
        }

        // Grant content access and mint token
        contentAccess.grantAccess(msg.sender, tokenId);
        _mint(msg.sender, tokenId);

        emit TokenMinted(bookId, tokenId, msg.sender);
    }

    /// @notice Retrieve metadata for a specific token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        uint256 bookId = tokenToBookId[tokenId];
        return books[bookId].metadata.contentLink;
    }


    /// @notice Updates the ContentAccess contract
    function updateContentAccess(address newContentAccess) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newContentAccess != address(0), "Invalid address");
        contentAccess = IContentAccess(newContentAccess);
        emit ContentAccessUpdated(newContentAccess);
    }

    /// @notice Updates the RoyaltyManager contract
    function updateRoyaltyManager(address newRoyaltyManager) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newRoyaltyManager != address(0), "Invalid address");
        royaltyManager = IRoyaltyManager(newRoyaltyManager);
        emit RoyaltyManagerUpdated(newRoyaltyManager);
    }

    /// @notice Updates the PaymentHandler contract
    function updatePaymentHandler(address newPaymentHandler) external onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newPaymentHandler != address(0), "Invalid address");
        paymentHandler = IPaymentHandler(newPaymentHandler);
        emit PaymentHandlerUpdated(newPaymentHandler);
    }

    /// @notice Retrieve book information
    function getBook(uint256 bookId)
        external
        view
        returns (
            MetadataLib.Metadata memory metadata,
            uint256 maxCopies,
            uint256 mintedCopies,
            uint256 price,
            address author
        )
    {
        Book storage book = books[bookId];
        require(book.maxCopies > 0, "Book does not exist");
        return (book.metadata, book.maxCopies, book.mintedCopies, book.price, book.author);
    }
}
