import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import metadataRoutes from './routers/metadataRoutes.mjs';
import authRoutes from './routers/authRoutes.mjs';
import adminRoutes from './routers/adminRoutes.mjs';
import errorHandler from './middleware/errorHandler.mjs';
import logger from './utils/logger.mjs';
import { initializeDefaultAdmin } from './utils/initAdmin.mjs';


dotenv.config();

console.log('PORT:', process.env.PORT);
console.log('JWT_SECRET:', process.env.JWT_SECRET);
console.log('REFRESH_TOKEN_SECRET:', process.env.REFRESH_TOKEN_SECRET);
console.log('Mongo URI:', process.env.MONGO_URI);

console.log('Defined paths:', adminRoutes.stack.map(r => r.route?.path)); // Log all defined paths




const app = express();

// Middleware
app.use(express.json());
app.use(cors());

(async () => {
    await initializeDefaultAdmin();
})();

// Register routes
app.use('/api/metadata', metadataRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', authRoutes);

// Route not found middleware
app.use((req, res) => {
    logger.warn(`Route not found: ${req.method} ${req.originalUrl}`);
    res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use(errorHandler);

// Health Check
app.get('/', (req, res) => {
    res.send('Welcome to the Backend API!');
});

const PORT = process.env.PORT || 3000;

// Graceful shutdown with cleanup logic
process.on('SIGINT', async () => {
    logger.info('Shutting down server...');
    try {
        // Add any cleanup logic here
    } catch (err) {
        logger.error('Error during shutdown:', err);
    }
    process.exit(0);
});

process.on('SIGTERM', async () => {
    logger.info('Server terminated.');
    try {
        // Add any cleanup logic here
    } catch (err) {
        logger.error('Error during shutdown:', err);
    }
    process.exit(0);
});

export default app;
