SELECT   ---Kontrollime kuupäevade vahemikku---
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date
FROM clean_orders;

SELECT   ---Kontrollime kuupäevade vahemikku---
    MIN(updated_at) AS min_carts_date,
    MAX(updated_at) AS max_carts_date
FROM clean_carts cc ;

--- Loome dim_date tabelit---

CREATE TABLE dim_date (
    date_id INTEGER PRIMARY KEY,
    year INTEGER NOT NULL,
    m INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day INTEGER NOT NULL
);

INSERT INTO dim_date (
    date_id,
    year,
    m,
    month_name,
    week,
    day
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_id,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    EXTRACT(MONTH FROM d)::INTEGER AS m,
    TRIM(TO_CHAR(d, 'Month')) AS month_name,
    EXTRACT(WEEK FROM d)::INTEGER AS week,
    EXTRACT(DAY FROM d)::INTEGER AS day
FROM generate_series(
    '2020-12-15'::DATE,
    '2026-09-18'::DATE,
    '1 day'::INTERVAL
) AS d;

SELECT *  ---Kontrollime tabelit---
FROM dim_date
LIMIT 20;

--- Loome dim_customer tabelit---

DROP TABLE IF EXISTS dim_customers;

CREATE TABLE dim_customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_order_date_id INTEGER,
    number_of_orders INTEGER,
    last_order_date_id INTEGER
);

INSERT INTO dim_customers (
    customer_id,
    first_order_date_id,
    number_of_orders,
    last_order_date_id
)
SELECT
    c.customer_id,
    TO_CHAR(c.first_order_date, 'YYYYMMDD')::INTEGER AS first_order_date_id,
    COUNT(o.order_id)::INTEGER AS number_of_orders,
    TO_CHAR(MAX(o.order_date), 'YYYYMMDD')::INTEGER AS last_order_date_id
FROM public.clean_customers c
LEFT JOIN public.clean_orders o
    ON c.customer_id = o.customer_id
    AND o.status = 'complete'
GROUP BY
    c.customer_id,
    c.first_order_date;

SELECT *  ---Kontrollime tabelit---
FROM dim_customers
LIMIT 20;

SELECT COUNT(*) AS clean_rows
FROM dim_customers;

SELECT *
FROM clean_products
LIMIT 5;

--- Loome dim_products tabelit---

DROP TABLE IF EXISTS dim_products;

INSERT INTO dim_products (
    product_id,
    product_name,
    category,
    brand,
    price
)
SELECT
    product_id,
    product_name,
    category,
    brand,
    price
FROM clean_products;

---Kontrollime tabelit---

SELECT *
FROM dim_products
LIMIT 10;

SELECT COUNT(*) AS clean_rows
FROM dim_products;

--- Loome fact_order_items tabelit---

CREATE TABLE fact_order_items (
  fact_order_item_id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(20) NOT NULL,
  product_id VARCHAR(20) NOT NULL,
  customer_id VARCHAR(20),
  date_id INTEGER NOT NULL,
  status VARCHAR(20),
  customer_type VARCHAR(20),
  quantity INTEGER,
  unit_price NUMERIC(10,2),
  discount NUMERIC(10,2),
  vat_rate NUMERIC(5,2),
  revenue_with_vat NUMERIC(12,2),
  revenue_without_vat NUMERIC(12,2),
  days_between_last_order INTEGER
);

