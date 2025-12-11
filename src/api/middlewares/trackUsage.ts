import { Request, Response, NextFunction } from 'express';
import { UsageTrackingService } from '../../core/services/usage-tracking/UsageTrackingService';
import { logger } from '../../config/logger';

/**
 * Middleware para rastrear uso da API automaticamente
 * Deve ser usado DEPOIS do apiKeyAuth middleware
 */
export const trackUsage = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Capturar timestamp de início
  const startTime = Date.now();

  // Interceptar res.send() para capturar statusCode e responseTime
  const originalSend = res.send;
  
  res.send = function (data: any): Response {
    // Calcular tempo de resposta
    const responseTime = Date.now() - startTime;
    
    // Verificar se tem API key (tracking só funciona com API key auth)
    if (req.apiKey && req.user) {
      // Track usage (fire and forget - não bloqueia response)
      UsageTrackingService.trackUsage({
        apiKeyId: req.apiKey.id,
        userId: req.user.id,
        endpoint: req.originalUrl || req.url,
        method: req.method,
        statusCode: res.statusCode,
        responseTime,
        ipAddress: req.ip || req.socket.remoteAddress,
        userAgent: req.get('user-agent'),
        errorMessage: res.statusCode >= 400 ? (data?.error || data?.message) : undefined
      }).catch((error) => {
        logger.error('[trackUsage] Error tracking usage:', {
          error: error.message,
          apiKeyId: req.apiKey?.id
        });
      });
    }
    
    // Chamar método original
    return originalSend.call(this, data);
  };

  next();
};

/**
 * Middleware simplificado para rotas públicas
 * Apenas loga requests sem salvar no banco
 */
export const logRequest = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  logger.info('[Request]', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });

  next();
};
