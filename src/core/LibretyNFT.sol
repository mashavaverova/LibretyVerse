// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
/*
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IContentAccess.sol";
import "../interfaces/IRoyaltyManager.sol";
import "../interfaces/IPaymentHandler.sol";
import "../interfaces/ILibretyNFT.sol";
import "../libraries/MetadataLib.sol";
import "forge-std/console.sol"; // Import console.log

error UnauthorizedAccount_LNFT(address account, bytes32 role); // Define globally

contract LibretyNFT is ERC721, AccessControl, ILibretyNFT {
    using MetadataLib for MetadataLib.Metadata;

    // Constants for roles
    bytes32 public constant AUTHOR_ROLE = keccak256("AUTHOR_ROLE");
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN_ROLE");

    // State variables
    uint256 private _bookIdCounter;
    uint256 private _tokenIdCounter;
    IContentAccess public contentAccess;
    IRoyaltyManager public royaltyManager;
    IPaymentHandler public paymentHandler;

    // Custom tracking of role members
    mapping(bytes32 => address[]) private _roleMembers;

    struct Book {
        MetadataLib.Metadata metadata;
        uint256 maxCopies;
        uint256 mintedCopies;
        uint256 price; // Price in wei
        address author; // Address of the author (or platform admin if no author)
    }

    // Mappings
    mapping(uint256 => Book) private books;
    mapping(uint256 => uint256) private tokenToBookId;

    // Events
    event BookMinted(
        uint256 indexed bookId,
        address indexed author,
        string title,
        uint256 maxCopies,
        uint256 price,
        string ipfsHash
    );
    event CopyMinted(uint256 indexed bookId, uint256 indexed tokenId, address indexed recipient);

constructor(
    string memory _name,
    string memory _symbol,
    address _contentAccess,
    address _royaltyManager,
    address _paymentHandler
) ERC721(_name, _symbol) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PLATFORM_ADMIN_ROLE, msg.sender);

    // Make PLATFORM_ADMIN_ROLE its own admin role
    _setRoleAdmin(PLATFORM_ADMIN_ROLE, PLATFORM_ADMIN_ROLE);

    _roleMembers[PLATFORM_ADMIN_ROLE].push(msg.sender); // Track the platform admin
    contentAccess = IContentAccess(_contentAccess);
    royaltyManager = IRoyaltyManager(_royaltyManager);
    paymentHandler = IPaymentHandler(_paymentHandler);
}


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint a new NFT book
 function mintNFT(
    MetadataLib.Metadata memory metadata,
    uint256 maxCopies,
    uint256 price
) external {
    console.log("mintNFT called by:", msg.sender);

    address author = hasRole(AUTHOR_ROLE, msg.sender) ? msg.sender : getRoleMember(PLATFORM_ADMIN_ROLE, 0);
    console.log("Author determined as:", author);

    require(maxCopies > 0, "Max copies must be greater than 0");
    require(price > 0, "Price must be greater than 0");
    console.log("Max copies:", maxCopies, "Price:", price);

    (string memory field, string memory reason) = metadata.validateMetadata();
    require(bytes(field).length == 0, reason);

    uint256 bookId = _bookIdCounter;
    console.log("Book ID assigned:", bookId);
    _bookIdCounter++;
    books[bookId] = Book(metadata, maxCopies, 0, price, author);

    emit BookMinted(bookId, author, metadata.title, maxCopies, price, metadata.contentLink);
    console.log("BookMinted event emitted for book ID:", bookId);
}


    /// @notice Mint a copy of an existing book
function mintCopy(uint256 bookId) external payable {
    console.log("mintCopy called for book ID:", bookId, "by:", msg.sender);

    Book storage book = books[bookId];
    require(book.maxCopies > 0, "Book does not exist");
    require(book.mintedCopies < book.maxCopies, "Max copies reached");
    console.log("Book exists. Current minted copies:", book.mintedCopies);

    require(msg.value >= book.price, "Insufficient payment");
    console.log("Payment received:", msg.value, "Required price:", book.price);

    uint256 tokenId = _tokenIdCounter;
    _tokenIdCounter++;
    book.mintedCopies++;
    tokenToBookId[tokenId] = bookId;

    console.log("Token ID assigned:", tokenId);

    // Calculate royalties
    (uint256 authorRoyalty, uint256 platformRoyalty, uint256 totalDonation) =
        royaltyManager.calculateRoyalties(msg.value);

    console.log("Author Royalty:", authorRoyalty);
    console.log("Platform Royalty:", platformRoyalty);
    console.log("Total Donations:", totalDonation);
    
    // Distribute payments via payment handler
    paymentHandler.processPayment{value: msg.value}(
        bookId,
        book.price,
        book.author,
        platformRoyalty,
        authorRoyalty,
        totalDonation
    );
    console.log("Payment processed via PaymentHandler.");

    // Mint the NFT
    _mint(msg.sender, tokenId);
    contentAccess.grantAccess(msg.sender, tokenId);

    emit CopyMinted(bookId, tokenId, msg.sender);
    console.log("CopyMinted event emitted for token ID:", tokenId, "Recipient:", msg.sender);
}


    /// @notice Retrieve metadata for a specific token
    function getMetadata(uint256 tokenId) external view returns (MetadataLib.Metadata memory) {
        uint256 bookId = tokenToBookId[tokenId];
        require(books[bookId].maxCopies > 0, "Invalid token ID");
        return books[bookId].metadata;
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
        return (
            book.metadata,
            book.maxCopies,
            book.mintedCopies,
            book.price,
            book.author
        );
    }

function grantRole(bytes32 role, address account) public override {
    // Manually check if the caller has the admin role
    if (!hasRole(getRoleAdmin(role), msg.sender)) {
        revert UnauthorizedAccount_LNFT(msg.sender, getRoleAdmin(role));
    }

    console.log("Attempting to grant role:");
    console.log("  Account:", account);
    console.log("  Sender:", msg.sender);

    // Log role and admin role details
    bytes32 adminRole = getRoleAdmin(role);
    console.log("  Role being granted (bytes32):", uint256(role));
    console.log("  Admin role required for this action:", uint256(adminRole));
    console.log("  Caller has the admin role:", hasRole(adminRole, msg.sender));

    // Ensure the account does not already have the role
    console.log("  Account has role before grant:", hasRole(role, account));
    require(!hasRole(role, account), "Account already has the role");

    // Call the parent implementation to grant the role
    super.grantRole(role, account);

    // Track the new role member
    _roleMembers[role].push(account);

    // Log after the role has been granted
    console.log("Role granted and member added.");
    console.log("  Role successfully granted to account:", account);
    console.log("  Account has role after grant:", hasRole(role, account));
    console.log("  Total role members after grant:", _roleMembers[role].length);
}


    function _isRoleMember(bytes32 role, address account) internal view returns (bool) {
        for (uint256 i = 0; i < _roleMembers[role].length; i++) {
            if (_roleMembers[role][i] == account) {
                return true;
            }
        }
        return false;
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        console.log("Attempting to revoke role:");
        console.log("  Account:", account);
        console.log("  Sender:", msg.sender);

        require(hasRole(role, account), "Account does not have the role");
        super.revokeRole(role, account);

        // Remove the role member safely
        _removeRoleMember(role, account);
    }

    function _removeRoleMember(bytes32 role, address account) internal {
        uint256 length = _roleMembers[role].length;
        for (uint256 i = 0; i < length; i++) {
            if (_roleMembers[role][i] == account) {
                _roleMembers[role][i] = _roleMembers[role][length - 1];
                _roleMembers[role].pop();
                console.log("Role revoked and member removed.");
                return;
            }
        }
        console.log("Role member not found.");
    }





    /// @notice Retrieve a role member by index
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        require(index < _roleMembers[role].length, "Index out of bounds");
        return _roleMembers[role][index];
    }

    /// @notice Get the total number of members for a role
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].length;
    }










    function updateContentAccess(address newContentAccess) external onlyRole(PLATFORM_ADMIN_ROLE) {
    require(newContentAccess != address(0), "Invalid address");
    contentAccess = IContentAccess(newContentAccess);
}

function updateRoyaltyManager(address newRoyaltyManager) external onlyRole(PLATFORM_ADMIN_ROLE) {
    require(newRoyaltyManager != address(0), "Invalid address");
    royaltyManager = IRoyaltyManager(newRoyaltyManager);
}

function updatePaymentHandler(address newPaymentHandler) external onlyRole(PLATFORM_ADMIN_ROLE) {
    require(newPaymentHandler != address(0), "Invalid address");
    paymentHandler = IPaymentHandler(newPaymentHandler);
}
}
*/
