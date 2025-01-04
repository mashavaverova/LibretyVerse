import Web3 from 'web3';
import fs from 'fs';
import path from 'path';
import User from '../models/userModel.mjs';
import ENV from '../config/environment.mjs'; 
import AuthorRequest from '../models/AuthorRequestModel.mjs';


 console.log('AuthorRequest model:', AuthorRequest);
 console.log('User model:', User);
// Dynamically load ABI file
const ABI_PATH = path.resolve('src/contracts/LibretyNFT.json');
const libretyNFTABI = JSON.parse(fs.readFileSync(ABI_PATH, 'utf-8'));

console.log('ABI is an array:', Array.isArray(libretyNFTABI.abi)); // Should output: true

// Initialize Web3
const web3 = new Web3(ENV.anvilRpcUrl);
const contract = new web3.eth.Contract(libretyNFTABI.abi, ENV.contractAddresses.libretyNFT);

const ROLE_HASHES = {
    PLATFORM_ADMIN: 'PLATFORM_ADMIN_ROLE',
    FUNDS_MANAGER: 'FUNDS_MANAGER_ROLE',
    AUTHOR: 'AUTHOR_ROLE',
};

// Helper function to fetch role hash
async function getRoleHash(roleKey) {
    try {
        console.log(`Fetching role hash for key: ${roleKey}`);
        if (!contract.methods[roleKey]) {
            throw new Error(`Method ${roleKey} does not exist on contract.`);
        }
        const roleHash = await contract.methods[roleKey]().call();
        console.log(`Role hash for ${roleKey}:`, roleHash);
        return roleHash;
    } catch (error) {
        console.error(`Failed to fetch role hash for ${roleKey}:`, error.message);
        throw new Error(`Failed to fetch role hash for ${roleKey}: ${error.message}`);
    }
}


const sendTransaction = async (method, adminPrivateKey) => {
    try {
        // Derive the admin account from the private key
        const adminAccount = web3.eth.accounts.privateKeyToAccount(adminPrivateKey);

        // Encode the transaction data
        const data = method.encodeABI();

        // Estimate gas for the transaction
        const gas = await method.estimateGas({ from: adminAccount.address });

        // Fetch gas price or use a default value
        const gasPrice = await web3.eth.getGasPrice(); // Legacy gas pricing
        console.log("Gas Price:", gasPrice);

        // Alternatively, calculate EIP-1559 fee parameters
        const maxPriorityFeePerGas = web3.utils.toWei('2', 'gwei'); // Example value
        const maxFeePerGas = web3.utils.toWei('50', 'gwei'); // Example value

        // Create the transaction object
        const tx = {
            to: ENV.contractAddresses.libretyNFT, // Contract address
            data, // Encoded function call
            gas, // Estimated gas
            from: adminAccount.address, // Explicitly set the sender
            // Uncomment one of the following:
            // For legacy gas pricing:
            gasPrice,
            // OR for EIP-1559:
            // maxPriorityFeePerGas,
            // maxFeePerGas,
        };

        // Sign the transaction using the admin private key
        const signedTx = await web3.eth.accounts.signTransaction(tx, adminPrivateKey);

        console.log("Signed Transaction:", signedTx);

        // Broadcast the signed transaction
        return await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
    } catch (error) {
        console.error("Error in sendTransaction:", error.message);
        throw new Error("Failed to send transaction: " + error.message);
    }
};




// Grant Role
export const grantRole = async (req, res, next) => {
    try {
        const { walletAddress, role } = req.body;

        console.log('Inside grantRole function:', req.body);

        if (!walletAddress || !role) {
            console.log('Missing walletAddress or role in request body');
            return res.status(400).json({ error: 'Wallet Address and Role are required.' });
        }

        const user = await User.findOne({ walletAddress: new RegExp(`^${walletAddress}$`, "i") });
        console.log('User found:', user);

        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }

        const roleKey = ROLE_HASHES[role];
        if (!roleKey) {
            return res.status(400).json({ error: 'Invalid role specified.' });
        }

        const roleHash = await getRoleHash(roleKey);

        const hasRole = await contract.methods.hasRole(roleHash, walletAddress).call();
        if (hasRole) {
            return res.status(400).json({ error: `Role '${role}' already granted to wallet address ${walletAddress}` });
        }

        const receipt = await sendTransaction(
            contract.methods.grantRole(roleHash, walletAddress),
            ENV.privateKeyAnvil0
        );

        if (receipt.status) {
            user.role = role;
            await user.save();

            console.log(`Role '${role}' successfully granted to wallet address: ${walletAddress}`);
            return res.json({ message: `Role '${role}' granted to user with wallet address ${walletAddress}` });
        } else {
            throw new Error('Transaction failed. Role was not granted.');
        }
    } catch (error) {
        console.error('Error granting role:', error.message);
        next(error);
    }
};


