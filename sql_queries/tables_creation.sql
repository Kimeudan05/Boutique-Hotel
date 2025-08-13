CREATE TABLE customers (
    CustomerID BIGINT PRIMARY KEY,
    CustomerAge BIGINT,
    CustomerGender TEXT,
    CustomerCountry TEXT
);

CREATE TABLE rooms (
    RoomNumber BIGINT PRIMARY KEY,
    Capacity BIGINT,
    RoomType TEXT,
    BasePrice BIGINT
);

CREATE TABLE orders (
    OrderID BIGINT PRIMARY KEY,
    CustomerIDs TEXT,  -- You may want to normalize this later
    CustomerCount BIGINT,
    RoomNumber BIGINT REFERENCES rooms(RoomNumber),
    CheckInDate DATE,
    CheckOutDate DATE,
    StayDuration BIGINT,
    TotalCost NUMERIC,
    PaymentMethod TEXT,
    SeasonalFactor TEXT
);

-- create staging table to manipulate insted of the database tables
-- Step 1: Clone structure (with all constraints, etc.)
CREATE TABLE customers_staging (LIKE customers INCLUDING ALL);
-- Step 2: Insert all data
INSERT INTO customers_staging SELECT * FROM customers;
--orders
CREATE TABLE orders_staging (LIKE orders INCLUDING ALL);
INSERT INTO orders_staging SELECT * FROM orders;
--rooms
CREATE TABLE rooms_staging (LIKE rooms INCLUDING ALL);
INSERT INTO rooms_staging SELECT * FROM rooms;


-- create the customer count column if does not exist
SELECT orderid, customerids, array_length(string_to_array(customerids,','),1) AS customersCOunt
FROM orders_staging
LIMIT 10

-- check what each table contains
SELECT * FROM customers_staging LIMIT 10
SELECT * FROM orders_staging LIMIT 10
SELECT * FROM orders_staging LIMIT 10