# FederalNet VPS Deployment Guide

This guide explains how to deploy the FederalNet ISP billing system on a VPS (Virtual Private Server).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Methods](#deployment-methods)
  - [Method 1: Automated Deployment (Recommended)](#method-1-automated-deployment-recommended)
  - [Method 2: Docker Compose Deployment](#method-2-docker-compose-deployment)
  - [Method 3: Manual Deployment](#method-3-manual-deployment)
- [Configuration](#configuration)
- [SSL/TLS Setup](#ssltls-setup)
- [Database Management](#database-management)
- [Monitoring and Logs](#monitoring-and-logs)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Prerequisites

### Server Requirements

- **OS**: Ubuntu 20.04 LTS or later (Debian-based)
- **RAM**: Minimum 2GB, recommended 4GB+
- **Storage**: Minimum 20GB SSD
- **Network**: Public IP address with ports 80, 443 accessible
- **Domain** (optional but recommended): For SSL/TLS setup

### Required Software

The deployment script will install these automatically:
- Docker (latest)
- Docker Compose (latest)
- Git
- UFW (firewall)
- Certbot (for SSL)

## Quick Start

For a fresh VPS, run this one-line command as root:

```bash
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | bash
```

Or with a custom domain:

```bash
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | DOMAIN=your-domain.com bash
```

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

This method uses the automated deployment script that handles everything for you.

1. **SSH into your VPS**:
   ```bash
   ssh root@your-server-ip
   ```

2. **Download and run the deployment script**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh -o deploy-vps.sh
   chmod +x deploy-vps.sh
   ./deploy-vps.sh
   ```

3. **With custom settings**:
   ```bash
   DOMAIN=federalnet.example.com \
   DEPLOY_DIR=/opt/federalnet \
   BRANCH=main \
   ./deploy-vps.sh
   ```

The script will:
- Install all dependencies (Docker, Docker Compose, Git)
- Configure the firewall
- Clone the repository
- Generate secure credentials
- Set up SSL certificates (if domain provided)
- Deploy the application stack
- Configure automated backups

### Method 2: Docker Compose Deployment

For manual control over the deployment process:

1. **Prepare the server**:
   ```bash
   # Update system
   apt-get update && apt-get upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com | bash
   
   # Install Docker Compose
   mkdir -p /usr/local/lib/docker/cli-plugins
   curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
     -o /usr/local/lib/docker/cli-plugins/docker-compose
   chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
   ```

2. **Clone the repository**:
   ```bash
   mkdir -p /opt/federalnet
   cd /opt/federalnet
   git clone https://github.com/santoeaungdev/federalnet.git .
   ```

3. **Configure environment**:
   ```bash
   cp .env.production.example .env.production
   nano .env.production  # Edit with your credentials
   ```

4. **Create SSL certificates** (self-signed for testing):
   ```bash
   mkdir -p deployment/nginx/ssl
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout deployment/nginx/ssl/key.pem \
     -out deployment/nginx/ssl/cert.pem
   ```

5. **Deploy the application**:
   ```bash
   docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
   ```

6. **Verify deployment**:
   ```bash
   docker compose -f docker-compose.prod.yml ps
   curl http://localhost/api/health
   ```

### Method 3: Manual Deployment

For native installation without Docker:

1. **Install Rust**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   ```

2. **Install MySQL**:
   ```bash
   apt-get install -y mysql-server
   mysql_secure_installation
   ```

3. **Setup database**:
   ```bash
   mysql -u root -p < docker/federalnet_schema.sql
   mysql -u root -p < docker/radius.sql
   ```

4. **Build backend**:
   ```bash
   cd backend/federalnet-api
   cargo build --release
   ```

5. **Configure systemd service**:
   ```bash
   cp deployment/systemd/federalnet-api.service /etc/systemd/system/
   systemctl daemon-reload
   systemctl enable federalnet-api
   systemctl start federalnet-api
   ```

6. **Install and configure Nginx**:
   ```bash
   apt-get install -y nginx
   cp deployment/nginx/conf.d/federalnet.conf /etc/nginx/sites-available/federalnet
   ln -s /etc/nginx/sites-available/federalnet /etc/nginx/sites-enabled/
   nginx -t
   systemctl restart nginx
   ```

## Configuration

### Environment Variables

Edit `/opt/federalnet/.env.production`:

```bash
# MySQL Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=federalnetwuntho
MYSQL_USER=federalnet
MYSQL_PASSWORD=your_secure_password

# API Configuration
JWT_SECRET=your_very_long_random_jwt_secret_key
RUST_LOG=info

# Optional: Enable seed endpoints (DO NOT enable in production)
ENABLE_SEED_ENDPOINTS=0
```

### Nginx Configuration

Edit `deployment/nginx/conf.d/federalnet.conf` to customize:
- Server name (domain)
- SSL certificate paths
- Proxy settings
- Rate limiting

## SSL/TLS Setup

### Using Let's Encrypt (Recommended for Production)

1. **Ensure your domain points to the server**:
   ```bash
   dig your-domain.com +short  # Should return your server IP
   ```

2. **Obtain SSL certificate**:
   ```bash
   certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

3. **Auto-renewal** (certbot sets this up automatically):
   ```bash
   certbot renew --dry-run  # Test renewal
   ```

### Using Self-Signed Certificate (Development/Testing)

```bash
mkdir -p deployment/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deployment/nginx/ssl/key.pem \
  -out deployment/nginx/ssl/cert.pem \
  -subj "/C=MM/ST=Yangon/L=Yangon/O=FederalNet/CN=your-domain.com"
```

## Database Management

### Import Initial Data

```bash
# Import schema
docker exec -i federalnet-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" federalnetwuntho < docker/federalnet_schema.sql

# Import RADIUS tables
docker exec -i federalnet-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" federalnetwuntho < docker/radius.sql
```

### Direct Database Access

```bash
docker exec -it federalnet-mysql mysql -u root -p
```

### Database Migrations

```bash
# Future migrations will be placed in docker/migrations/
# Run migrations manually:
docker exec -i federalnet-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" federalnetwuntho < docker/migrations/001_add_new_table.sql
```

## Monitoring and Logs

### View Application Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f mysql
docker compose -f docker-compose.prod.yml logs -f nginx
```

### System Logs (Manual Deployment)

```bash
# API logs
journalctl -u federalnet-api -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Health Checks

```bash
# API health
curl http://localhost/api/health

# Database health
docker exec federalnet-mysql mysqladmin ping -h localhost -u root -p

# Container status
docker compose -f docker-compose.prod.yml ps
```

## Backup and Restore

### Automated Backups

The deployment script sets up daily backups at 2 AM. Backups are stored in `/var/backups/federalnet/`.

### Manual Backup

```bash
# Database backup
docker exec federalnet-mysql mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > backup_$(date +%Y%m%d).sql

# Compress
gzip backup_$(date +%Y%m%d).sql
```

### Restore from Backup

```bash
# Uncompress
gunzip backup_20240101.sql.gz

# Restore
docker exec -i federalnet-mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" < backup_20240101.sql
```

### Application Files Backup

```bash
# Backup configuration
tar -czf federalnet-config-$(date +%Y%m%d).tar.gz \
  /opt/federalnet/.env.production \
  /opt/federalnet/deployment/nginx/
```

## Troubleshooting

### Service Won't Start

```bash
# Check Docker logs
docker compose -f docker-compose.prod.yml logs

# Check service status
docker compose -f docker-compose.prod.yml ps

# Restart services
docker compose -f docker-compose.prod.yml restart
```

### Database Connection Issues

```bash
# Verify database is running
docker exec federalnet-mysql mysqladmin ping -h localhost -u root -p

# Check DATABASE_URL in .env.production
cat /opt/federalnet/.env.production | grep DATABASE_URL

# Test connection from API container
docker exec -it federalnet-api /bin/bash
# Try to connect to mysql:3306
```

### SSL Certificate Issues

```bash
# Check certificate validity
openssl x509 -in deployment/nginx/ssl/cert.pem -text -noout

# Renew Let's Encrypt certificate
certbot renew

# Check Nginx configuration
nginx -t
```

### Port Already in Use

```bash
# Find what's using port 80/443
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Stop conflicting service
systemctl stop apache2  # or whatever is using the port
```

## Security Best Practices

1. **Change Default Credentials**: Always change default passwords in `.env.production`

2. **Firewall Configuration**:
   ```bash
   ufw enable
   ufw allow ssh
   ufw allow http
   ufw allow https
   ufw status
   ```

3. **Regular Updates**:
   ```bash
   apt-get update && apt-get upgrade -y
   docker compose -f docker-compose.prod.yml pull
   docker compose -f docker-compose.prod.yml up -d
   ```

4. **Use SSL/TLS**: Always use HTTPS in production

5. **Disable Seed Endpoints**: Set `ENABLE_SEED_ENDPOINTS=0` in production

6. **Regular Backups**: Ensure automated backups are working

7. **Monitor Logs**: Regularly check logs for suspicious activity

8. **Limit Database Access**: Database should only be accessible from localhost

9. **Strong JWT Secret**: Use a long, random string for `JWT_SECRET`

10. **Keep Software Updated**: Regularly update Docker images and system packages

## Updates and Maintenance

### Update Application

```bash
cd /opt/federalnet
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build
```

### Update Docker Images

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Clean Up Old Images

```bash
docker system prune -a
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/santoeaungdev/federalnet/issues
- Documentation: Check the `/docs` directory in the repository

## License

This deployment setup is part of the FederalNet project.
