# MySQL8 Master-Slave Replication Setup Guide Using Docker Compose

This comprehensive guide will walk you through setting up a MySQL8 Master-Slave replication environment using Docker Compose. MySQL replication allows data from one MySQL database server (the master) to be copied automatically to one or more MySQL database servers (the slaves). This setup provides data redundancy, improves read performance through load distribution, and enables data backup operations without disrupting the master server.

## Prerequisites

Before beginning this setup, ensure you have the following prerequisites installed on your system:

- Docker Engine (version 19.03.0+)
- Docker Compose (version 1.27.0+)
- Basic understanding of MySQL and Docker concepts

The setup described in this guide has been tested on Linux, macOS, and Windows environments with Docker Desktop.

## Project Structure

Our MySQL replication setup consists of the following directory structure:

```
mysql-replication/
├── docker-compose.yml
├── .env (optional)
├── master/
│   ├── conf.d/
│   │   └── master.cnf
│   └── init/
│       └── 01-create-replication-user.sh
└── slave/
    ├── conf.d/
    │   └── slave.cnf
    └── init/
        └── 01-configure-slave.sh
```

The `docker-compose.yml` file defines our services, while the configuration files in the `conf.d` directories contain MySQL-specific settings. The initialization scripts in the `init` directories are executed when the containers first start, setting up replication.

## Understanding the Configuration

### Docker Compose Configuration

Our `docker-compose.yml` file defines two services: `mysql_master` and `mysql_slave`. Both services use the official MySQL 8.0 image, with specific port mappings, volume mounts, and network configurations. The master exposes port 3307 on the host, while the slave exposes port 3308, allowing you to connect to each instance separately.

The services are configured with environment variables for setting the root password, creating an initial database, and a regular user. These variables can be customized through a `.env` file or by modifying the Docker Compose file directly.

Health checks are implemented to ensure services are fully operational before dependencies are established. The slave service depends on the master, ensuring the master is healthy before the slave attempts to connect.

### Master Configuration

The master configuration (`master.cnf`) includes several important settings:

- `server-id = 1`: A unique identifier for the master server
- `log_bin = mysql-bin`: Enables binary logging, which is essential for replication
- `binlog_format = ROW`: Uses row-based replication for better data consistency
- `gtid_mode = ON`: Enables Global Transaction Identifier (GTID) based replication
- `enforce_gtid_consistency = ON`: Ensures transactions are GTID-compatible

These settings ensure that all changes to the master database are properly logged and can be replicated to the slave.

### Slave Configuration

The slave configuration (`slave.cnf`) includes complementary settings:

- `server-id = 2`: A unique identifier different from the master
- `read_only = ON` and `super_read_only = ON`: Prevents direct writes to the slave
- `gtid_mode = ON`: Matches the master's GTID configuration
- `slave_skip_errors = 1062`: Optionally skips duplicate entry errors

These settings ensure the slave can properly receive and apply changes from the master while preventing direct modifications that could break replication.

## Initialization Scripts

### Master Initialization

The master initialization script (`01-create-replication-user.sh`) creates a dedicated user for replication with appropriate privileges. This script:

1. Waits for the MySQL service to be ready
2. Creates a 'replication_user' with the password specified in environment variables
3. Grants the necessary REPLICATION SLAVE and REPLICATION CLIENT privileges
4. Displays the current master status for reference

### Slave Initialization

The slave initialization script (`01-configure-slave.sh`) configures the slave to connect to the master and begin replication. This script:

1. Waits for the MySQL slave service to be ready using mysqladmin
2. Waits for the MySQL master service to be available by checking connectivity with mysqladmin
3. Configures the slave to connect to the master using the replication user credentials
4. Enables GTID-based auto-positioning for replication
5. Starts the replication process
6. Displays the slave status for verification

## Setting Up the Environment

To set up the MySQL8 Master-Slave replication environment, follow these steps:

### Step 1: Create the Project Directory Structure

First, create the project directory structure as described earlier. You can use the following commands:

```bash
mkdir -p mysql-replication/{master,slave}/{conf.d,init}
cd mysql-replication
```

### Step 2: Create Configuration Files

Create the Docker Compose file and MySQL configuration files as described in this guide. You can use a text editor to create these files in their respective directories.

