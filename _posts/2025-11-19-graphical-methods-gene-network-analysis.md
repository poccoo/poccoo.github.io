---
layout: post
title: Graphical Methods Final Project
subtitle: Gene network comparison between asthma and normal samples
cover-img: /assets/img/graphical-methods-cover.png
tags: [Graphical Methods, Gene Network, FastGGM, Graphical Lasso]
comments: true
mathjax: true
author: Yixin Zheng
---

## Project Objective

This project compares asthma vs normal gene networks using microarray expression data and two complementary high-dimensional graphical methods:

1. `FastGGM` partial-correlation graph learning.
2. Graphical Lasso (`huge`) precision-matrix estimation.

The main scientific goal is to identify network-structure differences and candidate differential edges between disease groups.

## Data and Preprocessing

Input files used in the analysis code:

1. `Normalized_expression.txt`
2. `E-MTAB-1425.sdrf.txt`

Key preprocessing steps:

1. Keep samples labeled as `asthma` or `normal` from SDRF annotations.
2. Match expression columns to sample IDs from metadata.
3. Keep top variable genes with `P_GENES = 800`.
4. Standardize each gene before graph learning.
5. Use top 100 variable genes for correlation heatmap visualization.

## Modeling Setup

Core settings from `final_project_code.Rmd`:

1. `P_GENES = 800`
2. `TARGET_EDGE_COUNT = 800`
3. `N_LAMBDA = 30`
4. `FASTGGM_FDR_ALPHA = 0.10`
5. `B_PERM = 200` (permutation iterations)

### Method 1: FastGGM

Two graph variants were built for each group:

1. BH-FDR thresholded graph (`alpha = 0.10`).
2. Top-K graph (`K = 800` edges) for direct density-matched comparison.

### Method 2: Graphical Lasso

For each group:

1. Fit a lambda path with `nlambda = 30`.
2. Select lambda index with edge count closest to 800.
3. Build adjacency from top absolute partial correlations.

## Main Results

### Edge Overlap (Density-Matched Graphs)

| Method | Asthma edges | Normal edges | Intersection | Symmetric difference |
|---|---:|---:|---:|---:|
| FastGGM (TopK) | 800 | 800 | 238 | 1124 |
| Glasso (Top\|pcor\|) | 800 | 800 | 570 | 460 |

Interpretation:

1. Under matched edge counts, Glasso networks are more similar across groups than FastGGM TopK networks.
2. FastGGM TopK shows larger between-group structural divergence.

### FastGGM BH-FDR Graph Size

| Method | Asthma edges | Normal edges | Intersection | Symmetric difference | alpha |
|---|---:|---:|---:|---:|---:|
| FastGGM (BH-FDR) | 9264 | 3912 | 929 | 11318 | 0.10 |

Interpretation:

1. The asthma BH-FDR network is much denser than normal at the same FDR threshold.
2. This motivates density-matched comparisons when contrasting structure.

### Differential Edge Screening

Glasso permutation-based differential testing summary:

1. Tested edges: 518 (union/hub-filtered set).
2. `min(p_emp) = 0.00498`.
3. `min(q_fdr) = 0.39648`.
4. Significant edges at `q_fdr <= 0.10`: `0`.

FastGGM descriptive top absolute delta edges (not permutation/FDR-tested in this table):

| gene_i | gene_j | delta |
|---|---|---:|
| 224568_x_at | 211367_s_at | -0.5898 |
| 219759_at | 226085_at | 0.5628 |
| 224568_x_at | 225046_at | 0.5475 |
| 200799_at | 216576_x_at | 0.5305 |
| 211555_s_at | 211367_s_at | -0.5281 |

## Figures

### Correlation and Tuning

![Top-100 gene correlation heatmap]({{ '/assets/reports/graphical-methods/eda_correlation_heatmap_top100.jpg' | absolute_url }})

![Glasso tuning path: edge count vs lambda index]({{ '/assets/reports/graphical-methods/glasso_edgecount_path.jpg' | absolute_url }})

![Degree distribution by method and group]({{ '/assets/reports/graphical-methods/degree_distribution_by_method.jpg' | absolute_url }})

### Network Visualizations

![FastGGM TopK network in asthma]({{ '/assets/reports/graphical-methods/network_fastggm_asthma.jpg' | absolute_url }})

![FastGGM TopK network in normal]({{ '/assets/reports/graphical-methods/network_fastggm_normal.jpg' | absolute_url }})

![Glasso network in asthma]({{ '/assets/reports/graphical-methods/network_glasso_asthma.jpg' | absolute_url }})

![Glasso network in normal]({{ '/assets/reports/graphical-methods/network_glasso_normal.jpg' | absolute_url }})

## Reproducibility Files

- [Project code (Rmd)]({{ '/assets/reports/graphical-methods/final_project_code.Rmd' | absolute_url }})
- [Final project report (PDF, 2025 version)]({{ '/assets/reports/graphical-methods/final_proj_2025.pdf' | absolute_url }})
- [Previous report copy (PDF)]({{ '/assets/reports/graphical-methods/graphical_methods.pdf' | absolute_url }})
- [Edge overlap summary (CSV)]({{ '/assets/reports/graphical-methods/edge_overlap_summary.csv' | absolute_url }})
- [FastGGM FDR overlap (CSV)]({{ '/assets/reports/graphical-methods/edge_overlap_fastggm_fdr.csv' | absolute_url }})
- [FastGGM differential edges by |delta| (CSV)]({{ '/assets/reports/graphical-methods/diff_edges_fastggm_desc.csv' | absolute_url }})
- [Glasso permutation differential edges (CSV)]({{ '/assets/reports/graphical-methods/diff_edges_glasso_perm.csv' | absolute_url }})
