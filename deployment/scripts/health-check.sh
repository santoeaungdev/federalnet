#!/bin/bash
# Health check script for FederalNet services
# Can be used for monitoring or alerting

set -euo pipefail

# Configuration
API_URL="${API_URL:-http://localhost/api/health}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-federalnet-mysql}"
COMPOSE_FILE="${COMPOSE_FILE:-/opt/federalnet/docker-compose.prod.yml}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment if exists
if [ -f /opt/federalnet/.env.production ]; then
    source /opt/federalnet/.env.production
fi

ALL_HEALTHY=true

echo "FederalNet Health Check - $(date)"
echo "========================================"
echo ""

# Check API health
echo -n "API Service: "
HTTP_CODE=$(curl -f -s -o /dev/null -w '%{http_code}' "$API_URL" 2>/dev/null || echo '000')
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${RED}✗ Unhealthy (HTTP $HTTP_CODE)${NC}"
    ALL_HEALTHY=false
fi

# Check MySQL
echo -n "MySQL Database: "
if docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" "$MYSQL_CONTAINER" mysqladmin ping -h localhost -u root --silent 2>/dev/null; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${RED}✗ Unhealthy${NC}"
    ALL_HEALTHY=false
fi

# Check Nginx
echo -n "Nginx: "
if docker ps | grep -q "federalnet-nginx.*Up"; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Running${NC}"
    ALL_HEALTHY=false
fi

# Check container status
echo ""
echo "Container Status:"
echo "----------------"
if [ -f "$COMPOSE_FILE" ]; then
    docker compose -f "$COMPOSE_FILE" ps
else
    docker ps --filter "name=federalnet"
fi

# Check disk space
echo ""
echo "Disk Space:"
echo "----------"
df -h / | grep -v Filesystem

# Check memory usage
echo ""
echo "Memory Usage:"
echo "------------"
free -h

# Check Docker volume sizes
echo ""
echo "Docker Volumes:"
echo "--------------"
docker volume ls --filter "name=federalnet" --format "table {{.Name}}\t{{.Driver}}"

echo ""
if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}All services are healthy!${NC}"
    exit 0
else
    echo -e "${RED}Some services are unhealthy!${NC}"
    exit 1
fi
