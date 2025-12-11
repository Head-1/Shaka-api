# Shaka API 🚀

> Enterprise-grade API Management Platform with Multi-tenancy & AI-Powered Analytics

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue.svg)](https://www.typescriptlang.org/)
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Coverage](https://img.shields.io/badge/coverage-81.9%25-brightgreen.svg)]()

![Shaka API Architecture](docs/images/architecture.png)

## 📋 Overview

Shaka API is a production-ready SaaS platform for API key management, usage tracking, and analytics. Built with Clean Architecture principles and designed for enterprise scalability.

### Key Features

- ✅ **Multi-tenancy**: 4-tier subscription system (Free, Basic, Pro, Enterprise)
- ✅ **API Key Management**: Generate, rotate, and revoke keys with fine-grained permissions
- ✅ **Usage Tracking**: Real-time analytics with rate limiting
- ✅ **JWT Authentication**: Secure auth with refresh tokens
- ✅ **Redis Caching**: High-performance caching layer
- ✅ **Kubernetes Ready**: Production-grade K8s manifests included
- ✅ **143 Automated Tests**: 81.9% code coverage

## 🏗️ Architecture
```
┌─────────────────────────────────────────┐
│          API Gateway (Express)          │
├─────────────────────────────────────────┤
│  Controllers  →  Services  →  Repos     │
├─────────────────────────────────────────┤
│  PostgreSQL (Primary)  │  Redis (Cache) │
└─────────────────────────────────────────┘
```

### Tech Stack

- **Runtime**: Node.js 20+ with TypeScript 5.3
- **Framework**: Express 4.18
- **Database**: PostgreSQL 15 with TypeORM
- **Cache**: Redis 7
- **Auth**: JWT with bcrypt
- **Testing**: Jest with Supertest
- **Infra**: Docker, Kubernetes (K3s)

## 🚀 Quick Start

### Prerequisites

- Node.js 20+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose (optional)

### Installation
```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/shaka-api.git
cd shaka-api

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env with your database credentials

# 4. Run migrations
npm run typeorm migration:run

# 5. Start development server
npm run dev

# API will be available at http://localhost:3000
```

### Docker Setup (Recommended)
```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## 📖 API Documentation

### Authentication
```bash
# Register user
POST /api/v1/auth/register
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "secure_password"
}

# Login
POST /api/v1/auth/login
{
  "email": "john@example.com",
  "password": "secure_password"
}
# Returns: { accessToken, refreshToken }
```

### API Key Management
```bash
# Create API key
POST /api/v1/api-keys
Authorization: Bearer <accessToken>
{
  "name": "Production Key",
  "permissions": ["read", "write"]
}

# List keys
GET /api/v1/api-keys
Authorization: Bearer <accessToken>

# Revoke key
DELETE /api/v1/api-keys/:keyId
Authorization: Bearer <accessToken>
```

Full API documentation: [docs/API.md](docs/API.md)

## 🧪 Testing
```bash
# Run all tests
npm test

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage

# E2E tests
npm run test:e2e
```

Current test coverage: **81.9%** (143 tests passing)

## 📦 Deployment

### Kubernetes
```bash
# Deploy to K8s cluster
kubectl apply -f infrastructure/kubernetes/

# Check deployment
kubectl get pods -n shaka-api

# View logs
kubectl logs -f deployment/shaka-api -n shaka-api
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DB_HOST` | PostgreSQL host | ✅ |
| `DB_PORT` | PostgreSQL port | ✅ |
| `DB_USER` | Database user | ✅ |
| `DB_PASSWORD` | Database password | ✅ |
| `DB_NAME` | Database name | ✅ |
| `REDIS_HOST` | Redis host | ✅ |
| `REDIS_PORT` | Redis port | ✅ |
| `JWT_SECRET` | JWT signing secret | ✅ |
| `JWT_EXPIRES_IN` | Token expiry (default: 15m) | ❌ |

See [.env.example](.env.example) for complete list.

## 📊 Project Structure
```
shaka-api/
├── src/
│   ├── api/                    # API Layer
│   │   ├── controllers/        # Route handlers
│   │   ├── middlewares/        # Express middlewares
│   │   ├── routes/             # Route definitions
│   │   └── validators/         # Request validation
│   │
│   ├── core/                   # Business Logic
│   │   ├── services/           # Domain services
│   │   └── types/              # Domain types
│   │
│   ├── infrastructure/         # External Services
│   │   ├── database/           # TypeORM config
│   │   │   ├── entities/       # DB models
│   │   │   ├── migrations/     # DB migrations
│   │   │   └── repositories/   # Data access
│   │   └── cache/              # Redis client
│   │
│   ├── shared/                 # Shared utilities
│   │   ├── errors/             # Custom errors
│   │   └── utils/              # Helper functions
│   │
│   └── server.ts               # App entry point
│
├── tests/                      # Test suites
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # E2E tests
│
├── infrastructure/
│   └── kubernetes/             # K8s manifests
│
└── docs/                       # Documentation
```

## 🗺️ Roadmap

- [x] Core API functionality
- [x] JWT authentication
- [x] Multi-tenancy support
- [x] Rate limiting
- [x] Usage analytics
- [ ] Webhooks
- [ ] GraphQL API
- [ ] SSO/SAML integration
- [ ] Mobile SDK
- [ ] Admin dashboard

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass (`npm test`)
- Code follows ESLint rules (`npm run lint`)
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/)

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 👤 Author

**[Seu Nome]**

- GitHub: [@seu-usuario](https://github.com/seu-usuario)
- LinkedIn: [seu-nome](https://linkedin.com/in/seu-nome)
- Portfolio: [seu-site.dev](https://seu-site.dev)

## 🙏 Acknowledgments

- [TypeORM](https://typeorm.io/) - ORM framework
- [Express](https://expressjs.com/) - Web framework
- [Jest](https://jestjs.io/) - Testing framework

---

⭐ If this project helped you, please give it a star!

**Built with ❤️ using Clean Architecture principles**
