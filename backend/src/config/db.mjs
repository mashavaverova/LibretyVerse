import mongoose from 'mongoose';
import { ENV } from './environment.mjs';

export const connectDB = async () => {
    try {
        await mongoose.connect(ENV.mongoUri);
        console.log('Connected to MongoDB');
    } catch (error) {
        console.error('MongoDB connection error:', error);
        process.exit(1);
    }
};