INSERT INTO fact_order_items (
    fact_order_item_id,order_id,product_id,customer_id,date_id,status,
    customer_type,quantity,unit_price,discount,vat_rate,revenue_with_vat,
    revenue_without_vat,days_between_last_order
)
WITH complete_order_data AS (
    SELECT
        o.order_id,o.customer_id,o.order_date,o.status,ct.customer_type,d.date_id,
        LAG(o.order_date) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date,o.order_id
        ) AS previous_order_date
    FROM public.clean_orders o
    LEFT JOIN public.clean_order_customer_type ct
        ON o.order_id=ct.order_id
    LEFT JOIN public.dim_date d
        ON o.order_date=TO_DATE(d.date_id::TEXT,'YYYYMMDD')
    WHERE o.status='complete'
),
complete_order_data_with_days AS (
    SELECT
        order_id,customer_id,order_date,status,customer_type,date_id,
        CASE
            WHEN previous_order_date IS NOT NULL
            THEN order_date-previous_order_date
            ELSE NULL
        END AS days_between_last_order
    FROM complete_order_data
),
all_order_data AS (
    SELECT
        o.order_id,o.customer_id,o.order_date,o.status,ct.customer_type,d.date_id
    FROM public.clean_orders o
    LEFT JOIN public.clean_order_customer_type ct
        ON o.order_id=ct.order_id
    LEFT JOIN public.dim_date d
        ON o.order_date=TO_DATE(d.date_id::TEXT,'YYYYMMDD')
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY oi.order_id,oi.product_id
    )::TEXT||'-'||oi.order_id AS fact_order_item_id,
    oi.order_id,
    oi.product_id,
    ao.customer_id,
    ao.date_id,
    ao.status,
    ao.customer_type,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    CASE
        WHEN ao.order_date<DATE '2024-01-01' THEN 0.20
        WHEN ao.order_date<DATE '2025-07-01' THEN 0.22
        ELSE 0.24
    END AS vat_rate,
    ROUND(
        (oi.quantity*oi.unit_price)-COALESCE(oi.discount,0),2
    ) AS revenue_with_vat,
    ROUND(
        ((oi.quantity*oi.unit_price)-COALESCE(oi.discount,0))/
        (1+CASE
            WHEN ao.order_date<DATE '2024-01-01' THEN 0.20
            WHEN ao.order_date<DATE '2025-07-01' THEN 0.22
            ELSE 0.24
        END),2
    ) AS revenue_without_vat,
    cod.days_between_last_order
FROM public.clean_order_items oi
LEFT JOIN all_order_data ao
    ON oi.order_id=ao.order_id
LEFT JOIN complete_order_data_with_days cod
    ON oi.order_id=cod.order_id;

---Kontrollime tabelit---

SELECT COUNT(*) AS row_count
FROM fact_order_items;

--- Kontrollime, kas fact_order_item_id on unikaalne ---
SELECT fact_order_item_id, COUNT(*) AS cnt   
FROM fact_order_items
GROUP BY fact_order_item_id
HAVING COUNT(*) > 1;

--- 3. Kontrollime võtmeväljade puuduvaid väärtusi ---
SELECT
    COUNT(*) FILTER (WHERE fact_order_item_id IS NULL) AS missing_fact_order_item_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE date_id IS NULL) AS missing_date_id
FROM fact_order_items;

--- 4. Kontrollime quantity väärtusi ---
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity
FROM fact_order_items;

SELECT *
FROM fact_order_items
WHERE quantity <= 0 OR quantity IS NULL;

--- 5. Kontrollime unit_price väärtusi ---
SELECT
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price
FROM fact_order_items;

SELECT *
FROM fact_order_items
WHERE unit_price < 0 OR unit_price IS NULL;

--- 6. Kontrollime discount väärtusi ---
SELECT
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    AVG(discount) AS avg_discount
FROM fact_order_items;

SELECT *
FROM fact_order_items
WHERE discount < 0;

--- Kontrollime, et allahindlus ei ületaks brutohinda ---
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    quantity * unit_price AS gross_amount
FROM fact_order_items
WHERE discount > quantity * unit_price;

--- 7. Kontrollime käibemaksumäärasid ---
SELECT
    CASE
        WHEN o.order_date < DATE '2024-01-01' THEN 'Enne 01.01.2024'
        WHEN o.order_date < DATE '2025-07-01' THEN '01.01.2024–30.06.2025'
        ELSE 'Alates 01.07.2025'
    END AS vat_period,
    f.vat_rate,
    COUNT(*) AS frequency
FROM fact_order_items f
JOIN clean_orders o
    ON f.order_id = o.order_id
GROUP BY
    CASE
        WHEN o.order_date < DATE '2024-01-01' THEN 'Enne 01.01.2024'
        WHEN o.order_date < DATE '2025-07-01' THEN '01.01.2024–30.06.2025'
        ELSE 'Alates 01.07.2025'
    END,
    f.vat_rate
ORDER BY MIN(o.order_date);

--- Kontrollime, kas käibemaksumäär vastab tellimuse kuupäevale ---
SELECT
    f.order_id,
    f.date_id,
    f.vat_rate,
    o.order_date
