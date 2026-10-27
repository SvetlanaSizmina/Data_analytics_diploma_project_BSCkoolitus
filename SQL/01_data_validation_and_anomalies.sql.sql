SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers --- 1. Andmete mahu ja tühjade tabelite kontroll---
UNION ALL
SELECT 'order_customer_type', COUNT(*) FROM order_customer_type
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'carts', COUNT(*) FROM carts
UNION ALL
SELECT 'cart_items', COUNT(*) FROM cart_items
ORDER BY table_name;

SELECT    ---2. Andmetüüpide kontroll---
    table_name, 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name IN ('order_items', 'orders', 'products', 'cart_items', 'carts', 'customers', 'order_customer_type')
ORDER BY table_name, ordinal_position;

select ---Struktuuri kontroll---
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN (
    'order_items',
    'orders',
    'products',
    'cart_items',
    'carts',
    'customers',
    'order_customer_type'
)
ORDER BY table_name, ordinal_position;

SELECT cart_id, product_id, COUNT(*) -----3. Primaarvõtmete kontroll tühjade väärtuste ja duplikaatide suhtes------
FROM Cart_items 
GROUP BY cart_id, product_id 
HAVING COUNT(*) > 1 OR cart_id IS NULL OR product_id IS NULL;

SELECT cart_id, COUNT(*) 
FROM Carts 
GROUP BY cart_id 
HAVING COUNT(*) > 1 OR cart_id IS NULL;

SELECT customer_id, COUNT(*) 
FROM Customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1 OR customer_id IS NULL;

SELECT order_id, COUNT(*) 
FROM Order_customer_type 
GROUP BY order_id 
HAVING COUNT(*) > 1 OR order_id IS NULL;

SELECT 
    order_id,  
    product_id, 
    COUNT(*) AS count
FROM Order_items 
GROUP BY order_id, product_id 
HAVING COUNT(*) > 1 
    OR order_id IS NULL 
    OR product_id IS NULL;

SELECT order_id, COUNT(*) 
FROM Orders 
GROUP BY order_id 
HAVING COUNT(*) > 1 OR order_id IS NULL;

SELECT product_id, COUNT(*) 
FROM Products 
GROUP BY product_id 
HAVING COUNT(*) > 1 OR product_id IS NULL;

select             ---4.Puuduvate väärtuste üldine ülevaade (Tühjad tekstiread, NULL, Tekstiline väärtus "NULL")---
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (where cart_id IS NULL) AS cart_id_null,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(product_id AS VARCHAR))) = 'null'
    ) AS product_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(product_id AS VARCHAR)) = ''
    ) AS product_id_empty,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS quantity_null,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_null
FROM cart_items;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE cart_id IS NULL) AS cart_id_null,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(customer_id AS VARCHAR))) = 'null'
    ) AS customer_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(customer_id AS VARCHAR)) = ''
    ) AS customer_id_empty,
    COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(created_at)) = 'null'
    ) AS created_at_text_null,
    COUNT(*) FILTER (WHERE TRIM(created_at) = ''
    ) AS created_at_empty,
    COUNT(*) FILTER (WHERE updated_at IS NULL) AS updated_at_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(updated_at)) = 'null'
    ) AS updated_at_text_null,
    COUNT(*) FILTER (WHERE TRIM(updated_at) = ''
    ) AS updated_at_empty,
    COUNT(*) FILTER (WHERE status IS NULL) AS status_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'null'
    ) AS status_text_null,
    COUNT(*) FILTER (WHERE TRIM(status) = ''
    ) AS status_empty,
    COUNT(*) FILTER (WHERE total_amount IS NULL) AS total_amount_null
FROM carts;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(customer_id AS VARCHAR))) = 'null'
    ) AS customer_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(customer_id AS VARCHAR)) = ''
    ) AS customer_id_empty,
    COUNT(*) FILTER (WHERE first_order_date IS NULL) AS first_order_date_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(first_order_date AS VARCHAR))) = 'null'
    ) AS first_order_date_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(first_order_date AS VARCHAR)) = ''
    ) AS first_order_date_empty
