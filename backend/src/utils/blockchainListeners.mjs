import web3 from './web3.mjs';
import { ENV } from '../config/environment.mjs';
import LibretyNFTABI from '../contracts/LibretyNFT.json';

// Create a contract instance
const libretyNFT = new web3.eth.Contract(LibretyNFTABI, ENV.contractAddresses.libretyNFT);

export async function startEventListeners() {
    console.log('Starting blockchain event listeners...');

    // Ensure connection
    const accounts = await web3.eth.getAccounts();
    console.log('Connected to Anvil with accounts:', accounts);

    // Listen for `BookMinted` events
    libretyNFT.events.BookMinted({}, async (error, event) => {
        if (error) {
            console.error('Error in BookMinted event listener:', error);
            return;
        }
        console.log('BookMinted event detected:', event.returnValues);

        // Example: Process the event data
        const { bookId, author, metadataURI } = event.returnValues;
        console.log(`Book ID: ${bookId}, Author: ${author}, Metadata URI: ${metadataURI}`);
    });

    // Listen for `MetadataUpdated` events
    libretyNFT.events.MetadataUpdated({}, async (error, event) => {
        if (error) {
            console.error('Error in MetadataUpdated event listener:', error);
            return;
        }
        console.log('MetadataUpdated event detected:', event.returnValues);

        // Process MetadataUpdated event data
        const { bookId, metadataURI } = event.returnValues;
        console.log(`Updated Metadata for Book ID: ${bookId}, Metadata URI: ${metadataURI}`);
    });
}
