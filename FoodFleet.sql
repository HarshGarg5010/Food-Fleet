-- ============================================================
-- FoodFleet: 20 Real-World SQL Business Problem Solutions
-- PostgreSQL
-- ============================================================

-- ============================================================
-- SET SCHEMA PATH
-- ============================================================

SET search_path TO Fooddelivery_sch;


-- ============================================================
-- VIEW ALL TABLES
-- ============================================================

SELECT *
FROM customers;

SELECT *
FROM restaurants;

SELECT *
FROM orders;

SELECT *
FROM riders;

SELECT *
FROM deliveries;


-- ============================================================
-- DATA CLEANING: HANDLING NULL VALUES
-- ============================================================

-- Check for NULL values in customers
SELECT COUNT(*)
FROM customers
WHERE customer_name IS NULL
   OR reg_date IS NULL;


-- Check for NULL values in restaurants
SELECT COUNT(*)
FROM restaurants
WHERE restaurant_name IS NULL
   OR city IS NULL
   OR opening_hours IS NULL;


-- Check for NULL values in orders
SELECT *
FROM orders
WHERE order_item IS NULL
   OR order_date IS NULL
   OR order_time IS NULL
   OR order_status IS NULL
   OR total_amount IS NULL;


-- Delete orders containing NULL values
DELETE FROM orders
WHERE order_item IS NULL
   OR order_date IS NULL
   OR order_time IS NULL
   OR order_status IS NULL
   OR total_amount IS NULL;


-- ============================================================
-- ANALYSIS & REPORTS
-- ============================================================


-- ============================================================
-- Q.1 TOP 5 MOST FREQUENTLY ORDERED DISHES
-- ============================================================
-- Find the top 5 most frequently ordered dishes by
-- customer "Arjun Mehta".

WITH overall_analysis AS
(
    SELECT
        customer_id,
        order_item,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY
        customer_id,
        order_item
),

ranking AS
(
    SELECT
        customer_id,
        order_item,
        total_orders,
        ROW_NUMBER() OVER
        (
            PARTITION BY customer_id
            ORDER BY total_orders DESC
        ) AS dish_rank
    FROM overall_analysis
)

SELECT
    c.customer_name AS name,
    r.order_item AS dish,
    r.total_orders
FROM ranking AS r
LEFT JOIN customers AS c
    ON r.customer_id = c.customer_id
WHERE r.dish_rank <= 5
  AND c.customer_name = 'Arjun Mehta';


-- ============================================================
-- Q.2 POPULAR TIME SLOTS
-- ============================================================
-- Identify the 2-hour time slots during which
-- the most orders are placed.

SELECT
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_time,
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_time,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2,
    FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2
ORDER BY
    start_time;


-- ============================================================
-- Q.3 ORDER VALUE ANALYSIS
-- ============================================================
-- Find the average order value (AOV) per customer
-- who has placed more than 750 orders.

SELECT
    c.customer_name,
    AVG(o.total_amount) AS aov
FROM orders AS o
JOIN customers AS c
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_name
HAVING COUNT(o.order_id) > 750;


-- ============================================================
-- Q.4 HIGH-VALUE CUSTOMERS
-- ============================================================
-- List customers who have spent more than 100K
-- in total on food orders.

SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS total_spent
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING SUM(o.total_amount) > 100000
ORDER BY
    total_spent DESC;


-- ============================================================
-- Q.5 ORDERS WITHOUT DELIVERY
-- ============================================================
-- Find orders that were placed but not delivered.
-- Return restaurant name, city and number of
-- not-delivered orders.

SELECT
    r.restaurant_name,
    r.city,
    COUNT(DISTINCT o.order_id) AS cnt_not_delivered_orders
FROM restaurants AS r
JOIN orders AS o
    ON o.restaurant_id = r.restaurant_id
LEFT JOIN deliveries AS d
    ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
   OR d.delivery_status = 'Not Delivered'
GROUP BY
    r.restaurant_name,
    r.city
ORDER BY
    cnt_not_delivered_orders DESC;


