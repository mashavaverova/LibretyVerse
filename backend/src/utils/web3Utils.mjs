import Web3 from 'web3';
import contracts from './contracts.mjs'; // This imports the initialized contracts module

// Initialize Web3 with the RPC URL
const web3 = new Web3(process.env.ANVIL_RPC_URL || 'http://127.0.0.1:8545');

/**
 * Validates and logs metadata using the MetadataManager contract.
 * @param {string} metadataURI - The metadata URI to validate.
 * @returns {string} - The transaction hash.
 * @throws {Error} - If the transaction fails.
 */
export async function validateAndLogMetadata(metadataURI) {
    try {
        const result = await contracts.MetadataManager.methods
            .validateAndLog(metadataURI)
            .send({ from: process.env.PLATFORM_ADMIN_ADDRESS, gas: 3000000 });

        return result.transactionHash; // Return the transaction hash
    } catch (error) {
        console.error('Error validating metadata:', error.message);
        throw error;
    }
}

/**
 * Sends a transaction using a specified contract method.
 * @param {object} contractMethod - The contract method to call.
 * @param {object} options - Transaction options (e.g., `from`, `value`).
 * @returns {object} - The transaction receipt.
 * @throws {Error} - If the transaction fails.
 */
export async function sendTransaction(contractMethod, options = {}) {
    try {
        // Estimate gas for the transaction
        const gasEstimate = await contractMethod.estimateGas(options);

        // Send the transaction with the estimated gas
        const tx = await contractMethod.send({ ...options, gas: gasEstimate });

        return tx; // Return the transaction receipt
    } catch (error) {
        console.error('Transaction failed:', error.message);
        throw error;
    }
}

// Export the initialized Web3 instance
export default web3;
