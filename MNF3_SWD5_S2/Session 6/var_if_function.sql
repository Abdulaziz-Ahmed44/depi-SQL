--1
DECLARE @customer_id INT = 1;
DECLARE @total_spent DECIMAL(10,2);

SELECT @total_spent = SUM(oi.quantity * oi.list_price)
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @customer_id;

SELECT 
    @customer_id AS customer_id,
    @total_spent AS total_spent,
    CASE 
        WHEN @total_spent > 5000 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_status;


    --2
    DECLARE @price_threshold DECIMAL(10, 2) = 1500;
DECLARE @product_count INT;

SELECT @product_count = COUNT(*)
FROM production.products
WHERE list_price > @price_threshold;

SELECT 
    'Number of products with price greater than $' + 
    CAST(@price_threshold AS VARCHAR) + 
    ' is: ' + 
    CAST(@product_count AS VARCHAR) AS result_message;


    --3
    DEClARE @staff_ID int = 1;
    DEClARE @order_year int = 2017;
    DEClARE @total_sales decimal(10,2);

    select   @total_sales = sum(oi.quantity * oi.list_price *(1-oi.discount))
    from sales.orders o join sales.order_items oi on o.order_id = oi.order_id
    where o.staff_id = @total_sales and o.order_date like '@order_year%';

   
    SELECT 
    ' the total sales: for staff member ID' + 
    CAST(@total_sales AS VARCHAR) + 
    ' for staff member ID' +
    CAST(@staff_ID AS VARCHAR) +
    ' in the year ' +
    CAST(@order_year AS VARCHAR)
    AS result_message;



    --4
    SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Version],@@ROWCOUNT AS [Affected Rows];




    --5
    declare @quantit int;
    DECLARE @message VARCHAR(50);

    select @quantit = quantity
    from production.stocks
    where product_id = 1 and store_id = 1;


    if (@quantit > 20)
        SET @message = 'Well stocked';
    if (@quantit between 10 and 20)
        SET @message = 'Moderate stock';
    if (@quantit < 10)
        SET @message = 'Low stock - reorder needed';

        SELECT @message AS [Inventory Level];



        --6
        DECLARE @store_id INT;
DECLARE @product_id INT;
DECLARE @updated_count INT = 0;
DECLARE @batch_size INT = 0;

WHILE EXISTS (
    SELECT 1 FROM production.stocks
    WHERE quantity < 5
)
BEGIN
    SET @batch_size = 0;

    WHILE @batch_size < 3 AND EXISTS (
        SELECT 1 FROM production.stocks
        WHERE quantity < 5
    )
    BEGIN
        SELECT TOP 1 
            @store_id = store_id, 
            @product_id = product_id
        FROM production.stocks
        WHERE quantity < 5
        ORDER BY store_id, product_id;

        UPDATE production.stocks
        SET quantity = quantity + 10
        WHERE store_id = @store_id AND product_id = @product_id;

        PRINT ' Updated Product: Store ID = ' + CAST(@store_id AS VARCHAR) + 
              ', Product ID = ' + CAST(@product_id AS VARCHAR);

        SET @batch_size = @batch_size + 1;
        SET @updated_count = @updated_count + 1;
    END

    PRINT '--- Batch of 3 products updated ---';
END

PRINT ' All low-stock products updated. Total updated: ' + CAST(@updated_count AS VARCHAR);




--7
select product_id, product_name,list_price,
     case
         when list_price < 300 then 'Budget'
         when list_price between 300 and 800 then 'Mid-Range'
         when list_price between 801 and 2000 then 'Premium'
         when list_price > 2000 then 'Luxury'
     END AS price_category
from production.products;



--8
DECLARE @CustomerId INT = 5;
DECLARE @OrderCount INT;


