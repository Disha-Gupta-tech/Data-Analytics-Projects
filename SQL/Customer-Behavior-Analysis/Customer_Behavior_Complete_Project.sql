-- ============================================================
-- PROJECT: Understanding Customer Behavior Through POS Data Analysis
-- DATABASE: Customer_Behavior
-- ============================================================

-- 1. DATABASE SETUP
DROP DATABASE IF EXISTS Customer_Behavior;
CREATE DATABASE Customer_Behavior;
USE Customer_Behavior;

-- After creating the database, import these CSV files into MySQL Workbench:
-- 1. Customer.csv
-- 2. Transactions.csv
-- 3. prod_cat_info.csv
--
-- Suggested table names:
-- Customer
-- Transactions
-- Product_Category

-- ============================================================
-- 2. DATA PREPARATION AND UNDERSTANDING
-- ============================================================

/*
1.	Determine the total number of rows present in each of 
the three tables: Customer, Transactions, and Product Category 
*/
-- Customer Table
SELECT COUNT(*) AS total_rows
FROM Customer; # 5645

-- Product Category Table
SELECT COUNT(*) AS total_rows
FROM prod_cat_info; # 23

-- Transactions Table
SELECT COUNT(*) AS total_rows
FROM transactions; # 23053

/*
Combined Result:
Total number of rows in all three tables
*/
SELECT 'Customer' AS table_name, COUNT(*) AS total_rows FROM Customer
UNION ALL
SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL
SELECT 'Product Category', COUNT(*) FROM Prod_Cat_info;

/*
2.	Identify the total number of returned transactions 
*/
SELECT COUNT(*) AS total_returned_transactions
FROM Transactions
WHERE Qty < 0; #2177

/*
3.	Convert all date fields into valid date formats 
before proceeding with analysis 
*/
SELECT STR_TO_DATE(tran_date, '%d-%m-%Y') AS valid_tran_date
FROM Transactions;

SELECT STR_TO_DATE(DOB, '%d-%m-%Y') AS valid_DOB
FROM customer;

/*
4.	Establish the overall time range of the transaction dataset and 
display the output in terms of days, months, and years 
*/
SELECT 
    MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')) AS start_date,
    MAX(STR_TO_DATE(tran_date, '%d-%m-%Y')) AS end_date,

    DATEDIFF(
        MAX(STR_TO_DATE(tran_date, '%d-%m-%Y')),
        MIN(STR_TO_DATE(tran_date, '%d-%m-%Y'))
    ) AS total_days,

    TIMESTAMPDIFF(
        MONTH,
        MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')),
        MAX(STR_TO_DATE(tran_date, '%d-%m-%Y'))
    ) AS total_months,

    TIMESTAMPDIFF(
        YEAR,
        MIN(STR_TO_DATE(tran_date, '%d-%m-%Y')),
        MAX(STR_TO_DATE(tran_date, '%d-%m-%Y'))
    ) AS total_years

FROM Transactions;

/*
5.	Determine the product category to which the 
sub-category “DIY” belongs 
*/
select * from prod_cat_info where prod_subcat= 'DIY';

-- ============================================================
-- 3. CORE BUSINESS ANALYSIS
-- ============================================================

/*
1.	Identify the most frequently used transaction channel 
*/
select 
Store_type,
count(Store_type) as 'total transaction channel'
from transactions
group by Store_type
order by 2 desc;

/*
2.	Calculate the count of male and female customers 
*/

SELECT Gender, COUNT(*) AS total_customers
FROM Customer
WHERE Gender IN ('M', 'F')
GROUP BY Gender;

/*
3.	Determine which city has the maximum number of customers and provide the count 
*/
SELECT 
    city_code, COUNT(city_code)
FROM
    customer
GROUP BY city_code
ORDER BY 2 DESC
LIMIT 1; #3(city_code)

/*
4.	Ascertain the number of sub-categories under the books category
*/

SELECT COUNT(prod_subcat) AS total_subcategories
FROM prod_cat_info
WHERE prod_cat = 'Books'; #6

/*
5.	Find the maximum quantity ordered in a single transaction 
*/

SELECT 
    MAX(Qty) 'maximum quantity ordered'
FROM
    customer_behavior.transactions;               #5

-- ============================================================
-- 4. REVENUE AND PROFITABILITY ANALYSIS
-- ============================================================

/*
1.	Calculate the net total revenue generated in 
the electronics and books categories 
*/
SELECT 
    pc.prod_cat, ROUND(SUM(t.total_amt), 2) 'net total revenue'
FROM
    transactions t
        INNER JOIN
    prod_cat_info pc ON t.prod_cat_code = pc.prod_cat_code
WHERE
    pc.prod_cat IN ('electronics' , 'books')
GROUP BY 1 WITH ROLLUP; #130548482.42

/*
2.	Identify customers with more than 10 transactions, excluding returns 
*/

