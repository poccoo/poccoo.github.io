---
layout: post
title: ADNI rs FMRI FC Analysis
subtitle: Baricitinib for Severe Alopecia Areata
cover-img: /assets/img/image2.png
tags: [FMRI, Function Connectivity]
comments: true
mathjax: true
author: Yixin Zheng
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r session info, include=TRUE, collapse=TRUE}
sessionInfo()
```

This analysis follows the approach of Kim et al.(2023), applying similar
modeling to ADNI resting-state fMRI data.

We summarize within network functional connectivity (we will derive the
functional connectivity within the reward/effort network later)

Specifically, we will focus on H1-H3 this time: H1. amyloid -\> FC -\>
apathy (mediation) H2. amyloid -\> FC -\> apathy (interaction —
specificity of FC) H3. amyloid -\> FC -\> other NPS (common vs unique FC
effects) H4. amyloid -\> FC -\> cognition -\> apathy

```{r library, include=FALSE}
library(dplyr)
library(tidyr)
library(ggplot2)
library(broom)
library(lme4)
library(lmerTest)
library(mediation)
library(arsenal)
library(emmeans)
library(performance)
library(arm)
library(knitr)
library(sjPlot)
```

# Data Preprocessing

```{r load, collapse=TRUE}
# load
dat      <- read.csv("../Data/ADNI_dat.longitudinal_full.n1513_2025_06_23.csv")
baseline <- read.csv("../Data/ADNI_dat.baseline_only.n745_2025_06_23.csv")

# variable sets
fc_raw     <- c("SN","DMN","FPN")  # raw FC variables
nps_vars   <- c("NPIATOT","NPIBTOT","NPICTOT","NPIDTOT","NPIETOT",
                "NPIFTOT","NPIHTOT","NPIITOT","NPIJTOT","NPIKTOT","NPILTOT")
nps_vars_z <- paste0(nps_vars, "_z")

# helpers
to_num <- function(x) suppressWarnings(as.numeric(x))
z <- function(x) as.numeric(scale(x))  # returns numeric, not matrix

# robust binary guard: maps common encodings to 0/1
as_bin01 <- function(v, cutoff = NULL) {
  # if cutoff provided, use continuous source to create binary
  if (!is.null(cutoff)) return(ifelse(to_num(v) >= cutoff, 1L, 0L))
  # otherwise coerce from existing codes/strings
  out <- tolower(as.character(v))
  out[out %in% c("1","yes","true","pos","positive")] <- "1"
  out[out %in% c("0","no","false","neg","negative")] <- "0"
  out <- as.integer(out)
  # leave NA if still not 0/1
  out[!(out %in% c(0L,1L))] <- NA_integer_
  out
}

preprocess_fn <- function(df) {
  # ensure PTID available as factor for random effects
  if (!"PTID" %in% names(df)) stop("PTID is required in the dataset.")
  df$PTID <- as.factor(df$PTID)

  # FC & NPS numerics
  for (v in fc_raw)    if (v %in% names(df)) df[[v]] <- to_num(df[[v]])
  for (v in nps_vars)  if (v %in% names(df)) df[[v]] <- to_num(df[[v]])

  # core continuous numerics
  num_vars <- c("Age","PTEDUCAT","NPITOTAL","NPIGTOT","SUMMARYSUVR_WHOLECEREBNORM")
  for (v in num_vars) if (v %in% names(df)) df[[v]] <- to_num(df[[v]])

  # outcomes
  df$NPIG <- ifelse(!is.na(df$NPIGTOT) & df$NPIGTOT > 0, 1L, 0L)

  # amyloid binary (prefer provided cutoff var if valid; else derive from 1.11)
  if ("SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF" %in% names(df)) {
    bin_raw <- as_bin01(df$SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF)
  } else {
    bin_raw <- as_bin01(df$SUMMARYSUVR_WHOLECEREBNORM, cutoff = 1.11)
  }
  df$SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF <- bin_raw

  # categorical covariates as factors (set explicit order later)
  if ("HMHYPERT" %in% names(df))               df$HMHYPERT <- factor(as_bin01(df$HMHYPERT), levels = c(0,1))
  if ("sedatives_hypnotics_use" %in% names(df)) df$sedatives_hypnotics_use <- factor(as_bin01(df$sedatives_hypnotics_use), levels = c(0,1))
  if ("PTGENDER" %in% names(df))               df$PTGENDER <- factor(df$PTGENDER)
  if ("DX.new" %in% names(df))                 df$DX.new   <- factor(df$DX.new)

  # z-scales for continuous predictors/outcomes
  if ("NPIGTOT" %in% names(df))  df$NPIGTOT_z  <- z(df$NPIGTOT)
  if ("Age" %in% names(df))      df$Age_z      <- z(df$Age)
  if ("PTEDUCAT" %in% names(df)) df$PTEDUCAT_z <- z(df$PTEDUCAT)
  if ("NPITOTAL" %in% names(df)) df$NPITOTAL_z <- z(df$NPITOTAL)
  if ("SN" %in% names(df))       df$SN_z       <- z(df$SN)
  if ("DMN" %in% names(df))      df$DMN_z      <- z(df$DMN)
  if ("FPN" %in% names(df))      df$FPN_z      <- z(df$FPN)
  if ("SUMMARYSUVR_WHOLECEREBNORM" %in% names(df))
    df$Amyloid_z <- z(df$SUMMARYSUVR_WHOLECEREBNORM)

  # z-scores for all NPS domains (continuous; used in H3 longitudinal)
  for (i in seq_along(nps_vars)) {
    v <- nps_vars[i]; vz <- nps_vars_z[i]
    if (v %in% names(df)) df[[vz]] <- z(df[[v]])
  }

  # set factor reference levels for interpretability
  if ("PTGENDER" %in% names(df) && any(levels(df$PTGENDER) == "0")) df$PTGENDER <- 
    stats::relevel(df$PTGENDER, ref = "0")
  if ("DX.new"   %in% names(df) && any(levels(df$DX.new)   == "CN")) df$DX.new   <- 
    stats::relevel(df$DX.new, ref = "CN")

  df
}

