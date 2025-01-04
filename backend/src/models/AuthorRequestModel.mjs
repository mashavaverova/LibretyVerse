import mongoose from 'mongoose';

const authorRequestSchema = new mongoose.Schema(
    {
        walletAddress: { type: String, required: true, unique: true },
        requestedAt: { type: Date, default: Date.now },
        status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'], default: 'PENDING' },
    },
    { timestamps: true }
);

export default mongoose.model('AuthorRequest', authorRequestSchema);
