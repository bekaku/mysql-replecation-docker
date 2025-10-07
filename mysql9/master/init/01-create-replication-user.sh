#!/bin/bash
# Save as: master/init/01-create-replication-user.sh

set -e

echo "=== MySQL 9.4 Master Initialization ==="
echo "Creating replication user with caching_sha2_password..."

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- Create replication user with caching_sha2_password (MySQL 9.4 default)
    CREATE USER IF NOT EXISTS '${MYSQL_REPLICATION_USER}'@'%' 
        IDENTIFIED WITH caching_sha2_password BY '${MYSQL_REPLICATION_PASSWORD}';
    
    -- Grant replication privileges
    GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPLICATION_USER}'@'%';
    
    -- Grant additional monitoring privileges (useful for MySQL 9.4)
    GRANT REPLICATION CLIENT ON *.* TO '${MYSQL_REPLICATION_USER}'@'%';
    
    -- Flush privileges
    FLUSH PRIVILEGES;
    
    -- Show master status
    SELECT '=== Master Status ===' AS '';
    SHOW BINARY LOG STATUS;
    
    -- Show GTID executed set
    SELECT '=== GTID Executed ===' AS '';
    SELECT @@GLOBAL.gtid_executed AS gtid_executed;
    
    -- Show binary log info
    SELECT '=== Binary Logs ===' AS '';
    SHOW BINARY LOGS;
EOSQL

echo "✓ Replication user created successfully!"
echo "✓ Master is ready for replication"