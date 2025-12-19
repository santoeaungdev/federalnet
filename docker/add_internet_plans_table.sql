-- Add tbl_internet_plans table for phpNuxBill-style plan management
-- This table stores internet plans that can be assigned to customers via RADIUS groups

USE `wunthofederalnet`;

CREATE TABLE IF NOT EXISTS `tbl_internet_plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL DEFAULT 'Personal' COMMENT 'Personal or Business',
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency` varchar(10) NOT NULL DEFAULT 'MMK',
  `validity_unit` enum('minutes','hours','days','months') NOT NULL DEFAULT 'months',
  `validity_value` int(11) NOT NULL DEFAULT 1,
  `download_mbps` int(11) NOT NULL DEFAULT 10 COMMENT 'Download speed in Mbps',
  `upload_mbps` int(11) NOT NULL DEFAULT 10 COMMENT 'Upload speed in Mbps',
  `radius_groupname` varchar(64) NOT NULL COMMENT 'RADIUS group to assign via radusergroup',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `status_idx` (`status`),
  KEY `radius_groupname_idx` (`radius_groupname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Internet plans for PPPoE customers with RADIUS group mapping';
