-- FederalNet consolidated schema & migrations (selected finished changes)
-- Generated: 2025-12-24
-- This file combines the schema changes added during development
-- Apply on top of existing `wunthofederalnet` schema as needed.

-- ============ owner_wallets and transactions ============
-- Migration: owner wallets and owner wallet transactions
CREATE TABLE IF NOT EXISTS `owner_wallets` (
  `owner_id` INT(10) UNSIGNED NOT NULL,
  `balance` DECIMAL(13,2) NOT NULL DEFAULT 0.00,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `owner_wallet_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,
  `customer_id` INT(10) UNSIGNED NOT NULL,
  `amount` DECIMAL(13,2) NOT NULL,
  `note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- idempotency for owner wallet transactions
SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

ALTER TABLE owner_wallet_transactions
    ADD COLUMN idempotency_key VARCHAR(128) NULL;

CREATE INDEX idx_owner_idempotency ON owner_wallet_transactions (owner_id, idempotency_key);

COMMIT;

-- ============ owner income table ============
-- Migration: owner income records
CREATE TABLE IF NOT EXISTS `owner_income` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,
  `customer_id` INT(10) UNSIGNED NULL,
  `nas_id` INT(10) UNSIGNED NULL,
  `period` VARCHAR(7) NOT NULL,
  `usage_bytes` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `revenue` DECIMAL(13,2) NOT NULL DEFAULT 0.00,
  `tax` DECIMAL(13,2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner_period` (`owner_id`, `period`),
  KEY `idx_period` (`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ plan billing enhancements ============
-- Migration: add billing_mode and price_per_unit to tbl_internet_plans
ALTER TABLE `tbl_internet_plans`
  ADD COLUMN `billing_mode` VARCHAR(16) DEFAULT 'data' COMMENT 'data|time',
  ADD COLUMN `price_per_unit` DECIMAL(13,4) NULL COMMENT 'price per MB for data or price per minute for time',
  ADD COLUMN `billing_unit` VARCHAR(8) DEFAULT 'MB' COMMENT 'MB or min';

-- ============ user types ============
-- Extend tbl_users.user_type enum to include Owner and Operator
SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

ALTER TABLE tbl_users
    MODIFY COLUMN user_type ENUM('SuperAdmin','Admin','Report','Owner','Operator') NOT NULL;

COMMIT;

-- ============ owner_gateways mapping ============
CREATE TABLE IF NOT EXISTS `owner_gateways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,
  `nas_id` INT(10) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_owner_nas` (`owner_id`, `nas_id`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_nas_id` (`nas_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ nas owner column ============
ALTER TABLE `nas`
  ADD COLUMN `owner_id` INT(10) UNSIGNED NULL AFTER `id`,
  ADD INDEX `idx_nas_owner_id` (`owner_id`);

-- Notes:
--  - This file contains schema changes added during development branch up to 2025-12-24.
--  - Before applying in production: backup DB, review existing `wunthofederalnet` dump in docker/wunthofederalnet.sql,
--    and run migrations in a transactional manner appropriate for your MySQL version.
--  - Some optional FK constraints are commented in the migration files in the repository; enable them if desired.
