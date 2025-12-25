#!/bin/bash
# Deployment validation script
# Validates that all required files and configurations are present
# Note: Not using 'set -e' to allow all checks to run and report all failures
# Using 'set -u' to catch undefined variables

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} $1"
        ((CHECKS_FAILED++))
    fi
}

echo "FederalNet Deployment Validation"
echo "=================================="
echo ""

# Check required files
echo "Checking required files..."

[ -f "docker-compose.prod.yml" ]
check "docker-compose.prod.yml exists"

[ -f ".env.production.example" ]
check ".env.production.example exists"

[ -f "backend/federalnet-api/Dockerfile" ]
check "backend/federalnet-api/Dockerfile exists"

[ -f "backend/federalnet-api/.dockerignore" ]
check "backend/federalnet-api/.dockerignore exists"

[ -f "deployment/deploy-vps.sh" ] && [ -x "deployment/deploy-vps.sh" ]
check "deployment/deploy-vps.sh exists and is executable"

[ -f "deployment/VPS_DEPLOYMENT.md" ]
check "deployment/VPS_DEPLOYMENT.md exists"

[ -f "deployment/nginx/nginx.conf" ]
check "deployment/nginx/nginx.conf exists"

[ -f "deployment/nginx/conf.d/federalnet.conf" ]
check "deployment/nginx/conf.d/federalnet.conf exists"

[ -f "deployment/systemd/federalnet-api.service" ]
check "deployment/systemd/federalnet-api.service exists"

echo ""
echo "Checking utility scripts..."

for script in backup-database.sh restore-database.sh health-check.sh; do
    [ -f "deployment/scripts/$script" ] && [ -x "deployment/scripts/$script" ]
    check "deployment/scripts/$script exists and is executable"
done

echo ""
echo "Checking database schema files..."

[ -f "docker/federalnet_schema.sql" ]
check "docker/federalnet_schema.sql exists"

[ -f "docker/radius.sql" ]
check "docker/radius.sql exists"

echo ""
echo "Checking backend files..."

[ -f "backend/federalnet-api/Cargo.toml" ]
check "backend/federalnet-api/Cargo.toml exists"

[ -f "backend/federalnet-api/src/main.rs" ]
check "backend/federalnet-api/src/main.rs exists"

echo ""
echo "Validation Results"
echo "=================="
echo -e "Passed: ${GREEN}${CHECKS_PASSED}${NC}"
echo -e "Failed: ${RED}${CHECKS_FAILED}${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. Please review before deploying.${NC}"
    exit 1
fi
