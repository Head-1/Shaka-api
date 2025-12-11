/**
 * Motor Hybrid - Main Entry Point
 * 
 * Arquitetura evolutiva:
 * - Fase 1: Auth Motor (agora)
 * - Fase 2: ATHOS Integration (futuro)
 * - Fase 3: MCP Protocol (quando necessário)
 */

export { AuthMotor } from './auth/AuthMotor';
export * from './types';

// Futuro: ATHOS integration
// export { AthosConnector } from './future-mcp/AthosConnector';

// Futuro: MCP Protocol
// export { MCPRouter } from './future-mcp/MCPRouter';
