#!/bin/bash

echo "db-init script"

DB_ROOT_PASSWORD=$1
ETLEAP_DB_PASSWORD=$2
ETLEAP_RDS_HOSTNAME=$3
ETLEAP_DB_SUPPORT_USERNAME=$4
ETLEAP_DB_SUPPORT_PASSWORD=$5

# Create etleap-prod user for app
mysql -h$ETLEAP_RDS_HOSTNAME -uroot -p$DB_ROOT_PASSWORD >> /var/log/db-init.log 2>&1 <<EOF
CREATE DATABASE IF NOT EXISTS etleap;
CREATE USER IF NOT EXISTS 'etleap-prod'@'%' IDENTIFIED BY '$ETLEAP_DB_PASSWORD';
GRANT ALL PRIVILEGES ON etleap.* TO 'etleap-prod'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS etleap_ls_cache;
GRANT ALL PRIVILEGES ON etleap_ls_cache.* TO 'etleap-prod'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

EOF

# Create $ETLEAP_DB_SUPPORT_USERNAME user for etleap support access
# Create procedure to grant write permissions on all tables except user, saml_idp_config (read permissions), extraction_sample (no permissions)
# Create event to run procedure every 6 hours to automatically update the permissions
# User $ETLEAP_DB_SUPPORT_USERNAME will be able to call the procedure to update permissions when needed
# Note: This is a workaround for the lack of support for wildcards in GRANT statements in MySQL
# The procedure finds all tables in the etleap database (except some specific) and grants permissions to $ETLEAP_DB_SUPPORT_USERNAME

mysql -h$ETLEAP_RDS_HOSTNAME -uroot -p$DB_ROOT_PASSWORD etleap >> /var/log/db-init.log 2>&1 <<EOF

DELIMITER XXXX

DROP PROCEDURE IF EXISTS refreshSupportUserRole XXXX
CREATE PROCEDURE refreshSupportUserRole ()
  COMMENT 'Grant SELECT on new databases/tables, revoke on deleted'
BEGIN
  DECLARE done BOOL;
  DECLARE db VARCHAR(128);
  DECLARE tb VARCHAR(128);

  # Find all tables in the etleap database (to grant read permissions)
  DECLARE tables CURSOR FOR
    SELECT table_schema, table_name FROM information_schema.tables
    WHERE table_schema = 'etleap' AND
    NOT (
      table_name = 'user'
      OR table_name = 'saml_idp_config'
      OR table_name = 'extraction_sample'
    );

  # Loop should end when there are no more tables to fetch (code 02000 is NOT FOUND)
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done=true;

  CREATE USER IF NOT EXISTS '$ETLEAP_DB_SUPPORT_USERNAME'@'%' IDENTIFIED BY '$ETLEAP_DB_SUPPORT_PASSWORD';
  REVOKE ALL, GRANT OPTION FROM '$ETLEAP_DB_SUPPORT_USERNAME';

  # Grant specific read permissions to $ETLEAP_DB_SUPPORT_USERNAME
  GRANT SELECT ON etleap.user TO '$ETLEAP_DB_SUPPORT_USERNAME';
  GRANT SELECT ON etleap.saml_idp_config TO '$ETLEAP_DB_SUPPORT_USERNAME';

  OPEN tables;
  SET done = false;

  # Loop through all writable tables and grant permissions to $ETLEAP_DB_SUPPORT_USERNAME
  grant_loop: LOOP
    FETCH tables INTO db, tb;
    IF done THEN
      LEAVE grant_loop;
    END IF;
    # Grant all permissions on the table to the support user
    SET @grant_statement = CONCAT('GRANT ALL ON ', db, '.', tb, ' TO ''$ETLEAP_DB_SUPPORT_USERNAME''');
    PREPARE grant_statement FROM @grant_statement;
    EXECUTE grant_statement;
    DEALLOCATE PREPARE grant_statement;
  END LOOP;
  CLOSE tables;

  GRANT EXECUTE ON PROCEDURE refreshSupportUserRole TO '$ETLEAP_DB_SUPPORT_USERNAME'@'%';
  FLUSH PRIVILEGES;

END XXXX
DELIMITER ;

DROP EVENT IF EXISTS refresh_support_user;
CREATE EVENT refresh_support_user ON SCHEDULE every 6 HOUR DO call refreshSupportUserRole;

CALL refreshSupportUserRole;
FLUSH PRIVILEGES;
SHOW GRANTS FOR '$ETLEAP_DB_SUPPORT_USERNAME'@'%';

EOF


exit 0
