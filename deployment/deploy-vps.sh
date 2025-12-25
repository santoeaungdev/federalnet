#!/usr/bin/env bash
# VPS Production Deployment Script for FederalNet
# This script sets up and deploys the complete FederalNet application stack
# on a VPS server using Docker Compose.

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="${DEPLOY_DIR:-/opt/federalnet}"
REPO_URL="${REPO_URL:-https://github.com/santoeaungdev/federalnet.git}"
BRANCH="${BRANCH:-main}"
DOMAIN="${DOMAIN:-}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing system dependencies..."
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        ufw \
        certbot \
        python3-certbot-nginx
}

install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed"
        return
    fi

    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh

    log_info "Installing Docker Compose..."
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    systemctl enable docker
    systemctl start docker
}

setup_firewall() {
    log_info "Configuring firewall..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 1812/udp  # RADIUS authentication
    ufw allow 1813/udp  # RADIUS accounting
    ufw reload
}

clone_repository() {
    log_info "Cloning repository..."
    if [ -d "$DEPLOY_DIR" ]; then
        log_warn "Deployment directory already exists. Pulling latest changes..."
        cd "$DEPLOY_DIR"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    else
        mkdir -p "$DEPLOY_DIR"
        git clone -b "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
        cd "$DEPLOY_DIR"
    fi
}

setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f "$DEPLOY_DIR/.env.production" ]; then
        cp "$DEPLOY_DIR/.env.production.example" "$DEPLOY_DIR/.env.production"
        
        # Generate random passwords
        MYSQL_ROOT_PASS=$(openssl rand -base64 32)
        MYSQL_PASS=$(openssl rand -base64 32)
        JWT_SECRET=$(openssl rand -base64 64)
        
        # Update .env.production
        sed -i "s/change_this_root_password/$MYSQL_ROOT_PASS/" "$DEPLOY_DIR/.env.production"
        sed -i "s/change_this_password/$MYSQL_PASS/" "$DEPLOY_DIR/.env.production"
        sed -i "s/change_this_to_a_long_random_string_for_production/$JWT_SECRET/" "$DEPLOY_DIR/.env.production"
        
        log_info "Generated new credentials. Please review $DEPLOY_DIR/.env.production"
    else
        log_warn "Environment file already exists. Skipping generation."
    fi
}

setup_ssl() {
    if [ -z "$DOMAIN" ]; then
        log_warn "No domain specified. Skipping SSL setup."
        log_warn "To set up SSL later, run: certbot --nginx -d your-domain.com"
        
        # Create self-signed certificate for development
        log_info "Creating self-signed SSL certificate..."
        mkdir -p "$DEPLOY_DIR/deployment/nginx/ssl"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$DEPLOY_DIR/deployment/nginx/ssl/key.pem" \
            -out "$DEPLOY_DIR/deployment/nginx/ssl/cert.pem" \
            -subj "/C=MM/ST=Yangon/L=Yangon/O=FederalNet/CN=localhost"
        return
    fi
    
    log_info "Setting up SSL certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@"$DOMAIN"
    
    # Update nginx configuration with domain
    sed -i "s/server_name _;/server_name $DOMAIN;/" "$DEPLOY_DIR/deployment/nginx/conf.d/federalnet.conf"
}

deploy_application() {
    log_info "Deploying application with Docker Compose..."
    cd "$DEPLOY_DIR"
    
    # Create required directories
    mkdir -p deployment/nginx/ssl
    
    # Build and start services
    docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
    
    log_info "Waiting for services to be healthy..."
    sleep 10
    
    # Check service health
    if docker compose -f docker-compose.prod.yml ps | grep -q "unhealthy"; then
        log_error "Some services are unhealthy. Check logs with: docker compose -f docker-compose.prod.yml logs"
        exit 1
    fi
}

setup_backup() {
    log_info "Setting up automated backups..."
    
    # Create backup directory
    mkdir -p /var/backups/federalnet
    
    # Create backup script
    cat > /usr/local/bin/federalnet-backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/federalnet"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MYSQL_CONTAINER="federalnet-mysql"

# Backup database using MYSQL_PWD environment variable for security
docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" $MYSQL_CONTAINER mysqldump -u root --all-databases > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Compress backup
gzip "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +7 -delete
EOF
    
    chmod +x /usr/local/bin/federalnet-backup.sh
    
    # Add to crontab (daily at 2 AM)
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/federalnet-backup.sh") | crontab -
    
    log_info "Backup configured to run daily at 2 AM"
}

print_summary() {
    log_info "=========================="
    log_info "Deployment Summary"
    log_info "=========================="
    log_info "Deployment directory: $DEPLOY_DIR"
    log_info "Environment file: $DEPLOY_DIR/.env.production"
    log_info ""
    log_info "Services:"
    docker compose -f "$DEPLOY_DIR/docker-compose.prod.yml" ps
    log_info ""
    log_info "Access the application:"
    if [ -n "$DOMAIN" ]; then
        log_info "  - API: https://$DOMAIN/api/health"
        log_info "  - Web: https://$DOMAIN/"
    else
        log_info "  - API: http://YOUR_SERVER_IP/api/health"
        log_info "  - Web: http://YOUR_SERVER_IP/"
    fi
    log_info ""
    log_info "Useful commands:"
    log_info "  - View logs: cd $DEPLOY_DIR && docker compose -f docker-compose.prod.yml logs -f"
    log_info "  - Restart services: cd $DEPLOY_DIR && docker compose -f docker-compose.prod.yml restart"
    log_info "  - Stop services: cd $DEPLOY_DIR && docker compose -f docker-compose.prod.yml down"
    log_info "  - Update application: cd $DEPLOY_DIR && git pull && docker compose -f docker-compose.prod.yml up -d --build"
    log_info ""
    log_info "IMPORTANT: Review and update credentials in $DEPLOY_DIR/.env.production"
}

main() {
    log_info "Starting FederalNet VPS deployment..."
    
    check_root
    install_dependencies
    install_docker
    setup_firewall
    clone_repository
    setup_environment
    setup_ssl
    deploy_application
    setup_backup
    print_summary
    
    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"
