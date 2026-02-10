# Database Project Tables 
# create Stardew Valley schema #
CREATE DATABASE IF NOT EXISTS stardew_valley_cookbook;
USE stardew_valley_cookbook;

-- General Assumption Note:

-- NOTE: We assume all products are in their best quality and farmer level has no effect on price, yield, or growth time.

# drop tables if needed (optional) #
/*
DROP TABLE IF EXISTS recipe;
DROP TABLE IF EXISTS food;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
*/

-- ====================================================================
-- Table 1: category
-- Description: Stores category names (e.g., Crops, Fruit Tree, Animal, Artisan Goods)
-- Role: Lookup Table (full list of options, 4+)
-- Relationships: One-to-many with product
-- 3NF: Each row uniquely describes a category; no transitive dependencies
-- ====================================================================
CREATE TABLE category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL UNIQUE
);

INSERT INTO category (category_name)
VALUES 
    ('Crops'),
	('Fruit Tree'),
    ('Animals'),
    ('Artisan Goods');
    
-- ====================================================================
-- Table: product
-- Role: Lookup Table for recipe, Parent Table for growth_cycle
-- Description: Contains all base Stardew Valley ingredients
-- Relationships: Many-to-one with category, one-to-one with growth_cycle, many-to-many with food via recipe
-- 3NF: All non-key attributes describe only the product; no repeating groups or transitive dependencies
-- ====================================================================
CREATE TABLE product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL, -- FK to category
    product_name VARCHAR(255) NOT NULL UNIQUE,
    product_price SMALLINT UNSIGNED NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

INSERT INTO product (category_id, product_name, product_price)
VALUES
(1, 'blue jazz', 100),
(1, 'carrot', 70),
(1, 'cauliflower', 350),
(1, 'coffee bean', 30),
(1, 'garlic', 120),
(1, 'green bean', 80),
(1, 'kale', 220),
(1, 'parsnip', 70),
(1, 'potato', 160),
(1, 'rhubarb', 440),
(1, 'strawberry', 240),
(1, 'tulip', 60),
(1, 'unmilled rice', 60),
(1, 'blueberry', 100),
(1, 'corn', 100),
(1, 'hops', 50),
(1, 'hot pepper', 80),
(1, 'melon', 500),
(1, 'poppy', 280),
(1, 'radish', 180),
(1, 'red cabbage', 520),
(1, 'starfruit', 1500),
(1, 'summer spangle', 180),
(1, 'summer squash', 90),
(1, 'sunflower', 160),
(1, 'tomato', 120),
(1, 'wheat', 50),
(1, 'amaranth', 300),
(1, 'artichoke', 320),
(1, 'beet', 200),
(1, 'bok choy', 140),
(1, 'broccoli', 140),
(1, 'cranberries', 150),
(1, 'eggplant', 120),
(1, 'fairy rose', 580),
(1, 'grape', 160),
(1, 'pumpkin', 640),
(1, 'yam', 320),
(1, 'powdermelon', 120),
(1, 'pineapple', 600),
(1, 'taro root', 200),
(1, 'sweet gem berry', 6000),
(1, 'tea leaves', 50),
(2, 'apricot', 100),
(2, 'cherry', 160),
(2, 'banana', 300),
(2, 'mango', 260),
(2, 'orange', 200),
(2, 'peach', 280),
(2, 'apple', 200),
(2, 'pomegranate', 280),
(3, 'chicken egg', 50),
(3, 'duck egg', 95),
(3, 'cow milk', 125),
(3, 'goat milk', 225),
(3, 'truffle', 625),
(4, 'cheese', 230),
(4, 'mayonnaise', 190),
(4, 'coffee', 150),
(4, 'wheat flour', 50),
(4, 'sugar', 50),
(4, 'rice', 100),
(4, 'oil', 100),
(4, 'vinegar', 100);

-- ====================================================================
-- Table: growth_cycle
-- Role: Child Table (extension of product, 1:1)
-- Description: Holds season and growth-related variables
-- Relationships: One-to-one with product
-- 3NF: Each row describes a single product's growth logic

