/* =========================================================
   1. CUSTOMER SEGMENTATION & DEMOGRAPHICS
   ========================================================= */

/* Gender distribution of customers */
SELECT 
    customergender AS gender, 
    COUNT(*) AS customers
FROM customers_staging
GROUP BY customergender
ORDER BY customers DESC;

/* Age group distribution */
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

/* Country distribution with total customers */
SELECT 
    customercountry AS country, 
    COUNT(*) AS customers,
    SUM(COUNT(*)) OVER () AS total_customers
FROM customers_staging
GROUP BY country
ORDER BY customers DESC;

/* Top 10 countries with the most customers */
SELECT 
    customercountry AS country,
    COUNT(*) AS customers
FROM customers_staging
GROUP BY country
ORDER BY customers DESC
LIMIT 10;

/* Rolling customer totals by country */
SELECT 
    customercountry AS country,
    COUNT(*) AS number_of_customers,
    SUM(COUNT(*)) OVER (ORDER BY customercountry) AS rolling_total
FROM customers_staging
GROUP BY customercountry
ORDER BY customercountry;


/* =========================================================
   2. BOOKING TRENDS
   ========================================================= */

/* Average stay duration by room type and capacity */
SELECT 
    rs.roomtype,
    rs.capacity, 
    ROUND(AVG(os.stayduration), 3) AS avg_duration
FROM orders_staging os
JOIN rooms_staging rs 
    ON rs.roomnumber = os.roomnumber
GROUP BY rs.roomtype, rs.capacity;

/* Total revenue by room type */
SELECT 
    rs.roomtype, 
    SUM(os.totalcost) AS revenue
FROM orders_staging os
JOIN rooms_staging rs 
    ON os.roomnumber = rs.roomnumber
GROUP BY rs.roomtype
ORDER BY revenue DESC;

/* Room type popularity per season */
SELECT 
    seasonalfactor,
    r.roomtype,
    COUNT(*) AS bookings
FROM orders_staging o
JOIN rooms_staging r 
    ON r.roomnumber = o.roomnumber
GROUP BY seasonalfactor, r.roomtype
ORDER BY seasonalfactor, bookings DESC;

/* Capacity utilization percentage by room type */
SELECT 
    r.roomtype,
    ROUND(AVG(o.customercount::decimal / r.capacity) * 100, 2) AS avg_utilization_percent
FROM orders_staging o
JOIN rooms_staging r 
    ON r.roomnumber = o.roomnumber
GROUP BY r.roomtype
ORDER BY avg_utilization_percent DESC;


/* =========================================================
   3. PAYMENT & REVENUE INSIGHTS
   ========================================================= */

/* Revenue by payment method */
SELECT 
    paymentmethod, 
    SUM(totalcost) AS revenue
FROM orders_staging
GROUP BY paymentmethod
ORDER BY revenue DESC;

/* Top 10 high value bookings */
SELECT 
    orderid, 
    totalcost, 
    paymentmethod, 
    checkindate, 
    checkoutdate
FROM orders_staging
WHERE totalcost > 2000
ORDER BY totalcost DESC
LIMIT 10;

/* High value bookings using 90th percentile cutoff */
SELECT *
FROM orders_staging
WHERE totalcost > (
    SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY totalcost) 
    FROM orders_staging
)
ORDER BY totalcost DESC;

/* Gender vs average spend per customer */
SELECT 
    c.customergender,
    COUNT(*) AS gender_count,
    ROUND(AVG(o.totalcost / o.customercount), 2) AS avg_spend_per_customer
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.customerid = cust_id::int
GROUP BY c.customergender
ORDER BY avg_spend_per_customer DESC;

/* Gender vs total spend */
SELECT 
    c.customergender,
    ROUND(SUM(o.totalcost / o.customercount), 2) AS total_spend
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.customerid = cust_id::int
GROUP BY c.customergender
ORDER BY total_spend DESC;


/* =========================================================
   4. SEASONALITY & TIMING ANALYSIS
   ========================================================= */

/* Impact of seasonal factor on customers & revenue */
SELECT 
    seasonalfactor AS season,
    SUM(customercount) AS customers,
    SUM(totalcost) AS revenue
FROM orders_staging
GROUP BY season;

/* Monthly customer and revenue distribution */
SELECT 
    TRIM(TO_CHAR(checkindate, 'Month')) AS month,
    SUM(customercount) AS customers,
    SUM(totalcost) AS revenue
FROM orders_staging
GROUP BY month, EXTRACT(MONTH FROM checkindate)
ORDER BY EXTRACT(MONTH FROM checkindate);

/* Revenue per room type per month */
SELECT 
    TO_CHAR(DATE_TRUNC('month', checkindate), 'FMMonth') AS month,
    r.roomtype,
    SUM(totalcost) AS revenue
FROM orders_staging o
JOIN rooms_staging r 
    ON r.roomnumber = o.roomnumber
GROUP BY DATE_TRUNC('month', checkindate), r.roomtype
ORDER BY DATE_TRUNC('month', checkindate), revenue DESC;


/* =========================================================
   5. CUSTOMER BEHAVIOR CROSS-ANALYSIS
   ========================================================= */

/* Country vs room type preference */
SELECT 
    c.customercountry,
    r.roomtype,
    COUNT(*) AS total_bookings
FROM orders_staging o
JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
JOIN customers_staging c 
    ON c.customerid = cust_id::int
JOIN rooms_staging r 
    ON r.roomnumber = o.roomnumber
GROUP BY c.customercountry, r.roomtype
ORDER BY total_bookings DESC;

/* Age Group vs Payment Method */
WITH customer_bookings AS (
    SELECT 
        c.customerid,
        c.customerage,
        o.paymentmethod
    FROM orders_staging o
    JOIN LATERAL unnest(string_to_array(o.customerids, ',')) AS cust_id ON TRUE
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
