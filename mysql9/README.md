# MySQL9 Master-Slave Replication with Docker Compose

This repository contains all the necessary files to set up a MySQL9 Master-Slave replication environment using Docker Compose.

## Quick Start

1. Clone or download this repository
2. Create a `.env` file with your desired passwords (optional)
3. Run `chmod +x master/init/01-create-replication-user.sh slave/init/01-configure-slave.sh`
4. Run `docker-compose up -d`
5. Verify replication with `docker-compose exec mysql-slave mysql -uroot -p -e "SHOW SLAVE REPLICA"`

## Files Included

- `docker-compose.yml` - Docker Compose configuration file
- `master/conf.d/replication.cnf` - MySQL Master configuration
- `slave/conf.d/replication.cnf` - MySQL Slave configuration
- `master/init/01-create-replication-user.sh` - Master initialization script
- `slave/init/01-setup-replication.sh` - Slave initialization script

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
If using VS Code → open the file `master/init/01-create-replication-user.sh` and `slave/init/01-setup-replication.sh` → look at bottom-right corner → click CRLF → choose LF.

```bash
chmod +x master/init/01-create-replication-user.sh
chmod +x slave/init/01-setup-replication.sh
chmod +x slave/init/02-restart-slave.sh
```

- (Windows only) Right click /master/conf.d/replication.cnf > properties > uncheck Read only 

- (Windows only) Right click /slave/conf.d/replication.cnf > properties > uncheck Read only 
- Edit /slave/conf.d/replication.cnf comment out this two lines 
`#read_only = ON`
`#super_read_only = ON`
- (Windows only) Right click /slave/conf.d/replication.cnf > properties > check Read only 

1. run docker
```bash
docker-compose up -d
```

Waits for the MySQL service to be ready from master and slave

- (Windows only) Right click /slave/conf.d/replication.cnf > properties > uncheck Read only 
- Edit /slave/conf.d/replication.cnf uncomment this two lines 
`read_only = ON`
`super_read_only = ON`
- (Windows only) Right click /slave/conf.d/replication.cnf > properties > check Read only 

2. Restart slave container
```bash
docker-compose restart mysql-slave
```

3. Restart slave service
```bash
docker exec -it mysql-slave bash /docker-entrypoint-initdb.d/02-restart-slave.sh
```

4. verify the replication status by connecting to the slave container and checking the replication status

```bash
docker-compose exec mysql-slave mysql -uroot -p -e "SHOW REPLICA STATUS"
```

5. test slave sync data from master
```bash
#!/bin/bash

# 1. Create table on master
docker exec -it mysql-master mysql -uroot -p -D appdb -e "
CREATE TABLE test_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_products (name, price) VALUES 
    ('Product 1', 99.99),
    ('Product 2', 149.99),
    ('Product 3', 199.99);
"

# 2. Wait 2 seconds, then check on slave
sleep 2
docker exec -it mysql-slave mysql -uroot -p -D appdb -e "SELECT * FROM test_products;"

# 3. Verify counts match
docker exec -it mysql-master mysql -uroot -p -D appdb -e "SELECT COUNT(*) FROM test_products;"
docker exec -it mysql-slave mysql -uroot -p -D appdb -e "SELECT COUNT(*) FROM test_products;"
```

6. shutdown docker
```bash
docker-compose down
```

7. shutdown docker and remove all vulumes
```bash
docker-compose down -v
```



