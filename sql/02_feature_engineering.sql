-- ============================================================
-- 02_FEATURE_ENGINEERING.SQL
-- Bank Customer Churn Analysis
-- Prerequisite: 01_data_cleaning.sql has been run
-- ============================================================

-- ------------------------------------------------------------
-- FEATURE 1: Age Group
-- ------------------------------------------------------------
-- Bucket customers into lifecycle segments
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS AgeGroup VARCHAR(20);

UPDATE churn_clean
SET AgeGroup = CASE
    WHEN Age < 25              THEN '18-24 Young Adult'
    WHEN Age BETWEEN 25 AND 34 THEN '25-34 Early Career'
    WHEN Age BETWEEN 35 AND 44 THEN '35-44 Mid Career'
    WHEN Age BETWEEN 45 AND 54 THEN '45-54 Pre-Senior'
    WHEN Age BETWEEN 55 AND 64 THEN '55-64 Senior'
    ELSE                            '65+ Retired'
END;

-- ------------------------------------------------------------
-- FEATURE 2: Credit Score Band
-- ------------------------------------------------------------
-- Standard US FICO-style bands
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS CreditBand VARCHAR(20);

UPDATE churn_clean
SET CreditBand = CASE
    WHEN CreditScore <  580 THEN 'Poor (300-579)'
    WHEN CreditScore <  670 THEN 'Fair (580-669)'
    WHEN CreditScore <  740 THEN 'Good (670-739)'
    WHEN CreditScore <  800 THEN 'Very Good (740-799)'
    ELSE                         'Exceptional (800+)'
END;

-- ------------------------------------------------------------
-- FEATURE 3: Balance Segment
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS BalanceSegment VARCHAR(25);

UPDATE churn_clean
SET BalanceSegment = CASE
    WHEN Balance = 0                    THEN 'Zero Balance'
    WHEN Balance < 50000                THEN 'Low (<50K)'
    WHEN Balance BETWEEN 50000 AND 99999  THEN 'Medium (50K-100K)'
    WHEN Balance BETWEEN 100000 AND 149999 THEN 'High (100K-150K)'
    ELSE                                     'Premium (150K+)'
END;

-- ------------------------------------------------------------
-- FEATURE 4: Salary Segment
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS SalarySegment VARCHAR(20);

UPDATE churn_clean
SET SalarySegment = CASE
    WHEN EstimatedSalary <  50000                   THEN 'Low (<50K)'
    WHEN EstimatedSalary BETWEEN 50000  AND 99999   THEN 'Lower-Mid (50K-100K)'
    WHEN EstimatedSalary BETWEEN 100000 AND 149999  THEN 'Upper-Mid (100K-150K)'
    WHEN EstimatedSalary BETWEEN 150000 AND 199999  THEN 'High (150K-200K)'
    ELSE                                                 'Very High (200K+)'
END;

-- ------------------------------------------------------------
-- FEATURE 5: Tenure Group
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS TenureGroup VARCHAR(20);

UPDATE churn_clean
SET TenureGroup = CASE
    WHEN Tenure = 0                THEN 'New (0 yr)'
    WHEN Tenure BETWEEN 1 AND 2   THEN 'Early (1-2 yrs)'
    WHEN Tenure BETWEEN 3 AND 5   THEN 'Mid (3-5 yrs)'
    WHEN Tenure BETWEEN 6 AND 8   THEN 'Loyal (6-8 yrs)'
    ELSE                               'Long-term (9-10 yrs)'
END;

-- ------------------------------------------------------------
-- FEATURE 6: Customer Profile (composite segment)
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS CustomerProfile VARCHAR(30);

UPDATE churn_clean
SET CustomerProfile = CASE
    WHEN IsActiveMember = 1 AND Balance > 100000  THEN 'Active High-Value'
    WHEN IsActiveMember = 1 AND Balance <= 100000 THEN 'Active Standard'
    WHEN IsActiveMember = 0 AND Balance > 100000  THEN 'Dormant High-Value'
    ELSE                                               'Dormant Standard'
END;

-- ------------------------------------------------------------
-- FEATURE 7: Revenue at Risk (simplified annual proxy)
-- ------------------------------------------------------------
-- Assume 1% net interest margin on balance + 0.5% on salary (spending proxy)
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS RevenueAtRisk DECIMAL(15,2);

UPDATE churn_clean
SET RevenueAtRisk = ROUND(
    (Balance * 0.01) + (EstimatedSalary * 0.005),
    2
);

-- ------------------------------------------------------------
-- FEATURE 8: Is Zero Balance (binary flag)
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS IsZeroBalance SMALLINT;

UPDATE churn_clean
SET IsZeroBalance = CASE WHEN Balance = 0 THEN 1 ELSE 0 END;

-- ------------------------------------------------------------
-- FEATURE 9: Products + Active (interaction)
-- ------------------------------------------------------------
ALTER TABLE churn_clean ADD COLUMN IF NOT EXISTS ProductsActiveCombo VARCHAR(30);

UPDATE churn_clean
SET ProductsActiveCombo = CONCAT(
    NumOfProducts, ' Product(s) | ',
    CASE WHEN IsActiveMember = 1 THEN 'Active' ELSE 'Inactive' END
);

-- ------------------------------------------------------------
-- VALIDATION: Preview engineered features
-- ------------------------------------------------------------
SELECT
    CustomerId,
    Age,          AgeGroup,
    CreditScore,  CreditBand,
    Balance,      BalanceSegment,
    EstimatedSalary, SalarySegment,
    Tenure,       TenureGroup,
    CustomerProfile,
    RevenueAtRisk,
    IsZeroBalance,
    ProductsActiveCombo,
    Churned
FROM churn_clean
LIMIT 10;

-- ------------------------------------------------------------
-- FEATURE CHURN RATES — Quick sanity check
-- ------------------------------------------------------------
SELECT AgeGroup,        ROUND(100.0 * AVG(Churned),2) AS churn_pct FROM churn_clean GROUP BY 1 ORDER BY 1;
SELECT CreditBand,      ROUND(100.0 * AVG(Churned),2) AS churn_pct FROM churn_clean GROUP BY 1 ORDER BY 1;
SELECT BalanceSegment,  ROUND(100.0 * AVG(Churned),2) AS churn_pct FROM churn_clean GROUP BY 1 ORDER BY 1;
SELECT CustomerProfile, ROUND(100.0 * AVG(Churned),2) AS churn_pct FROM churn_clean GROUP BY 1 ORDER BY 1;
