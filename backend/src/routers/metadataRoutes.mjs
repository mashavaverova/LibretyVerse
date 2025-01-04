import express from 'express';
import { validateAndLogMetadata } from '../utils/web3Utils.mjs';

const router = express.Router();

router.post('/setMetadata', async (req, res) => {
    const { metadataURI } = req.body;
    if (!metadataURI) {
        return res.status(400).json({ error: 'Metadata URI is required' });
    }
    try {
        const txHash = await validateAndLogMetadata(metadataURI);
        res.json({ success: true, transactionHash: txHash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export default router;
