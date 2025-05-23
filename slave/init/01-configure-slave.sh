#!/bin/bash
# MySQL Slave initialization script
# This script configures the slave to connect to the master

# Wait for MySQL to be ready
echo "Waiting for MySQL Slave to be ready..."
until mysqladmin ping -h"localhost" -u"root" -p"$MYSQL_ROOT_PASSWORD" --silent; do
    sleep 1
done

# Wait for master to be available
echo "Waiting for MySQL Master to be available..."
# Use mysqladmin to check master availability instead of nc
until mysqladmin ping -h"mysql_master" -u"root" -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null; do
    echo "Master not available yet, waiting..."
    sleep 3
done

sleep 3

# Enable read-only before replication
#echo "Enabling read-only mode before replication setup..."
#mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
#SET GLOBAL read_only = ON;
#SET GLOBAL super_read_only = ON;
#EOF
#sleep 3

echo "Configuring replication on slave..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CHANGE MASTER TO
  MASTER_HOST='mysql_master',
  MASTER_PORT=3306,
  MASTER_USER='replication_user',
  MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD',
  MASTER_AUTO_POSITION=1;
  
STOP SLAVE;
START SLAVE;
SHOW SLAVE STATUS\G
EOF

echo "Slave initialization completed!"