-- NOTE:
-- max_harvests = NULL means unlimited/continuous harvest (e.g., animals, trees)
-- is_perennial = TRUE means the crop/animal/tree does not die when the season ends

-- NOTE: We use the year 2016 as default. Published date of the game if feb.26th, 2016. Seasons are mapped as follows:
-- Spring: 2016-01-01 to 2016-03-31
-- Summer: 2016-04-01 to 2016-06-30
-- Fall:   2016-07-01 to 2016-09-30
-- Winter: 2016-10-01 to 2016-12-31
-- For crops that span multiple seasons (e.g., "summer and fall"), we extend the season_end_date accordingly.
-- For year-round products (e.g., tea leaves), we use: season_start_date = '2016-01-01', season_end_date   = '2016-12-31'

-- NOTE: Fruit Trees require 28 days to mature, after which they produce one fruit per day when in season
-- so remember to exclude the growth_time from future years when analyzing.

-- NOTES: Baby farm animals must mature before producing. Growth time indicates time to adulthood.
-- Coops hold 12 animals: assume 6 chickens + 6 ducks = 6 eggs per harvest each.
-- Barns hold 12 animals: assume 4 pigs, 4 cows, 4 goats.
-- Truffles are produced by pigs.

-- NOTE: Artisan goods have a growth time of 1 and NULL regrowth, since they require new inputs each time.
-- Yield per harvest reflects the maximum daily output.
-- For wheat flour, sugar, and rice, yield is calculated as: CEIL(36 / crop growth time),
-- where 36 is the mill’s capacity and crop growth time is: wheat (4), beet (4), rice (8).
-- ====================================================================
CREATE TABLE growth_cycle (
    product_id INT PRIMARY KEY,  -- PK + FK to product
    season_start_date DATE NOT NULL,
    season_end_date DATE NOT NULL,
    growth_time TINYINT UNSIGNED NOT NULL,
    regrowth_time TINYINT UNSIGNED DEFAULT NULL, -- NULL if not regrowable
    max_harvests TINYINT UNSIGNED DEFAULT NULL, -- NULL if unlimited
    yield_per_harvest TINYINT UNSIGNED NOT NULL DEFAULT 1,
    is_perennial BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES product(product_id)
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

INSERT INTO growth_cycle (
  product_id, season_start_date, season_end_date, growth_time,
  regrowth_time, max_harvests, yield_per_harvest, is_perennial
)
VALUES
(1, '2016-01-01', '2016-03-31', 7, NULL, 1, 1, FALSE),
(2, '2016-01-01', '2016-03-31', 3, NULL, 1, 1, FALSE),
(3, '2016-01-01', '2016-03-31', 12, NULL, 1, 1, FALSE),
(4, '2016-01-01', '2016-06-30', 10, 2, 23, 4, FALSE),
(5, '2016-01-01', '2016-03-31', 4, NULL, 1, 1, FALSE),
(6, '2016-01-01', '2016-03-31', 10, 3, 6, 1, FALSE),
(7, '2016-01-01', '2016-03-31', 6, NULL, 1, 1, FALSE),
(8, '2016-01-01', '2016-03-31', 4, NULL, 1, 1, FALSE),
(9, '2016-01-01', '2016-03-31', 6, NULL, 1, 1, FALSE),
(10, '2016-01-01', '2016-03-31', 13, NULL, 1, 1, FALSE),
(11, '2016-01-01', '2016-03-31', 8, 4, 5, 1, FALSE),
(12, '2016-01-01', '2016-03-31', 6, NULL, 1, 1, FALSE),
(13, '2016-01-01', '2016-03-31', 8, NULL, 1, 1, FALSE),
(14, '2016-04-01', '2016-06-30', 13, 4, 4, 3, FALSE),
(15, '2016-04-01', '2016-09-30', 14, 4, 11, 1, FALSE),
(16, '2016-04-01', '2016-06-30', 11, 1, 11, 1, FALSE),
(17, '2016-04-01', '2016-06-30', 5, 3, 8, 1, FALSE),
(18, '2016-04-01', '2016-06-30', 12, NULL, 1, 1, FALSE),
(19, '2016-04-01', '2016-06-30', 7, NULL, 1, 1, FALSE),
(20, '2016-04-01', '2016-06-30', 6, NULL, 1, 1, FALSE),
(21, '2016-04-01', '2016-06-30', 9, NULL, 1, 1, FALSE),
(22, '2016-04-01', '2016-06-30', 13, NULL, 1, 1, FALSE),
(23, '2016-04-01', '2016-06-30', 8, NULL, 1, 1, FALSE),
(24, '2016-04-01', '2016-06-30', 6, 3, 8, 1, FALSE),
(25, '2016-04-01', '2016-09-30', 8, NULL, 1, 1, FALSE),
(26, '2016-04-01', '2016-06-30', 11, 4, 5, 1, FALSE),
(27, '2016-04-01', '2016-09-30', 4, NULL, 1, 1, FALSE),
(28, '2016-07-01', '2016-09-30', 7, NULL, 1, 1, FALSE),
(29, '2016-07-01', '2016-09-30', 8, NULL, 1, 1, FALSE),
(30, '2016-07-01', '2016-09-30', 6, NULL, 1, 1, FALSE),
(31, '2016-07-01', '2016-09-30', 4, NULL, 1, 1, FALSE),
(32, '2016-07-01', '2016-09-30', 8, 4, 5, 1, FALSE),
(33, '2016-07-01', '2016-09-30', 7, 5, 5, 2, FALSE),
(34, '2016-07-01', '2016-09-30', 5, 5, 5, 1, FALSE),
(35, '2016-07-01', '2016-09-30', 12, NULL, 1, 1, FALSE),
(36, '2016-07-01', '2016-09-30', 10, 3, 6, 1, FALSE),
(37, '2016-07-01', '2016-09-30', 13, NULL, 1, 1, FALSE),
(38, '2016-07-01', '2016-09-30', 10, NULL, 1, 1, FALSE),
(39, '2016-10-01', '2016-12-31', 7, NULL, 1, 1, FALSE),
(40, '2016-04-01', '2016-06-30', 14, 7, 2, 1, FALSE),
(41, '2016-04-01', '2016-06-30', 10, NULL, 1, 1, FALSE),
(42, '2016-07-01', '2016-09-30', 24, NULL, 1, 1, FALSE),
(43, '2016-01-01', '2016-12-31', 20, 1, NULL, 1, TRUE),
(44, '2016-01-01', '2016-03-31', 28, 1, NULL, 1, TRUE),
(45, '2016-01-01', '2016-03-31', 28, 1, NULL, 1, TRUE),
(46, '2016-04-01', '2016-06-30', 28, 1, NULL, 1, TRUE),
(47, '2016-04-01', '2016-06-30', 28, 1, NULL, 1, TRUE),
(48, '2016-04-01', '2016-06-30', 28, 1, NULL, 1, TRUE),
(49, '2016-04-01', '2016-06-30', 28, 1, NULL, 1, TRUE),
(50, '2016-07-01', '2016-09-30', 28, 1, NULL, 1, TRUE),
(51, '2016-07-01', '2016-09-30', 28, 1, NULL, 1, TRUE),
(52, '2016-01-01', '2016-12-31', 3, 1, NULL, 6, TRUE),
(53, '2016-01-01', '2016-12-31', 5, 2, NULL, 6, TRUE),
(54, '2016-01-01', '2016-12-31', 5, 1, NULL, 4, TRUE),
(55, '2016-01-01', '2016-12-31', 5, 2, NULL, 4, TRUE),
(56, '2016-01-01', '2016-09-30', 10, 1, NULL, 4, TRUE), -- truffle (spring to fall)
(57, '2016-01-01', '2016-12-31', 1, NULL, NULL, 6, TRUE),
(58, '2016-01-01', '2016-12-31', 1, NULL, NULL, 6, TRUE),
(59, '2016-01-01', '2016-12-31', 1, NULL, NULL, 9, TRUE),
(60, '2016-01-01', '2016-12-31', 1, NULL, NULL, 10, TRUE),
(61, '2016-01-01', '2016-12-31', 1, NULL, NULL, 10, TRUE),
(62, '2016-01-01', '2016-12-31', 1, NULL, NULL, 5, TRUE),
(63, '2016-01-01', '2016-12-31', 1, NULL, NULL, 17, TRUE),
(64, '2016-01-01', '2016-12-31', 1, NULL, NULL, 2, TRUE);

-- ====================================================================
-- Table: food
-- Role: Parent Table of recipe
-- Description: Final cooked dishes in Stardew Valley
-- Relationships: One-to-many with recipe
-- 3NF: Each row describes a unique food; all attributes are fully functionally dependent on PK
-- ====================================================================
CREATE TABLE food (
    food_id INT AUTO_INCREMENT PRIMARY KEY,
    food_name VARCHAR(255) NOT NULL UNIQUE,
    food_price SMALLINT UNSIGNED NOT NULL,
    energy SMALLINT UNSIGNED NOT NULL
);

INSERT INTO food (food_name, food_price, energy)
VALUES
('Fried Egg', 35, 50),
('Omelet', 125, 100),
('Cheese Cauliflower', 300, 138),
('Parsnip Soup', 120, 85),
('Vegetable Stew', 120, 165),
('Pizza', 300, 150),
('Bean Hotpot', 100, 125),
('Glazed Yams', 200, 200),
('Hashbrowns', 120, 90),
('Pancakes', 80, 90),
('Pepper Poppers', 200, 130),
('Bread', 60, 50),
('Chocolate Cake', 200, 150),
('Pink Cake', 480, 250),
('Rhubarb Pie', 400, 215),
('Cookie', 140, 90),
('Spaghetti', 120, 75),
('Tortilla', 75, 50),
('Red Plate', 400, 240),
('Eggplant Parmesan', 200, 175),
('Rice Pudding', 260, 115),
('Ice Cream', 120, 100),
('Blueberry Tart', 180, 125),
('Autumns Bounty', 350, 220),
('Pumpkin Soup', 300, 200),
('Cranberry Sauce', 175, 125),
('Artichoke Dip', 210, 100),
('Pumpkin Pie', 385, 225),
('Radish Salad', 300, 200),
('Fruit Salad', 480, 263),
('Cranberry Candy', 230, 125),
('Coleslaw', 345, 213);

-- ====================================================================
-- Table: recipe
-- Role: Child Table
-- Relationships: Many-to-one with food, many-to-one with product; bridge table (many-to-many) between food and product
-- 3NF: Every attribute depends on the full CPK (food_id + variant_id + product_id)

-- NOTE: Foods with egg or milk include all valid combinations using the following:
--   - EGG = chicken egg (product_id = 52), duck egg (product_id = 53)
--   - MILK = cow milk (product_id = 54), goat milk (product_id = 55)
-- ====================================================================
CREATE TABLE recipe (
    recipe_id INT AUTO_INCREMENT PRIMARY KEY,
    food_id INT NOT NULL, -- FK to food
    product_id INT NOT NULL, -- FK to product
    amount TINYINT UNSIGNED NOT NULL,
	variant_id INT NOT NULL,
    FOREIGN KEY (food_id) REFERENCES food(food_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX (variant_id)
);

INSERT INTO recipe (food_id, product_id, amount, variant_id) 
VALUES
-- Recipe for food_id = 1
(1, 52, 1, 1),
(1, 53, 1, 2),
-- Recipe for food_id = 2
(2, 52, 1, 1),
(2, 54, 1, 1),
(2, 52, 1, 2),
(2, 55, 1, 2),
(2, 53, 1, 3),
(2, 54, 1, 3),
(2, 53, 1, 4),
(2, 55, 1, 4),
-- Recipe for food_id = 3
(3, 3, 1, 1),
(3, 57, 1, 1),
-- Recipe for food_id = 4
(4, 8, 1, 1),
(4, 54, 1, 1),
(4, 64, 1, 1),
(4, 8, 1, 2),
(4, 55, 1, 2),
(4, 64, 1, 2),
-- Recipe for food_id = 5
(5, 26, 1, 1),
(5, 30, 1, 1),
-- Recipe for food_id = 6
(6, 60, 1, 1),
(6, 26, 1, 1),
(6, 57, 1, 1),
-- Recipe for food_id = 7
(7, 6, 1, 1),
(7, 6, 1, 1),
-- Recipe for food_id = 8
(8, 38, 1, 1),
(8, 61, 1, 1),
-- Recipe for food_id = 9
(9, 9, 1, 1),
(9, 63, 1, 1),
-- Recipe for food_id = 10
(10, 60, 1, 1),
(10, 52, 1, 1),
(10, 60, 1, 2),
(10, 53, 1, 2),
-- Recipe for food_id = 11
(11, 17, 1, 1),
(11, 57, 1, 1),
-- Recipe for food_id = 12
(12, 60, 1, 1),
-- Recipe for food_id = 13
(13, 60, 1, 1),
(13, 61, 1, 1),
(13, 52, 1, 1),
(13, 60, 1, 2),
(13, 61, 1, 2),
(13, 53, 1, 2),
-- Recipe for food_id = 14
(14, 18, 1, 1),
(14, 60, 1, 1),
(14, 61, 1, 1),
(14, 52, 1, 1),
(14, 18, 1, 2),
(14, 60, 1, 2),
(14, 61, 1, 2),
(14, 53, 1, 2),
-- Recipe for food_id = 15
(15, 10, 1, 1),
(15, 60, 1, 1),
(15, 61, 1, 1),
-- Recipe for food_id = 16
(16, 60, 1, 1),
(16, 61, 1, 1),
(16, 52, 1, 1),
(16, 60, 1, 2),
(16, 61, 1, 2),
(16, 53, 1, 2),
-- Recipe for food_id = 17
(17, 60, 1, 1),
(17, 26, 1, 1),
-- Recipe for food_id = 18
(18, 15, 1, 1),
-- Recipe for food_id = 19
(19, 21, 1, 1),
(19, 20, 1, 1),
-- Recipe for food_id = 20
(20, 34, 1, 1),
(20, 26, 1, 1),
-- Recipe for food_id = 21
(21, 54, 1, 1),
(21, 61, 1, 1),
(21, 62, 1, 1),
(21, 55, 1, 2),
(21, 61, 1, 2),
(21, 62, 1, 2),
-- Recipe for food_id = 22
(22, 54, 1, 1),
(22, 61, 1, 1),
(22, 55, 1, 2),
(22, 61, 1, 2),
-- Recipe for food_id = 23
(23, 14, 1, 1),
(23, 60, 1, 1),
(23, 61, 1, 1),
(23, 52, 1, 1),
(23, 14, 1, 2),
(23, 60, 1, 2),
(23, 61, 1, 2),
(23, 53, 1, 2),
-- Recipe for food_id = 24
(24, 38, 1, 1),
(24, 37, 1, 1),
-- Recipe for food_id = 25
(25, 37, 1, 1),
(25, 54, 1, 1),
(25, 37, 1, 2),
(25, 55, 1, 2),
-- Recipe for food_id = 26
(26, 33, 1, 1),
(26, 61, 1, 1),
-- Recipe for food_id = 27
(27, 29, 1, 1),
(27, 54, 1, 1),
(27, 29, 1, 2),
(27, 55, 1, 2),
-- Recipe for food_id = 28
(28, 37, 1, 1),
(28, 60, 1, 1),
(28, 54, 1, 1),
(28, 61, 1, 1),
(28, 37, 1, 2),
(28, 60, 1, 2),
(28, 55, 1, 2),
(28, 61, 1, 2),
-- Recipe for food_id = 29
(29, 63, 1, 1),
(29, 64, 1, 1),
(29, 20, 1, 1),
-- Recipe for food_id = 30
(30, 14, 1, 1),
(30, 18, 1, 1),
(30, 44, 1, 1),
-- Recipe for food_id = 31
(31, 33, 1, 1),
(31, 50, 1, 1),
(31, 61, 1, 1),
-- Recipe for food_id = 32
(32, 21, 1, 1),
(32, 64, 1, 1),
(32, 58, 1, 1);