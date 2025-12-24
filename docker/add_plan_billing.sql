-- Migration: add billing_mode and price_per_unit to tbl_internet_plans
ALTER TABLE `tbl_internet_plans`
  ADD COLUMN `billing_mode` VARCHAR(16) DEFAULT 'data' COMMENT 'data|time',
  ADD COLUMN `price_per_unit` DECIMAL(13,4) NULL COMMENT 'price per MB for data or price per minute for time',
  ADD COLUMN `billing_unit` VARCHAR(8) DEFAULT 'MB' COMMENT 'MB or min';
