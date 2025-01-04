import { fileURLToPath } from 'url';
import { dirname } from 'path';
import fs from 'fs';
import dotenv from 'dotenv';
import web3 from '../utils/web3.mjs';
import ENV from '../config/environment.mjs'; // Import the environment config as a module

dotenv.config();

// Resolve __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Helper function to dynamically load and parse JSON ABI files
function loadABI(fileName) {
    const filePath = new URL(`../contracts/${fileName}.json`, import.meta.url);
    const fileContent = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(fileContent).abi;
}

// Map contract names to ABIs (loaded dynamically)
const contractABIs = {
    LibretyNFT: loadABI('LibretyNFT'),
    PaymentHandler: loadABI('PaymentHandler'),
    RoyaltyManager: loadABI('RoyaltyManager'),
    MetadataManager: loadABI('MetadataManager'),
    ContentAccess: loadABI('ContentAccess'),
    PlatformAdmin: loadABI('PlatformAdmin'),
    AuthorManager: loadABI('AuthorManager'),
};

// Function to load and initialize the contract
function loadContract(contractName, addressKey) {
    const contractAddress = ENV.contractAddresses[addressKey];

    if (!contractAddress) {
        throw new Error(`Contract address for ${contractName} is not set in the environment configuration.`);
    }

    const abi = contractABIs[contractName];
    if (!abi) {
        throw new Error(`ABI for ${contractName} is not available.`);
    }

    // Initialize and return the contract instance
    const contract = new web3.eth.Contract(abi, contractAddress);
    console.log(`${contractName} Contract Methods:`, contract.methods);
    return contract;
}

// Load all contracts
function loadContracts() {
    try {
        const contracts = {
            LibretyNFT: loadContract('LibretyNFT', 'libretyNFT'),
            PaymentHandler: loadContract('PaymentHandler', 'paymentHandler'),
            RoyaltyManager: loadContract('RoyaltyManager', 'royaltyManager'),
            MetadataManager: loadContract('MetadataManager', 'metadataManager'),
            ContentAccess: loadContract('ContentAccess', 'contentAccess'),
            PlatformAdmin: loadContract('PlatformAdmin', 'platformAdmin'),
            AuthorManager: loadContract('AuthorManager', 'authorManager'),
        };

        console.log('Contracts loaded successfully:', Object.keys(contracts));
        return contracts;
    } catch (error) {
        console.error('Failed to load contracts:', error.message);
        throw error;
    }
}

// Initialize and export contracts
let contracts;
try {
    contracts = loadContracts();
} catch (error) {
    console.error('Error initializing contracts:', error.message);
    process.exit(1); // Exit process if contracts cannot be loaded
}

export default contracts;
