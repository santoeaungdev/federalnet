-- SQL to create database and user for FederalNet on VPS
-- Run as MySQL root or a user with CREATE/GRANT privileges:

CREATE DATABASE IF NOT EXISTS `wunthofederalnet` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Replace password below if you prefer a different secret
CREATE USER IF NOT EXISTS 'wunthoadmin'@'localhost' IDENTIFIED BY 'admin$@nT03';
GRANT ALL PRIVILEGES ON `wunthofederalnet`.* TO 'wunthoadmin'@'localhost';
FLUSH PRIVILEGES;

-- If your app connects from another host, create user for that host too (example: 127.0.0.1 / %)
-- CREATE USER IF NOT EXISTS 'wunthoadmin'@'%' IDENTIFIED BY 'admin$@nT03';
-- GRANT ALL PRIVILEGES ON `wunthofederalnet`.* TO 'wunthoadmin'@'%';
-- FLUSH PRIVILEGES;
