import express from 'express';
import { registerUser, loginUser, logoutUser, refreshToken, verifyToken } from '../controllers/authController.mjs';

const router = express.Router();

// Register user route
router.post('/register', registerUser);

// Login user route
router.post('/login', loginUser);

// Logout user route
router.post('/logout', logoutUser);

// Refresh token route
router.post('/refresh-token', refreshToken);

// Verify token route
router.post('/verify-token', verifyToken);

export default router;
