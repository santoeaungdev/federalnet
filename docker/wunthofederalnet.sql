-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Dec 06, 2025 at 04:21 AM
-- Server version: 10.11.13-MariaDB-0ubuntu0.24.04.1
-- PHP Version: 8.2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `wunthofederalnet`
--

-- --------------------------------------------------------

--
-- Table structure for table `nas`
--

CREATE TABLE `nas` (
  `id` int(10) NOT NULL,
  `nasname` varchar(128) NOT NULL,
  `shortname` varchar(32) DEFAULT NULL,
  `type` varchar(30) DEFAULT 'other',
  `ports` int(5) DEFAULT NULL,
  `secret` varchar(60) NOT NULL DEFAULT 'secret',
  `server` varchar(64) DEFAULT NULL,
  `community` varchar(50) DEFAULT NULL,
  `description` varchar(200) DEFAULT 'RADIUS Client',
  `routers` varchar(32) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nas`
--

INSERT INTO `nas` (`id`, `nasname`, `shortname`, `type`, `ports`, `secret`, `server`, `community`, `description`, `routers`) VALUES
(1, '192.168.0.1', 'STARNET1', 'other', 1812, 'verysecret', NULL, NULL, 'RADIUS Client', 'STARNET1');

-- --------------------------------------------------------

--
-- Table structure for table `nasreload`
--

CREATE TABLE `nasreload` (
  `nasipaddress` varchar(15) NOT NULL,
  `reloadtime` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radacct`
--

CREATE TABLE `radacct` (
  `radacctid` bigint(21) NOT NULL,
  `acctsessionid` varchar(64) NOT NULL DEFAULT '',
  `acctuniqueid` varchar(32) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `realm` varchar(64) DEFAULT '',
  `nasipaddress` varchar(15) NOT NULL DEFAULT '',
  `nasportid` varchar(32) DEFAULT NULL,
  `nasporttype` varchar(32) DEFAULT NULL,
  `acctstarttime` datetime DEFAULT NULL,
  `acctupdatetime` datetime DEFAULT NULL,
  `acctstoptime` datetime DEFAULT NULL,
  `acctinterval` int(12) DEFAULT NULL,
  `acctsessiontime` int(12) UNSIGNED DEFAULT NULL,
  `acctauthentic` varchar(32) DEFAULT NULL,
  `connectinfo_start` varchar(128) DEFAULT NULL,
  `connectinfo_stop` varchar(128) DEFAULT NULL,
  `acctinputoctets` bigint(20) DEFAULT NULL,
  `acctoutputoctets` bigint(20) DEFAULT NULL,
  `calledstationid` varchar(50) NOT NULL DEFAULT '',
  `callingstationid` varchar(50) NOT NULL DEFAULT '',
  `acctterminatecause` varchar(32) NOT NULL DEFAULT '',
  `servicetype` varchar(32) DEFAULT NULL,
  `framedprotocol` varchar(32) DEFAULT NULL,
  `framedipaddress` varchar(15) NOT NULL DEFAULT '',
  `framedipv6address` varchar(45) NOT NULL DEFAULT '',
  `framedipv6prefix` varchar(45) NOT NULL DEFAULT '',
  `framedinterfaceid` varchar(44) NOT NULL DEFAULT '',
  `delegatedipv6prefix` varchar(45) NOT NULL DEFAULT '',
  `class` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radcheck`
--

CREATE TABLE `radcheck` (
  `id` int(11) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radgroupcheck`
--

CREATE TABLE `radgroupcheck` (
  `id` int(11) UNSIGNED NOT NULL,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radgroupreply`
--

CREATE TABLE `radgroupreply` (
  `id` int(11) UNSIGNED NOT NULL,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT '',
  `plan_id` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radpostauth`
--

CREATE TABLE `radpostauth` (
  `id` int(11) NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `pass` varchar(64) NOT NULL DEFAULT '',
  `reply` varchar(32) NOT NULL DEFAULT '',
  `authdate` timestamp(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  `class` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radreply`
--

CREATE TABLE `radreply` (
  `id` int(11) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `radusergroup`
--

CREATE TABLE `radusergroup` (
  `id` int(11) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `priority` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rad_acct`
--

CREATE TABLE `rad_acct` (
  `id` bigint(20) NOT NULL,
  `acctsessionid` varchar(64) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `realm` varchar(128) NOT NULL DEFAULT '',
  `nasid` varchar(32) NOT NULL DEFAULT '',
  `nasipaddress` varchar(15) NOT NULL DEFAULT '',
  `nasportid` varchar(32) DEFAULT NULL,
  `nasporttype` varchar(32) DEFAULT NULL,
  `framedipaddress` varchar(15) NOT NULL DEFAULT '',
  `acctsessiontime` bigint(20) NOT NULL DEFAULT 0,
  `acctinputoctets` bigint(20) NOT NULL DEFAULT 0,
  `acctoutputoctets` bigint(20) NOT NULL DEFAULT 0,
  `acctstatustype` varchar(32) DEFAULT NULL,
  `macaddr` varchar(50) NOT NULL,
  `dateAdded` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_appconfig`
--

CREATE TABLE `tbl_appconfig` (
  `id` int(11) NOT NULL,
  `setting` mediumtext NOT NULL,
  `value` mediumtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_appconfig`
--

INSERT INTO `tbl_appconfig` (`id`, `setting`, `value`) VALUES
(1, 'CompanyName', 'Myanmar Federal-Net'),
(2, 'currency_code', 'MMK'),
(3, 'language', 'english'),
(4, 'show-logo', '1'),
(5, 'nstyle', 'blue'),
(6, 'timezone', 'Asia/Yangon'),
(7, 'dec_point', '.'),
(8, 'thousands_sep', ','),
(9, 'rtl', '0'),
(10, 'address', ''),
(11, 'phone', ''),
(12, 'date_format', 'd M Y'),
(13, 'note', 'Thank you...'),
(14, 'api_key', '2125bc004ac7547d71e54540184176e71fa16c28'),
(15, 'country_code_phone', ''),
(16, 'radius_plan', 'Radius Plan'),
(17, 'hotspot_plan', 'Hotspot Plan'),
(18, 'pppoe_plan', 'PPPOE Plan'),
(19, 'vpn_plan', 'VPN Plan'),
(20, 'csrf_token', 'd764e5932101fbde43ec65d3d5b252b4'),
(21, 'CompanyFooter', ''),
(22, 'printer_cols', '60'),
(23, 'theme', 'default'),
(24, 'payment_usings', ''),
(25, 'reset_day', '1'),
(26, 'dashboard_cr', ''),
(27, 'url_canonical', 'no'),
(28, 'general', ''),
(29, 'login_page_type', 'default'),
(30, 'login_Page_template', 'moon'),
(31, 'login_page_head', ''),
(32, 'login_page_description', ''),
(33, 'disable_registration', 'no'),
(34, 'registration_username', 'username'),
(35, 'photo_register', 'no'),
(36, 'sms_otp_registration', 'no'),
(37, 'phone_otp_type', 'sms'),
(38, 'reg_nofify_admin', 'yes'),
(39, 'man_fields_email', 'no'),
(40, 'man_fields_fname', 'yes'),
(41, 'man_fields_address', 'yes'),
(42, 'session_timeout_duration', ''),
(43, 'single_session', 'no'),
(44, 'csrf_enabled', 'no'),
(45, 'disable_voucher', 'no'),
(46, 'voucher_format', 'up'),
(47, 'voucher_redirect', ''),
(48, 'radius_enable', '1'),
(49, 'extend_expired', '0'),
(50, 'extend_days', ''),
(51, 'extend_confirmation', ''),
(52, 'enable_balance', 'yes'),
(53, 'allow_balance_transfer', 'yes'),
(54, 'minimum_transfer', ''),
(55, 'allow_balance_custom', 'yes'),
(56, 'telegram_bot', ''),
(57, 'telegram_target_id', ''),
(58, 'sms_url', ''),
(59, 'mikrotik_sms_command', '/tool sms send'),
(60, 'wa_url', ''),
(61, 'smtp_host', ''),
(62, 'smtp_port', ''),
(63, 'smtp_user', ''),
(64, 'smtp_pass', ''),
(65, 'smtp_ssltls', ''),
(66, 'mail_from', ''),
(67, 'mail_reply_to', ''),
(68, 'user_notification_expired', 'email'),
(69, 'user_notification_payment', 'email'),
(70, 'user_notification_reminder', 'sms'),
(71, 'notification_reminder_1day', 'yes'),
(72, 'notification_reminder_3days', 'yes'),
(73, 'notification_reminder_7days', 'yes'),
(74, 'tawkto', ''),
(75, 'tawkto_api_key', ''),
(76, 'http_proxy', ''),
(77, 'http_proxyauth', ''),
(78, 'enable_tax', 'no'),
(79, 'tax_rate', '0.5'),
(80, 'custom_tax_rate', ''),
(81, 'github_username', ''),
(82, 'github_token', ''),
(83, 'man_fields_custom', 'no'),
(84, 'enable_session_timeout', '0'),
(85, 'hide_mrc', 'no'),
(86, 'hide_tms', 'no'),
(87, 'hide_al', 'no'),
(88, 'hide_uet', 'no'),
(89, 'hide_vs', 'no'),
(90, 'hide_pg', 'no'),
(91, 'hide_aui', 'no'),
(92, 'new_version_notify', 'enable'),
(93, 'router_check', '0'),
(94, 'allow_phone_otp', 'no'),
(95, 'allow_email_otp', 'no'),
(96, 'show_bandwidth_plan', 'yes'),
(97, 'hs_auth_method', 'api'),
(98, 'frrest_interim_update', '0'),
(99, 'check_customer_online', 'yes'),
(100, 'extend_expiry', 'yes'),
(101, 'save', 'save'),
(102, 'docs_clicked', 'yes');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_bandwidth`
--

CREATE TABLE `tbl_bandwidth` (
  `id` int(10) UNSIGNED NOT NULL,
  `name_bw` varchar(255) NOT NULL,
  `rate_down` int(10) UNSIGNED NOT NULL,
  `rate_down_unit` enum('Kbps','Mbps') NOT NULL,
  `rate_up` int(10) UNSIGNED NOT NULL,
  `rate_up_unit` enum('Kbps','Mbps') NOT NULL,
  `burst` varchar(128) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_bandwidth`
--

INSERT INTO `tbl_bandwidth` (`id`, `name_bw`, `rate_down`, `rate_down_unit`, `rate_up`, `rate_up_unit`, `burst`) VALUES
(1, 'Regular Plan', 5, 'Mbps', 5, 'Mbps', '10M/10M 3840k/3840k 16/16 8 2560k/2560k');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_coupons`
--

CREATE TABLE `tbl_coupons` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `type` enum('fixed','percent') NOT NULL,
  `value` decimal(10,2) NOT NULL,
  `description` text NOT NULL,
  `max_usage` int(11) NOT NULL DEFAULT 1,
  `usage_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') NOT NULL,
  `min_order_amount` decimal(10,2) NOT NULL,
  `max_discount_amount` decimal(10,2) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_customers`
--

CREATE TABLE `tbl_customers` (
  `id` int(11) NOT NULL,
  `username` varchar(45) NOT NULL,
  `password` varchar(45) NOT NULL,
  `photo` varchar(128) NOT NULL DEFAULT '/user.default.jpg',
  `pppoe_username` varchar(32) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `pppoe_password` varchar(45) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `pppoe_ip` varchar(32) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `fullname` varchar(45) NOT NULL,
  `address` mediumtext DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `district` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `zip` varchar(10) DEFAULT NULL,
  `phonenumber` varchar(20) DEFAULT '0',
  `email` varchar(128) NOT NULL DEFAULT '1',
  `coordinates` varchar(50) NOT NULL DEFAULT '' COMMENT 'Latitude and Longitude coordinates',
  `account_type` enum('Business','Personal') DEFAULT 'Personal' COMMENT 'For selecting account type',
  `balance` decimal(15,2) NOT NULL DEFAULT 0.00 COMMENT 'For Money Deposit',
  `service_type` enum('Hotspot','PPPoE','VPN','Others') DEFAULT 'Others' COMMENT 'For selecting user type',
  `auto_renewal` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Auto renewall using balance',
  `status` enum('Active','Banned','Disabled','Inactive','Limited','Suspended') NOT NULL DEFAULT 'Active',
  `created_by` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_login` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_customers`
--

INSERT INTO `tbl_customers` (`id`, `username`, `password`, `photo`, `pppoe_username`, `pppoe_password`, `pppoe_ip`, `fullname`, `address`, `city`, `district`, `state`, `zip`, `phonenumber`, `email`, `coordinates`, `account_type`, `balance`, `service_type`, `auto_renewal`, `status`, `created_by`, `created_at`, `last_login`) VALUES
(1, 'testuser', '11115555', '/user.default.jpg', '', '', '', 'testuser', '', '', '', '', '', '', 'zawminaung@gmail.com', '', 'Personal', 2000.00, 'PPPoE', 1, 'Active', 1, '2025-12-05 04:06:11', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_customers_fields`
--

CREATE TABLE `tbl_customers_fields` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `field_name` varchar(255) NOT NULL,
  `field_value` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_customers_inbox`
--

CREATE TABLE `tbl_customers_inbox` (
  `id` int(10) UNSIGNED NOT NULL,
  `customer_id` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `date_read` datetime DEFAULT NULL,
  `subject` varchar(64) NOT NULL,
  `body` text DEFAULT NULL,
  `from` varchar(8) NOT NULL DEFAULT 'System' COMMENT 'System or Admin or Else',
  `admin_id` int(11) NOT NULL DEFAULT 0 COMMENT 'other than admin is 0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_logs`
--

CREATE TABLE `tbl_logs` (
  `id` int(11) NOT NULL,
  `date` datetime DEFAULT NULL,
  `type` varchar(50) NOT NULL,
  `description` mediumtext NOT NULL,
  `userid` int(11) NOT NULL,
  `ip` mediumtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_logs`
--

INSERT INTO `tbl_logs` (`id`, `date`, `type`, `description`, `userid`, `ip`) VALUES
(1, '2025-12-03 23:05:45', 'SuperAdmin', 'admin Login Successful', 1, '129.224.203.237'),
(2, '2025-12-03 23:07:33', 'SuperAdmin', '[admin]: Password changed successfully', 1, '129.224.203.237'),
(3, '2025-12-03 23:16:47', 'SuperAdmin', '[admin]: Created Agent <b>zawminaung</b>', 1, '129.224.203.237'),
(4, '2025-12-03 23:22:58', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(5, '2025-12-03 22:53:25', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(6, '2025-12-03 22:54:38', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(7, '2025-12-03 22:54:50', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(8, '2025-12-03 22:55:23', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(9, '2025-12-03 22:56:12', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(10, '2025-12-03 23:53:01', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.203.237'),
(11, '2025-12-04 07:42:46', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '150.228.149.174'),
(12, '2025-12-04 07:43:00', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '150.228.149.174'),
(13, '2025-12-05 09:46:43', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.202.140'),
(14, '2025-12-05 09:46:56', 'SuperAdmin', '[admin]: Settings Saved Successfully', 1, '129.224.202.140');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_message_logs`
--

CREATE TABLE `tbl_message_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `message_type` varchar(50) DEFAULT NULL,
  `recipient` varchar(255) DEFAULT NULL,
  `message_content` text DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_message_logs`
--

INSERT INTO `tbl_message_logs` (`id`, `message_type`, `recipient`, `message_content`, `status`, `error_message`, `sent_at`) VALUES
(1, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-1*\r\nDate : 05 Dec 2025 10:48\r\nDeposit Administrator\r\n\r\n\r\nType : *Balance*\r\nPackage : *Topup 5000*\r\nPrice : *MMK 5,000*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 04:18:11'),
(2, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-2*\r\nDate : 05 Dec 2025 10:50\r\nVoucher bf4F5a\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 11:50*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 04:20:02'),
(3, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-3*\r\nDate : 05 Dec 2025 14:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 15:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 08:00:01'),
(4, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-4*\r\nDate : 05 Dec 2025 18:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 19:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 12:00:01'),
(5, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-5*\r\nDate : 05 Dec 2025 22:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 23:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 16:00:01'),
(6, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-6*\r\nDate : 06 Dec 2025 02:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *06 Dec 2025 03:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-05 20:00:01'),
(7, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-7*\r\nDate : 06 Dec 2025 06:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *06 Dec 2025 07:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-06 00:00:01'),
(8, 'Email', 'zawminaung@gmail.com', '*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-8*\r\nDate : 06 Dec 2025 10:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *06 Dec 2025 11:30*\r\n\r\n====================\r\nThank you...', 'Success', NULL, '2025-12-06 04:00:01');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_meta`
--

CREATE TABLE `tbl_meta` (
  `id` int(10) UNSIGNED NOT NULL,
  `tbl` varchar(32) NOT NULL COMMENT 'Table name',
  `tbl_id` int(11) NOT NULL COMMENT 'table value id',
  `name` varchar(32) NOT NULL,
  `value` mediumtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='This Table to add additional data for any table';

-- --------------------------------------------------------

--
-- Table structure for table `tbl_odps`
--

CREATE TABLE `tbl_odps` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `port_amount` int(11) NOT NULL,
  `attenuation` decimal(15,2) NOT NULL DEFAULT 0.00,
  `address` mediumtext NOT NULL,
  `coordinates` varchar(50) NOT NULL,
  `coverage` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payment_gateway`
--

CREATE TABLE `tbl_payment_gateway` (
  `id` int(11) NOT NULL,
  `username` varchar(32) NOT NULL,
  `user_id` int(11) NOT NULL DEFAULT 0,
  `gateway` varchar(32) NOT NULL COMMENT 'xendit | midtrans',
  `gateway_trx_id` varchar(512) NOT NULL DEFAULT '',
  `plan_id` int(11) NOT NULL,
  `plan_name` varchar(40) NOT NULL,
  `routers_id` int(11) NOT NULL,
  `routers` varchar(32) NOT NULL,
  `price` varchar(40) NOT NULL,
  `pg_url_payment` varchar(512) NOT NULL DEFAULT '',
  `payment_method` varchar(32) NOT NULL DEFAULT '',
  `payment_channel` varchar(32) NOT NULL DEFAULT '',
  `pg_request` text DEFAULT NULL,
  `pg_paid_response` text DEFAULT NULL,
  `expired_date` datetime DEFAULT NULL,
  `created_date` datetime NOT NULL,
  `paid_date` datetime DEFAULT NULL,
  `trx_invoice` varchar(25) NOT NULL DEFAULT '' COMMENT 'from tbl_transactions',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 unpaid 2 paid 3 failed 4 canceled'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_plans`
--

CREATE TABLE `tbl_plans` (
  `id` int(11) NOT NULL,
  `name_plan` varchar(40) NOT NULL,
  `id_bw` int(11) NOT NULL,
  `price` varchar(40) NOT NULL,
  `price_old` varchar(40) NOT NULL DEFAULT '',
  `type` enum('Hotspot','PPPOE','VPN','Balance') NOT NULL,
  `typebp` enum('Unlimited','Limited') DEFAULT NULL,
  `limit_type` enum('Time_Limit','Data_Limit','Both_Limit') DEFAULT NULL,
  `time_limit` int(10) UNSIGNED DEFAULT NULL,
  `time_unit` enum('Mins','Hrs') DEFAULT NULL,
  `data_limit` int(10) UNSIGNED DEFAULT NULL,
  `data_unit` enum('MB','GB') DEFAULT NULL,
  `validity` int(11) NOT NULL,
  `validity_unit` enum('Mins','Hrs','Days','Months','Period') NOT NULL,
  `shared_users` int(11) DEFAULT NULL,
  `routers` varchar(32) NOT NULL,
  `is_radius` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 is radius',
  `pool` varchar(40) DEFAULT NULL,
  `plan_expired` int(11) NOT NULL DEFAULT 0,
  `expired_date` tinyint(1) NOT NULL DEFAULT 20,
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 disabled\r\n',
  `allow_purchase` enum('yes','no') DEFAULT 'yes' COMMENT 'allow to show package in buy package page',
  `prepaid` enum('yes','no') DEFAULT 'yes' COMMENT 'is prepaid',
  `plan_type` enum('Business','Personal') DEFAULT 'Personal' COMMENT 'For selecting account type',
  `device` varchar(32) NOT NULL DEFAULT '',
  `on_login` text DEFAULT NULL,
  `on_logout` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_plans`
--

INSERT INTO `tbl_plans` (`id`, `name_plan`, `id_bw`, `price`, `price_old`, `type`, `typebp`, `limit_type`, `time_limit`, `time_unit`, `data_limit`, `data_unit`, `validity`, `validity_unit`, `shared_users`, `routers`, `is_radius`, `pool`, `plan_expired`, `expired_date`, `enabled`, `allow_purchase`, `prepaid`, `plan_type`, `device`, `on_login`, `on_logout`) VALUES
(1, 'Regular (1Hr)', 1, '500', '', 'PPPOE', NULL, NULL, NULL, NULL, NULL, NULL, 1, 'Hrs', NULL, '', 1, 'starnet1', 0, 0, 1, 'yes', 'yes', 'Personal', 'RadiusRest', '', ''),
(2, 'Regular (4Hr)', 1, '2000', '', 'PPPOE', NULL, NULL, NULL, NULL, NULL, NULL, 4, 'Hrs', NULL, '', 1, 'starnet1', 0, 0, 1, 'yes', 'yes', 'Personal', 'RadiusRest', NULL, NULL),
(3, 'Topup 5000', 0, '5000', '', 'Balance', NULL, NULL, NULL, NULL, NULL, NULL, 0, 'Months', NULL, '', 0, '', 0, 20, 1, 'yes', 'yes', 'Personal', '', NULL, NULL),
(4, 'Topup 1000', 0, '1000', '', 'Balance', NULL, NULL, NULL, NULL, NULL, NULL, 0, 'Months', NULL, '', 0, '', 0, 20, 1, 'yes', 'yes', 'Personal', '', NULL, NULL),
(5, 'Topup 10000', 0, '10000', '', 'Balance', NULL, NULL, NULL, NULL, NULL, NULL, 0, 'Months', NULL, '', 0, '', 0, 20, 1, 'yes', 'yes', 'Personal', '', NULL, NULL),
(6, 'Regular (2Hr)', 1, '1000', '', 'PPPOE', NULL, NULL, NULL, NULL, NULL, NULL, 2, 'Hrs', NULL, '', 1, 'starnet1', 0, 0, 1, 'yes', 'yes', 'Personal', 'RadiusRest', NULL, NULL),
(7, 'Regular (10Hr)', 1, '5000', '', 'PPPOE', NULL, NULL, NULL, NULL, NULL, NULL, 10, 'Hrs', NULL, '', 1, 'starnet1', 0, 0, 1, 'yes', 'yes', 'Personal', 'RadiusRest', NULL, NULL),
(8, 'Monthly (Regular)', 1, '60000', '', 'Hotspot', 'Unlimited', 'Time_Limit', 0, 'Hrs', 0, 'MB', 1, 'Months', 3, '', 1, NULL, 0, 20, 1, 'yes', 'yes', 'Personal', 'RadiusRest', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pool`
--

CREATE TABLE `tbl_pool` (
  `id` int(11) NOT NULL,
  `pool_name` varchar(40) NOT NULL,
  `local_ip` varchar(40) NOT NULL DEFAULT '',
  `range_ip` varchar(40) NOT NULL,
  `routers` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_pool`
--

INSERT INTO `tbl_pool` (`id`, `pool_name`, `local_ip`, `range_ip`, `routers`) VALUES
(1, 'starnet1', '192.168.0.0', '192.168.8.50-192.168.10.254', 'radius');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_port_pool`
--

CREATE TABLE `tbl_port_pool` (
  `id` int(10) NOT NULL,
  `public_ip` varchar(40) NOT NULL,
  `port_name` varchar(40) NOT NULL,
  `range_port` varchar(40) NOT NULL,
  `routers` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_routers`
--

CREATE TABLE `tbl_routers` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `ip_address` varchar(128) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(60) NOT NULL,
  `description` varchar(256) DEFAULT NULL,
  `coordinates` varchar(50) NOT NULL DEFAULT '',
  `status` enum('Online','Offline') DEFAULT 'Online',
  `last_seen` datetime DEFAULT NULL,
  `coverage` varchar(8) NOT NULL DEFAULT '0',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 disabled'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_routers`
--

INSERT INTO `tbl_routers` (`id`, `name`, `ip_address`, `username`, `password`, `description`, `coordinates`, `status`, `last_seen`, `coverage`, `enabled`) VALUES
(1, 'STARNET1', '192.168.0.1:1812', 'admin', 'verysecret', '', '', 'Online', NULL, '1000', 1);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_transactions`
--

CREATE TABLE `tbl_transactions` (
  `id` int(11) NOT NULL,
  `invoice` varchar(25) NOT NULL,
  `username` varchar(32) NOT NULL,
  `user_id` int(11) NOT NULL DEFAULT 0,
  `plan_name` varchar(40) NOT NULL,
  `price` varchar(40) NOT NULL,
  `recharged_on` date NOT NULL,
  `recharged_time` time NOT NULL DEFAULT '00:00:00',
  `expiration` date NOT NULL,
  `time` time NOT NULL,
  `method` varchar(128) NOT NULL,
  `routers` varchar(32) NOT NULL,
  `type` enum('Hotspot','PPPOE','VPN','Balance') NOT NULL,
  `note` varchar(256) NOT NULL DEFAULT '' COMMENT 'for note',
  `admin_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_transactions`
--

INSERT INTO `tbl_transactions` (`id`, `invoice`, `username`, `user_id`, `plan_name`, `price`, `recharged_on`, `recharged_time`, `expiration`, `time`, `method`, `routers`, `type`, `note`, `admin_id`) VALUES
(1, 'INV-1', 'testuser', 1, 'Topup 5000', '5000', '2025-12-05', '10:48:11', '2025-12-05', '10:48:11', 'Deposit - Administrator', 'balance', 'Balance', '', 1),
(2, 'INV-2', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-05', '10:50:02', '2025-12-05', '11:50:02', 'Voucher - bf4F5a', 'radius', 'PPPOE', '', 1),
(3, 'INV-3', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-05', '14:30:01', '2025-12-05', '15:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0),
(4, 'INV-4', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-05', '18:30:01', '2025-12-05', '19:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0),
(5, 'INV-5', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-05', '22:30:01', '2025-12-05', '23:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0),
(6, 'INV-6', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-06', '02:30:01', '2025-12-06', '03:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0),
(7, 'INV-7', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-06', '06:30:01', '2025-12-06', '07:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0),
(8, 'INV-8', 'testuser', 1, 'Regular (1Hr)', '500', '2025-12-06', '10:30:01', '2025-12-06', '11:30:01', 'Customer - Balance', 'radius', 'PPPOE', '', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_users`
--

CREATE TABLE `tbl_users` (
  `id` int(10) UNSIGNED NOT NULL,
  `root` int(11) NOT NULL DEFAULT 0 COMMENT 'for sub account',
  `photo` varchar(128) NOT NULL DEFAULT '/admin.default.png',
  `username` varchar(45) NOT NULL DEFAULT '',
  `fullname` varchar(45) NOT NULL DEFAULT '',
  `password` varchar(64) NOT NULL,
  `phone` varchar(32) NOT NULL DEFAULT '',
  `email` varchar(128) NOT NULL DEFAULT '',
  `city` varchar(64) NOT NULL DEFAULT '' COMMENT 'kota',
  `subdistrict` varchar(64) NOT NULL DEFAULT '' COMMENT 'kecamatan',
  `ward` varchar(64) NOT NULL DEFAULT '' COMMENT 'kelurahan',
  `user_type` enum('SuperAdmin','Admin','Report','Agent','Sales') NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `data` text DEFAULT NULL COMMENT 'to put additional data',
  `last_login` datetime DEFAULT NULL,
  `login_token` varchar(40) DEFAULT NULL,
  `creationdate` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_users`
--

INSERT INTO `tbl_users` (`id`, `root`, `photo`, `username`, `fullname`, `password`, `phone`, `email`, `city`, `subdistrict`, `ward`, `user_type`, `status`, `data`, `last_login`, `login_token`, `creationdate`) VALUES
(1, 0, '/admin.default.png', 'admin', 'Administrator', '6bbd589b9147687713ad1bba45ea4ecb9a5117e3', '', '', '', '', '', 'SuperAdmin', 'Active', NULL, '2025-12-03 23:05:45', '8cfb0217f53df81907722fb196650e9f53a113c9', '2014-06-23 01:43:07'),
(2, 0, '/admin.default.png', 'zawminaung', 'Zaw Min Aung', 'a642a77abd7d4f51bf9226ceaf891fcbb5b299b8', '', 'zawminaung@gmail.com', 'Wuntho', 'Jodaung', '', 'Agent', 'Active', NULL, NULL, NULL, '2025-12-03 23:16:47');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_user_recharges`
--

CREATE TABLE `tbl_user_recharges` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `username` varchar(32) NOT NULL,
  `plan_id` int(11) NOT NULL,
  `namebp` varchar(40) NOT NULL,
  `recharged_on` date NOT NULL,
  `recharged_time` time NOT NULL DEFAULT '00:00:00',
  `expiration` date NOT NULL,
  `time` time NOT NULL,
  `status` varchar(20) NOT NULL,
  `method` varchar(128) NOT NULL DEFAULT '',
  `routers` varchar(32) NOT NULL,
  `type` varchar(15) NOT NULL,
  `admin_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_user_recharges`
--

INSERT INTO `tbl_user_recharges` (`id`, `customer_id`, `username`, `plan_id`, `namebp`, `recharged_on`, `recharged_time`, `expiration`, `time`, `status`, `method`, `routers`, `type`, `admin_id`) VALUES
(1, 1, 'testuser', 1, 'Regular (1Hr)', '2025-12-06', '10:30:01', '2025-12-06', '11:30:01', 'on', 'Customer - Balance', 'radius', 'PPPOE', 0);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_voucher`
--

CREATE TABLE `tbl_voucher` (
  `id` int(11) NOT NULL,
  `type` enum('Hotspot','PPPOE') NOT NULL,
  `routers` varchar(32) NOT NULL,
  `id_plan` int(11) NOT NULL,
  `code` varchar(55) NOT NULL,
  `user` varchar(45) NOT NULL,
  `status` varchar(25) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `used_date` datetime DEFAULT NULL,
  `generated_by` int(11) NOT NULL DEFAULT 0 COMMENT 'id admin'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_voucher`
--

INSERT INTO `tbl_voucher` (`id`, `type`, `routers`, `id_plan`, `code`, `user`, `status`, `created_at`, `used_date`, `generated_by`) VALUES
(1, 'PPPOE', 'radius', 1, 'bf4F5a', 'testuser', '1', '2025-12-05 04:19:07', NULL, 1),
(2, 'PPPOE', 'radius', 1, 'dE8088', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(3, 'PPPOE', 'radius', 1, '6a9a03', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(4, 'PPPOE', 'radius', 1, '69EDfb', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(5, 'PPPOE', 'radius', 1, '9fb086', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(6, 'PPPOE', 'radius', 1, 'EA0714', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(7, 'PPPOE', 'radius', 1, 'fee43C', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(8, 'PPPOE', 'radius', 1, 'D32182', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(9, 'PPPOE', 'radius', 1, '0E7529', '0', '0', '2025-12-05 04:19:07', NULL, 1),
(10, 'PPPOE', 'radius', 1, 'f40666', '0', '0', '2025-12-05 04:19:07', NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_widgets`
--

CREATE TABLE `tbl_widgets` (
  `id` int(11) NOT NULL,
  `orders` int(11) NOT NULL DEFAULT 99,
  `position` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1. top 2. left 3. right 4. bottom',
  `user` enum('Admin','Agent','Sales','Customer') NOT NULL DEFAULT 'Admin',
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `title` varchar(64) NOT NULL,
  `widget` varchar(64) NOT NULL DEFAULT '',
  `content` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tbl_widgets`
--

INSERT INTO `tbl_widgets` (`id`, `orders`, `position`, `user`, `enabled`, `title`, `widget`, `content`) VALUES
(1, 1, 1, 'Admin', 1, 'Top Widget', 'top_widget', ''),
(2, 2, 1, 'Admin', 1, 'Default Info', 'default_info_row', ''),
(3, 1, 2, 'Admin', 1, 'Graph Monthly Registered Customers', 'graph_monthly_registered_customers', ''),
(4, 2, 2, 'Admin', 1, 'Graph Monthly Sales', 'graph_monthly_sales', ''),
(5, 3, 2, 'Admin', 1, 'Voucher Stocks', 'voucher_stocks', ''),
(6, 4, 2, 'Admin', 1, 'Customer Expired', 'customer_expired', ''),
(7, 1, 3, 'Admin', 1, 'Cron Monitor', 'cron_monitor', ''),
(8, 2, 3, 'Admin', 1, 'Mikrotik Cron Monitor', 'mikrotik_cron_monitor', ''),
(9, 3, 3, 'Admin', 1, 'Info Payment Gateway', 'info_payment_gateway', ''),
(10, 4, 3, 'Admin', 1, 'Graph Customers Insight', 'graph_customers_insight', ''),
(11, 5, 3, 'Admin', 1, 'Activity Log', 'activity_log', ''),
(30, 1, 1, 'Agent', 1, 'Top Widget', 'top_widget', ''),
(31, 2, 1, 'Agent', 1, 'Default Info', 'default_info_row', ''),
(32, 1, 2, 'Agent', 1, 'Graph Monthly Registered Customers', 'graph_monthly_registered_customers', ''),
(33, 2, 2, 'Agent', 1, 'Graph Monthly Sales', 'graph_monthly_sales', ''),
(34, 3, 2, 'Agent', 1, 'Voucher Stocks', 'voucher_stocks', ''),
(35, 4, 2, 'Agent', 1, 'Customer Expired', 'customer_expired', ''),
(36, 1, 3, 'Agent', 1, 'Cron Monitor', 'cron_monitor', ''),
(37, 2, 3, 'Agent', 1, 'Mikrotik Cron Monitor', 'mikrotik_cron_monitor', ''),
(38, 3, 3, 'Agent', 1, 'Info Payment Gateway', 'info_payment_gateway', ''),
(39, 4, 3, 'Agent', 1, 'Graph Customers Insight', 'graph_customers_insight', ''),
(40, 5, 3, 'Agent', 1, 'Activity Log', 'activity_log', ''),
(41, 1, 1, 'Sales', 1, 'Top Widget', 'top_widget', ''),
(42, 2, 1, 'Sales', 1, 'Default Info', 'default_info_row', ''),
(43, 1, 2, 'Sales', 1, 'Graph Monthly Registered Customers', 'graph_monthly_registered_customers', ''),
(44, 2, 2, 'Sales', 1, 'Graph Monthly Sales', 'graph_monthly_sales', ''),
(45, 3, 2, 'Sales', 1, 'Voucher Stocks', 'voucher_stocks', ''),
(46, 4, 2, 'Sales', 1, 'Customer Expired', 'customer_expired', ''),
(47, 1, 3, 'Sales', 1, 'Cron Monitor', 'cron_monitor', ''),
(48, 2, 3, 'Sales', 1, 'Mikrotik Cron Monitor', 'mikrotik_cron_monitor', ''),
(49, 3, 3, 'Sales', 1, 'Info Payment Gateway', 'info_payment_gateway', ''),
(50, 4, 3, 'Sales', 1, 'Graph Customers Insight', 'graph_customers_insight', ''),
(51, 5, 3, 'Sales', 1, 'Activity Log', 'activity_log', ''),
(60, 1, 2, 'Customer', 1, 'Account Info', 'account_info', ''),
(61, 3, 1, 'Customer', 1, 'Active Internet Plan', 'active_internet_plan', ''),
(62, 4, 1, 'Customer', 1, 'Balance Transfer', 'balance_transfer', ''),
(63, 1, 1, 'Customer', 1, 'Unpaid Order', 'unpaid_order', ''),
(64, 2, 1, 'Customer', 1, 'Announcement', 'announcement', ''),
(65, 5, 1, 'Customer', 1, 'Recharge A Friend', 'recharge_a_friend', ''),
(66, 2, 2, 'Customer', 1, 'Voucher Activation', 'voucher_activation', '');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `nas`
--
ALTER TABLE `nas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nasname` (`nasname`);

--
-- Indexes for table `nasreload`
--
ALTER TABLE `nasreload`
  ADD PRIMARY KEY (`nasipaddress`);

--
-- Indexes for table `radacct`
--
ALTER TABLE `radacct`
  ADD PRIMARY KEY (`radacctid`),
  ADD UNIQUE KEY `acctuniqueid` (`acctuniqueid`),
  ADD KEY `username` (`username`),
  ADD KEY `framedipaddress` (`framedipaddress`),
  ADD KEY `framedipv6address` (`framedipv6address`),
  ADD KEY `framedipv6prefix` (`framedipv6prefix`),
  ADD KEY `framedinterfaceid` (`framedinterfaceid`),
  ADD KEY `delegatedipv6prefix` (`delegatedipv6prefix`),
  ADD KEY `acctsessionid` (`acctsessionid`),
  ADD KEY `acctsessiontime` (`acctsessiontime`),
  ADD KEY `acctstarttime` (`acctstarttime`),
  ADD KEY `acctinterval` (`acctinterval`),
  ADD KEY `acctstoptime` (`acctstoptime`),
  ADD KEY `nasipaddress` (`nasipaddress`),
  ADD KEY `class` (`class`);

--
-- Indexes for table `radcheck`
--
ALTER TABLE `radcheck`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`(32));

--
-- Indexes for table `radgroupcheck`
--
ALTER TABLE `radgroupcheck`
  ADD PRIMARY KEY (`id`),
  ADD KEY `groupname` (`groupname`(32));

--
-- Indexes for table `radgroupreply`
--
ALTER TABLE `radgroupreply`
  ADD PRIMARY KEY (`id`),
  ADD KEY `groupname` (`groupname`(32));

--
-- Indexes for table `radpostauth`
--
ALTER TABLE `radpostauth`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`),
  ADD KEY `class` (`class`);

--
-- Indexes for table `radreply`
--
ALTER TABLE `radreply`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`(32));

--
-- Indexes for table `radusergroup`
--
ALTER TABLE `radusergroup`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`(32));

--
-- Indexes for table `rad_acct`
--
ALTER TABLE `rad_acct`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`),
  ADD KEY `framedipaddress` (`framedipaddress`),
  ADD KEY `acctsessionid` (`acctsessionid`),
  ADD KEY `nasipaddress` (`nasipaddress`);

--
-- Indexes for table `tbl_appconfig`
--
ALTER TABLE `tbl_appconfig`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_bandwidth`
--
ALTER TABLE `tbl_bandwidth`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_coupons`
--
ALTER TABLE `tbl_coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `tbl_customers`
--
ALTER TABLE `tbl_customers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_customers_fields`
--
ALTER TABLE `tbl_customers_fields`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `tbl_customers_inbox`
--
ALTER TABLE `tbl_customers_inbox`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_logs`
--
ALTER TABLE `tbl_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_message_logs`
--
ALTER TABLE `tbl_message_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_meta`
--
ALTER TABLE `tbl_meta`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_odps`
--
ALTER TABLE `tbl_odps`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indexes for table `tbl_payment_gateway`
--
ALTER TABLE `tbl_payment_gateway`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_plans`
--
ALTER TABLE `tbl_plans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_pool`
--
ALTER TABLE `tbl_pool`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_port_pool`
--
ALTER TABLE `tbl_port_pool`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_routers`
--
ALTER TABLE `tbl_routers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_transactions`
--
ALTER TABLE `tbl_transactions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_user_recharges`
--
ALTER TABLE `tbl_user_recharges`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_voucher`
--
ALTER TABLE `tbl_voucher`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_widgets`
--
ALTER TABLE `tbl_widgets`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `nas`
--
ALTER TABLE `nas`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `radacct`
--
ALTER TABLE `radacct`
  MODIFY `radacctid` bigint(21) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radcheck`
--
ALTER TABLE `radcheck`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radgroupcheck`
--
ALTER TABLE `radgroupcheck`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radgroupreply`
--
ALTER TABLE `radgroupreply`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radpostauth`
--
ALTER TABLE `radpostauth`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radreply`
--
ALTER TABLE `radreply`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `radusergroup`
--
ALTER TABLE `radusergroup`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rad_acct`
--
ALTER TABLE `rad_acct`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_appconfig`
--
ALTER TABLE `tbl_appconfig`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `tbl_bandwidth`
--
ALTER TABLE `tbl_bandwidth`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_coupons`
--
ALTER TABLE `tbl_coupons`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_customers`
--
ALTER TABLE `tbl_customers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_customers_fields`
--
ALTER TABLE `tbl_customers_fields`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_customers_inbox`
--
ALTER TABLE `tbl_customers_inbox`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_logs`
--
ALTER TABLE `tbl_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `tbl_message_logs`
--
ALTER TABLE `tbl_message_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_meta`
--
ALTER TABLE `tbl_meta`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_odps`
--
ALTER TABLE `tbl_odps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_payment_gateway`
--
ALTER TABLE `tbl_payment_gateway`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_plans`
--
ALTER TABLE `tbl_plans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_pool`
--
ALTER TABLE `tbl_pool`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_port_pool`
--
ALTER TABLE `tbl_port_pool`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_routers`
--
ALTER TABLE `tbl_routers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_transactions`
--
ALTER TABLE `tbl_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_users`
--
ALTER TABLE `tbl_users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tbl_user_recharges`
--
ALTER TABLE `tbl_user_recharges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_voucher`
--
ALTER TABLE `tbl_voucher`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tbl_widgets`
--
ALTER TABLE `tbl_widgets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=67;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