FROM customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(order_id AS VARCHAR))) = 'null'
    ) AS order_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(order_id AS VARCHAR)) = ''
    ) AS order_id_empty,
    COUNT(*) FILTER (WHERE customer_type IS NULL) AS customer_type_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(customer_type)) = 'null'
    ) AS customer_type_text_null,
    COUNT(*) FILTER (WHERE TRIM(customer_type) = ''
    ) AS customer_type_empty
FROM order_customer_type;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(order_id AS VARCHAR))) = 'null'
    ) AS order_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(order_id AS VARCHAR)) = ''
    ) AS order_id_empty,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(product_id AS VARCHAR))) = 'null'
    ) AS product_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(product_id AS VARCHAR)) = ''
    ) AS product_id_empty, 
    COUNT(*) FILTER (WHERE quantity IS NULL) AS quantity_null,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS unit_price_null,
    COUNT(*) FILTER (WHERE discount IS NULL) AS discount_null
FROM order_items;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(order_id)) = 'null'
    ) AS order_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(order_id) = ''
    ) AS order_id_empty,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(customer_id)) = 'null'
    ) AS customer_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(customer_id) = ''
    ) AS customer_id_empty,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS order_date_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(order_date)) = 'null'
    ) AS order_date_text_null,
    COUNT(*) FILTER (WHERE TRIM(order_date) = ''
    ) AS order_date_empty,
    COUNT(*) FILTER (WHERE status IS NULL) AS status_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(status)) = 'null'
    ) AS status_text_null,
    COUNT(*) FILTER (WHERE TRIM(status) = ''
    ) AS status_empty,
    COUNT(*) FILTER (WHERE total_amount IS NULL) AS total_amount_null
FROM orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(CAST(product_id AS VARCHAR))) = 'null'
    ) AS product_id_text_null,
    COUNT(*) FILTER (WHERE TRIM(CAST(product_id AS VARCHAR)) = ''
    ) AS product_id_empty,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS product_name_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(product_name)) = 'null'
    ) AS product_name_text_null,
    COUNT(*) FILTER (WHERE TRIM(product_name) = ''
    ) AS product_name_empty,
    COUNT(*) FILTER (WHERE category IS NULL) AS category_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(category)) = 'null'
    ) AS category_text_null,
    COUNT(*) FILTER (WHERE TRIM(category) = ''
    ) AS category_empty,
    COUNT(*) FILTER (WHERE brand IS NULL) AS brand_null,
    COUNT(*) FILTER (WHERE LOWER(TRIM(brand)) = 'null'
    ) AS brand_text_null,
    COUNT(*) FILTER (WHERE TRIM(brand) = ''
    ) AS brand_empty,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_null
FROM products;

----Cart_items: Tabelipõhine andmekvaliteedi kontroll----

select   ---Kontrollime quantity---
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    AVG(quantity) AS avg_quantity
FROM cart_items;

SELECT *
FROM Cart_items
WHERE quantity <= 0;

select   ---Kontrollime price---
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price
FROM cart_items;

SELECT *
FROM cart_items
WHERE price = 0

SELECT product_id, product_name, price, category, brand
FROM products
WHERE product_id = 'P007290';

SELECT 
    c.cart_id,
    c.customer_id,
    c.status,
    c.total_amount,
    ci.product_id,
    ci.price
FROM cart_items ci
JOIN carts c ON ci.cart_id = c.cart_id
WHERE ci.price = 0;

SELECT *
FROM cart_items
WHERE cart_id IN (118125);

SELECT ci.cart_id  ----Kontrollime ühendust Carts tabeliga----
FROM cart_items ci
LEFT JOIN carts c
    ON ci.cart_id = c.cart_id
WHERE c.cart_id IS NULL;

SELECT ci.product_id ----Kontrollime ühendust Products tabeliga----
FROM cart_items ci
LEFT JOIN products p
    ON ci.product_id = p.product_id
WHERE p.product_id IS NULL;

