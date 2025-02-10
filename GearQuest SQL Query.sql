-----------------------------------------------------------------------------------------
-- 1. YEARLY SALES & ORDER VALUES WITH YEAR-OVER-YEAR CHANGES
-----------------------------------------------------------------------------------------
WITH CTE AS(
    SELECT 
        YEAR(purchase_ts) AS Year,                  -- Extract the year from the purchase timestamp
        SUM(usd_price) AS Total_Revenue,            -- Total revenue for the year
        ROUND(AVG(usd_price),0) AS AOV,             -- Average order value, rounded
        CAST(COUNT(id) AS FLOAT) AS Order_Count,    -- Number of orders in that year

        -- Window functions to capture the previous year's metrics for YoY comparisons
        LAG(SUM(usd_price),1) OVER(ORDER BY YEAR(purchase_ts)) AS Prev_Rev,
        LAG(ROUND(AVG(usd_price),0),1) OVER(ORDER BY YEAR(purchase_ts)) AS Prev_AOV,
        LAG(CAST(COUNT(id) AS FLOAT),1) OVER(ORDER BY YEAR(purchase_ts)) AS Prev_Order
    FROM
        orders
    GROUP BY YEAR(purchase_ts)
)
SELECT
    Year,
    Total_Revenue,
    AOV,
    Order_Count,
    -- Calculate Year-over-Year % changes based on the LAG values
    (Total_Revenue - Prev_Rev) / (Prev_Rev) AS Rev_Change,
    (AOV - Prev_AOV) / (Prev_AOV) AS AOV_Change,
    (Order_Count - Prev_Order) / (Prev_Order) AS Order_Change
FROM
    CTE
WHERE Year IN (2021,2022,2023,2024);


-----------------------------------------------------------------------------------------
-- 2. MONTHLY SALES & ORDERS TREND (PIVOTED BY YEAR)
-----------------------------------------------------------------------------------------
WITH RevenuePivot AS ( 
    SELECT * 
    FROM (
        SELECT 
            MONTH(purchase_ts) AS Month,       -- Extract month from purchase timestamp
            YEAR(purchase_ts) AS Year,         -- Extract year from purchase timestamp
            SUM(usd_price) AS Total_Revenue    -- Monthly total revenue
        FROM orders
        GROUP BY YEAR(purchase_ts), MONTH(purchase_ts)
    ) AS SourceTable
    PIVOT (
        SUM(Total_Revenue) 
        FOR Year IN ([2021], [2022], [2023], [2024]) -- Pivot so each year becomes its own column
    ) AS RevPivot
),
OrdersPivot AS (
    SELECT * 
    FROM (
        SELECT 
            MONTH(purchase_ts) AS Month,   -- Extract month
            YEAR(purchase_ts) AS Year,     -- Extract year
            COUNT(id) AS Total_Orders      -- Monthly total orders
        FROM orders
        GROUP BY YEAR(purchase_ts), MONTH(purchase_ts)
    ) AS SourceTable
    PIVOT (
        SUM(Total_Orders) 
        FOR Year IN ([2021], [2022], [2023], [2024]) -- Pivot to show orders per year as columns
    ) AS OrdPivot
)
SELECT 
    r.Month, 
    r.[2021] AS Revenue_2021, 
    r.[2022] AS Revenue_2022, 
    r.[2023] AS Revenue_2023, 
    r.[2024] AS Revenue_2024,
    o.[2021] AS Orders_2021, 
    o.[2022] AS Orders_2022, 
    o.[2023] AS Orders_2023, 
    o.[2024] AS Orders_2024
FROM RevenuePivot AS r
JOIN OrdersPivot AS o 
    ON r.Month = o.Month;   -- Match monthly records from both pivots


