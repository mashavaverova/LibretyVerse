import jwt from 'jsonwebtoken';
import { ENV } from '../config/environment.mjs';

if (!ENV.jwtSecret || !ENV.refreshTokenSecret || !ENV.defaultAdminWallet) {
    throw new Error('Missing critical environment variables.');
}

export const authenticateJWT = (req, res, next) => {
    const token = req.header('Authorization')?.split(' ')[1]; // Extract token from Bearer
    if (!token) {
        console.log('No token provided in request.');
        return res.status(401).json({ error: 'Access Denied. No token provided.' });
    }

    try {
        const verified = jwt.verify(token, ENV.jwtSecret);
        console.log('Token verified:', verified);
        req.user = verified; // Attach user info to request
        next();
    } catch (err) {
        console.error('Token verification failed:', err.message);
        return res.status(403).json({ error: 'Invalid Token.' });
    }
};



export const requireRole = (role) => async (req, res, next) => {
    if (!req.user) {
        console.error('No user in request. Role check failed.');
        return res.status(401).json({ error: 'Access Denied. User not authenticated.' });
    }

    console.log(`Checking user role. Required: ${role}, User role: ${req.user.role}`);

    if (req.user.role !== role) {
        console.warn(`Access Denied. User role '${req.user.role}' does not match required role '${role}'.`);
        return res.status(403).json({ error: `Access Denied. Requires ${role} role.` });
    }

    console.log(`Role check passed for role: ${role}`);

    next();
};




export const requireRoles = (roles) => (req, res, next) => {
    if (!req.user) {
        console.error('User information not found in request.');
        return res.status(401).json({ error: 'Access Denied. User not authenticated.' });
    }

    if (!roles.includes(req.user.role)) {
        console.warn(`Access Denied. User role ${req.user.role} is not in the allowed roles: ${roles.join(', ')}.`);
        return res.status(403).json({ error: 'Access Denied. Insufficient permissions.' });
    }
    next();
};