----Carts: Tabelipõhine andmekvaliteedi kontroll----

select    ---Kontrollime statuses lubatud väärtused--
    status,
    COUNT(*) AS frequency
FROM carts
GROUP BY status
ORDER BY frequency DESC;

SELECT ---Kontrollime, kui palju on ostukorve, kus customer_id = NULL---
    customer_id, 
    COUNT(*) AS total_carts
FROM carts
WHERE customer_id IS NULL 
   OR customer_id = '' 
   OR LOWER(CAST(customer_id AS TEXT)) = 'null'
GROUP BY customer_id;

SELECT   ---Kontrollime, kui millised staatused on ostukorvidel kus customer_id =0---
    status,
    COUNT(*) AS total_carts
FROM carts
WHERE customer_id IS NULL 
   OR customer_id = '' 
   OR LOWER(CAST(customer_id AS TEXT)) = 'null'
GROUP BY status
ORDER BY total_carts DESC;

select   ---Kontrollime kuupäevade loogilise korrektsust---
    cart_id,
    customer_id,
    created_at,
    updated_at,
    status
FROM carts
WHERE updated_at::timestamp < created_at::timestamp; 

SELECT
    cart_id,
    customer_id,
    created_at,
    updated_at,
    status
FROM carts
WHERE created_at::timestamp > CURRENT_TIMESTAMP
   OR updated_at::timestamp > CURRENT_TIMESTAMP;

SELECT
    MIN(created_at) AS min_created_at,
    MAX(created_at) AS max_created_at,
    MIN(updated_at) AS min_updated_at,
    MAX(updated_at) AS max_updated_at
FROM Carts;

select   ---kontrollime total_amount---
    MIN(total_amount) AS min_total_amount,
    MAX(total_amount) AS max_total_amount,
    AVG(total_amount) AS avg_total_amount
FROM carts;

SELECT *
FROM Carts
WHERE total_amount < 0;

SELECT ---Kontrollime ostukorve, mille total_amount = 0---
    c.cart_id, 
    c.customer_id, 
    c.status, 
    c.total_amount,
    ci.product_id,
    ci.quantity,
    ci.price
FROM carts c
LEFT JOIN cart_items ci ON c.cart_id = ci.cart_id
WHERE c.total_amount = 0;

select ---Kontrollime seost Carts → Customers---
    c.customer_id,
    COUNT(*) AS total_carts
FROM carts c
LEFT JOIN customers cu
    ON c.customer_id = cu.customer_id
WHERE c.customer_id IS NOT NULL
  AND cu.customer_id IS NULL
GROUP BY c.customer_id
ORDER BY total_carts DESC;


select  ---Kontrollime seost Carts → Cart_items---
    c.cart_id,
    c.customer_id,
    c.status,
    c.total_amount,
    c.created_at
FROM carts c
LEFT JOIN cart_items ci
    ON c.cart_id = ci.cart_id
WHERE ci.cart_id IS NULL;

select  ------ Kontrollime, kas summad klappivad tabelites Carts ja Cart_items---
    c.cart_id,
    c.status,
    c.total_amount AS carts_total_amount,
    SUM(ci.quantity * ci.price) AS cart_items_total_amount,
    c.total_amount - SUM(ci.quantity * ci.price) AS difference,
    ROUND(
        (
            (c.total_amount - SUM(ci.quantity * ci.price)) 
            / NULLIF(SUM(ci.quantity * ci.price), 0) * 100
        )::numeric, 
        2
    ) AS difference_pct
FROM carts c
JOIN cart_items ci
    ON c.cart_id = ci.cart_id
GROUP BY
    c.cart_id,
    c.status,
    c.total_amount
ORDER BY difference DESC;

