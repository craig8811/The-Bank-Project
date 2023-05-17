/*


Performing Exploratory Data Analysis for Bank Segmentation Project


*/



-- 0. Looking at the key metrics of the credit card users

SELECT ROUND(COUNT(clietnum)/1000.0,2)|| 'K' AS total_customers
	  ,'$'||ROUND(SUM(total_trans_amt)/1000000,2)|| 'M' AS total_spend
	  ,'$'||ROUND((SUM(total_trans_amt)/12)/1000000,2)|| 'M' AS total_monthly_spend
	  ,ROUND((SUM(total_trans_ct)/12)/1000.0,2)||'K' AS total_monthly_transactions
FROM bank_churn




-- 1. Looking at the overall attrition rate
-- Finding segments with equivalent or higher churn rates than 15.70%

WITH churn AS (
				SELECT SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS total_churned
					  ,SUM(CASE WHEN attrition_flag = 'Existing Customer' THEN 1 ELSE 1 END) AS total_existing
				FROM bank_churn
			  )
			  
SELECT *
	  ,ROUND((total_churned/total_existing::numeric)*100.0,2) AS overall_churn_rate
FROM churn



-- 2. Segmenting Customers by Demographics to Find Churn Rates
-- Segmenting Groups by Age: Young(26-40),Middle(41-55), Mature(56-70)
-- Middle age group has two strong segments to predict churn.



WITH middle_churn AS (
				SELECT --customer_age
					   gender
					  ,income_category --marital_status
					  ,marital_status --education_level
					  ,COUNT(*) AS total_customers
					  ,SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
				FROM bank_churn
				WHERE customer_age BETWEEN 41 AND 55
				GROUP BY 1,2,3
				ORDER BY 4 DESC
			  )

SELECT *
	  ,ROUND((churned_customers/total_customers::numeric),2) AS churn_rate
FROM middle_churn
ORDER BY total_customers DESC



-- 3. Segmenting Customers by Behavior to Find Churn Rates
-- Looking at frequency of total transaction count, avg. transaction amount, months_on_book, total_relationship count, months_inactive 
-- Keep exploring by filtering on transaction count, and months_inactive



WITH low_spend_churn AS (
				SELECT months_on_book
					  ,total_relationship_count
					  --,months_inactive
					  --,total_trans_amt
					  ,COUNT(*) AS total_customers
					  ,SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
				FROM bank_churn
				WHERE total_trans_amt BETWEEN 510 AND 5630
				GROUP BY 1,2
				ORDER BY 3 DESC
			  )

SELECT *
	  ,ROUND((churned_customers/total_customers::numeric),2) AS churn_rate
FROM low_spend_churn
ORDER BY total_customers DESC





WITH med_relationship_churn AS (
				SELECT months_on_book
					  --,total_relationship_count
					  ,months_inactive
					  --,total_trans_amt
					  ,COUNT(*) AS total_customers
					  ,SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
				FROM bank_churn
				WHERE total_relationship_count BETWEEN 3 AND 4
				GROUP BY 1,2
				ORDER BY 3 DESC
			  )

SELECT *
	  ,ROUND((churned_customers/total_customers::numeric),2) AS churn_rate
FROM med_relationship_churn
ORDER BY total_customers DESC




WITH med_months_churn AS (
				SELECT --months_on_book
					  total_relationship_count
					  ,months_inactive
					  --,total_trans_amt
					  ,COUNT(*) AS total_customers
					  ,SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
				FROM bank_churn
				WHERE months_on_book BETWEEN 27 AND 41
				AND total_trans_amt BETWEEN 510 AND 5630
				AND total_trans_ct BETWEEN 30 AND 90
				GROUP BY 1,2
				ORDER BY 3 DESC
			  )

SELECT *
	  ,ROUND((churned_customers/total_customers::numeric),2) AS churn_rate
FROM med_months_churn
ORDER BY total_customers DESC



-- 4. Segmenting Customers by Credit Utilization to Find Churn Rates
-- Looking at avg_utilization_ratio because those who max out credit limit more likely to churn


