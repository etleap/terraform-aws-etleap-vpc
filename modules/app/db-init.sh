#!/bin/bash

echo "db-init script"

DB_ROOT_PASSWORD=$1
ETLEAP_DB_PASSWORD=$2
SALESFORCE_DB_PASSWORD=$3
ORG_NAME=$4
ETLEAP_RDS_HOSTNAME=$5
ETLEAP_DB_SUPPORT_PASSWORD=$6

# Create etleap-prod user for app
mysql -h$ETLEAP_RDS_HOSTNAME -uroot -p$DB_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS etleap;
CREATE USER IF NOT EXISTS 'etleap-prod'@'%' IDENTIFIED BY '$ETLEAP_DB_PASSWORD';
GRANT ALL PRIVILEGES ON etleap.* TO 'etleap-prod'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS etleap_ls_cache;
GRANT ALL PRIVILEGES ON etleap_ls_cache.* TO 'etleap-prod'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS salesforce;
USE salesforce;
CREATE USER IF NOT EXISTS 'salesforce'@'%' IDENTIFIED BY '$SALESFORCE_DB_PASSWORD';
GRANT ALL PRIVILEGES ON salesforce.* TO 'salesforce'@'%' WITH GRANT OPTION;
CREATE TABLE IF NOT EXISTS jobs (id bigint(20) NOT NULL AUTO_INCREMENT,
  user_hash varchar(64) NOT NULL,
  job_id varchar(64) NOT NULL,
  first_batch_id varchar(64),
  query_hash varchar(64) NOT NULL,
  bulk_api_calls int(11) NOT NULL,
  failed tinyint(1) NOT NULL DEFAULT 0,
  create_date datetime NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (user_hash, job_id),
  INDEX user_hash_create_date (user_hash, create_date)
) ENGINE=InnoDB;

FLUSH PRIVILEGES;

EOF

# Create etleap_support user for etleap support
mysql -h$ETLEAP_RDS_HOSTNAME -uroot -p$DB_ROOT_PASSWORD etleap <<EOF

DELIMITER $$

DROP PROCEDURE IF EXISTS refreshRoles $$
CREATE PROCEDURE refreshRoles ()
  COMMENT 'Grant SELECT on new databases/tables, revoke on deleted'
BEGIN
  DECLARE done BOOL;
  DECLARE db VARCHAR(128);
  DECLARE tb VARCHAR(128);
  DECLARE rl VARCHAR(128);
  DECLARE tables CURSOR FOR
    SELECT table_schema, table_name, 'etleap_support' FROM information_schema.tables
    WHERE table_schema = 'etleap' AND
    NOT (
      table_name = 'user'
      OR table_name = 'saml_idp_config'
      OR table_name = 'extraction_sample'
    );

  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done=true;

  CREATE USER IF NOT EXISTS 'etleap_support'@'%' IDENTIFIED BY '$ETLEAP_DB_SUPPORT_PASSWORD';
  REVOKE ALL, GRANT OPTION FROM 'etleap_support';

  OPEN tables;
  SET done = false;
  grant_loop: LOOP
    FETCH tables INTO db, tb, rl;
    IF done THEN
      LEAVE grant_loop;
    END IF;
    SET @g = CONCAT('GRANT ALL ON ', db, '.', tb, ' TO ', rl);
    PREPARE g FROM @g;
    EXECUTE g;
    DEALLOCATE PREPARE g;
  END LOOP;
  CLOSE tables;

  GRANT SELECT ON etleap.user TO etleap_support;
  GRANT SELECT ON etleap.saml_idp_config TO etleap_support;

END $$
DELIMITER ;

CALL refreshRoles;
FLUSH PRIVILEGES;
SHOW GRANTS FOR  'etleap_support'@'%';

EOF


exit 0