IF EXISTS (
    SELECT 1 FROM sales.customers WHERE customer_id = @CustomerId
)
BEGIN

    SELECT @OrderCount = COUNT(*) 
    FROM sales.orders 
    WHERE customer_id = @CustomerId;

    PRINT 'Customer ID ' + CAST(@CustomerId AS VARCHAR) + 
          ' exists and has made ' + CAST(@OrderCount AS VARCHAR) + ' orders.';
END
ELSE
BEGIN
    PRINT 'Customer ID ' + CAST(@CustomerId AS VARCHAR) + ' does not exist in the database.';
END;



--9
CREATE FUNCTION dbo.CalculateShipping (@OrderTotal DECIMAL(10, 2))
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @ShippingCost DECIMAL(10, 2);

    SET @ShippingCost = 
        CASE 
            WHEN @OrderTotal > 100 THEN 0.00
            WHEN @OrderTotal BETWEEN 50 AND 99.99 THEN 5.99
            ELSE 12.99
        END;

    RETURN @ShippingCost;
END;



SELECT dbo.CalculateShipping(120.00) AS ShippingCost;  

SELECT 
    order_id,
    total_price = SUM(quantity * list_price * (1 - discount)),
    shipping_cost = dbo.CalculateShipping(SUM(quantity * list_price * (1 - discount)))
FROM sales.order_items 
GROUP BY order_id;




--10
CREATE FUNCTION dbo.GetProductsByPriceRange (
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        b.brand_name,
        c.category_name
    FROM production.products p
    INNER JOIN production.brands b ON p.brand_id = b.brand_id
    INNER JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice
);




SELECT * 
FROM dbo.GetProductsByPriceRange(500, 1500);




