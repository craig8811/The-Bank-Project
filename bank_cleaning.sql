/*


Cleaning Data For Bank Customer Segmentation Project


*/


-- Preview the data
SELECT *
FROM bank_churn
LIMIT 100



-- 1. Handle Missing Values
-- Check for the missing values in each column
SELECT 
    SUM(CASE WHEN clietnum IS NULL THEN 1 ELSE 0 END) as clietnum_nulls
	,SUM(CASE WHEN attrition_flag IS NULL THEN 1 ELSE 0 END) as attrition_flag_nulls
	,SUM(CASE WHEN customer_age IS NULL THEN 1 ELSE 0 END) as customer_age_nulls
	,SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as gender_nulls
	,SUM(CASE WHEN dependent_count IS NULL THEN 1 ELSE 0 END) as dependent_count_nulls
	,SUM(CASE WHEN education_level IS NULL THEN 1 ELSE 0 END) as education_level_nulls
	,SUM(CASE WHEN marital_status IS NULL THEN 1 ELSE 0 END) as marital_status_nulls
	,SUM(CASE WHEN income_category IS NULL THEN 1 ELSE 0 END) as income_category_nulls
	,SUM(CASE WHEN card_category IS NULL THEN 1 ELSE 0 END) as card_category_nulls
	,SUM(CASE WHEN months_on_book IS NULL THEN 1 ELSE 0 END) as months_on_book_nulls
	,SUM(CASE WHEN total_relationship_count IS NULL THEN 1 ELSE 0 END) as total_relationship_count_nulls
	,SUM(CASE WHEN months_inactive IS NULL THEN 1 ELSE 0 END) as months_inactive_nulls
	,SUM(CASE WHEN contacts_count IS NULL THEN 1 ELSE 0 END) as contacts_count_nulls
	,SUM(CASE WHEN credit_limit IS NULL THEN 1 ELSE 0 END) as credit_limit_nulls
	,SUM(CASE WHEN total_revolving_bal IS NULL THEN 1 ELSE 0 END) as total_revolving_bal_nulls
	,SUM(CASE WHEN avg_open_to_buy IS NULL THEN 1 ELSE 0 END) as avg_open_to_buy_nulls
	,SUM(CASE WHEN total_amt_change_q4_q1 IS NULL THEN 1 ELSE 0 END) as total_amt_change_q4_q1_nulls
	,SUM(CASE WHEN total_trans_amt IS NULL THEN 1 ELSE 0 END) as total_trans_amt_nulls
	,SUM(CASE WHEN total_trans_ct IS NULL THEN 1 ELSE 0 END) as total_trans_ct_nulls
	,SUM(CASE WHEN total_ct_change_q4_q1 IS NULL THEN 1 ELSE 0 END) as total_ct_change_q4_q1_nulls
	,SUM(CASE WHEN avg_utilization_ratio IS NULL THEN 1 ELSE 0 END) as avg_utilization_ratio_nulls
	
FROM bank_churn


-- Going through each column to validate my first query's results
SELECT * 
FROM bank_churn
--WHERE COALESCE(card_category,'') = ''
WHERE avg_utilization_ratio IS NULL --COALESCE(avg_utilization_ratio,0) = 0



-- 2. Removing Duplicates
-- Check for duplicate rows in the table

SELECT avg_utilization_ratio
	  ,COUNT(*) AS amount
FROM bank_churn
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY 2 DESC





-- 3. Handle Data Types
-- Data is input and formatted correctly

SELECT attname AS column_name
	  ,format_type(atttypid, atttypmod) AS data_type
	  , relname AS table_name
FROM pg_attribute
JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
WHERE relkind = 'r'::char AND attnum > 0 AND NOT attisdropped
ORDER BY table_name, attnum;




-- 4. Remove Irrelevant Columns
-- All columns are necessary for exploring customer segmentation

SELECT *
FROM bank_churn
LIMIT 5



-- 5. Handle Categorical Values
-- All categories are fit for RFM analysis and customer segmentation 


-- 6. Handle Outlier Values
-- Looking at descriptive statistics to find outliers


-- Calculate the average, median, standard deviation, minimum, and maximum age of customers.
SELECT ROUND(avg(customer_age),2) AS avg_age
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY customer_age) AS median_age
	  ,ROUND(STDDEV(customer_age),2) AS stdv_of_age 
	  ,MIN(customer_age) AS min_age
	  ,MAX(customer_age) AS max_age 
FROM bank_churn

-- There is one customer who is 73 years old, which is 3 standard deviations above the mean.
-- This customer is an outlier and may be skewing the results.


-- This code then identifies the rows that are outliers
SELECT customer_age 
	  ,NTILE(100) OVER (ORDER BY customer_age) AS percentile
FROM bank_churn


-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE customer_age = 73