FROM fact_order_items f
JOIN clean_orders o ON f.order_id = o.order_id
WHERE (o.order_date < DATE '2024-01-01' AND f.vat_rate <> 0.20)
   OR (o.order_date >= DATE '2024-01-01' AND o.order_date < DATE '2025-07-01' AND f.vat_rate <> 0.22)
   OR (o.order_date >= DATE '2025-07-01' AND f.vat_rate <> 0.24);

--- 8. Kontrollime revenue_with_vat arvutuse õigsust ---
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    revenue_with_vat,
    ROUND(quantity * unit_price - COALESCE(discount,0),2) AS calculated_revenue_with_vat
FROM fact_order_items
WHERE revenue_with_vat <> 
      ROUND(quantity * unit_price - COALESCE(discount,0),2);

--- 9. Kontrollime revenue_without_vat arvutuse õigsust ---
SELECT
    order_id,
    product_id,
    revenue_with_vat,
    vat_rate,
    revenue_without_vat,
    ROUND(revenue_with_vat / (1 + vat_rate),2) AS calculated_revenue_without_vat
FROM fact_order_items
WHERE revenue_without_vat <>
      ROUND(revenue_with_vat / (1 + vat_rate),2);

--- 10. Kontrollime, et müügitulu ei oleks negatiivne ---
SELECT *
FROM fact_order_items
WHERE revenue_with_vat < 0
   OR revenue_without_vat < 0;

--- 11. Kontrollime order_id vastavust algsele tellimuste tabelile ---
SELECT f.*
FROM fact_order_items f
LEFT JOIN clean_orders o
    ON f.order_id = o.order_id
WHERE o.order_id IS NULL;

--- 12. Kontrollime product_id vastavust dimensioonitabelile ---
SELECT f.*
FROM fact_order_items f
LEFT JOIN dim_products p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

--- 13. Kontrollime date_id vastavust tellimuse kuupäevale ---
SELECT
    f.order_id,
    f.date_id,
    o.order_date
FROM fact_order_items f
JOIN clean_orders o
    ON f.order_id = o.order_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE o.order_date <> TO_DATE(d.date_id::TEXT,'YYYYMMDD');

--- 14. Kontrollime, et ühe tellimuse andmed oleksid ühtsed ---
SELECT
    order_id
FROM fact_order_items
GROUP BY order_id
HAVING COUNT(DISTINCT customer_id) > 1
    OR COUNT(DISTINCT date_id) > 1
    OR COUNT(DISTINCT status) > 1;

--- Kontrollime, et ühel tellimusel oleks ainult üks customer_id ---
SELECT order_id
FROM fact_order_items
GROUP BY order_id
HAVING COUNT(DISTINCT customer_id) > 1;

--- Kontrollime, et ühel tellimusel oleks ainult üks date_id ---
SELECT order_id
FROM fact_order_items
GROUP BY order_id
HAVING COUNT(DISTINCT date_id) > 1;

--- Kontrollime, et ühel tellimusel oleks ainult üks status ---
SELECT order_id
FROM fact_order_items
GROUP BY order_id
HAVING COUNT(DISTINCT status) > 1;

--- 15. Kontrollime days_between_last_order väärtusi ---
SELECT *
FROM fact_order_items
WHERE days_between_last_order < 0;

--- Kontrollime, et esimese lõpetatud tellimuse puhul oleks väärtus NULL ---
WITH x AS (
    SELECT DISTINCT
        customer_id,
        order_id,
        days_between_last_order,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY date_id, order_id) AS rn
    FROM fact_order_items
    WHERE status = 'complete')
SELECT *
FROM x
WHERE rn = 1
  AND days_between_last_order IS NOT NULL;

--- Kontrollime, et lõpetamata tellimustel oleks days_between_last_order NULL ---
SELECT *
FROM fact_order_items
WHERE status <> 'complete'
  AND days_between_last_order IS NOT NULL;

--- Leidme fact_order_items read, kus samal päeval tehti kordustellimus ---
SELECT 
    fact_order_item_id,
    order_id,
    customer_id,
    date_id,
    status,
    days_between_last_order
FROM fact_order_items
WHERE days_between_last_order = 0
ORDER BY customer_id, date_id;

--- Leidme samal päeval sama kliendi poolt sama toote korduva ostmise teistes tellimustes koos staatusega ---

