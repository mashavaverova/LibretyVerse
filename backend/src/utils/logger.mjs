import pino from 'pino';

const isProduction = process.env.NODE_ENV === 'production';

const logger = pino({
    level: process.env.LOG_LEVEL || 'info',
    transport: isProduction
        ? undefined // Use JSON format in production
        : {
              target: 'pino-pretty',
              options: {
                  colorize: true, // Colorize the logs
                  translateTime: 'yyyy-mm-dd HH:MM:ss', // Human-readable time format
                  ignore: 'pid,hostname', // Ignore unnecessary fields
              },
          },
});

export default logger;