### Step 3: Create Environment Variables (Optional)

For better security, create a `.env` file in the project root directory to store sensitive information:

```
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=your_database_name
MYSQL_USER=your_regular_user
MYSQL_PASSWORD=your_regular_user_password
MYSQL_REPLICATION_PASSWORD=your_replication_password
```

### Step 4: Make Initialization Scripts Executable

Ensure that the initialization scripts have executable permissions:

```bash
chmod +x master/init/01-create-replication-user.sh
chmod +x slave/init/01-configure-slave.sh
```

### Step 5: Start the Services

Start the MySQL master and slave services using Docker Compose:

```bash
docker-compose up -d
```

Docker Compose will create the necessary networks, volumes, and containers based on your configuration. The `-d` flag runs the containers in detached mode (background).

### Step 6: Verify Replication Status

After the containers have started and the initialization scripts have run, you can verify the replication status by connecting to the slave container and checking the replication status:

```bash
docker-compose exec mysql_slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"
```

When prompted, enter the root password you specified. In the output, look for:

- `Slave_IO_Running: Yes`
- `Slave_SQL_Running: Yes`

These indicate that replication is working correctly.

## Testing Replication

To test that replication is working properly, you can create a table and insert data on the master, then verify that the changes are replicated to the slave:

### On the Master:

```bash
docker-compose exec mysql_master mysql -uroot -p -e "USE your_database_name; CREATE TABLE test (id INT, name VARCHAR(100)); INSERT INTO test VALUES (1, 'Test Replication');"
```

### On the Slave:

```bash
docker-compose exec mysql_slave mysql -uroot -p -e "USE your_database_name; SELECT * FROM test;"
```

If replication is working correctly, you should see the table and data that you created on the master.

## Troubleshooting

### Replication Not Starting

If replication doesn't start properly, check the following:

1. Verify that both containers are running:
   ```bash
   docker-compose ps
   ```

2. Check the logs for any errors:
   ```bash
   docker-compose logs mysql_master
   docker-compose logs mysql_slave
   ```

3. Ensure the replication user was created correctly on the master:
   ```bash
   docker-compose exec mysql_master mysql -uroot -p -e "SELECT User, Host FROM mysql.user WHERE User='replication_user';"
   ```

4. Verify network connectivity between containers:
   ```bash
   docker-compose exec mysql_slave ping mysql_master
   ```

### Replication Errors

If replication starts but then encounters errors:

1. Check the slave status for specific error messages:
   ```bash
   docker-compose exec mysql_slave mysql -uroot -p -e "SHOW SLAVE STATUS\G"
   ```

2. If needed, reset the slave and restart replication:
   ```bash
   docker-compose exec mysql_slave mysql -uroot -p -e "STOP SLAVE; RESET SLAVE; START SLAVE;"
   ```

## Advanced Configuration

### Adding More Slaves

To add more slave instances, you can extend your Docker Compose file with additional slave services. Ensure each slave has a unique `server-id` in its configuration file.

### Implementing Semi-Synchronous Replication

For stronger durability guarantees, you can implement semi-synchronous replication by adding the following to your master configuration:

```
plugin-load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
rpl_semi_sync_master_enabled = 1
rpl_semi_sync_master_timeout = 10000
```

And to your slave configuration:

```
plugin-load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
rpl_semi_sync_slave_enabled = 1
```

### Backup Considerations

When performing backups of your replicated environment, consider using the slave for backup operations to avoid impacting the performance of the master. You can temporarily stop replication during the backup:

```bash
docker-compose exec mysql_slave mysql -uroot -p -e "STOP SLAVE;"
# Perform backup operations
docker-compose exec mysql_slave mysql -uroot -p -e "START SLAVE;"
```

## Conclusion

You have successfully set up MySQL8 Master-Slave replication using Docker Compose. This configuration provides a solid foundation for database redundancy and improved read performance. The use of Docker Compose makes it easy to deploy and manage this setup in various environments.

Remember to monitor your replication setup regularly and implement proper backup strategies to ensure data integrity and availability. As your needs grow, you can extend this setup with additional slaves or more advanced replication configurations.

For production environments, consider implementing additional security measures, such as secure password management, network isolation, and regular security updates.
