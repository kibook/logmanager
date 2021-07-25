CREATE TABLE logmanager_log (
	id INT NOT NULL AUTO_INCREMENT,
	time DATETIME NOT NULL,
	resource VARCHAR(255),
	player_name VARCHAR(255),
	message VARCHAR(255),
	PRIMARY KEY (id)
);

CREATE TABLE logmanager_log_identifier (
	id INT NOT NULL AUTO_INCREMENT,
	log_id INT NOT NULL,
	identifier VARCHAR(255) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY logmanager_log (id)
);
