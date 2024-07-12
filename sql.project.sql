-- PROJECT

-- 1) Gsearch seems to be the biggest driver of our business. we pull the MONTHLY trends for 
--  GSEARCH SESSIONS AND ORDERS so that we can showcase the growth there,  (before november 27 , 2012)

-- use mavenfuzzyfactory;
SELECT 
    YEAR(website_sessions.created_at) AS mnth,
    MONTH(website_sessions.created_at) AS yr,
    COUNT(website_sessions.website_session_id) AS sessions,
    COUNT(orders.order_id) AS orders,
    COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) as conv_rate
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
GROUP BY 1 , 2;


-- 2) Next, it would be great to see a similar monthly trend for gsearch, but this time splitting out 
--  NONBRAND and BRAND  campaigns seperately.

select
    
    MONTHNAME(website_sessions.created_at) AS month,
    COUNT(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end ) as brands_sessions,
	COUNT(distinct case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end ) as nonbrands_sessions,
	count(distinct case when utm_campaign = 'brand' then order_id else null end) as brands_orders,
    count(distinct case when utm_campaign = 'nonbrand' then order_id else null end) as nonbrands_orders
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
GROUP BY 1 ;


-- 3) Monthly trends for gsearch, alongside monthly trends for each of our other channel

-- select distinct utm_source from website_sessions;

select
year(website_sessions.created_at) as yr,
month(website_sessions.created_at) as mnth,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct case when utm_source= 'gsearch' then website_sessions.website_session_id else null end) as gsearch_sessions,
count(distinct case when utm_source= 'bsearch' then website_sessions.website_session_id else null end) as bsearch_sessions,
count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_sessions_sessions,
count(distinct case when utm_source is null and http_referer is  null then website_sessions.website_session_id else null end) as direct_type_sessions
from website_sessions
left join orders on
website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1, 2;


-- 4) for the gsearch lander test, estimate revenue that test earned us



select
min(website_pageview_id) as first_test_pv
from website_pageviews
where pageview_url = '/lander-1';
--  first_pageview_id is 23504

create temporary table first_pageviews
select
website_pageviews.website_session_id,
min(website_pageviews.website_pageview_id) as min_pv_id
from website_pageviews
inner join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
and website_sessions.created_at < '2012-07-28'
and website_pageviews.website_pageview_id >=23504
and utm_source = 'gsearch'
and utm_campaign='nonbrand'
group by 
website_pageviews.website_session_id;

--  next we' ll bring in the landing page to each session

create temporary table nonbrand_test_sessions_landing_page
select
first_pageviews.website_session_id,
website_pageviews.pageview_url as landing_page
from first_pageviews
left join website_pageviews
on website_pageviews.website_pageview_id=first_pageviews.min_pv_id
where website_pageviews.pageview_url in ('/home','/lander-1');

-- then we make a table to bring in orders

create temporary table nonbrand_sessions_orders
select 
nonbrand_test_sessions_landing_page.website_session_id,
nonbrand_test_sessions_landing_page.landing_page,
orders.order_id as order_id
from nonbrand_test_sessions_landing_page
left join orders 
on orders.website_session_id=nonbrand_test_sessions_landing_page.website_session_id;

-- to find the difference between conversion rates
select 
landing_page,
count(distinct website_session_id) as sessions,
count(distinct order_id) as orders,
count(distinct order_id)/count(distinct  website_session_id) as conv_rate
from nonbrand_sessions_orders
group by 1;

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
 select 
max(website_sessions.website_session_id) as most_recent_pageview
from website_sessions
left join website_pageviews
on website_pageviews.website_session_id = website_sessions.website_session_id
where utm_source = 'gsearch'
and utm_campaign='nonbrand'
and pageview_url='/home'
and website_sessions.created_at < '2012-11-27';
 -- max website_session_id = 17145
 
 select 
 count(website_session_id) as sessions_since_test
 from website_sessions
 where created_at < '2012-11-27'
 and website_session_id > 17145
 and utm_source = 'gsearch'
 and utm_campaign ='nonbrand'
 ;  -- 22,972 website_sessions since the test
  
  -- X .0087 incremental conversion = 202 incremental orders since 7/29
  -- roughly 50 extra orders per month.


