-- Migration: owner income records
-- Records computed owner income per month per customer/nas
CREATE TABLE IF NOT EXISTS `owner_income` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,
  `customer_id` INT(10) UNSIGNED NULL,
  `nas_id` INT(10) UNSIGNED NULL,
  `period` VARCHAR(7) NOT NULL, -- YYYY-MM
  `usage_bytes` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `revenue` DECIMAL(13,2) NOT NULL DEFAULT 0.00,
  `tax` DECIMAL(13,2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner_period` (`owner_id`, `period`),
  KEY `idx_period` (`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
