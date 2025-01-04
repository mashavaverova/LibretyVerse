import web3 from '../utils/web3.mjs';
import 'dotenv/config';


async function testConnection() {
    console.log('RPC URL:', process.env.ANVIL_RPC_URL);
    console.log('Private Key:', process.env.PRIVATE_KEY_ANVIL_0);

    try {
        const accounts = await web3.eth.getAccounts();
        console.log('Accounts:', accounts);

        if (accounts.length === 0) {
            console.error('No accounts found. Adding private key manually...');
            web3.eth.accounts.wallet.add(process.env.PRIVATE_KEY_ANVIL_0);
            console.log('Wallet accounts:', web3.eth.accounts.wallet);
        } else {
            const balance = await web3.eth.getBalance(accounts[0]);
            console.log(`Balance of account[0]: ${web3.utils.fromWei(balance, 'ether')} ETH`);
        }
    } catch (error) {
        console.error('Error:', error.message);
    }
}

testConnection();