WITH cart_pct_diffs AS (   ---Grupeerimine ostukorvi summa lahknevuse järgi---
    SELECT
        c.cart_id,
        c.status,
        c.total_amount,
        SUM(ci.quantity * ci.price) AS items_total_amount,
        (c.total_amount - SUM(ci.quantity * ci.price)) AS diff_amount,
        ((c.total_amount - SUM(ci.quantity * ci.price)) / NULLIF(SUM(ci.quantity * ci.price), 0) * 100) AS diff_pct
    FROM carts c
    JOIN cart_items ci ON c.cart_id = ci.cart_id
    GROUP BY c.cart_id, c.status, c.total_amount
),
cart_groups AS (
    SELECT
        cart_id,
        status,
        diff_amount,
        diff_pct,
        CASE
            WHEN ABS(diff_pct) <= 0.01 THEN '0–0.01%'
            WHEN ABS(diff_pct) <= 1 THEN '>0.01–1%'
            WHEN ABS(diff_pct) <= 5 THEN '>1–5%'
            WHEN ABS(diff_pct) <= 10 THEN '>5–10%'
            ELSE '>10%'
        END AS diff_group
    FROM cart_pct_diffs
)
SELECT
    diff_group,
    COUNT(*) AS frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_pct,
    ROUND(MIN(diff_amount)::numeric, 2) AS min_diff_amount,
    ROUND(MAX(diff_amount)::numeric, 2) AS max_diff_amount
FROM cart_groups
GROUP BY diff_group
ORDER BY
    CASE diff_group
        WHEN '0–0.01%' THEN 1
        WHEN '>0.01–1%' THEN 2
        WHEN '>1–5%' THEN 3
        WHEN '>5–10%' THEN 4
        WHEN '>10%' THEN 5
    END;

WITH CartsWithShipping AS (  --- Vaatame ostukorve, kus tarnekulu on vähemalt 0.50 eurot ---
    SELECT 
        c.cart_id,
        c.status,
        c.total_amount AS carts_total_amount,
        SUM(ci.quantity * ci.price) AS cart_items_total_amount,
        (c.total_amount - SUM(ci.quantity * ci.price)) AS shipping_amount
    FROM carts c
    JOIN cart_items ci ON c.cart_id = ci.cart_id
    GROUP BY c.cart_id, c.status, c.total_amount
    HAVING (c.total_amount - SUM(ci.quantity * ci.price)) >= 0.50
)
SELECT 
    COUNT(*) AS total_carts_with_shipping,
    ROUND(AVG(shipping_amount)::numeric, 2) AS avg_shipping_amount,
    ROUND(MIN(shipping_amount)::numeric, 2) AS min_shipping_amount,
    ROUND(MAX(shipping_amount)::numeric, 2) AS max_shipping_amount
FROM CartsWithShipping;

----Customers: Tabelipõhine andmekvaliteedi kontroll----

SELECT first_order_date  ---Andmete esmane ülevaade---
FROM Customers
LIMIT 30;
 
SELECT first_order_date  ---Kuupäeva vormingu ja struktuuri kontroll---
FROM Customers
WHERE first_order_date IS NOT NULL
  AND TRIM(first_order_date) <> ''
  AND first_order_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
LIMIT 20;

select   ---Ajalise vahemiku kontroll---
    MIN(first_order_date::DATE) AS min_date,
    MAX(first_order_date::DATE) AS max_date
FROM Customers
WHERE first_order_date IS NOT NULL
  AND TRIM(first_order_date) <> '';

SELECT *  ---Tulevikukuupäevade ehk anomaaliate kontroll---
FROM Customers
WHERE first_order_date IS NOT NULL
  AND TRIM(first_order_date) <> ''
  AND first_order_date::DATE > CURRENT_DATE;

SELECT   ---kliendi profiilis olev esimene tellimuse kuupäev ühtib tellimuse kuupäevaga---
    c.customer_id, 
    c.first_order_date::DATE AS customer_first_date, 
    MIN(o.order_date) AS actual_first_order_date
FROM Customers c
JOIN clean_orders o ON c.customer_id = o.customer_id
WHERE c.first_order_date IS NOT NULL 
  AND TRIM(c.first_order_date) <> ''
GROUP BY c.customer_id, c.first_order_date
HAVING c.first_order_date::DATE != MIN(o.order_date);

