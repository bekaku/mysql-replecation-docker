#!/bin/bash

docker exec -it mysql-slave bash /docker-entrypoint-initdb.d/02-restart-slave.sh