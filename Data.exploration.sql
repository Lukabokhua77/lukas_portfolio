
-- 1) list the top 10 order with the highest sales from the order_breakdown table

select *
from order_breakdown
order by sales desc limit 10;


-- 2)show the number of orders for each product category in order_breakdown table

select
category,
count(*) as Number_of_orders
from order_breakdown
group by category;


-- 3) find the total profit for each sub-category in order_breakdown table

select
subcategory,
sum(profit) as total_profit
from order_breakdown
group by 1
order by 2 desc;

-- 4) identify the customer with the highest total sales across all orders

select
customername,
sum(sales) as total_sales
from order_list
join order_breakdown on
order_breakdown.orderid = order_list.orderid
group by customername
order by 2 desc limit 1;


-- 5) Find the month with the highest average sales in order_list table

select
monthname(orderdate) as month,
avg(sales) as avg_sales
from order_list
join order_breakdown on
order_list.orderid = order_breakdown.orderid
group by 1
order by 2 desc limit 1;

-- 6) Find out the average quantity ordered by customers whose first name starts with an 's'

select
customername,
avg(quantity) as avg_quantity
from order_list
join order_breakdown on
order_list.orderid = order_breakdown.orderid
group by CustomerName
having substring_index(customername," ",-1)  like 's%'
order by 2 desc limit 1;


-- 7) Find out how many new customers were acquired in the year 2014


select count(*) as number_customers from (
select
customername, min(orderdate) as firstorderdate
from order_list
group by customername
having year(min(orderdate)) = 2014 ) as custwithfirstorders;

-- 8) Find the average sales per customer , considering only customers who have made more than 10 orders

select 
customername,
avg(sales) as avg_sales
from order_list
join order_breakdown on
order_list.orderid = order_breakdown.orderid
group by 1
having count(distinct order_list.orderid) > 10;

-- 9) Identify the top performing subcategory in each category based on total sales

create temporary table subcategorys
select
category,
subcategory,
sum(sales) as total_sales,
rank() over(partition by category order by sum(sales) desc) as subcategory_rank
from order_breakdown
group by category, subcategory;

select * from 
subcategorys
where subcategory_rank = 1;




