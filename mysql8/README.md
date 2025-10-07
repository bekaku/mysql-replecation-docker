# MySQL8 Master-Slave Replication with Docker Compose

This repository contains all the necessary files to set up a MySQL8 Master-Slave replication environment using Docker Compose.

## Quick Start

1. Clone or download this repository
2. Create a `.env` file with your desired passwords (optional)
3. Run `chmod +x master/init/01-create-replication-user.sh slave/init/01-configure-slave.sh`
4. Run `docker-compose up -d`
5. Verify replication with `docker-compose exec mysql-slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"`

## Files Included

- `docker-compose.yml` - Docker Compose configuration file
- `master/conf.d/master.cnf` - MySQL Master configuration
- `slave/conf.d/slave.cnf` - MySQL Slave configuration
- `master/init/01-create-replication-user.sh` - Master initialization script
- `slave/init/01-configure-slave.sh` - Slave initialization script
- `mysql_replication_guide.md` - Comprehensive setup guide

## Environment Variables

Create a `.env` file with the following variables:

```
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=your_database_name
MYSQL_USER=your_regular_user
MYSQL_PASSWORD=your_regular_user_password
MYSQL_REPLICATION_PASSWORD=your_replication_password
```

## Detailed Documentation

Linux only
Ensure that the initialization scripts have executable permissions:
If using VS Code → open the file `master/init/01-create-replication-user.sh` and `slave/init/01-configure-slave.sh` → look at bottom-right corner → click CRLF → choose LF.

```bash
chmod +x master/init/01-create-replication-user.sh
chmod +x slave/init/01-configure-slave.sh
chmod +x slave/init/02-restart-slave.sh
```

1. run docker
```bash
docker-compose up -d
```

Waits for the MySQL service to be ready from master and slave

2. Restart slave service
```bash
docker exec -it mysql-slave bash /docker-entrypoint-initdb.d/02-restart-slave.sh
```

3. verify the replication status by connecting to the slave container and checking the replication status

```bash
docker-compose exec mysql-slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"
```

4. shutdown docker
```bash
docker-compose down
```

5. shutdown docker and remove all vulumes
```bash
docker-compose down -v
```



