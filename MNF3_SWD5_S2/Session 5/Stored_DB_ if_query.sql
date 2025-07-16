--1
select 
     product_name, 
     list_price,
     case
         when list_price < 300 then 'Economy'
         when list_price between 300 and 999 then 'Standard'
         when list_price between 1000 and 2499 then 'Premium'
         when list_price >= 2500 then 'Luxury'
     end AS price_category
 from production.products
 ORDER BY list_price;




 --2
 SELECT 
    o.order_id,
    o.order_status,
    o.order_date,
    
    CASE o.order_status
        WHEN 1 THEN 'Order Received'
        WHEN 2 THEN 'In Preparation'
        WHEN 3 THEN 'Order Cancelled'
        WHEN 4 THEN 'Order Delivered'
        ELSE 'Unknown Status'
    END AS status_description,
   
    CASE 
        WHEN o.order_status = 1 AND DATEDIFF(DAY, o.order_date, GETDATE()) > 5 THEN 'URGENT'
        WHEN o.order_status = 2 AND DATEDIFF(DAY, o.order_date, GETDATE()) > 3 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS priority
FROM sales.orders o;




--3
select s.staff_id,(s.first_name + ' ' + s.last_name) As staff_name, count(o.order_id) AS total_orders,
            case
                when count(o.order_id) = 0 then 'New Staff'
                when count(o.order_id) between 1 and 10 then 'Junior Staff'
                when count(o.order_id) between 11 and 25 then 'Senior Staff'
                when count(o.order_id) >= 26 then 'Expert Staff'
            end as staff_level
from sales.staffs s left join sales.orders o on s.staff_id = o.staff_id
group by s.staff_id,s.first_name,s.last_name;




--4
SELECT 
    customer_id,
   ( first_name + ' ' +last_name) as full_name,
    ISNULL(phone, 'Phone Not Available') AS phone,
    email,
    street,
    city,
    state,
    zip_code,
    COALESCE(phone, email, 'No Contact Method') AS preferred_contact
FROM sales.customers;




--5
SELECT 
    s.product_id,
    p.product_name,
    s.quantity,
   
    ISNULL(p.list_price / NULLIF(s.quantity, 0), 0) AS price_per_unit,
    
    CASE 
        WHEN s.quantity > 0 THEN 'In Stock'
        ELSE 'Out of Stock'
    END AS stock_status

FROM production.stocks s
JOIN production.products p ON s.product_id = p.product_id
WHERE s.store_id = 1;




--6
SELECT 
    customer_id,
    first_name,
    last_name,
    COALESCE(street, '') AS street,
    COALESCE(city, '') AS city,
    COALESCE(state, '') AS state,
    COALESCE(zip_code, '') AS zip_code,

    COALESCE(street, '') + 
    CASE WHEN city IS NOT NULL THEN ', ' + city ELSE '' END +
    CASE WHEN state IS NOT NULL THEN ', ' + state ELSE '' END +
    CASE WHEN zip_code IS NOT NULL THEN ', ' + zip_code ELSE ', No ZIP' END AS formatted_address

FROM sales.customers;




--7
WITH CustomerSpending AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_spent
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    cs.total_spent
FROM CustomerSpending cs
JOIN sales.customers c ON cs.customer_id = c.customer_id
WHERE cs.total_spent > 1500
ORDER BY cs.total_spent DESC;




--8
WITH CategoryRevenue AS (
    SELECT 
        p.category_id,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_revenue
    FROM production.products p
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id
),

CategoryOrderAvg AS (
    SELECT 
        p.category_id,
        AVG(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS avg_order_value
    FROM production.products p
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category_id
)

SELECT 
    c.category_name,
    cr.total_revenue,
    coa.avg_order_value,
    
    CASE 
        WHEN cr.total_revenue > 50000 THEN 'Excellent'
        WHEN cr.total_revenue > 20000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_rating

FROM CategoryRevenue cr
JOIN CategoryOrderAvg coa ON cr.category_id = coa.category_id
JOIN production.categories c ON cr.category_id = c.category_id
ORDER BY cr.total_revenue DESC;




--9
WITH MonthlySales AS (
    SELECT 
        FORMAT(o.order_date, 'yyyy-MM') AS sale_month,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_sales
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY FORMAT(o.order_date, 'yyyy-MM')
),

SalesWithPrev AS (
    SELECT 
        ms.sale_month,
        ms.total_sales,
        LAG(ms.total_sales) OVER (ORDER BY ms.sale_month) AS prev_month_sales
    FROM MonthlySales ms
)


SELECT 
    sale_month,
    total_sales,
    prev_month_sales,
    CASE 
        WHEN prev_month_sales IS NULL THEN NULL
        WHEN prev_month_sales = 0 THEN NULL  
        ELSE ROUND(((total_sales - prev_month_sales) / prev_month_sales) * 100, 2)
    END AS growth_percentage
FROM SalesWithPrev
ORDER BY sale_month;




--10
WITH RankedProducts AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.list_price,

        ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS row_num,
        RANK()       OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS price_rank,
        DENSE_RANK() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS dense_price_rank

    FROM production.products p
    JOIN production.categories c ON p.category_id = c.category_id
)

