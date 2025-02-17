CREATE TABLE etl (
	order_id int primary key,
    order_date date,
    ship_mode varchar(20),
    segment varchar(20),
    country varchar(20),
    city varchar(20),
    state varchar(20),
    postal_code varchar(20),
    region varchar(20),
    category varchar(20),
    sub_category varchar(20),
    product_id varchar(50),
    quantity int,
    discount decimal(7,2),
    sell_price decimal(7,2),
    profit decimal(7,2));

-- find top 10 highest revenue generating products

select product_id, round(sum(sell_price * quantity),2) as revenue
from etl
group by product_id
order by revenue desc 
limit 10;


-- find top 5 highest selling products in each region

with cte as (
	select region, product_id,round(sum(sell_price),2) as sales
	from etl
	group by region,product_id
	)
select * from (
	select *,rank() over(partition by region order by sales desc) as rn
	from cte) as A
where rn<=5;

-- find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023

with cte as (
	select  year(order_date) as order_year, 
    month(order_date) as order_month, sum(sell_price) as sales from etl
	group by year(order_date),month(order_date)
)
select order_month,
round(sum(case when order_year=2022 then sales else 0 end),2) as '2022_sales',
round(sum(case when order_year=2023 then sales else 0 end),2) as '2023_sales'
from cte
group by order_month
order by order_month;

-- for each category which month had highest sales

with cte as (
	select category,year(order_date) as order_year, 
    month(order_date) as order_month,round(sum(sell_price),2) as sales
	from etl
    group by category,order_year,order_month
	)
    
select * from (
	select *,
	rank() over(partition by category order by sales desc) as rn
	from cte) as A
where rn=1;


-- which sub-category saw the highest growth by profit in 2023 compared to 2022

with cte as (
	select  sub_category, year(order_date) as order_year, 
	sum(profit) as total_profit from etl
	group by sub_category, year(order_date)
),

cte2 as( 
	select sub_category,
	round(sum(case when order_year=2022 then total_profit else 0 end),2) as 2022_profit,
	round(sum(case when order_year=2023 then total_profit else 0 end),2) as 2023_profit
	from cte
	group by sub_category
)
select *, round(((2023_profit-2022_profit)*100/2022_profit),2) as growth_percent
from cte2
order by growth_percent desc limit 1;
