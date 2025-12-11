import { Request, Response, NextFunction } from 'express';
import { ObjectSchema } from 'joi';
import { logger } from '../../config/logger';

/**
 * Middleware para validação de request usando Joi
 * @param schema - Joi schema
 * @param source - 'body' | 'query' | 'params' (default: 'body')
 */
export const validateRequest = (
  schema: ObjectSchema,
  source: 'body' | 'query' | 'params' = 'body'
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const dataToValidate = req[source];

    const { error, value } = schema.validate(dataToValidate, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      logger.warn('[validateRequest] Validation error:', {
        source,
        errors: error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message
        }))
      });

      res.status(400).json({
        error: 'Validation error',
        message: 'The request contains invalid data',
        details: error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message
        }))
      });
      return;
    }

    // Replace request data with validated data
    req[source] = value;

    next();
  };
};
