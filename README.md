# Superstore Sales SQL Analysis

A real-world SQL portfolio project covering the top patterns asked in 80% of data analyst interviews, built on the Kaggle Superstore dataset (9,994 rows, 2014–2017).

---

## Project Summary

| Item | Detail |
|------|--------|
| **Dataset** | [Kaggle Superstore Sales](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) |
| **Rows** | 9,994 orders across 4 regions, 3 categories, 17 sub-categories |
| **Tools** | SQLite / PostgreSQL, Excel / Google Sheets |
| **Skills** | GROUP BY, HAVING, JOIN, Window Functions, CTEs, CASE WHEN |

---

## Dashboard KPIs (Real Data)

| Metric | Value |
|--------|-------|
| Total Revenue | $2,297,201 |
| Total Profit | $286,397 |
| Profit Margin | 12.5% |
| Total Orders | 5,009 |
| Total Customers | 793 |
| Date Range | Jan 2014 – Dec 2017 |

---

## Key Findings

1. **Phones & Chairs lead revenue** — each above $328K, but Chairs has only 8.1% margin vs Phones at 13.5%
2. **Tables are loss-making** — $207K revenue but -8.6% profit margin; a discount problem
3. **West region dominates** — $725K revenue, 30% more than the South ($392K)
4. **Top customer Sean Miller** — $25,043 lifetime value across 15 orders
5. **Loyal customers (8+ orders)** — only 622 customers but $3,410 avg LTV vs $219 for one-time buyers
6. **Q4 seasonality** — November consistently spikes (+52% MoM in 2017)

---

## Repository Structure

```
Superstore-Sales-SQL-Analysis/
│
├── superstore.sql              # All 6 SQL queries with real outputs in comments
├── README.md                   # This file
├── LICENSE                     # MIT
│
├── data/
│   └── README_data.md          # How to download the dataset (CSV not committed)
│
├── results/
│   ├── query1_top_products.csv
│   ├── query2_regional_performance.csv
│   ├── query3_customer_ltv.csv
│   ├── query4_monthly_trends.csv
│   ├── query5_top_per_category.csv
│   ├── query6_customer_segments.csv
│   └── README_results.md
│
└── screenshots/
    ├── dashboard_overview.png
    └── query_outputs.png
```

---

## SQL Queries

### Query 1 — Top Sub-Categories by Revenue
**Concept**: `GROUP BY` + `ORDER BY` + Aggregate Functions
**Pattern**: *"Find top N products / best sellers"*

```sql
SELECT Sub_Category, COUNT(*) AS total_orders,
       ROUND(SUM(Sales), 2) AS total_revenue,
       ROUND(SUM(Profit)/SUM(Sales)*100, 2) AS profit_margin_pct
FROM superstore
GROUP BY Sub_Category
ORDER BY total_revenue DESC
LIMIT 10;
```
**Result**: Phones ($330K, 13.5%) | Chairs ($328K, 8.1%) | Tables ($207K, **-8.6%** ⚠️)

---

### Query 2 — Regional Performance
**Concept**: `GROUP BY` + `HAVING` + `COUNT DISTINCT`
**Pattern**: *"Show only groups that meet a threshold"*

```sql
SELECT Region, ROUND(SUM(Sales),2) AS total_revenue,
       COUNT(DISTINCT Customer_ID) AS unique_customers
FROM superstore
GROUP BY Region
HAVING SUM(Sales) > 100000
ORDER BY total_revenue DESC;
```
**Result**: All 4 regions qualify. West leads at $725K, South trails at $392K.

> `WHERE` filters rows **before** grouping. `HAVING` filters groups **after** aggregation — a classic interview distinction.

---

### Query 3 — Customer Lifetime Value
**Concept**: `GROUP BY` + Aggregation + Date Functions
**Pattern**: *"Customer segmentation / RFM analysis"*

```sql
SELECT Customer_ID, Customer_Name,
       COUNT(*) AS total_orders, ROUND(SUM(Sales),2) AS lifetime_value,
       MIN(Order_Date) AS first_order, MAX(Order_Date) AS last_order
FROM superstore
GROUP BY Customer_ID, Customer_Name
ORDER BY lifetime_value DESC LIMIT 10;
```
**Result**: Sean Miller — $25,043 LTV | Tamara Chand — $19,052 | Raymond Buch — $15,117

