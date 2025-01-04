import logger from '../utils/logger.mjs';

const errorHandler = (err, req, res, next) => {
    logger.error(`Error: ${err.message}`);
    res.status(500).json({ error: err.message });
};

export default errorHandler;
