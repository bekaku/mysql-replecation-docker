#!/bin/bash
# MySQL Master initialization script
# This script creates a replication user and grants necessary privileges

# Wait for MySQL to be ready
echo "Waiting for MySQL Master to be ready..."
until mysqladmin ping -h"localhost" -u"root" -p"$MYSQL_ROOT_PASSWORD" --silent; do
    sleep 1
done

echo "Creating replication user..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE USER 'replication_user'@'%' IDENTIFIED BY '$MYSQL_REPLICATION_PASSWORD';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF

echo "Master initialization completed!"
