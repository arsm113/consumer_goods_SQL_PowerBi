/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

select distinct market from dim_customer 
where region='APAC' and customer="Atliq Exclusive" 
order by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

with unique_2020 as (
select count(distinct product_code) as unique_product_2020 
from fact_sales_monthly where fiscal_year=2020),
unique_2021 as (select count(distinct product_code) as unique_product_2021 
from fact_sales_monthly where fiscal_year=2021)
select unique_2020.*, unique_2021.*,
round(((unique_2021.unique_product_2021 - unique_2020.unique_product_2020)
   /unique_2020.unique_product_2020)*100,2) as percentage_chg
   from unique_2020, unique_2021;
   
-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment, count(distinct product_code) as product_count 
from dim_product 
group by segment 
order by count(distinct product_code) desc;


-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

with product_2020 as (
select p.segment,count(distinct fm.product_code) as product_2020 from dim_product p
 join fact_sales_monthly fm on p.product_code=fm.product_code 
where fiscal_year=2020 group by p.segment),
product_2021 as (
select p.segment,count(distinct fm.product_code) as product_2021 from dim_product p
 join fact_sales_monthly fm on p.product_code=fm.product_code 
where fiscal_year=2021 group by p.segment)

select product_2020.*,product_2021.product_2021,
 (product_2021.product_2021 - product_2020.product_2020) as difference
 from product_2020,product_2021
where product_2020.segment=product_2021.segment;


-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select mc.product_code,p.product, mc.manufacturing_cost from
 fact_manufacturing_cost mc join dim_product p on mc.product_code=p.product_code
 where mc.manufacturing_cost in (select max(manufacturing_cost) from fact_manufacturing_cost
union 
select min(manufacturing_cost) from fact_manufacturing_cost) order by manufacturing_cost desc ;


-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select c.customer_code,c.customer,
round(avg(fd.pre_invoice_discount_pct), 4) as discount_percentage
from dim_customer c 
join  fact_pre_invoice_deductions fd 
on c.customer_code=fd.customer_code 
where fd.fiscal_year=2021 and c.market = 'India'
group by c.customer_code,c.customer 
order by discount_percentage desc limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


select concat(monthname(sm.date),'(', year(sm.date),')') as month,sm.fiscal_year, 
sum(p.gross_price*sm.sold_quantity) as gross_amount 
from fact_sales_monthly sm join dim_customer c on sm.customer_code=c.customer_code
join fact_gross_price p on sm.product_code=p.product_code
 where c.customer="Atliq Exclusive"
group by month, sm.fiscal_year;





-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

select quarter(date) as qrt,sum(sold_quantity)as qty 
from fact_sales_monthly where fiscal_year=2020 group by qrt
order by qty desc;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with gross_ml as (
select c.channel, round(sum(gp.gross_price*sm.sold_quantity)/1000000, 2) as gross_sales_ml
from fact_gross_price gp join fact_sales_monthly sm on gp.product_code=sm.product_code
join dim_customer c on sm.customer_code=c.customer_code where sm.fiscal_year=2021 group by c.channel),

total_sales as (select round(sum(gp.gross_price*sm.sold_quantity)/1000000, 2) as gross_sales_total
from fact_gross_price gp join fact_sales_monthly sm on gp.product_code=sm.product_code
 where sm.fiscal_year=2021)
 
 select gross_ml.channel, concat(gross_ml.gross_sales_ml,' M') as gross_sales_ml, 
 concat(round((gross_ml.gross_sales_ml/total_sales.gross_sales_total)*100, 2), ' %') as percent
 from gross_ml,total_sales order by percent desc;
 
 
 
--  10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order


select * from (select *,
rank() over(partition by division order by qty desc) as rnk
 from (
select p.division,p.product_code,p.product,sum(s.sold_quantity) as qty
 from dim_product p join fact_sales_monthly s on p.product_code=s.product_code
 where s.fiscal_year=2021 group by p.division,p.product_code,p.product order by qty desc) t) t2
 where rnk<=3;
 
 












