import app from './src/app.mjs'; 
import { ENV } from './src/config/environment.mjs'; 
import { connectDB } from './src/config/db.mjs';
import logger from './src/utils/logger.mjs'; 

(async () => {
    // Connect to MongoDB
        await connectDB();
        logger.info('Connected to MongoDB');

        // Start the server
        const PORT = ENV.port || 3000;
        app.listen(PORT, () => {
            logger.info(`Server running on http://localhost:${PORT}`);
        });
  
})();