# run preprocessing
dat      <- preprocess_fn(dat)
baseline <- preprocess_fn(baseline)

# modeling variable names 
fc_vars  <- c("SN_z","DMN_z","FPN_z")                 # mediators
x_bin    <- "SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF"   # binary amyloid
x_cont   <- "Amyloid_z"                               # continuous amyloid
y_bin    <- "NPIG"                                    # binary apathy
y_cont   <- "NPIGTOT_z"                               # z-scored continuous apathy

# covariate sets (with & without DX.new)
covars_with_dx <- c("Age_z","PTGENDER","PTEDUCAT_z","DX.new",
                    "sedatives_hypnotics_use","NPITOTAL_z","HMHYPERT")
covars_no_dx   <- c("Age_z","PTGENDER","PTEDUCAT_z",
                    "sedatives_hypnotics_use","NPITOTAL_z","HMHYPERT")

```

-   `SubID`: Scan ID for each imaging session, includes Patient ID and
    scan date (YearMonthDay). You may have multiple SubIDs for the same
    participant, corresponding to different visit dates.\

-   `PTID`: Imaging Patient ID\

-   `RID`: Research ID\

-   `Age`: Age at scan (years)\

-   `Age_z`: Standardized age at scan (z-score)\

-   `PTGENDER`: Sex (0 = Male, 1 = Female) Used directly as `Sex`
    covariate per Kim et al.\

-   `PTEDUCAT`: Years of education\

-   `PTEDUCAT_z`: Standardized years of education (z-score)\

-   `DX.new`: Clinical diagnosis (CN, MCI, Dementia) Matches
    `Cognitive Statics` per Kim et al.\

-   `HMHYPERT`: History of hypertension (0 = No, 1 = Yes)

-   `sedatives_hypnotics_use`: Sedatives/hypnotics use (binary, 0 =
    FALSE, 1 = TRUE) Matches `Sleep medication use` per Kim et al.\

-   `SUMMARYSUVR_WHOLECEREBNORM`: Amyloid burden (continuous)\

-   `Amyloid_z`: Standardized amyloid burden (z-score), used in all
    longitudinal models

-   `SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF`: Amyloid positivity (binary;
    0 = negative, 1 = positive). Threshold of 1.11 used to define
    amyloid-positive status\

-   `NPITOTAL`: Total NPI score. Matches `Total NPI/NPIQ score` per Kim
    et al.\

-   `NPITOTAL_z`: Standardized total NPI score (z-score)\

-   `NPIGTOT`: Apathy subscore, outcome in H1 and H2\

-   `NPIGTOT_z`: Standardized apathy score (z-score), used in
    longitudinal models\

-   `NPIG`: Binary apathy outcome (1 = Apathy present if NPIGTOT \> 0,
    else 0), derived from `NPIGTOT`\

-   Other NPS outcomes for H3 (continuous 0–12): outcomes in H3 Also
    standardized to z-scores for use in longitudinal mixed models:

    -   `NPIATOT`: Delusions `NPIATOT_z`: Standardized delusions score
    -   `NPIBTOT`: Hallucinations `NPIBTOT_z`: Standardized
        hallucinations score
    -   `NPICTOT`: Agitation `NPICTOT_z`: Standardized agitation score
    -   `NPIDTOT`: Depression / Dysphoria `NPIDTOT_z`: Standardized
        depression score
    -   `NPIETOT`: Anxiety `NPIETOT_z`: Standardized anxiety score
    -   `NPIFTOT`: Euphoria `NPIFTOT_z`: Standardized euphoria score
    -   `NPIHTOT`: Disinhibition `NPIHTOT_z`: Standardized disinhibition
        score
    -   `NPIITOT`: Irritability / Lability `NPIITOT_z`: Standardized
        irritability score
    -   `NPIJTOT`: Aberrant motor activity `NPIJTOT_z`: Standardized
        aberrant motor score
    -   `NPIKTOT`: Night-time behavioral disturbances `NPIKTOT_z`:
        Standardized night-time disturbances score
    -   `NPILTOT`: Appetite and eating abnormalities `NPILTOT_z`:
        Standardized appetite/eating score

-   FC variables: Within-network functional connectivity measures\

    -   `SN`: Salience Network\
        `SN_z`: Standardized SN connectivity\
    -   `DMN`: Default Mode Network\
        `DMN_z`: Standardized DMN connectivity\
    -   `FPN`: Frontoparietal Network\
        `FPN_z`: Standardized FPN connectivity\

### Notes:

This analysis includes both **baseline-only** and **longitudinal**
approaches. The baseline dataset uses the earliest available visit for
each participant and is analyzed using standard linear (`lm`) and
logistic (`glm`) regression models. This simplifies interpretation by
avoiding within-subject correlation.

The longitudinal dataset includes repeated imaging sessions per
participant. To account for within-subject correlation over time, we use
mixed-effects models (`lmer`, `glmer`) with random intercepts for
participant ID (`PTID`). These models allow us to leverage follow-up
data to increase statistical power while properly handling repeated
measures.

We z-score continuous predictors (FC, amyloid burden, age, education,
total NPI) to improve model convergence and allow comparison of effect
sizes.

Binary predictors (e.g., amyloid positivity, NPIG) are not scaled. For
H2 interaction models, continuous amyloid is used to evaluate graded
effects across the amyloid spectrum.

Mediation analyses use quasi-Bayesian simulations (n = 5000) to estimate
indirect (ACME), direct (ADE), total effects, and the proportion
mediated, with 95% confidence intervals. Binary outcomes (e.g., apathy
presence) are modeled with logistic mixed models, while continuous
outcomes (e.g., NPI subscores) use linear mixed models.

Functional connectivity is measured at the **within-network level**: SN:
Salience Network\
DMN: Default Mode Networt\
FPN: Frontoparietal Network

Some models produced convergence warnings, likely due to low apathy
prevalence and small subgroup sizes. We retain these models
provisionally for exploratory interpretation and will follow up with
alternative specifications if needed.

# Descriptive Table

**Descriptives & sample sizes**

```{r High-level N and prevalence}
# Prevalence
baseline_prev <- mean(baseline$NPIG, na.rm = TRUE) * 100
long_prev     <- mean(dat$NPIG,      na.rm = TRUE) * 100

