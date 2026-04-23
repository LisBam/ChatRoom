/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: chat_room
-- ------------------------------------------------------
-- Server version	10.11.14-MariaDB-0+deb12u2

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
-- Table structure for table `Messages`
--

DROP TABLE IF EXISTS `Messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `Messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) DEFAULT NULL,
  `content` text NOT NULL,
  `msg_type` enum('text','image','emoji') DEFAULT 'text',
  `status` enum('sent','delivered','read') DEFAULT 'sent',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `sender_id` (`sender_id`),
  KEY `receiver_id` (`receiver_id`),
  CONSTRAINT `Messages_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `Users` (`id`),
  CONSTRAINT `Messages_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `Users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Messages`
--

LOCK TABLES `Messages` WRITE;
/*!40000 ALTER TABLE `Messages` DISABLE KEYS */;
INSERT INTO `Messages` VALUES
(1,1,NULL,'111','text','sent','2026-04-15 14:22:20'),
(2,7,NULL,'用户二发言','text','sent','2026-04-21 12:55:46'),
(3,6,NULL,'用户一发言','text','sent','2026-04-21 12:55:55'),
(4,7,6,'我发起了私聊','text','sent','2026-04-21 12:56:50'),
(5,6,4,'晚上好！这是个什么系统？','text','sent','2026-04-21 12:57:32'),
(6,8,4,'晚上好！这是个什么系统？','text','sent','2026-04-21 13:01:02'),
(7,4,8,'晚上好！您正在使用由郑力铭制作的 Chat Whisper 系统。这是一款基于AI的在线聊天室平台，支持实时多用户对话、文本传送与互动功能。\n\n系统由专业开发者郑力铭打造，目标是为用户提供稳定、高效且私密的在线聊天体验。需配合服务器端环境运行，技术基于深度学习与自然语言处理技术，以满足日常在线交流与问题解答的需求。\n\n若您需要使用其他功能或有疑问，请尽管提出，我会尽力协助您！✨','text','sent','2026-04-21 13:01:13');
/*!40000 ALTER TABLE `Messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Users`
--

DROP TABLE IF EXISTS `Users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `Users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Users`
--

LOCK TABLES `Users` WRITE;
/*!40000 ALTER TABLE `Users` DISABLE KEYS */;
INSERT INTO `Users` VALUES
(1,'LisBam','lisbam','23107733499@qq.com','2026-04-15 05:09:28'),
(2,'redmoon','lhy123055','2485853725@qq.com','2026-04-15 05:15:33'),
(3,'2310773349','2310773349','3025211125@qq.com','2026-04-15 05:30:40'),
(4,'AI助手','','','2026-04-15 10:33:49'),
(5,'不要打扰我睡觉','123456','2961008155@qq.com','2026-04-15 10:40:31'),
(6,'我是用户一','123456','26579276532@qq.com','2026-04-21 12:55:08'),
(7,'这里是用户二','123456','2452847543@qq.com','2026-04-21 12:55:40'),
(8,'12345678','123456','258176532@qq.com','2026-04-21 13:00:49');
/*!40000 ALTER TABLE `Users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-22 22:52:45
