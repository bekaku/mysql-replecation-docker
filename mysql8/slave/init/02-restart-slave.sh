#!/bin/bash

echo "Restarting slave replication..."
sleep 10  # Wait for MySQL service to be fully up
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
STOP SLAVE;
START SLAVE;
SHOW SLAVE STATUS\G
EOF
echo "Restarting slave replication completed!"