# Unique participants from each file
n_baseline_ptid <- dplyr::n_distinct(baseline$PTID)
n_long_ptid     <- dplyr::n_distinct(dat$PTID)

# Visit structure (longitudinal)
visit_counts       <- dat %>% dplyr::count(PTID, name = "n_visits")
n_with_followup    <- sum(visit_counts$n_visits > 1)
pct_with_followup  <- round(100 * n_with_followup / n_long_ptid, 1)

# Baseline models (H1/H2 use these at baseline): require binary apathy, amyloid (both forms),
# all three FC mediators present, and covariates with DX.new
needed_base <- c(y_bin, x_bin, x_cont, fc_vars, covars_with_dx)
baseline_cc <- baseline[stats::complete.cases(baseline[, needed_base]), ]
n_baseline_cc <- nrow(baseline_cc)                

# Longitudinal models (H1/H2/H3): require PTID, covariates with DX.new, amyloid (both forms),
# both apathy outcomes (binary & continuous), and all three FC mediators
needed_long <- c("PTID", covars_with_dx, x_bin, x_cont, y_bin, y_cont, fc_vars)
dat_cc      <- dat[stats::complete.cases(dat[, needed_long]), ]
n_long_rows_cc <- nrow(dat_cc)                     
n_long_ids_cc  <- dplyr::n_distinct(dat_cc$PTID)    

cat(sprintf("Baseline apathy prevalence: %.1f%%\n", baseline_prev))
cat(sprintf("Longitudinal apathy prevalence (all visits): %.1f%%\n", long_prev))
cat(sprintf("Total unique participants (baseline): %d (complete cases: %d)\n",
            n_baseline_ptid, n_baseline_cc))
cat(sprintf("Total unique participants (longitudinal): %d (complete-case IDs: %d)\n",
            n_long_ptid, n_long_ids_cc))
cat(sprintf("Longitudinal complete-case rows used in models: %d\n", n_long_rows_cc))
cat(sprintf("Participants with \u22652 visits: %d (%.1f%%)\n",
            n_with_followup, pct_with_followup))
```

```{r Baseline descriptives by amyloid status}
baseline_bl <- baseline %>%
  mutate(Amyloid_Group = ifelse(.data[[x_bin]] == 1, "Amyloid+", "Amyloid-"))

tbl_bl <- tableby(
  Amyloid_Group ~ Age + PTGENDER + PTEDUCAT + DX.new +
    sedatives_hypnotics_use + HMHYPERT + NPITOTAL + NPIGTOT + NPIG,
  data = baseline_bl
)

knitr::kable(
  as.data.frame(summary(tbl_bl)),
  caption = sprintf(
    "Baseline Descriptives by Amyloid Group")
)
```

```{r Longitudinal cohort (first visit per PTID) descriptives}
needed_cc <- c(x_bin, y_bin, covars_with_dx, "PTID")
dat_long_cc <- dat[complete.cases(dat[, needed_cc]), ]

# Add amyloid grouping; use raw variables in the table for interpretability
dat_long_cc <- dat_long_cc %>%
  mutate(Amyloid_Group = ifelse(.data[[x_bin]] == 1, "Amyloid+", "Amyloid-"))

n_long_rows <- nrow(dat_long_cc)                     # ≈ 1320
n_long_ids  <- dplyr::n_distinct(dat_long_cc$PTID)   # ≈ 743

tbl_long_all <- tableby(
  Amyloid_Group ~ Age + PTGENDER + PTEDUCAT + DX.new +
    sedatives_hypnotics_use + HMHYPERT + NPITOTAL + NPIGTOT + NPIG,
  data = dat_long_cc
)

knitr::kable(
  as.data.frame(summary(tbl_long_all)),
  caption = sprintf(
    "Longitudinal Descriptives by Amyloid Group (ALL visits used in longitudinal models; rows = %d; unique PTIDs = %d)",
    n_long_rows, n_long_ids
  )
)
```

```{r N used in each hypothesis/model family}
# H1 (example shown for SN_z; all FC use same filtering structure)
vars_h1_bin   <- c(x_cont, y_bin, fc_vars, covars_with_dx, "PTID") # binary apathy; continuous amyloid
vars_h1_cont  <- c(x_cont, y_cont, fc_vars, covars_with_dx, "PTID") # continuous apathy

dat_h1_bin  <- dat[complete.cases(dat[, vars_h1_bin]), ]
dat_h1_cont <- dat[complete.cases(dat[, vars_h1_cont]), ]

