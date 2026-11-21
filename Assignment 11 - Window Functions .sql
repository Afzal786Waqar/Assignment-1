
Select * from production.products;

--  Question 1 — Aggregate as a Window Function

--  a) Return product_name, list_price and the overall average
--     list_price of all products as a column named overall_avg
--     (use AVG with an empty OVER()).

SELECT
    product_name,
    list_price,
    AVG(list_price) OVER () AS overall_avg
FROM production.products;

--  b) Extend the query to add price_difference, i.e. each
--     product's list_price minus overall_avg.

--  Add price_difference = list_price - overall_avg
--    (a window function can't be referenced by its alias in the same
--     SELECT, so repeat the expression or wrap it in a subquery/CTE)

SELECT
    product_name,
    list_price,
    AVG(list_price) OVER ()              AS overall_avg,
    list_price - AVG(list_price) OVER () AS price_difference
FROM production.products;

-- Equivalent using a CTE (avoids repeating the window expression):

WITH priced AS (
    SELECT
        product_name,
        list_price,
        AVG(list_price) OVER () AS overall_avg
    FROM production.products
)
SELECT
    product_name,
    list_price,
    overall_avg,
    list_price - overall_avg AS price_difference
FROM priced;

-- c) Window function vs. GROUP BY with AVG
--
--    GROUP BY AVG(list_price) collapses the rows: you get one row per
--    group (or a single row for the whole table if there is no GROUP BY),
--    and the individual product rows are lost. You can only select the
--    grouped columns and aggregates, so product_name and list_price
--    could not appear alongside the average without being grouped or
--    aggregated themselves.
--
--    AVG(list_price) OVER () computes the same aggregate but keeps every
--    original row. The average is calculated across the window (here the
--    entire result set, since OVER() is empty) and attached to each row
--    as an extra column. That is what makes it possible to compare each
--    row to the aggregate, as in price_difference, in a single query
--    without a self-join or subquery.
--
--    With GROUP BY you would need something like:
--      SELECT p.product_name, p.list_price, a.avg_price
--      FROM products p
--      CROSS JOIN (SELECT AVG(list_price) AS avg_price FROM products) a;
--    to get the same result.

--  Question 2 — PARTITION BY

--  a) Return product_name, category_id, list_price and the
--     average list_price of that product's category as
--     category_avg_price (rounded to 2 decimals).

--  Category average price on every product row

SELECT
    product_name,
    category_id,
    list_price,
    ROUND(AVG(list_price) OVER (PARTITION BY category_id), 2) AS category_avg_price
FROM production.products;

--  b) Return product_name, brand_id, list_price and the
--     MAX list_price within the brand as brand_max_price.

--  Highest list_price within each product's brand

SELECT
    product_name,
    brand_id,
    list_price,
    MAX(list_price) OVER (PARTITION BY brand_id) AS brand_max_price
FROM production.products;

--  c) Return order_id, item_id, product_id, quantity and the
--     total quantity of the whole order as order_total_qty
--     (from sales.order_items).

--  Total quantity of the whole order, repeated on each line item

SELECT
    order_id,
    item_id,
    product_id,
    quantity,
    SUM(quantity) OVER (PARTITION BY order_id) AS order_total_qty
FROM sales.order_items;

--  Question 3 — ROW_NUMBER

--  a) Assign a sequential number to every customer ordered by
--     last_name, then first_name. Show row_num, first_name,
--     last_name and city.

--  Sequential number across all customers, ordered by last_name, then first_name

SELECT
    ROW_NUMBER() OVER (ORDER BY last_name, first_name) AS row_num,
    first_name,
    last_name,
    city
FROM sales.customers;

--  b) Restart the numbering for each city (PARTITION BY city),
--     ordered by first_name.

--  Restart numbering within each city, ordered by first_name

SELECT
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY first_name) AS row_num,
    first_name,
    last_name,
    city
FROM sales.customers;

--  c) For each category_id, number the products from the most
--     expensive to the cheapest. Show category_id,
--     product_name, list_price and row_num.

