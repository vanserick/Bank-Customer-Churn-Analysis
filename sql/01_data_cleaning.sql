-- ============================================================
-- 01_DATA_CLEANING.SQL
-- Bank Customer Churn Analysis
-- Dataset: Churn_Modelling.csv (10,000 rows, 14 columns)
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1: Create raw staging table
-- ------------------------------------------------------------
DROP TABLE IF EXISTS churn_raw;

CREATE TABLE churn_raw (
    RowNumber        INTEGER,
    CustomerId       BIGINT,
    Surname          VARCHAR(100),
    CreditScore      INTEGER,
    Geography        VARCHAR(50),
    Gender           VARCHAR(10),
    Age              INTEGER,
    Tenure           INTEGER,
    Balance          DECIMAL(15,2),
    NumOfProducts    INTEGER,
    HasCrCard        SMALLINT,
    IsActiveMember   SMALLINT,
    EstimatedSalary  DECIMAL(15,2),
    Exited           SMALLINT
);

-- Load from CSV (adjust path as needed for your environment)
-- COPY churn_raw FROM '/path/to/Churn_Modelling.csv' DELIMITER ',' CSV HEADER;

-- ------------------------------------------------------------
-- STEP 2: Inspect for quality issues
-- ------------------------------------------------------------

-- 2a. Row count
SELECT COUNT(*) AS total_rows FROM churn_raw;
-- Expected: 10,000

-- 2b. Duplicate CustomerId check
SELECT CustomerId, COUNT(*) AS cnt
FROM churn_raw
GROUP BY CustomerId
HAVING COUNT(*) > 1;

-- 2c. Null / blank checks per column
SELECT
    SUM(CASE WHEN CustomerId       IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN Surname          IS NULL OR TRIM(Surname) = '' THEN 1 ELSE 0 END) AS null_surname,
    SUM(CASE WHEN CreditScore      IS NULL THEN 1 ELSE 0 END) AS null_credit_score,
    SUM(CASE WHEN Geography        IS NULL OR TRIM(Geography) = '' THEN 1 ELSE 0 END) AS null_geography,
    SUM(CASE WHEN Gender           IS NULL OR TRIM(Gender) = '' THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN Age              IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN Tenure           IS NULL THEN 1 ELSE 0 END) AS null_tenure,
    SUM(CASE WHEN Balance          IS NULL THEN 1 ELSE 0 END) AS null_balance,
    SUM(CASE WHEN NumOfProducts    IS NULL THEN 1 ELSE 0 END) AS null_num_products,
    SUM(CASE WHEN HasCrCard        IS NULL THEN 1 ELSE 0 END) AS null_has_cr_card,
    SUM(CASE WHEN IsActiveMember   IS NULL THEN 1 ELSE 0 END) AS null_is_active,
    SUM(CASE WHEN EstimatedSalary  IS NULL THEN 1 ELSE 0 END) AS null_salary,
    SUM(CASE WHEN Exited           IS NULL THEN 1 ELSE 0 END) AS null_exited
FROM churn_raw;

-- 2d. Out-of-range value checks
SELECT
    SUM(CASE WHEN CreditScore < 300 OR CreditScore > 850 THEN 1 ELSE 0 END) AS invalid_credit_score,
    SUM(CASE WHEN Age < 18 OR Age > 100 THEN 1 ELSE 0 END)                  AS invalid_age,
    SUM(CASE WHEN Tenure < 0 OR Tenure > 50 THEN 1 ELSE 0 END)              AS invalid_tenure,
    SUM(CASE WHEN Balance < 0 THEN 1 ELSE 0 END)                            AS negative_balance,
    SUM(CASE WHEN NumOfProducts < 1 OR NumOfProducts > 10 THEN 1 ELSE 0 END) AS invalid_products,
    SUM(CASE WHEN HasCrCard NOT IN (0,1) THEN 1 ELSE 0 END)                 AS invalid_has_cr_card,
    SUM(CASE WHEN IsActiveMember NOT IN (0,1) THEN 1 ELSE 0 END)            AS invalid_is_active,
    SUM(CASE WHEN EstimatedSalary < 0 THEN 1 ELSE 0 END)                    AS negative_salary,
    SUM(CASE WHEN Exited NOT IN (0,1) THEN 1 ELSE 0 END)                    AS invalid_exited
FROM churn_raw;

-- 2e. Distinct values for categorical fields
SELECT DISTINCT Geography FROM churn_raw ORDER BY 1;
SELECT DISTINCT Gender    FROM churn_raw ORDER BY 1;
SELECT DISTINCT NumOfProducts FROM churn_raw ORDER BY 1;

-- ------------------------------------------------------------
-- STEP 3: Create cleaned table
-- ------------------------------------------------------------
DROP TABLE IF EXISTS churn_clean;

CREATE TABLE churn_clean AS
SELECT
    -- Primary key
    CustomerId,

    -- Identifiers (drop RowNumber — unstable surrogate)
    TRIM(Surname)                         AS Surname,

    -- Standardise categoricals to proper case
    INITCAP(TRIM(Geography))              AS Geography,
    INITCAP(TRIM(Gender))                 AS Gender,

    -- Numeric fields — cast & clamp edge cases
    CASE
        WHEN CreditScore < 300 THEN 300
        WHEN CreditScore > 850 THEN 850
        ELSE CreditScore
    END                                   AS CreditScore,

    CASE
        WHEN Age < 18 THEN 18
        WHEN Age > 100 THEN 100
        ELSE Age
    END                                   AS Age,

    CASE
        WHEN Tenure < 0 THEN 0
        ELSE Tenure
    END                                   AS Tenure,

    GREATEST(Balance, 0)                  AS Balance,

    NumOfProducts,

    -- Boolean flags as clean integers
    CASE WHEN HasCrCard     = 1 THEN 1 ELSE 0 END AS HasCrCard,
    CASE WHEN IsActiveMember = 1 THEN 1 ELSE 0 END AS IsActiveMember,

    GREATEST(EstimatedSalary, 0)          AS EstimatedSalary,

    -- Target variable
    CASE WHEN Exited = 1 THEN 1 ELSE 0 END AS Churned

FROM churn_raw
WHERE CustomerId IS NOT NULL          -- drop rows with no identifier
ORDER BY CustomerId;

-- ------------------------------------------------------------
-- STEP 4: Validation — compare row counts
-- ------------------------------------------------------------
SELECT 'raw'   AS source, COUNT(*) AS rows FROM churn_raw
UNION ALL
SELECT 'clean' AS source, COUNT(*) AS rows FROM churn_clean;

-- ------------------------------------------------------------
-- STEP 5: Summary statistics on cleaned data
-- ------------------------------------------------------------
SELECT
    COUNT(*)                                        AS total_customers,
    SUM(Churned)                                    AS churned_customers,
    ROUND(100.0 * SUM(Churned) / COUNT(*), 2)       AS churn_rate_pct,
    ROUND(AVG(CreditScore), 1)                      AS avg_credit_score,
    ROUND(AVG(Age), 1)                              AS avg_age,
    ROUND(AVG(Tenure), 1)                           AS avg_tenure,
    ROUND(AVG(Balance), 2)                          AS avg_balance,
    ROUND(AVG(EstimatedSalary), 2)                  AS avg_estimated_salary
FROM churn_clean;
