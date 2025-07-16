--1
select  Count(*) As 'the total number of products'
from production.products;


--2
SELECT 
    AVG(list_price) AS average_price,  MIN(list_price) AS min_price,    MAX(list_price) AS max_price
FROM production.products;


--3
SELECT category_id, COUNT(*) AS product_count
FROM production.products
GROUP BY category_id;


--4
SELECT s.store_name , COUNT(o.order_id) AS order_count
FROM sales.orders o join sales.stores s on s.store_id = o.store_id
GROUP BY s.store_name;


--5
select top 10 UPPER(first_name) as name_upper, LOWER(last_name) as last_name_lower
FROM sales.customers;

--6
select Top 10 product_name,LEN(product_name) AS length_product
from production.products


--7
SELECT 
    customer_id,
    SUBSTRING(phone, 1, 3) AS area_code
FROM sales.customers
WHERE customer_id BETWEEN 1 AND 15;


--8
select top 10 order_date,year(order_date) AS year_date,month(order_date) AS month_date
from sales.orders;


--9
select p.product_name,c.category_name
from production.products p join production.categories c on p.category_id = c.category_id
order by p.product_name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; 


--10
select top 10  (c.first_name + ' ' + c.last_name) AS Customer_Name,o.order_date
from sales.customers c join sales.orders o on c.customer_id = o.customer_id;


-- 11
SELECT 
    p.product_name,
    COALESCE(b.brand_name, 'No Brand') AS brand_name
FROM production.products p
LEFT JOIN production.brands b ON p.brand_id = b.brand_id;

 
 --12
 select product_name, list_price
 from production.products
 where  list_price > (select AVG(list_price)AS Average
            from production.products);
            
--13
select customer_id,(first_name + ' ' + last_name) AS customer_name
from sales.customers
where customer_id IN (select distinct customer_id from sales.orders where customer_id is not null);

--14
SELECT 
    customer_id,
    first_name + ' ' + last_name AS customer_name,
    (
        SELECT COUNT(*) 
        FROM sales.orders o 
        WHERE o.customer_id = c.customer_id
    ) AS total_orders
FROM sales.customers c;

--15
create view easy_product_list AS
select p.product_name ,c.category_name,p.list_price
from production.products p join production.categories c on p.category_id = c.category_id;

select * 
from easy_product_list
where list_price > 100 ;

--16 
create view customer_info As
select customer_id, CONCAT(first_name,' ' ,last_name) As Full_Name,email,(city + ' , '+ state) AS location
from sales.customers ;

select *
from customer_info
where location like '% , CA';

--17
select product_name, list_price
from production.products 
where list_price between 50 and 200 
order by list_price asc;

--18 
select state, COUNT(*) AS customer_count
from sales.customers 
group by state
order by customer_count desc ;


--19
select c.category_name, p.product_name,p.list_price
from production.categories c join production.products p on c.category_id = p.category_id
where p.list_price = (
     select max(p2.list_price) 
     from production.products p2
     where p2.category_id = p.category_id
);


--20
select s.store_name,s.city,count(o.order_id) AS order_count
from sales.stores s left join sales.orders o on s.store_id = o.store_id
group by s.store_name,s.city;