-- Calculate the average, median, standard deviation, minimum, and maximum dependent count of customers.
SELECT ROUND(avg(dependent_count),2) AS avg_dependent_count
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dependent_count) AS median_dependent_count
	  ,ROUND(STDDEV(dependent_count),2) AS stdv_of_dependent_count
	  ,MIN(dependent_count) AS min_dependent_count
	  ,MAX(dependent_count) AS max_dependent_count
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum months on book of customers.
SELECT ROUND(avg(months_on_book),2) AS avg_months_on_book
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY months_on_book) AS median_months_on_book
	  ,ROUND(STDDEV(months_on_book),2) AS stdv_of_months_on_book
	  ,MIN(months_on_book) AS min_months_on_book
	  ,MAX(months_on_book) AS max_months_on_book
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum total relationship count of customers
SELECT ROUND(avg(total_relationship_count),2) AS avg_total_relationship_count
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_relationship_count) AS median_total_relationship_count
	  ,ROUND(STDDEV(total_relationship_count),2) AS stdv_of_total_relationship_count
	  ,MIN(total_relationship_count) AS min_total_relationship_count
	  ,MAX(total_relationship_count) AS max_total_relationship_count
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum months inactive of customers
SELECT ROUND(avg(months_inactive),2) AS avg_months_inactive
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY months_inactive) AS median_months_inactive
	  ,ROUND(STDDEV(months_inactive),2) AS stdv_of_months_inactive
	  ,MIN(months_inactive) AS min_months_inactive
	  ,MAX(months_inactive) AS max_months_inactive 
FROM bank_churn

-- There is one customer who has been inactive for 3 standard deviations above the mean.
-- This customer is an outlier and may be skewing the results.


-- This code then identifies the rows that are outliers
SELECT months_inactive 
	  ,NTILE(100) OVER (ORDER BY months_inactive) AS percentile
FROM bank_churn

-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE months_inactive IN(
						WITH q1 AS (
									SELECT months_inactive
								   ,NTILE(100) OVER (ORDER BY months_inactive) AS percentile
									FROM bank_churn
								   )

						SELECT months_inactive
						FROM q1
						WHERE percentile = 100)
						RETURNING *;


-- Calculate the average, median, standard deviation, minimum, and maximum contacts count of customers.
SELECT ROUND(avg(contacts_count),2) AS avg_contacts_count
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY contacts_count) AS median_contacts_count
	  ,ROUND(STDDEV(contacts_count),2) AS stdv_of_contacts_count
	  ,MIN(contacts_count) AS min_contacts_count
	  ,MAX(contacts_count) AS max_contacts_count
FROM bank_churn

-- There is one customer who has contacts which are 3 standard deviations above the mean.
-- This customer is an outlier and may be skewing the results.


-- This code then identifies the rows that are outliers
SELECT contacts_count 
	  ,NTILE(100) OVER (ORDER BY contacts_count) AS percentile
FROM bank_churn


-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE contacts_count IN(
						WITH q1 AS (
									SELECT contacts_count
								   ,NTILE(100) OVER (ORDER BY contacts_count) AS percentile
									FROM bank_churn
								   )

						SELECT contacts_count
						FROM q1
						WHERE percentile = 100)
						RETURNING *;



-- Calculate the average, median, standard deviation, minimum, and maximum values for credit_limit
SELECT ROUND(avg(credit_limit),2) AS avg_credit_limit
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY credit_limit) AS median_credit_limit
	  ,ROUND(STDDEV(credit_limit),2) AS stdv_of_credit_limit
	  ,MIN(credit_limit) AS min_credit_limit
	  ,MAX(credit_limit) AS max_credit_limit
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum values for total_revolving_bal
SELECT ROUND(avg(total_revolving_bal),2) AS avg_revolving_bal
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revolving_bal) AS median_revolving_bal
	  ,ROUND(STDDEV(total_revolving_bal),2) AS stdv_of_revolving_bal
	  ,MIN(total_revolving_bal) AS min_revolving_bal
	  ,MAX(total_revolving_bal) AS max_revolving_bal
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum values for avg_open_to_buy
SELECT ROUND(avg(avg_open_to_buy),2) AS ovrl_avg_open_to_buy
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_open_to_buy) AS median_open_to_buy
	  ,ROUND(STDDEV(avg_open_to_buy),2) AS stdv_of_avg_open_to_buy
	  ,MIN(avg_open_to_buy) AS min_avg_open_to_buy
	  ,MAX(avg_open_to_buy) AS max_avg_open_to_buy
FROM bank_churn


