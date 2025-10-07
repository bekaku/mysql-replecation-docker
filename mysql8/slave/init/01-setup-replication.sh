#!/bin/bash
# Save as: slave/init/01-setup-replication.sh

set -e

echo "Waiting for master to be ready..."
until mysql -h"${MYSQL_MASTER_HOST}" -P"${MYSQL_MASTER_PORT}" -u"${MYSQL_REPLICATION_USER}" -p"${MYSQL_REPLICATION_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "Master not ready yet, waiting..."
    sleep 5
done

echo "Master is ready, configuring replication..."

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- Stop slave if it's running
    STOP SLAVE;
    
    -- Reset slave configuration
    RESET SLAVE ALL;
    
    -- Configure replication with GTID
    CHANGE MASTER TO
        MASTER_HOST='${MYSQL_MASTER_HOST}',
        MASTER_PORT=${MYSQL_MASTER_PORT},
        MASTER_USER='${MYSQL_REPLICATION_USER}',
        MASTER_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        MASTER_AUTO_POSITION=1;
    
    -- Start slave
    START SLAVE;
    
    -- Show slave status
    SHOW SLAVE STATUS\G
EOSQL

echo "Replication configured successfully!"