--11
CREATE FUNCTION dbo.GetCustomerYearlySummary (
    @CustomerID INT
)
RETURNS @Summary TABLE (
    OrderYear INT,
    TotalOrders INT,
    TotalSpent DECIMAL(18, 2),
    AvgOrderValue DECIMAL(18, 2)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(o.order_date) AS OrderYear,
        COUNT(DISTINCT o.order_id) AS TotalOrders,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS TotalSpent,
        AVG(oi.quantity * oi.list_price * (1 - oi.discount)) AS AvgOrderValue
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(o.order_date)
    
    RETURN
END;




SELECT * 
FROM dbo.GetCustomerYearlySummary(5);




--12
CREATE FUNCTION dbo.CalculateBulkDiscount (
    @Quantity INT
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(4,2)

    SET @Discount = 
        CASE 
            WHEN @Quantity BETWEEN 1 AND 2 THEN 0.00
            WHEN @Quantity BETWEEN 3 AND 5 THEN 0.05
            WHEN @Quantity BETWEEN 6 AND 9 THEN 0.10
            WHEN @Quantity >= 10 THEN 0.15
            ELSE 0.00  
        END

    RETURN @Discount
END;




SELECT 
    order_id,
    item_id,
    quantity,
    dbo.CalculateBulkDiscount(quantity) AS DiscountPercent
FROM sales.order_items;




--13
CREATE PROCEDURE sp_GetCustomerOrderHistory
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        o.order_id,
        o.order_date,
        o.order_status,
            CASE o.order_status
                WHEN 1 THEN 'Pending'
                WHEN 2 THEN 'Processing'
                WHEN 3 THEN 'Rejected'
                WHEN 4 THEN 'Completed'
            END,
        o.required_date,
        o.shipped_date,
        s.store_name,
        st.first_name + ' ' + st.last_name AS staff_name,
        TotalAmount = SUM(oi.quantity * oi.list_price * (1 - oi.discount))
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    INNER JOIN sales.stores s ON o.store_id = s.store_id
    INNER JOIN sales.staffs st ON o.staff_id = st.staff_id
    WHERE o.customer_id = @CustomerID
      AND (@StartDate IS NULL OR o.order_date >= @StartDate)
      AND (@EndDate IS NULL OR o.order_date <= @EndDate)
    GROUP BY 
        o.order_id, o.order_date, o.required_date, o.shipped_date, 
        o.order_status, s.store_name, st.first_name, st.last_name
    ORDER BY o.order_date DESC;
END;




EXEC sp_GetCustomerOrderHistory @CustomerID = 5;





--14
CREATE PROCEDURE sp_RestockProduct
    @StoreID INT,
    @ProductID INT,
    @RestockQty INT,
    @OldQty INT OUTPUT,
    @NewQty INT OUTPUT,
    @Success BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM production.stocks 
        WHERE store_id = @StoreID AND product_id = @ProductID
    )
    BEGIN
        SELECT @OldQty = quantity
        FROM production.stocks
        WHERE store_id = @StoreID AND product_id = @ProductID;

        UPDATE production.stocks
        SET quantity = quantity + @RestockQty
        WHERE store_id = @StoreID AND product_id = @ProductID;

        SELECT @NewQty = quantity
        FROM production.stocks
        WHERE store_id = @StoreID AND product_id = @ProductID;

        SET @Success = 1;
    END
    ELSE
    BEGIN
        SET @OldQty = NULL;
        SET @NewQty = NULL;
        SET @Success = 0;
    END
END;



DECLARE @Old INT, @New INT, @Success BIT;

EXEC sp_RestockProduct
    @StoreID = 1,
    @ProductID = 2,
    @RestockQty = 15,
    @OldQty = @Old OUTPUT,
    @NewQty = @New OUTPUT,
    @Success = @Success OUTPUT;

SELECT 
    Old_Quantity = @Old,
    New_Quantity = @New,
    Status = CASE WHEN @Success = 1 THEN 'Updated' ELSE 'Failed' END;



    --15
    CREATE PROCEDURE sp_ProcessNewOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @StoreID INT
AS
BEGIN
    DECLARE @StaffID INT;
    DECLARE @OrderID INT;
    DECLARE @ListPrice DECIMAL(10,2);
    DECLARE @Today DATE = GETDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP 1 @StaffID = staff_id
        FROM sales.staffs
        WHERE store_id = @StoreID AND active = 1;

        IF @StaffID IS NULL
            THROW 50001, 'No active staff found in the store.', 1;

        SELECT @ListPrice = list_price
        FROM production.products
        WHERE product_id = @ProductID;

        IF @ListPrice IS NULL
            THROW 50002, 'Invalid Product ID.', 1;

        INSERT INTO sales.orders (
            customer_id, order_status, order_date,
            required_date, shipped_date,
            store_id, staff_id
        )
        VALUES (
            @CustomerID, 1, @Today,
            DATEADD(DAY, 7, @Today), NULL,
            @StoreID, @StaffID
        );

        SET @OrderID = SCOPE_IDENTITY();

        INSERT INTO sales.order_items (
            order_id, item_id, product_id,
            quantity, list_price, discount
        )
        VALUES (
            @OrderID, 1, @ProductID,
            @Quantity, @ListPrice, 0
        );

        UPDATE production.stocks
        SET quantity = quantity - @Quantity
        WHERE store_id = @StoreID AND product_id = @ProductID;

        IF @@ROWCOUNT = 0
            THROW 50003, 'Stock not found or not enough.', 1;

        COMMIT TRANSACTION;

        PRINT 'Order processed successfully. Order ID: ' + CAST(@OrderID AS VARCHAR);

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        PRINT 'Error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;




EXEC sp_ProcessNewOrder 
    @CustomerID = 5, 
    @ProductID = 12, 
    @Quantity = 3, 
    @StoreID = 1;




    --16
    CREATE PROCEDURE sp_SearchProducts
    @ProductName NVARCHAR(255) = NULL,
    @CategoryID INT = NULL,
    @MinPrice DECIMAL(10, 2) = NULL,
    @MaxPrice DECIMAL(10, 2) = NULL,
    @SortColumn NVARCHAR(50) = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    SELECT 
        p.product_id,
        p.product_name,
        b.brand_name,
        c.category_name,
        p.model_year,
        p.list_price
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE 1=1';

    IF @ProductName IS NOT NULL
        SET @SQL += ' AND p.product_name LIKE ''%' + @ProductName + '%''';

    IF @CategoryID IS NOT NULL
        SET @SQL += ' AND p.category_id = ' + CAST(@CategoryID AS NVARCHAR);

    IF @MinPrice IS NOT NULL
        SET @SQL += ' AND p.list_price >= ' + CAST(@MinPrice AS NVARCHAR);

    IF @MaxPrice IS NOT NULL
        SET @SQL += ' AND p.list_price <= ' + CAST(@MaxPrice AS NVARCHAR);

    IF @SortColumn IS NOT NULL AND 
       @SortColumn IN ('product_name', 'list_price', 'model_year')  
        SET @SQL += ' ORDER BY p.' + QUOTENAME(@SortColumn);
    ELSE
        SET @SQL += ' ORDER BY p.product_id';

    EXEC sp_executesql @SQL;
END;


EXEC sp_SearchProducts @ProductName = 'Laptop';


EXEC sp_SearchProducts @CategoryID = 3, @MaxPrice = 800;


EXEC sp_SearchProducts 
    @ProductName = 'Phone', 
    @MinPrice = 300, 
    @MaxPrice = 1000,
    @SortColumn = 'list_price';






    --17
IF OBJECT_ID('tempdb..#StaffBonuses') IS NOT NULL
    DROP TABLE #StaffBonuses;

CREATE TABLE #StaffBonuses (
    staff_id INT,
    full_name NVARCHAR(255),
    total_sales DECIMAL(18,2),
    bonus_rate DECIMAL(4,2),
    bonus_amount DECIMAL(18,2)
);