WITH low_avg_uti_churn AS ( --Tinkering with the avg_utilization_ratio to be more targeted***
				SELECT 
					  gender
					  ,income_category
					  ,COUNT(*) AS total_customers
					  ,SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
				FROM bank_churn
				WHERE avg_utilization_ratio BETWEEN 0.000 AND 0.30 --BETWEEN 0 AND 0.333
				AND customer_age BETWEEN 40 AND 55 --AND customer_age BETWEEN 30 AND 45
				GROUP BY 1,2
				ORDER BY 3 DESC
			  )

SELECT *
	  ,ROUND((churned_customers/total_customers::numeric),2) AS churn_rate
FROM low_avg_uti_churn
ORDER BY total_customers DESC




-- Building a RFM Model and connecting it to attrited customers
--Recency(months_inactive),Frequency(total_trans_ct),Monetary(total_trans_amt)

/* Step 1. Put together the RFM Report for females */
--Most likely females to churn are married or single women in early 40's to early 50's who make less than $60K.

WITH frfm AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					WHERE gender = 'F'
					ORDER BY 2 DESC
				),

 	segment_atr AS(
					SELECT bc.clietnum
						  ,bc.customer_age
						  ,bc.marital_status
						  ,bc.education_level
						  ,bc.income_category
						  ,frfm.recency  -- Computing rfm by month
						  ,ROUND(frfm.frequency::numeric/12,2) AS frequency
						  ,ROUND(frfm.monetary::numeric/12,2) AS monetary
						  ,frfm.r
						  ,frfm.f
						  ,frfm.m
						  ,ROUND((frfm.f + frfm.m)/2,0) AS fm
						  --,CASE WHEN frfm.r <= 2 AND frfm.f <= 2 AND frfm.m <=2 THEN 'LOW RFM' 
						   --ELSE 'Other' END AS rfm_segment
						  ,SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
						  --,COUNT(*) AS total_customers
						  --,ROUND(SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 
						   --ELSE 0 END)::numeric / COUNT(*),2) AS attrition_rate

					FROM bank_churn bc
					JOIN frfm ON (bc.clietnum = frfm.clietnum)
					GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
					ORDER BY 1 ASC
				   ),

	segments AS(	
		SELECT *
			  ,CASE WHEN (r = 5 AND fm = 5) OR (r = 5 AND fm = 4) OR (r = 4 AND fm = 5) THEN 'Champions'
			   WHEN (r = 5 AND fm = 3) OR (r = 4 AND fm = 4) OR (r = 3 AND fm = 5) OR (r = 3 AND fm = 4) THEN 'Engaged'
			   WHEN (r = 5 AND fm = 2) OR (r = 4 AND fm = 2) OR (r = 3 AND fm = 3) OR (r = 4 AND fm = 3) THEN 'Potential'
			   WHEN (r = 5 AND fm = 1) THEN 'Recent Customers'
			   WHEN (r = 4 AND fm = 1) OR (r = 3 AND fm = 1) THEN 'Promising' 
			   WHEN (r = 3 AND fm = 2) OR (r = 2 AND fm = 3) OR (r = 2 AND fm = 2) THEN 'Need Attention'
			   WHEN (r = 2 AND fm = 1) THEN 'About to sleep'
			   WHEN (r = 2 AND fm = 5) OR (r = 2 AND fm = 4) OR (r = 1 AND fm = 3) THEN 'At risk'
			   WHEN (r = 1 AND fm = 5) OR (r = 1 AND fm = 4) THEN 'Can''t lose them' 
			   WHEN r = 1 AND fm = 2 THEN 'Hibernating'
			   WHEN r = 1 AND fm = 1 THEN 'Lost' END AS rfm_segment
		FROM segment_atr
		ORDER BY 1 ASC
			  )

SELECT rfm_segment
	  ,COUNT(*) AS total_segment
	  ,COUNT(*) FILTER(WHERE churned_customers = 1) AS total_churned
	  ,COALESCE(ROUND((SUM(churned_customers) FILTER(WHERE churned_customers = 1)/COUNT(*))*100,2),0) AS churn_rate
FROM segments
--WHERE churned_customers = 0 --WHERE churned_customers = 1
GROUP BY 1
ORDER BY 4 DESC


				   
/* Step 2. Put together the RFM Report for males */
--Most likely males to churn are married or single men in late 30's to early 50's who make $80-$120K .

