-- 1. Create Table

CREATE TABLE upi_transactions (
    transaction_id NUMBER PRIMARY KEY,
    user_id NUMBER,
    amount NUMBER(10,2),
    category VARCHAR2(50),
    transaction_type VARCHAR2(20),
    merchant_name VARCHAR2(100),
    payment_app VARCHAR2(50),
    city VARCHAR2(50),
    device_type VARCHAR2(20),
    transaction_datetime TIMESTAMP,
    status VARCHAR2(20)
);

-- 2. Data Generation

INSERT INTO upi_transactions
SELECT 
    LEVEL AS transaction_id,
    MOD(LEVEL, 10) + 100 AS user_id,
    ROUND(DBMS_RANDOM.VALUE(50, 3000), 2) AS amount,
    
    CASE MOD(LEVEL, 6)
        WHEN 0 THEN 'Food'
        WHEN 1 THEN 'Shopping'
        WHEN 2 THEN 'Bills'
        WHEN 3 THEN 'Travel'
        WHEN 4 THEN 'Entertainment'
        ELSE 'Groceries'
    END AS category,
    
    CASE 
        WHEN MOD(LEVEL, 5) = 0 THEN 'transfer'
        ELSE 'expense'
    END AS transaction_type,
    
    CASE MOD(LEVEL, 5)
        WHEN 0 THEN 'Friend Transfer'
        WHEN 1 THEN 'Amazon'
        WHEN 2 THEN 'Swiggy'
        WHEN 3 THEN 'Uber'
        ELSE 'Netflix'
    END AS merchant_name,
    
    CASE MOD(LEVEL, 3)
        WHEN 0 THEN 'GPay'
        WHEN 1 THEN 'PhonePe'
        ELSE 'Paytm'
    END AS payment_app,
    
    CASE MOD(LEVEL, 4)
        WHEN 0 THEN 'Chennai'
        WHEN 1 THEN 'Bangalore'
        WHEN 2 THEN 'Mumbai'
        ELSE 'Delhi'
    END AS city,
    
    CASE MOD(LEVEL, 2)
        WHEN 0 THEN 'Android'
        ELSE 'iOS'
    END AS device_type,
    
    TO_TIMESTAMP('2024-05-01 10:00:00','YYYY-MM-DD HH24:MI:SS') 
        + NUMTODSINTERVAL(LEVEL * 3, 'HOUR') AS transaction_datetime,
    
    CASE 
        WHEN MOD(LEVEL, 10) = 0 THEN 'failed'
        ELSE 'success'
    END AS status

FROM dual
CONNECT BY LEVEL <= 300;

-- 3. Data Cleaning
--    3.1 Create Clean Dataset

CREATE VIEW clean_data AS
  SELECT *
     FROM upi_transactions
WHERE status = 'success';

-- 4. User Spending Behavior

SELECT 
    user_id,
    total_spent,
    CASE 
        WHEN segment = 1 THEN 'Low Spender'
        WHEN segment = 2 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS user_type
FROM (
    SELECT 
        user_id,
        SUM(amount) AS total_spent,
        NTILE(3) OVER (ORDER BY SUM(amount)) AS segment
    FROM clean_data
    WHERE transaction_type = 'expense'
    GROUP BY user_id
);

-- 5. Peak Transaction Time Analysis

SELECT 
    hour,
    total_transactions,
    CASE 
        WHEN total_transactions > 30 THEN 'Peak Time'
        ELSE 'Normal'
    END AS activity_level
FROM (
    SELECT 
        EXTRACT(HOUR FROM transaction_datetime) AS hour,
        COUNT(*) AS total_transactions
    FROM clean_data
    GROUP BY EXTRACT(HOUR FROM transaction_datetime)
)
ORDER BY total_transactions DESC;

-- 6. Category-wise Spending Analysis
--    6.1 Total Spending by Category

SELECT 
    category,
    SUM(amount) AS total_spent
FROM clean_data
WHERE transaction_type = 'expense'
GROUP BY category
ORDER BY total_spent DESC;

--    6.2 Number of Transactions per Category

SELECT 
    category,
    COUNT(*) AS total_transactions
FROM clean_data
WHERE transaction_type = 'expense'
GROUP BY category
ORDER BY total_transactions DESC;

--    6.3 Average Spending per Category

SELECT 
    category,
    ROUND(AVG(amount),2) AS avg_spend
FROM clean_data
WHERE transaction_type = 'expense'
GROUP BY category
ORDER BY avg_spend DESC;

-- 7. Anomaly Detection
--    7.1 Find Average Spending

SELECT AVG(amount) AS avg_spend
FROM clean_data
WHERE transaction_type = 'expense';

--    7.2 Detect High Value Transactions

-- Rule: If amount > 2x average → anomaly
SELECT 
    transaction_id,
    user_id,
    amount,
    category,
    CASE 
        WHEN amount > (
            SELECT AVG(amount) * 2 
            FROM clean_data
            WHERE transaction_type = 'expense'
        ) THEN 'Anomaly'
        ELSE 'Normal'
    END AS transaction_flag
FROM clean_data
WHERE transaction_type = 'expense';