WITH duplicate_product_same_day AS (
    SELECT 
        customer_id,
        date_id,
        product_id
    FROM fact_order_items
    WHERE status = 'complete' 
      AND customer_id IS NOT NULL
    GROUP BY 
        customer_id, 
        date_id, 
        product_id
    HAVING COUNT(DISTINCT order_id) > 1)
SELECT 
    f.customer_id,
    f.date_id,
    f.order_id,
    f.status,
    f.product_id,
    f.quantity,
    f.unit_price,
    f.discount,
    f.revenue_with_vat,
    f.days_between_last_order
FROM fact_order_items f
INNER JOIN duplicate_product_same_day d
    ON f.customer_id = d.customer_id 
   AND f.date_id = d.date_id
   AND f.product_id = d.product_id
WHERE f.status = 'complete'
ORDER BY 
    f.customer_id, 
    f.date_id, 
    f.product_id, 
    f.order_id;

--- Loome fact_order_items_clean tabelit---

CREATE TABLE fact_order_items_clean AS
SELECT *
FROM fact_order_items
WHERE 1 = 0;

INSERT INTO fact_order_items_clean (
    fact_order_item_id,
    order_id,
    product_id,
    customer_id,
    date_id,
    status,
    customer_type,
    quantity,
    unit_price,
    discount,
    vat_rate,
    revenue_with_vat,
    revenue_without_vat,
    days_between_last_order
) WITH cleaned_data AS (
    SELECT
        fact_order_item_id,
        CASE
            WHEN order_id = '000000976' THEN '2000000219'
            WHEN order_id = '000004031' THEN '000004032'
            ELSE order_id
        END AS order_id,
        product_id,
        customer_id,
        date_id,
        status,
        customer_type,
        quantity,
        unit_price,
        discount,
        vat_rate,
        revenue_with_vat,
        revenue_without_vat,
        days_between_last_order
    FROM fact_order_items
    WHERE order_id NOT IN (
        '2000000009',
        '2000000010',
        '2000000011',
        '2000000012',
        '2000000016',
        '2000000017',
        '2000000018',
        '2000000019',
        '2000000020',
        '2000000025',
        '2000000026',
        '2000000035',
        '2000000036',
        '2000000037',
        '2000000038',
        '2000000039',
        '2000000040',
        '2000000041',
        '2000000042',
        '2000000043',
        '2000000045',
        '2000000046',
        '2000000047',
        '2000000048',
        '2000000049',
        '2000000050',
        '2000000051',
        '2000000052',
        '2000000053',
        '2000000054',
        '2000000055',
        '2000000060',
        '2000000061',
        '000001108',
        '000001109',
        '000001110',
        '000003537',
        '2000000744',
        '2000000745',
        '000003538'
    )
), aggregated_data AS (
    SELECT
        order_id,
        product_id,
        SUM(quantity) AS quantity,
        MAX(unit_price) AS unit_price,
        SUM(COALESCE(discount, 0)) AS discount,
        MAX(vat_rate) AS vat_rate,
        SUM(revenue_with_vat) AS revenue_with_vat,
        SUM(revenue_without_vat) AS revenue_without_vat,
        MAX(customer_id) AS customer_id,
        MAX(date_id) AS date_id,
        MAX(status) AS status,
        MAX(customer_type) AS customer_type,
        MAX(days_between_last_order) AS days_between_last_order
    FROM cleaned_data
    GROUP BY
        order_id,
        product_id
) SELECT
    ROW_NUMBER() OVER (
        ORDER BY order_id, product_id
    )::TEXT || '-' || order_id AS fact_order_item_id,
    order_id,
    product_id,
    customer_id,
    date_id,
    status,
    customer_type,
    quantity,
    unit_price,
    discount,
    vat_rate,
    revenue_with_vat,
    revenue_without_vat,
    days_between_last_order
FROM aggregated_data;

---Kontrollime tabelit---

SELECT *
FROM fact_order_items_clean
LIMIT 20;

SELECT  ---Kontrollime fact_order_items VS fact_order_items_clean----
    'fact_order_items (vana)' AS source_table,
    COUNT(*) AS total_rows,
    SUM(quantity) AS total_quantity,
    SUM(revenue_with_vat) AS total_revenue_with_vat
