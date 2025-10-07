#!/bin/bash
# Save as: slave/init/01-setup-replication.sh

set -e

echo "=== MySQL 9.4 Slave Initialization ==="
echo "Waiting for master to be ready..."

# Wait for master to be ready
MAX_RETRIES=30
RETRY_COUNT=0

until mysql -h"${MYSQL_MASTER_HOST}" -P"${MYSQL_MASTER_PORT}" -u"${MYSQL_REPLICATION_USER}" -p"${MYSQL_REPLICATION_PASSWORD}" --get-server-public-key -e "SELECT 1" >/dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: Master not available after $MAX_RETRIES attempts"
        exit 1
    fi
    echo "Master not ready yet, waiting... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done

echo "✓ Master is ready, configuring replication..."

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- Stop replica if running (MySQL 9.4 uses REPLICA terminology)
    STOP REPLICA;
    
    -- Reset replica configuration
    RESET REPLICA ALL;
    
    -- Configure replication source with GTID auto-positioning
    -- MySQL 9.4 uses CHANGE REPLICATION SOURCE instead of CHANGE MASTER
    CHANGE REPLICATION SOURCE TO
        SOURCE_HOST='${MYSQL_MASTER_HOST}',
        SOURCE_PORT=${MYSQL_MASTER_PORT},
        SOURCE_USER='${MYSQL_REPLICATION_USER}',
        SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        SOURCE_AUTO_POSITION=1,
        SOURCE_CONNECT_RETRY=10,
        SOURCE_RETRY_COUNT=3,
        GET_SOURCE_PUBLIC_KEY=1;
    
    -- Start replica
    START REPLICA;
    
    -- Wait a moment for replica to start
    SELECT SLEEP(2);
    
    -- Show replica status
    SELECT '=== Replica Status ===' AS '';
    SHOW REPLICA STATUS\G
    
    -- Show key replication metrics
    SELECT '=== Replication Health ===' AS '';
    SELECT 
        SERVICE_STATE as IO_State,
        (SELECT SERVICE_STATE FROM performance_schema.replication_applier_status_by_worker LIMIT 1) as SQL_State
    FROM performance_schema.replication_connection_status;
EOSQL

echo "✓ Replication configured successfully!"
echo "✓ Slave is now replicating from master"