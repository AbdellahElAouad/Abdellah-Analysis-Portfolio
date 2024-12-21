/* After cleaning the data, I will analyze it to answer key questions and provide valuable insights. */
--------------------------------------------------------------------------------------
-- 1. What is the total amount that each customer has recorded to date?
-- 2. Which customer type generates the highest revenue for the company?
-- 3. Which customer types, across different geographic zones, generate the highest amount of transaction value?
-- 4. Which top 5 products are most frequently purchased by each customer type?
-- 5. What is the transaction share of each product type?
-- 6. What is the total revenue from own-brand products in each geographic zone?
-- 7. What is the total quantity of transactions and the value for each customer type by month and year?
-- 8. Which markets generate the highest revenue during each quarter?
--------------------------------------------------------------------------------------

		-- 1. What is the total amount that each customer has recorded to date?

SELECT 
  C.customer_code, C.custmer_name,
  SUM(T.sales_qty) AS total_sales_qty,
  ROUND(SUM(T.sales_amount_usd), 0) AS total_sales_usd
FROM 
  Transactions T
LEFT JOIN 
  Customers C
ON C.customer_code = T.customer_code
GROUP BY
  C.customer_code,C.custmer_name 
ORDER BY
  total_sales_usd DESC;



		-- 2. Which customer type generates the highest revenue for the company?

SELECT 
  C.customer_type, 
  COUNT(T.customer_code) AS total_transactions,
  SUM(T.sales_amount_usd) AS total_amount_usd
FROM 
  Transactions T
JOIN 
  Customers C
ON 
  C.customer_code = T.customer_code
GROUP BY 
  C.customer_type;



		-- 3. Which customer types, across different geographic zones, generate the highest amount of transaction value?

WITH SumTransactionValues AS (
SELECT
  M.zone, 
  C.customer_type,
  SUM(T.sales_amount_usd) AS sum_transaction_val
FROM 
  Transactions T
JOIN 
  Customers C ON T.customer_code = C.customer_code
JOIN 
  Markets M ON T.market_code = M.market_code
GROUP BY 
  M.zone, C.customer_type
)
SELECT 
  zone,
  customer_type,
  sum_transaction_val
FROM 
  SumTransactionValues
WHERE 
  sum_transaction_val = (
    SELECT 
      MAX(sum_transaction_val)
    FROM 
      SumTransactionValues AS ST
    WHERE 
      ST.zone = SumTransactionValues.zone
    )
ORDER BY 
  zone;



	-- 4. Which top 5 products are most frequently purchased by each customer type?

WITH QTYPURCHASED AS(
SELECT
  P.product_code,
  C.customer_type,
  SUM(sales_qty) AS purchased_qty,
  ROW_NUMBER() OVER (PARTITION BY C.customer_type ORDER BY SUM(T.sales_qty) DESC) AS rank
FROM
  Transactions T
JOIN
  Products P ON T.product_code = P.product_code
JOIN
  Customers C ON T.customer_code = C.customer_code
GROUP BY 
  P.product_code, C.customer_type
  )
SELECT 
  product_code,
  customer_type,
  purchased_qty
FROM
  QTYPURCHASED
WHERE 
  rank <= 5
ORDER BY
  customer_type, purchased_qty DESC; 



	-- 5. What is the transaction share of each product type?

SELECT
  P.product_type,
  COUNT(T.product_code) AS transaction_count,
  COUNT(T.product_code) * 100.0 / SUM(COUNT(T.product_code)) OVER () AS transaction_share_percentage
FROM
  Products P
LEFT JOIN
  Transactions T ON T.product_code = P.product_code
GROUP BY
  P.product_type
ORDER BY
  transaction_share_percentage DESC;



	-- 6. What is the total revenue from own-brand products in each City and geographic zone?

SELECT
  P.product_type,
  M.market_name,
  M.zone,
  SUM(T.sales_amount_usd) AS total_revenue
FROM
  Transactions T
JOIN
  Products P ON T.product_code = P.product_code
JOIN
  Markets M ON T.market_code = M.market_code
GROUP BY 
  P.product_type, M.market_name, M.zone
ORDER BY
  M.zone, total_revenue DESC;



	  --7. What is the total quantity of transactions and the value for each customer type by month and year?

SELECT 
  c.customer_type,
  DATEPART(YEAR, d.date) AS Year,
  RIGHT(d.date_yy_mmm, 4) AS Month,
  SUM(t.sales_qty) AS total_transaction_qty,
  SUM(t.sales_amount_usd) AS total_transaction_value
FROM 
  Transactions t
JOIN 
  Customers c ON t.customer_code = c.customer_code
JOIN 
  Date d ON t.order_date = d.date
GROUP BY 
  c.customer_type, DATEPART(YEAR, d.date), RIGHT(d.date_yy_mmm, 4)
ORDER BY 
  Year, Month, c.customer_type;



	  --8. Which markets generate the highest revenue during each quarter?

SELECT 
  m.market_name,
  DATEPART(YEAR, d.date) AS Year,
  DATEPART(QUARTER, d.date) AS Quarter,
  SUM(t.sales_amount_usd) AS Total_Revenue
FROM 
  Transactions t
JOIN 
  Markets m ON t.market_code = m.market_code
JOIN 
  Date d ON t.order_date = d.date
GROUP BY 
  m.market_name, DATEPART(YEAR, d.date), DATEPART(QUARTER, d.date)
ORDER BY 
  Year, Quarter, Total_Revenue DESC;
