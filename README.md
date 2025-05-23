# MySQL8 Master-Slave Replication with Docker Compose

This repository contains all the necessary files to set up a MySQL8 Master-Slave replication environment using Docker Compose.

## Quick Start

1. Clone or download this repository
2. Create a `.env` file with your desired passwords (optional)
3. Run `chmod +x master/init/01-create-replication-user.sh slave/init/01-configure-slave.sh`
4. Run `docker-compose up -d`
5. Verify replication with `docker-compose exec mysql_slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"`

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

For detailed instructions, please refer to the `mysql_replication_guide.md` file.

Linux only
Ensure that the initialization scripts have executable permissions:

```bash
chmod +x master/init/01-create-replication-user.sh
chmod +x slave/init/01-configure-slave.sh
```


1. Edit docker-compose.yml comment out this line 
`#- ./slave/init:/docker-entrypoint-initdb.d` from mysql_slave service 


2. (Windows only) Right click /slave/conf.d/slave.cnf > properties > uncheck Read only 
3. Edit /slave/conf.d/slave.cnf comment out this two lines 
`#read_only = ON`
`#super_read_only = ON`
4. (Windows only) Right click /slave/conf.d/slave.cnf > properties > check Read only 

3. run docker
```bash
docker-compose up -d
```

Waits for the MySQL service to be ready from master and slave


4. shutdown docker
```bash
docker-compose down
```

5. Edit docker-compose.yml uncomment out this line
`- ./slave/init:/docker-entrypoint-initdb.d` from mysql_slave service 


6. (Windows only) Right click /slave/conf.d/slave.cnf > properties > uncheck Read only 

7. Edit /slave/conf.d/slave.cnf comment out this two lines 
`read_only = ON`
`super_read_only = ON`
8. (Windows only) Right click /slave/conf.d/slave.cnf > properties > check Read only 


8. run docker again
```bash
docker-compose down
```

8. Run configure slave 
```bash
docker-compose exec mysql_slave sh /docker-entrypoint-initdb.d/01-configure-slave.sh
```

9. verify the replication status by connecting to the slave container and checking the replication status

```bash
docker-compose exec mysql_slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"
```