----Order_customer_type: Tabelipõhine andmekvaliteedi kontroll----

SELECT DISTINCT oct.order_id   ---Kontrollime order_id seost---
FROM Order_customer_type oct
LEFT JOIN Orders o
    ON oct.order_id = o.order_id
WHERE o.order_id IS NULL;

select  ---Kontrollime, et ühel tellimusel ei ole mittu customer_type---
    order_id,
    COUNT(DISTINCT customer_type) AS customer_type_count
FROM Order_customer_type
GROUP BY order_id
HAVING COUNT(DISTINCT customer_type) > 1;

select   ---Kontrollime customer_type---
    customer_type,
    COUNT(*) AS order_count
FROM Order_customer_type
GROUP BY customer_type
ORDER BY order_count DESC;

----Order items: Tabelipõhine andmekvaliteedi kontroll----

SELECT
    MIN(quantity) AS min_quantity,  ---Kontrollime quantity---
    MAX(quantity) AS max_quantity
FROM order_items;

SELECT *
FROM order_items
WHERE quantity <= 0;

select       ---Kontrollime unit_price---
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price
FROM order_items;

SELECT 
    oi.order_id,
    o.status AS order_status,
    oi.product_id,
    p.product_name AS product_name,
    p.price AS catalog_price, -- Цена товара из основного каталога products
    oi.quantity,
    oi.unit_price AS order_unit_price, -- Фактическая цена в заказе (0)
    oi.discount
FROM order_items oi
LEFT JOIN orders o 
    ON oi.order_id = o.order_id
LEFT JOIN products p 
    ON oi.product_id = p.product_id
WHERE oi.unit_price = 0;

WITH problematic_orders AS (  ---Kontrolime discount---
    -- Находим ID всех заказов, где есть товары с префиксом PX
    SELECT DISTINCT order_id
    FROM order_items
    WHERE product_id LIKE 'PX%'
)
select ---kontrollime allahindlusi---
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    AVG(discount) AS avg_discount
FROM order_items;

SELECT *
FROM order_items
WHERE discount < 0;

select  ---Kas on allahindlus kus suurem kui toote hind---
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    quantity * unit_price AS gross_amount
FROM order_items
WHERE discount > quantity * unit_price;

SELECT  ---allahindlus % min ja max---
    ROUND(
        MIN(discount / NULLIF(quantity * unit_price, 0) * 100)::numeric,
        2
    ) AS min_discount_percent,
    ROUND(
        MAX(discount / NULLIF(quantity * unit_price, 0) * 100)::numeric,
        2
    ) AS max_discount_percent,
    ROUND(
        AVG(discount / NULLIF(quantity * unit_price, 0) * 100)::numeric,
        2
    ) AS avg_discount_percent
FROM order_items;

select   ---Kontrollitakse order_id + product_id kombinatsiooni unikaalsust---
    order_id,
    product_id,
    COUNT(*) AS number_of_rows
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

SELECT oi.order_id  ---Kontrollime ühenduse tellimustega, kas tellimuse numbrid on mõlemates tabelites---
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT distinct ---Kontrollime ühenduse toodetega, kas kõik tooted on product tabelis---
    oi.order_id,
    o.status AS order_status,
    oi.product_id,
    oi.quantity,
    oi.unit_price
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
ORDER BY oi.order_id;

select     ---iga toote vaatamise eest arvestatakse tasu enne ja pärast allahindlust---
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    quantity * unit_price AS gross_amount,
    quantity * unit_price - discount AS net_amount
FROM order_items 
order by net_amount desc 
LIMIT 20;

select  ---Tellimuste summade võrdlemine (orders vs order_items)---
    o.order_id,
    o.status,
    o.total_amount AS order_total,
SUM(oi.quantity * oi.unit_price) AS calculated_gross_total,
SUM(oi.quantity * oi.unit_price - oi.discount) AS calculated_net_total,
o.total_amount - SUM(oi.quantity * oi.unit_price - oi.discount) AS difference,
ROUND(((o.total_amount- SUM(oi.quantity * oi.unit_price - oi.discount))/ 
NULLIF(SUM(oi.quantity * oi.unit_price - oi.discount),0) * 100)::numeric,
2) AS diff_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.status,
    o.total_amount