-----------------------------------------------------------------------------------------
-- 3. MONTH-OVER-MONTH GROWTH FOR SALES, ORDERS, AND AOV
-----------------------------------------------------------------------------------------
WITH MonthlyData AS (
    SELECT 
        YEAR(purchase_ts) AS Year,                 -- Extract year
        MONTH(purchase_ts) AS Month,               -- Extract month
        SUM(usd_price) AS Total_Revenue,           -- Monthly total revenue
        COUNT(id) AS Total_Orders,                 -- Monthly total orders
        CASE 
            WHEN COUNT(id) > 0 THEN SUM(usd_price) * 1.0 / COUNT(id)
            ELSE 0 
        END AS Average_Order_Value                 -- Average order value for the month
    FROM 
        orders
    GROUP BY 
        YEAR(purchase_ts),
        MONTH(purchase_ts)
),
ChangeData AS (
    SELECT 
        Year,
        Month,
        Total_Revenue,
        Total_Orders,
        Average_Order_Value,
        -- Capture previous month metrics for calculating month-over-month changes
        LAG(Total_Revenue) OVER (ORDER BY Year, Month) AS Prev_Total_Revenue,
        LAG(Total_Orders) OVER (ORDER BY Year, Month) AS Prev_Total_Orders,
        LAG(Average_Order_Value) OVER (ORDER BY Year, Month) AS Prev_AOV
    FROM 
        MonthlyData
)
SELECT 
    Year,
    Month,
    Total_Revenue,
    Total_Orders,
    Average_Order_Value,
    -- Month-over-month percentage changes, NULL if no previous month in context
    CASE 
        WHEN Prev_Total_Revenue IS NOT NULL 
             THEN (Total_Revenue - Prev_Total_Revenue) * 1.0 / Prev_Total_Revenue
        ELSE NULL 
    END AS Revenue_Change,
    CASE 
        WHEN Prev_Total_Orders IS NOT NULL 
             THEN (Total_Orders - Prev_Total_Orders) * 1.0 / Prev_Total_Orders
        ELSE NULL 
    END AS Orders_Change,
    CASE 
        WHEN Prev_AOV IS NOT NULL 
             THEN (Average_Order_Value - Prev_AOV) * 1.0 / Prev_AOV
        ELSE NULL 
    END AS AOV_Change
FROM 
    ChangeData
ORDER BY 
    Year ASC,
    Month ASC;


-----------------------------------------------------------------------------------------
-- 4. REGIONAL SALES & ORDERS ANALYSIS BY YEAR
-----------------------------------------------------------------------------------------
WITH CTE AS (
    SELECT
        YEAR(o.purchase_ts) AS Year,   -- Extract year
        (SELECT g.region
         FROM geo_lookup AS g
         WHERE g.country = c.country_code) AS Region,  -- Region lookup based on country_code
        c.country_code,
        o1.Overall_Sales,
        o1.Overall_Orders,
        SUM(o.usd_price) AS Regional_Sales,           -- Sales contributed by this region
        CAST(COUNT(o.id) AS FLOAT) AS Regional_Orders -- Number of orders from this region
    FROM
        orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.id
    LEFT JOIN (
        SELECT
            YEAR(purchase_ts) AS Sales_Year,
            SUM(usd_price) AS Overall_Sales,
            CAST(COUNT(id) AS FLOAT) AS Overall_Orders
        FROM orders
        GROUP BY YEAR(purchase_ts)
    ) AS o1
        ON YEAR(o.purchase_ts) = o1.Sales_Year
    WHERE
        YEAR(o.purchase_ts) IN (2021,2022,2023,2024)
    GROUP BY
        YEAR(o.purchase_ts), 
        c.country_code, 
        o1.Overall_Sales,  
        o1.Overall_Orders
),
change AS (
    SELECT 
        Year,
        Region,
        country_code,
        Regional_Sales,
        ROUND((Regional_Sales/Overall_Sales),5) AS percentage_of_total_sales,
        LAG(Regional_Sales,1) OVER(PARTITION BY Region, country_code ORDER BY Year) AS Prev_Rev,
        Regional_Orders,
        LAG(Regional_Orders,1) OVER(PARTITION BY Region, country_code ORDER BY Year) Prev_Order,
        ROUND((Regional_Orders/Overall_Orders),5) AS percentage_of_total_orders
    FROM
        CTE
)
SELECT
    Year,
    Region,
    country_code,
    Regional_Sales,
    percentage_of_total_sales,
    percentage_of_total_orders,
    Regional_Orders,
    -- Calculate year-over-year change in revenue and orders for each region & country
    ROUND(((Regional_Sales-Prev_Rev)/(Prev_Rev)),5) AS Rev_Change,
    ROUND((Regional_Orders - Prev_Order)/(Prev_Order),5) AS Order_Change
