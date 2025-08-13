-- 1. Customer demographic
--distribution by gender

SELECT customergender AS gender, Count(customergender) AS customers
    from customers_staging
    GROUP BY customergender
    ORDER BY customers DESC;

-- age group analysis
SELECT 
    CASE 
        WHEN customerage < 18 THEN 'Under 18'
        WHEN customerage <= 30 THEN '18 - 30'
        WHEN customerage <= 50 THEN '31 - 50'
        WHEN customerage <= 70 THEN '51 - 70'
        ELSE '71 +'
    END AS age_group,
    COUNT(*) AS customers
FROM customers_staging
GROUP BY age_group
ORDER BY age_group;

-- subquery
SELECT 
    age_group,
    COUNT(*) AS amount
FROM (
    SELECT 
        CASE 
            WHEN customerage < 18 THEN 'Under 18'
            WHEN customerage <= 30 THEN '18 - 30'
            WHEN customerage <= 50 THEN '31 - 50'
            WHEN customerage <= 70 THEN '51 - 70'
            ELSE '71 +'
        END AS age_group
    FROM customers_staging
) AS grouped_ages
GROUP BY age_group
ORDER BY age_group;

--cte
WITH grouped_ages AS(
    SELECT 
        CASE 
            WHEN customerage < 18 THEN 'Under 18'
            WHEN customerage <= 30 THEN '18 - 30'
            WHEN customerage <= 50 THEN '31 - 50'
            WHEN customerage <= 70 THEN '51 - 70'
            ELSE '71 +'
        END AS age_group,
        COUNT(*) AS amount
    FROM customers_staging
    GROUP BY age_group
    ORDER BY age_group
) SELECT age_group,amount
FROM grouped_ages


-- this give the number of customers and total customers on a different column
SELECT 
    customercountry AS country, 
    COUNT(*) AS customers,
    SUM(COUNT(*)) OVER () AS "total customers"
FROM customers_staging
GROUP BY country
ORDER BY customers DESC;

-- Roling totals from country
SELECT 
    customercountry AS country,
    COUNT(*) AS "number of customers",
    SUM(COUNT(*)) OVER (ORDER BY customercountry) AS "rolling total"
FROM customers_staging
GROUP BY customercountry
ORDER BY customercountry;

-- TOP 10 countries with the most customers
SELECT customercountry AS country ,
    COUNT(*) AS customers
FROM customers_staging
GROUP BY country
ORDER BY customers DESC
LIMIT 10;


-- 2. Booking Trends
--Average stay duration by room type
SELECT rs.roomtype,rs.capacity, ROUND(AVG(os.stayduration),3) AS duration
FROM orders_staging os JOIN rooms_staging rs ON
rs.roomnumber = os.roomnumber
GROUP BY  rs.roomtype, rs.capacity;


 -- Total revenue by roomtype
SELECT 
    rs.roomtype, SUM(os.totalcost) AS revenue
FROM orders_staging os JOIN rooms_staging rs ON os.roomnumber = rs.roomnumber
GROUP BY
    rs.roomtype
ORDER BY
    revenue DESC;

-- Most popular roomtype
SELECT roomtype, COUNT(*) AS rooms
FROM rooms_staging
GROUP BY roomtype
ORDER BY rooms DESC
LIMIT 1;

-- Customer count  by capacity
SELECT os.customercount, rs.capacity
FROM orders_staging os JOIN rooms_staging rs ON rs.roomnumber= os.roomnumber
GROUP BY os.customercount,rs.capacity;

SELECT 
    os.customercount, 
    rs.capacity, 
    rs.roomtype,
    COUNT(*) AS order_count
FROM 
    orders_staging os
JOIN 
    rooms_staging rs 
    ON rs.roomnumber = os.roomnumber
GROUP BY 
    os.customercount, rs.capacity,rs.roomtype
ORDER BY 
    order_count DESC;


-- 3. Payment and Revenue Insights
--Revenue by payment method
SELECT 
    paymentmethod, SUM(totalcost) AS revenue
FROM 
    orders_staging
GROUP BY paymentmethod
ORDER BY revenue DESC;


-- Average spend per customer
SELECT * FROM orders_staging LIMIT 10;
--Top 10 high value bookings
SELECT orderid, totalcost, paymentmethod, checkindate, checkoutdate
FROM orders_staging
WHERE totalcost > 2000
ORDER BY totalcost DESC
LIMIT 10;

--using percentiles (90th percentile)
SELECT *
FROM orders_staging
WHERE totalcost > (
    SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY totalcost) 
    FROM orders_staging
)
ORDER BY totalcost DESC;


