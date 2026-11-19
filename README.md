<h1 align="center">🍔 FoodFleet | Food Delivery SQL Analytics</h1>

<p align="center">
  <b>19 real-world business problems solved with PostgreSQL: customer behavior, restaurant performance, rider efficiency, and sales trends</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/SQL-003B57?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Window%20Functions-FF6B35?style=for-the-badge" />
  <img src="https://img.shields.io/badge/CTEs-6A5ACD?style=for-the-badge" />
</p>

<p align="center">
  <a href="#-database-schema">Schema</a> 
</p>

---

## 📌 Project Overview

**FoodFleet** is a SQL analytics project on a food delivery platform, built in **PostgreSQL**. It begins with data cleaning (NULL checks and removal), then answers **19 business questions** across four areas:

- **Customers:** favorite dishes, spending, segmentation, churn, lifetime value
- **Restaurants:** revenue ranking, cancellation rates, monthly growth
- **Riders:** earnings, ratings, delivery efficiency
- **Orders & Sales:** peak time slots, seasonal demand, monthly trends

All queries are in a single file, `foodfleet_queries.sql`.

## 📊 Project at a Glance

| Aspect | Details |
|---|---|
| Database | PostgreSQL |
| Schema | `Fooddelivery_sch` |
| Tables | 5 (customers, restaurants, orders, riders, deliveries) |
| Business Problems | 19 |
| Techniques | CTEs, Subqueries, Window Functions, Joins, Conditional Logic |
| Project Type | Data Analytics / Business Analysis |

## 🗂️ Database Schema

```
customers   (customer_id, customer_name, reg_date)
restaurants (restaurant_id, restaurant_name, city, opening_hours)
orders      (order_id, customer_id, restaurant_id, order_item,
             order_date, order_time, order_status, total_amount)
riders      (rider_id, ...)
deliveries  (delivery_id, order_id, rider_id, delivery_status, delivery_time)
```

**Relationships:** `orders` links to `customers` and `restaurants`; `deliveries` links to `orders` and `riders`.

> Add an ER diagram image here: `![ER Diagram](images/er-diagram.png)`

## 🧹 Data Cleaning

Before analysis, the data was checked for missing values:

- NULL checks on `customers` (name, registration date)
- NULL checks on `restaurants` (name, city, opening hours)
- NULL checks on `orders` (item, date, time, status, amount)
- Orders with NULL values were **deleted** to keep the analysis reliable

## ❓ Business Problems Solved

### 👥 Customer Analysis

| # | Problem | Key Technique |
|---|---|---|
| Q1 | Top 5 most frequently ordered dishes for a specific customer | CTE, `ROW_NUMBER()` |
| Q3 | Average order value for customers with 750+ orders | `HAVING`, `AVG` |
| Q4 | High-value customers who spent over 100K | `SUM`, `HAVING` |
| Q8 | Customer churn: ordered in 2023 but not in 2024 | Subquery, `NOT IN` |
| Q12 | Gold vs. Silver segmentation based on overall AOV | `CASE WHEN`, scalar subquery |
| Q16 | Customer Lifetime Value (CLV) | Aggregation, joins |

### 🍽️ Restaurant & City Analysis

| # | Problem | Key Technique |
|---|---|---|
| Q5 | Restaurants with orders placed but not delivered | `LEFT JOIN`, anti-join logic |
| Q6 | Restaurant revenue rank within each city | `ROW_NUMBER() OVER (PARTITION BY)` |
| Q7 | Most popular dish in each city | `RANK()`, subquery |
| Q9 | Cancellation rate comparison, 2024 vs. 2023 | Conditional aggregation, `COALESCE`, `NULLIF` |
| Q11 | Monthly growth ratio per restaurant (delivered orders) | `LAG()`, `PARTITION BY` |
| Q20 | City revenue ranking for 2023 | `RANK()` |

### 🏍️ Rider Performance

| # | Problem | Key Technique |
|---|---|---|
| Q10 | Delivery time per order (handles delivery past midnight) | `EXTRACT(EPOCH)`, interval logic |
| Q13 | Monthly rider earnings at 8% of order amount | `TO_CHAR`, aggregation |
| Q14 | Rider star ratings from delivery time (<15 min = 5★, 15–20 = 4★, >20 = 3★) | CTE, `CASE WHEN` |
| Q18 | Fastest and slowest riders by average delivery time | CTE, dual `ROW_NUMBER()` |

### 📈 Orders & Sales Trends

| # | Problem | Key Technique |
|---|---|---|
| Q2 | Peak 2-hour time slots for orders | `FLOOR`, `EXTRACT(HOUR)` |
| Q17 | Month-over-month sales comparison | `LAG()` over aggregates |
| Q19 | Seasonal popularity of order items | `CASE WHEN`, grouping |

## 🧠 SQL Concepts Used

