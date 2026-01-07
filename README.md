# FederalNet

Myanmar FederalNet ISP billing system - A comprehensive billing and customer management system for Internet Service Providers.

## Features

- **Customer Management**: Register and manage customer accounts
- **Admin Portal**: Full administrative control panel
- **RADIUS Integration**: FreeRADIUS integration for authentication
- **Internet Plans**: Flexible plan management and assignment
- **Multi-Platform**: Backend API + Flutter mobile apps (Admin, Customer, Owner)

## Architecture

- **Backend**: Rust-based API using Actix-web framework
- **Database**: MySQL 8 with RADIUS tables
- **Frontend**: Flutter applications for multiple platforms
- **Deployment**: Docker-based deployment with Nginx reverse proxy

## Quick Start - VPS Deployment

Deploy the entire stack to a VPS with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/deployment/deploy-vps.sh | bash
```

For detailed deployment instructions, see [VPS Deployment Guide](deployment/VPS_DEPLOYMENT.md).

## Development Setup

### Prerequisites

- Rust 1.75 or later
- MySQL 8
- Docker and Docker Compose (for containerized setup)
- Flutter 3.x (for mobile apps)

### Backend Setup

```bash
cd backend/federalnet-api

# Install dependencies (Rust will handle this via Cargo)
cargo build

# Set up environment
cp .env .env.local
# Edit .env.local with your database credentials

# Run the API
cargo run
```

### Database Setup

```bash
# Start MySQL with Docker
docker compose -f docker/docker-compose.dev.yml up -d

# Import schema
mysql -h 127.0.0.1 -P 3307 -u root -p < docker/federalnet_schema.sql
mysql -h 127.0.0.1 -P 3307 -u root -p < docker/radius.sql
```

### Frontend Setup

```bash
cd frontend/admin_app  # or customer_app, owner_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Production Deployment

### VPS Deployment (Recommended)

See the comprehensive [VPS Deployment Guide](deployment/VPS_DEPLOYMENT.md) for:
- Automated deployment script
- Docker Compose setup
- SSL/TLS configuration
- Database management
- Backup and restore procedures
- Monitoring and health checks

Quick reference: [Deployment Quick Reference](deployment/QUICK_REFERENCE.md)

### Manual Deployment

For manual deployment using systemd services, see the [VPS Deployment Guide](deployment/VPS_DEPLOYMENT.md#method-3-manual-deployment).

## Project Structure

```
federalnet/
├── backend/
│   └── federalnet-api/       # Rust API server
│       ├── src/
│       ├── Cargo.toml
│       └── Dockerfile
├── frontend/
│   ├── admin_app/            # Flutter admin application
│   ├── customer_app/         # Flutter customer application
│   └── owner_app/            # Flutter owner application
├── docker/                   # Database schemas and Docker configs
│   ├── federalnet_schema.sql
│   ├── radius.sql
│   └── docker-compose.dev.yml
├── deployment/               # Production deployment files
│   ├── deploy-vps.sh        # Automated deployment script
│   ├── VPS_DEPLOYMENT.md    # Deployment documentation
│   ├── QUICK_REFERENCE.md   # Quick command reference
│   ├── nginx/               # Nginx configurations
│   ├── systemd/             # Systemd service files
│   └── scripts/             # Utility scripts
├── scripts/                  # Development scripts
└── docker-compose.prod.yml  # Production Docker Compose
```

## API Endpoints

- `GET /api/health` - Health check
- `POST /api/admin/login` - Admin login
- `POST /api/customer/login` - Customer login
- `POST /api/customer/register` - Customer registration
- `GET /api/admin/customers` - List customers (admin)
- `POST /api/admin/assign_plan` - Assign internet plan (admin)
- `GET /api/admin/internet_plans` - List internet plans (admin)
- `GET /api/admin/nas` - List RADIUS NAS devices (admin)

See API documentation for complete endpoint list.

## Configuration

### Environment Variables

```bash
DATABASE_URL=mysql://user:password@host:port/database
JWT_SECRET=your-secret-key
RUST_LOG=info
ENABLE_SEED_ENDPOINTS=0  # Set to 0 in production
```

## Scripts

### Deployment
- `deployment/deploy-vps.sh` - Automated VPS deployment
- `deployment/scripts/backup-database.sh` - Database backup
- `deployment/scripts/restore-database.sh` - Database restore
- `deployment/scripts/health-check.sh` - Service health check

### Legacy Scripts
- `scripts/deploy-federalnet-api.sh` - Manual API deployment
- `scripts/vps_deploy_backend.sh` - Backend deployment helper
- `scripts/import_schema_to_vps.sh` - Schema import utility

## Security

- JWT-based authentication
- bcrypt password hashing
- RADIUS integration for network authentication
- SQL injection protection via SQLx
- HTTPS/TLS encryption (in production)
- Firewall configuration
- Regular security updates

## License

This project is proprietary software for FederalNet ISP.

## Support

For issues or questions:
- GitHub Issues: https://github.com/santoeaungdev/federalnet/issues
- Documentation: See `/deployment` directory for deployment guides