-- ============================================================
-- Q.6 RESTAURANT REVENUE RANKING
-- ============================================================
-- Rank restaurants by total revenue and show
-- their rank within their city.

SELECT
    r.restaurant_name,
    r.city,
    SUM(o.total_amount) AS total_revenue,
    ROW_NUMBER() OVER
    (
        PARTITION BY r.city
        ORDER BY SUM(o.total_amount) DESC
    ) AS restaurant_rank
FROM restaurants AS r
INNER JOIN orders AS o
    ON o.restaurant_id = r.restaurant_id
GROUP BY
    r.restaurant_name,
    r.city
ORDER BY
    r.city,
    restaurant_rank;


-- ============================================================
-- Q.7 MOST POPULAR DISH BY CITY
-- ============================================================
-- Identify the most popular dish in each city
-- based on number of orders.

SELECT *
FROM
(
    SELECT
        r.city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER
        (
            PARTITION BY r.city
            ORDER BY COUNT(o.order_id) DESC
        ) AS dish_rank
    FROM orders AS o
    JOIN restaurants AS r
        ON r.restaurant_id = o.restaurant_id
    GROUP BY
        r.city,
        o.order_item
) AS t1
WHERE dish_rank = 1;


-- ============================================================
-- Q.8 CUSTOMER CHURN
-- ============================================================
-- Find customers who placed an order in 2023
-- but haven't placed an order in 2024.

SELECT DISTINCT
    customer_id
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
  AND customer_id NOT IN
  (
      SELECT DISTINCT
          customer_id
      FROM orders
      WHERE EXTRACT(YEAR FROM order_date) = 2024
  );


-- ============================================================
-- Q.9 CANCELLATION RATE COMPARISON
-- ============================================================
-- Compare the order cancellation rate for each restaurant
-- between 2024 and 2023.

WITH restaurant_analysis AS
(
    SELECT
        r.restaurant_name,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM o.order_date) = 2023
                 AND d.delivery_id IS NULL
                THEN 1
                ELSE 0
            END
        ) AS previous_year_Cancelled,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM o.order_date) = 2023
                THEN 1
                ELSE 0
            END
        ) AS previous_year_total_orders,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM o.order_date) = 2024
                 AND d.delivery_id IS NULL
                THEN 1
                ELSE 0
            END
        ) AS current_year_Cancelled,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM o.order_date) = 2024
                THEN 1
                ELSE 0
            END
        ) AS current_year_total_orders

    FROM restaurants AS r
    RIGHT JOIN orders AS o
        ON r.restaurant_id = o.restaurant_id
    LEFT JOIN deliveries AS d
        ON o.order_id = d.order_id
    GROUP BY
        r.restaurant_name
)

SELECT
    restaurant_name,

    COALESCE(
        ROUND(
            previous_year * 100.0
            / NULLIF(previous_year_total_orders, 0),
            1
        ),
        0.0
    ) AS previous_year_pct,

    COALESCE(
        ROUND(
            current_year * 100.0
            / NULLIF(current_year_total_orders, 0),
            1
        ),
        0.0
    ) AS current_year_pct

FROM restaurant_analysis;


-- ============================================================
-- Q.10  DELIVERY TIME
-- ============================================================
-- The query below calculates delivery time for each order.

SELECT
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    d.delivery_time - o.order_time AS time_difference,

    ROUND(
        EXTRACT(
            EPOCH FROM
            (
                d.delivery_time - o.order_time
                + CASE
                    WHEN d.delivery_time < o.order_time
                    THEN INTERVAL '1 day'
                    ELSE INTERVAL '0 day'
                  END
            )
        ) / 60,
        2
    ) AS time_difference_minutes

FROM orders AS o
JOIN deliveries AS d
    ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
order by order_id;


-- ============================================================
-- Q.11 MONTHLY RESTAURANT GROWTH RATIO
-- ============================================================
-- Calculate each restaurant's monthly growth ratio
-- based on delivered orders.

