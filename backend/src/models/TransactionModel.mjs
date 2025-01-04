import mongoose from 'mongoose';

const TransactionSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    transactionHash: { type: String, required: true, unique: true },
    type: { type: String, enum: ['Donation', 'Purchase', 'Royalty'], required: true },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['Pending', 'Completed', 'Failed'], required: true },
    createdAt: { type: Date, default: Date.now },
});

export default mongoose.model('Transaction', TransactionSchema);
