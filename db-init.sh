#!/bin/bash -e

DB_ROOT_PASSWORD=$1
ETLEAP_DB_PASSWORD=$2
SALESFORCE_DB_PASSWORD=$3
ORG_NAME=$4

mysql -hdbprod.etleap.internal -uroot -p$DB_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS etleap;
GRANT ALL PRIVILEGES ON etleap.* TO 'etleap-prod'@'%' IDENTIFIED BY "$ETLEAP_DB_PASSWORD";

CREATE DATABASE IF NOT EXISTS salesforce;
USE salesforce;
GRANT ALL PRIVILEGES ON salesforce.* TO 'salesforce'@'%' IDENTIFIED BY "$SALESFORCE_DB_PASSWORD";
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

exit 0
