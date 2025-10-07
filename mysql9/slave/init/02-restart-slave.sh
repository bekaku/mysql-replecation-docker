#!/bin/bash

echo "Restarting slave replication..."
sleep 3  # Wait for MySQL service to be fully up
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
STOP REPLICA;
START REPLICA;
SHOW REPLICA STATUS;
EOF
echo "Restarting slave replication completed!"