FROM fact_order_items
WHERE status = 'complete'
UNION all
SELECT 
    'fact_order_items_clean (uus)' AS source_table,
    COUNT(*) AS total_rows,
    SUM(quantity) AS total_quantity,
    SUM(revenue_with_vat) AS total_revenue_with_vat
FROM fact_order_items_clean
WHERE status = 'complete';

SELECT 
    '1. vana(fact_order_items)' AS source,
    SUM(discount) AS total_discount,
    SUM(revenue_without_vat) AS total_no_vat,
    SUM(revenue_with_vat - revenue_without_vat) AS total_vat_amount
FROM fact_order_items
WHERE status = 'complete'
UNION all
SELECT 
    '2. uus (fact_order_items_clean)' AS source,
    SUM(discount) AS total_discount,
    SUM(revenue_without_vat) AS total_no_vat,
    SUM(revenue_with_vat - revenue_without_vat) AS total_vat_amount
FROM fact_order_items_clean
WHERE status = 'complete';

SELECT  ---Kontrollime andmete tüüpid---
    c1.column_name,
    c1.data_type AS raw_table_type,
    c2.data_type AS clean_table_type,
    CASE 
        WHEN c1.data_type = c2.data_type THEN 'Klapib'
        ELSE 'Muudetud (Optimeeritud)'
    END AS status
FROM (
    SELECT column_name, data_type, ordinal_position
    FROM information_schema.columns
    WHERE table_name = 'fact_order_items'
) c1
FULL OUTER JOIN (
    SELECT column_name, data_type, ordinal_position
    FROM information_schema.columns
    WHERE table_name = 'fact_order_items_clean'
) c2 ON c1.column_name = c2.column_name
ORDER BY COALESCE(c1.ordinal_position, c2.ordinal_position);

SELECT DISTINCT order_id ---Kontrollime, kas tellimused on kustutatud---
FROM fact_order_items_clean
WHERE order_id IN (
    '2000000009',
    '2000000010',
    '2000000011',
    '2000000012',
    '2000000016',
    '2000000017',
    '2000000018',
    '2000000019',
    '2000000020',
    '2000000025',
    '2000000026',
    '2000000035',
    '2000000036',
    '2000000037',
    '2000000038',
    '2000000039',
    '2000000040',
    '2000000041',
    '2000000042',
    '2000000043',
    '2000000045',
    '2000000046',
    '2000000047',
    '2000000048',
    '2000000049',
    '2000000050',
    '2000000051',
    '2000000052',
    '2000000053',
    '2000000054',
    '2000000055',
    '2000000060',
    '2000000061',
    '000001108',
    '000001109',
    '000001110',
    '000003537',
    '2000000744',
    '2000000745',
    '000003538'
);

select  ---Kontrollime tellimuste ühendamist---
    order_id,
    COUNT(*) AS rows_count,
    SUM(quantity) AS total_quantity,
    SUM(revenue_with_vat) AS total_revenue_with_vat
FROM fact_order_items_clean
WHERE order_id IN ('000000976', '2000000219')
GROUP BY order_id;

SELECT
    order_id,
    COUNT(*) AS rows_count,
    SUM(quantity) AS total_quantity,
    SUM(revenue_with_vat) AS total_revenue_with_vat
FROM fact_order_items_clean
WHERE order_id IN ('000004031', '000004032')
GROUP BY order_id;

--- Loome fact_cart_items tabelit---

DROP TABLE IF EXISTS fact_cart_items;

CREATE TABLE fact_cart_items (
    cart_product_id VARCHAR(50) PRIMARY KEY,
    cart_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    customer_id VARCHAR(20),
    date_id INTEGER NOT NULL,
    status VARCHAR(20),
    quantity INTEGER,
    price NUMERIC(10,2),
    items_amount NUMERIC(12,2),
    items_amount_without_vat NUMERIC(12,2)
);

INSERT INTO fact_cart_items (
    cart_product_id,cart_id,product_id,customer_id,date_id,status,
    quantity,price,items_amount,items_amount_without_vat)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY ci.cart_id,ci.product_id
    )::TEXT || '-' || ci.cart_id AS cart_product_id,
    ci.cart_id,
    ci.product_id,
    c.customer_id,
    d.date_id,
    c.status,
    ci.quantity,
    ci.price,
    ROUND(ci.quantity * ci.price,2) AS items_amount,
    ROUND(
        (ci.quantity * ci.price) / 1.24,
        2) AS items_amount_without_vat
