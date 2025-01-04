import AuthorRequest from '../models/AuthorRequestModel.mjs';

export const requestAuthorRole = async (req, res, next) => {
    try {
        const { walletAddress } = req.body;

        if (!walletAddress) {
            console.error('Missing wallet address in request.');
            return res.status(400).json({ error: 'Wallet Address is required.' });
        }

        console.log('Requesting author role for walletAddress:', walletAddress);

        // Check if the request already exists
        const existingRequest = await AuthorRequest.findOne({ walletAddress });
        console.log('Existing Request:', existingRequest);

        if (existingRequest) {
            return res.status(400).json({ error: 'Request already submitted.' });
        }

        // Create a new author request
        console.log('Creating a new author request...');
        const authorRequest = new AuthorRequest({ walletAddress });

        const savedRequest = await authorRequest.save();
        console.log('Saved Author Request:', savedRequest);

        return res.status(201).json({ message: 'Author role request submitted successfully.' });
    } catch (error) {
        console.error('Error submitting author request:', error.message);
        next(error);
    }
};
