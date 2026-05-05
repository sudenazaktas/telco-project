--1. Tariff-Based Customer Queries
--1.1 List the customers who are subscribed to the 'Kobiye Destek' tariff.

--This query lists all customers records that subscribe to the 'Kobiye Destek' tariff.
--The CUSTOMERS and TARIFFS tables are joined using TARIFF_ID column.
--The WHERE clause filters for only the tariff called 'Kobiye Destek'.
SELECT * FROM CUSTOMERS c 
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME='Kobiye Destek';


--1.2 Find the newest customer who subscribed to this tariff.

--This query finds the newest customer subscribed to the 'Kobiye Destek' tariff.
--CUSTOMERS and TARIFFS tables are joined on TARIFF_ID to access tariff information.
--A subquery retrieves the maximum SIGNUP_DATE among all 'Kobiye Destek' subscribers.
--The outer query then filters the customer whose signup date matches this maximum date.
SELECT * FROM CUSTOMERS c 
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME = 'Kobiye Destek'
AND c.SIGNUP_DATE = (
	SELECT MAX(c2.SIGNUP_DATE)
	FROM CUSTOMERS c2 
	JOIN TARIFFS t2 ON c2.TARIFF_ID = t2.TARIFF_ID
	WHERE t2.NAME = 'Kobiye Destek'
);


--2. Tariff Distribution
--2.1 Find the distribution of tariffs among the customers.

--The COUNT function counts the number of customers per tariff and the result is labeled
--as CUSTOMER_COUNT using the AS keyword.
--CUSTOMERS and TARIFFS tables are joined on TARIFF_ID to get tariff names.
--GROUP BY is used to count the number of customers per tariff.
--ORDER BY is added to show the most popular tariffs first by using DESC keyword.

