-- ==========================================================
-- POWER BI ANALYTICS VIEWS (BASED ON YOUR REAL TABLE SCHEMA)
-- ==========================================================

-- 1. Distribution of Customers by Age Group
CREATE OR REPLACE VIEW vw_customer_age_groups AS
SELECT 
    CASE 
        WHEN CustomerAge < 18 THEN 'Under 18'
        WHEN CustomerAge BETWEEN 18 AND 30 THEN '18-30'
        WHEN CustomerAge BETWEEN 31 AND 45 THEN '31-45'
        WHEN CustomerAge BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS number_of_customers
FROM customers_staging
GROUP BY age_group;

-- 2. Distribution of Customers by Gender
CREATE OR REPLACE VIEW vw_customer_gender_distribution AS
SELECT 
    CustomerGender,
    COUNT(*) AS number_of_customers
FROM customers_staging
GROUP BY CustomerGender;

-- 3. Distribution of Customers by Country
CREATE OR REPLACE VIEW vw_customer_country_distribution AS
SELECT 
    CustomerCountry,
    COUNT(*) AS number_of_customers
FROM customers_staging
GROUP BY CustomerCountry;

-- 4. Revenue per Room Type
CREATE OR REPLACE VIEW vw_revenue_per_room_type AS
SELECT 
    r.RoomType,
    SUM(o.TotalCost) AS total_revenue
FROM orders_staging o
JOIN rooms_staging r 
    ON o.RoomNumber = r.RoomNumber
GROUP BY r.RoomType;

-- 5. Average Stay Duration per Room Type
CREATE OR REPLACE VIEW vw_avg_stay_per_room_type AS
SELECT 
    r.RoomType,
    ROUND(AVG(o.StayDuration), 2) AS avg_stay_days
FROM orders_staging o
JOIN rooms_staging r 
    ON o.RoomNumber = r.RoomNumber
GROUP BY r.RoomType;

-- 6. Revenue by Payment Method
CREATE OR REPLACE VIEW vw_revenue_by_payment_method AS
SELECT 
    PaymentMethod,
    SUM(TotalCost) AS total_revenue
FROM orders_staging
GROUP BY PaymentMethod;

-- 7. Occupancy Rate per Room
CREATE OR REPLACE VIEW vw_occupancy_rate_per_room AS
WITH booking_days AS (
    SELECT 
        RoomNumber,
        SUM(StayDuration) AS total_days_booked
    FROM orders_staging
    GROUP BY RoomNumber
),
total_days AS (
    SELECT 
        MIN(CheckInDate) AS min_date,
        MAX(CheckOutDate) AS max_date
    FROM orders_staging
)
SELECT 
    r.RoomNumber,
    r.RoomType,
    ROUND(
        b.total_days_booked::NUMERIC / 
        NULLIF((td.max_date - td.min_date), 0) * 100, 2
    ) AS occupancy_rate_percent
FROM booking_days b
JOIN rooms_staging r 
    ON b.RoomNumber = r.RoomNumber
CROSS JOIN total_days td;


-- 8. Seasonal Booking Trends
CREATE OR REPLACE VIEW vw_seasonal_booking_trends AS
SELECT 
    SeasonalFactor,
    COUNT(*) AS total_bookings,
    SUM(TotalCost) AS total_revenue
FROM orders_staging
GROUP BY SeasonalFactor;

-- 9. Top Countries by Revenue (handles multi-customer bookings)
CREATE OR REPLACE VIEW vw_top_countries_by_revenue AS
SELECT 
    c.CustomerCountry,
    SUM(o.TotalCost / array_length(string_to_array(o.CustomerIDs, ','), 1)) AS total_revenue
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.CustomerIDs, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.CustomerID = cust_id::int
GROUP BY c.CustomerCountry;


-- 10 ) The master view
CREATE OR REPLACE VIEW vw_master_bookings AS
SELECT 
    o.OrderID,
    c.CustomerID,
    c.CustomerAge,
    CASE 
        WHEN c.CustomerAge < 18 THEN 'Under 18'
        WHEN c.CustomerAge <= 30 THEN '18 - 30'
        WHEN c.CustomerAge <= 50 THEN '31 - 50'
        WHEN c.CustomerAge <= 70 THEN '51 - 70'
        ELSE '71 +'
    END AS age_group,
    c.CustomerGender,
    c.CustomerCountry,
    o.CustomerCount,
    o.CheckInDate,
    o.CheckOutDate,
    o.StayDuration,
    o.TotalCost,
    o.PaymentMethod,
    o.SeasonalFactor,
    r.RoomNumber,
    r.Capacity,
    r.RoomType,
    r.BasePrice
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.CustomerIDs, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.CustomerID = cust_id::int
JOIN rooms_staging r 
    ON o.RoomNumber = r.RoomNumber;

--This master View creates a table that joins all other tables to be able to create measures for the KPIS