--  Number products within each category from most to least expensive

SELECT
    category_id,
    product_name,
    list_price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS row_num
FROM production.products;

--  Question 4 — Top N per Group

--  a) Return the 3 most expensive products of EACH category.
--     Show category_id, product_name, list_price.
--     Hint: use ROW_NUMBER inside a CTE or derived table, then
--     filter on it in the outer query (window functions cannot
--     be used directly in WHERE).

--  Top 3 most expensive products in each category

WITH ranked AS (
    SELECT
        category_id,
        product_name,
        list_price,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY list_price DESC, product_name
        ) AS rn
    FROM production.products
)
SELECT
    category_id,
    product_name,
    list_price
FROM ranked
WHERE rn <= 3
ORDER BY category_id, list_price DESC;

--  b) Return the most recent order of EACH customer.
--     Show customer_id, order_id and order_date.

--  Most recent order of each customer

WITH ranked_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC, order_id DESC
        ) AS rn
    FROM sales.orders
)
SELECT
    customer_id,
    order_id,
    order_date
FROM ranked_orders
WHERE rn = 1
ORDER BY customer_id;

--  Question 5 — RANK vs DENSE_RANK

--  a) Rank all products by list_price (highest first) using
--     both RANK() and DENSE_RANK() in the same query. Show
--     product_name, list_price, price_rank and dense_price_rank.

--  Rank all products by list_price, highest first

SELECT
    product_name,
    list_price,
    RANK()       OVER (ORDER BY list_price DESC) AS price_rank,
    DENSE_RANK() OVER (ORDER BY list_price DESC) AS dense_price_rank
FROM production.products
ORDER BY list_price DESC, product_name;

--  b) Do the same ranking, but restart it inside each brand_id
--     (PARTITION BY brand_id).

--  Same ranking, restarted inside each brand

SELECT
    brand_id,
    product_name,
    list_price,
    RANK()       OVER (PARTITION BY brand_id ORDER BY list_price DESC) AS price_rank,
    DENSE_RANK() OVER (PARTITION BY brand_id ORDER BY list_price DESC) AS dense_price_rank
FROM production.products
ORDER BY brand_id, list_price DESC, product_name;

--  c) Explain in a comment what happens to the numbers after
--     a tie with RANK and with DENSE_RANK. Point to a row from
--     your own result as an example.


--  (answer as a comment):
--  What happens after a tie
--
--    Both functions give tied rows the SAME number. The difference is
--    what number comes next:
--
--    RANK() leaves a gap. If two rows tie for position 3, both get 3,
--    and the next row gets 5 (position 4 is "used up" by the tie),
--    so the sequence looks like 1, 2, 3, 3, 5.
--
--    DENSE_RANK() leaves no gap. After two rows tie at 3, the next
--    distinct value gets 4, so the sequence looks like 1, 2, 3, 3, 4.
--
--    Example from the result of (a) in BikeStores: the most expensive
--    product is the Trek Domane SLR 9 Disc - 2018 at 11999.99, which is
--    rank 1 under both functions. Several products share the next prices
--    further down the list; whenever two or more rows share a price,
--    they show the same price_rank AND the same dense_price_rank, but
--    the row right after the tie shows a larger price_rank than
--    dense_price_rank (e.g. RANK = 7 vs DENSE_RANK = 6 after a two-way
--    tie at 5/4). From that point on, price_rank stays ahead of
--    dense_price_rank by the number of "extra" tied rows.
--    Run the query and pick the first pair of equal list_price values
--    in your own output to see this concretely.

--  Question 6 — Ranking with Aggregates

--  Calculate the total revenue of each customer
--  (SUM(quantity * list_price * (1 - discount))) and rank the
--  customers from the highest spender to the lowest using
--  DENSE_RANK. Show customer_id, total_spent and spend_rank.
--  Hint: aggregate in a CTE first, then apply the window
--  function in the next step.

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    ROUND(total_spent, 2) AS total_spent,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM customer_revenue
ORDER BY spend_rank, customer_id;

