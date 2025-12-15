-- Create a limited FreeRADIUS DB user and grant minimal privileges
-- Customize the username and password before running on VPS

CREATE DATABASE IF NOT EXISTS radius;

-- Replace 'radiususer' and 'STRONG_PASSWORD' with secure values
CREATE USER IF NOT EXISTS 'radiususer'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE ON radius.* TO 'radiususer'@'localhost';
FLUSH PRIVILEGES;
