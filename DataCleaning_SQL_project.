
-- 1) Establish the relationship between the tables

alter table order_list
modify column orderid varchar (255) not null;

alter table order_list
add constraint pk_orderid primary key (orderid);

desc order_list;

alter table order_breakdown
modify column orderid varchar (255) not null;

alter table order_breakdown
add constraint fk_order_id foreign key (orderid)
references order_list(orderid);

desc order_breakdown;

-- 2) Split city_state_country into 3 individual columns

Alter table order_list
Add  city varchar(255) not null ,
add state varchar(255) not null ,
add country varchar(255) not null;


update  order_list set
city = substring_index(city_state_country,",",1),
state = substring_index(substring_index(city_state_country,",",2),",",-1),
country = substring_index(substring_index(city_state_country,",",3),",",-1);

select * from order_list;

alter table order_list
drop column city_state_country;


-- 3)  Add a new category column using the following mapping es per the first 3 characters
--    TEC - technology
--    OFS - Office supplies
--    FUR - Furniture

select * from order_breakdown;

Alter table order_breakdown
add category varchar(255) not null;

UPDATE order_breakdown
set category = case when left(productName,3) = "OFS" then "office supplies"
                    when left(productName,3) = "TEC" then "technology"
                    when left(productName,3) = "FUR" then "furniture"
			 END;

-- 4) delete the first 4 characters from the productname column.

Update order_breakdown
set productName = substring(productName, 5, length(productName) - 4);


-- 5) Remove duplicate rows from order_breakdown table if all column values are matching;

with CTE as(
select * , row_number() over(partition by Orderid, productName, Discount,  sales, profit, quantity,
			category, subcategory order by orderid) as rn
            from order_breakdown
)
delete from CTE
where rn > 1;



