SELECT t.NAME, COUNT(c.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS c 
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID 
GROUP BY t.NAME 
ORDER BY CUSTOMER_COUNT DESC;

--3. Customer Signup Analysis
--3.1 Identify the earliest customers to sign up.

--The MIN function is used to find the earliest signup date in the CUSTOMERS table.
--A subquery is used to filter customers whose signup date matches the minimum date.
--Earliest customers may not have the lowest IDs as the hint suggests.
--This means we cannot simply sort by CUSTOMER_ID to find the earliest signups.
--Instead, we must rely on the SIGNUP_DATE column for accurate results.

SELECT * FROM CUSTOMERS
WHERE SIGNUP_DATE = (
	SELECT MIN(SIGNUP_DATE)
	FROM CUSTOMERS
);


--3.2 Find the distribution of these earliest customers across different cities,
--including the total count for each city.

--First, the earliest signup date is found using a subquery with MIN function.
--Then customers with that date are grouped by city to count how many are in each.
--GROUP BY CITY groups all earliest customers by their city field.
--Without GROUP BY, COUNT would return the total number instead of per-city counts.
--The COUNT function counts how many earliest customers belong to each city.
--ORDER BY is used to show cities with the most earliest customers first.

SELECT CITY, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMERS 
WHERE SIGNUP_DATE = (
	SELECT MIN(SIGNUP_DATE)
	FROM CUSTOMERS
) 
GROUP BY CITY
ORDER BY CUSTOMER_COUNT DESC;


--4. Missing Monthly Records
--4.1 Every customer has a monthly fee, and the dataset contains this month's usage values.
--However, an insertion error occurred, and some customers' monthly records are missing.
--Identify the IDs of these missing customers.

--A LEFT JOIN is used to match each customer with their monthly stats record.
--If there are no records for a customer in MONTHLY_STATS table, then ID field would be shown as NULL.
--WHERE clause filters only the customers whose MONTHLY_STATS record is NULL.

SELECT c.CUSTOMER_ID
FROM CUSTOMERS c 
LEFT JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID 
WHERE ms.CUSTOMER_ID IS NULL;


--4.2 Find the distribution of these missing customers across different cities.

--The same LEFT JOIN approach is used to identify customers without monthly records.
--GROUP BY CITY groups the missing customers by their city field.
--COUNT function counts how many missing customers belong to each city.
--ORDER BY shows the cities with the most missing records first.

SELECT CITY, COUNT(*) AS MISSING_COUNT
FROM CUSTOMERS c 
LEFT JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID 
WHERE ms.CUSTOMER_ID IS NULL
GROUP BY c.CITY 
ORDER BY MISSING_COUNT DESC;


--5. Usage Analysis
--5.1 Find the customers who have used at least 75% of their data limit.

--CUSTOMERS, TARIFFS and MONTHLY_STATS tables are joined to access all necessary data.
--DATA_USAGE is divided by DATA_LIMIT and multiplied by 100 to calculate usage percentage.
--The ROUND function rounds the percentage to 2 decimal places for better readability.
--The result is labeled as USAGE_PERCENTAGE using AS keyword to make the output clearer.
--WHERE clause filters only customers whose data usage is 75% or more of their limit.
--The results are ordered by USAGE_PERCENTAGE in descending order
--so the customers closest to or exceeding their limit appear first.
--Customers with a DATA_LIMIT of 0 are excluded to avoid division by zero errors.

SELECT c.CUSTOMER_ID, c.NAME, ms.DATA_USAGE, t.DATA_LIMIT,
	ROUND (ms.DATA_USAGE / t.DATA_LIMIT * 100,2) AS USAGE_PERCENTAGE
FROM CUSTOMERS c 
JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID 
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.DATA_LIMIT > 0
AND ms.DATA_USAGE >= t.DATA_LIMIT * 0.75
ORDER BY USAGE_PERCENTAGE DESC;

--5.2 Identify the customers who have completely exhausted all of their package limits (data, minutes, and SMS).
--CUSTOMERS, TARIFFS and MONTHLY_STATS tables are joined to compare usage with limits.
--All three conditions must be true simultaneously so AND operator is used.
--If DATA_LIMIT or MINUTE_LIMIT is 0, that field is considered as already exhausted.
--OR t.DATA_LIMIT = 0 condition is added to handle tariffs with no data or minute limit.
--A customer appears in results only if they have used 100% of all three limits.
--The query returns an empty result set because no customer has fully exhausted 
--all three limits simultaneously in the current dataset.

SELECT c.CUSTOMER_ID, c.NAME, ms.DATA_USAGE, ms.MINUTE_USAGE, ms.SMS_USAGE
FROM CUSTOMERS c
JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE (ms.DATA_USAGE >= t.DATA_LIMIT OR t.DATA_LIMIT = 0)
AND (ms.MINUTE_USAGE >= t.MINUTE_LIMIT OR t.MINUTE_LIMIT = 0)
AND (ms.SMS_USAGE >= t.SMS_LIMIT OR t.SMS_LIMIT = 0);


--6. Payment Analysis
--6.1 Find the customers who have unpaid fees.

--CUSTOMERS and MONTHLY_STATS tables are joined on CUSTOMER_ID to access payment info.
--The dataset contains three payment statuses: PAID, LATE, and UNPAID.
--The != operator is used to filter out only PAID records from the results.
--This means both LATE and UNPAID customers are included in the output.

SELECT c.CUSTOMER_ID, c.NAME, c.CITY, ms.PAYMENT_STATUS
FROM CUSTOMERS c
JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID
WHERE ms.PAYMENT_STATUS != 'PAID';

--6.2 Find the distribution of all payment statuses across the different tariffs.
--CUSTOMERS, TARIFFS and MONTHLY_STATS tables are all joined together.
--CUSTOMERS is the bridge table connecting TARIFFS and MONTHLY_STATS.
--GROUP BY t.NAME, m.PAYMENT_STATUS groups results by both tariff name and payment status.
--This means each tariff gets a separate row for each payment status (PAID, LATE, UNPAID).
--COUNT(*) counts how many customers fall into each tariff and payment status combination.
--ORDER BY t.NAME, m.PAYMENT_STATUS sorts results alphabetically for easier reading.

SELECT t.NAME AS TARIFF_NAME, ms.PAYMENT_STATUS, COUNT(*) AS COUNT
FROM CUSTOMERS c
JOIN MONTHLY_STATS ms ON c.CUSTOMER_ID = ms.CUSTOMER_ID
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
GROUP BY t.NAME, ms.PAYMENT_STATUS
ORDER BY t.NAME, ms.PAYMENT_STATUS;