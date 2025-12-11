#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$1" in
  start)
    echo -e "${BLUE}🚀 Iniciando Shaka API...${NC}"
    
    # Verificar se já está rodando
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
      echo -e "${YELLOW}⚠ Servidor já está rodando na porta 3000${NC}"
      echo -e "${YELLOW}Execute: ./manage-server.sh restart${NC}"
      exit 1
    fi
    
    # Iniciar em background com nohup
    nohup npm run dev > server.log 2>&1 &
    PID=$!
    echo $PID > .server.pid
    
    echo -e "${GREEN}✓ Servidor iniciado (PID: $PID)${NC}"
    echo -e "${GREEN}✓ Logs em: server.log${NC}"
    echo ""
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo -e "  Ver logs: tail -f server.log"
    echo -e "  Parar: ./manage-server.sh stop"
    echo -e "  Status: ./manage-server.sh status"
    ;;
    
  stop)
    echo -e "${YELLOW}🛑 Parando Shaka API...${NC}"
    
    if [ -f .server.pid ]; then
      PID=$(cat .server.pid)
      if kill -0 $PID 2>/dev/null; then
        kill $PID
        rm .server.pid
        echo -e "${GREEN}✓ Servidor parado (PID: $PID)${NC}"
      else
        echo -e "${YELLOW}⚠ Processo não encontrado${NC}"
        rm .server.pid
      fi
    else
      # Tentar matar pela porta
      PIDS=$(lsof -ti:3000)
      if [ -n "$PIDS" ]; then
        kill -9 $PIDS
        echo -e "${GREEN}✓ Processos na porta 3000 encerrados${NC}"
      else
        echo -e "${YELLOW}⚠ Nenhum servidor rodando${NC}"
      fi
    fi
    ;;
    
  restart)
    echo -e "${BLUE}🔄 Reiniciando Shaka API...${NC}"
    $0 stop
    sleep 2
    $0 start
    ;;
    
  status)
    echo -e "${BLUE}📊 Status do Shaka API${NC}"
    echo ""
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
      PID=$(lsof -ti:3000)
      echo -e "${GREEN}✓ Servidor RODANDO${NC}"
      echo -e "  PID: $PID"
      echo -e "  Porta: 3000"
      echo -e "  URL: http://localhost:3000"
      echo ""
      
      # Testar health
      if curl -s http://localhost:3000/health > /dev/null; then
        echo -e "${GREEN}✓ Health check: OK${NC}"
      else
        echo -e "${RED}✗ Health check: FALHOU${NC}"
      fi
    else
      echo -e "${RED}✗ Servidor NÃO está rodando${NC}"
    fi
    ;;
    
  logs)
    if [ -f server.log ]; then
      tail -f server.log
    else
      echo -e "${RED}✗ Arquivo de log não encontrado${NC}"
    fi
    ;;
    
  test)
    echo -e "${BLUE}🧪 Testando API...${NC}"
    echo ""
    
    # Health check
    echo -n "Health check: "
    if curl -s http://localhost:3000/health > /dev/null; then
      echo -e "${GREEN}✓ OK${NC}"
      curl -s http://localhost:3000/health | jq '.'
    else
      echo -e "${RED}✗ FALHOU${NC}"
    fi
    ;;
    
  *)
    echo -e "${BLUE}Gerenciador do Shaka API${NC}"
    echo ""
    echo "Uso: $0 {start|stop|restart|status|logs|test}"
    echo ""
    echo "Comandos:"
    echo "  start   - Iniciar servidor em background"
    echo "  stop    - Parar servidor"
    echo "  restart - Reiniciar servidor"
    echo "  status  - Ver status do servidor"
    echo "  logs    - Ver logs em tempo real"
    echo "  test    - Testar endpoints"
    exit 1
    ;;
esac

