/* Creating Views For Tableau Visualization */



-- 1. Key Metrics of Credit Card Customers
SELECT 
	  -- Calculate the total number of customers in thousands
	  ROUND(COUNT(clietnum)/1000.0,2) AS total_customers
	  
	  -- Calculate the total amount spent by customers in millions of dollars
	  ,ROUND(SUM(total_trans_amt)/1000000,2) AS total_spend
	  
	  -- Calculate the total number of transactions per month in thousands
	  ,ROUND((SUM(total_trans_ct)/12)/1000.0,2) AS total_trans_mth
	 
	 -- Calculate the percentage of customers who have churned
	 ,ROUND(COUNT(*) FILTER(WHERE attrition_flag = 'Attrited Customer')/COUNT(*)::numeric*100.0,2)
	  AS pct_cust_churned
FROM bank_churn

/* This query computes key metrics for credit card customers such as the total number of 
customers, total spend, total transaction per month, and the percentage of churned customers. */


-- 2. Looking at the prominent segment groups
WITH prfm AS (
/* Create a Common Table Expression (CTE) called 'prfm' to compute the Recency, 
Frequency,and Monetary (RFM) values for each customer in the dataset */
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
	-- Create another CTE called 'segment_atr' to combine RFM values and other attributes of each customer
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

	segments AS(
	-- Create a CTE called 'segments' to assign RFM segments based on the quantiles
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
	  ,COUNT(*)
	  ,COUNT(*) FILTER(WHERE churned_customers = 1) AS total_churned
	  ,COALESCE(ROUND((SUM(churned_customers) FILTER(WHERE churned_customers = 1)/COUNT(*))*100,2),0) AS churn_rate
FROM segments
GROUP BY 1
ORDER BY 4 DESC

/*This query computes the RFM (Recency, Frequency, Monetary) values for each customer and categorizes them 
into five segments using the NTILE function. It also computes the number of churned customers per segment. */


-- 3. Compute RFM Reports for all customers
WITH crfm AS (
	-- Create a Common Table Expression (CTE) called 'crfm'
    -- Calculate Recency, Frequency and Monetary (RFM) values for each client 
    -- by dividing the data into 5 equal segments (quintiles) using NTILE
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
	-- Create another CTE called 'segment_atr'
    -- Join the 'crfm' CTE with the 'bank_churn' table on client number 
    -- Calculate RFM values per month
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

	segments AS(
	-- Create a third CTE called 'segments'
    -- Classify clients into segments based on their RFM scores
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
	  ,ROUND(AVG(recency),2) AS average_recency
	  ,ROUND(AVG(frequency),2) AS average_frequency
	  ,ROUND(AVG(monetary),2) AS average_monetary
FROM segments
GROUP BY 1
ORDER BY 2 DESC, 3 ASC, 4 ASC



-- 4. Showing pct. of gender, age_ranges, spend utilization
--ranges, income segments, and educational segments.
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



-- 5. Showing a matrix for recency, frequency/monetary and the resulting churn rate
WITH matrix AS (
					SELECT  clietnum
							,months_inactive AS Recency
							,total_trans_ct AS Frequency
							,total_trans_amt AS Monetary
							,NTILE(5) OVER (ORDER BY months_inactive DESC) AS r
							,NTILE(5) OVER (ORDER BY total_trans_ct ASC) AS f
							,NTILE(5) OVER (ORDER BY total_trans_amt ASC) AS m
					FROM bank_churn
					ORDER BY 2 DESC
				)


SELECT r
	  ,ROUND((f + m)/2,0) AS fm
	  ,ROUND(COUNT(*) FILTER(WHERE bc.attrition_flag = 'Attrited Customer')/COUNT(*)::numeric*100,2) AS churned_percent

FROM matrix mt
JOIN bank_churn bc ON (mt.clietnum=bc.clietnum)
GROUP BY 1,2
ORDER BY churned_percent DESC


					
