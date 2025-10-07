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