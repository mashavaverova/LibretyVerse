// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/core/LibretyNFT.sol";
import "../src/libraries/MetadataLib.sol";

contract MockContentAccess {
    function grantAccess(address, uint256) external {}
}

contract MockRoyaltyManager {
    function processPayment(uint256, uint256, address, address) external payable {}
}

contract MockPaymentHandler {
    function processPayment(uint256, uint256, address, address) external payable {}
}

contract LibretyNFTTest is Test {
    LibretyNFT public nft;
    MockContentAccess public contentAccess;
    MockRoyaltyManager public royaltyManager;
    MockPaymentHandler public paymentHandler;

    address public admin = address(0xA1);
    address public author = address(0xA2);
    address public user = address(0xA3);

    function setUp() public {
        // Deploy mock contracts
        contentAccess = new MockContentAccess();
        royaltyManager = new MockRoyaltyManager();
        paymentHandler = new MockPaymentHandler();

        // Deploy the LibretyNFT contract
        nft = new LibretyNFT(
            "LibretyNFT",
            "LIBNFT",
            address(contentAccess),
            address(royaltyManager),
            address(paymentHandler)
        );

        // Grant roles
        vm.prank(admin);
        nft.grantRole(nft.PLATFORM_ADMIN_ROLE(), admin);

        vm.prank(admin);
        nft.grantRole(nft.AUTHOR_ROLE(), author);

        // Set up balances
        vm.deal(user, 100 ether);
    }

    function testCreateBook() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Test Book",
            "Author Name",
            "ipfs://contenthash",
            1 ether,
            "MIT",
            1, // Valid copyNumber
            1
        );

        vm.prank(author);
        nft.createBook(metadata, 100, 1 ether);

        (
            MetadataLib.Metadata memory returnedMetadata,
            uint256 maxCopies,
            uint256 mintedCopies,
            uint256 price,
            address bookAuthor
        ) = nft.getBook(0);

        assertEq(returnedMetadata.title, metadata.title);
        assertEq(returnedMetadata.author, metadata.author);
        assertEq(maxCopies, 100);
        assertEq(mintedCopies, 0);
        assertEq(price, 1 ether);
        assertEq(bookAuthor, author);
    }

    function testCreateBookUnauthorized() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Test Book",
            "Author Name",
            "ipfs://contenthash",
            1 ether,
            "MIT",
            1,
            1
        );

        vm.expectRevert(abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)",
            user, // Caller
            nft.AUTHOR_ROLE() // Expected role
        ));
        vm.prank(user);
        nft.createBook(metadata, 100, 1 ether);
    }

    function testCreateBookByAdmin() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Admin Book",
            "Admin Author",
            "ipfs://adminhash",
            2 ether,
            "Apache",
            1,
            1
        );

        vm.prank(admin);
        nft.createBookByAdmin(author, metadata, 50, 2 ether);

        (
            MetadataLib.Metadata memory returnedMetadata,
            uint256 maxCopies,
            uint256 mintedCopies,
            uint256 price,
            address bookAuthor
        ) = nft.getBook(0);

        assertEq(returnedMetadata.title, metadata.title);
        assertEq(returnedMetadata.author, metadata.author);
        assertEq(maxCopies, 50);
        assertEq(mintedCopies, 0);
        assertEq(price, 2 ether);
        assertEq(bookAuthor, author);
    }

    function testConstructor() public view{
        // Verify contract name and symbol
        assertEq(nft.name(), "LibretyNFT");
        assertEq(nft.symbol(), "LIBNFT");

        // Verify dependency addresses
        assertEq(address(nft.contentAccess()), address(contentAccess));
        assertEq(address(nft.royaltyManager()), address(royaltyManager));
        assertEq(address(nft.paymentHandler()), address(paymentHandler));
    }

    function testCreateBookByAdminUnauthorized() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Unauthorized Admin Book",
            "Unknown Admin",
            "ipfs://unauthorizedadminhash",
            2 ether,
            "None",
            1,
            1
        );

        // Expect revert due to missing `PLATFORM_ADMIN_ROLE`
        vm.expectRevert(abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)",
            user, // Caller
            nft.PLATFORM_ADMIN_ROLE() // Expected role
        ));

        vm.prank(user); // Simulate the user
        nft.createBookByAdmin(author, metadata, 50, 2 ether);
    }

    function testMintCopy() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Mintable Book",
            "Mint Author",
            "ipfs://mintablehash",
            1 ether,
            "CC0",
            1,
            1
        );

        // Author creates a book
        vm.prank(author);
        nft.createBook(metadata, 10, 1 ether);

        // User mints a copy
        vm.prank(user);
        nft.mintCopy{value: 1 ether}(0);

        // Verify minted copy
        assertEq(nft.balanceOf(user), 1);
        assertEq(nft.ownerOf(0), user);

        (, , uint256 mintedCopies, , ) = nft.getBook(0);
        assertEq(mintedCopies, 1);
    }

    function testMintCopyInsufficientPayment() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "Mintable Book",
            "Mint Author",
            "ipfs://mintablehash",
            1 ether,
            "CC0",
            1,
            1
        );

        // Author creates a book
        vm.prank(author);
        nft.createBook(metadata, 10, 1 ether);

        // Expect revert due to insufficient payment
        vm.expectRevert("Insufficient payment");

        vm.prank(user);
        nft.mintCopy{value: 0.5 ether}(0);
    }

    function testTokenURI() public {
        MetadataLib.Metadata memory metadata = MetadataLib.Metadata(
            "TokenURI Book",
            "Token Author",
            "ipfs://tokenurihash",
            1 ether,
            "GPL",
            1,
            1
        );

        // Author creates a book
        vm.prank(author);
        nft.createBook(metadata, 10, 1 ether);

        // User mints a copy
        vm.prank(user);
        nft.mintCopy{value: 1 ether}(0);

        // Verify token URI
        string memory uri = nft.tokenURI(0);
        assertEq(uri, "ipfs://tokenurihash");
    }

    function testUpdateContentAccess() public {
        address newContentAccess = address(0x123);

        vm.prank(admin);
        nft.updateContentAccess(newContentAccess);

        assertEq(address(nft.contentAccess()), newContentAccess);
    }

    function testUpdateRoyaltyManager() public {
        address newRoyaltyManager = address(0x456);

        vm.prank(admin);
        nft.updateRoyaltyManager(newRoyaltyManager);

        assertEq(address(nft.royaltyManager()), newRoyaltyManager);
    }

    function testUpdatePaymentHandler() public {
        address newPaymentHandler = address(0x789);

        vm.prank(admin);
        nft.updatePaymentHandler(newPaymentHandler);

        assertEq(address(nft.paymentHandler()), newPaymentHandler);
    }








}