WITH mrfm AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					WHERE gender = 'M'
					ORDER BY 2 DESC
				),

 	segment_atr AS(
					SELECT bc.clietnum
						  ,bc.customer_age
						  ,bc.marital_status
						  ,bc.education_level
						  ,bc.income_category
						  ,mrfm.recency  -- Computing rfm by month
						  ,ROUND(mrfm.frequency::numeric/12,2) AS frequency
						  ,ROUND(mrfm.monetary::numeric/12,2) AS monetary
						  ,mrfm.r
						  ,mrfm.f
						  ,mrfm.m
						  ,ROUND((mrfm.f + mrfm.m)/2,0) AS fm
						  --,CASE WHEN frfm.r <= 2 AND frfm.f <= 2 AND frfm.m <=2 THEN 'LOW RFM' 
						   --ELSE 'Other' END AS rfm_segment
						  ,SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers
						  --,COUNT(*) AS total_customers
						  --,ROUND(SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 
						   --ELSE 0 END)::numeric / COUNT(*),2) AS attrition_rate

					FROM bank_churn bc
					JOIN mrfm ON (bc.clietnum = mrfm.clietnum)
					GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
					ORDER BY 1 ASC
				   ),

	segments AS(	
		SELECT *
			  ,CASE WHEN (r = 5 AND fm = 5) OR (r = 5 AND fm = 4) OR (r = 4 AND fm = 5) THEN 'Champions'
			   WHEN (r = 5 AND fm = 3) OR (r = 4 AND fm = 4) OR (r = 3 AND fm = 5) OR (r = 3 AND fm = 4) THEN 'Engaged'
			   WHEN (r = 5 AND fm = 2) OR (r = 4 AND fm = 2) OR (r = 3 AND fm = 3) OR (r = 4 AND fm = 3) THEN 'Potential'
			   WHEN (r = 5 AND fm = 1) THEN 'Recent Customers'
			   WHEN (r = 4 AND fm = 1) OR (r = 3 AND fm = 1) THEN 'Promising' 
			   WHEN (r = 3 AND fm = 2) OR (r = 2 AND fm = 3) OR (r = 2 AND fm = 2) THEN 'Need Attention'
			   WHEN (r = 2 AND fm = 1) THEN 'About to sleep'
			   WHEN (r = 2 AND fm = 5) OR (r = 2 AND fm = 4) OR (r = 1 AND fm = 3) THEN 'At risk'
			   WHEN (r = 1 AND fm = 5) OR (r = 1 AND fm = 4) THEN 'Can''t lose them' 
			   WHEN r = 1 AND fm = 2 THEN 'Hibernating'
			   WHEN r = 1 AND fm = 1 THEN 'Lost' END AS rfm_segment
		FROM segment_atr
		ORDER BY 1 ASC
			  )

SELECT rfm_segment
	  ,COUNT(*) AS total_segment
	  ,COUNT(*) FILTER(WHERE churned_customers = 1) AS total_churned
	  ,COALESCE(ROUND((SUM(churned_customers) FILTER(WHERE churned_customers = 1)/COUNT(*))*100,2),0) AS churn_rate
FROM segments
GROUP BY 1
ORDER BY 4 DESC




/* Step 3. Put together the RFM Report for all customers, posting 
stats about average recency, frequency, and monetary per month. */

-- This code creates a customer segmentation table based on RFM scores.

-- First, we create a CTE called `crfm` that calculates the RFM scores for each customer.
WITH crfm AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					ORDER BY 2 DESC
				),
/*  Next, we create a CTE called `segment_atr` that joins the `crfm` CTE with the `bank_churn` table and 
adds additional columns, such as customer age, marital status, education level, and income category. */ 
 	segment_atr AS(
					SELECT bc.clietnum
						  ,bc.customer_age
						  ,bc.marital_status
						  ,bc.education_level
						  ,bc.income_category
						  ,crfm.recency  -- Computing rfm by month
						  ,ROUND(crfm.frequency::numeric/12,2) AS frequency
						  ,ROUND(crfm.monetary::numeric/12,2) AS monetary
						  ,crfm.r
						  ,crfm.f
						  ,crfm.m
						  ,ROUND((crfm.f + crfm.m)/2,0) AS fm
						  ,SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers

					FROM bank_churn bc
					JOIN crfm ON (bc.clietnum = crfm.clietnum)
					GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
					ORDER BY 1 ASC
				   ),