cat("H1 longitudinal (binary apathy) rows/IDs:",
    nrow(dat_h1_bin), "/", n_distinct(dat_h1_bin$PTID), "\n")
cat("H1 longitudinal (continuous apathy) rows/IDs:",
    nrow(dat_h1_cont), "/", n_distinct(dat_h1_cont$PTID), "\n\n")

# H2 longitudinal (binary apathy) WITH and WITHOUT DX.new
ns_h2 <- lapply(fc_vars, function(m) {
  d_with <- dat[complete.cases(dat[, c(x_bin, y_bin, m, covars_with_dx, "PTID")]), ]
  d_no   <- dat[complete.cases(dat[, c(x_bin, y_bin, m, covars_no_dx, "PTID")]), ]
  tibble(
    Mediator = m,
    n_rows_withDX = nrow(d_with),
    n_ids_withDX  = n_distinct(d_with$PTID),
    n_rows_noDX   = nrow(d_no),
    n_ids_noDX    = n_distinct(d_no$PTID)
  )
}) %>% bind_rows()

knitr::kable(ns_h2, caption = "H2 (Binary Apathy) Longitudinal n’s by FC and DX.new inclusion")

# H3 longitudinal (all NPS_z outcomes)
vars_h3 <- expand.grid(Mediator = fc_vars, Outcome = paste0(nps_vars, "_z"), KEEP.OUT.STATS = FALSE)
ns_h3 <- apply(vars_h3, 1, function(row) {
  m <- row[["Mediator"]]; y <- row[["Outcome"]]
  d <- dat[complete.cases(dat[, c(x_cont, y, m, covars_with_dx, "PTID")]), ]
  tibble(Mediator = m, Outcome = y, n_rows = nrow(d), n_ids = n_distinct(d$PTID))
}) %>% bind_rows()

knitr::kable(ns_h3, caption = "H3 Longitudinal n’s by FC and NPS outcome")
```

```{r NPIGTOT distribution at baseline, collapse=TRUE}
ggplot(baseline, aes(x = NPIGTOT)) +
  geom_histogram(binwidth = 1, fill = "aliceblue", alpha = 0.8, boundary = 0) +
  theme_minimal() +
  labs(
    title = "Distribution of NPIGTOT (Apathy Severity) at Baseline",
    x = "NPIGTOT Score",
    y = "Count"
  )
```

**Demographics and Clinical Characteristics at baseline**

```{r demographics and  fc distribution by amyloid}
baseline1 <- baseline %>%
  mutate(Amyloid_Group = factor(
    ifelse(SUMMARYSUVR_WHOLECEREBNORM_1.11CUTOFF == 1, "Amyloid+", "Amyloid-")
  ))

tbl1 <- tableby(
  Amyloid_Group ~ Age + PTGENDER + PTEDUCAT + DX.new +
    sedatives_hypnotics_use + HMHYPERT + NPITOTAL + NPIGTOT,
  data = baseline1
)
knitr::kable(as.data.frame(summary(tbl1)),
             caption = "Baseline Demographics and Clinical Characteristics by Amyloid Group")

fc_by_amyloid <- baseline1 %>%
  tidyr::pivot_longer(cols = all_of(fc_raw), names_to = "FC", values_to = "Value")

