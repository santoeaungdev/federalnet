#!/bin/bash

# vps_deploy_backend.sh
# Improved deployment script for backend on VPS

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
APP_NAME="backend_app"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOGFILE="/var/log/${APP_NAME}_deploy.log"

# Functions
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a $LOGFILE
}

# Update and install dependencies
log_message "Updating package lists..."
sudo apt-get update && sudo apt-get upgrade -y || log_message "Failed to update and upgrade packages"

log_message "Installing dependencies..."
sudo apt-get install -y git curl || log_message "Failed to install dependencies"

# Fetch the latest code
log_message "Changing directory to app source..."
cd /var/www/$APP_NAME || log_message "Directory /var/www/$APP_NAME does not exist"

git fetch origin main || log_message "Failed to fetch latest changes"
git reset --hard origin/main || log_message "Failed to reset to latest commit"

# Install application dependencies
log_message "Installing application dependencies..."
if [ -f package.json ]; then
    npm install || log_message "Failed to install npm dependencies"
fi

# Restart application service
log_message "Restarting application service..."
sudo systemctl restart ${APP_NAME}.service || log_message "Failed to restart application service"

log_message "Deployment completed successfully!"