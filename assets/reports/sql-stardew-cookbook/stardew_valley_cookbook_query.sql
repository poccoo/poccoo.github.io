# Database Project Queries
USE stardew_valley_cookbook;

# 1. Which dishes restore the most energy per gold spent?

SELECT food_id, food_name, energy, food_price,
    ROUND(energy / food_price, 2) AS energy_per_gold,
    RANK() OVER (ORDER BY energy / food_price DESC) AS efficiency_rank
FROM food
ORDER BY efficiency_rank
LIMIT 10;

-- Purpose: Shows the most cost-efficient food to take when mining or working on the farm.

# 2. Which crops give the highest profit per day of growth?

SELECT p.product_name, p.product_price, g.growth_time,
    DATEDIFF(g.season_end_date, g.season_start_date) AS season_length,
    ROUND(p.product_price / g.growth_time, 2) AS profit_per_grow_day
FROM product AS p
INNER JOIN growth_cycle AS g ON p.product_id = g.product_id
WHERE g.growth_time > 0
ORDER BY profit_per_grow_day DESC
LIMIT 10;

-- Purpose: Helps farmers select crops that bring the most gold per day invested.

# 3. Which ingredients are used in the most recipes?

SELECT p.product_name, COUNT(DISTINCT r.food_id) AS recipe_count
FROM product AS p
INNER JOIN recipe AS r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
ORDER BY recipe_count DESC
LIMIT 10;

-- Purpose: Identifies the most “versatile” or “important” ingredients for maximizing cooking options and profit.

# 4. Which cooked dishes have the highest profit margin?

WITH recipe_profits AS (
    SELECT f.food_id, f.food_name, f.food_price,
        SUM(p.product_price * r.amount) AS total_ingredient_cost,
        (f.food_price - SUM(p.product_price * r.amount)) AS profit
    FROM food AS f
    INNER JOIN recipe AS r ON f.food_id = r.food_id
    INNER JOIN product AS p ON r.product_id = p.product_id
    GROUP BY f.food_id, f.food_name, f.food_price
)
SELECT food_name, food_price, total_ingredient_cost, profit,
    RANK() OVER (ORDER BY profit DESC) AS profit_rank
FROM recipe_profits
ORDER BY profit DESC
LIMIT 10;

-- Purpose: Ranks cooked dishes by profitability—essential for making money through cooking.

# 5. What are the full ingredient lists for every dish variant?

SELECT f.food_id, f.food_name, r.variant_id AS recipe_variant,
    GROUP_CONCAT(CONCAT(p.product_name, ' (', r.amount, ')') ORDER BY p.product_name SEPARATOR ', ') AS ingredients
FROM recipe AS r
INNER JOIN food AS f ON r.food_id = f.food_id
INNER JOIN product AS p ON r.product_id = p.product_id
GROUP BY f.food_id, f.food_name, r.variant_id
ORDER BY f.food_id, r.variant_id;

-- Purpose: Shows the full recipe for each dish and all its variants—great for planning what ingredients to farm or keep on hand.