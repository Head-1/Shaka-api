import { Request, Response, NextFunction } from 'express';
import logger from '../../shared/utils/logger';
import { AppError } from '../../shared/errors/AppError';

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  if (error instanceof AppError) {
    logger.warn(`AppError: ${error.message}`, {
      statusCode: error.statusCode,
      path: req.path
    });

    res.status(error.statusCode).json({
      status: 'error',
      message: error.message,
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
    return;
  }

  logger.error('Unhandled error:', error);

  res.status(500).json({
    status: 'error',
    message: 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && {
      error: error.message,
      stack: error.stack
    })
  });
}