FROM clean_cart_items ci
JOIN clean_carts c
    ON ci.cart_id = c.cart_id
LEFT JOIN dim_date d
    ON c.created_at::date = TO_DATE(d.date_id::TEXT,'YYYYMMDD');


---Kontrollime tabelit---

--- 0. Vaatame fact_cart_items tabeli esimesi ridu ---
SELECT *
FROM fact_cart_items
LIMIT 20;

--- 1. Kontrollime tabeli ridade arvu ---
SELECT COUNT(*) AS ridade_arv
FROM fact_cart_items;

--- 2. Kontrollime cart_product_id unikaalsust ---
SELECT
    cart_product_id,
    COUNT(*) AS ridade_arv
FROM fact_cart_items
GROUP BY cart_product_id
HAVING COUNT(*) > 1;

--- 3. Kontrollime võtmeväljade puuduvaid väärtusi ---
SELECT
    COUNT(*) FILTER (WHERE cart_product_id IS NULL) AS puudu_cart_product_id,
    COUNT(*) FILTER (WHERE cart_id IS NULL) AS puudu_cart_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS puudu_product_id,
    COUNT(*) FILTER (WHERE date_id IS NULL) AS puudu_date_id
FROM fact_cart_items;

--- 4. Kontrollime quantity väärtusi ---
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    ROUND(AVG(quantity)::numeric,2) AS avg_quantity
FROM fact_cart_items;

--- 5. Kontrollime price väärtusi ---
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price)::numeric,2) AS avg_price
FROM fact_cart_items;

--- 5.1. Kontrollime null- ja negatiivseid hindu ---
SELECT *
FROM fact_cart_items
WHERE price <= 0;

--- 6. Kontrollime items_amount arvutust ---
SELECT
    cart_product_id,
    quantity,
    price,
    items_amount,
    ROUND(quantity * price,2) AS expected_items_amount
FROM fact_cart_items
WHERE items_amount <> ROUND(quantity * price,2);

--- 7. Kontrollime items_amount_without_vat arvutust ---
SELECT
    cart_product_id,
    items_amount,
    items_amount_without_vat,
    ROUND(items_amount / 1.24,2) AS expected_amount_without_vat
FROM fact_cart_items
WHERE items_amount_without_vat <> ROUND(items_amount / 1.24,2);

--- 8. Kontrollime, et summad ei oleks negatiivsed ---
SELECT *
FROM fact_cart_items
WHERE items_amount < 0
   OR items_amount_without_vat < 0;

--- 9. Kontrollime seost fact_cart_items → clean_carts ---
SELECT
    f.cart_id
FROM fact_cart_items f
LEFT JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id
WHERE c.cart_id IS NULL;

--- 10. Kontrollime seost fact_cart_items → dim_products ---
SELECT
    f.product_id
FROM fact_cart_items f
LEFT JOIN dim_products p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

--- 11. Kontrollime date_id vastavust ostukorvi loomise kuupäevale ---
SELECT
    f.cart_id,
    f.date_id,
    c.created_at
FROM fact_cart_items f
JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.created_at::DATE <> TO_DATE(d.date_id::TEXT,'YYYYMMDD');

--- 12. Kontrollime customer_id vastavust clean_carts tabeliga ---
SELECT
    f.cart_id,
    f.customer_id AS fact_customer_id,
    c.customer_id AS cart_customer_id
FROM fact_cart_items f
JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id
WHERE f.customer_id IS DISTINCT FROM c.customer_id;

--- 13. Kontrollime staatuse vastavust clean_carts tabeliga ---
SELECT
    f.cart_id,
    f.status AS fact_status,
    c.status AS cart_status
FROM fact_cart_items f
JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id
WHERE f.status IS DISTINCT FROM c.status;

--- 14. Kontrollime, et ühe ostukorvi andmed oleksid ridadel ühesugused ---
SELECT
    cart_id,
    COUNT(DISTINCT customer_id) AS customer_id_arv,
    COUNT(DISTINCT date_id) AS date_id_arv,
    COUNT(DISTINCT status) AS status_arv