WITH growth_ratio AS
(
    SELECT
        o.restaurant_id,
        EXTRACT(YEAR FROM o.order_date) AS year,
        EXTRACT(MONTH FROM o.order_date) AS month,
        COUNT(o.order_id) AS current_month_orders,

        LAG(COUNT(o.order_id)) OVER
        (
            PARTITION BY o.restaurant_id
            ORDER BY
                EXTRACT(YEAR FROM o.order_date),
                EXTRACT(MONTH FROM o.order_date)
        ) AS previous_month_orders

    FROM orders AS o
    JOIN deliveries AS d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY
        o.restaurant_id,
        EXTRACT(YEAR FROM o.order_date),
        EXTRACT(MONTH FROM o.order_date)
)

SELECT
    restaurant_id,
    year,
    month,
    previous_month_orders,
    current_month_orders,

    ROUND(
        (
            current_month_orders::NUMERIC
            - previous_month_orders::NUMERIC
        )
        / previous_month_orders::NUMERIC * 100,
        2
    ) AS growth_ratio

FROM growth_ratio
ORDER BY
    restaurant_id,
    year,
    month;


-- ============================================================
-- Q.12 CUSTOMER SEGMENTATION
-- ============================================================
-- Segment customers into Gold or Silver based on
-- their average order value compared with overall AOV.
-- Return total orders and average order value by segment.

SELECT
    cx_category,
    SUM(total_orders) AS total_orders,
    ROUND(AVG(avg_order_value), 1) AS avg_order_value
FROM
(
    SELECT
        customer_id,
        AVG(total_amount) AS avg_order_value,
        COUNT(order_id) AS total_orders,

        CASE
            WHEN AVG(total_amount) >
                 (SELECT AVG(total_amount) FROM orders)
            THEN 'Gold'
            ELSE 'Silver'
        END AS cx_category

    FROM orders
    GROUP BY
        customer_id
) AS t1
GROUP BY
    cx_category;


-- Overall AOV

SELECT
    AVG(total_amount) AS overall_aov
FROM orders;


-- ============================================================
-- Q.13 RIDER MONTHLY EARNINGS
-- ============================================================
-- Calculate each rider's monthly earnings,
-- assuming riders earn 8% of the order amount.

SELECT
    d.rider_id,
    TO_CHAR(o.order_date, 'MM-YY') AS month,
    SUM(o.total_amount) AS revenue,
    SUM(o.total_amount) * 0.08 AS riders_earning
FROM orders AS o
JOIN deliveries AS d
    ON o.order_id = d.order_id
GROUP BY
    d.rider_id,
    TO_CHAR(o.order_date, 'MM-YY')
ORDER BY
    d.rider_id,
    TO_CHAR(o.order_date, 'MM-YY');


-- ============================================================
-- Q.14 RIDER RATINGS ANALYSIS
-- ============================================================
-- Rating rules:
--   < 15 minutes       = 5 stars
--   15 to 20 minutes   = 4 stars
--   > 20 minutes       = 3 stars

WITH delivery_times AS
(
    SELECT
        o.order_id,
        d.rider_id,
        o.order_time,
        d.delivery_time,

        EXTRACT(
            EPOCH FROM
            (
                d.delivery_time - o.order_time
                + CASE
                    WHEN d.delivery_time < o.order_time
                    THEN INTERVAL '1 day'
                    ELSE INTERVAL '0 day'
                  END
            )
        ) / 60 AS delivery_time_minutes

    FROM orders AS o
    JOIN deliveries AS d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
rider_ratings AS
(
    SELECT
        rider_id,
        delivery_time_minutes,

        CASE
            WHEN delivery_time_minutes < 15
                THEN '5 star'

            WHEN delivery_time_minutes BETWEEN 15 AND 20
                THEN '4 star'

            ELSE '3 star'
        END AS stars

    FROM delivery_times
)
SELECT
    rider_id,
    stars,
    COUNT(*) AS total_stars
FROM rider_ratings
GROUP BY
    rider_id,
    stars
ORDER BY
    rider_id,
    total_stars DESC;


-- ============================================================
-- Q.16 CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================
-- Calculate total revenue generated by each customer
-- over all their orders.

SELECT
    o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS clv
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    o.customer_id,
    c.customer_name;


-- ============================================================
-- Q.17 MONTHLY SALES TRENDS
-- ============================================================
-- Compare each month's total sales with the previous month.

SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(total_amount) AS total_sale,

    LAG(SUM(total_amount)) OVER
    (
        ORDER BY
            EXTRACT(YEAR FROM order_date),
            EXTRACT(MONTH FROM order_date)
    ) AS previous_month_sale

FROM orders
GROUP BY
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date)
ORDER BY
    year,
    month;


