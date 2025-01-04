import express from 'express';
import { grantRole, revokeRole, approveAuthor, revokeAuthor } from '../controllers/adminController.mjs';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware.mjs';
import { requestAuthorRole } from '../controllers/authorController.mjs';

const router = express.Router();

// DEFAULT_ADMIN routes
router.post('/grant-role', authenticateJWT, requireRole('DEFAULT_ADMIN'), grantRole);
router.post('/revoke-role', authenticateJWT, requireRole('DEFAULT_ADMIN'), revokeRole);

// PLATFORM_ADMIN routes
router.post('/approve-author', authenticateJWT, requireRole('PLATFORM_ADMIN'), approveAuthor);
router.post('/revoke-author', authenticateJWT, requireRole('PLATFORM_ADMIN'), revokeAuthor);

// AUTHOR routes
router.post('/request-author', authenticateJWT, requireRole('USER'), requestAuthorRole);

export default router;
