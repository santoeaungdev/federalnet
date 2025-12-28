# GitHub Actions Workflows

This directory contains the CI/CD workflows for the FederalNet project.

## Workflows

### 1. Build Admin App APK (`build-admin-app-apk.yml`)
Builds the Flutter admin app as a debug APK when changes are made to the `frontend/admin_app` directory.

### 2. Deploy Backend API to VPS (`deploy-backend-to-vps.yml`)
Automatically deploys the Rust backend API to a VPS server when changes are pushed to the `development` branch.

## Required GitHub Secrets

To enable the deployment workflow, you need to configure the following secrets in your GitHub repository settings:

### VPS Connection Secrets

1. **`VPS_SSH_KEY`** (Required)
   - Description: Private SSH key for authenticating to the VPS
   - How to generate:
     ```bash
     # On your local machine
     ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/federalnet_deploy
     
     # Copy the public key to your VPS
     ssh-copy-id -i ~/.ssh/federalnet_deploy.pub user@your-vps-host
     
     # Copy the ENTIRE private key content (including BEGIN and END lines)
     cat ~/.ssh/federalnet_deploy
     ```
   - In GitHub: Paste the entire private key content

2. **`VPS_HOST`** (Required)
   - Description: Hostname or IP address of your VPS
   - Example: `example.com` or `192.168.1.100`

3. **`VPS_USER`** (Required)
   - Description: SSH username for connecting to the VPS
   - Example: `ubuntu`, `root`, or your custom user
   - Note: This user must have sudo privileges

4. **`VPS_PORT`** (Optional)
   - Description: SSH port for the VPS
   - Default: `22`
   - Example: `2222` (if you use a custom SSH port)

### Application Secrets

5. **`DATABASE_URL`** (Required)
   - Description: MySQL connection string for the backend API
   - Format: `mysql://username:password@host:port/database`
   - Example: `mysql://wunthoadmin:admin%24%401nT03@127.0.0.1:3306/wunthofederalnet`
   - **Important**: URL-encode special characters in the password:
     - `$` → `%24`
     - `@` → `%40`
     - `!` → `%21`
     - `#` → `%23`

6. **`JWT_SECRET`** (Required)
   - Description: Secret key for signing JWT tokens
   - How to generate:
     ```bash
     openssl rand -base64 32
     ```
   - Example: `your_random_64_character_secret_string_here`
   - **Important**: Use a strong, random secret and keep it secure

7. **`ENABLE_SEED_ENDPOINTS`** (Optional)
   - Description: Enable seed/test data endpoints
   - Values: `true`, `false`, `1`, `0`
   - Default: `false`
   - **Important**: Set to `false` or omit in production!

## Setting Up Secrets in GitHub

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name listed above
5. Paste the corresponding value
6. Click **Add secret**

## VPS Setup Requirements

Before the deployment workflow can succeed, ensure your VPS has:

1. **SSH Access**: The VPS user specified in `VPS_USER` can connect via SSH
2. **Sudo Privileges**: The user has sudo access without password prompt for the deployment commands
3. **MySQL Database**: The database specified in `DATABASE_URL` exists and is accessible
4. **Network Access**: Port 8080 is available for the API service (or configure your preferred port)

### Recommended VPS Setup

```bash
# On your VPS (as root or sudo user)

# 1. Create deployment user with sudo privileges
sudo adduser deployer
sudo usermod -aG sudo deployer

# 2. Configure sudo without password for specific commands (optional but recommended)
sudo visudo
# Add this line:
# deployer ALL=(ALL) NOPASSWD: /bin/systemctl, /usr/bin/tee, /bin/mv, /bin/chmod, /usr/sbin/useradd, /bin/mkdir, /bin/chown

# 3. Set up SSH key authentication
su - deployer
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Add the public key from VPS_SSH_KEY to ~/.ssh/authorized_keys
echo "your-public-key-here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 4. Create necessary directories
sudo mkdir -p /opt/federalnet/bin
sudo mkdir -p /etc/default

# 5. Install MySQL client (if not already installed)
sudo apt-get update
sudo apt-get install -y mysql-client curl
```

## Deployment Process

The deployment workflow performs the following steps:

1. **Checkout**: Fetches the code from the `development` branch
2. **Setup Rust**: Installs and configures the Rust toolchain
3. **Build**: Compiles the backend in release mode with optimizations
4. **Test**: Runs the test suite (continues on error)
5. **Deploy**: 
   - Transfers the compiled binary to the VPS via SCP
   - Updates the environment configuration file
   - Sets up the systemd service
   - Restarts the `federalnet-api` service
6. **Verify**: Tests the health endpoint to confirm successful deployment
7. **Logs**: Displays deployment logs for troubleshooting

## Triggering the Deployment

The deployment workflow runs automatically when:
- Code is pushed to the `development` branch
- Changes are made to files in `backend/federalnet-api/`
- Changes are made to the workflow file itself

You can also trigger it manually:
1. Go to **Actions** tab in GitHub
2. Select **Deploy Backend API to VPS**
3. Click **Run workflow**
4. Choose the `development` branch
5. Click **Run workflow**

## Monitoring Deployments

### GitHub Actions UI
- View real-time logs in the **Actions** tab
- Each step shows detailed output with collapsible groups
- Failed deployments show error messages and service logs

### VPS Monitoring
```bash
# Check service status
sudo systemctl status federalnet-api

# View recent logs
sudo journalctl -u federalnet-api -f

# Test the API
curl http://127.0.0.1:8080/api/health
```

## Troubleshooting

### Deployment Fails at SSH Connection
- Verify `VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`, and `VPS_PORT` are correct
- Ensure the SSH key has been added to the VPS user's `~/.ssh/authorized_keys`
- Check that the VPS firewall allows SSH connections

### Service Fails to Start
- Check the logs in the GitHub Actions output
- Verify `DATABASE_URL` and `JWT_SECRET` are correctly set
- Ensure the database is running and accessible from the VPS
- Check VPS logs: `sudo journalctl -u federalnet-api -n 100`

### Health Endpoint Not Responding
- Verify the service is running: `sudo systemctl status federalnet-api`
- Check if port 8080 is in use by another process
- Review environment variables: `sudo cat /etc/default/federalnet-api`
- Check database connectivity from the VPS

### Build Failures
- Review the Rust compilation errors in the Actions log
- Ensure `Cargo.toml` dependencies are compatible
- Check for syntax errors introduced in recent commits

## Security Best Practices

1. **Rotate Secrets Regularly**: Change `JWT_SECRET` and SSH keys periodically
2. **Use Strong Passwords**: Ensure database passwords are strong and complex
3. **Limit SSH Access**: Use SSH keys only, disable password authentication
4. **Firewall Configuration**: Only expose necessary ports (SSH, API)
5. **Monitor Logs**: Regularly review deployment and application logs
6. **Principle of Least Privilege**: VPS user should only have necessary permissions
7. **Disable Seed Endpoints**: Never enable `ENABLE_SEED_ENDPOINTS` in production

## Support

For issues or questions about the deployment workflow:
- Check the [deployment logs](#monitoring-deployments) in GitHub Actions
- Review the [troubleshooting section](#troubleshooting)
- Open an issue in the repository with relevant logs
