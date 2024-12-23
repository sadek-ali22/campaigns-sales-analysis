--Number of Customers in each Recency and percantage from total
SELECT segment_of_Recency , count("ID") as Number_of_Customer,round(count("ID")/ sum(count("ID")) over() *100,2) as  percent_from_total
from(
 SELECT 
            CASE
            WHEN "Recency" BETWEEN 0 AND MAX( "Recency") OVER () / 4 THEN 'A'
            WHEN "Recency" BETWEEN MAX( "Recency") OVER () / 4 + 1 AND MAX( "Recency") OVER () / 4 * 2 THEN 'B'
            WHEN "Recency" BETWEEN MAX( "Recency") OVER () / 4 * 2 +1 AND MAX( "Recency") OVER () / 4 * 3 THEN 'C'
			ELSE 'D'
            END AS segment_of_Recency ,"ID"
  FROM "Fact"
  ) as tt
  GROUP BY segment_of_Recency 
  ORDER BY segment_of_Recency desc
  
---------------------------------------------------------------------------------------
--Average recency  by customer age group
SELECT 
    CASE
    WHEN Age < 23 THEN 'Young'
    WHEN Age BETWEEN 24 AND 46 THEN 'Middle-Aged'
    ELSE 'Aged'
  END AS age_group, Round(AVG("Recency"),2) AS avg_recency
FROM ( 
       select  2014 - cast("Year_Birth" as integer)  as Age,"Recency"
        from "Fact"
)
GROUP BY age_group
ORDER BY avg_recency

--------------------------------------------------------------------------------------------------------
--Knowing the buying behaviors of each age group and the number of customers in each age group
select age_group ,total_customer,"Product",total_Amount,ranking
from(
select age_group ,total_customer,"Product",total_Amount,row_number() over(partition by age_group order by total_Amount desc) as ranking
from(
SELECT 
    CASE
    WHEN Age < 27 THEN 'Young'
    WHEN Age BETWEEN 28 AND 46 THEN 'Middle-Aged'
    ELSE 'Aged'
  END AS age_group, count("ID") as total_customer,"Product" ,sum("Amount") as total_Amount 
FROM ( 
       select  2014 - cast("Year_Birth" as integer)  as Age,"Product","Amount",f."ID"
        from "Fact" f inner join "Dim Product" p
    on f."ID"=p."ID" 
)
GROUP BY age_group,"Product" 
order by  age_group
)
)
where ranking =1 or ranking=6
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Total Amount spent of product and percent from total  via different kidhome
select "Kidhome",  "Product",total_Amount_spent ,
round(total_Amount_spent/total_Amount_spent_in_each_Kidhome,4) *100 as percent_Amount_spent_from_total
from(
SELECT "Kidhome",  "Product",total_Amount_spent ,
SUM( total_Amount_spent ) over(partition by "Kidhome" ) as total_Amount_spent_in_each_Kidhome
from(
SELECT "Kidhome",  "Product", SUM("Amount") AS total_Amount_spent
FROM "Fact" f inner join "Dim Product" p
on f."ID"=p."ID"
GROUP BY "Kidhome", "Product"
ORDER BY "Kidhome" ASC,total_Amount_spent Desc
)
)
-------------------------------------------------------------------------------------------
-- Correlation between marital status and amounts (total amount by each marital status)
select distinct FF."Marital_Status",sum(PP."Amount") over (partition by FF."Marital_Status")  Amount_spent
from "Fact" FF inner join public."Dim Product" PP 
on FF."ID"=PP."ID" 
order by FF."Marital_Status"

------------------------------------------------------------------------------------------------
--Each product with total sold amounts  by each marital status
select distinct FF."Marital_Status" , PP."Product", sum(PP."Amount")
from "Fact" FF inner join "Dim Product" PP 
on FF."ID"=PP."ID"
group by FF."Marital_Status", PP."Product"
order by FF."Marital_Status"

----------------------------------------------------------------------------------------------
---Amount _spent in each product
select "Product" , Sum("Amount") "Total Amount" 
from "Dim Product"
group by "Product"
order by "Total Amount" desc

