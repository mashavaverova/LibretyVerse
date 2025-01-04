import mongoose from 'mongoose';

const IPFSReferenceSchema = new mongoose.Schema({
    referenceType: { type: String, enum: ['Book', 'Metadata', 'ProofOfOwnership'], required: true },
    ipfsCID: { type: String, required: true },
    linkedId: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
});

export default mongoose.model('IPFSReference', IPFSReferenceSchema);