-- 4. Seasonal and pricing

--impact of seasonal factor on booking

SELECT seasonalfactor as season,SUM(customercount) AS customers ,
    SUM(totalcost) AS revenue
FROM orders_staging
GROUP BY season

-- Number of customers and revenue distribution monthly

SELECT 
    TRIM(TO_CHAR(checkindate, 'Month')) AS month,
    SUM(customercount) AS customers, SUM(totalcost) AS revenue
FROM orders_staging
GROUP BY month,EXTRACT(MONTH FROM checkindate)
ORDER BY EXTRACT(MONTH FROM checkindate)
;

-- Country vs room type preference
SELECT 
    c.customercountry,
    r.roomtype,
    COUNT(*) AS total_bookings
FROM orders_staging o
    -- split customer ids into rows
JOIN LATERAL unnest(string_to_array(o.customerids,',')) AS cust_id ON TRUE
    -- match to the customer table
JOIN customers_staging c 
    ON c.customerid = cust_id::INT
    -- match to rooms table
JOIN rooms_staging r
    ON r.roomnumber = o.roomnumber
GROUP BY c.customercountry,r.roomtype
ORDER BY total_bookings DESC;


-- Gender vs average spend
SELECT 
    c.customergender,COUNT(*) as gender,
    ROUND(AVG(o.totalcost / o.customercount), 2) AS avg_spend_per_customer
FROM orders_staging o
-- Step 1: Split multiple IDs into rows
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
-- Step 2: Link each split ID to its customer record
JOIN customers_staging c 
    ON c.customerid = cust_id::int
GROUP BY c.customergender
ORDER BY avg_spend_per_customer DESC;


-- gender vs total spend
SELECT 
    c.customergender,
    ROUND(SUM(o.totalcost / o.customercount),2) AS total_spend
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.customerid = cust_id::int
GROUP BY c.customergender
ORDER BY total_spend DESC;


--Room type popularity per season
SELECT 
    seasonalfactor,
    r.roomtype,
    COUNT(*) AS bookings
FROM orders_staging o
JOIN rooms_staging r ON r.roomnumber = o.roomnumber
GROUP BY seasonalfactor, r.roomtype
ORDER BY seasonalfactor, bookings DESC;


-- Revenue per roomtype per month
SELECT 
    TO_CHAR(DATE_TRUNC('month', checkindate), 'FMMonth') AS month,
    r.roomtype,
    SUM(totalcost) AS revenue
FROM orders_staging o
JOIN rooms_staging r ON r.roomnumber = o.roomnumber
GROUP BY DATE_TRUNC('month', checkindate), r.roomtype
ORDER BY DATE_TRUNC('month', checkindate), revenue DESC;

-- Capacity utilization
SELECT 
    r.roomtype,
    ROUND(AVG(o.customercount::decimal / r.capacity) * 100, 2) AS avg_utilization_percent
FROM orders_staging o
JOIN rooms_staging r ON r.roomnumber = o.roomnumber
GROUP BY r.roomtype
ORDER BY avg_utilization_percent DESC;


-- Age Group vs Payment Method (stacked column)

SELECT 
    CASE 
        WHEN customerage < 18 THEN 'Under 18'
        WHEN c.customerage < 30 THEN '18-30'
        WHEN c.customerage BETWEEN 31 AND 50 THEN '31-50'
        WHEN c.customerage BETWEEN 51 AND 70 THEN '51-70'
        ELSE '71+'
    END AS age_group,
    o.paymentmethod,
    COUNT(*) AS booking_count
FROM orders_staging o
-- Step 1: Split CustomerIDs into rows
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
-- Step 2: Join to customers table
JOIN customers_staging c 
    ON c.customerid = cust_id::int
GROUP BY age_group, o.paymentmethod
ORDER BY age_group, booking_count DESC;


--use a CTE
WITH customer_bookings AS (
    SELECT 
        c.customerid,
        c.customerage,
        o.paymentmethod
    FROM orders_staging o
    -- Split multiple customer IDs into separate rows
    JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
    -- Join to customers table
    JOIN customers_staging c 
        ON c.customerid = cust_id::int
)
SELECT 
    CASE 
        WHEN customerage < 18 THEN 'Under 18'
        WHEN customerage < 30 THEN '18-30'
        WHEN customerage BETWEEN 31 AND 50 THEN '31-50'
        WHEN customerage BETWEEN 51 AND 70 THEN '51-70'
        ELSE '71+'
    END AS age_group,
    paymentmethod,
    COUNT(*) AS booking_count
FROM customer_bookings
GROUP BY age_group, paymentmethod
ORDER BY age_group, booking_count DESC;