SELECT 
    product_id,
    product_name,
    category_name,
    list_price,
    row_num,
    price_rank,
    dense_price_rank
FROM RankedProducts
WHERE row_num <= 3
ORDER BY category_name, row_num;




--11
WITH CustomerSpending AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_spent
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),

RankedCustomers AS (
    SELECT 
        cs.customer_id,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank,
        NTILE(5) OVER (ORDER BY cs.total_spent DESC) AS spending_group
    FROM CustomerSpending cs
)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    rc.total_spent,
    rc.spending_rank,
    rc.spending_group,

    CASE rc.spending_group
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
        ELSE 'Standard'
    END AS customer_tier

FROM RankedCustomers rc
JOIN sales.customers c ON rc.customer_id = c.customer_id
ORDER BY rc.total_spent DESC;



--12
WITH StorePerformance AS (
    SELECT 
        s.store_id,
        s.store_name,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM sales.stores s
    JOIN sales.orders o ON s.store_id = o.store_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY s.store_id, s.store_name
)

SELECT 
    store_id,
    store_name,
    total_revenue,
    total_orders,

    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,

    RANK() OVER (ORDER BY total_orders DESC) AS order_count_rank,

    PERCENT_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_percentile

FROM StorePerformance
ORDER BY total_revenue DESC;



--13
WITH ProductData AS (
    SELECT 
        c.category_name,
        b.brand_name,
        p.product_id
    FROM production.products p
    JOIN production.categories c ON p.category_id = c.category_id
    JOIN production.brands b ON p.brand_id = b.brand_id
    WHERE b.brand_name IN ('Electra', 'Haro', 'Trek', 'Surly')
)

SELECT *
FROM (
    SELECT category_name, brand_name
    FROM ProductData
) AS SourceTable
PIVOT (
    COUNT(brand_name)
    FOR brand_name IN ([Electra], [Haro], [Trek], [Surly])
) AS PivotTable
ORDER BY category_name;



--14
WITH MonthlySales AS (
    SELECT 
        s.store_name,
        DATENAME(MONTH, o.order_date) AS sales_month,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN sales.stores s ON o.store_id = s.store_id
    GROUP BY s.store_name, DATENAME(MONTH, o.order_date), MONTH(o.order_date)
)

SELECT 
    store_name,
    ISNULL([January], 0) AS Jan,
    ISNULL([February], 0) AS Feb,
    ISNULL([March], 0) AS Mar,
    ISNULL([April], 0) AS Apr,
    ISNULL([May], 0) AS May,
    ISNULL([June], 0) AS Jun,
    ISNULL([July], 0) AS Jul,
    ISNULL([August], 0) AS Aug,
    ISNULL([September], 0) AS Sep,
    ISNULL([October], 0) AS Oct,
    ISNULL([November], 0) AS Nov,
    ISNULL([December], 0) AS Dec,

    ISNULL([January], 0) + ISNULL([February], 0) + ISNULL([March], 0) +
    ISNULL([April], 0) + ISNULL([May], 0) + ISNULL([June], 0) +
    ISNULL([July], 0) + ISNULL([August], 0) + ISNULL([September], 0) +
    ISNULL([October], 0) + ISNULL([November], 0) + ISNULL([December], 0)
    AS Total

FROM MonthlySales
PIVOT (
    SUM(revenue)
    FOR sales_month IN (
        [January], [February], [March], [April], [May], [June],
        [July], [August], [September], [October], [November], [December]
    )
) AS PivotTable
ORDER BY store_name;




--15
WITH OrderStatusData AS (
    SELECT 
        s.store_name,
        CASE o.order_status
            WHEN 1 THEN 'Pending'
            WHEN 2 THEN 'Processing'
            WHEN 3 THEN 'Rejected'
            WHEN 4 THEN 'Completed'
        END AS status
    FROM sales.orders o
    JOIN sales.stores s ON o.store_id = s.store_id
)

SELECT 
    store_name,
    ISNULL([Pending], 0) AS Pending,
    ISNULL([Processing], 0) AS Processing,
    ISNULL([Completed], 0) AS Completed,
    ISNULL([Rejected], 0) AS Rejected