-- Calculate the average, median, standard deviation, minimum, and maximum values for total_amt_change_q4_q1
SELECT ROUND(avg(total_amt_change_q4_q1),2) AS avg_total_amt_change_q4_q1
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amt_change_q4_q1) AS median_total_amt_change_q4_q1
	  ,ROUND(STDDEV(total_amt_change_q4_q1),2) AS stdv_of_total_amt_change_q4_q1
	  ,MIN(total_amt_change_q4_q1) AS min_total_amt_change_q4_q1
	  ,MAX(total_amt_change_q4_q1) AS max_total_amt_change_q4_q1 -- Outlier of 3 STDDEV
FROM bank_churn


-- This code then identifies the rows that are outliers
SELECT total_amt_change_q4_q1 
	  ,NTILE(100) OVER (ORDER BY total_amt_change_q4_q1) AS percentile
FROM bank_churn


-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE total_amt_change_q4_q1 IN(
						WITH q1 AS (
									SELECT total_amt_change_q4_q1
								   ,NTILE(100) OVER (ORDER BY total_amt_change_q4_q1) AS percentile
									FROM bank_churn
								   )

						SELECT total_amt_change_q4_q1
						FROM q1
						WHERE percentile = 100)
						RETURNING *;


-- Calculate the average, median, standard deviation, minimum, and maximum values for total_trans_amt 
SELECT ROUND(avg(total_trans_amt),2) AS avg_total_trans_amt
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_trans_amt) AS median_total_trans_amt
	  ,ROUND(STDDEV(total_trans_amt),2) AS stdv_of_total_trans_amt
	  ,MIN(total_trans_amt) AS min_total_trans_amt
	  ,MAX(total_trans_amt) AS max_total_trans_amt -- Outlier of 3 STDDEV
FROM bank_churn


-- This code then identifies the rows that are outliers
SELECT total_trans_amt 
	  ,NTILE(100) OVER (ORDER BY total_trans_amt) AS percentile
FROM bank_churn

-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE total_trans_amt IN(
						WITH q1 AS (
									SELECT total_trans_amt
								   ,NTILE(100) OVER (ORDER BY total_trans_amt) AS percentile
									FROM bank_churn
								   )

						SELECT total_trans_amt
						FROM q1
						WHERE percentile = 100)
						RETURNING *;


-- Calculate the average, median, standard deviation, minimum, and maximum values for total_trans_ct
SELECT ROUND(avg(total_trans_ct),2) AS avg_total_trans_ct
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_trans_ct) AS median_total_trans_ct
	  ,ROUND(STDDEV(total_trans_ct),2) AS stdv_of_total_trans_ct
	  ,MIN(total_trans_ct) AS min_total_trans_ct
	  ,MAX(total_trans_ct) AS max_total_trans_ct -- Outlier of 3 STDDEV
FROM bank_churn


-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE total_trans_ct > 133



-- Calculate the average, median, standard deviation, minimum, and maximum values for total_ct_change_q4_q1
SELECT ROUND(avg(total_ct_change_q4_q1),2) AS avg_total_ct_change_q4_q1
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_ct_change_q4_q1) AS median_total_ct_change_q4_q1
	  ,ROUND(STDDEV(total_ct_change_q4_q1),2) AS stdv_of_total_ct_change_q4_q1
	  ,MIN(total_ct_change_q4_q1) AS min_total_ct_change_q4_q1
	  ,MAX(total_ct_change_q4_q1) AS max_total_ct_change_q4_q1 -- Outlier of 3 STDDEV
FROM bank_churn



-- This code then identifies the rows that are outliers
SELECT total_ct_change_q4_q1 
	  ,NTILE(100) OVER (ORDER BY total_ct_change_q4_q1 ASC) AS percentile
FROM bank_churn


-- This code then deletes the rows that are outliers
DELETE FROM bank_churn
WHERE total_ct_change_q4_q1 IN(
						WITH q1 AS (
									SELECT total_ct_change_q4_q1
								   ,NTILE(100) OVER (ORDER BY total_ct_change_q4_q1) AS percentile
									FROM bank_churn
								   )

						SELECT total_ct_change_q4_q1
						FROM q1
						WHERE percentile = 100)
						RETURNING *;
						
DELETE FROM bank_churn
WHERE total_ct_change_q4_q1 = 0
RETURNING *;


-- Calculate the average, median, standard deviation, minimum, and maximum values for avg_utilization_ratio
SELECT ROUND(avg(avg_utilization_ratio),2) AS ovrl_avg_utilization_ratio
	  ,PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_utilization_ratio) AS median_avg_utilization_ratio
	  ,ROUND(STDDEV(avg_utilization_ratio),2) AS stdv_of_avg_utilization_ratio
	  ,MIN(avg_utilization_ratio) AS min_avg_utilization_ratio
	  ,MAX(avg_utilization_ratio) AS max_avg_utilization_ratio
FROM bank_churn



-- 7. Validate the Data
/* Months_on_book(36) has nearly ten times the count of next record (37)
It may be caused by a bank policy or deal offered to customers. Will be
looking at how sensitive data is to this metric in EDA phase. */















