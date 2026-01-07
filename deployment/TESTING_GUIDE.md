# VPS Deployment Testing Guide

This guide helps you test the VPS deployment before and after deploying to production.

## Pre-Deployment Testing

### 1. Validate Deployment Files

Run the validation script to ensure all required files are present:

```bash
./deployment/scripts/validate-deployment.sh
```

Expected output: All checks should pass (16/16).

### 2. Validate Docker Compose Configuration

```bash
docker compose -f docker-compose.prod.yml config
```

This should output the parsed configuration without errors.

### 3. Check Environment Template

Verify the environment template has all required variables:

```bash
cat .env.production.example
```

Required variables:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `JWT_SECRET`
- `RUST_LOG`
- `ENABLE_SEED_ENDPOINTS`

### 4. Validate Dockerfile

```bash
cd backend/federalnet-api
docker build -t federalnet-api-test .
```

This should build successfully without errors.

## Local Testing (Before VPS Deployment)

### 1. Create Test Environment

```bash
cp .env.production.example .env.test
# Edit .env.test with test credentials
nano .env.test
```

### 2. Test Database Schema Import

```bash
# Start MySQL container
docker compose -f docker/docker-compose.dev.yml up -d

# Wait for MySQL to be ready
sleep 10

# Import schema
docker exec -i mysql-federalnet-dev mysql -u root -padmin\$@nT03 -e "CREATE DATABASE IF NOT EXISTS test_federalnet;"
docker exec -i mysql-federalnet-dev mysql -u root -padmin\$@nT03 test_federalnet < docker/federalnet_schema.sql
docker exec -i mysql-federalnet-dev mysql -u root -padmin\$@nT03 test_federalnet < docker/radius.sql

# Verify tables were created
docker exec -i mysql-federalnet-dev mysql -u root -padmin\$@nT03 test_federalnet -e "SHOW TABLES;"
```

### 3. Test Backend Build

```bash
cd backend/federalnet-api
cargo build --release
```

This should compile successfully.

### 4. Test Backend Locally

```bash
cd backend/federalnet-api
# Set test environment
export DATABASE_URL="mysql://root:admin\$@nT03@localhost:3307/test_federalnet"
export JWT_SECRET="test-secret-key"

# Run the API
cargo run
```

In another terminal, test the API:

```bash
curl http://localhost:8080/api/health
# Expected: OK
```

## Production VPS Testing

### Phase 1: Pre-Deployment

Before running the deployment script on your VPS:

1. **Check VPS Requirements**:
   ```bash
   # Check OS version
   lsb_release -a
   # Should be Ubuntu 20.04+ or Debian-based
   
   # Check available RAM
   free -h
   # Should have at least 2GB
   
   # Check disk space
   df -h
   # Should have at least 20GB free
   ```

2. **Verify Network Connectivity**:
   ```bash
   # Test internet access
   ping -c 4 google.com
   
   # Check if ports are available
   netstat -tulpn | grep -E ':(80|443|3306|8080)'
   # Should show no conflicting services
   ```

3. **Verify Domain DNS** (if using a domain):
   ```bash
   # Check if domain points to VPS
   dig your-domain.com +short
   # Should return your VPS IP address
   ```

### Phase 2: Deployment

1. **Download deployment script**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh -o deploy-vps.sh
   chmod +x deploy-vps.sh
   ```

2. **Review the script** (optional but recommended):
   ```bash
   less deploy-vps.sh
   ```

3. **Run deployment**:
   ```bash
   # Basic deployment
   ./deploy-vps.sh
   
   # Or with domain for SSL
   DOMAIN=your-domain.com ./deploy-vps.sh
   ```

### Phase 3: Post-Deployment Testing

After deployment completes, run these tests:

#### 1. Health Checks

```bash
cd /opt/federalnet

# Run health check script
./deployment/scripts/health-check.sh

# Expected: All services should be healthy
```

#### 2. API Endpoint Testing

```bash
# Test health endpoint
curl http://localhost/api/health
# Expected: OK

# Test with external access (replace with your server IP or domain)
curl http://your-server-ip/api/health
# or
curl https://your-domain.com/api/health
```

#### 3. Database Connectivity

```bash
# Access MySQL
docker exec -it federalnet-mysql mysql -u root -p

# Inside MySQL, verify databases
SHOW DATABASES;
USE federalnetwuntho;
SHOW TABLES;
```

#### 4. Container Status

```bash
cd /opt/federalnet
docker compose -f docker-compose.prod.yml ps

# All containers should be "Up" and "healthy"
```

#### 5. Log Inspection

```bash
# Check API logs
docker compose -f docker-compose.prod.yml logs api --tail 50

# Check MySQL logs
docker compose -f docker-compose.prod.yml logs mysql --tail 50

# Check Nginx logs
docker compose -f docker-compose.prod.yml logs nginx --tail 50

