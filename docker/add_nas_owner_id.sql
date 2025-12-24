-- Migration: add nullable owner_id to nas table
-- One owner per gateway (nullable means gateway can be unassigned)
ALTER TABLE `nas`
  ADD COLUMN `owner_id` INT(10) UNSIGNED NULL AFTER `id`,
  ADD INDEX `idx_nas_owner_id` (`owner_id`);

-- Optional foreign key (uncomment if `tbl_users` exists and you want enforced constraint)
-- ALTER TABLE `nas`
--   ADD CONSTRAINT `fk_nas_owner` FOREIGN KEY (`owner_id`) REFERENCES `tbl_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
