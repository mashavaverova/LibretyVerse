import Web3 from 'web3';

async function checkBalance() {
    const web3 = new Web3('http://127.0.0.1:8545'); // Ensure connection to Anvil
    const account = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    try {
        const balance = await web3.eth.getBalance(account);
        console.log(`Balance of ${account}: ${web3.utils.fromWei(balance, 'ether')} ETH`);
    } catch (error) {
        console.error('Error fetching balance:', error);
    }
}

checkBalance();
