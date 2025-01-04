import User from '../models/userModel.mjs';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { ENV } from '../config/environment.mjs';

export const registerUser = async (req, res) => {
    try {
        const { email, password, walletAddress } = req.body;

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = new User({
            email,
            password: hashedPassword,
            walletAddress,
        });

        await user.save();

        const token = jwt.sign(
            { id: user._id, email: user.email, role: user.role },
            ENV.jwtSecret,
            { expiresIn: '1h' }
        );

        res.json({ token, user });
    } catch (err) {
        res.status(500).json({ error: 'Failed to register user.' });
    }
};

export const loginUser = async (req, res) => {
    try {
        const { identifier, password } = req.body;

        console.log('Login attempt with identifier:', identifier);

        // Ensure identifier and password are provided
        if (!identifier || !password) {
            return res.status(400).json({ error: 'Identifier and password are required.' });
        }

        // Determine whether the identifier is an email or walletAddress
        const isEmail = identifier.includes('@');
        const query = isEmail
            ? { email: identifier }
            : { walletAddress: identifier };

        // Find user by email or walletAddress
        const user = await User.findOne(query);
        if (!user) {
            console.log('User not found');
            return res.status(400).json({ error: 'Invalid credentials.' });
        }

        console.log('User found:', user);

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        console.log('Password match:', isMatch);

        if (!isMatch) {
            return res.status(400).json({ error: 'Invalid credentials.' });
        }

        // Generate tokens
        const accessToken = jwt.sign(
            { id: user._id, email: user.email, role: user.role },
            ENV.jwtSecret,
            { expiresIn: '1h' }
        );

        const refreshToken = jwt.sign(
            { id: user._id, email: user.email, role: user.role },
            ENV.refreshTokenSecret,
            { expiresIn: '7d' }
        );

        res.json({ accessToken, refreshToken });
    } catch (err) {
        console.error('Error during login:', err);
        res.status(500).json({ error: 'Failed to login user.' });
    }
};





export const logoutUser = (req, res) => {
    // Ideally, invalidate the refresh token here (e.g., remove it from the database or blacklist)
    res.status(200).json({ message: 'Logged out successfully' });
};

export const refreshToken = (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({ error: 'Refresh Token is required' });
    }

    try {
        const decoded = jwt.verify(refreshToken, ENV.refreshTokenSecret);
        const newAccessToken = jwt.sign(
            { id: decoded.id, email: decoded.email, role: decoded.role },
            ENV.jwtSecret,
            { expiresIn: '1h' }
        );

        res.json({ accessToken: newAccessToken });
    } catch (err) {
        res.status(403).json({ error: 'Invalid or expired Refresh Token' });
    }
};

export const verifyToken = (req, res) => {
    const { token } = req.body;

    if (!token) {
        return res.status(401).json({ error: 'Token is required' });
    }

    try {
        const decoded = jwt.verify(token, ENV.jwtSecret);
        res.json({ valid: true, user: decoded });
    } catch (err) {
        res.status(403).json({ valid: false, error: 'Invalid or expired Token' });
    }
};
