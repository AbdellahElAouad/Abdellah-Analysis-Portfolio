/* In this cleaning process I will go through these five tables in my database (ATLIX_Project): */
----------------------------------------------------------------------------------------------------
--1. Customers: where we find a unique customer code, each customer name, and their type of business
--2. Markets: there is a market code, name (city), and geographic zone
--3. Products: product code, and whether it is locally made by the company or a distribution
--4. Date: date time detailed
--5. Transactions:  where we find detailed information about every transaction made (sales)
----------------------------------------------------------------------------------------------------

--Selecting tables to detect flows:

  --Customers Table:
SELECT  *
FROM
  ATLIX_Project..Customers
ORDER BY
  customer_code;







  --Markets Table:
SELECT  *
FROM
  ATLIX_Project..Markets
ORDER BY
  market_code;

--===================================
/*
STEP 1: Handling the missing values in the zone column next to (Paris, Naw York).
STEP 2: I will change the last two market codes to suit the previous ones in their numerical order
*/


SELECT *
FROM
  ATLIX_Project..Markets
WHERE
  zone IS NULL;



--STEP 1:
UPDATE Markets
SET
  zone = 'West'
WHERE
  zone IS NULL;



--STEP 2:
UPDATE Markets
SET
  market_code = CASE
    WHEN market_code = 'Mark097' THEN 'Mark016'
    WHEN market_code = 'Mark999' THEN 'Mark017'
  END
WHERE
  market_code IN ('Mark097', 'Mark999');

--====================================================================================================







  --Products Table:
SELECT  *
FROM 
  ATLIX_Project..Products
ORDER BY
  product_code;







  --Date Table:
SELECT  *
FROM 
  ATLIX_Project..Date
ORDER BY 
  date;

--===================================

UPDATE Date
SET cy_date = CAST(cy_date AS DATE),
    date = CAST(date AS DATE);



ALTER TABLE Date
ALTER COLUMN cy_date DATE;

ALTER TABLE Date
ALTER COLUMN date DATE;

--====================================================================================================







  --Transactions Table:
SELECT  *
FROM 
  ATLIX_Project..Transactions
ORDER BY 
  sales_amount, sales_qty;

--===================================
/*
STEP 1: Detecting if there are some duplicate rows
STEP 2: Removing the duplicates
*/


SELECT DISTINCT *
FROM
  Transactions
ORDER BY 
  order_date;



	-- Identifying the number of value duplicates:
SELECT
  order_date, sales_qty, sales_amount_usd, 
  product_code, customer_code, market_code,
  COUNT(*)
FROM
  Transactions
GROUP BY
  product_code, customer_code, market_code,
  order_date, sales_qty, sales_amount_usd
HAVING
  COUNT(*) > 1
ORDER BY
  order_date;





/* Create a backup table with all data from Transactions in case of missing something */

        -- Step 1: Create an empty backup table with the same structure as Transactions
CREATE TABLE Transactions_backup (
	product_code NVARCHAR(255),
	customer_code NVARCHAR(255),
	market_code NVARCHAR(255),
    order_date DATE,
    sales_qty FLOAT,
	currency VARCHAR(255),
    sales_amount_usd INT
	);



	-- Step 2: Insert all data from Transactions into Transactions_backup
INSERT INTO Transactions_backup
SELECT *
FROM Transactions;





/* Removing transactions' duplicates using temp table not to risk losing data */

	-- Step 1: Create the temporary table with the same structure as Transactions
CREATE TABLE Transactions_temp (
		product_code NVARCHAR(255),
		customer_code NVARCHAR(255),
		market_code NVARCHAR(255),
    		order_date DATE,
    		sales_qty FLOAT,
		currency VARCHAR(255),
    		sales_amount_usd INT
	);



	-- Step 2: Insert unique records into Transactions_temp
INSERT INTO 
	Transactions_temp (product_code, customer_code, market_code, order_date, sales_qty, currency, sales_amount_usd )
SELECT DISTINCT 
	product_code, customer_code, market_code,
    	order_date, sales_qty, currency, sales_amount_usd
FROM 
    	Transactions;



	-- Step 3: Delete all records from Transactions
DELETE FROM 
	Transactions;



	-- Step 4: Insert unique records back into Transactions from Transactions_temp and drop the table