---------------------------------------------------------------------------------
--Total amount spent by each customer on different products only two most spent
SELECT "ID", "Product",total_Amount,ranking
from(
SELECT f."ID", "Product", SUM("Amount") AS total_Amount,row_number() over(partition by f."ID" order by SUM("Amount") desc) as ranking
FROM "Fact" f inner join "Dim Product" p
    on f."ID"=p."ID" 
GROUP BY f."ID", "Product"
ORDER BY "ID",total_Amount DESC
)
where ranking<3
------------------------------------------------------------------------------------------------
--Average income and Average Amount_Spent of customers by marital status
SELECT "Marital_Status", Round(AVG("Income")) AS avg_income,Round(AVG("Amount")) AS avg_Amount_of_product
FROM "Fact" f inner join "Dim Product" p
    on f."ID"=p."ID" 
GROUP BY "Marital_Status"
ORDER BY avg_income DESC


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

--Total purchases in different purchase types
SELECT "Purchase", SUM("Number of Purchase") AS total_purchases,"Product",sum("Amount") as total_Amount
FROM "Fact" f inner join "Dim Purchase" p
    on f."ID"=p."ID" inner join "Dim Product" pd
    on f."ID"=pd."ID"
GROUP BY  "Purchase","Product"
ORDER BY total_purchases DESC , total_Amount  DESC
-----------------------------------------------------------------------------------------------
--- correlation between Num of kids and num of purchases 
select distinct FF."Kidhome",
 sum(PP."Number of Purchase")over(partition by FF."Kidhome" order by FF."Kidhome" )"Num of purchases" 
from "Dim Purchase" PP inner join "Fact"FF 
on FF."ID"=PP."ID"
order by "Num of purchases" desc

----------------------------------------------------------------------------------------------------
--vip 10 customer by num of purchases
 select FF."ID", sum(PP."Number of Purchase")  "Num_of_Purchases" 
 from "Dim Purchase" PP inner join "Fact" FF 
 on FF."ID"=PP."ID"
 group by FF."ID"
 order by  "Num_of_Purchases" desc
 limit 10

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--Number of interactions with Compaigns
select "Compaign",sum("Accepted the compaign") as total_accepted
from "Dim Compaign"
group by "Compaign"
order by total_accepted DESC

-----------------------------------------------------------------------------------------------------
-- correlation between marital_status and campaings acceptance
select distinct FF."Marital_Status" , sum(CC."Accepted the compaign") over(partition by FF."Marital_Status" order by FF."Marital_Status") "Num of campaign acceptance" 
from "Fact"FF inner join "Dim Compaign" CC 
on CC."ID"=FF."ID"
-------------------------------------------------------------------------------------
--education level  and total number of accepted campaigns
SELECT "Education", SUM("Accepted the compaign") AS total_accepted
FROM "Fact" f inner join "Dim Compaign" c
    on f."ID"=c."ID" 
GROUP BY "Education"
ORDER BY total_accepted DESC
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
--TOTAL number of Accepted the compaign and Number of Purchases by income range
SELECT income_range,  SUM("Accepted the compaign") AS total_accepted ,SUM("Number of Purchase") AS "Number of Purchase"
FROM (
    SELECT 
            CASE
            WHEN "Income" BETWEEN 0 AND MAX("Income") OVER () / 3 THEN 'Low Income'
            WHEN "Income" BETWEEN MAX("Income") OVER () / 3 + 1 AND MAX("Income") OVER () / 3 * 2 THEN 'Middle Income'
            ELSE 'High Income'
            END AS income_range, "Accepted the compaign" ,"Number of Purchase"
    FROM "Fact" f inner join "Dim Purchase" p
    on f."ID"=p."ID"  inner join "Dim Compaign" c
    on f."ID"=c."ID" 
) AS tt
GROUP BY income_range
order by total_accepted DESC

------------------------------------------------------------------------------------------------------
--TOTAL number of web visits and Number of Purchases by income range
SELECT income_range, SUM("NumWebVisitsMonth" ) AS "NumWebVisitsMonth" 
FROM (
    SELECT 
            CASE
            WHEN "Income" <=50000 THEN 'Low Income'
            WHEN "Income" >=50001 and "Income" >=80000 THEN 'Middle Income'
            ELSE 'High Income'
            END AS income_range, "NumWebVisitsMonth" 
    FROM "Fact" f
) AS tt
GROUP BY income_range

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
