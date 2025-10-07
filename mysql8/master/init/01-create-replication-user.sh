#!/bin/bash
# Save as: master/init/01-create-replication-user.sh

set -e

echo "Creating replication user..."

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    CREATE USER IF NOT EXISTS '${MYSQL_REPLICATION_USER}'@'%' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_REPLICATION_PASSWORD}';
    GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPLICATION_USER}'@'%';
    FLUSH PRIVILEGES;
    
    -- Show master status for verification
    SHOW MASTER STATUS;
EOSQL

echo "Replication user created successfully!"