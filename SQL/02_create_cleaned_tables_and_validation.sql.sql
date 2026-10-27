DROP TABLE IF EXISTS clean_cart_items; ----Loome uus ja puhas tabelit clean_cart_items----

CREATE TABLE clean_cart_items (  
    cart_id INTEGER,
    product_id CHARACTER VARYING,
    quantity INTEGER,
    price NUMERIC(12,2)
);

INSERT INTO clean_cart_items (
    cart_id,
    product_id,
    quantity,
    price
)
SELECT
    cart_id::INTEGER,
    product_id::CHARACTER VARYING,
    quantity::INTEGER,
    price::NUMERIC(12,2)
FROM cart_items
WHERE cart_id NOT IN (118204);

---Kontrollime uut tabelit---

SELECT *
FROM clean_cart_items
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM clean_cart_items;

select  
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'clean_cart_items'
ORDER BY ordinal_position;

SELECT * ---Kontrollime, et ostukorv tootega kus hind=0 on eemaldatud---
FROM clean_cart_items
WHERE cart_id IN (118204);

DROP TABLE IF EXISTS clean_order_items;

----Loome uus ja puhas tabelit clean_orders----

DROP TABLE IF EXISTS clean_orders;

CREATE TABLE clean_orders (
    order_id CHARACTER VARYING,
    customer_id CHARACTER VARYING,
    order_date DATE,
    status CHARACTER VARYING,
    total_amount NUMERIC(12,2)
);

INSERT INTO clean_orders (
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
)
SELECT
    order_id::CHARACTER VARYING,
    customer_id::CHARACTER VARYING,
    order_date::DATE,
    CASE
        WHEN LOWER(TRIM(status)) = 'processing' THEN 'complete'
        WHEN LOWER(TRIM(status)) = 'complete' THEN 'complete'
        WHEN LOWER(TRIM(status)) IN ('pending', 'holded', 'closed', 'canceled', 'cancelled') THEN 'canceled'
    END AS status,
    total_amount::NUMERIC(12,2)
FROM Orders
WHERE status IS NOT NULL 
  AND TRIM(status) != ''
  -- Оставляем только строки, у которых статус входит в наш перечень:
  AND LOWER(TRIM(status)) IN ('processing', 'complete', 'pending', 'holded', 'closed', 'canceled', 'cancelled');

---Kontrollime uut tabelit---

SELECT *
FROM clean_orders
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM clean_orders;

SELECT
    status,
    COUNT(*) AS order_count,
    SUM(total_amount) AS revenue
FROM clean_orders
GROUP BY status
ORDER BY status;

SELECT
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'clean_orders'
ORDER BY ordinal_position;


----Loome uus ja puhas tabelit clean_order_items----

DROP TABLE IF EXISTS clean_order_items;

CREATE TABLE public.clean_order_items (
    order_id CHARACTER VARYING,
    product_id CHARACTER VARYING,
    quantity INTEGER,
    unit_price NUMERIC(12,2),
    discount NUMERIC(12,2)
);

INSERT INTO public.clean_order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    discount
)
SELECT
    oi.order_id::CHARACTER VARYING,
    oi.product_id::CHARACTER VARYING,
    oi.quantity::INTEGER,
    oi.unit_price::NUMERIC(12,2),
    oi.discount::NUMERIC(12,2)
FROM Order_items oi
INNER JOIN public.clean_orders o
    ON oi.order_id = o.order_id;

---Kontrollime uut tabelit---

SELECT * 
FROM clean_order_items
LIMIT 20;

SELECT COUNT(*) AS clean_rows
FROM clean_order_items;

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'clean_order_items'
ORDER BY ordinal_position;


----Loome uus ja puhas tabelit clean_products----

DROP TABLE IF EXISTS clean_products;

CREATE TABLE clean_products (
    product_id CHARACTER VARYING,
    product_name CHARACTER VARYING,
    category CHARACTER VARYING,
    brand CHARACTER VARYING,
    price NUMERIC(12,2)
);

INSERT INTO clean_products (
    product_id,
    product_name,
    category,
    brand,
    price
)
SELECT
    product_id::CHARACTER VARYING,
    product_name::CHARACTER VARYING,
    category::CHARACTER VARYING,
    brand::CHARACTER VARYING,
    price::NUMERIC(12,2)
FROM Products;

---Kontrollime uut tabelit---

SELECT *
FROM clean_products
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM clean_products;

SELECT
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'clean_products'
ORDER BY ordinal_position;

----Loome uus ja puhas tabelit clean_customers----

DROP TABLE IF EXISTS clean_customers;

CREATE TABLE clean_customers (
    customer_id CHARACTER VARYING,
    first_order_date DATE
);

INSERT INTO clean_customers (
    customer_id,
    first_order_date
)
SELECT
    customer_id::CHARACTER VARYING,
    first_order_date::TIMESTAMP::DATE
FROM Customers;

---Kontrollime uut tabelit---

SELECT *
FROM clean_customers
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM clean_customers;

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'clean_customers'
ORDER BY ordinal_position;

----Loome uus ja puhas tabelit clean_order_customer_type----

DROP TABLE IF EXISTS clean_order_customer_type;

CREATE TABLE clean_order_customer_type (
    order_id CHARACTER VARYING,
    customer_type CHARACTER VARYING
);

INSERT INTO clean_order_customer_type (
    order_id,
    customer_type
)
SELECT
    order_id::CHARACTER VARYING,
    customer_type::CHARACTER VARYING
FROM Order_customer_type;

---Kontrollime uut tabelit---

SELECT *
FROM clean_order_customer_type
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM Order_customer_type;

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'clean_order_customer_type'
ORDER BY ordinal_position;

----Loome uus ja puhas tabelit clean_carts----

DROP TABLE IF EXISTS clean_carts;

CREATE TABLE clean_carts (
    cart_id INTEGER,
    customer_id VARCHAR,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    status VARCHAR,
    total_amount NUMERIC(12,2)
);
    
    
INSERT INTO clean_carts (
    cart_id,
    customer_id,
    created_at,
    updated_at,
    status,
    total_amount
)
SELECT
    cart_id::integer,
    customer_id::varchar,
    created_at::timestamp, 
    updated_at::timestamp,
    status::varchar,
    total_amount::numeric(12,2)
FROM carts
WHERE cart_id <> 118204;

---Kontrollime uut tabelit---

SELECT *
FROM clean_carts
LIMIT 20;

SELECT COUNT(*) AS total_rows
FROM clean_carts;

SELECT
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'clean_carts'
ORDER BY ordinal_position;

SELECT *
FROM clean_carts
WHERE cart_id = 118204;