-- Finally, we create a CTE called `segments` using the `segment_atr` CTE to assign each customer to an RFM segment.
	segments AS(	
		SELECT *
			  ,CASE WHEN (r = 5 AND fm = 5) OR (r = 5 AND fm = 4) OR (r = 4 AND fm = 5) THEN 'Champions'
			   WHEN (r = 5 AND fm = 3) OR (r = 4 AND fm = 4) OR (r = 3 AND fm = 5) OR (r = 3 AND fm = 4) THEN 'Engaged'
			   WHEN (r = 5 AND fm = 2) OR (r = 4 AND fm = 2) OR (r = 3 AND fm = 3) OR (r = 4 AND fm = 3) THEN 'Potential'
			   WHEN (r = 5 AND fm = 1) THEN 'Recent Customers'
			   WHEN (r = 4 AND fm = 1) OR (r = 3 AND fm = 1) THEN 'Promising' 
			   WHEN (r = 3 AND fm = 2) OR (r = 2 AND fm = 3) OR (r = 2 AND fm = 2) THEN 'Need Attention'
			   WHEN (r = 2 AND fm = 1) THEN 'About to sleep'
			   WHEN (r = 2 AND fm = 5) OR (r = 2 AND fm = 4) OR (r = 1 AND fm = 3) THEN 'At risk'
			   WHEN (r = 1 AND fm = 5) OR (r = 1 AND fm = 4) THEN 'Can''t lose them' 
			   WHEN r = 1 AND fm = 2 THEN 'Hibernating'
			   WHEN r = 1 AND fm = 1 THEN 'Lost' END AS rfm_segment
		FROM segment_atr
		ORDER BY 1 ASC
			  )
/* This query selects the RFM segment, the average recency, the average frequency, 
and the average monetary value for each segment */
SELECT rfm_segment
	  ,ROUND(AVG(recency),2) AS average_recency
	  ,ROUND(AVG(frequency),2) AS average_frequency
	  ,ROUND(AVG(monetary),2) AS average_monetary
FROM segments
GROUP BY 1
ORDER BY 2 DESC, 3 ASC, 4 ASC





/* Step 4. Looking at the prominent segment groups of customers */

-- First, we create a CTE called `prfm` that calculates the RFM scores for each customer.
WITH prfm AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					ORDER BY 2 DESC
				),
/*  Next, we create a CTE called `segment_atr` that joins the `crfm` CTE with the `bank_churn` table and 
adds additional columns, such as customer age, marital status, education level, and income category. */ 
 	segment_atr AS(
					SELECT bc.clietnum
						  ,bc.customer_age
						  ,bc.marital_status
						  ,bc.education_level
						  ,bc.income_category
						  ,prfm.recency  -- Computing rfm by month
						  ,ROUND(prfm.frequency::numeric/12,2) AS frequency
						  ,ROUND(prfm.monetary::numeric/12,2) AS monetary
						  ,prfm.r
						  ,prfm.f
						  ,prfm.m
						  ,ROUND((prfm.f + prfm.m)/2,0) AS fm
						  ,SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers

					FROM bank_churn bc
					JOIN prfm ON (bc.clietnum = prfm.clietnum)
					GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
					ORDER BY 1 ASC
				   ),