having o.total_amount <>
    SUM(oi.quantity * oi.unit_price - oi.discount)
ORDER BY diff_pct ASC;


WITH order_pct_diffs AS (   ---Tellimuste summade võrdlemine (orders vs order_items)---
    SELECT
        o.order_id,
        o.status,
        -- 1. Разница в деньгах (абсолютная)
        (o.total_amount - SUM(oi.quantity * oi.unit_price - oi.discount)) AS diff_amount,
        -- 2. Процент расхождения
        ROUND(
            (
                (o.total_amount - SUM(oi.quantity * oi.unit_price - oi.discount)) 
                / NULLIF(SUM(oi.quantity * oi.unit_price - oi.discount), 0) 
                * 100
            )::numeric,
            2
        ) AS diff_pct
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.status,
        o.total_amount
)
SELECT
    diff_pct,
    COUNT(*) AS frequency,
    ROUND(
        (COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()),
        1
    ) AS share_pct,
    -- Минимальное и максимальное расхождение в деньгах внутри этой процентной группы
    ROUND(MIN(diff_amount)::numeric, 2) AS min_diff_amount,
    ROUND(MAX(diff_amount)::numeric, 2) AS max_diff_amount
FROM order_pct_diffs
GROUP BY diff_pct
ORDER BY frequency DESC
LIMIT 10;

----Orders: Tabelipõhine andmekvaliteedi kontroll----

select  ---Kontrollime statusid---
    status,
    COUNT(*) AS frequency
FROM orders
GROUP BY status
ORDER BY frequency DESC;

select  ---Kontrollime küüpäevad---
    order_date,
    COUNT(*) AS frequency
FROM orders
GROUP BY order_date
ORDER BY order_date
LIMIT 30;

SELECT
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date
FROM Orders;

SELECT *  ---Kas on tühjad või mittestandardsed väärtused---
FROM orders
WHERE order_date IS NULL
   OR TRIM(order_date) = ''
   OR LOWER(TRIM(order_date)) = 'null';

select   ---Võimatute olukordade kontrollimine--
    o.order_id,
    o.customer_id,
    o.order_date,
    c.first_order_date
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date::date < c.first_order_date::date;

select   ---Kontrollime total_amount---
    MIN(total_amount) AS min_amount,
    MAX(total_amount) AS max_amount,
    AVG(total_amount) AS avg_amount
FROM orders;

SELECT *
FROM Orders
WHERE total_amount::numeric < 0;

select    --- ei saanud kontrollida, kuna andmeteformat on REAL---
    total_amount
FROM Orders
WHERE total_amount !~ '^-?[0-9]+(\.[0-9]+)?$'
LIMIT 20;

select  ---kas iga tellimus on setud kliendiga---
    o.order_id,
    o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

----Products: Tabelipõhine andmekvaliteedi kontroll----

	select  ---hindade kontroll---
	    MIN(price) AS min_price,
	    MAX(price) AS max_price,
	    AVG(price) AS avg_price
	FROM products;
	
	SELECT ---Madalaima hinnaga tooted---
    product_id,
    product_name,
    price,
    category
FROM products
WHERE price < 0.5
ORDER BY price ASC;

select  ---Kontrollime kaubamärke---
    brand,
    COUNT(*) AS frequency
FROM products
GROUP BY brand
ORDER BY frequency DESC;

select  ---Kontrollime kategooriaid---
    category,
    COUNT(*) AS frequency
FROM products
GROUP BY category
ORDER BY frequency DESC;

SELECT
    product_id,
    product_name,
    category
FROM products
WHERE category LIKE '%;%';

select ---Kui palju tooteid mittu kategooriatega---
    COUNT(*) AS products_with_multiple_categories
FROM products
WHERE category LIKE '%;%';