FROM
    change
ORDER BY Year;


-----------------------------------------------------------------------------------------
-- 5. TOP PRODUCT CATEGORIES & NAMES BY SALES AND ORDERS
-----------------------------------------------------------------------------------------
WITH CTE AS (
    SELECT 
        YEAR(o.purchase_ts) AS year,          -- Extract the year
        p.category,                           -- Product category
        p.product_name,                       -- Product name
        SUM(o.usd_price) AS Total_Rev,        -- Total revenue generated by that product
        CAST(COUNT(o.id) AS FLOAT) AS Total_Order -- Total orders for that product
    FROM products AS p
    INNER JOIN orders AS o
        ON p.product_id = o.product_id
    GROUP BY
        YEAR(o.purchase_ts),
        p.category,
        p.product_name
),
overall AS (
    SELECT
        YEAR(purchase_ts) AS y1,
        SUM(usd_price) AS overall_sum, 
        CAST(COUNT(id) AS FLOAT) AS overall_order
    FROM orders
    GROUP BY YEAR(purchase_ts)
)
SELECT 
    c.year,
    c.category,
    c.product_name,
    c.Total_Rev,
    -- Percentage of total annual sales
    ROUND((c.Total_Rev/o.overall_sum),5) AS percent_of_total_sales,
    c.Total_Order,
    -- Percentage of total annual orders
    ROUND((c.Total_Order/o.overall_order),5) AS percent_of_total_orders
FROM
    CTE AS c
INNER JOIN
    overall AS o
    ON c.year = o.y1
WHERE 
    YEAR IN (2021,2022,2023,2024)
ORDER BY year;


-----------------------------------------------------------------------------------------
-- 6. AVERAGE DELIVERY TIME BY REGION (PURCHASE_TO_DELIVERY)
-----------------------------------------------------------------------------------------
WITH CTE AS (
    SELECT 
        o1.id AS order_id,
        o1.customer_id AS customer_id,
        r.region,
        r.country,
        o1.purchase_ts,
        o1.ship_ts,
        o1.delivery_ts
    FROM
        (SELECT
            o.id,
            o.customer_id,
            os.purchase_ts,
            os.ship_ts,
            os.delivery_ts
        FROM
            orders AS o
        INNER JOIN
            order_status AS os
            ON o.id = os.order_id
        ) AS o1
    INNER JOIN (
        SELECT
            c.id,
            g.region,
            g.country
        FROM
            customers AS c
        INNER JOIN 
            geo_lookup AS g
            ON c.country_code = g.country
    ) AS r
    ON o1.customer_id = r.id
),
deliveries AS (
    SELECT
        YEAR(purchase_ts) AS Year,
        region,
        country,
        MAX(DATEDIFF(DAY,purchase_ts,delivery_ts)) AS Max_Delivery_Time, -- Longest delivery time
        MIN(DATEDIFF(DAY,purchase_ts,delivery_ts)) AS Min_Delivery_Time, -- Shortest delivery time
        AVG(DATEDIFF(DAY,purchase_ts,delivery_ts)) AS Avg_Delivery_Time, -- Average delivery time
        CAST(COUNT(order_id) AS FLOAT) AS Total_Orders,
        -- Early deliveries = less than 5 days
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,purchase_ts,delivery_ts) < 5 THEN 1 END) AS FLOAT) AS Early_Deliveries,
        -- On-time deliveries = 5 to 7 days
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,purchase_ts,delivery_ts) >= 5 
                        AND DATEDIFF(DAY,purchase_ts,delivery_ts) <=7 THEN 1 END) AS FLOAT) AS Within_5_to_7_days,
        -- Delayed deliveries = more than 7 days
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,purchase_ts,delivery_ts) > 7 THEN 1 END) AS FLOAT) AS More_than_7_days
    FROM 
        CTE
    GROUP BY 
        YEAR(purchase_ts), 
        region, 
        country
)
SELECT 
    Year,
    region,
    country,
    Max_Delivery_Time,
    Min_Delivery_Time,
    Avg_Delivery_Time,
    Total_Orders,
    Early_Deliveries,
    ROUND((Early_Deliveries/Total_Orders),5) AS Percentage_of_Early_Deliveries,
    Within_5_to_7_days,
    ROUND((Within_5_to_7_days/Total_Orders),5) AS Percentage_of_Within5_to_7D_Deliveries,
    More_than_7_days,
    ROUND((More_than_7_days/Total_Orders),5) AS Percentage_of_More_Than_7d_Deliveries
