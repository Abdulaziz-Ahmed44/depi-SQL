--1
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON sales.customers (email);



--2
CREATE NONCLUSTERED INDEX IX_Products_Category_Brand
ON production.products (category_id, brand_id);


SELECT * 
FROM production.products
WHERE category_id = 3 AND brand_id = 2;


--3
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON sales.orders (order_date)
INCLUDE (customer_id, store_id, order_status);


SELECT order_date, customer_id, store_id, order_status
FROM sales.orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';



--4
CREATE TRIGGER trg_AfterInsertCustomer
ON sales.customers
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO sales.customer_log (customer_id, action)
    SELECT customer_id, 'Welcome New Customer'
    FROM inserted;
END;


INSERT INTO sales.customers (first_name, last_name, phone, email, street, city, state, zip_code)
VALUES ('Ali', 'Mostafa', '0123456789', 'ali@test.com', 'Street 1', 'Cairo', 'EG', '12345');


SELECT * FROM sales.customer_log;






--5
CREATE TRIGGER trg_TrackPriceChange
ON production.products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO production.price_history (product_id, old_price, new_price, changed_by)
    SELECT
        i.product_id,
        d.list_price AS old_price,
        i.list_price AS new_price,
        SYSTEM_USER
    FROM
        inserted i
    INNER JOIN
        deleted d ON i.product_id = d.product_id
    WHERE
        i.list_price <> d.list_price
END



    UPDATE production.products
SET list_price = list_price + 50
WHERE product_id = 1;


SELECT * FROM production.price_history;



--6
CREATE TRIGGER trg_PreventCategoryDeletion
ON production.categories
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN production.products p ON p.category_id = d.category_id
    )
    BEGIN
        RAISERROR ('Cannot delete category: One or more products are assigned to this category.', 16, 1);
        RETURN;
    END

    DELETE FROM production.categories
    WHERE category_id IN (SELECT category_id FROM deleted);
END


DELETE FROM production.categories
WHERE category_id = 1;




--7
CREATE TRIGGER trg_UpdateStockAfterOrderItemInsert
ON sales.order_items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.quantity = s.quantity - i.quantity
    FROM production.stocks s
    JOIN inserted i
        ON s.product_id = i.product_id AND s.store_id = (
            SELECT store_id
            FROM sales.orders
            WHERE order_id = i.order_id
        );

    IF EXISTS (
        SELECT 1
        FROM production.stocks
        WHERE quantity < 0
    )
    BEGIN
        RAISERROR('Stock cannot go below zero. Transaction cancelled.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;



SELECT quantity AS Quantity_Before
FROM production.stocks
WHERE product_id = 1 AND store_id = 1;

INSERT INTO sales.order_items (order_id, item_id, product_id, quantity, list_price, discount)
VALUES (1, 2, 1, 3, 1500.00, 0);

SELECT quantity AS Quantity_After
FROM production.stocks
WHERE product_id = 1 AND store_id = 1;



--8
CREATE TRIGGER trg_LogNewOrder
ON sales.orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO sales.order_audit (order_id, customer_id, store_id, staff_id, order_date)
    SELECT 
        i.order_id,
        i.customer_id,
        i.store_id,
        i.staff_id,
        i.order_date
    FROM inserted i;
END;




INSERT INTO sales.orders (customer_id, order_status, order_date, required_date, store_id, staff_id)
VALUES (1, 1, GETDATE(), DATEADD(DAY, 7, GETDATE()), 1, 1);

SELECT * FROM sales.order_audit
ORDER BY audit_timestamp DESC;