# No critical errors should appear
```

#### 6. SSL/TLS Testing

If using a domain with SSL:

```bash
# Test HTTPS endpoint
curl https://your-domain.com/api/health

# Check certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com < /dev/null | openssl x509 -noout -dates
```

#### 7. Performance Testing

```bash
# Install Apache Bench (if not present)
apt-get install -y apache2-utils

# Test API performance
ab -n 100 -c 10 http://localhost/api/health

# Review results - should handle requests without errors
```

### Phase 4: Functional Testing

#### 1. Test Admin Login

```bash
# First, you may need to seed test data or manually create an admin user
# Check with your database for existing admin users

# Test login endpoint
curl -X POST http://localhost/api/admin/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"testadmin","password":"testpass"}'

# Should return a token if credentials are valid
```

#### 2. Test Customer Registration

```bash
curl -X POST http://localhost/api/customer/register \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "testcustomer",
    "password": "testpass123",
    "phone": "09123456789",
    "address": "Test Address"
  }'
```

### Phase 5: Backup Testing

Test the backup functionality:

```bash
# Run manual backup
/opt/federalnet/deployment/scripts/backup-database.sh

# Verify backup was created
ls -lh /var/backups/federalnet/

# Test restore (on a test database)
# WARNING: This will overwrite the database!
# /opt/federalnet/deployment/scripts/restore-database.sh /var/backups/federalnet/db_backup_TIMESTAMP.sql.gz
```

### Phase 6: Monitoring Setup

#### 1. Check Automated Backups

```bash
# Verify cron job exists
crontab -l | grep federalnet-backup

# Expected: 0 2 * * * /usr/local/bin/federalnet-backup.sh
```

#### 2. Set Up External Monitoring (Optional)

Configure external monitoring services to check:
- HTTPS endpoint availability
- SSL certificate expiration
- Disk space usage
- Service uptime

## Common Issues and Solutions

### Issue: Containers Won't Start

```bash
# Check Docker service
systemctl status docker

# Check logs
docker compose -f docker-compose.prod.yml logs

# Try rebuilding
docker compose -f docker-compose.prod.yml up -d --build --force-recreate
```

### Issue: Database Connection Failed

```bash
# Verify MySQL is running
docker exec federalnet-mysql mysqladmin ping -h localhost -u root -p

# Check DATABASE_URL in .env.production
cat /opt/federalnet/.env.production | grep DATABASE_URL

# Restart API container
docker compose -f docker-compose.prod.yml restart api
```

### Issue: SSL Certificate Not Working

```bash
# Check certificate files
ls -l /opt/federalnet/deployment/nginx/ssl/

# For Let's Encrypt, try obtaining certificate again
certbot --nginx -d your-domain.com

# Check Nginx configuration
docker exec federalnet-nginx nginx -t

# Reload Nginx
docker compose -f docker-compose.prod.yml restart nginx
```

### Issue: Port Already in Use

```bash
# Find what's using the port
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Stop the conflicting service
systemctl stop apache2  # or other service

# Restart deployment
docker compose -f docker-compose.prod.yml up -d
```

## Performance Benchmarks

Expected performance on a 2GB VPS:

- **Health endpoint**: < 10ms response time
- **Login endpoint**: < 100ms response time
- **Database queries**: < 50ms for simple queries
- **Concurrent users**: 50-100 simultaneous connections

## Security Checks

After deployment, verify security:

```bash
# Check firewall status
ufw status

# Verify only necessary ports are open
netstat -tulpn

# Check for security updates
apt-get update
apt-get upgrade -y

# Verify no seed endpoints in production
grep ENABLE_SEED_ENDPOINTS /opt/federalnet/.env.production
# Should be 0 or not set
```

## Production Checklist

Before considering deployment complete:

- [ ] All services are running and healthy
- [ ] API health endpoint returns 200 OK
- [ ] Database connectivity confirmed
- [ ] SSL/TLS certificate is valid (if using domain)
- [ ] Backups are configured and tested
- [ ] Firewall is enabled and configured
- [ ] Logs are accessible and show no errors
- [ ] Environment variables are set correctly
- [ ] ENABLE_SEED_ENDPOINTS is disabled (0)
- [ ] Strong passwords are set
- [ ] External monitoring is configured (optional)
- [ ] Documentation is reviewed

## Rollback Procedure

If deployment fails:

```bash
# Stop all services
docker compose -f docker-compose.prod.yml down

# Remove containers and volumes (WARNING: This deletes data!)
docker compose -f docker-compose.prod.yml down -v

# Restore from backup if needed
# See deployment/scripts/restore-database.sh
```

## Next Steps

After successful testing:

1. Configure regular security updates
2. Set up monitoring and alerting
3. Plan for scaling (if needed)
4. Document any custom configurations
5. Train team on operations and maintenance

## Support

If you encounter issues not covered here:

- Check [VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md) for detailed guides
- Review [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for common commands
- Check GitHub Issues: https://github.com/santoeaungdev/federalnet/issues
