# Ingress Deployment Scripts

## Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `deploy-ingress.sh` | Deploy completo do Ingress (staging + dev) |
| `test-ingress.sh` | Testes E2E do Ingress |
| `rollback-ingress.sh` | Rollback para configuração anterior |

## Uso
```bash
# Deploy
bash ~/shaka-api/scripts/deployment/ingress/deploy-ingress.sh

# Testar
bash ~/shaka-api/scripts/deployment/ingress/test-ingress.sh

# Rollback (se necessário)
bash ~/shaka-api/scripts/deployment/ingress/rollback-ingress.sh
```

## Troubleshooting

Ver: `~/shaka-api/infrastructure/kubernetes/ingress/README.md`