---

### Query 4 — Monthly Revenue with MoM Growth %
**Concept**: Window Functions (`LAG`) + Date grouping
**Pattern**: *"Month-over-month / time-series growth"*

```sql
SELECT strftime('%Y-%m', Order_Date) AS month,
       ROUND(SUM(Sales), 2) AS monthly_revenue,
       LAG(ROUND(SUM(Sales),2)) OVER (ORDER BY strftime('%Y-%m', Order_Date)) AS prev_month,
       ROUND(100.0*(SUM(Sales) - LAG(SUM(Sales)) OVER (...)) / LAG(SUM(Sales)) OVER (...), 2) AS mom_pct
FROM superstore
GROUP BY strftime('%Y-%m', Order_Date);
```
**Result**: Nov 2017 — $118,448 (+52.3% MoM) | Dec 2017 — $83,829 (-29.2% MoM)

---

### Query 5 — Top Sub-Category per Category (Ranking)
**Concept**: `ROW_NUMBER()` + `PARTITION BY` + CTE
**Pattern**: *"Top N per group / rank within partition"*

```sql
WITH ranked AS (
  SELECT Category, Sub_Category,
         ROUND(SUM(Sales),2) AS revenue,
         ROW_NUMBER() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS rnk
  FROM superstore GROUP BY Category, Sub_Category
)
SELECT * FROM ranked WHERE rnk = 1;
```
**Result**: Technology → Phones ($330K) | Furniture → Chairs ($328K) | Office Supplies → Storage ($224K)

> `ROW_NUMBER` = unique rank | `RANK` = ties share rank, skip next | `DENSE_RANK` = ties share rank, no skip

---

### Query 6 (Bonus) — Customer Segmentation
**Concept**: `CASE WHEN` + Subquery bucketing
**Pattern**: *"Cohort labelling / user segmentation"*

```sql
SELECT
  CASE WHEN order_count=1 THEN '1-One-time'
       WHEN order_count<=3 THEN '2-Occasional'
       WHEN order_count<=7 THEN '3-Regular'
       ELSE '4-Loyal' END AS segment,
  COUNT(*) AS customers,
  ROUND(AVG(lifetime_value),2) AS avg_ltv
FROM (SELECT Customer_ID, COUNT(*) AS order_count, SUM(Sales) AS lifetime_value
      FROM superstore GROUP BY Customer_ID) t
GROUP BY segment ORDER BY segment;
```
**Result**: Loyal (8+ orders) — 622 customers, $3,410 avg LTV vs One-time — 5 customers, $219 avg LTV

---

## Interview Coverage

| Interview Question | Query | Pattern Used |
|---|---|---|
| Top N products / best sellers | Q1 | GROUP BY + ORDER BY + LIMIT |
| Filter groups by threshold | Q2 | HAVING |
| Customer lifetime value | Q3 | Multi-column GROUP BY + Date |
| Month-over-month growth | Q4 | LAG() Window Function |
| Top performer per category | Q5 | ROW_NUMBER + PARTITION BY + CTE |
| User segmentation / bucketing | Q6 | CASE WHEN + Subquery |

---

## How to Run

**Option A — SQLite Online (no install)**
1. Go to [sqliteonline.com](https://sqliteonline.com)
2. File > Import CSV → upload `superstore.csv` → table: `superstore`
3. Paste any query from `superstore.sql` → Run

**Option B — DBeaver (recommended)**
1. Download [DBeaver Community](https://dbeaver.io/download/)
2. New SQLite connection → import CSV → run queries

**Option C — PostgreSQL**
Replace `strftime('%Y-%m', Order_Date)` with `DATE_TRUNC('month', Order_Date::DATE)`

---

## Dataset

Not committed to this repo (publicly available, ~10K rows).
Download: [Kaggle Superstore Dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) → place as `data/superstore.csv`

---

## Author

**Garnipudi Nani**
[LinkedIn](https://www.linkedin.com/in/nani-garnipudi-534817376/) · [GitHub](https://github.com/GarnipudiNani)

---

## License

MIT License — see [LICENSE](LICENSE)