FROM
    deliveries
WHERE 
    Year IN (2021,2022,2023,2024)
ORDER BY Year;


-----------------------------------------------------------------------------------------
-- 7. OPERATIONAL STAGE TIMINGS: PURCHASE-TO-SHIP AND SHIP-TO-DELIVERY
-----------------------------------------------------------------------------------------
WITH CTE AS(
    SELECT 
        o1.id AS order_id,
        o1.customer_id AS customer_id,
        r.region,
        r.country,
        o1.purchase_ts,
        o1.ship_ts,
        o1.delivery_ts
    FROM
        (SELECT
            o.id,
            o.customer_id,
            os.purchase_ts,
            os.ship_ts,
            os.delivery_ts
        FROM
            orders AS o
        INNER JOIN
            order_status AS os
            ON o.id = os.order_id
        ) AS o1
    INNER JOIN (
        SELECT
            c.id,
            g.region,
            g.country
        FROM
            customers AS c
        INNER JOIN 
            geo_lookup AS g
            ON c.country_code = g.country
    ) AS r
    ON o1.customer_id = r.id
),
operational_time AS( 
    SELECT
        YEAR(purchase_ts) AS Year,
        region,
        country,
        CAST(COUNT(order_id) AS FLOAT) AS total_order,

        -- Processing times (purchase_ts -> ship_ts)
        MAX(DATEDIFF(DAY,purchase_ts,ship_ts)) AS Max_Processing_Time,
        MIN(DATEDIFF(DAY,purchase_ts,ship_ts)) AS Min_Processing_Time,
        AVG(DATEDIFF(DAY,purchase_ts,ship_ts)) AS Avg_Processing_Time,
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,purchase_ts,ship_ts) <= 2 THEN 1 END) AS FLOAT) AS orders_processed_in_2d,
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,purchase_ts,ship_ts) >  2 THEN 1 END) AS FLOAT) AS orders_processed_in_more_than2d,

        -- Transit times (ship_ts -> delivery_ts)
        MAX(DATEDIFF(DAY,ship_ts,delivery_ts)) AS Max_Transit_Time,
        MIN(DATEDIFF(DAY,ship_ts,delivery_ts)) AS Min_Transit_Time,
        AVG(DATEDIFF(DAY,ship_ts,delivery_ts)) AS Avg_Transit_Time,
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,ship_ts,delivery_ts) <= 5 THEN 1 END) AS FLOAT) AS orders_transitted_in_5d,
        CAST(COUNT(CASE WHEN DATEDIFF(DAY,ship_ts, delivery_ts) >  5 THEN 1 END) AS FLOAT) AS orders_transitted_in_more_than5d
    FROM
        CTE
    GROUP BY 
        YEAR(purchase_ts), 
        region, 
        country
)
SELECT
    Year,
    region,
    country,
    total_order,
    Max_Processing_Time,
    Min_Processing_Time,
    Avg_Processing_Time,
    orders_processed_in_2d,
    ROUND((orders_processed_in_2d/total_order),5) AS percent_of_orders_processed_in_2D,
    orders_processed_in_more_than2d,
    ROUND((orders_processed_in_more_than2d/total_order),5) AS percent_of_orders_processed_in_morethan_2d,
    Max_Transit_Time,
    Min_Transit_Time,
    Avg_Transit_Time,
    orders_transitted_in_5d,
    ROUND((orders_transitted_in_5d/total_order),5) AS percent_of_orders_transitted_in_5d,
    orders_transitted_in_more_than5d,
    ROUND((orders_transitted_in_more_than5d/total_order),5) AS percent_of_orders_take_morethan_5d_transit
