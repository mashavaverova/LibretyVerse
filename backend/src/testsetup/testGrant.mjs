import Web3 from 'web3';
import ABI from '../contracts/LibretyNFT.json';


const web3 = new Web3('http://127.0.0.1:8545');
const contract = new web3.eth.Contract(ABI, );
const senderAddress = '<ADMIN_ADDRESS>';
const privateKey = '<ADMIN_PRIVATE_KEY>';

async function testGrantRole() {
    const AUTHOR_ROLE = await contract.methods.AUTHOR_ROLE().call();
    console.log('AUTHOR_ROLE:', AUTHOR_ROLE);

    const data = contract.methods.grantRole(AUTHOR_ROLE, '<WALLET_ADDRESS>').encodeABI();

    const tx = {
        to: '<CONTRACT_ADDRESS>',
        gas: 1000000,
        data,
    };

    const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
    console.log('Transaction Receipt:', receipt);
}

testGrantRole().catch(console.error);
