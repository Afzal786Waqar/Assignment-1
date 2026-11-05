
-- ============================================================
--  Question 1 — Aggregate Functions
--  From sales.order_items, write ONE query that returns:
--    • total number of order lines
--    • total units sold (SUM of quantity)
--    • average, minimum and maximum list_price
--  Give every column a meaningful alias.
-- ============================================================

SELECT
    COUNT(*)           AS total_order_lines,
    SUM(quantity)      AS total_units_sold,
    AVG(list_price)    AS avg_list_price,
    MIN(list_price)    AS min_list_price,
    MAX(list_price)    AS max_list_price
FROM sales.order_items;

-- ============================================================
--  Question 2 — COUNT(*) vs COUNT(column)
--  a) How many rows are there in sales.customers?
--  b) How many customers have an email on record, and how many
--     have a phone number on record?
--  c) Using the results above, how many customers have NO phone
--     number? Confirm it with a separate query using IS NULL.
--  Add the numbers you get as comments.
-- ============================================================

-- Part a:
-- Total rows in sales.customers
SELECT COUNT(*) AS total_customers
FROM sales.customers;

-- Part b:
-- Customers with an email on record, and with a phone on record
-- COUNT(column) skips NULLs, COUNT(*) does not

SELECT
    COUNT(email) AS customers_with_email,
    COUNT(phone) AS customers_with_phone
FROM sales.customers;

-- Part c:
-- Customers with NO phone number
-- Derived: COUNT(*) - COUNT(phone) = 1445 - 178 = 1267
-- Confirmation with IS NULL:

SELECT COUNT(*) AS customers_without_phone
FROM sales.customers
WHERE phone IS NULL;

-- ============================================================
--  Question 3 — GROUP BY
--  a) Find the total units sold (SUM of quantity) for each
--     product_id in sales.order_items, highest first.
--  b) Count the number of customers in each state, highest
--     first.
--  c) Count the number of orders handled by each staff_id and
--     each order_status combination.
-- ============================================================

-- Part a:
-- a) Total units sold per product, highest first
SELECT
    product_id,
    SUM(quantity) AS total_units_sold
FROM sales.order_items
GROUP BY product_id
ORDER BY total_units_sold DESC;

-- Part b:
-- b) Number of customers in each state, highest first
SELECT
    state,
    COUNT(*) AS customer_count
FROM sales.customers
GROUP BY state
ORDER BY customer_count DESC;

-- Part c:
-- c) Number of orders per staff_id and order_status combination
SELECT
    staff_id,
    order_status,
    COUNT(*) AS order_count
FROM sales.orders
GROUP BY staff_id, order_status
ORDER BY staff_id, order_status;

-- ============================================================
--  Question 4 — GROUP BY with Joins
--  a) Show category_name and the average list_price of its
--     products (rounded to 2 decimals). Join products and
--     categories.
--  b) Show brand_name and the number of products in each brand,
--     sorted by the product count descending.
--  c) For every customer, show customer_id, first_name,
--     last_name, order_count and total_spent.
--     total_spent = SUM(quantity * list_price * (1 - discount))
--     Hint: use COUNT(DISTINCT order_id) so orders are not
--     counted once per item.
-- ============================================================

-- Part a:
-- a) Average list_price per category (rounded to 2 decimals)
SELECT
    c.category_name,
    ROUND(AVG(p.list_price), 2) AS avg_list_price
FROM production.products   AS p
JOIN production.categories AS c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY avg_list_price DESC;

-- Part b:
-- b) Number of products per brand, highest first
SELECT
    b.brand_name,
    COUNT(p.product_id) AS product_count
FROM production.products AS p
JOIN production.brands    AS b
    ON p.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY product_count DESC;

-- Part c:
-- c) Per customer: order count and total spent
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
FROM sales.customers   AS c
JOIN sales.orders      AS o  ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON o.order_id    = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- ============================================================
--  Question 5 — HAVING
--  a) List the model_year values that have more than 50
--     products, with the product count.
--  b) List the customers who have placed 2 or more orders
--     (customer_id and order_count).
--  c) List the product_ids that have sold more than 100 units
--     in total.
--  d) In a comment, explain why part (a) cannot be written
--     with WHERE alone.
-- ============================================================

