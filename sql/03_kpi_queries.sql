-- ============================================================
-- 03_KPI_QUERIES.SQL
-- Bank Customer Churn Analysis — All Dashboard KPIs & Charts
-- Prerequisite: 01_data_cleaning.sql + 02_feature_engineering.sql
-- ============================================================

-- ============================================================
-- PAGE 1: EXECUTIVE OVERVIEW
-- ============================================================

-- KPI-1: Total Customers
SELECT COUNT(*) AS total_customers FROM churn_clean;

-- KPI-2: Churned Customers
SELECT SUM(Churned) AS churned_customers FROM churn_clean;

-- KPI-3: Churn Rate (%)
SELECT
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2) AS churn_rate_pct
FROM churn_clean;

-- KPI-4: Average Balance (all customers)
SELECT ROUND(AVG(Balance), 2) AS avg_balance FROM churn_clean;

-- CHART-1: Churn by Geography
SELECT
    Geography,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    COUNT(*) - SUM(Churned)                         AS retained,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY Geography
ORDER BY churn_rate_pct DESC;

-- CHART-2: Churn by Age Group
SELECT
    AgeGroup,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY AgeGroup
ORDER BY MIN(Age);

-- CHART-3: Churn Trend by Tenure Year
-- (Tenure approximates years with the bank — proxy for "time trend")
SELECT
    Tenure                                          AS years_with_bank,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY Tenure
ORDER BY Tenure;


-- ============================================================
-- PAGE 2: CUSTOMER ANALYSIS
-- ============================================================

-- CHART-4: Churn by Gender
SELECT
    Gender,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY Gender
ORDER BY churn_rate_pct DESC;

-- CHART-5: Churn by Age (5-year buckets)
SELECT
    FLOOR(Age / 5) * 5                              AS age_band_start,
    FLOOR(Age / 5) * 5 + 4                          AS age_band_end,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY FLOOR(Age / 5)
ORDER BY age_band_start;

-- CHART-6: Churn by Credit Score Band
SELECT
    CreditBand,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(CreditScore), 1)                      AS avg_credit_score
FROM churn_clean
GROUP BY CreditBand
ORDER BY MIN(CreditScore);

-- CHART-7: Churn by Tenure Group
SELECT
    TenureGroup,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY TenureGroup
ORDER BY MIN(Tenure);


-- ============================================================
-- PAGE 3: PRODUCT ANALYSIS
-- ============================================================

-- CHART-8: Churn by Number of Products
SELECT
    NumOfProducts,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY NumOfProducts
ORDER BY NumOfProducts;

-- CHART-9: Churn by Credit Card Status
SELECT
    CASE WHEN HasCrCard = 1 THEN 'Has Credit Card' ELSE 'No Credit Card' END AS credit_card_status,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY HasCrCard
ORDER BY HasCrCard DESC;

-- CHART-10: Churn by Active Membership
SELECT
    CASE WHEN IsActiveMember = 1 THEN 'Active Member' ELSE 'Inactive Member' END AS membership_status,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY IsActiveMember
ORDER BY IsActiveMember DESC;

-- SUPPLEMENTAL: Products × Active cross-tab
SELECT
    ProductsActiveCombo,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct
FROM churn_clean
GROUP BY ProductsActiveCombo
ORDER BY NumOfProducts, IsActiveMember;


-- ============================================================
-- PAGE 4: FINANCIAL ANALYSIS
-- ============================================================

-- CHART-11: Churn by Balance Segment
SELECT
    BalanceSegment,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(Balance), 2)                          AS avg_balance,
    ROUND(SUM(Balance), 2)                          AS total_balance_at_risk
FROM churn_clean
WHERE Churned = 1
GROUP BY BalanceSegment
ORDER BY MIN(Balance);

-- CHART-12: Churn by Salary Segment
SELECT
    SalarySegment,
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(EstimatedSalary), 2)                  AS avg_salary
FROM churn_clean
GROUP BY SalarySegment
ORDER BY MIN(EstimatedSalary);

-- CHART-13: Revenue at Risk (by Geography × Active Status)
SELECT
    Geography,
    CASE WHEN IsActiveMember = 1 THEN 'Active' ELSE 'Inactive' END AS member_status,
    COUNT(*)                                        AS churned_customers,
    ROUND(SUM(RevenueAtRisk), 2)                    AS total_revenue_at_risk,
    ROUND(AVG(RevenueAtRisk), 2)                    AS avg_revenue_at_risk
FROM churn_clean
WHERE Churned = 1
GROUP BY Geography, IsActiveMember
ORDER BY total_revenue_at_risk DESC;

-- SUPPLEMENTAL: Top 10 highest RevenueAtRisk churned customers
SELECT
    CustomerId,
    Geography,
    Gender,
    Age,
    Balance,
    EstimatedSalary,
    NumOfProducts,
    CASE WHEN IsActiveMember = 1 THEN 'Active' ELSE 'Inactive' END AS member_status,
    RevenueAtRisk
FROM churn_clean
WHERE Churned = 1
ORDER BY RevenueAtRisk DESC
LIMIT 10;

-- SUPPLEMENTAL: Overall Revenue at Risk summary
SELECT
    ROUND(SUM(CASE WHEN Churned = 1 THEN RevenueAtRisk ELSE 0 END), 2)  AS churned_revenue_at_risk,
    ROUND(SUM(RevenueAtRisk), 2)                                          AS total_portfolio_revenue,
    ROUND(
        100.0 * SUM(CASE WHEN Churned = 1 THEN RevenueAtRisk ELSE 0 END)
              / NULLIF(SUM(RevenueAtRisk), 0),
        2
    )                                                                     AS pct_revenue_at_risk
FROM churn_clean;
