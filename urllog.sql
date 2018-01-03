CREATE TABLE `urls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `server` varchar(25) NOT NULL DEFAULT '<None>',
  `target` varchar(100) NOT NULL DEFAULT '<Unknown>',
  `nick` varchar(40) NOT NULL DEFAULT '<Unknown>',
  `url` text NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fullline` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10108 DEFAULT CHARSET=latin1;
