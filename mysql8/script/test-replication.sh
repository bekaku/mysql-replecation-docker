#!/bin/bash
# test-replication.sh - Complete replication testing script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-secure_root_password}
MYSQL_DATABASE=${MYSQL_DATABASE:-appdb}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MySQL Replication Test Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to execute SQL on master
exec_master() {
    docker exec -i mysql-master mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D"${MYSQL_DATABASE}" -e "$1"
}

# Function to execute SQL on slave
exec_slave() {
    docker exec -i mysql-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D"${MYSQL_DATABASE}" -e "$1"
}

# Function to check container health
check_health() {
    echo -e "${YELLOW}Step 1: Checking container health...${NC}"
    
    MASTER_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' mysql-master 2>/dev/null || echo "not found")
    SLAVE_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' mysql-slave 2>/dev/null || echo "not found")
    
    echo "Master status: $MASTER_HEALTH"
    echo "Slave status: $SLAVE_HEALTH"
    
    if [ "$MASTER_HEALTH" != "healthy" ] || [ "$SLAVE_HEALTH" != "healthy" ]; then
        echo -e "${RED}Containers are not healthy! Please wait or check logs.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Both containers are healthy${NC}\n"
}

# Function to check replication status
check_replication() {
    echo -e "${YELLOW}Step 2: Checking replication status...${NC}"
    
    docker exec mysql-master mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS\G" 2>/dev/null
    echo ""
    
    SLAVE_STATUS=$(docker exec mysql-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" 2>/dev/null)
    echo "$SLAVE_STATUS"
    
    IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{print $2}')
    SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{print $2}')
    
    if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
        echo -e "${GREEN}✓ Replication is running correctly${NC}\n"
    else
        echo -e "${RED}✗ Replication is not running properly!${NC}"
        echo "Slave_IO_Running: $IO_RUNNING"
        echo "Slave_SQL_Running: $SQL_RUNNING"
        exit 1
    fi
}

# Function to create test tables
create_tables() {
    echo -e "${YELLOW}Step 3: Creating test tables on master...${NC}"
    
    exec_master "
    DROP TABLE IF EXISTS users;
    DROP TABLE IF EXISTS orders;
    DROP TABLE IF EXISTS products;
    
    CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_username (username),
        INDEX idx_email (email)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    CREATE TABLE products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        stock INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_name (name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    CREATE TABLE orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id),
        INDEX idx_user_id (user_id),
        INDEX idx_order_date (order_date)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    "
    
    echo -e "${GREEN}✓ Tables created on master${NC}\n"
    sleep 2
}

# Function to insert test data
insert_data() {
    echo -e "${YELLOW}Step 4: Inserting test data on master...${NC}"
    
    exec_master "
    -- Insert users
    INSERT INTO users (username, email) VALUES
        ('john_doe', 'john@example.com'),
        ('jane_smith', 'jane@example.com'),
        ('bob_wilson', 'bob@example.com'),
        ('alice_johnson', 'alice@example.com'),
        ('charlie_brown', 'charlie@example.com');
    
    -- Insert products
    INSERT INTO products (name, price, stock) VALUES
        ('Laptop Pro', 1299.99, 50),
        ('Wireless Mouse', 29.99, 200),
        ('Mechanical Keyboard', 89.99, 150),
        ('USB-C Hub', 49.99, 100),
        ('Monitor 27\"', 399.99, 75),
        ('Webcam HD', 79.99, 120),
        ('Headphones', 149.99, 90),
        ('Desk Lamp', 39.99, 180),
        ('Phone Stand', 19.99, 250),
        ('Cable Organizer', 12.99, 300);
    
    -- Insert orders
    INSERT INTO orders (user_id, product_id, quantity, total_price) VALUES
        (1, 1, 1, 1299.99),
        (1, 2, 2, 59.98),
        (2, 3, 1, 89.99),
        (2, 5, 1, 399.99),
        (3, 6, 1, 79.99),
        (4, 7, 1, 149.99),
        (4, 8, 2, 79.98),
        (5, 9, 3, 59.97),
        (5, 10, 5, 64.95);
    "
    
    echo -e "${GREEN}✓ Test data inserted on master${NC}\n"
    sleep 3
}

# Function to verify replication
verify_replication() {
    echo -e "${YELLOW}Step 5: Verifying data on slave...${NC}"
    
    echo -e "\n${BLUE}Users on MASTER:${NC}"
    exec_master "SELECT id, username, email FROM users;"
    
    echo -e "\n${BLUE}Users on SLAVE:${NC}"
    exec_slave "SELECT id, username, email FROM users;"
    
    echo -e "\n${BLUE}Products on MASTER:${NC}"
    exec_master "SELECT id, name, price, stock FROM products LIMIT 5;"
    
    echo -e "\n${BLUE}Products on SLAVE:${NC}"
    exec_slave "SELECT id, name, price, stock FROM products LIMIT 5;"
    
    echo -e "\n${BLUE}Orders on MASTER:${NC}"
    exec_master "SELECT id, user_id, product_id, quantity, total_price FROM orders;"
    
    echo -e "\n${BLUE}Orders on SLAVE:${NC}"
    exec_slave "SELECT id, user_id, product_id, quantity, total_price FROM orders;"
    
    # Count records
    MASTER_USERS=$(exec_master "SELECT COUNT(*) as count FROM users;" | tail -1)
    SLAVE_USERS=$(exec_slave "SELECT COUNT(*) as count FROM users;" | tail -1)
    
    MASTER_PRODUCTS=$(exec_master "SELECT COUNT(*) as count FROM products;" | tail -1)
    SLAVE_PRODUCTS=$(exec_slave "SELECT COUNT(*) as count FROM products;" | tail -1)
    
    MASTER_ORDERS=$(exec_master "SELECT COUNT(*) as count FROM orders;" | tail -1)
    SLAVE_ORDERS=$(exec_slave "SELECT COUNT(*) as count FROM orders;" | tail -1)
    
    echo -e "\n${BLUE}Record counts:${NC}"
    echo "Users - Master: $MASTER_USERS, Slave: $SLAVE_USERS"
    echo "Products - Master: $MASTER_PRODUCTS, Slave: $SLAVE_PRODUCTS"
    echo "Orders - Master: $MASTER_ORDERS, Slave: $SLAVE_ORDERS"
    
    if [ "$MASTER_USERS" = "$SLAVE_USERS" ] && [ "$MASTER_PRODUCTS" = "$SLAVE_PRODUCTS" ] && [ "$MASTER_ORDERS" = "$SLAVE_ORDERS" ]; then
        echo -e "${GREEN}✓ Data replicated successfully!${NC}\n"
    else
        echo -e "${RED}✗ Data mismatch detected!${NC}\n"
        exit 1
    fi
}

# Function to test real-time replication
test_realtime() {
    echo -e "${YELLOW}Step 6: Testing real-time replication...${NC}"
    
    echo "Inserting new record on master..."
    exec_master "INSERT INTO users (username, email) VALUES ('test_user', 'test@example.com');"
    
    sleep 2
    
    echo -e "\n${BLUE}Checking if new record appears on slave:${NC}"
    SLAVE_TEST=$(exec_slave "SELECT username FROM users WHERE username='test_user';" | tail -1)
    
    if [ "$SLAVE_TEST" = "test_user" ]; then
        echo -e "${GREEN}✓ Real-time replication working!${NC}\n"
    else
        echo -e "${RED}✗ Real-time replication failed!${NC}\n"
        exit 1
    fi
}

# Function to test updates
test_updates() {
    echo -e "${YELLOW}Step 7: Testing UPDATE operations...${NC}"
    
    echo "Updating product price on master..."
    exec_master "UPDATE products SET price = 1399.99 WHERE name = 'Laptop Pro';"
    
    sleep 2
    
    echo -e "\n${BLUE}Checking updated price on slave:${NC}"
    SLAVE_PRICE=$(exec_slave "SELECT price FROM products WHERE name = 'Laptop Pro';" | tail -1)
    
    if [ "$SLAVE_PRICE" = "1399.99" ]; then
        echo -e "${GREEN}✓ UPDATE replication working!${NC}\n"
    else
        echo -e "${RED}✗ UPDATE replication failed!${NC}\n"
        exit 1
    fi
}

# Function to test deletes
test_deletes() {
    echo -e "${YELLOW}Step 8: Testing DELETE operations...${NC}"
    
    echo "Deleting a user on master..."
    exec_master "DELETE FROM users WHERE username = 'test_user';"
    
    sleep 2
    
    echo -e "\n${BLUE}Checking if record deleted on slave:${NC}"
    SLAVE_COUNT=$(exec_slave "SELECT COUNT(*) as count FROM users WHERE username='test_user';" | tail -1)
    
    if [ "$SLAVE_COUNT" = "0" ]; then
        echo -e "${GREEN}✓ DELETE replication working!${NC}\n"
    else
        echo -e "${RED}✗ DELETE replication failed!${NC}\n"
        exit 1
    fi
}

# Function to show summary
show_summary() {
    echo -e "${YELLOW}Step 9: Replication lag check...${NC}"
    docker exec mysql-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep -E "Seconds_Behind_Master|Slave_IO_Running|Slave_SQL_Running"
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}All tests passed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\nYour MySQL replication setup is working correctly."
    echo -e "Master: localhost:3306"
    echo -e "Slave: localhost:3307"
}

# Main execution
main() {
    check_health
    check_replication
    create_tables
    insert_data
    verify_replication
    test_realtime
    test_updates
    test_deletes
    show_summary
}

# Run main function
main