#!/bin/bash

# This deploy script is used to restart the backend service after deployment

APP_NAME="federalnet-api"
SERVICE_FILE="/etc/systemd/system/federalnet-api.service"

# Navigate to app directory
cd /var/www/$APP_NAME

echo "Pulling the latest changes"
git pull origin master

echo "Installing dependencies"
npm install

echo "Building the app"
npm run build

echo "Restarting the service"
sudo systemctl restart $SERVICE_FILE

echo "$APP_NAME deployment is complete"