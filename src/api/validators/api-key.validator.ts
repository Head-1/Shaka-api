import Joi from 'joi';

/**
 * Validator for creating API key
 */
export const createApiKeySchema = Joi.object({
  name: Joi.string()
    .min(3)
    .max(100)
    .required()
    .messages({
      'string.min': 'API key name must be at least 3 characters',
      'string.max': 'API key name must not exceed 100 characters',
      'any.required': 'API key name is required'
    }),

  permissions: Joi.array()
    .items(Joi.string().valid('read', 'write', 'delete', 'admin'))
    .default(['read', 'write'])
    .messages({
      'array.includes': 'Invalid permission. Must be one of: read, write, delete, admin'
    }),

  expiresAt: Joi.date()
    .iso()
    .greater('now')
    .optional()
    .messages({
      'date.greater': 'Expiration date must be in the future',
      'date.format': 'Expiration date must be in ISO 8601 format'
    })
});

/**
 * Validator for rotating API key
 */
export const rotateApiKeySchema = Joi.object({
  // No body params needed - ID comes from URL
});

/**
 * Validator for UUID params
 */
export const apiKeyIdSchema = Joi.object({
  id: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.guid': 'Invalid API key ID format',
      'any.required': 'API key ID is required'
    })
});
