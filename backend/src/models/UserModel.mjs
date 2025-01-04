import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: {
        type: String,
        required: function () {
            return this.role !== 'DEFAULT_ADMIN';
        },
    },   
    walletAddress: { type: String, required: true },
    role: {
        type: String,
        enum: ['DEFAULT_ADMIN', 'PLATFORM_ADMIN', 'FUNDS_MANAGER', 'AUTHOR', 'USER'],
        default: 'USER',
    },
});

export default mongoose.model('User', userSchema);
