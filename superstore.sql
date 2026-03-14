-- ============================================================
-- Superstore Sales Analysis — SQL Interview Project
-- Dataset : Kaggle "Sample - Superstore" (9,994 rows, 2014–2017)
-- Tool    : SQLite (column names use underscore — e.g. Sub_Category)
--           PostgreSQL users: replace strftime() with DATE_TRUNC()
-- Covers  : GROUP BY, HAVING, Window Functions, CTEs, CASE WHEN
-- ============================================================

-- ============================================================
-- SETUP: Import CSV
-- ============================================================
-- SQLite Online  → File > Open DB (or paste CSV)
-- DBeaver        → Right-click schema > Import Data > CSV
-- Table name     → superstore
-- Date columns   → Order_Date, Ship_Date (format: YYYY-MM-DD)
-- ============================================================


-- ============================================================
-- QUERY 1: Top Sub-Categories by Revenue
-- Concept : GROUP BY + ORDER BY + Aggregate Functions
-- Pattern : "Find top N products / best sellers"
-- ============================================================

SELECT
    Sub_Category,
    COUNT(*)                                    AS total_orders,
    ROUND(SUM(Sales), 2)                        AS total_revenue,
    ROUND(SUM(Profit), 2)                       AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY Sub_Category
ORDER BY total_revenue DESC
LIMIT 10;

-- Real Output:
-- Phones    | 889 orders  | $330,007 | 13.5% margin
-- Chairs    | 617 orders  | $328,449 |  8.1% margin
-- Storage   | 846 orders  | $223,844 |  9.5% margin
-- Warning: Tables has -8.6% margin → loss-making sub-category!


-- ============================================================
-- QUERY 2: Regional Performance (HAVING filter)
-- Concept : GROUP BY + HAVING + COUNT DISTINCT
-- Pattern : "Show only groups that meet a threshold"
-- ============================================================

SELECT
    Region,
    ROUND(SUM(Sales), 2)        AS total_revenue,
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    ROUND(AVG(Sales), 2)        AS avg_order_value,
    ROUND(SUM(Profit), 2)       AS total_profit
FROM superstore
GROUP BY Region
HAVING SUM(Sales) > 100000
ORDER BY total_revenue DESC;

-- Real Output:
-- West    | $725,458 | 686 customers
-- East    | $678,781 | 674 customers
-- Central | $501,240 | 629 customers
-- South   | $391,722 | 512 customers

-- Interview tip: WHERE filters rows BEFORE grouping.
--               HAVING filters groups AFTER aggregation.


-- ============================================================
-- QUERY 3: Customer Lifetime Value (LTV)
-- Concept : GROUP BY + Aggregation + Date Functions
-- Pattern : "Customer segmentation / RFM analysis"
-- ============================================================

SELECT
    Customer_ID,
    Customer_Name,
    COUNT(*)                    AS total_orders,
    ROUND(SUM(Sales), 2)        AS lifetime_value,
    ROUND(AVG(Sales), 2)        AS avg_order_value,
    MIN(Order_Date)             AS first_order,
    MAX(Order_Date)             AS last_order
FROM superstore
GROUP BY Customer_ID, Customer_Name
ORDER BY lifetime_value DESC
LIMIT 10;

-- Real Output (Top 3):
-- Sean Miller   | 15 orders | $25,043 LTV
-- Tamara Chand  | 12 orders | $19,052 LTV
-- Raymond Buch  | 18 orders | $15,117 LTV


-- ============================================================
-- QUERY 4: Monthly Revenue with Month-over-Month Growth
-- Concept : Window Functions (LAG) + Date grouping
-- Pattern : "Month-over-month / time-series growth rate"
-- ============================================================

-- SQLite version (uses strftime)
SELECT
    strftime('%Y-%m', Order_Date)               AS month,
    ROUND(SUM(Sales), 2)                        AS monthly_revenue,
    ROUND(
        LAG(SUM(Sales)) OVER (
            ORDER BY strftime('%Y-%m', Order_Date)
        ), 2
    )                                           AS prev_month_revenue,
    ROUND(
        100.0 * (
            SUM(Sales)
            - LAG(SUM(Sales)) OVER (ORDER BY strftime('%Y-%m', Order_Date))
        )
        / LAG(SUM(Sales)) OVER (ORDER BY strftime('%Y-%m', Order_Date))
    , 2)                                        AS mom_growth_pct
FROM superstore
GROUP BY strftime('%Y-%m', Order_Date)
ORDER BY month;

-- PostgreSQL: swap strftime('%Y-%m', Order_Date)
--        with DATE_TRUNC('month', Order_Date::DATE)

-- Real Output (sample):
-- 2017-11 | $118,448 | prev $77,777 | +52.3% MoM
-- 2017-12 |  $83,829 | prev $118,448 | -29.2% MoM


-- ============================================================
-- QUERY 5: #1 Sub-Category per Category (Ranking)
-- Concept : ROW_NUMBER() + PARTITION BY + CTE
-- Pattern : "Top N per group / rank within partition"
-- ============================================================

WITH category_revenue AS (
    -- Step 1: Aggregate revenue per sub-category
    SELECT
        Category,
        Sub_Category,
        ROUND(SUM(Sales), 2)    AS total_revenue,
        ROUND(SUM(Profit), 2)   AS total_profit,
        COUNT(*)                AS order_count
    FROM superstore
    GROUP BY Category, Sub_Category
),
ranked AS (
    -- Step 2: Rank sub-categories within each category
    SELECT
        Category,
        Sub_Category,
        total_revenue,
        total_profit,
        order_count,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY total_revenue DESC
        )                       AS rank_in_category
    FROM category_revenue
)
-- Step 3: Keep only rank 1 (best per category)
SELECT *
FROM ranked
WHERE rank_in_category = 1
ORDER BY total_revenue DESC;

-- Real Output:
-- Technology      | Phones   | $330,007
-- Furniture       | Chairs   | $328,449
-- Office Supplies | Storage  | $223,844

-- Ranking functions compared:
--    ROW_NUMBER  → Always unique (1, 2, 3, 4...)
--    RANK        → Ties share rank, skip next (1, 1, 3...)
--    DENSE_RANK  → Ties share rank, no skip (1, 1, 2...)


-- ============================================================
-- QUERY 6 (Bonus): Customer Segmentation with CASE WHEN
-- Concept : CASE WHEN + Subquery bucketing
-- Pattern : "Segment users / cohort labelling"
-- ============================================================

SELECT
    CASE
        WHEN order_count = 1  THEN '1 - One-time buyer'
        WHEN order_count <= 3 THEN '2 - Occasional (2-3 orders)'
        WHEN order_count <= 7 THEN '3 - Regular (4-7 orders)'
        ELSE                       '4 - Loyal (8+ orders)'
    END                             AS customer_segment,
    COUNT(*)                        AS customer_count,
    ROUND(AVG(lifetime_value), 2)   AS avg_ltv
FROM (
    SELECT
        Customer_ID,
        COUNT(*)        AS order_count,
        SUM(Sales)      AS lifetime_value
    FROM superstore
    GROUP BY Customer_ID
) AS customer_stats
GROUP BY customer_segment
ORDER BY customer_segment;

-- Real Output:
-- One-time buyer     |   5 customers | $219  avg LTV
-- Occasional (2-3)   |  28 customers | $617  avg LTV
-- Regular   (4-7)    | 138 customers | $1,143 avg LTV
-- Loyal     (8+)     | 622 customers | $3,410 avg LTV
-- Insight: 78% of customers are Loyal — prioritize retention!
