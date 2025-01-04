import dotenv from 'dotenv';
dotenv.config();


export const ENV = {
    port: process.env.PORT || 3000,
    alchemyApiUrl: process.env.ALCHEMY_API_URL,
    ipfsGateway: process.env.IPFS_GATEWAY,
    jwtSecret: process.env.JWT_SECRET,
    mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/libretyverse',
    anvilRpcUrl: process.env.ANVIL_RPC_URL,
    refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET,
    privateKeyAnvil0: process.env.PRIVATE_KEY_ANVIL_0,
    defaultAdminWallet: process.env.DEFAULT_ADMIN_WALLET || '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266',

    contractAddresses: {
        libretyNFT: process.env.LIBRETY_NFT_ADDRESS,
        paymentHandler: process.env.PAYMENT_HANDLER_ADDRESS,
        royaltyManager: process.env.ROYALTY_MANAGER_ADDRESS,
        metadataManager: process.env.METADATA_MANAGER_ADDRESS,
        contentAccess: process.env.CONTENT_ACCESS_ADDRESS,
        platformAdmin: process.env.PLATFORM_ADMIN_ADDRESS,
        authorManager: process.env.AUTHOR_MANAGER_ADDRESS,
    },
};

console.log('Environment Variables:', 'anvilRpcUrl', process.env.ANVIL_RPC_URL, 'privateKeyAnvil0', process.env.PRIVATE_KEY_ANVIL_0);



export default ENV;