-- Finally, we create a CTE called `segments` using the `segment_atr` CTE to assign each customer to an RFM segment.
	segments AS(	
		SELECT *
			  ,CASE WHEN (r = 5 AND fm = 5) OR (r = 5 AND fm = 4) OR (r = 4 AND fm = 5) THEN 'Champions'
			   WHEN (r = 5 AND fm = 3) OR (r = 4 AND fm = 4) OR (r = 3 AND fm = 5) OR (r = 3 AND fm = 4) THEN 'Engaged'
			   WHEN (r = 5 AND fm = 2) OR (r = 4 AND fm = 2) OR (r = 3 AND fm = 3) OR (r = 4 AND fm = 3) THEN 'Potential'
			   WHEN (r = 5 AND fm = 1) THEN 'Recent Customers'
			   WHEN (r = 4 AND fm = 1) OR (r = 3 AND fm = 1) THEN 'Promising' 
			   WHEN (r = 3 AND fm = 2) OR (r = 2 AND fm = 3) OR (r = 2 AND fm = 2) THEN 'Need Attention'
			   WHEN (r = 2 AND fm = 1) THEN 'About to sleep'
			   WHEN (r = 2 AND fm = 5) OR (r = 2 AND fm = 4) OR (r = 1 AND fm = 3) THEN 'At risk'
			   WHEN (r = 1 AND fm = 5) OR (r = 1 AND fm = 4) THEN 'Can''t lose them' 
			   WHEN r = 1 AND fm = 2 THEN 'Hibernating'
			   WHEN r = 1 AND fm = 1 THEN 'Lost' END AS rfm_segment
		FROM segment_atr
		ORDER BY 1 ASC
			  )
/* This query selects the RFM segment, the total number of customers in each segment, 
the total number of churned customers in each segment, and the churn rate for each segment. */
SELECT rfm_segment
	  ,COUNT(*)
	  ,COUNT(*) FILTER(WHERE churned_customers = 1) AS total_churned
	  ,COALESCE(ROUND((SUM(churned_customers) FILTER(WHERE churned_customers = 1)/COUNT(*))*100,2),0) AS churn_rate
FROM segments
GROUP BY 1
ORDER BY 4 DESC




/* Step 5. Looking at the prominent segments demographics/spending utilization
Use these stats as a viz in tool tip for step 4. */
/* Update to show percentage of gender, age_ranges, spending utilization ranges,
income segments, and education segments. */ 