INSERT INTO 
	Transactions (product_code, customer_code, market_code, order_date, sales_qty, currency, sales_amount_usd)
SELECT 
	product_code, customer_code, market_code,
    	order_date, sales_qty, currency, sales_amount_usd
FROM 
    	Transactions_temp;


DROP TABLE Transactions_temp;

DROP TABLE Transactions_backup;

----------------------------------------------------------




/*
STEP 2: Change the order_date data type in the Transactions Table.
*/

UPDATE Transactions
SET order_date = CAST(order_date AS DATE);



ALTER TABLE Transactions
ALTER COLUMN order_date DATE;

----------------------------------------------------------



/*
STEP 3: Since these numbers are not logical, let's select the rows where the sales amount is less or equal to 0
and delete them.
*/

SELECT  *
FROM 
  ATLIX_Project..Transactions
WHERE 
  sales_amount <= 0;



BEGIN TRANSACTION;

DELETE FROM Transactions
WHERE
  sales_amount <= 0;

ROLLBACK TRANSACTION;    --Rows Restoration command



SELECT  *
FROM 
  ATLIX_Project..Transactions
ORDER BY 
  sales_amount, sales_qty;

----------------------------------------------------------



/*
STEP 4: Converting sales amounts from INR to USD and removing the currency column
*/

SELECT
  sales_amount,
  currency
FROM
  ATLIX_Project..Transactions
ORDER BY
  sales_amount DESC;





        -- 1. Creating a column where I will convert the sales_amount from 'INR' to 'USD' by multiplying it by 0.012 :

ALTER TABLE Transactions DROP COLUMN IF EXISTS sales_amount_usd;
ALTER TABLE Transactions ADD sales_amount_usd int;
Update Transactions 
	Set sales_amount_usd = CASE
		WHEN Upper(RTRIM(currency)) = 'INR' THEN Round(sales_amount * 0.012, 0)    --converting all currencies from INR to USD
		WHEN Upper(RTRIM(currency)) = 'USD' THEN sales_amount
		ELSE sales_amount
	END;



SELECT
  sales_amount,
  currency,
  sales_amount_usd
FROM
  ATLIX_Project..Transactions 
ORDER BY sales_amount DESC;





        -- 2. The TRIM function didn't work on all values in the sales_amount column, there is a non-printable character to remove.

	-- Step 1: Identify the issue with non-printable characters
SELECT DISTINCT 
  currency,
  LEN(currency) AS length
FROM
  Transactions

	

	-- Step 2: Check the ASCII value of the last character in the currency field  
SELECT
  sales_amount,
  currency,
  ASCII(SUBSTRING(currency, LEN (currency), 1)) AS lastChar,         -- Find ASCII code of the last character
  LEN (SUBSTRING(currency, LEN (currency), 1)) AS lastCharLength
FROM
  Transactions
WHERE
  currency NOT IN ('INR', 'USD');



	-- Step 3: Remove non-printable characters (e.g., CHAR(9), CHAR(10), CHAR(13))
UPDATE Transactions
SET currency = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(currency, CHAR(13), ''), CHAR(10), ''), CHAR(9), '')));



	-- Step 4: Verify that non-printable characters have been removed
SELECT 
  DISTINCT currency, 
  LEN(currency) AS length
FROM 
  Transactions
WHERE 
  currency NOT IN ('INR', 'USD');





        -- 3. Rerun the calculation query:
        
ALTER TABLE Transactions DROP COLUMN IF EXISTS sales_amount_usd;
ALTER TABLE Transactions ADD sales_amount_usd int;

Update Transactions 
	Set sales_amount_usd = CASE
		WHEN Upper(RTRIM(currency)) = 'INR' THEN Round(sales_amount * 0.012, 0)    --converting all currencies from INR to USD
		WHEN Upper(RTRIM(currency)) = 'USD' THEN sales_amount
		ELSE sales_amount
	END;



SELECT
  sales_amount,
  currency,
  sales_amount_usd
FROM
  ATLIX_Project..Transactions 
ORDER BY sales_amount DESC;





        -- 4. Then I will change the currency symbols in the currency column:

UPDATE Transactions
SET currency = 'USD';
--====================================================================================================
