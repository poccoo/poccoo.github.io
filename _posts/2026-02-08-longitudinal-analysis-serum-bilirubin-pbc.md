---
layout: post
title: Longitudinal Analysis of Serum Bilirubin Trajectories in PBC
subtitle: Mixed-effects modeling with the pbcseq trial data
cover-img: /assets/img/path.jpg
tags: [Longitudinal Data, Mixed Effects, R, PBC]
comments: true
mathjax: true
author: Yixin Zheng
---

## Study Question

This post summarizes a longitudinal analysis of serum bilirubin in patients with primary biliary cirrhosis (PBC), using repeated measurements from the randomized D-penicillamine trial (`pbcseq`, `survival` package).

Primary question:

What is the average trajectory of $\log(\text{bilirubin})$ over follow-up, and which within-subject dependence structure best captures repeated measurements?

## Data and Preprocessing

- Source: `pbcseq` dataset from the `survival` package
- Kept visits at/after baseline (`day >= 0`) and non-missing outcomes
- Required at least 3 observations per subject
- Converted follow-up time to years and centered time: $t^* = t - \bar t$

Final analytic data:

- `128` subjects
- `935` observations
- Follow-up range: `0` to `13.90` years
- After filtering, only the D-penicillamine arm remained

## Modeling Strategy

Mean structure candidates:

- Linear: $E(Y_{ij}) = \beta_0 + \beta_1 t^*_{ij}$
- Cubic: $E(Y_{ij}) = \beta_0 + \beta_1 t^*_{ij} + \beta_2 (t^*_{ij})^2 + \beta_3 (t^*_{ij})^3$

Dependence structures (fit by ML under cubic mean):

- Independent errors (GLS)
- Random intercept (RI)
- RI + random slope
- RI + CAR(1)
- RI + exponential residual correlation
- RI + exponential residual correlation + nugget

## Key Results

- EDA showed strong serial dependence (lag-1 residual correlation `0.926`)
- Best dependence model by AIC: `RI + Exponential + Nugget`
  - `AIC = 1328.32`, `logLik = -656.16`
- Mean comparison (LRT): linear vs cubic
  - `LR = 3.89`, `df = 2`, `p = 0.143`
  - Linear mean retained

Final fitted marginal mean:

$$
\widehat{E}(Y_{ki}) = 0.7918 + 0.1095\,t^*_{ki}
$$

Interpretation: average log-bilirubin increases over time, and modeling both subject heterogeneity and within-subject correlation is necessary for an adequate fit.

## Diagnostics and Limitations

Diagnostics indicated reduced residual autocorrelation in the final model, with mild heteroskedasticity and some tail deviation in Q-Q plots.

A key limitation is treatment imbalance after filtering (only one treatment arm remained), so treatment effects could not be estimated in this analysis.

## Files

- [Final report (PDF)]({{ '/assets/reports/longitudinal-pbc/final_1-1.pdf' | absolute_url }})
- [Analysis source (Rmd)]({{ '/assets/reports/longitudinal-pbc/final_1.Rmd' | absolute_url }})
