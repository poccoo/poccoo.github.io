---
layout: post
title: Graphical Methods Final Project
subtitle: Gene network comparison between asthma and normal samples
cover-img: /assets/reports/graphical-methods/graphical_methods-cover.png
tags: [Graphical Methods, Gene Network, FastGGM, Graphical Lasso]
comments: true
mathjax: true
author: Yixin Zheng
---

## Project Goal

This project studies differential gene network structure between asthma and normal groups using expression data, with two complementary graphical modeling approaches.

## Data Pipeline

The analysis pipeline in the code file (`final_project_code.Rmd`) is:

1. Read normalized expression matrix and SDRF annotation.
2. Match sample IDs and keep only asthma/normal groups.
3. Keep top variable genes (`P_GENES = 800`).
4. Standardize expression features before graph learning.

## Methods

Two methods are used and then compared under matched graph density:

1. `FastGGM`
- FDR-based graph (`BH`, `alpha = 0.10`)
- Top-K edge graph (`TARGET_EDGE_COUNT = 800`)

2. Graphical Lasso (`huge`)
- Tune over lambda path (`N_LAMBDA = 30`)
- Select lambda giving edge count closest to target
- Build adjacency from top absolute partial correlations

## Comparison and Differential Analysis

After network estimation, the workflow compares:

1. Edge overlap and symmetric differences between asthma/normal.
2. Degree distributions by method and group.
3. Network visualizations for top-degree subgraphs.

For differential edges in the glasso graph, the code applies a permutation framework:

1. Build tested edge set from union of asthma/normal edges (hub-filtered first).
2. Compute observed partial-correlation differences.
3. Run permutation with `B = 200`.
4. Compute empirical p-values and BH-adjusted FDR.

## Notes

This post summarizes the implemented workflow from the project code and accompanying report files. The raw expression inputs referenced in the code path are external to this website repository.

## Files

- [Project report (PDF)]({{ '/assets/reports/graphical-methods/graphical_methods.pdf' | absolute_url }})
- [Project code (Rmd)]({{ '/assets/reports/graphical-methods/final_project_code.Rmd' | absolute_url }})
