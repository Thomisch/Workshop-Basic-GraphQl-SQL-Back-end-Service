-- Création de la base de données et de la table si elle n'existe pas
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10, 2)
);

-- Insertion de données fictives
INSERT INTO products (name, price) VALUES
('Laptop', 999.99),
('Smartphone', 699.99),
('Headphones', 149.99),
('Monitor', 299.99),
('Something', 99.99),
('Something else', 199.99),
('Another thing', 299.99),
('Another thing else', 399.99),
('Yet another thing', 499.99),
('Yet another thing else', 599.99),
('And another thing', 699.99),
('And another thing else', 799.99),
('One more thing', 899.99),
('One more thing else', 999.99),
('The last thing', 1099.99),
('The last thing else', 1199.99),
('The very last thing', 1299.99),
('The very last thing else', 1399.99),
('The very very last thing', 1499.99),
('The very very last thing else', 1599.99),
('The very very very last thing', 1699.99),
('The very very very last thing else', 1799.99),
('The very very very very last thing', 1899.99),
('The very very very very last thing else', 1999.99),
('The very very very very very last thing', 2099.99),
('The very very very very very last thing else', 2199.99),
('The very very very very very very last thing', 2299.99),
('The very very very very very very last thing else', 2399.99),
('The very very very very very very very last thing', 2499.99),
('The very very very very very very very last thing else', 2599.99),
('The very very very very very very very very last thing', 2699.99),
('The very very very very very very very very last thing else', 2799.99),
('The very very very very very very very very very last thing', 2899.99),
('The very very very very very very very very very last thing else', 2999.99);
