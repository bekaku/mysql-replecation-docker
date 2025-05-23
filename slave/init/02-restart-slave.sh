#!/bin/bash

echo "Restarting slave replication..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
STOP SLAVE;
START SLAVE;
SHOW SLAVE STATUS\G
EOF
echo "Restarting slave replication completed!"