FROM OrderStatusData
PIVOT (
    COUNT(status)
    FOR status IN ([Pending], [Processing], [Completed], [Rejected])
) AS PivotResult
ORDER BY store_name;





--16
WITH BrandSales AS (
    SELECT 
        b.brand_name,
        YEAR(o.order_date) AS sales_year,
        SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    JOIN production.brands b ON p.brand_id = b.brand_id
    WHERE YEAR(o.order_date) IN (2016, 2017, 2018)
    GROUP BY b.brand_name, YEAR(o.order_date)
)

, PivotedSales AS (
    SELECT 
        brand_name,
        ISNULL([2016], 0) AS Revenue_2016,
        ISNULL([2017], 0) AS Revenue_2017,
        ISNULL([2018], 0) AS Revenue_2018
    FROM BrandSales
    PIVOT (
        SUM(revenue)
        FOR sales_year IN ([2016], [2017], [2018])
    ) AS PivotTable
)

SELECT 
    brand_name,
    Revenue_2016,
    Revenue_2017,
    Revenue_2018,

    CASE 
        WHEN Revenue_2016 = 0 THEN NULL
        ELSE ROUND(((Revenue_2017 - Revenue_2016) / Revenue_2016) * 100.0, 2)
    END AS Growth_2016_2017_Percent,

    CASE 
        WHEN Revenue_2017 = 0 THEN NULL
        ELSE ROUND(((Revenue_2018 - Revenue_2017) / Revenue_2017) * 100.0, 2)
    END AS Growth_2017_2018_Percent

FROM PivotedSales
ORDER BY brand_name;




--17
SELECT 
    p.product_id,
    p.product_name,
    'In Stock' AS availability_status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE s.quantity > 0

UNION

SELECT 
    p.product_id,
    p.product_name,
    'Out of Stock' AS availability_status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE ISNULL(s.quantity, 0) = 0

UNION

SELECT 
    p.product_id,
    p.product_name,
    'Discontinued' AS availability_status
FROM production.products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM production.stocks s 
    WHERE p.product_id = s.product_id
);




--18
WITH LoyalCustomers AS (
    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2017

    INTERSECT

    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2018
)

SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS full_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * (oi.list_price - (oi.list_price * oi.discount))) AS total_spent
FROM LoyalCustomers lc
JOIN sales.customers c ON lc.customer_id = c.customer_id
JOIN sales.orders o ON c.customer_id = o.customer_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;





--19
SELECT 
    p.product_id,
    p.product_name,
    'Available in All Stores' AS status
FROM production.products p
JOIN production.stocks s1 ON p.product_id = s1.product_id AND s1.store_id = 1
INTERSECT
SELECT 
    p.product_id,
    p.product_name,
    'Available in All Stores' AS status
FROM production.products p
JOIN production.stocks s2 ON p.product_id = s2.product_id AND s2.store_id = 2
INTERSECT
SELECT 
    p.product_id,
    p.product_name,
    'Available in All Stores' AS status
FROM production.products p
JOIN production.stocks s3 ON p.product_id = s3.product_id AND s3.store_id = 3

UNION

SELECT 
    p.product_id,
    p.product_name,
    'Only in Store 1 (not in Store 2)' AS status
FROM production.products p
JOIN production.stocks s1 ON p.product_id = s1.product_id AND s1.store_id = 1
EXCEPT
SELECT 
    p.product_id,
    p.product_name,
    'Only in Store 1 (not in Store 2)' AS status
FROM production.products p
JOIN production.stocks s2 ON p.product_id = s2.product_id AND s2.store_id = 2;




--20
WITH Customers2016 AS (
    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2016
),
Customers2017 AS (
    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2017
),

LostCustomers AS (
    SELECT customer_id
    FROM Customers2016
    WHERE customer_id NOT IN (SELECT customer_id FROM Customers2017)
),

NewCustomers AS (
    SELECT customer_id
    FROM Customers2017
    WHERE customer_id NOT IN (SELECT customer_id FROM Customers2016)
),

RetainedCustomers AS (
    SELECT customer_id
    FROM Customers2016
    INTERSECT
    SELECT customer_id
    FROM Customers2017
)

SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS full_name,
    'Lost' AS status
FROM LostCustomers lc
JOIN sales.customers c ON c.customer_id = lc.customer_id

UNION ALL

SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS full_name,
    'New' AS status
FROM NewCustomers nc
JOIN sales.customers c ON c.customer_id = nc.customer_id

UNION ALL

SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS full_name,
    'Retained' AS status
FROM RetainedCustomers rc
JOIN sales.customers c ON c.customer_id = rc.customer_id;