-- ============================================================
-- Q.18 RIDER EFFICIENCY
-- ============================================================
-- Identify riders with the lowest and highest
-- average delivery times.

WITH delivery_times AS
(
    SELECT
        o.order_id,
        d.rider_id,
        o.order_time,
        d.delivery_time,

        EXTRACT(
            EPOCH FROM
            (
                d.delivery_time - o.order_time
                + CASE
                    WHEN d.delivery_time < o.order_time
                    THEN INTERVAL '1 day'
                    ELSE INTERVAL '0 day'
                  END
            )
        ) / 60 AS delivery_time_minutes

    FROM orders AS o
    JOIN deliveries AS d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
avg_time AS
(
    SELECT
        rider_id,
        AVG(delivery_time_minutes) AS avg_delivery_time,

        ROW_NUMBER() OVER
        (
            ORDER BY AVG(delivery_time_minutes)
        ) AS lowest_rank,

        ROW_NUMBER() OVER
        (
            ORDER BY AVG(delivery_time_minutes) DESC
        ) AS highest_rank

    FROM delivery_times
    GROUP BY
        rider_id
)
SELECT
    rider_id,
    ROUND(avg_delivery_time, 1) AS avg_delivery_time
FROM avg_time
WHERE lowest_rank = 1
   OR highest_rank = 1;


-- Alternative solution:
-- Return only the minimum and maximum average delivery time.

WITH new_table AS
(
    SELECT
        o.*,
        d.rider_id AS rider_id,

        EXTRACT(
            EPOCH FROM
            (
                d.delivery_time - o.order_time
                + CASE
                    WHEN d.delivery_time < o.order_time
                    THEN INTERVAL '1 day'
                    ELSE INTERVAL '0 day'
                  END
            )
        ) / 60 AS delivery_time_minutes

    FROM orders AS o
    JOIN deliveries AS d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
riders_time AS
(
    SELECT
        rider_id,
        AVG(delivery_time_minutes) AS avg_delivery_time
    FROM new_table
    GROUP BY
        rider_id
)

SELECT
    MIN(avg_delivery_time) AS lowest_avg_delivery_time,
    MAX(avg_delivery_time) AS highest_avg_delivery_time
FROM riders_time;


-- ============================================================
-- Q.19 ORDER ITEM POPULARITY
-- ============================================================
-- Track popularity of order items by season
-- and identify seasonal demand.

SELECT
    order_item,
    season,
    COUNT(order_id) AS total_orders
FROM
(
    SELECT
        order_item,
        order_id,
        order_date,
        EXTRACT(MONTH FROM order_date) AS month,

        CASE
            WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6
                THEN 'Spring'

            WHEN EXTRACT(MONTH FROM order_date) > 6
             AND EXTRACT(MONTH FROM order_date) < 9
                THEN 'Summer'

            ELSE 'Winter'
        END AS season

    FROM orders
) AS t1
GROUP BY
    order_item,
    season
ORDER BY
    order_item,
    total_orders DESC;


-- ============================================================
-- Q.20 CITY REVENUE RANKING FOR 2023
-- ============================================================
-- Rank each city based on total revenue generated
-- during 2023.

SELECT
    r.city,
    SUM(o.total_amount) AS total_revenue,

    RANK() OVER
    (
        ORDER BY SUM(o.total_amount) DESC
    ) AS city_rank

FROM orders AS o
JOIN restaurants AS r
    ON o.restaurant_id = r.restaurant_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY
    r.city
ORDER BY
    city_rank;


-- ============================================================
-- END OF REPORTS
-- ============================================================