FROM
    operational_time
ORDER BY
    Year;


-----------------------------------------------------------------------------------------
-- 8. PURCHASE PLATFORM EFFICIENCY (DELIVERY TIME ANALYSIS)
-----------------------------------------------------------------------------------------
SELECT 
    YEAR(os.purchase_ts) AS Year,       -- Year from purchase timestamp
    o.purchase_platform,                -- Purchase platform (e.g., Website, App)
    MIN(DATEDIFF(DAY, os.purchase_ts, os.delivery_ts)) AS Shortest_Delivery_Time,
    AVG(DATEDIFF(DAY, os.purchase_ts, os.delivery_ts)) AS Avg_Delivery_Time,

    -- Distribution of delivery times
    COUNT(CASE WHEN DATEDIFF(DAY, os.purchase_ts, os.delivery_ts) BETWEEN 5 AND 7 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_5_7_Days_Delivery,
    COUNT(CASE WHEN DATEDIFF(DAY, os.purchase_ts, os.delivery_ts) > 7 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_More_Than_7_Days_Delivery,
    COUNT(CASE WHEN DATEDIFF(DAY, os.purchase_ts, os.delivery_ts) < 5 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_Less_Than_5_Days_Delivery,

    -- Distribution of processing times (purchase -> ship)
    AVG(DATEDIFF(DAY, o.purchase_ts, os.ship_ts)) AS Avg_Processing_Time,
    MIN(DATEDIFF(DAY, o.purchase_ts, os.ship_ts)) AS Min_Processing_Time,
    COUNT(CASE WHEN DATEDIFF(DAY, o.purchase_ts, os.ship_ts) < 2 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_Less_Than_2_Days_Processing,
    COUNT(CASE WHEN DATEDIFF(DAY, o.purchase_ts, os.ship_ts) BETWEEN 2 AND 5 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_2_5_Days_Processing,
    COUNT(CASE WHEN DATEDIFF(DAY, o.purchase_ts, os.ship_ts) > 5 THEN 1 END) 
        * 1.0 / COUNT(o.id) AS Pct_More_Than_5_Days_Processing
FROM
    orders AS o
INNER JOIN
    order_status AS os
    ON o.id = os.order_id
GROUP BY
    YEAR(os.purchase_ts),
    o.purchase_platform
ORDER BY 
    Year;


-----------------------------------------------------------------------------------------
-- 9. MARKETING CHANNEL CONTRIBUTIONS: REVENUE, ORDERS, AND AOV
-----------------------------------------------------------------------------------------
WITH mkt_channel AS
(
    SELECT 
        YEAR(o.purchase_ts) AS Year,               -- Year of purchase
        c.marketing_channel AS Mkt_Channel,        -- Marketing channel (e.g., Email, Social, etc.)
        SUM(o.usd_price) AS Total_Revenue,         -- Total revenue from that channel
        ROUND(AVG(o.usd_price),0) AS AOV,          -- Average Order Value for that channel
        CAST(COUNT(o.id) AS FLOAT) AS Order_Count  -- Orders from that channel
    FROM
        orders AS o
    INNER JOIN
        customers AS c
    ON 
        o.customer_id = c.id
    WHERE
        YEAR(o.purchase_ts) IN (2021,2022,2023,2024)
    GROUP BY
        YEAR(o.purchase_ts),
        c.marketing_channel
),
overall AS (
    SELECT
        YEAR(purchase_ts) AS Year1,
        SUM(usd_price) AS Overall_Rev,
        ROUND(AVG(usd_price),0) AS Overall_AOV,
        CAST(COUNT(id) AS FLOAT) AS Overall_Order
    FROM orders
    GROUP BY YEAR(purchase_ts)
)
SELECT 
    Year,
    Mkt_Channel,
    Total_Revenue,
    -- % share of overall revenue by marketing channel
    ROUND((Total_Revenue/Overall_Rev),5) AS Pct_of_Total_Rev,
    Order_Count,
    -- % share of overall orders by marketing channel
    ROUND((Order_Count/Overall_Order),5) AS Pct_of_total_order
FROM
    mkt_channel AS mc
INNER JOIN
    overall AS ov
ON mc.Year = ov.Year1
ORDER BY 
    Year;


-----------------------------------------------------------------------------------------
-- 10. PURCHASE PLATFORM PERFORMANCE: REVENUE, AOV, AND ORDER COUNT
-----------------------------------------------------------------------------------------
WITH purchase_plat AS (
    SELECT
        YEAR(purchase_ts) AS Year,
        purchase_platform,            -- e.g. Website, Mobile App
        SUM(usd_price) AS Total_Rev,  -- Total revenue for that platform & year
        ROUND(AVG(usd_price),0) AS AOV,-- Average order value
        CAST(COUNT(id) AS FLOAT) AS Total_Order
    FROM
        orders
    GROUP BY 
        YEAR(purchase_ts),
        purchase_platform
),
overall AS(
    SELECT
        YEAR(purchase_ts) AS Year1,
        SUM(usd_price) AS Overall_Rev,
        ROUND(AVG(usd_price),0) AS Overall_AOV,
        CAST(COUNT(id) AS FLOAT) AS Overall_Order
    FROM
        orders
    GROUP BY
        YEAR(purchase_ts)
)
SELECT
    pp.Year,
    pp.purchase_platform,
    pp.Total_Rev,
    -- % share of overall revenue by platform
    ROUND((pp.Total_Rev/o.Overall_Rev),5) AS Pct_of_Total_Rev,
    pp.Total_Order,
    -- % share of overall orders by platform
    ROUND((pp.Total_Order/o.Overall_Order),5) AS Pct_of_Total_Order
FROM
    purchase_plat AS pp
INNER JOIN 
    overall AS o
ON
    pp.Year = o.Year1
WHERE
    Year IN (2021,2022,2023,2024)
ORDER BY
    Year;


-----------------------------------------------------------------------------------------
-- 11. REFUND RATE BY YEAR
-----------------------------------------------------------------------------------------
SELECT
    YEAR(purchase_ts) AS Year,                          -- Year from the purchase timestamp
    CAST(COUNT(order_id) AS FLOAT) AS Total_Order,      -- Total orders in that year
    CAST(COUNT(refund_ts) AS FLOAT) AS Total_Refunds,   -- Total refunds in that year
    ROUND(
        CAST(COUNT(refund_ts) AS FLOAT) / CAST(COUNT(order_id) AS FLOAT),
        5
    ) AS Refund_Rate                                     -- Refund rate = refunds / total orders
FROM
    order_status
WHERE
    YEAR(purchase_ts) IN (2021,2022,2023,2024)
GROUP BY 
    YEAR(purchase_ts)
ORDER BY 
    Year;


-----------------------------------------------------------------------------------------
-- 12. MOST FREQUENTLY RETURNED PRODUCTS
-----------------------------------------------------------------------------------------
WITH product_count AS (
    SELECT 
        YEAR(o.purchase_ts) AS year,           -- Year from purchase timestamp
        o.product_id,
        p.product_name,
        COUNT(o.id) AS total_orders            -- How many orders for that product in a year
    FROM
        orders AS o
    INNER JOIN products AS p
        ON o.product_id = p.product_id
    GROUP BY
        YEAR(o.purchase_ts),
        o.product_id,
        p.product_name
),
refunds AS (
    SELECT 
        YEAR(os.refund_ts) AS year,            -- Year from refund timestamp
        o.product_id,
        COUNT(os.refund_ts) AS total_refunds   -- How many times this product was refunded
    FROM 
        order_status AS os
    INNER JOIN orders AS o
        ON os.order_id = o.id
    WHERE 
        os.refund_ts IS NOT NULL               -- Only consider refunded orders
    GROUP BY
        YEAR(os.refund_ts),
        o.product_id
)
SELECT 
    pc.year,
    pc.product_id,
    pc.product_name,
    pc.total_orders,
    COALESCE(r.total_refunds, 0) AS total_refunds,  -- Replace NULL with 0 if no refunds
    -- Refund rate = (refunded orders / total orders) * 100
    ROUND(
        COALESCE(r.total_refunds, 0) * 100.0 / NULLIF(pc.total_orders, 0), 
        2
    ) AS refund_rate,

    -- Values from previous year for growth comparisons
    LAG(pc.total_orders) OVER (PARTITION BY pc.product_id ORDER BY pc.year) AS prev_year_orders,
    LAG(r.total_refunds) OVER (PARTITION BY pc.product_id ORDER BY pc.year) AS prev_year_refunds,

    -- Order growth rate = % change from previous year
    ROUND(
        (pc.total_orders 
         - COALESCE(LAG(pc.total_orders) OVER (PARTITION BY pc.product_id ORDER BY pc.year), 0)) 
         * 100.0 / NULLIF(
           LAG(pc.total_orders) OVER (PARTITION BY pc.product_id ORDER BY pc.year), 
           0
         ), 
        2
    ) AS order_growth_rate,

    -- Refund growth rate = % change from previous year
    ROUND(
        (COALESCE(r.total_refunds, 0) 
         - COALESCE(LAG(r.total_refunds) OVER (PARTITION BY pc.product_id ORDER BY pc.year), 0)) 
         * 100.0 / NULLIF(
           LAG(r.total_refunds) OVER (PARTITION BY pc.product_id ORDER BY pc.year), 
           0
         ), 
        2
    ) AS refund_growth_rate
FROM 
    product_count AS pc
LEFT JOIN 
    refunds AS r
    ON pc.year = r.year AND pc.product_id = r.product_id
ORDER BY 
    pc.year, 
    refund_rate DESC; -- Sort to see the worst offenders at the top


-----------------------------------------------------------------------------------------
-- 13. REFUND TREND BY MONTH AND YEAR
-----------------------------------------------------------------------------------------
SELECT 
    YEAR (os.refund_ts) AS Refund_Year,   -- Year of refund
    MONTH(os.refund_ts) AS Refund_Month, -- Month of refund
    COUNT(os.refund_ts) AS Total_Refunds -- How many refunds occurred in that month & year
FROM orders AS o
LEFT JOIN order_status AS os 
    ON o.id = os.order_id
WHERE YEAR(os.refund_ts) IS NOT NULL
GROUP BY  
    YEAR(os.refund_ts),
    MONTH(os.refund_ts)
ORDER BY 
    Refund_Year, 
    Refund_Month;