DECLARE 
    @StartDate DATE = '2025-01-01',
    @EndDate DATE = '2025-03-31';

INSERT INTO #StaffBonuses (staff_id, full_name, total_sales, bonus_rate, bonus_amount)
SELECT
    s.staff_id,
    s.first_name + ' ' + s.last_name AS full_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
    
    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) < 10000 THEN 0.00
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 10000 AND 20000 THEN 0.05
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 20001 AND 50000 THEN 0.10
        ELSE 0.15
    END AS bonus_rate,

    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) < 10000 THEN 0.00
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 10000 AND 20000 THEN 
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)) * 0.05
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 20001 AND 50000 THEN 
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)) * 0.10
        ELSE 
            SUM(oi.quantity * oi.list_price * (1 - oi.discount)) * 0.15
    END AS bonus_amount

FROM sales.staffs s
JOIN sales.orders o ON o.staff_id = s.staff_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY s.staff_id, s.first_name, s.last_name;

SELECT * FROM #StaffBonuses
ORDER BY bonus_amount DESC;



--18
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    c.category_name,
    s.quantity,
    
    CASE 
        WHEN p.category_id = 1 AND s.quantity < 10 THEN 50        
        WHEN p.category_id = 2 AND s.quantity < 20 THEN 100        
        WHEN p.category_id NOT IN (1, 2, 3) AND s.quantity < 5 THEN 30  
        ELSE 0  
    END AS reorder_quantity,

    CASE 
        WHEN p.category_id = 1 AND s.quantity < 10 THEN 'Restock Electronics'
        WHEN p.category_id = 2 AND s.quantity < 20 THEN 'Restock Clothing'
        WHEN p.category_id = 3 AND s.quantity < 15 THEN 'Restock Accessories'
        WHEN p.category_id NOT IN (1, 2, 3) AND s.quantity < 5 THEN 'Restock Other Category'
        ELSE 'Stock Sufficient'
    END AS status_message

FROM production.stocks s join production.products p on s.product_id = p.product_id
JOIN production.categories c ON p.category_id = c.category_id
WHERE 
    (
        (p.category_id = 1 AND s.quantity < 10) OR
        (p.category_id = 2 AND s.quantity < 20) OR
        (p.category_id = 3 AND s.quantity < 15) OR
        (p.category_id NOT IN (1,2,3) AND s.quantity < 5)
    )
