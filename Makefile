# ============================================================================
# SHAKA API - MAKEFILE
# ============================================================================

.PHONY: help start stop restart logs health reset migrate build ps shell

help:
	@./docker.sh help

start:
	@./docker.sh start

stop:
	@./docker.sh stop

restart:
	@./docker.sh restart

logs:
	@./docker.sh logs

health:
	@./docker.sh health

reset:
	@./docker.sh reset

migrate-run:
	@./docker.sh migrate run

migrate-revert:
	@./docker.sh migrate revert

build:
	@./docker.sh build

ps:
	@./docker.sh ps

shell:
	@./docker.sh shell

# Atalhos adicionais
dev:
	@./docker.sh start dev

prod:
	@./docker.sh start prod

test:
	@docker-compose exec api npm test

coverage:
	@docker-compose exec api npm run test:coverage
