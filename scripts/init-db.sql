-- Shaka API - Inicialização do Banco de Dados

-- Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Schema principal
CREATE SCHEMA IF NOT EXISTS shaka;

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS shaka.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'starter',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de API Keys
CREATE TABLE IF NOT EXISTS shaka.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES shaka.users(id) ON DELETE CASCADE,
    key_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(key_hash)
);

-- Tabela de uso da API (rate limiting)
CREATE TABLE IF NOT EXISTS shaka.api_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES shaka.users(id) ON DELETE CASCADE,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_users_email ON shaka.users(email);
CREATE INDEX idx_users_plan ON shaka.users(plan);
CREATE INDEX idx_api_keys_user ON shaka.api_keys(user_id);
CREATE INDEX idx_api_usage_user_timestamp ON shaka.api_usage(user_id, timestamp);
CREATE INDEX idx_api_usage_timestamp ON shaka.api_usage(timestamp);

-- Inserir usuário de teste
INSERT INTO shaka.users (email, password_hash, full_name, plan)
VALUES ('admin@shaka.api', crypt('admin123', gen_salt('bf')), 'Admin User', 'business')
ON CONFLICT (email) DO NOTHING;

COMMENT ON SCHEMA shaka IS 'Schema principal da Shaka API';