ORDER BY reorder_quantity DESC;



--19
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    
    ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS total_spent,

    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN 'Platinum'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 5000 AND 9999.99 THEN 'Gold'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) BETWEEN 1000 AND 4999.99 THEN 'Silver'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) < 1000 AND SUM(oi.quantity * oi.list_price * (1 - oi.discount)) IS NOT NULL THEN 'Bronze'
        ELSE 'No Orders'
    END AS loyalty_tier

FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id

GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
ORDER BY 
    total_spent DESC;





    --20
CREATE PROCEDURE sp_DiscontinueProduct
    @product_id INT,
    @replacement_product_id INT = NULL, 
    @status_message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pending_orders INT;

    IF NOT EXISTS (SELECT 1 FROM production.products WHERE product_id = @product_id)
    BEGIN
        SET @status_message = 'Product not found.';
        RETURN;
    END

    SELECT @pending_orders = COUNT(DISTINCT oi.order_id)
    FROM sales.order_items oi
    JOIN sales.orders o ON o.order_id = oi.order_id
    WHERE oi.product_id = @product_id AND o.order_status = 1; 

    IF @pending_orders > 0
    BEGIN
        IF @replacement_product_id IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM production.products WHERE product_id = @replacement_product_id)
            BEGIN
                SET @status_message = 'Replacement product not found.';
                RETURN;
            END

            UPDATE oi
            SET oi.product_id = @replacement_product_id
            FROM sales.order_items oi
            JOIN sales.orders o ON o.order_id = oi.order_id
            WHERE oi.product_id = @product_id AND o.order_status = 1;

            SET @status_message = 'Product replaced in pending orders. ';
        END
        ELSE
        BEGIN
            SET @status_message = 'Pending orders exist. No replacement provided. ';
        END
    END
    ELSE
    BEGIN
        SET @status_message = 'No pending orders. ';
    END

    DELETE FROM production.stocks
    WHERE product_id = @product_id;

    DELETE FROM production.products
    WHERE product_id = @product_id;

    SET @status_message = @status_message + 'Product discontinued and inventory cleared.';
END;




DECLARE @msg NVARCHAR(MAX);
EXEC sp_DiscontinueProduct @product_id = 5, @replacement_product_id = 8, @status_message = @msg OUTPUT;
PRINT @msg;




--Bonus Challenges

--21
WITH MonthlySales AS (
    SELECT
        FORMAT(o.order_date, 'yyyy-MM') AS YearMonth,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS MonthlyRevenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4 
    GROUP BY FORMAT(o.order_date, 'yyyy-MM')
),

StaffPerformance AS (
    SELECT
        s.staff_id,
        CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
        COUNT(DISTINCT o.order_id) AS OrdersHandled,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS TotalSales
    FROM sales.staffs s
    JOIN sales.orders o ON s.staff_id = o.staff_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY s.staff_id, s.first_name, s.last_name
),

CategoryAnalysis AS (
    SELECT
        c.category_name,
        SUM(oi.quantity) AS TotalUnitsSold,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS Revenue
    FROM production.categories c
    JOIN production.products p ON c.category_id = p.category_id
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    JOIN sales.orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY c.category_name
)

SELECT 
    'Monthly Trends' AS Section, 
    YearMonth AS Info1, 
    CAST(MonthlyRevenue AS DECIMAL(18,2)) AS Info2, 
    NULL AS Info3
FROM MonthlySales

UNION ALL

SELECT 
    'Staff Performance',
    staff_name,
    CAST(OrdersHandled AS VARCHAR),
    CAST(TotalSales AS DECIMAL(18,2))
FROM StaffPerformance

UNION ALL

SELECT 
    'Category Analysis',
    category_name,
    CAST(TotalUnitsSold AS VARCHAR),
    CAST(Revenue AS DECIMAL(18,2))
FROM CategoryAnalysis;




