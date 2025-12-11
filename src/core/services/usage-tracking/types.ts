/**
 * Usage Tracking Types
 * Define interfaces para rastreamento de uso da API
 */

export interface UsageRecord {
  id: string;
  apiKeyId: string;
  userId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number; // milliseconds
  timestamp: Date;
  ipAddress?: string;
  userAgent?: string;
  errorMessage?: string;
}

export interface UsageStats {
  totalRequests: number;
  requestsToday: number;
  requestsThisWeek: number;
  requestsThisMonth: number;
  lastUsed: Date | null;
  averageLatency: number;
  errorRate: number;
  mostUsedEndpoints: EndpointStats[];
  statusCodeDistribution: { [key: number]: number };
}

export interface EndpointStats {
  endpoint: string;
  method: string;
  count: number;
  averageLatency: number;
  errorCount: number;
}

export interface DailyUsage {
  date: string; // YYYY-MM-DD
  requests: number;
  errors: number;
  averageLatency: number;
}

export interface TrackUsageDTO {
  apiKeyId: string;
  userId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number;
  ipAddress?: string;
  userAgent?: string;
  errorMessage?: string;
}