-- Part a:
-- a) model_year values with more than 50 products
SELECT
    model_year,
    COUNT(*) AS product_count
FROM production.products
GROUP BY model_year
HAVING COUNT(*) > 50
ORDER BY model_year;

-- Part b:
-- b) Customers with 2 or more orders
SELECT
    customer_id,
    COUNT(*) AS order_count
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY order_count DESC;

-- Part c:
-- c) Product_ids that have sold more than 100 units in total
SELECT
    product_id,
    SUM(quantity) AS total_units_sold
FROM sales.order_items
GROUP BY product_id
HAVING SUM(quantity) > 100
ORDER BY total_units_sold DESC;

-- Part d (answer as a comment):
-- d) Why (a) cannot be written with WHERE alone:
--    WHERE filters individual rows BEFORE grouping happens, so at that
--    point no group exists yet and COUNT(*) per model_year has not been
--    calculated. A condition like WHERE COUNT(*) > 50 is invalid because
--    aggregate functions are not allowed in WHERE. The product count only
--    exists after GROUP BY has formed the groups, so the filter on it must
--    go in HAVING, which is evaluated after grouping and can use aggregates.



-- ============================================================
--  Question 6 — WHERE + GROUP BY + HAVING Together
--  Using only orders placed in the year 2017, find the stores
--  (store_id) whose total revenue is above 100000.
--  Show store_id and total_revenue, highest first.
--  Hint: WHERE filters rows before grouping, HAVING filters
--  groups after grouping.
-- ============================================================

SELECT
    o.store_id,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM sales.orders      AS o
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_date >= '2017-01-01'
  AND o.order_date <  '2018-01-01'
GROUP BY o.store_id
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 100000
ORDER BY total_revenue DESC;

-- ============================================================
--  Question 7 — Subquery in WHERE (IN)
--  a) Return all orders placed by customers who live in
--     'New York'. Use a subquery on sales.customers.
--  b) Return the product_id and product_name of all products
--     that belong to the categories 'Electric Bikes' or
--     'Cruisers Bicycles'. Use a subquery on categories.
--  c) Return the customers (first_name, last_name, city) who
--     have placed at least one order. Use IN with a subquery.
-- ============================================================

-- Part a:
-- a) All orders placed by customers who live in 'New York'
--    (here 'New York' is the city; use state = 'NY' if you meant the state)
SELECT *
FROM sales.orders
WHERE customer_id IN (
    SELECT customer_id
    FROM sales.customers
    WHERE city = 'New York'
);

-- Part b:
-- b) Products in the categories 'Electric Bikes' or 'Cruisers Bicycles'
SELECT
    product_id,
    product_name
FROM production.products
WHERE category_id IN (
    SELECT category_id
    FROM production.categories
    WHERE category_name IN ('Electric Bikes', 'Cruisers Bicycles')
);


-- Part c:
-- c) Customers who have placed at least one order
SELECT
    first_name,
    last_name,
    city
FROM sales.customers
WHERE customer_id IN (
    SELECT customer_id
    FROM sales.orders
);

-- ============================================================
--  Question 8 — Subquery in WHERE (Scalar & NOT IN)
--  a) Return all products priced ABOVE the overall average
--     list_price. Do not hardcode the average.
--  b) Return all products priced BELOW the overall average
--     list_price, and write a second query that counts how
--     many such products there are.
--  c) Return the customers who have NEVER placed an order,
--     using NOT IN.
--  d) Return the products that have never been ordered
--     (not present in sales.order_items).
--  Hint for c and d: filter out NULLs inside the subquery so
--  NOT IN works correctly.
-- ============================================================

-- Part a:
-- a) Products priced ABOVE the overall average list_price
SELECT
    product_id,
    product_name,
    list_price
FROM production.products
WHERE list_price > (
    SELECT AVG(list_price)
    FROM production.products
)
ORDER BY list_price DESC;

-- Part b:
-- b) Products priced BELOW the overall average list_price
SELECT
    product_id,
    product_name,
    list_price
