-- Migration: create owner_gateways mapping table
-- Links owners (tbl_users.id) to NAS entries (nas.id)
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

-- Optional foreign keys (uncomment if `tbl_users` and `nas` exist and you want enforced FKs)
-- ALTER TABLE `owner_gateways`
--   ADD CONSTRAINT `fk_owner_gateways_owner`
--     FOREIGN KEY (`owner_id`) REFERENCES `tbl_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
--   ADD CONSTRAINT `fk_owner_gateways_nas`
--     FOREIGN KEY (`nas_id`) REFERENCES `nas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