SELECT 
    cust_id,
    COUNT(*) AS total_transactions
FROM Transactions
WHERE Qty > 0
GROUP BY cust_id
HAVING COUNT(*) > 10;

/*
3.	Compute combined revenue from electronics and clothing categories in flagship stores 
*/
SELECT 
    pc.prod_cat, ROUND(SUM(t.total_amt), 2) 'net total revenue'
FROM
    transactions t
        INNER JOIN
    prod_cat_info pc ON t.prod_cat_code = pc.prod_cat_code
WHERE
    pc.prod_cat IN ('electronics' , 'clothing') AND t.Store_type = 'Flagship store'
GROUP BY 1 WITH ROLLUP; 

/*
4.	Determine total revenue generated from male customers in 
the electronics category, grouped by sub-category 
*/
SELECT 
    pc.prod_subcat, ROUND(SUM(t.total_amt), 2) 'total revenue'
FROM
    transactions t
        JOIN
    prod_cat_info pc 
    ON t.prod_cat_code = pc.prod_cat_code
    join
    customer c
    on t.cust_id = c.customer_Id
WHERE
    pc.prod_cat = 'electronics' AND c.Gender = 'M'
GROUP BY 1 ; 

/*
5.	Calculate sales and returns percentages by product sub-category,
 displaying the top five sub-categories by sales 
*/
SELECT 
    prod_subcat,
    SUM(CASE
        WHEN t.Qty > 0 THEN 1
        ELSE 0
    END) AS sales,
    SUM(CASE
        WHEN t.Qty < 0 THEN 1
        ELSE 0
    END) AS returns,
    ROUND(SUM(CASE
                WHEN t.Qty > 0 THEN 1
                ELSE 0
            END) * 100 / COUNT(*),
            2) AS sales_percentage,
    ROUND(SUM(CASE
                WHEN t.Qty < 0 THEN 1
                ELSE 0
            END) * 100 / COUNT(*),
            2) AS returns_percentage
FROM
    transactions t
        JOIN
    prod_cat_info pc ON t.prod_cat_code = pc.prod_cat_code
GROUP BY pc.prod_subcat
ORDER BY sales DESC
LIMIT 5;

-- ============================================================
-- 5. TIME-BASED AND DEMOGRAPHIC ANALYSIS
-- ============================================================

/*
1.	Calculate revenue from customers aged 25-35 years during the last 30 days 
from the maximum transaction date 
*/

SELECT
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(c.dob, '%d-%m-%Y'),
        CURDATE()
    ) AS age,
    SUM(t.total_amt) AS revenue
FROM transactions t
JOIN customer c
    ON t.cust_id = c.customer_Id
WHERE TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(c.dob, '%d-%m-%Y'),
        CURDATE()
      ) BETWEEN 25 AND 35
  AND t.tran_date >= DATE_SUB(
        (SELECT MAX(tran_date) FROM transactions),
        INTERVAL 30 DAY
      )
GROUP BY age
ORDER BY revenue DESC; #0

/*
2.	Identify the product category with the highest return 
value in the last three months 
*/
SELECT 
    pc.prod_cat_code,
    pc.prod_cat,
    SUM(ABS(t.total_amt)) AS return_value
FROM transactions t
INNER JOIN prod_cat_info pc 
    ON t.prod_cat_code = pc.prod_cat_code
WHERE t.total_amt <= 0
  AND t.tran_date >= DATE_SUB(
        (SELECT MAX(tran_date) FROM transactions),
        INTERVAL 90 DAY
      )
GROUP BY pc.prod_cat_code, pc.prod_cat
ORDER BY return_value DESC;  #0

/*
3.	Determine which store type generates maximum sales 
by revenue and quantity
*/
SELECT 
    Store_type,
    SUM(Qty) AS total_quantity,
    SUM(total_amt) AS total_revenue
FROM transactions
GROUP BY Store_type
ORDER BY total_revenue DESC;

/*
4.	Identify categories with average revenue above the overall average 
*/
SELECT 
    pc.prod_cat,
    AVG(t.total_amt) AS category_avg_revenue
FROM transactions t
JOIN prod_cat_info pc
    ON t.prod_cat_code = pc.prod_cat_code
GROUP BY pc.prod_cat
HAVING AVG(t.total_amt) > (
    SELECT AVG(total_amt)
    FROM transactions
);

/*
5.	Find average and total revenue by sub-category for the top
 five categories in terms of quantity sold 
*/
SELECT
    pc.prod_cat,
    SUM(t.Qty) AS total_quantity
FROM transactions t
JOIN prod_cat_info pc
    ON t.prod_cat_code = pc.prod_cat_code
WHERE t.Qty > 0
GROUP BY pc.prod_cat
ORDER BY total_quantity DESC
LIMIT 5;

-- ============================================================
-- END OF PROJECT SQL SCRIPT
-- ============================================================