-- 5) for the landing page test , it would be great to show a full conversion funnel 
-- from each of the two pages to orders (jun 19, jul 28)


select distinct pageview_url from website_pageviews
where created_at between '2012-06-19' and '2012-07-28' ;

create temporary table page_levels
select 
website_session_id,
max(home_page) as saw_homepage,
max(lander_page) as saw_landerpage,
max(products_page) as saw_products_page,
max(mrfuzzy_page) as saw_mrfuzzy,
max(cart_page) as saw_cart_page,
max(shipping_page) as saw_shipping_page,
max(billing_page) as saw_billing_page,
max(thanks_page) as saw_thanks_page
from(
select
website_sessions.website_session_id,
website_pageviews.pageview_url,
case when pageview_url = '/home' then 1 else 0 end as home_page,
case when pageview_url = '/lander-1' then 1 else 0 end as lander_page,
case when pageview_url = '/products' then 1 else 0 end as products_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thanks_page
from website_sessions
left join website_pageviews
on website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand'
and website_sessions.created_at between '2012-06-19' and '2012-07-28'
order by website_sessions.website_session_id,
website_pageviews.created_at) as pageview_level
group by website_session_id;


select 
case when saw_homepage = 1 then 'saw_homepage'
     when saw_landerpage = 1 then 'saw_lander'
     else 'check ...'
end as segment,
count(distinct website_session_id) as sessions,
count(distinct case when saw_products_page = 1 then website_session_id else null end) as to_products,
count(distinct case when saw_mrfuzzy = 1 then website_session_id else null end) as to_mrfuzzy,
count(distinct case when saw_cart_page = 1 then website_session_id else null end) as to_cart,
count(distinct case when saw_shipping_page = 1 then website_session_id else null end) as to_shipping,
count(distinct case when saw_billing_page = 1 then website_session_id else null end) as to_billing,
count(distinct case when saw_thanks_page = 1 then website_session_id else null end) as to_thanks
from page_levels
group by 1;

-- 6) product sales analysis

select 
year(created_at) as yr,
month(created_at) as mo,
count( order_id) as number_of_sales,
sum(price_usd) as total_revenue,
sum(price_usd - cogs_usd) as total_margin
from orders
where created_at < '2013-01-04'
group by 1,2;

-- 7) Monthly order volume, overall conversion rates, revenue per session and breakdown of sales by product

CREATE VIEW products_revenue_and_orders AS
    SELECT 
        YEAR(website_sessions.created_at) AS yr,
        MONTH(website_sessions.created_at) AS mo,
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
        SUM(price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
        COUNT(DISTINCT CASE
                WHEN primary_product_id = 1 THEN order_id
                ELSE NULL
            END) AS product_1_orders,
        COUNT(DISTINCT CASE
                WHEN primary_product_id = 2 THEN order_id
                ELSE NULL
            END) AS product_2_orders,
        COUNT(DISTINCT CASE
                WHEN primary_product_id = 3 THEN order_id
                ELSE NULL
            END) AS product_3_orders,
        COUNT(DISTINCT CASE
                WHEN primary_product_id = 4 THEN order_id
                ELSE NULL
            END) AS product_4_orders
    FROM
        website_sessions
            LEFT JOIN
        orders ON website_sessions.website_session_id = orders.website_session_id
    GROUP BY 1 , 2;

select * from products_revenue_and_orders;

-- we can say that after launching new products our revenue per session and orders are increasing


-- 8) from the begining to end we have four primary products, i want to show the products revenue in time

SELECT 
    product_name,
    products.product_id,
    SUM(price_usd - cogs_usd) AS revenue,
    DATEDIFF(MAX(order_items.created_at),
            products.created_at) / 365 AS time_segment_years
FROM
    order_items
        JOIN
    products ON products.product_id = order_items.product_id
GROUP BY 1 , 2;

