# FederalNet VPS Deployment - Quick Reference

## One-Line Installation

```bash
# Basic installation
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | bash

# With domain (for SSL)
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | DOMAIN=your-domain.com bash
```

## Common Commands

### Service Management

```bash
# Navigate to deployment directory
cd /opt/federalnet

# Start services
docker compose -f docker-compose.prod.yml up -d

# Stop services
docker compose -f docker-compose.prod.yml down

# Restart services
docker compose -f docker-compose.prod.yml restart

# View logs
docker compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker compose -f docker-compose.prod.yml logs -f api
```

### Database Operations

```bash
# Backup database
./deployment/scripts/backup-database.sh

# Restore database
./deployment/scripts/restore-database.sh /var/backups/federalnet/db_backup_20240101_120000.sql.gz

# Access MySQL CLI
docker exec -it federalnet-mysql mysql -u root -p
```

### Health Checks

```bash
# Run health check
./deployment/scripts/health-check.sh

# Check API health
curl http://localhost/api/health

# Check service status
docker compose -f docker-compose.prod.yml ps
```

### Updates

```bash
# Update application
cd /opt/federalnet
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build

# Update Docker images only
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### SSL/TLS

```bash
# Setup SSL with Let's Encrypt
certbot --nginx -d your-domain.com

# Renew certificates
certbot renew

# Test renewal
certbot renew --dry-run
```

## File Locations

- **Deployment Directory**: `/opt/federalnet`
- **Environment File**: `/opt/federalnet/.env.production`
- **Backups**: `/var/backups/federalnet/`
- **Logs**: 
  - Docker: `docker compose logs`
  - Nginx: `/var/log/nginx/`
  - System: `journalctl -u federalnet-api`

## Environment Variables

Edit `/opt/federalnet/.env.production`:

```bash
MYSQL_ROOT_PASSWORD=<your-password>
MYSQL_DATABASE=federalnetwuntho
MYSQL_USER=federalnet
MYSQL_PASSWORD=<your-password>
JWT_SECRET=<your-jwt-secret>
RUST_LOG=info
ENABLE_SEED_ENDPOINTS=0
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose -f docker-compose.prod.yml logs

# Check disk space
df -h

# Restart Docker
systemctl restart docker
```

### Database connection issues
```bash
# Test MySQL
docker exec federalnet-mysql mysqladmin ping -h localhost -u root -p

# Check environment variables
cat /opt/federalnet/.env.production
```

### Port conflicts
```bash
# Check what's using ports
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Stop conflicting service
systemctl stop apache2
```

## Security Checklist

- [ ] Change all default passwords in `.env.production`
- [ ] Enable firewall (UFW)
- [ ] Setup SSL/TLS certificates
- [ ] Disable `ENABLE_SEED_ENDPOINTS` in production
- [ ] Configure automated backups
- [ ] Setup monitoring
- [ ] Regular security updates

## API Endpoints

- **Health**: `GET /api/health`
- **Admin Login**: `POST /api/admin/login`
- **Customer Login**: `POST /api/customer/login`
- **Customer Register**: `POST /api/customer/register`

## Support

- **Documentation**: `/opt/federalnet/deployment/VPS_DEPLOYMENT.md`
- **GitHub**: https://github.com/santoeaungdev/federalnet
- **Issues**: https://github.com/santoeaungdev/federalnet/issues
