---
layout: post
title: Survival Analysis on Cirrhosis Clinical Trial Data
subtitle: Kaplan-Meier, log-rank tests, and stratified Cox modeling in PBC
cover-img: /assets/img/survival-analysis-cirrhosis-cover.png
tags: [Survival Analysis, Cox Model, Kaplan-Meier, Cirrhosis, Biostatistics]
comments: true
mathjax: true
author: Yixin Zheng
---

## Project Objective

This project evaluates whether D-penicillamine improves survival versus placebo in primary biliary cirrhosis (PBC), and identifies baseline prognostic factors for mortality.

## Data and Setup

- Source clinical trial cohort: 418 observations.
- Status coding: `D` as event, `C` and `CL` as censored.
- Main modeling cohort: randomized, complete-case subset.
- Key transformed variables:
  - `age_years` from age in days.
  - `log_bilirubin` to address strong right skew.
  - `edema_bin` as binary edema indicator.

## Exploratory Findings

Baseline distribution and biomarker patterns support known liver disease progression signals.

![Age distribution by survival status]({{ '/assets/reports/survival-analysis-cirrhosis/age-distribution.png' | absolute_url }})

![Distribution of key numeric variables]({{ '/assets/reports/survival-analysis-cirrhosis/distribution-of-numeric-variables.png' | absolute_url }})

![Albumin and bilirubin by status]({{ '/assets/reports/survival-analysis-cirrhosis/lab-markers-distribution.png' | absolute_url }})

![Correlation heatmap]({{ '/assets/reports/survival-analysis-cirrhosis/correlation-heatmap.png' | absolute_url }})

Baseline balance between treatment groups:

![Baseline categorical variables table]({{ '/assets/reports/survival-analysis-cirrhosis/eda-baseline-cat.png' | absolute_url }})

![Baseline continuous variables table]({{ '/assets/reports/survival-analysis-cirrhosis/eda-baseline-cont.png' | absolute_url }})

## Kaplan-Meier and Log-rank Results

Overall and stratified Kaplan-Meier analyses consistently show no clear survival separation between treatment arms.

- Unstratified log-rank: `p = 0.7`
- Stratified by stage: `p = 0.6`
- Stratified by age tertile: `p = 1.0`
- Stratified by bilirubin quartile: `p = 0.9`
- Stratified by albumin tertile: `p = 1.0`

![Overall KM curve]({{ '/assets/reports/survival-analysis-cirrhosis/km-plot-main.png' | absolute_url }})

![KM by histologic stage]({{ '/assets/reports/survival-analysis-cirrhosis/km-plot-stage.png' | absolute_url }})

![KM by age tertile]({{ '/assets/reports/survival-analysis-cirrhosis/km-plot-age.png' | absolute_url }})

![KM by bilirubin quartile]({{ '/assets/reports/survival-analysis-cirrhosis/km-plot-bili.png' | absolute_url }})

![KM by albumin tertile]({{ '/assets/reports/survival-analysis-cirrhosis/km-plot-alb.png' | absolute_url }})

Corresponding log-rank outputs:

![Log-rank overall]({{ '/assets/reports/survival-analysis-cirrhosis/logrank-main.png' | absolute_url }})

![Log-rank stratified by stage]({{ '/assets/reports/survival-analysis-cirrhosis/logrank-stage.png' | absolute_url }})

![Log-rank stratified by age]({{ '/assets/reports/survival-analysis-cirrhosis/logrank-age.png' | absolute_url }})

![Log-rank stratified by bilirubin]({{ '/assets/reports/survival-analysis-cirrhosis/logrank-bili.png' | absolute_url }})

![Log-rank stratified by albumin]({{ '/assets/reports/survival-analysis-cirrhosis/logrank-alb.png' | absolute_url }})

## Cox Proportional Hazards Modeling

Main model and reduced model both indicate no statistically significant treatment effect for D-penicillamine vs placebo after adjustment.

Core prognostic signals are stable:

- Higher age increases hazard.
- Higher log-bilirubin increases hazard strongly.
- Higher albumin is protective.
- Longer prothrombin time increases hazard.
- Edema is retained as an adverse factor in the reduced model.

![Main Cox model output]({{ '/assets/reports/survival-analysis-cirrhosis/cox-main-model.png' | absolute_url }})

![Reduced Cox model output]({{ '/assets/reports/survival-analysis-cirrhosis/cox-reduced-model.png' | absolute_url }})

## Variable Selection and Diagnostics

Supporting model-selection outputs:

![Stepwise model summary]({{ '/assets/reports/survival-analysis-cirrhosis/stepwise-table.png' | absolute_url }})

![Lasso model summary]({{ '/assets/reports/survival-analysis-cirrhosis/lasso-table.png' | absolute_url }})

Time-varying effect checks for selected covariates:

![Schoenfeld residual check for edema]({{ '/assets/reports/survival-analysis-cirrhosis/schoenfeld-edema.png' | absolute_url }})

![Schoenfeld residual check for prothrombin]({{ '/assets/reports/survival-analysis-cirrhosis/schoenfeld-prothrombin.png' | absolute_url }})

Nomogram for 1-, 3-, and 5-year survival prediction:

![Nomogram]({{ '/assets/reports/survival-analysis-cirrhosis/nomgram-cx.png' | absolute_url }})

## Files

- [Final report (PDF)]({{ '/assets/reports/survival-analysis-cirrhosis/survival-analysis-report-1.pdf' | absolute_url }})
- [LaTeX source (main.tex)]({{ '/assets/reports/survival-analysis-cirrhosis/main.tex' | absolute_url }})
- [LaTeX source (main2.tex)]({{ '/assets/reports/survival-analysis-cirrhosis/main2.tex' | absolute_url }})