| Concept | Where Used |
|---|---|
| **Aggregations** (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`) | Throughout |
| **Joins** (`INNER`, `LEFT`, `RIGHT`) | Combining orders, customers, restaurants, deliveries |
| **CTEs** (`WITH`) | Q1, Q9, Q11, Q14, Q18 |
| **Subqueries** | Q7, Q8, Q12, Q19 |
| **Window Functions** (`ROW_NUMBER`, `RANK`, `LAG`) | Q1, Q6, Q7, Q11, Q17, Q18, Q20 |
| **Date & Time Functions** (`EXTRACT`, `TO_CHAR`, `INTERVAL`) | Q2, Q8, Q10, Q13, Q17, Q19 |
| **Conditional Logic** (`CASE WHEN`) | Q9, Q12, Q14, Q19 |
| **NULL Handling** (`COALESCE`, `NULLIF`) | Q9 |
| **Type Casting** (`::NUMERIC`) | Q11 |

## 💻 Sample Queries

<details>
<summary><b>Q6: Restaurant revenue rank within each city</b></summary>

```sql
SELECT
    r.restaurant_name,
    r.city,
    SUM(o.total_amount) AS total_revenue,
    ROW_NUMBER() OVER (
        PARTITION BY r.city
        ORDER BY SUM(o.total_amount) DESC
    ) AS restaurant_rank
FROM restaurants AS r
INNER JOIN orders AS o
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name, r.city
ORDER BY r.city, restaurant_rank;
```
</details>

<details>
<summary><b>Q12: Customer segmentation (Gold / Silver)</b></summary>

```sql
SELECT
    cx_category,
    SUM(total_orders) AS total_orders,
    ROUND(AVG(avg_order_value), 1) AS avg_order_value
FROM (
    SELECT
        customer_id,
        AVG(total_amount) AS avg_order_value,
        COUNT(order_id) AS total_orders,
        CASE
            WHEN AVG(total_amount) > (SELECT AVG(total_amount) FROM orders)
            THEN 'Gold' ELSE 'Silver'
        END AS cx_category
    FROM orders
    GROUP BY customer_id
) AS t1
GROUP BY cx_category;
```
</details>

<details>
<summary><b>Q18: Rider efficiency (fastest and slowest)</b></summary>

```sql
WITH delivery_times AS (
    SELECT
        d.rider_id,
        EXTRACT(EPOCH FROM (
            d.delivery_time - o.order_time
            + CASE WHEN d.delivery_time < o.order_time
                   THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
        )) / 60 AS delivery_time_minutes
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
avg_time AS (
    SELECT
        rider_id,
        AVG(delivery_time_minutes) AS avg_delivery_time,
        ROW_NUMBER() OVER (ORDER BY AVG(delivery_time_minutes))      AS lowest_rank,
        ROW_NUMBER() OVER (ORDER BY AVG(delivery_time_minutes) DESC) AS highest_rank
    FROM delivery_times
    GROUP BY rider_id
)
SELECT rider_id, ROUND(avg_delivery_time, 1) AS avg_delivery_time
FROM avg_time
WHERE lowest_rank = 1 OR highest_rank = 1;
```
</details>

## 🔍 Key Insights

> Run the queries and add 4–6 real findings here. This section shows analytical thinking.

- 🏆 **Top customers:** [e.g., X customers spent over 100K, contributing Y% of revenue]
- 🥇 **Customer segments:** [e.g., Gold customers averaged ₹X per order vs. ₹Y for Silver]
- 🕐 **Peak hours:** [e.g., Highest order volume between X PM and Y PM]
- 🌆 **Top city:** [e.g., City X ranked #1 in 2023 revenue]
- 🏍️ **Riders:** [e.g., Fastest rider averaged X min vs. Y min for the slowest]
- 📉 **Churn:** [e.g., X customers ordered in 2023 but not in 2024]

## 📁 Repository Structure

```
FoodFleet/
├── data/                    # Source CSV files (5 tables)
├── images/                  # ER diagram / query output screenshots
├── foodfleet_queries.sql    # Schema setup, cleaning, and 19 analysis queries
└── README.md
```

## 🚀 How to Run

1. **Clone the repository**
   ```bash
   git clone [YOUR_REPO_URL]
   cd FoodFleet
   ```
2. **Create the schema and tables** in PostgreSQL (`Fooddelivery_sch`) and import the CSV files from `data/`
3. **Open `foodfleet_queries.sql`** in pgAdmin, DBeaver, or `psql`
4. **Set the schema path** (first line of the script):
   ```sql
   SET search_path TO Fooddelivery_sch;
   ```
5. **Run the cleaning section first**, then execute each query in the analysis section

## 💼 Skills Demonstrated

SQL • PostgreSQL • Data Cleaning • CTEs • Subqueries • Window Functions • Joins • Date/Time Analysis • Customer Segmentation • Churn Analysis • Business Analytics • Problem Solving

## 📬 Connect With Me

**[Your Name]**
🔗 [LinkedIn](https://www.linkedin.com/in/harsh-garg-161878291?utm_source=share_via&utm_content=profile&utm_medium=member_android) • ✉️ harshgarg500@gmail.com
⭐ *If you found this project useful, please consider giving it a star!*

<p align="center"><i>Turning Data into Decisions, One Query at a Time. 🍔</i></p>
