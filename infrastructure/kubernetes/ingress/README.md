# Shaka API - Ingress Configuration

## Overview
Configuração do Traefik Ingress Controller para acesso externo à Shaka API.

## Arquitetura
```
Internet (91.99.184.67)
    ↓
Traefik LoadBalancer (ports 80/443)
    ↓
Ingress Rules (staging.shaka.local, dev.shaka.local)
    ↓
Middlewares (CORS, Rate Limit)
    ↓
Service ClusterIP (shaka-api:3000)
    ↓
Pods (staging: 2/2, dev: 1/2)
```

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `01-ingress-staging.yaml` | Ingress + Service para staging |
| `02-ingress-dev.yaml` | Ingress + Service para dev |
| `03-middleware-cors.yaml` | CORS policy (staging: restritivo, dev: permissivo) |
| `04-middleware-ratelimit.yaml` | Rate limiting (staging: 100rps, dev: 1000rps) |

## Deploy
```bash
# Deploy completo
bash ~/shaka-api/scripts/deployment/ingress/deploy-ingress.sh

# Deploy individual
kubectl apply -f ~/shaka-api/infrastructure/kubernetes/ingress/

# Verificar
kubectl get ingress -A
kubectl describe ingress shaka-api -n shaka-staging
```

## Configuração do Host

Adicione ao `/etc/hosts`:
```bash
sudo nano /etc/hosts

# Adicionar:
127.0.0.1  staging.shaka.local
127.0.0.1  dev.shaka.local
```

## Endpoints

### Staging
- **Base URL:** http://staging.shaka.local
- **Health:** http://staging.shaka.local/health
- **API v1:** http://staging.shaka.local/api/v1/...

### Dev
- **Base URL:** http://dev.shaka.local
- **Health:** http://dev.shaka.local/health
- **API v1:** http://dev.shaka.local/api/v1/...

## Testing
```bash
# Health check
curl http://staging.shaka.local/health

# API endpoint
curl -X POST http://staging.shaka.local/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!"}'

# CORS test
curl -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  http://staging.shaka.local/api/v1/auth/login -v
```

## Troubleshooting

### Ingress não responde
```bash
# Verificar Traefik
kubectl get pods -n kube-system | grep traefik
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# Verificar Ingress
kubectl describe ingress shaka-api -n shaka-staging

# Verificar Service
kubectl get svc shaka-api -n shaka-staging
kubectl get endpoints shaka-api -n shaka-staging
```

### 404 Not Found
```bash
# Verificar pods
kubectl get pods -n shaka-staging -l app=shaka-api

# Verificar logs
kubectl logs -n shaka-staging -l app=shaka-api --tail=50

# Port-forward direto (bypass Ingress)
kubectl port-forward -n shaka-staging svc/shaka-api 8080:3000
curl http://localhost:8080/health
```

## TLS/HTTPS (Futuro)

Para produção, descomentar seção TLS nos manifestos e criar certificados:
```bash
# Cert-Manager + Let's Encrypt
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ClusterIssuer
# ...ver .examples/tls-config.yaml
```

## Production Checklist

- [ ] Configurar DNS real (substituir *.shaka.local)
- [ ] Configurar TLS/SSL (Let's Encrypt ou wildcard cert)
- [ ] Ajustar rate limits para carga real
- [ ] Configurar CORS para domínios de produção
- [ ] Adicionar WAF rules (ModSecurity)
- [ ] Configurar IP whitelist para admin endpoints
- [ ] Monitoramento de Ingress (Prometheus + Grafana)

## Referências

- [Traefik Docs](https://doc.traefik.io/traefik/)
- [K3s Ingress](https://docs.k3s.io/networking#traefik-ingress-controller)
- [Traefik Middleware](https://doc.traefik.io/traefik/middlewares/overview/)
