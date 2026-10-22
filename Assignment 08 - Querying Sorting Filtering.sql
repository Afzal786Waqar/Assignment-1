
-- ============================================================
--  ASSIGNMENT 01 — Querying, Sorting & Filtering
--  Database : BikeStores
--  Topics   : SELECT, WHERE, ORDER BY, TOP/OFFSET-FETCH,
--             DISTINCT, AND / OR
-- ============================================================


-- ============================================================
--  Question 1 — SELECT & WHERE
--  Retrieve the first name, last name, city, and phone number
--  of all customers who live in the state of 'CA' (California)
--  and have a phone number on record.
-- ============================================================

-- Write your query below:

SELECT first_name, last_name, city, phone
FROM sales.customers
WHERE state = 'CA'
  AND phone IS NOT NULL;

-- ============================================================
--  Question 2 — ORDER BY (Multiple Columns)
--  Fetch the product_id, product_name, model_year, and
--  list_price of all products.
--  Sort the results by model_year in descending order, and
--  within the same year sort by list_price in ascending order.
-- ============================================================

-- Write your query below:

SELECT product_id, product_name, model_year, list_price
FROM production.products
ORDER BY model_year DESC, list_price ASC;

-- ============================================================
--  Question 3 — TOP N & TOP PERCENT
--  a) Return the top 5 most expensive products showing only
--     product_name and list_price.
--  b) Return the top 5% of cheapest products (all columns).
--     How many rows does the 5% result return? Add the row
--     count as a comment in your answer.
-- ============================================================

-- Part a:

SELECT TOP 5 product_name, list_price
FROM production.products
ORDER BY list_price DESC;

-- Part b:

SELECT TOP 5 PERCENT *
FROM production.products
ORDER BY list_price ASC;

-- ============================================================
--  Question 4 — OFFSET & FETCH (Pagination)
--  The sales team wants to browse products page by page,
--  10 products per page, sorted by list_price descending.
--  Write queries to return:
--    a) Page 1  (rows  1 – 10)
--    b) Page 2  (rows 11 – 20)
--    c) Page 3  (rows 21 – 30)
-- ============================================================

-- Page 1:
-- Page 1 (rows 1-10)
SELECT product_id, product_name, list_price
FROM production.products
ORDER BY list_price DESC, product_id
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 2:
-- Page 2 (rows 11-20)
SELECT product_id, product_name, list_price
FROM production.products
ORDER BY list_price DESC, product_id
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 3:
-- Page 3 (rows 21-30)
SELECT product_id, product_name, list_price
FROM production.products
ORDER BY list_price DESC, product_id
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- ============================================================
--  Question 5 — DISTINCT
--  a) List all unique states in which BikeStores has customers.
--     Sort the result alphabetically.
--  b) List every unique combination of state and city,
--     sorted by state then city (both ascending).
--  c) How many unique model years exist in the products table?
--     (Retrieve the distinct values; count them manually or
--     use COUNT — your choice.)
-- ============================================================

-- Part a:
-- Part a: unique states, alphabetical
SELECT DISTINCT state
FROM sales.customers
ORDER BY state;

-- Part b:
-- Part b: unique state + city combinations
SELECT DISTINCT state, city
FROM sales.customers
ORDER BY state ASC, city ASC;

-- Part c:
-- Part c: unique model years
SELECT DISTINCT model_year
FROM production.products
ORDER BY model_year;

-- Or count them directly:
SELECT COUNT(DISTINCT model_year) AS unique_model_years
FROM production.products;
-- Expected: 4 (2016, 2017, 2018, 2019). Newer versions of the
-- dataset may also include 2020; check your output.

-- ============================================================
--  Question 6 — Logical Operators (AND / OR)
--  Write a single query that returns the product_id,
--  product_name, brand_id, category_id, and list_price for
--  products that meet ALL of the following conditions:
--    • list_price is between $500 and $1500 (inclusive)
--    • model_year is 2019 OR 2020
--  Sort the results by list_price ascending.
--  Hint: use parentheses to control the order of evaluation.
-- ============================================================

-- Write your query below:
select * from production.products
SELECT product_id,
       product_name,
       brand_id,
       category_id,
       list_price
FROM production.products
WHERE list_price BETWEEN 500 AND 1500
  AND (model_year = 2019 OR model_year = 2020)
ORDER BY list_price ASC;

-- BikeStores Data me 2019 me $500 between $1500 ka Data nahi he and 2020 me koi Data nahi he is liye iska output kuch bhi nahi aa rha he

-- Checking k liye 2017 and 2018 ka Data check kiya he iska output aa raha he q k is me hamary Question k mutabiq Query BikeStore Data me mujood he

SELECT product_id, product_name, brand_id, category_id, list_price
FROM production.products
WHERE list_price BETWEEN 500 AND 1500
  AND (model_year = 2017 OR model_year = 2018)
ORDER BY list_price ASC;
