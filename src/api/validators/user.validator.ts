import Joi from 'joi';

// Schemas Joi
export const registerUserSchema = Joi.object({
  name: Joi.string().min(3).max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/)
    .required(),
  plan: Joi.string().valid('starter', 'pro', 'business').default('starter')
});

export const updateUserSchema = Joi.object({
  name: Joi.string().min(2).max(100),
  email: Joi.string().email(),
  plan: Joi.string().valid('starter', 'pro', 'business')
});

export const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required(),
  newPassword: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/)
    .required()
});

export const listUsersSchema = Joi.object({
  page: Joi.string().pattern(/^\d+$/).default('1'),
  limit: Joi.string().pattern(/^\d+$/).custom((value, helpers) => {
    const num = parseInt(value, 10);
    if (num > 100) {
      return helpers.error('any.invalid');
    }
    return value;
  }).default('10')
});

// Funcoes de validacao (EXPORT ADICIONADO)
export function validateUserRegistration(data: any) {
  return registerUserSchema.validate(data);
}

export function validateUserUpdate(data: any) {
  return updateUserSchema.validate(data);
}

export function validatePasswordChange(data: any) {
  return changePasswordSchema.validate(data);
}

export function validateUserQuery(data: any) {
  return listUsersSchema.validate(data);
}