--  Question 7 — LAG

--  For the brand 'Electra' in the year 2018, calculate the net
--  sales per month (SUM(quantity * list_price * (1 - discount))).
--  Then use LAG to show:
--    month, net_sales, previous_month_sales and the percentage
--    change versus the previous month.
--  Hint: a CTE for the monthly sales, a second step for LAG.

WITH monthly_sales AS (
    SELECT
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS net_sales
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    JOIN production.products p
        ON p.product_id = oi.product_id
    JOIN production.brands b
        ON b.brand_id = p.brand_id
    WHERE b.brand_name = 'Electra'
      AND o.order_date >= '2018-01-01'
      AND o.order_date <  '2019-01-01'
    GROUP BY MONTH(o.order_date)
),
with_prev AS (
    SELECT
        month,
        net_sales,
        LAG(net_sales) OVER (ORDER BY month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    month,
    ROUND(net_sales, 2)            AS net_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        (net_sales - previous_month_sales) * 100.0
        / NULLIF(previous_month_sales, 0),
        2
    ) AS pct_change
FROM with_prev
ORDER BY month;

--  Question 8 — LEAD

--  a) For each customer, show order_id, order_date and the
--     order_date of their NEXT order as next_order_date.

--  Next order date for each customer

SELECT
    customer_id,
    order_id,
    order_date,
    LEAD(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS next_order_date
FROM sales.orders
ORDER BY customer_id, order_date, order_id;

--  b) Add a column days_to_next_order using DATEDIFF.
--     Orders with no next order should show NULL.

--  Days between an order and the customer's next order

SELECT
    customer_id,
    order_id,
    order_date,
    LEAD(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS next_order_date,
    DATEDIFF(
        DAY,
        order_date,
        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        )
    ) AS days_to_next_order
FROM sales.orders
ORDER BY customer_id, order_date, order_id;

--  c) Repeat part (a) but use the third argument of LEAD to
--     replace NULL with '2099-12-31'.

--  Replace NULL with '2099-12-31' using LEAD's third argument

SELECT
    customer_id,
    order_id,
    order_date,
    LEAD(order_date, 1, '2099-12-31') OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS next_order_date
FROM sales.orders
ORDER BY customer_id, order_date, order_id;

--  Question 9 — Running Total

--  a) Show each order's order_id, order_date and its total
--     order value, together with a running total of the order
--     value ordered by order_date, order_id.
--     Hint: SUM(...) OVER (ORDER BY order_date, order_id).

--  Order value per order, plus a running total across all orders

WITH order_totals AS (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS order_value
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.order_date
)
SELECT
    order_id,
    order_date,
    ROUND(order_value, 2) AS order_value,
    ROUND(
        SUM(order_value) OVER (
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_total
FROM order_totals
ORDER BY order_date, order_id;

--  b) Restart the running total for every store_id
--     (PARTITION BY store_id).

--  Restart the running total for every store

WITH order_totals AS (
    SELECT
        o.store_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS order_value
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.store_id, o.order_id, o.order_date
)
SELECT
    store_id,
    order_id,
    order_date,
    ROUND(order_value, 2) AS order_value,
    ROUND(
        SUM(order_value) OVER (
            PARTITION BY store_id
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_total
FROM order_totals
ORDER BY store_id, order_date, order_id;

--  Question 10 — Challenge

--  Build a report for the year 2017 with one row per month:
--    month, total_sales, previous_month_sales,
--    sales_change (in %), and sales_rank
--    (rank of the month by total_sales, highest first).
--  Use a CTE for the monthly totals and combine LAG with
--  RANK in the final SELECT.

WITH monthly_totals AS (
    SELECT
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_date >= '2017-01-01'
      AND o.order_date <  '2018-01-01'
    GROUP BY MONTH(o.order_date)
)
SELECT
    month,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(LAG(total_sales) OVER (ORDER BY month), 2) AS previous_month_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(total_sales) OVER (ORDER BY month), 0),
        2
    ) AS sales_change,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM monthly_totals
ORDER BY month;