FROM production.products
WHERE list_price < (
    SELECT AVG(list_price)
    FROM production.products
)
ORDER BY list_price;
--    Count of products priced below the average
SELECT COUNT(*) AS below_avg_count
FROM production.products
WHERE list_price < (
    SELECT AVG(list_price)
    FROM production.products
);

-- Part c:
-- c) Customers who have NEVER placed an order (NOT IN)
SELECT
    customer_id,
    first_name,
    last_name
FROM sales.customers
WHERE customer_id NOT IN (
    SELECT customer_id
    FROM sales.orders
    WHERE customer_id IS NOT NULL
);

-- Part d:

-- d) Products that have never been ordered (NOT IN)
SELECT
    product_id,
    product_name
FROM production.products
WHERE product_id NOT IN (
    SELECT product_id
    FROM sales.order_items
    WHERE product_id IS NOT NULL
);


-- ============================================================
--  Question 9 — Subquery in FROM (Derived Table)
--  a) First find the number of orders handled by each staff
--     member. Then, using that result as a derived table,
--     calculate the average, minimum and maximum order count
--     per staff member.
--  b) Using a derived table of total_spent per customer,
--     return the average total_spent across all customers.
--  Remember: a derived table needs an alias.
-- ============================================================

-- Part a:
-- a) Average, min and max number of orders per staff member
--    Inner query: order count per staff member
--    Outer query: aggregates over those counts
SELECT
    AVG(order_count) AS avg_orders_per_staff,
    MIN(order_count) AS min_orders_per_staff,
    MAX(order_count) AS max_orders_per_staff
FROM (
    SELECT
        staff_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY staff_id
) AS staff_orders;

-- Part b:
-- b) Average total_spent across all customers
--    Inner query: total_spent per customer
--    Outer query: average of those totals
SELECT
    AVG(total_spent) AS avg_total_spent_per_customer
FROM (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
    FROM sales.orders      AS o
    JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
) AS customer_totals;

-- ============================================================
--  Question 10 — Subquery in SELECT
--  a) For each product (product_id, product_name, list_price),
--     show the total quantity sold as a column named
--     units_sold, using a correlated subquery on
--     sales.order_items.
--  b) For each order (order_id, order_date), show the number of
--     items in that order as item_count and the highest
--     list_price in that order as max_item_price.
--  c) Show the difference between each product's list_price and
--     the overall average list_price as price_difference.
-- ============================================================

-- Part a:
-- a) Total quantity sold per product (correlated subquery)
SELECT
    p.product_id,
    p.product_name,
    p.list_price,
    (
        SELECT COALESCE(SUM(oi.quantity), 0)
        FROM sales.order_items AS oi
        WHERE oi.product_id = p.product_id
    ) AS units_sold
FROM production.products AS p
ORDER BY units_sold DESC;

-- Part b:
-- b) Item count and highest list_price per order
--    (two correlated subqueries, one per computed column)
SELECT
    o.order_id,
    o.order_date,
    (
        SELECT COUNT(*)
        FROM sales.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS item_count,
    (
        SELECT MAX(oi.list_price)
        FROM sales.order_items AS oi
        WHERE oi.order_id = o.order_id
    ) AS max_item_price
FROM sales.orders AS o
ORDER BY o.order_id;

-- Part c:

-- c) Difference between each product's price and the overall average
SELECT
    p.product_id,
    p.product_name,
    p.list_price,
    p.list_price - (
        SELECT AVG(list_price)
        FROM production.products
    ) AS price_difference
FROM production.products AS p
ORDER BY price_difference DESC;

-- ============================================================
--  Question 11 — Challenge
--  Find the customers whose total_spent is higher than the
--  average total_spent of all customers.
--  Show customer_id, first_name, last_name and total_spent,
--  highest first.
--  Hint: combine GROUP BY + HAVING with a scalar subquery
--  (or a derived table) that calculates the average.
-- ============================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
FROM sales.customers   AS c
JOIN sales.orders      AS o  ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON o.order_id    = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(oi2.quantity * oi2.list_price * (1 - oi2.discount)) AS customer_total
        FROM sales.orders      AS o2
        JOIN sales.order_items AS oi2
            ON o2.order_id = oi2.order_id
        GROUP BY o2.customer_id
    ) AS customer_totals
)
ORDER BY total_spent DESC;