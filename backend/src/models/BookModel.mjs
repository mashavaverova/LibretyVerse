import mongoose from 'mongoose';

const BookSchema = new mongoose.Schema({
    metadataCID: { type: String, required: true },
    maxCopies: { type: Number, required: true },
    mintedCopies: { type: Number, default: 0 },
    price: { type: Number, required: true },
    author: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
});

export default mongoose.model('Book', BookSchema);
