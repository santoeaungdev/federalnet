# FederalNet Deployment

This directory contains all files and documentation needed to deploy FederalNet on a VPS.

## Quick Deploy

```bash
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | bash
```

## Contents

### Documentation
- **[VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md)** - Complete deployment guide with all methods
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick command reference

### Scripts
- **[deploy-vps.sh](deploy-vps.sh)** - Automated deployment script
- **[scripts/backup-database.sh](scripts/backup-database.sh)** - Database backup utility
- **[scripts/restore-database.sh](scripts/restore-database.sh)** - Database restore utility
- **[scripts/health-check.sh](scripts/health-check.sh)** - System health monitoring

### Configuration Files
- **[nginx/](nginx/)** - Nginx web server configurations
  - `nginx.conf` - Main Nginx configuration
  - `conf.d/federalnet.conf` - FederalNet site configuration
- **[systemd/](systemd/)** - Systemd service files
  - `federalnet-api.service` - API service configuration

## Deployment Methods

### Method 1: Automated (Recommended)
Use the automated script for a complete setup:
```bash
./deploy-vps.sh
```

### Method 2: Docker Compose
For more control over the deployment:
```bash
cd /opt/federalnet
docker compose -f docker-compose.prod.yml up -d
```

### Method 3: Manual
For native installation without Docker - see VPS_DEPLOYMENT.md

## Requirements

- Ubuntu 20.04+ or Debian-based Linux
- 2GB+ RAM
- 20GB+ storage
- Public IP with ports 80, 443 accessible
- (Optional) Domain name for SSL

## Support

Refer to:
- [VPS_DEPLOYMENT.md](VPS_DEPLOYMENT.md) for detailed instructions
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for common commands
- Main project [README](../README.md) for project overview
