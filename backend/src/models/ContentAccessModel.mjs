import mongoose from 'mongoose';

const ContentAccessSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tokenId: { type: String, required: true },
    accessType: { type: String, enum: ['Timed', 'Unlimited'], required: true },
    expiresAt: { type: Date },
    grantedAt: { type: Date, default: Date.now },
});

export default mongoose.model('ContentAccess', ContentAccessSchema);