FROM fact_cart_items
GROUP BY cart_id
HAVING COUNT(DISTINCT customer_id) > 1
    OR COUNT(DISTINCT date_id) > 1
    OR COUNT(DISTINCT status) > 1;

--- 15. Kontrollime analüüsi perioodi ---
SELECT
    MIN(c.created_at::DATE) AS min_cart_date,
    MAX(c.created_at::DATE) AS max_cart_date
FROM fact_cart_items f
JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id;

--- 15.1. Kontrollime, et kõik ostukorvid kuuluvad analüüsiperioodi ---
SELECT *
FROM fact_cart_items f
JOIN clean_carts c
    ON f.cart_id::INTEGER = c.cart_id
WHERE c.created_at::DATE < DATE '2026-07-01'
   OR c.created_at::DATE >= DATE '2026-10-01';
	

--- 1. Kontrollime dim_date date_id unikaalsust ---
SELECT
    date_id,
    COUNT(*) AS ridade_arv
FROM dim_date
GROUP BY date_id
HAVING COUNT(*) > 1;

--- 2. Kontrollime dim_customers customer_id unikaalsust ---
SELECT
    customer_id,
    COUNT(*) AS ridade_arv
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--- 3. Kontrollime dim_products product_id unikaalsust ---
SELECT
    product_id,
    COUNT(*) AS ridade_arv
FROM dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;

--- 4. Kontrollime ID-väljade andmetüüpe ---
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN (
    'dim_date',
    'dim_customers',
    'dim_products',
    'fact_order_items',
    'fact_cart_items'
)
AND column_name LIKE '%id%'
ORDER BY column_name, table_name;

--- 5. Kontrollime dim_customers kuupäevade seoseid dim_date tabeliga ---
SELECT
    dc.customer_id,
    dc.first_order_date_id,
    dc.last_order_date_id
FROM dim_customers dc
LEFT JOIN dim_date d1
    ON dc.first_order_date_id = d1.date_id
LEFT JOIN dim_date d2
    ON dc.last_order_date_id = d2.date_id
WHERE
    (dc.first_order_date_id IS NOT NULL AND d1.date_id IS NULL)
    OR
    (dc.last_order_date_id IS NOT NULL AND d2.date_id IS NULL);

----Viimane kontroll----

--- 1. Kontrollime, kas faktitabeli kliendid on olemas dimensioonitabelis dim_customers ---
SELECT DISTINCT f.customer_id
FROM fact_order_items f
LEFT JOIN dim_customers c 
    ON f.customer_id = c.customer_id
WHERE f.customer_id IS NOT NULL 
  AND c.customer_id IS NULL;

--- 2. Kontrollime, kas kõik faktitabeli kuupäevad on olemas kalendritabelis dim_date ---
SELECT DISTINCT f.date_id
FROM fact_order_items f
LEFT JOIN dim_date d 
    ON f.date_id = d.date_id
WHERE d.date_id IS NULL;

--- 3. Kontrollime, kas ostukorvi faktide kliendid on olemas dimensioonitabelis dim_customers ---
SELECT DISTINCT f.customer_id
FROM fact_cart_items f
LEFT JOIN dim_customers c 
    ON f.customer_id = c.customer_id
WHERE f.customer_id IS NOT NULL 
  AND c.customer_id IS NULL;

--- Kontrollime müügitulu koondsummade vastavust algandmete ja faktitabeli vahel ---

select (
        SELECT ROUND(SUM(quantity * unit_price - COALESCE(discount, 0)), 2) 
        FROM public.clean_order_items oi
        JOIN public.clean_orders o ON oi.order_id = o.order_id
    ) AS raw_total_revenue_with_vat,(
        SELECT SUM(revenue_with_vat) 
        FROM fact_order_items
    ) AS fact_total_revenue_with_vat,(
        SELECT ROUND(SUM(quantity * unit_price - COALESCE(discount, 0)), 2) 
        FROM public.clean_order_items oi
        JOIN public.clean_orders o ON oi.order_id = o.order_id
    ) - (
        SELECT SUM(revenue_with_vat) 
        FROM fact_order_items
    ) AS difference;

----Kontrollime PRIMARY KEYS ja loome----

ALTER TABLE fact_order_items_clean 
    ALTER COLUMN fact_order_item_id SET NOT NULL,
    ADD PRIMARY KEY (fact_order_item_id);