ggplot(fc_by_amyloid, aes(x = Amyloid_Group, y = Value, fill = Amyloid_Group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.2, color = "black", size = 0.6) +
  facet_wrap(~ FC, scales = "free_y") +
  theme_minimal() +
  labs(title = "Within-Network FC at Baseline by Amyloid Group",
       x = "Amyloid Group", y = "FC Value") +
  theme(legend.position = "none")
```
# Hypothesis

## H1

### baseline

```{r H1 baseline, collapse=TRUE}
results_list_H1_baseline <- list()

for (m in fc_vars) {
  cat("\n# H1 Baseline: Mediation - Amyloid ->", m, "-> Apathy (NPIG)\n")

  dat_b <- baseline[complete.cases(baseline[, c(x_cont, y_bin, m, covars_with_dx)]), ]
  N_used <- nrow(dat_b)

  model.m <- lm(as.formula(paste(m, "~", x_cont, "+", paste(covars_with_dx, collapse = "+"))),
                data = dat_b)
  model.y <- glm(as.formula(paste(y_bin, "~", m, "+", x_cont, "+", paste(covars_with_dx, collapse = "+"))),
                 data = dat_b, family = binomial)

  ## print model summaries
  cat("\nMediator model:\n")
  print(summary(model.m))
  cat("\nOutcome model:\n")
  print(summary(model.y))
  
  ## mediation
  set.seed(123)
  med.out <- mediation::mediate(model.m, model.y, treat = x_cont, mediator = m,
                                boot = FALSE, sims = 5000)
  out_summary <- summary(med.out)

  result <- data.frame(
    Mediator = m,
    N = N_used,
    ACME = out_summary$d0,
    ACME_lower = out_summary$d0.ci[1],
    ACME_upper = out_summary$d0.ci[2],
    ADE = out_summary$z0,
    ADE_lower = out_summary$z0.ci[1],
    ADE_upper = out_summary$z0.ci[2],
    Total_Effect = out_summary$tau.coef,
    Total_lower = out_summary$tau.ci[1],
    Total_upper = out_summary$tau.ci[2],
    Proportion_Mediated = out_summary$n0
  )

  print(result)
  results_list_H1_baseline[[m]] <- result
}
```

### longitudinal

```{r H1 longitudinal binary, collapse=TRUE}
results_list_H1_logi <- list()

for (m in fc_vars) {
  cat("\n---\n")
  cat(paste0("## H1 Longitudinal: Manual Mediation - Amyloid -> ", m, " -> Apathy (NPIG)\n"))

  vars_needed <- c(x_cont, y_bin, m, covars_with_dx, "PTID")
  dat_h1 <- dat[complete.cases(dat[, vars_needed]), ]
  n_used <- nrow(dat_h1); n_ids <- dplyr::n_distinct(dat_h1$PTID)
  cat("Rows used:", n_used, " | Unique PTID:", n_ids, "\n")

  formula_m <- as.formula(paste(m, "~", x_cont, "+", paste(covars_with_dx, collapse = "+"), "+ (1 | PTID)"))
  formula_y <- as.formula(paste(y_bin, "~", m, "+", x_cont, "+", paste(covars_with_dx, collapse = "+"), "+ (1 | PTID)"))

  model.m <- lme4::lmer(formula_m, data = dat_h1,
                        control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  model.y <- lme4::glmer(formula_y, data = dat_h1, family = binomial,
                         control = lme4::glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  
  ## print model summaries
  cat("\nMediator model:\n")
  print(summary(model.m))
  cat("\nOutcome model:\n")
  print(summary(model.y))
  
  ## Manual mediation via simulation of fixed effects
  set.seed(123)
  sims.m <- arm::sim(model.m, n.sims = 5000)
  sims.y <- arm::sim(model.y, n.sims = 5000)

  a.sim   <- sims.m@fixef[, x_cont]
  b.sim   <- sims.y@fixef[, m]
  cp.sim  <- sims.y@fixef[, x_cont]
  ab.sim  <- a.sim * b.sim
  total.sim <- ab.sim + cp.sim
  prop.med  <- ab.sim / total.sim

  result <- data.frame(
    Mediator = m,
    N = n_used,
    ACME = mean(ab.sim),
    ACME_lower = stats::quantile(ab.sim, 0.025),
    ACME_upper = stats::quantile(ab.sim, 0.975),
    ADE = mean(cp.sim),
    ADE_lower = stats::quantile(cp.sim, 0.025),
    ADE_upper = stats::quantile(cp.sim, 0.975),
    Total_Effect = mean(total.sim),
    Total_lower = stats::quantile(total.sim, 0.025),
    Total_upper = stats::quantile(total.sim, 0.975),
    Proportion_Mediated = mean(prop.med, na.rm = TRUE)
  )

  print(result)
  results_list_H1_logi[[m]] <- result
}
```

### continuous

```{r H1 longitudinal continuous}
results_list_H1_cont <- list()

for (m in fc_vars) {
  cat("\n## H1 Longitudinal: Amyloid ->", m, "-> Apathy (NPIGTOT_z)\n")

  vars_needed <- c(x_cont, y_cont, m, covars_with_dx, "PTID")
  dat_h1 <- dat[complete.cases(dat[, vars_needed]), ]
  N_used <- nrow(dat_h1); n_ids <- dplyr::n_distinct(dat_h1$PTID)
  cat("Rows used:", N_used, " | Unique PTID:", n_ids, "\n")

  model.m <- lme4::lmer(as.formula(paste(m, "~", x_cont, "+", paste(covars_with_dx, collapse = "+"), "+ (1 | PTID)")),
                        data = dat_h1,
                        control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  model.y <- lme4::lmer(as.formula(paste(y_cont, "~", m, "+", x_cont, "+", paste(covars_with_dx, collapse = "+"), "+ (1 | PTID)")),
                        data = dat_h1,
                        control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  ## print model summaries
  cat("\nMediator model:\n")
  print(summary(model.m))
  cat("\nOutcome model:\n")
  print(summary(model.y))
  
  ## manual mediation via simulation
  set.seed(123)
  sims.m <- arm::sim(model.m, n.sims = 5000)
  sims.y <- arm::sim(model.y, n.sims = 5000)

  a.sim   <- sims.m@fixef[, x_cont]
  b.sim   <- sims.y@fixef[, m]
  cp.sim  <- sims.y@fixef[, x_cont]
  ab.sim  <- a.sim * b.sim
  total.sim <- ab.sim + cp.sim
  prop.med  <- ab.sim / total.sim

  result <- data.frame(
    Mediator = m,
    N = N_used,
    ACME = mean(ab.sim),
    ACME_lower = stats::quantile(ab.sim, 0.025),
    ACME_upper = stats::quantile(ab.sim, 0.975),
    ADE = mean(cp.sim),
    ADE_lower = stats::quantile(cp.sim, 0.025),
    ADE_upper = stats::quantile(cp.sim, 0.975),
    Total_Effect = mean(total.sim),
    Total_lower = stats::quantile(total.sim, 0.025),
    Total_upper = stats::quantile(total.sim, 0.975),
    Proportion_Mediated = mean(prop.med, na.rm = TRUE)
  )

  print(result)
  results_list_H1_cont[[m]] <- result
}
```

### table

```{r H1 table, collapse=TRUE}
# baseline
mediation_table_H1_base <- dplyr::bind_rows(results_list_H1_baseline) %>%
  dplyr::mutate(
    `ACME [95% CI]`        = sprintf("%.2f [%.2f, %.2f]", ACME, ACME_lower, ACME_upper),
    `ADE [95% CI]`         = sprintf("%.2f [%.2f, %.2f]", ADE, ADE_lower, ADE_upper),
    `Total Effect [95% CI]`= sprintf("%.2f [%.2f, %.2f]", Total_Effect, Total_lower, Total_upper),
    `Proportion Mediated`  = sprintf("%.2f", Proportion_Mediated)
  ) %>%
  dplyr::select(Mediator, N, `ACME [95% CI]`, `ADE [95% CI]`, `Total Effect [95% CI]`, `Proportion Mediated`) %>%
  dplyr::rename(`Mediator (FC)` = Mediator, `Sample Size (n)` = N)

knitr::kable(mediation_table_H1_base,
             caption = "H1 Baseline Mediation – Amyloid -> FC -> Apathy (NPIG)")

# longitudinal (binary apathy)
h1_summary_df <- dplyr::bind_rows(results_list_H1_logi) %>%
  dplyr::mutate(
    `ACME [95% CI]`        = sprintf("%.2f [%.2f, %.2f]", ACME, ACME_lower, ACME_upper),
    `ADE [95% CI]`         = sprintf("%.2f [%.2f, %.2f]", ADE, ADE_lower, ADE_upper),
    `Total Effect [95% CI]`= sprintf("%.2f [%.2f, %.2f]", Total_Effect, Total_lower, Total_upper),
    `Proportion Mediated`  = sprintf("%.2f", Proportion_Mediated)
  ) %>%
  dplyr::select(Mediator, N, `ACME [95% CI]`, `ADE [95% CI]`, `Total Effect [95% CI]`, `Proportion Mediated`) %>%
  dplyr::rename(`Mediator (FC)` = Mediator, `Sample Size (n)` = N)

knitr::kable(h1_summary_df,
             caption = "H1 Longitudinal Mediation – Amyloid -> FC -> Apathy (NPIG)")

# longitudinal (continuous apathy)
mediation_table_H1_long <- dplyr::bind_rows(results_list_H1_cont) %>%
  dplyr::mutate(
    `ACME [95% CI]`        = sprintf("%.2f [%.2f, %.2f]", ACME, ACME_lower, ACME_upper),
    `ADE [95% CI]`         = sprintf("%.2f [%.2f, %.2f]", ADE, ADE_lower, ADE_upper),
    `Total Effect [95% CI]`= sprintf("%.2f [%.2f, %.2f]", Total_Effect, Total_lower, Total_upper),
    `Proportion Mediated`  = sprintf("%.2f", Proportion_Mediated)
  ) %>%
  dplyr::select(`Mediator (FC)` = Mediator,
                `Sample Size (n)` = N,
                `ACME [95% CI]`, `ADE [95% CI]`,
                `Total Effect [95% CI]`, `Proportion Mediated`)

knitr::kable(mediation_table_H1_long,
             caption = "H1 Longitudinal Mediation – Amyloid -> FC -> Apathy (NPIGTOT_z)")
```

## H2

### baseline

```{r H2 baseline, collapse=TRUE}
## H2 Baseline (Binary Apathy)
results_list_H2_baseline <- list()
pvals_H2_base <- c()

for (m in fc_vars) {
  dat_b <- baseline[complete.cases(baseline[, c(x_bin, y_bin, m, covars_with_dx)]), ]
  n_used <- nrow(dat_b)
  
  fit <- glm(
    as.formula(paste(y_bin, "~", m, "*", x_bin, "+", paste(covars_with_dx, collapse = "+"))),
    data = dat_b, family = binomial
  )
  
  print(summary(fit))
  
  term <- paste0(m, ":", x_bin)
  ct   <- coef(summary(fit))
  
  if (!term %in% rownames(ct)) {
    est <- se <- z <- pval <- or <- lcl <- ucl <- NA_real_
  } else {
    est  <- ct[term, "Estimate"]
    se   <- ct[term, "Std. Error"]
    z    <- ct[term, "z value"]
    pval <- ct[term, "Pr(>|z|)"]
    or   <- exp(est)
    lcl  <- exp(est - 1.96 * se)
    ucl  <- exp(est + 1.96 * se)
  }

  pvals_H2_base <- c(pvals_H2_base, pval)

  results_list_H2_baseline[[m]] <- data.frame(
    Mediator = m, N = n_used, Estimate = est, SE = se, z = z, `p-value` = pval,
    OR = or, OR_low = lcl, OR_high = ucl,
    Model = "Baseline (WITH DX.new)", conv_warn = FALSE, check.names = FALSE
  )
}

fdr_H2_base <- p.adjust(pvals_H2_base, method = "fdr")
df_H2_base <- bind_rows(results_list_H2_baseline) %>%
  mutate(`FDR-adjusted p` = sprintf("%.3f", fdr_H2_base[Mediator]))
```

### longitudinal

```{r H2 longitudinal: binary apathy with or without DX.new, collapse=TRUE}
fit_h2_bin <- function(mediator, include_dx = TRUE) {
  covs <- if (include_dx) covars_with_dx else covars_no_dx
  needed <- c(x_bin, y_bin, mediator, covs, "PTID")
  d <- dat[complete.cases(dat[, needed]), ]
  
  form <- as.formula(
    paste0(y_bin, " ~ ", mediator, " * ", x_bin, " + ",
           paste(covs, collapse = " + "), " + (1 | PTID)")
  )
  
  fit <- glmer(form, data = d, family = binomial,
               control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  
  sm <- summary(fit)
  print(sm)  
  
  term <- paste0(mediator, ":", x_bin)
  ct <- coef(sm)
  
  tibble(
    Mediator = mediator, N = nrow(d),
    Estimate = ct[term, "Estimate"], SE = ct[term, "Std. Error"],
    z = ct[term, "z value"], p = ct[term, "Pr(>|z|)"],
    Model = ifelse(include_dx, "Longitudinal Binary (WITH DX.new)", "Longitudinal Binary (NO DX.new)"),
    conv_warn = !is.null(sm$optinfo$conv$lme4$messages)
  )
}

tab_h2_bin <- bind_rows(
  bind_rows(lapply(fc_vars, fit_h2_bin, include_dx = TRUE)),
  bind_rows(lapply(fc_vars, fit_h2_bin, include_dx = FALSE))
) %>%
  group_by(Model) %>%
  mutate(`FDR (within model set)` = p.adjust(p, method = "fdr")) %>%
  ungroup()
```

### continuous

```{r H2 continuous, collapse =TRUE}
fit_h2_cont <- function(mediator, include_dx = TRUE) {
  covs <- if (include_dx) covars_with_dx else covars_no_dx
  needed <- c(x_cont, y_cont, mediator, covs, "PTID")
  d <- dat[complete.cases(dat[, needed]), ]
  
  form <- as.formula(
    paste0(y_cont, " ~ ", mediator, " * ", x_cont, " + ",
           paste(covs, collapse = " + "), " + (1 | PTID)")
  )
  
  fit <- lmer(form, data = d,
              control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)))
  
  sm <- summary(fit)
  print(sm)
  
  term <- paste0(mediator, ":", x_cont)
  ct <- coef(sm)
  
  tibble(
    Mediator = mediator, N = nrow(d),
    Estimate = ct[term, "Estimate"], SE = ct[term, "Std. Error"],
    t = ct[term, "t value"], p = ct[term, "Pr(>|t|)"],
    Model = ifelse(include_dx, "Longitudinal Continuous (WITH DX.new)", "Longitudinal Continuous (NO DX.new)"),
    conv_warn = !is.null(sm$optinfo$conv$lme4$messages)
  )
}

tab_h2_cont <- bind_rows(
  bind_rows(lapply(fc_vars, fit_h2_cont, include_dx = TRUE)),
  bind_rows(lapply(fc_vars, fit_h2_cont, include_dx = FALSE))
) %>%
  group_by(Model) %>%
  mutate(`FDR (within model set)` = p.adjust(p, method = "fdr")) %>%
  ungroup()
```

### table

```{r H2 table, collapse=TRUE}
safe_select <- function(df, cols) {
  dplyr::select(df, any_of(cols))
}

# baseline
df_H2_base_final <- df_H2_base %>%
  safe_select(c("Mediator", "Estimate", "SE", "z", "p-value", "FDR-adjusted p", 
                "OR", "OR_low", "OR_high")) %>%
  mutate(across(where(is.numeric), ~ signif(., 6)))

# longitudinal binary
tab_h2_bin_final <- tab_h2 %>%
  safe_select(c("Mediator", "Estimate", "SE", "z", "p", "conv_warn", "Model", 
                "FDR (within model set)")) %>%
  rename(`p-value` = p,
         `FDR-adjusted p` = `FDR (within model set)`) %>%
  mutate(across(where(is.numeric), ~ signif(., 6)))

# longitudinal continuous (matching binary style)
tab_h2_cont_final <- tab_h2_cont %>%
  safe_select(c("Mediator", "Estimate", "SE", "t", "p", "conv_warn", "Model", 
                "FDR (within model set)")) %>%
  rename(`p-value` = p,
         `FDR-adjusted p` = `FDR (within model set)`) %>%
  mutate(across(where(is.numeric), ~ signif(., 6)))

# print all three
knitr::kable(df_H2_base_final, caption = "H2 Baseline Interaction", digits = 6)
knitr::kable(tab_h2_bin_final, caption = "H2 Longitudinal Interaction – Binary Apathy (NPIG)", digits = 6)
knitr::kable(tab_h2_cont_final, caption = "H2 Longitudinal Interaction – Continuous Apathy (NPIGTOT_z)", digits = 6)
```

```{r H2 visualisations, collapse=TRUE}
if (!exists("df_H2_long_bin") && exists("tab_h2")) {
  df_H2_long_bin <- tab_h2
}

# 1) Forest plot of interaction ORs for longitudinal binary models
or_df <- df_H2_long_bin %>%
  mutate(
    OR     = exp(Estimate),
    OR_low = exp(Estimate - 1.96 * SE),
    OR_high= exp(Estimate + 1.96 * SE)
  )

ggplot(or_df, aes(x = Mediator, y = OR, ymin = OR_low, ymax = OR_high, shape = Model)) +
  geom_pointrange(position = position_dodge(width = 0.4)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Interaction OR: FC × Amyloid (Binary Apathy)",
       y = "Odds Ratio (interaction term)", x = "")

# 2)
# Fit DMN_z x Amyloid_z lmer and plot (this is the only significant H2 result)
needed_cont <- c(x_cont, y_cont, "DMN_z", covars_with_dx, "PTID")
d_use       <- dat[complete.cases(dat[, needed_cont]), ]

fit_DMN_cont <- lmer(
  as.formula(paste0(
    y_cont, " ~ DMN_z * ", x_cont, " + ",
    paste(covars_with_dx, collapse = " + "),
    " + (1 | PTID)"
  )),
  data = d_use,
  control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6))
)

cat("\n--- DMN_z x Amyloid_z (Continuous NPIGTOT_z) model summary ---\n")
print(summary(fit_DMN_cont))

# sjPlot (continuous NPIGTOT_z): DMN_z x Amyloid_z
plot_model(
  fit_DMN_cont,
  type  = "pred",
  terms = c("DMN_z", paste0(x_cont, "[-1,0,1]")),
  title = "Predicted NPIGTOT_z by DMN_z × Amyloid_z (sjPlot, Continuous)"
) + theme_minimal()
```

## H3

### baseline

```{r H3 baseline, collapse=TRUE}
results_list_H3_base <- list()
covars_str <- paste(covars_with_dx, collapse = " + ")

for (m in fc_vars) {
  for (y in nps_vars) {
    cat("\n# H3 Baseline: Amyloid ->", m, "->", y, "\n")
    
    dat_b <- baseline[complete.cases(baseline[, c(x_cont, y, m, covars_with_dx)]), ]
    N_used <- nrow(dat_b)

    model.m <- lm(as.formula(paste(m, "~", x_cont, "+", covars_str)), data = dat_b)
    model.y <- lm(as.formula(paste(y, "~", m, "+", x_cont, "+", covars_str)), data = dat_b)

    set.seed(123)
    med.out <- mediate(model.m, model.y, treat = x_cont, mediator = m,
                       boot = FALSE, sims = 5000)
    out <- summary(med.out)

    results_list_H3_base[[paste(m, y, sep = "_")]] <- data.frame(
      Mediator = m,
      Outcome = y,
      N = N_used,
      ACME = out$d0, ACME_lower = out$d0.ci[1], ACME_upper = out$d0.ci[2],
      ADE = out$z0, ADE_lower = out$z0.ci[1], ADE_upper = out$z0.ci[2],
      Total_Effect = out$tau.coef, Total_lower = out$tau.ci[1], Total_upper = out$tau.ci[2],
      Proportion_Mediated = out$n0
    )
  }
}
```

### longitudinal

```{r H3 longitudinal, collapse=TRUE}
results_list_H3_long_manual <- list()
covars_str <- paste(covars_with_dx, collapse = " + ")

for (m in fc_vars) {
  for (y in nps_vars_z) {
    cat("\n# H3 Longitudinal: Manual Mediation –", m, "->", y, "\n")
    
    dat_l <- dat[complete.cases(dat[, c(x_cont, y, m, covars_with_dx, "PTID")]), ]
    N_used <- nrow(dat_l)

    model.m <- lmer(as.formula(paste(m, "~", x_cont, "+", covars_str, "+ (1 | PTID)")), data = dat_l)
    model.y <- lmer(as.formula(paste(y, "~", m, "+", x_cont, "+", covars_str, "+ (1 | PTID)")), data = dat_l)

    set.seed(123)
    sims.m <- sim(model.m, n.sims = 5000)
    sims.y <- sim(model.y, n.sims = 5000)

    a.sim <- sims.m@fixef[, x_cont]
    b.sim <- sims.y@fixef[, m]
    cp.sim <- sims.y@fixef[, x_cont]
    ab.sim <- a.sim * b.sim
    total.sim <- ab.sim + cp.sim
    prop.med <- ab.sim / total.sim

    results_list_H3_long_manual[[paste(m, y, sep = "_")]] <- data.frame(
      Mediator = m,
      Outcome = y,
      N = N_used,
      ACME = mean(ab.sim), ACME_lower = quantile(ab.sim, 0.025), ACME_upper = quantile(ab.sim, 0.975),
      ADE = mean(cp.sim), ADE_lower = quantile(cp.sim, 0.025), ADE_upper = quantile(cp.sim, 0.975),
      Total_Effect = mean(total.sim), Total_lower = quantile(total.sim, 0.025), Total_upper = quantile(total.sim, 0.975),
      Proportion_Mediated = mean(prop.med, na.rm = TRUE)
    )
  }
}
```

### table

```{r H3 table, collapse=TRUE}
# make sure we always use dplyr's verbs here
df_H3_base <- dplyr::bind_rows(results_list_H3_base) |>
  dplyr::mutate(
    `ACME [95% CI]`        = sprintf("%.2f [%.2f, %.2f]", ACME, ACME_lower, ACME_upper),
    `ADE [95% CI]`         = sprintf("%.2f [%.2f, %.2f]", ADE, ADE_lower, ADE_upper),
    `Total Effect [95% CI]`= sprintf("%.2f [%.2f, %.2f]", Total_Effect, Total_lower, Total_upper),
    `Proportion Mediated`  = sprintf("%.2f", Proportion_Mediated)
  ) |>
  dplyr::select(
    `Mediator (FC)` = Mediator,
    `NPS Outcome`   = Outcome,
    N,
    `ACME [95% CI]`,
    `ADE [95% CI]`,
    `Total Effect [95% CI]`,
    `Proportion Mediated`
  )

knitr::kable(df_H3_base,
             caption = "H3 Baseline Mediation – Amyloid -> FC -> NPS Domains")


df_H3_long_manual <- dplyr::bind_rows(results_list_H3_long_manual) |>
  dplyr::mutate(
    `ACME [95% CI]`        = sprintf("%.2f [%.2f, %.2f]", ACME, ACME_lower, ACME_upper),
    `ADE [95% CI]`         = sprintf("%.2f [%.2f, %.2f]", ADE, ADE_lower, ADE_upper),
    `Total Effect [95% CI]`= sprintf("%.2f [%.2f, %.2f]", Total_Effect, Total_lower, Total_upper),
    `Proportion Mediated`  = sprintf("%.2f", Proportion_Mediated)
  ) |>
  dplyr::select(
    `Mediator (FC)` = Mediator,
    `NPS Outcome`   = Outcome,
    N,
    `ACME [95% CI]`,
    `ADE [95% CI]`,
    `Total Effect [95% CI]`,
    `Proportion Mediated`
  )

knitr::kable(df_H3_long_manual,
             caption = "H3 Longitudinal (Manual Mediation) – Amyloid -> FC -> NPS Domains")

```

