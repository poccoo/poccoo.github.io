---
layout: post
title: Stardew Valley Cookbook SQL Database Project
subtitle: MySQL schema design and query analysis for recipe and farming decisions
cover-img: /assets/img/sql-stardew-cookbook-cover.png
tags: [SQL, MySQL, Database Design, Query Optimization, Stardew Valley]
comments: true
author: Yixin Zheng
---

## Project Overview

This project builds a MySQL database around the Stardew Valley cooking workflow, from ingredient production to dish profitability.

The dataset includes:

1. Base ingredients (`product`) with category and price.
2. Seasonal production logic (`growth_cycle`) including growth time, regrowth, and harvest limits.
3. Cooked dishes (`food`) with sell price and energy.
4. Recipe composition (`recipe`) linking dishes to ingredients and variants.

## Schema Design

The schema is normalized around five tables:

1. `category`
2. `product`
3. `growth_cycle`
4. `food`
5. `recipe`

Key design choices in the table script include:

1. Foreign keys with cascade behavior for referential integrity.
2. A bridge table (`recipe`) to model many-to-many dish-ingredient relationships.
3. Explicit assumptions for season boundaries, perennial behavior, and production limits.

## Analysis Queries

The query script focuses on practical game-planning questions:

1. Best dishes by energy per gold.
2. Most profitable crops per growth day.
3. Most frequently used ingredients across recipes.
4. Highest-margin cooked dishes.
5. Full ingredient lists for each dish variant.

These queries combine joins, aggregation, common table expressions, and window functions (`RANK`) to support decision-oriented analysis.

## Files

- [Project proposal (PDF)]({{ '/assets/reports/sql-stardew-cookbook/project-proposal-2025.pdf' | absolute_url }})
- [Final cookbook report (PDF)]({{ '/assets/reports/sql-stardew-cookbook/stardew-valley-cookbook-1.pdf' | absolute_url }})
- [Table definitions (SQL)]({{ '/assets/reports/sql-stardew-cookbook/stardew_valley_cookbook_table.sql' | absolute_url }})
- [Analysis queries (SQL)]({{ '/assets/reports/sql-stardew-cookbook/stardew_valley_cookbook_query.sql' | absolute_url }})
