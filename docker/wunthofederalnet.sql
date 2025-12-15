/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.13-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: wunthofederalnet
-- ------------------------------------------------------
-- Server version	10.11.13-MariaDB-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `nas`
--

DROP TABLE IF EXISTS `nas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nas` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `nasname` varchar(128) NOT NULL,
  `shortname` varchar(32) DEFAULT NULL,
  `type` varchar(30) DEFAULT 'other',
  `ports` int(5) DEFAULT NULL,
  `secret` varchar(60) NOT NULL DEFAULT 'secret',
  `server` varchar(64) DEFAULT NULL,
  `community` varchar(50) DEFAULT NULL,
  `description` varchar(200) DEFAULT 'RADIUS Client',
  `routers` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `nasname` (`nasname`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nas`
--

LOCK TABLES `nas` WRITE;
/*!40000 ALTER TABLE `nas` DISABLE KEYS */;
INSERT INTO `nas` VALUES
(1,'192.168.0.1','STARNET1','other',1812,'verysecret',NULL,NULL,'RADIUS Client','STARNET1');
/*!40000 ALTER TABLE `nas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nasreload`
--

DROP TABLE IF EXISTS `nasreload`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nasreload` (
  `nasipaddress` varchar(15) NOT NULL,
  `reloadtime` datetime NOT NULL,
  PRIMARY KEY (`nasipaddress`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nasreload`
--

LOCK TABLES `nasreload` WRITE;
/*!40000 ALTER TABLE `nasreload` DISABLE KEYS */;
/*!40000 ALTER TABLE `nasreload` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rad_acct`
--

DROP TABLE IF EXISTS `rad_acct`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rad_acct` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
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
  `dateAdded` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `framedipaddress` (`framedipaddress`),
  KEY `acctsessionid` (`acctsessionid`),
  KEY `nasipaddress` (`nasipaddress`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rad_acct`
--

LOCK TABLES `rad_acct` WRITE;
/*!40000 ALTER TABLE `rad_acct` DISABLE KEYS */;
/*!40000 ALTER TABLE `rad_acct` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radacct`
--

DROP TABLE IF EXISTS `radacct`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radacct` (
  `radacctid` bigint(21) NOT NULL AUTO_INCREMENT,
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
  `acctsessiontime` int(12) unsigned DEFAULT NULL,
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
  `class` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`radacctid`),
  UNIQUE KEY `acctuniqueid` (`acctuniqueid`),
  KEY `username` (`username`),
  KEY `framedipaddress` (`framedipaddress`),
  KEY `framedipv6address` (`framedipv6address`),
  KEY `framedipv6prefix` (`framedipv6prefix`),
  KEY `framedinterfaceid` (`framedinterfaceid`),
  KEY `delegatedipv6prefix` (`delegatedipv6prefix`),
  KEY `acctsessionid` (`acctsessionid`),
  KEY `acctsessiontime` (`acctsessiontime`),
  KEY `acctstarttime` (`acctstarttime`),
  KEY `acctinterval` (`acctinterval`),
  KEY `acctstoptime` (`acctstoptime`),
  KEY `nasipaddress` (`nasipaddress`),
  KEY `class` (`class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radacct`
--

LOCK TABLES `radacct` WRITE;
/*!40000 ALTER TABLE `radacct` DISABLE KEYS */;
/*!40000 ALTER TABLE `radacct` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radcheck`
--

DROP TABLE IF EXISTS `radcheck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radcheck` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radcheck`
--

LOCK TABLES `radcheck` WRITE;
/*!40000 ALTER TABLE `radcheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `radcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupcheck`
--

DROP TABLE IF EXISTS `radgroupcheck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radgroupcheck` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radgroupcheck`
--

LOCK TABLES `radgroupcheck` WRITE;
/*!40000 ALTER TABLE `radgroupcheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `radgroupcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupreply`
--

DROP TABLE IF EXISTS `radgroupreply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radgroupreply` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT '',
  `plan_id` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radgroupreply`
--

LOCK TABLES `radgroupreply` WRITE;
/*!40000 ALTER TABLE `radgroupreply` DISABLE KEYS */;
/*!40000 ALTER TABLE `radgroupreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radpostauth`
--

DROP TABLE IF EXISTS `radpostauth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radpostauth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `pass` varchar(64) NOT NULL DEFAULT '',
  `reply` varchar(32) NOT NULL DEFAULT '',
  `authdate` timestamp(6) NOT NULL DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  `class` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `class` (`class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radpostauth`
--

LOCK TABLES `radpostauth` WRITE;
/*!40000 ALTER TABLE `radpostauth` DISABLE KEYS */;
/*!40000 ALTER TABLE `radpostauth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radreply`
--

DROP TABLE IF EXISTS `radreply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radreply` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radreply`
--

LOCK TABLES `radreply` WRITE;
/*!40000 ALTER TABLE `radreply` DISABLE KEYS */;
/*!40000 ALTER TABLE `radreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radusergroup`
--

DROP TABLE IF EXISTS `radusergroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radusergroup` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `priority` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radusergroup`
--

LOCK TABLES `radusergroup` WRITE;
/*!40000 ALTER TABLE `radusergroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `radusergroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_appconfig`
--

DROP TABLE IF EXISTS `tbl_appconfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_appconfig` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting` mediumtext NOT NULL,
  `value` mediumtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
  `nrc_no` varchar(45) DEFAULT NULL,
-- Dumping data for table `tbl_appconfig`
--

LOCK TABLES `tbl_appconfig` WRITE;
/*!40000 ALTER TABLE `tbl_appconfig` DISABLE KEYS */;
INSERT INTO `tbl_appconfig` VALUES
(1,'CompanyName','Myanmar Federal-Net'),
(2,'currency_code','MMK'),
(3,'language','english'),
(4,'show-logo','1'),
(5,'nstyle','blue'),
(6,'timezone','Asia/Yangon'),
(7,'dec_point','.'),
(8,'thousands_sep',','),
(9,'rtl','0'),
(10,'address',''),
(11,'phone',''),
(12,'date_format','d M Y'),
(13,'note','Thank you...'),
(14,'api_key','2125bc004ac7547d71e54540184176e71fa16c28'),
(15,'country_code_phone',''),
(16,'radius_plan','Radius Plan'),
(17,'hotspot_plan','Hotspot Plan'),
(18,'pppoe_plan','PPPOE Plan'),
(19,'vpn_plan','VPN Plan'),
(20,'csrf_token','d764e5932101fbde43ec65d3d5b252b4'),
(21,'CompanyFooter',''),
(22,'printer_cols','60'),
(23,'theme','default'),
(24,'payment_usings',''),
(25,'reset_day','1'),
(26,'dashboard_cr',''),
(27,'url_canonical','no'),
(28,'general',''),
(29,'login_page_type','default'),
(30,'login_Page_template','moon'),
(31,'login_page_head',''),
(32,'login_page_description',''),
(33,'disable_registration','no'),
(34,'registration_username','username'),
(35,'photo_register','no'),
(36,'sms_otp_registration','no'),
(37,'phone_otp_type','sms'),
(38,'reg_nofify_admin','yes'),
(39,'man_fields_email','no'),
(40,'man_fields_fname','yes'),
(41,'man_fields_address','yes'),
(42,'session_timeout_duration',''),
(43,'single_session','no'),
(44,'csrf_enabled','no'),
(45,'disable_voucher','no'),
(46,'voucher_format','up'),
(47,'voucher_redirect',''),
(48,'radius_enable','1'),
(49,'extend_expired','0'),
(50,'extend_days',''),
(51,'extend_confirmation',''),
(52,'enable_balance','yes'),
(53,'allow_balance_transfer','yes'),
(54,'minimum_transfer',''),
(55,'allow_balance_custom','yes'),
(56,'telegram_bot',''),
(57,'telegram_target_id',''),
(58,'sms_url',''),
(59,'mikrotik_sms_command','/tool sms send'),
(60,'wa_url',''),
(61,'smtp_host',''),
(62,'smtp_port',''),
(63,'smtp_user',''),
(64,'smtp_pass',''),
(65,'smtp_ssltls',''),
(66,'mail_from',''),
(67,'mail_reply_to',''),
(68,'user_notification_expired','email'),
(69,'user_notification_payment','email'),
(70,'user_notification_reminder','sms'),
(71,'notification_reminder_1day','yes'),
(72,'notification_reminder_3days','yes'),
(73,'notification_reminder_7days','yes'),
(74,'tawkto',''),
(75,'tawkto_api_key',''),
(76,'http_proxy',''),
(77,'http_proxyauth',''),
(78,'enable_tax','no'),
(79,'tax_rate','0.5'),
(80,'custom_tax_rate',''),
(81,'github_username',''),
(82,'github_token',''),
(83,'man_fields_custom','no'),
(84,'enable_session_timeout','0'),
(85,'hide_mrc','no'),
(86,'hide_tms','no'),
(87,'hide_al','no'),
(88,'hide_uet','no'),
(89,'hide_vs','no'),
(90,'hide_pg','no'),
(91,'hide_aui','no'),
(92,'new_version_notify','enable'),
(93,'router_check','0'),
(94,'allow_phone_otp','no'),
(95,'allow_email_otp','no'),
(96,'show_bandwidth_plan','yes'),
(97,'hs_auth_method','api'),
(98,'frrest_interim_update','0'),
(99,'check_customer_online','yes'),
(100,'extend_expiry','yes'),
(101,'save','save'),
(102,'docs_clicked','yes');
/*!40000 ALTER TABLE `tbl_appconfig` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_bandwidth`
--

DROP TABLE IF EXISTS `tbl_bandwidth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_bandwidth` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name_bw` varchar(255) NOT NULL,
  `rate_down` int(10) unsigned NOT NULL,
  `rate_down_unit` enum('Kbps','Mbps') NOT NULL,
  `rate_up` int(10) unsigned NOT NULL,
  `rate_up_unit` enum('Kbps','Mbps') NOT NULL,
  `burst` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_bandwidth`
--

LOCK TABLES `tbl_bandwidth` WRITE;
/*!40000 ALTER TABLE `tbl_bandwidth` DISABLE KEYS */;
INSERT INTO `tbl_bandwidth` VALUES
(1,'Regular Plan',5,'Mbps',5,'Mbps','10M/10M 3840k/3840k 16/16 8 2560k/2560k');
/*!40000 ALTER TABLE `tbl_bandwidth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_coupons`
--

DROP TABLE IF EXISTS `tbl_coupons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_coupons` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_coupons`
--

LOCK TABLES `tbl_coupons` WRITE;
/*!40000 ALTER TABLE `tbl_coupons` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_coupons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_customers`
--

DROP TABLE IF EXISTS `tbl_customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(45) NOT NULL,
  `password` varchar(128) NOT NULL,
  `photo` varchar(128) NOT NULL DEFAULT '/user.default.jpg',
  `pppoe_username` varchar(32) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `pppoe_password` varchar(45) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `pppoe_ip` varchar(32) NOT NULL DEFAULT '' COMMENT 'For PPPOE Login',
  `fullname` varchar(45) NOT NULL,
  `nrc_no` varchar(45) DEFAULT NULL,
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
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_customers`
--

LOCK TABLES `tbl_customers` WRITE;
/*!40000 ALTER TABLE `tbl_customers` DISABLE KEYS */;
INSERT INTO `tbl_customers` (`id`,`username`,`password`,`photo`,`pppoe_username`,`pppoe_password`,`pppoe_ip`,`fullname`,`nrc_no`,`address`,`city`,`district`,`state`,`zip`,`phonenumber`,`email`,`coordinates`,`account_type`,`balance`,`service_type`,`auto_renewal`,`status`,`created_by`,`created_at`,`last_login`) VALUES
(1,'testuser','11115555','/user.default.jpg','','','','testuser','',NULL,NULL,NULL,NULL,NULL,NULL,'zawminaung@gmail.com','','Personal',2500.00,'PPPoE',1,'Active',1,'2025-12-05 04:06:11',NULL);
/*!40000 ALTER TABLE `tbl_customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_customers_fields`
--

DROP TABLE IF EXISTS `tbl_customers_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_customers_fields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `field_name` varchar(255) NOT NULL,
  `field_value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_customers_fields`
--

LOCK TABLES `tbl_customers_fields` WRITE;
/*!40000 ALTER TABLE `tbl_customers_fields` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_customers_fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_customers_inbox`
--

DROP TABLE IF EXISTS `tbl_customers_inbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_customers_inbox` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `date_read` datetime DEFAULT NULL,
  `subject` varchar(64) NOT NULL,
  `body` text DEFAULT NULL,
  `from` varchar(8) NOT NULL DEFAULT 'System' COMMENT 'System or Admin or Else',
  `admin_id` int(11) NOT NULL DEFAULT 0 COMMENT 'other than admin is 0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_customers_inbox`
--

LOCK TABLES `tbl_customers_inbox` WRITE;
/*!40000 ALTER TABLE `tbl_customers_inbox` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_customers_inbox` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_logs`
--

DROP TABLE IF EXISTS `tbl_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` datetime DEFAULT NULL,
  `type` varchar(50) NOT NULL,
  `description` mediumtext NOT NULL,
  `userid` int(11) NOT NULL,
  `ip` mediumtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_logs`
--

LOCK TABLES `tbl_logs` WRITE;
/*!40000 ALTER TABLE `tbl_logs` DISABLE KEYS */;
INSERT INTO `tbl_logs` VALUES
(1,'2025-12-03 23:05:45','SuperAdmin','admin Login Successful',1,'129.224.203.237'),
(2,'2025-12-03 23:07:33','SuperAdmin','[admin]: Password changed successfully',1,'129.224.203.237'),
(3,'2025-12-03 23:16:47','SuperAdmin','[admin]: Created Agent <b>zawminaung</b>',1,'129.224.203.237'),
(4,'2025-12-03 23:22:58','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(5,'2025-12-03 22:53:25','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(6,'2025-12-03 22:54:38','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(7,'2025-12-03 22:54:50','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(8,'2025-12-03 22:55:23','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(9,'2025-12-03 22:56:12','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(10,'2025-12-03 23:53:01','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.203.237'),
(11,'2025-12-04 07:42:46','SuperAdmin','[admin]: Settings Saved Successfully',1,'150.228.149.174'),
(12,'2025-12-04 07:43:00','SuperAdmin','[admin]: Settings Saved Successfully',1,'150.228.149.174'),
(13,'2025-12-05 09:46:43','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.202.140'),
(14,'2025-12-05 09:46:56','SuperAdmin','[admin]: Settings Saved Successfully',1,'129.224.202.140');
/*!40000 ALTER TABLE `tbl_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_message_logs`
--

DROP TABLE IF EXISTS `tbl_message_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_message_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `message_type` varchar(50) DEFAULT NULL,
  `recipient` varchar(255) DEFAULT NULL,
  `message_content` text DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_message_logs`
--

LOCK TABLES `tbl_message_logs` WRITE;
/*!40000 ALTER TABLE `tbl_message_logs` DISABLE KEYS */;
INSERT INTO `tbl_message_logs` VALUES
(1,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-1*\r\nDate : 05 Dec 2025 10:48\r\nDeposit Administrator\r\n\r\n\r\nType : *Balance*\r\nPackage : *Topup 5000*\r\nPrice : *MMK 5,000*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 04:18:11'),
(2,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-2*\r\nDate : 05 Dec 2025 10:50\r\nVoucher bf4F5a\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 11:50*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 04:20:02'),
(3,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-3*\r\nDate : 05 Dec 2025 14:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 15:30*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 08:00:01'),
(4,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-4*\r\nDate : 05 Dec 2025 18:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 19:30*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 12:00:01'),
(5,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-5*\r\nDate : 05 Dec 2025 22:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *05 Dec 2025 23:30*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 16:00:01'),
(6,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-6*\r\nDate : 06 Dec 2025 02:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *06 Dec 2025 03:30*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-05 20:00:01'),
(7,'Email','zawminaung@gmail.com','*Myanmar Federal-Net*\r\n\r\n\r\n\r\n\r\nINVOICE: *INV-7*\r\nDate : 06 Dec 2025 06:30\r\nCustomer Balance\r\n\r\n\r\nType : *PPPOE*\r\nPackage : *Regular (1Hr)*\r\nPrice : *MMK 500*\r\n\r\nUsername : *testuser*\r\nPassword : ***********\r\n\r\nExpired : *06 Dec 2025 07:30*\r\n\r\n====================\r\nThank you...','Success',NULL,'2025-12-06 00:00:01');
/*!40000 ALTER TABLE `tbl_message_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_meta`
--

DROP TABLE IF EXISTS `tbl_meta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_meta` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tbl` varchar(32) NOT NULL COMMENT 'Table name',
  `tbl_id` int(11) NOT NULL COMMENT 'table value id',
  `name` varchar(32) NOT NULL,
  `value` mediumtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='This Table to add additional data for any table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_meta`
--

LOCK TABLES `tbl_meta` WRITE;
/*!40000 ALTER TABLE `tbl_meta` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_meta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_odps`
--

DROP TABLE IF EXISTS `tbl_odps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_odps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `port_amount` int(11) NOT NULL,
  `attenuation` decimal(15,2) NOT NULL DEFAULT 0.00,
  `address` mediumtext NOT NULL,
  `coordinates` varchar(50) NOT NULL,
  `coverage` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_odps`
--

LOCK TABLES `tbl_odps` WRITE;
/*!40000 ALTER TABLE `tbl_odps` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_odps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_payment_gateway`
--

DROP TABLE IF EXISTS `tbl_payment_gateway`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_payment_gateway` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 unpaid 2 paid 3 failed 4 canceled',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_payment_gateway`
--

LOCK TABLES `tbl_payment_gateway` WRITE;
/*!40000 ALTER TABLE `tbl_payment_gateway` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_payment_gateway` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_plans`
--

DROP TABLE IF EXISTS `tbl_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name_plan` varchar(40) NOT NULL,
  `id_bw` int(11) NOT NULL,
  `price` varchar(40) NOT NULL,
  `price_old` varchar(40) NOT NULL DEFAULT '',
  `type` enum('Hotspot','PPPOE','VPN','Balance') NOT NULL,
  `typebp` enum('Unlimited','Limited') DEFAULT NULL,
  `limit_type` enum('Time_Limit','Data_Limit','Both_Limit') DEFAULT NULL,
  `time_limit` int(10) unsigned DEFAULT NULL,
  `time_unit` enum('Mins','Hrs') DEFAULT NULL,
  `data_limit` int(10) unsigned DEFAULT NULL,
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
  `on_logout` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_plans`
--

LOCK TABLES `tbl_plans` WRITE;
/*!40000 ALTER TABLE `tbl_plans` DISABLE KEYS */;
INSERT INTO `tbl_plans` VALUES
(1,'Regular (1Hr)',1,'500','','PPPOE',NULL,NULL,NULL,NULL,NULL,NULL,1,'Hrs',NULL,'',1,'starnet1',0,0,1,'yes','yes','Personal','RadiusRest','',''),
(2,'Regular (4Hr)',1,'2000','','PPPOE',NULL,NULL,NULL,NULL,NULL,NULL,4,'Hrs',NULL,'',1,'starnet1',0,0,1,'yes','yes','Personal','RadiusRest',NULL,NULL),
(3,'Topup 5000',0,'5000','','Balance',NULL,NULL,NULL,NULL,NULL,NULL,0,'Months',NULL,'',0,'',0,20,1,'yes','yes','Personal','',NULL,NULL),
(4,'Topup 1000',0,'1000','','Balance',NULL,NULL,NULL,NULL,NULL,NULL,0,'Months',NULL,'',0,'',0,20,1,'yes','yes','Personal','',NULL,NULL),
(5,'Topup 10000',0,'10000','','Balance',NULL,NULL,NULL,NULL,NULL,NULL,0,'Months',NULL,'',0,'',0,20,1,'yes','yes','Personal','',NULL,NULL),
(6,'Regular (2Hr)',1,'1000','','PPPOE',NULL,NULL,NULL,NULL,NULL,NULL,2,'Hrs',NULL,'',1,'starnet1',0,0,1,'yes','yes','Personal','RadiusRest',NULL,NULL),
(7,'Regular (10Hr)',1,'5000','','PPPOE',NULL,NULL,NULL,NULL,NULL,NULL,10,'Hrs',NULL,'',1,'starnet1',0,0,1,'yes','yes','Personal','RadiusRest',NULL,NULL),
(8,'Monthly (Regular)',1,'60000','','Hotspot','Unlimited','Time_Limit',0,'Hrs',0,'MB',1,'Months',3,'',1,NULL,0,20,1,'yes','yes','Personal','RadiusRest',NULL,NULL);
/*!40000 ALTER TABLE `tbl_plans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_pool`
--

DROP TABLE IF EXISTS `tbl_pool`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_pool` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pool_name` varchar(40) NOT NULL,
  `local_ip` varchar(40) NOT NULL DEFAULT '',
  `range_ip` varchar(40) NOT NULL,
  `routers` varchar(40) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_pool`
--

LOCK TABLES `tbl_pool` WRITE;
/*!40000 ALTER TABLE `tbl_pool` DISABLE KEYS */;
INSERT INTO `tbl_pool` VALUES
(1,'starnet1','192.168.0.0','192.168.8.50-192.168.10.254','radius');
/*!40000 ALTER TABLE `tbl_pool` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_port_pool`
--

DROP TABLE IF EXISTS `tbl_port_pool`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_port_pool` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `public_ip` varchar(40) NOT NULL,
  `port_name` varchar(40) NOT NULL,
  `range_port` varchar(40) NOT NULL,
  `routers` varchar(40) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_port_pool`
--

LOCK TABLES `tbl_port_pool` WRITE;
/*!40000 ALTER TABLE `tbl_port_pool` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_port_pool` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_routers`
--

DROP TABLE IF EXISTS `tbl_routers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_routers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `ip_address` varchar(128) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(60) NOT NULL,
  `description` varchar(256) DEFAULT NULL,
  `coordinates` varchar(50) NOT NULL DEFAULT '',
  `status` enum('Online','Offline') DEFAULT 'Online',
  `last_seen` datetime DEFAULT NULL,
  `coverage` varchar(8) NOT NULL DEFAULT '0',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 disabled',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_routers`
--

LOCK TABLES `tbl_routers` WRITE;
/*!40000 ALTER TABLE `tbl_routers` DISABLE KEYS */;
INSERT INTO `tbl_routers` VALUES
(1,'STARNET1','192.168.0.1:1812','admin','verysecret','','','Online',NULL,'1000',1);
/*!40000 ALTER TABLE `tbl_routers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_transactions`
--

DROP TABLE IF EXISTS `tbl_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `admin_id` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_transactions`
--

LOCK TABLES `tbl_transactions` WRITE;
/*!40000 ALTER TABLE `tbl_transactions` DISABLE KEYS */;
INSERT INTO `tbl_transactions` VALUES
(1,'INV-1','testuser',1,'Topup 5000','5000','2025-12-05','10:48:11','2025-12-05','10:48:11','Deposit - Administrator','balance','Balance','',1),
(2,'INV-2','testuser',1,'Regular (1Hr)','500','2025-12-05','10:50:02','2025-12-05','11:50:02','Voucher - bf4F5a','radius','PPPOE','',1),
(3,'INV-3','testuser',1,'Regular (1Hr)','500','2025-12-05','14:30:01','2025-12-05','15:30:01','Customer - Balance','radius','PPPOE','',0),
(4,'INV-4','testuser',1,'Regular (1Hr)','500','2025-12-05','18:30:01','2025-12-05','19:30:01','Customer - Balance','radius','PPPOE','',0),
(5,'INV-5','testuser',1,'Regular (1Hr)','500','2025-12-05','22:30:01','2025-12-05','23:30:01','Customer - Balance','radius','PPPOE','',0),
(6,'INV-6','testuser',1,'Regular (1Hr)','500','2025-12-06','02:30:01','2025-12-06','03:30:01','Customer - Balance','radius','PPPOE','',0),
(7,'INV-7','testuser',1,'Regular (1Hr)','500','2025-12-06','06:30:01','2025-12-06','07:30:01','Customer - Balance','radius','PPPOE','',0);
/*!40000 ALTER TABLE `tbl_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_user_recharges`
--

DROP TABLE IF EXISTS `tbl_user_recharges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_user_recharges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `admin_id` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_user_recharges`
--

LOCK TABLES `tbl_user_recharges` WRITE;
/*!40000 ALTER TABLE `tbl_user_recharges` DISABLE KEYS */;
INSERT INTO `tbl_user_recharges` VALUES
(1,1,'testuser',1,'Regular (1Hr)','2025-12-06','06:30:01','2025-12-06','07:30:01','on','Customer - Balance','radius','PPPOE',0);
/*!40000 ALTER TABLE `tbl_user_recharges` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_users`
--

DROP TABLE IF EXISTS `tbl_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
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
  `creationdate` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_users`
--

LOCK TABLES `tbl_users` WRITE;
/*!40000 ALTER TABLE `tbl_users` DISABLE KEYS */;
INSERT INTO `tbl_users` VALUES
(1,0,'/admin.default.png','admin','Administrator','6bbd589b9147687713ad1bba45ea4ecb9a5117e3','','','','','','SuperAdmin','Active',NULL,'2025-12-03 23:05:45','8cfb0217f53df81907722fb196650e9f53a113c9','2014-06-23 01:43:07'),
(2,0,'/admin.default.png','zawminaung','Zaw Min Aung','a642a77abd7d4f51bf9226ceaf891fcbb5b299b8','','zawminaung@gmail.com','Wuntho','Jodaung','','Agent','Active',NULL,NULL,NULL,'2025-12-03 23:16:47');
/*!40000 ALTER TABLE `tbl_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_voucher`
--

DROP TABLE IF EXISTS `tbl_voucher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_voucher` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('Hotspot','PPPOE') NOT NULL,
  `routers` varchar(32) NOT NULL,
  `id_plan` int(11) NOT NULL,
  `code` varchar(55) NOT NULL,
  `user` varchar(45) NOT NULL,
  `status` varchar(25) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `used_date` datetime DEFAULT NULL,
  `generated_by` int(11) NOT NULL DEFAULT 0 COMMENT 'id admin',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_voucher`
--

LOCK TABLES `tbl_voucher` WRITE;
/*!40000 ALTER TABLE `tbl_voucher` DISABLE KEYS */;
INSERT INTO `tbl_voucher` VALUES
(1,'PPPOE','radius',1,'bf4F5a','testuser','1','2025-12-05 04:19:07',NULL,1),
(2,'PPPOE','radius',1,'dE8088','0','0','2025-12-05 04:19:07',NULL,1),
(3,'PPPOE','radius',1,'6a9a03','0','0','2025-12-05 04:19:07',NULL,1),
(4,'PPPOE','radius',1,'69EDfb','0','0','2025-12-05 04:19:07',NULL,1),
(5,'PPPOE','radius',1,'9fb086','0','0','2025-12-05 04:19:07',NULL,1),
(6,'PPPOE','radius',1,'EA0714','0','0','2025-12-05 04:19:07',NULL,1),
(7,'PPPOE','radius',1,'fee43C','0','0','2025-12-05 04:19:07',NULL,1),
(8,'PPPOE','radius',1,'D32182','0','0','2025-12-05 04:19:07',NULL,1),
(9,'PPPOE','radius',1,'0E7529','0','0','2025-12-05 04:19:07',NULL,1),
(10,'PPPOE','radius',1,'f40666','0','0','2025-12-05 04:19:07',NULL,1);
/*!40000 ALTER TABLE `tbl_voucher` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_widgets`
--

DROP TABLE IF EXISTS `tbl_widgets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tbl_widgets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orders` int(11) NOT NULL DEFAULT 99,
  `position` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1. top 2. left 3. right 4. bottom',
  `user` enum('Admin','Agent','Sales','Customer') NOT NULL DEFAULT 'Admin',
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `title` varchar(64) NOT NULL,
  `widget` varchar(64) NOT NULL DEFAULT '',
  `content` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_widgets`
--

LOCK TABLES `tbl_widgets` WRITE;
/*!40000 ALTER TABLE `tbl_widgets` DISABLE KEYS */;
INSERT INTO `tbl_widgets` VALUES
(1,1,1,'Admin',1,'Top Widget','top_widget',''),
(2,2,1,'Admin',1,'Default Info','default_info_row',''),
(3,1,2,'Admin',1,'Graph Monthly Registered Customers','graph_monthly_registered_customers',''),
(4,2,2,'Admin',1,'Graph Monthly Sales','graph_monthly_sales',''),
(5,3,2,'Admin',1,'Voucher Stocks','voucher_stocks',''),
(6,4,2,'Admin',1,'Customer Expired','customer_expired',''),
(7,1,3,'Admin',1,'Cron Monitor','cron_monitor',''),
(8,2,3,'Admin',1,'Mikrotik Cron Monitor','mikrotik_cron_monitor',''),
(9,3,3,'Admin',1,'Info Payment Gateway','info_payment_gateway',''),
(10,4,3,'Admin',1,'Graph Customers Insight','graph_customers_insight',''),
(11,5,3,'Admin',1,'Activity Log','activity_log',''),
(30,1,1,'Agent',1,'Top Widget','top_widget',''),
(31,2,1,'Agent',1,'Default Info','default_info_row',''),
(32,1,2,'Agent',1,'Graph Monthly Registered Customers','graph_monthly_registered_customers',''),
(33,2,2,'Agent',1,'Graph Monthly Sales','graph_monthly_sales',''),
(34,3,2,'Agent',1,'Voucher Stocks','voucher_stocks',''),
(35,4,2,'Agent',1,'Customer Expired','customer_expired',''),
(36,1,3,'Agent',1,'Cron Monitor','cron_monitor',''),
(37,2,3,'Agent',1,'Mikrotik Cron Monitor','mikrotik_cron_monitor',''),
(38,3,3,'Agent',1,'Info Payment Gateway','info_payment_gateway',''),
(39,4,3,'Agent',1,'Graph Customers Insight','graph_customers_insight',''),
(40,5,3,'Agent',1,'Activity Log','activity_log',''),
(41,1,1,'Sales',1,'Top Widget','top_widget',''),
(42,2,1,'Sales',1,'Default Info','default_info_row',''),
(43,1,2,'Sales',1,'Graph Monthly Registered Customers','graph_monthly_registered_customers',''),
(44,2,2,'Sales',1,'Graph Monthly Sales','graph_monthly_sales',''),
(45,3,2,'Sales',1,'Voucher Stocks','voucher_stocks',''),
(46,4,2,'Sales',1,'Customer Expired','customer_expired',''),
(47,1,3,'Sales',1,'Cron Monitor','cron_monitor',''),
(48,2,3,'Sales',1,'Mikrotik Cron Monitor','mikrotik_cron_monitor',''),
(49,3,3,'Sales',1,'Info Payment Gateway','info_payment_gateway',''),
(50,4,3,'Sales',1,'Graph Customers Insight','graph_customers_insight',''),
(51,5,3,'Sales',1,'Activity Log','activity_log',''),
(60,1,2,'Customer',1,'Account Info','account_info',''),
(61,3,1,'Customer',1,'Active Internet Plan','active_internet_plan',''),
(62,4,1,'Customer',1,'Balance Transfer','balance_transfer',''),
(63,1,1,'Customer',1,'Unpaid Order','unpaid_order',''),
(64,2,1,'Customer',1,'Announcement','announcement',''),
(65,5,1,'Customer',1,'Recharge A Friend','recharge_a_friend',''),
(66,2,2,'Customer',1,'Voucher Activation','voucher_activation','');
/*!40000 ALTER TABLE `tbl_widgets` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-06  3:16:38

-- # get me those 5 tables creation sql

-- Here are MySQL/MariaDB `CREATE TABLE` statements for the 5 tables, matching your existing style (InnoDB, utf8mb4).

-- ## 1. `owner_gateways`

-- ```sql
CREATE TABLE `owner_gateways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,  -- tbl_users.id (owner role)
  `nas_id` INT(10) NOT NULL,             -- nas.id
  `bound_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `unbound_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_owner_nas` (`owner_id`, `nas_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_nas` (`nas_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- ```


-- ## 2. `customer_wallet_ledger`

-- ```sql
CREATE TABLE `customer_wallet_ledger` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` INT(11) NOT NULL,        -- tbl_customers.id
  `owner_id` INT(10) UNSIGNED NOT NULL,  -- tbl_users.id (owner)
  `ref_type` ENUM('voucher','topup','plan_purchase','refund','adjustment') NOT NULL,
  `ref_id` BIGINT UNSIGNED DEFAULT NULL, -- e.g. tbl_voucher.id, tbl_transactions.id
  `amount_mmk` DECIMAL(15,2) NOT NULL,   -- +credit to customer, -debit
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_ref` (`ref_type`, `ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- ```


-- ## 3. `owner_revenue_ledger`

-- ```sql
CREATE TABLE `owner_revenue_ledger` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,      -- tbl_users.id
  `period_month` CHAR(7) NOT NULL,           -- 'YYYY-MM'
  `source_type` ENUM('plan_sale','extra_fee','refund_adjustment') NOT NULL,
  `source_id` BIGINT UNSIGNED DEFAULT NULL,  -- e.g. tbl_transactions.id
  `gross_amount` DECIMAL(15,2) NOT NULL,
  `platform_tax_pct` DECIMAL(5,2) NOT NULL,
  `platform_tax_amount` DECIMAL(15,2) NOT NULL,
  `net_owner_amount` DECIMAL(15,2) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner_period` (`owner_id`, `period_month`),
  KEY `idx_source` (`source_type`, `source_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- ```


-- ## 4. `owner_settlements`

-- ```sql
CREATE TABLE `owner_settlements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,   -- tbl_users.id
  `period_month` CHAR(7) NOT NULL,        -- 'YYYY-MM'
  `statement_from` DATE NOT NULL,
  `statement_to` DATE NOT NULL,
  `total_gross` DECIMAL(15,2) NOT NULL,
  `total_tax` DECIMAL(15,2) NOT NULL,
  `total_net_due` DECIMAL(15,2) NOT NULL,
  `paid_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `payment_method` VARCHAR(32) NOT NULL DEFAULT '',  -- cash/NUGPay/bank
  `payment_ref` VARCHAR(64) NOT NULL DEFAULT '',     -- slip/txn id
  `status` ENUM('pending','partial','paid','disputed') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `settled_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_owner_period` (`owner_id`, `period_month`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- ```


-- ## 5. `owner_cash_ledger` (optional but recommended)

-- ```sql
CREATE TABLE `owner_cash_ledger` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_id` INT(10) UNSIGNED NOT NULL,  -- tbl_users.id
  `ref_type` ENUM('revenue','tax','settlement','manual_adjustment') NOT NULL,
  `ref_id` BIGINT UNSIGNED DEFAULT NULL, -- owner_revenue_ledger.id or owner_settlements.id
  `amount_mmk` DECIMAL(15,2) NOT NULL,   -- + you owe owner, - owner owes you
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_ref` (`ref_type`, `ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



