import User from '../models/userModel.mjs';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { ENV } from '../config/environment.mjs';

export const initializeDefaultAdmin = async () => {
    try {
        const walletAddress = "0xYourDefaultAdminAddress"; // Replace with your Default Admin wallet address
        const email = "admin@example.com";
        const password = "securepassword"; // For testing purposes

        // Check if admin exists
        let admin = await User.findOne({ walletAddress });
        if (!admin) {
            const hashedPassword = await bcrypt.hash(password, 10);
            admin = new User({
                walletAddress,
                email,
                password: hashedPassword,
                role: 'DEFAULT_ADMIN',
            });
            await admin.save();

            console.log('Default admin created:', admin);
        }

        // Generate a token
        const token = jwt.sign(
            { id: admin._id, email: admin.email, role: admin.role },
            ENV.jwtSecret,
            { expiresIn: '1h' }
        );

        console.log('Default Admin Token:', token);
    } catch (err) {
        console.error('Error initializing default admin:', err.message);
    }
};
