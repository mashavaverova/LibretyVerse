## LibretyVerse: The Independent Publishing Platform

LibretyVerse is a decentralized, censorship-resistant platform that empowers authors to publish and distribute their works freely on the blockchain. By tokenizing books as NFTs and storing their content off-chain, the platform ensures affordable scalability, secure ownership, and automated royalties. Readers can explore a diverse, unrestricted library of works, while authors maintain control and receive fair compensation. This project is developed as part of a diploma project for Medieinstitutet in Sweden, Blockchain Development program, and is open source.

### **Key Features**
   
**Censorship Resistance:**
Provides an immutable publishing option for authors in regions with restricted freedom of expression.

**Royalty and Donation Management:**
Ensures fair compensation for authors with automated royalty distribution.
Allows authors to allocate a percentage of their royalties to donations for causes they care about.

**Scalability and Affordability:**
Off-chain content storage and multi-chain payments make the platform scalable and cost-effective.

**Global Accessibility:**
Bridges knowledge gaps by enabling access to censored materials worldwide.


## Detalis 

## 1. Smart Contracts
<details>
<summary>Click to expand</summary>

### Core Contracts

    1. NFT Minting Contract:
    Implements the ERC-721 standard to tokenize books as NFTs.
    Metadata includes:
    Author, Title, Genre, Description, License, Content Link (Base/IPFS), Censorship Status (if banned and where), and Price.
    Restricted minting to verified authors.

    2. Royalty Distribution Contract:
    Adjustable royalty system:
    Allows the platform administrator to set author fees, platform fees, and donation options.
    Authors can allocate a portion of their royalties to donations, with the recipient wallet address specified during NFT minting.
    Automates royalty payments on NFT primary sales and resales, ensuring fair compensation for authors and the platform.

    3. Access Control Contract:
    Allows readers to view books securely without the ability to copy content.
    Tracks NFT ownership and permissions for access.
    Integrates resale royalty splits between authors, the platform, and donation targets.

    4. Administrator Contract:
    Manages author verification.
    Adjusts royalty percentages, donation options, and platform policies.
</details>

## 2. Backend
<details>
<summary>Click to expand</summary>

    1. API:
        - Provides endpoints for:
            - Minting NFTs.
            - Handling royalty payments.
            - Access control for content viewing.
        - Facilitates interactions between the frontend, smart contracts, and Base.

    2. Content Management:
        - Integrates with Base for uploading and retrieving book content.
        - Ensures scalable and affordable off-chain storage.

    3. Anonymity Management:
        - Ensures reader anonymity to mitigate risks associated with accessing censored content.
</details>

## 3. Frontend (React-Based Interface)
<details>
<summary>Click to expand</summary>

      1. Author Dashboard:
      Features for uploading books, minting NFTs, setting donation targets, and tracking royalties.
      Accessible only to verified authors.

      2. Reader Interface:
      Allows readers to explore books by genre, censorship status, or other filters.
      Supports purchasing NFTs, viewing books securely, and reselling them.

      3. Accredited Reviewer System:
      Enables verified reviewers to leave comments and ratings for books.
</details>

## 4. Decentralized Storage
<details>
<summary>Click to expand</summary>

    1. Base Integration:
        - All book content is stored off-chain on Base for affordable scalability.
        - Metadata links the NFTs to the content stored on Base.

    2. Security:
        - Ensures that book content can be accessed securely while protecting against unauthorized copying.
</details>

## 5. Payment System
<details>
<summary>Click to expand</summary>

    1. Multi-Chain Payments:
        - Transactions can be processed on both Ethereum and Base to optimize costs and accessibility.

    2. Flexible Pricing and Donations:
        - Authors can set the price for their books during the NFT minting process.
        - Resale royalties are distributed automatically to the author, platform, and optional donation targets.
</details>

## 6. Author Verification
<details>
<summary>Click to expand</summary>

### Manual Wallet-Based Authentication
    - Authors undergo manual verification, where the platform admin links their wallet address to their verified status.
    - Wallet authentication is required for authors to log in and access platform features.
    - Future upgrades may include decentralized verification solutions like BrightID.
</details>

## 7. Anonymity and Censorship Resistance
<details>
<summary>Click to expand</summary>

    1. Reader Anonymity:
    Readers can browse and purchase content without exposing their identity, ensuring safety when accessing censored materials.

    2. Immutable Content:
    Content stored off-chain is censorship-resistant, allowing global access to restricted books.
</details>