WITH crfm AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					ORDER BY 2 DESC
				),

 	segment_atr AS(
					SELECT bc.clietnum
						  ,bc.customer_age
						  ,bc.gender
						  ,bc.marital_status
						  ,bc.education_level
						  ,bc.income_category
						  ,bc.avg_utilization_ratio
						  ,crfm.recency  -- Computing rfm by month
						  ,ROUND(crfm.frequency::numeric/12,2) AS frequency
						  ,ROUND(crfm.monetary::numeric/12,2) AS monetary
						  ,crfm.r
						  ,crfm.f
						  ,crfm.m
						  ,ROUND((crfm.f + crfm.m)/2,0) AS fm
						  ,SUM(CASE WHEN bc.attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churned_customers

					FROM bank_churn bc
					JOIN crfm ON (bc.clietnum = crfm.clietnum)
					GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
					ORDER BY 1 ASC
				   ),

	segments AS(	
		SELECT *
			  ,CASE WHEN (r = 5 AND fm = 5) OR (r = 5 AND fm = 4) OR (r = 4 AND fm = 5) THEN 'Champions'
			   WHEN (r = 5 AND fm = 3) OR (r = 4 AND fm = 4) OR (r = 3 AND fm = 5) OR (r = 3 AND fm = 4) THEN 'Engaged'
			   WHEN (r = 5 AND fm = 2) OR (r = 4 AND fm = 2) OR (r = 3 AND fm = 3) OR (r = 4 AND fm = 3) THEN 'Potential'
			   WHEN (r = 5 AND fm = 1) THEN 'Recent Customers'
			   WHEN (r = 4 AND fm = 1) OR (r = 3 AND fm = 1) THEN 'Promising' 
			   WHEN (r = 3 AND fm = 2) OR (r = 2 AND fm = 3) OR (r = 2 AND fm = 2) THEN 'Need Attention'
			   WHEN (r = 2 AND fm = 1) THEN 'About to sleep'
			   WHEN (r = 2 AND fm = 5) OR (r = 2 AND fm = 4) OR (r = 1 AND fm = 3) THEN 'At risk'
			   WHEN (r = 1 AND fm = 5) OR (r = 1 AND fm = 4) THEN 'Can''t lose them' 
			   WHEN r = 1 AND fm = 2 THEN 'Hibernating'
			   WHEN r = 1 AND fm = 1 THEN 'Lost' END AS rfm_segment
			  ,CASE WHEN customer_age BETWEEN 26 AND 40 THEN 'Younger'
			   WHEN customer_age BETWEEN 41 AND 55 THEN 'Middle Aged'
			   WHEN customer_age BETWEEN 56 AND 70 THEN 'Older' END AS age_group
			  ,CASE WHEN avg_utilization_ratio BETWEEN 0.000 AND 0.333 THEN 'Low Use'
			   WHEN avg_utilization_ratio BETWEEN 0.334 AND 0.667 THEN 'Medium Use'
			   WHEN avg_utilization_ratio BETWEEN 0.668 AND 0.999 THEN 'High Use'
			   END AS utilization_category
		FROM segment_atr
		ORDER BY 1 ASC
			  ),

	seg_vit AS (
			SELECT rfm_segment
				  ,age_group
				  ,customer_age
				  ,gender
				  ,education_level
				  ,income_category
				  ,utilization_category
				  ,COUNT(*) OVER (PARTITION BY rfm_segment, age_group, utilization_category) AS total_segment_count
			FROM segments
			WHERE churned_customers = 1
			AND rfm_segment IN ('Hibernating','Lost','Promising','Need Attention','At risk')
			ORDER BY 8 DESC
			  )
			  
SELECT rfm_segment
	  ,ROUND((COUNT(*) FILTER(WHERE gender = 'M')/COUNT(*)::numeric)*100.0,2) AS percent_males
	  ,ROUND((COUNT(*) FILTER(WHERE gender = 'F')/COUNT(*)::numeric)*100.0,2) AS percent_females
	  ,ROUND((COUNT(*) FILTER(WHERE age_group = 'Younger')/COUNT(*)::numeric)*100.0,2) AS percent_young
	  ,ROUND((COUNT(*) FILTER(WHERE age_group = 'Middle Aged')/COUNT(*)::numeric)*100.0,2) AS percent_middle_aged
	  ,ROUND((COUNT(*) FILTER(WHERE age_group = 'Older')/COUNT(*)::numeric)*100.0,2) AS percent_old
	  ,ROUND((COUNT(*) FILTER(WHERE utilization_category = 'Low Use')/COUNT(*)::numeric)*100.0,2) AS percent_low_use
	  ,ROUND((COUNT(*) FILTER(WHERE utilization_category = 'Medium Use')/COUNT(*)::numeric)*100.0,2) AS percent_med_use
	  ,ROUND((COUNT(*) FILTER(WHERE utilization_category = 'High Use')/COUNT(*)::numeric)*100.0,2) AS percent_high_use
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = 'Less than $40K')/COUNT(*)::numeric)*100.0,2) AS percent_under_$40K
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = '$40K - $60K')/COUNT(*)::numeric)*100.0,2) AS percent_$40K_$60K
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = '$60K - $80K')/COUNT(*)::numeric)*100.0,2) AS percent_$60K_$80K
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = '$80K - $120K')/COUNT(*)::numeric)*100.0,2) AS percent_$80K_$120K
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = '$120K +')/COUNT(*)::numeric)*100.0,2) AS percent_over_$120K
	  ,ROUND((COUNT(*) FILTER(WHERE income_category = 'Unknown')/COUNT(*)::numeric)*100.0,2) AS percent_unknown
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'Uneducated')/COUNT(*)::numeric)*100.0,2) AS percent_undeducated
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'High School')/COUNT(*)::numeric)*100.0,2) AS percent_high_school
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'College')/COUNT(*)::numeric)*100.0,2) AS percent_college
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'Graduate')/COUNT(*)::numeric)*100.0,2) AS percent_graduate
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'Post-Graduate')/COUNT(*)::numeric)*100.0,2) AS percent_post_graduate
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'Doctorate')/COUNT(*)::numeric)*100.0,2) AS percent_doctorate
	  ,ROUND((COUNT(*) FILTER(WHERE education_level = 'Unknown')/COUNT(*)::numeric)*100.0,2) AS percent_unknown
FROM seg_vit
GROUP BY 1





