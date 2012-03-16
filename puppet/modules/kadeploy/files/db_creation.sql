-- Kadeploy 3.0
-- Copyright (c) by INRIA, Emmanuel Jeanvoine - 2008, 2009
-- CECILL License V2 - http://www.cecill.info
-- For details on use and redistribution please refer to License.txt


-- 
-- Table `environments`
-- 

DROP TABLE IF EXISTS `environments`;
CREATE TABLE IF NOT EXISTS `environments` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `version` int(10) unsigned NOT NULL default '0',
  `description` text,
  `author` varchar(56) NOT NULL default '',
  `tarball` varchar(512) NOT NULL,
  `preinstall` varchar(512) NOT NULL,
  `postinstall` varchar(512) NOT NULL,
  `hypervisor` varchar(255) NOT NULL,
  `hypervisor_params` varchar(255) NOT NULL,
  `initrd` varchar(255) NOT NULL,
  `kernel` varchar(255) NOT NULL,
  `kernel_params` varchar(255) NOT NULL,
  `fdisk_type` varchar(2) default NULL,
  `filesystem` varchar(9) default NULL,
  `user` varchar(255) default 'nobody',
  `allowed_users` varchar(512) NOT NULL,
  `environment_kind` varchar(10) NOT NULL,
  `visibility` varchar(8) NOT NULL,
  `demolishing_env` int(8) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

-- 
-- Table `log`
-- 

DROP TABLE IF EXISTS `log`;
CREATE TABLE IF NOT EXISTS `log` (
  `deploy_id` varchar(41) NOT NULL,
  `hostname` varchar(256) NOT NULL,
  `step1` varchar(45) NOT NULL,
  `step2` varchar(45) NOT NULL,
  `step3` varchar(45) NOT NULL,
  `timeout_step1` smallint(5) unsigned NOT NULL,
  `timeout_step2` smallint(5) unsigned NOT NULL,
  `timeout_step3` smallint(5) unsigned NOT NULL,
  `retry_step1` tinyint(1) unsigned NOT NULL,
  `retry_step2` tinyint(1) unsigned NOT NULL,
  `retry_step3` tinyint(1) unsigned NOT NULL,
  `start` int(10) unsigned NOT NULL,
  `step1_duration` int(10) unsigned NOT NULL,
  `step2_duration` int(10) unsigned NOT NULL,
  `step3_duration` int(10) unsigned NOT NULL,
  `env` varchar(64) NOT NULL,
  `anonymous_env` varchar(6) NOT NULL,
  `md5` varchar(35) NOT NULL,
  `success` varchar(6) NOT NULL,
  `error` varchar(255) NOT NULL,
  `user` varchar(16) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

-- 
-- Table `nodes`
-- 

DROP TABLE IF EXISTS `nodes`;
CREATE TABLE IF NOT EXISTS `nodes` (
  `hostname` varchar(256) NOT NULL,
  `state` varchar(16) NOT NULL,
  `env_id` int(10) NOT NULL,
  `date` int(10) unsigned NOT NULL,
  `user` varchar(16) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


-- --------------------------------------------------------

-- 
-- Table `rights`
-- 

DROP TABLE IF EXISTS `rights`;
CREATE TABLE IF NOT EXISTS `rights` (
  `user` varchar(30) NOT NULL,
  `node` varchar(256) NOT NULL,
  `part` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