export const revokeRole = async (req, res, next) => {
    try {
        const { walletAddress, role } = req.body;

     console.log('Inside revokeRole function:', req.body);


        if (!walletAddress || !role) {
            console.error("Missing walletAddress or role in request body");
            return res.status(400).json({ error: 'Wallet Address and Role are required.' });
        }

        console.log('Revoke Role Request:', req.body);

        // Normalize wallet address to lowercase
        const normalizedWalletAddress = walletAddress.toLowerCase();

        // Find user in MongoDB
        const user = await User.findOne({
            walletAddress: new RegExp(`^${normalizedWalletAddress}$`, 'i'),
        });

        if (!user) {
            console.error(`User not found for walletAddress: ${walletAddress}`);
            return res.status(404).json({ error: 'User not found.' });
        }

        console.log('User found for revocation:', user);

        if (user.role !== role) {
            console.error(`User role mismatch: Expected ${role}, Found ${user.role}`);
            return res.status(400).json({ error: `User does not have the role '${role}' to revoke.` });
        }

        // Fetch the role key and hash
        const roleKey = ROLE_HASHES[role];
        if (!roleKey) {
            console.error(`Invalid role specified: ${role}`);
            return res.status(400).json({ error: 'Invalid role specified.' });
        }

        const roleHash = await getRoleHash(roleKey);

        // Check if the user has the role
        const hasRole = await contract.methods.hasRole(roleHash, normalizedWalletAddress).call();
        if (!hasRole) {
            console.error(`Role '${role}' not found for wallet address: ${walletAddress}`);
            return res.status(400).json({ error: `User does not have the role '${role}' to revoke.` });
        }

        // Revoke the role
        console.log(`Revoking role '${role}' from wallet address: ${walletAddress}`);
        const receipt = await sendTransaction(
            contract.methods.revokeRole(roleHash, normalizedWalletAddress),
            ENV.privateKeyAnvil0
        );

        if (receipt.status) {
            // Update user's role in MongoDB
            user.role = 'USER';
            await user.save();

            console.log(`Role '${role}' successfully revoked from wallet address: ${walletAddress}`);
            return res.json({ message: `Role '${role}' revoked from user with wallet address ${walletAddress}` });
        } else {
            throw new Error('Transaction failed. Role was not revoked.');
        }
    } catch (error) {
        console.error('Error revoking role:', error.message);
        return res.status(500).json({ error: 'An error occurred while revoking the role.' });
    }
};



export const approveAuthor = async (req, res, next) => {

    console.log('Inside approveAuthor function:', req.body);
   

    try {
        const { walletAddress } = req.body;

        if (!walletAddress) {
            console.error('Wallet Address is missing in the request.');
            return res.status(400).json({ error: 'Wallet Address is required.' });
        }

        console.log('Approve Author Request:', { walletAddress, userRole: req.user.role });

        // Ensure the request is made by a PLATFORM_ADMIN
        if (req.user.role !== 'PLATFORM_ADMIN') {
            return res.status(403).json({ error: 'Access Denied. Only PLATFORM_ADMIN can approve author requests.' });
        }

        // Check if the author role request exists
        const authorRequest = await AuthorRequest.findOne({ walletAddress });
        if (!authorRequest) {
            console.error(`No author role request found for walletAddress: ${walletAddress}`);
            return res.status(404).json({ error: 'No author role request found for this wallet address.' });
        }

        console.log('Author Request found:', authorRequest);

        // Check if the user exists in the database
        const user = await User.findOne({ walletAddress });
        if (!user) {
            console.error(`User not found for walletAddress: ${walletAddress}`);
            return res.status(404).json({ error: 'User not found.' });
        }

        console.log('User found in database:', user);

        // Check if the user already has the AUTHOR role
        const authorRoleHash = await getRoleHash(ROLE_HASHES.AUTHOR);
        const hasRole = await contract.methods.hasRole(authorRoleHash, walletAddress).call();

        if (hasRole) {
            console.warn(`User already has the AUTHOR role for walletAddress: ${walletAddress}`);
            return res.status(400).json({ error: 'User already has the AUTHOR role.' });
        }

        // Grant the AUTHOR role via the smart contract
        console.log(`Granting AUTHOR role to walletAddress: ${walletAddress}`);
        const receipt = await sendTransaction(
            contract.methods.grantRole(authorRoleHash, walletAddress),
            ENV.privateKeyAnvil0 // Use the admin's private key
        );

        if (!receipt.status) {
            throw new Error('Transaction failed. Could not grant AUTHOR role.');
        }

        console.log('Transaction successful. Updating user role in database...');

        // Update the user's role in the database
        user.role = 'AUTHOR';
        await user.save();

        console.log(`User role updated to AUTHOR for walletAddress: ${walletAddress}`);

        // Remove the processed request from the database
        await AuthorRequest.deleteOne({ walletAddress });

        console.log(`Author request successfully removed for walletAddress: ${walletAddress}`);

        return res.json({ message: `Author role successfully granted to ${walletAddress}.` });
    } catch (error) {
        console.error('Error approving author request:', error.message);
        return res.status(500).json({ error: 'An error occurred while approving the author role.' });
    }
};



// Revoke Author
export const revokeAuthor = async (req, res, next) => {
    req.body.role = 'AUTHOR';
    await revokeRole(req, res, next);
};
