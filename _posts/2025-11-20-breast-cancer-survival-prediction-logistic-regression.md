---
layout: post
title: Prediction of Survival Rate for Breast Cancer Patients
subtitle: Logistic regression, fairness reweighting, and subgroup AUC analysis
cover-img: /assets/img/breast-cancer-cover.png
tags: [Biostatistical Methods, Logistic Regression, Fairness, Breast Cancer]
comments: true
mathjax: true
author: Yixin Zheng
---




## Abstract
Breast cancer is a leading cause of cancer-related mortality among women worldwide. This study develops a predictive model for survival outcomes in breast cancer patients using logistic regression, leveraging demographic, clinical, and pathological factors from a prospective cohort dataset. The analysis focuses on identifying key predictors of mortality, evaluating model performance across racial groups, and addressing fairness in prediction accuracy. Tumor stage, grade, and hormone receptor status emerged as significant predictors. The initial logistic regression model achieved a moderate performance, with an area under the receiver operating characteristic curve (ROC-AUC) of 0.74. However, disparities in model performance were observed between racial groups, prompting the implementation of reweighting strategies to enhance fairness. These findings highlight the importance of equitable modeling approaches to improve prognostic accuracy and clinical outcomes in breast cancer care. 

## Introduction
Breast cancer is highly prevalence with 2.3 million new cases worldwide reported in 2022$^1$. Approximately 13.1 % of female are diagnosed with breast cancer at some point in their lifetime. This type of cancer accounts for 23% of total cancer cases and 14% of cancer deaths$^2$. Advances diagnosis and tailored treatments have reduced mortality rates$3$. Survival of breast cancer depends on various factors including the tumor size, the grade of tumor$^4$, cancer stage, lymph node stages, and socioeconomic and race$^5$. Younger patients often have better outcomes$^6$ while disparities exist for lower-income and African American populations. This report examines data from a prospective cohort of breast cancer patients, which includes variables including demographic, clinical, and pathological factors, aiming to improve outcomes and address disparities.

## Methods

**Data Description** The dataset includes 10 categorical variables: race
(Black, White, Other), marital status (Divorced, Married, Separated,
Single, Widowed), tumor stage (T1, T2, T3, T4), lymph node stage (N1,
N2, N3), adjusted AJCC 6th stage (IIA, IIB, IIIA, IIIB, IIIC), tumor
differentiation (Well, Moderately, Poorly, Undifferentiated), grade
(1–4), tumor spread stage (Regional, Distant), estrogen receptor status
(Positive, Negative), and progesterone receptor status (Positive,
Negative). Additionally, there are 4 continuous variables: age, tumor
size, regional nodes examined, and regional nodes positive.

**Data Cleaning** Column headers were renamed, categorical variables
were converted to factors. tumor grade levels were recoded to ensure
interpretability. Missing values were assessed, and log transformations
were applied to highly skewed continuous variables (tumor size, regional
nodes examined, and regional nodes positive) to normalize their
distributions.



**EDA Methods** `skim()` function is applied to the dataset
(`model_data`) to compute detailed summary statistics for all variables.
(table.1 & 2), Group-wise key statistics are calculated based on
survival status(table.3) Cramér's V was used to quantify the strength of
the association between categorical variables and the binary outcome
(Alive/Dead), with values ranging from 0 (no association) to 1 (perfect
association). Distributional plots, including proportional bar plots for
race groups and histograms for continuous variables, were created to
visualize the data. Boxplots stratified by survival status were used to
explore relationships between continuous variables and the binary
outcome. A correlation matrix for continuous variables was generated to
assess pairwise relationship between variables.





















**Modeling Assumptions and Transformations** Logistic regression was
chosen as the primary method due to the binary nature of the outcome.
Assumptions checked are: 1. The response variable (status) was confirmed
to be binary by code.



2\. The `alias()` function identified collinearity between models:
grade2, grade3, and grade4 with other predictors, x6th_stageIIIC with
n_stage, and differentiate with grade. For simplification, some
variables were removed: x6th_stage captures n_stage's information,
n_stage was dropped. t_stage (linked to tumor size), differentiate
(overlapping with grade), and regional_node_positive (redundant with
tumor size and regional_node_examined) were removed.



VIF were calculated, to ensure that all values were below 5 (table.4),
indicating no multicollinearity. (dataset updated with dropped variable)



3\. Continuous predictors were log-transformed, and their relationships
with the log odds were examined (fig.12). This confirmed linearity.
(dataset updated with transformed variable)



4\. Independence of Errors: Since there were no group-level structures,
the independence assumption was satisfied.





5\. Outliers: Cook's Distance identified potential outliers exceeding
4/n, which flagged numerous points as influential, likely reflecting
population variability rather than errors (fig.12). Models with and
without these points were compared. Removing these points destabilized
coefficients like grade, making them unreliable. Robust logistic
regression (model_robust) mitigated outliers impact, providing stable
estimates for predictors (table.5). About 12% of data had reduced
influence, while most observations are unaffected. Despite its
advantages, we chose the original logistic regression for simplicity and
familiarity.

**Model Construction and Selection** Models were constructed using
predictors identified during EDA and assumption checks. Forward,
backward, and stepwise selection were applied based on the AIC to select
the final model. Interaction effects were tested by examining pairwise interactions between predictors. 

**Model Validation and Fairness** The model was validated using 10-fold
cross-validation, evaluating ROC-AUC, sensitivity, and specificity.
Fairness was assessed by evaluating model performance across racial
subgroups (White, Black, Other) based on subgroup-specific ROC-AUC
values. To address disparities, inverse probability weighting (IPW) was applied: the proportions were computed as the size of each group divided by the total sample size (White: 3413, Other: 320, Black: 291) (table.1). The weights `W` were then derived as follows: $W = \frac{1}{\text{Proportion}}$.The calculated weights were 1.18 for White, 13.89 for Black, and 12.50 for Other. To keep weights manageable, we normalized them such that the maximum weight was scaled to 2, resulting in final weights of 0.17 for White, 2.00 for Black, and 1.80 for Other. The reweighted model's performance was then compared to the original, using subgroup-specific and overall AUC values to assess predictive fairness. Predictor coefficients were interpreted as odds ratios to quantify their impact on survival outcomes.


## Results
**EDA** Cramér’s V analysis identified `x6th_stage`, `n_stage`, and
hormone receptor statuses as the strongest predictors of survival, while
`marital status`, `race`, and `a_stage` showed weaker associations
(fig.1). Bar plots highlight racial disparities, with higher mortality
among Non-White, particularly Black patients, and combining groups
simplifies comparisons (figs.2–3). Histograms revealed significant right
skewness for most continuous variables (except `age`), improved by log
transformations for the other continuous vars (figs.4–5). Boxplots
confirm these patterns (figs.6–10). A correlation matrix showed weak
overall relationships and no multicollinearity, except
`regional_node_positive` is moderately associated with both `tumor size`
(0.24) and `regional nodes examined` (0.41), guiding modeling choices
(fig.11).

**Model Selection and Intepretation**


AIC values differed slightly (Full: 3039.8; Forward: 3039.8; Backward: 3037.5; Stepwise: 3037.5), but all methods yielded the same model. The stepwise model was chosen for its lower AIC (full results attached):
$$Logit(P) = \beta_0 + \beta_1 \times raceBlack + \beta_2 \times raceOther + \ldots + \beta_i \times X_i $$
Where $\beta_i$ and $X_i$(significant predictors) are taken from Table 6, and $Logit(P) = log(\frac{P}{1-P})$, P is the probability of the `status` being 1.



**Interaction Effects** Pairwise interactions between predictors were tested, but none of the interaction terms had p-values below 0.05, consistent with earlier analyses showing weak or absent interaction effects (results attached)





**Model Performance**  Cross-validation (10-fold) revealed an overall ROC-AUC of 0.7400, indicating moderately good performance with an acceptable ability to
distinguish between "Alive" and "Dead" outcomes. The model demonstrated
high sensitivity (0.985), meaning it correctly identifies most of the "Dead" cases, but low specificity (0.122), indicating difficulty in correctly identifying "Alive" cases (full results attached).





The model performance varies across different racial groups.It demonstrates high ROC-AUC for the White group (0.7504), while the lower scores were evaluated for the Black group (0.7021) and Other group (0.6584).When Black and Other groups are combined as a single minority group, the model ROC-AUC improves to 0.7313, though it remains lower than the majority White group.
Reweighting narrowed this gap, increasing the model’s ROC-AUC for the minority group to 0.7358, closer to the White group (0.7486), improving fairness while maintaining accuracy (table.8). The model equation must be adjusted accordingly if the reweighted model is chosen: $$Logit(P) = \beta_0 + \beta_1 \times raceBlack + \ldots + \beta_i \times X_i$$ where $\beta_i$ values are from Table 7, and $X_i$ represents the same significant predictors as in the original stepwise model.

**Key Findings on Coefficients** Tables 6 and 7 present the key predictors and odds ratios from the original stepwise model and the reweighted model, respectively. In both models, race was significant: in the stepwise model, `raceBlack` (OR = 1.615) increased mortality odds by 61.5%, and `raceOther` (OR = 0.651) reduced them by 34.9%, while in the reweighted model, `raceBlack` (OR = 1.423) increased odds by 42.3% and `raceOther` (OR = 0.667) reduced them by 33.3%. `x6th_stage` was the strongest predictor across both models, with odds ratios in the original model (`IIIA`: 2.683, `IIIB`: 4.820, `IIIC`: 7.682) and reweighted model (`IIIA`: 2.505, `IIIB`: 4.163, `IIIC`: 6.255) showing progressively higher mortality risk. Poorly differentiated tumors (`Grade 3` and `Grade 4`) substantially raised mortality odds in both models. Positive hormone receptor status (e.g. estrogen: OR = 0.485 for stepwise; OR = 0.572 for reweighted) was protective. Other predictors, such as lymph nodes examined and age, showed consistent trends, with more nodes examined improving survival and older age increasing mortality risk, though these were non-significant in the reweighted model. Marital status showed no significant associations in either model.

## Conclusion and Limitation
In this study, we developed a logistic regression model to predict the odds of survival for breast cancer patients, selecting the final model using stepwise AIC-based selection. Key predictors included `x6th_stage`, `grade`, `rn_examined_log`, `age_log`, hormone receptor status, and marital status. The most significant predictors were adjusted AJCC 6th stage and tumor grade, consistent with existing literature. Advanced tumor stages (e.g. IIIC: OR = 6.255) and poorly differentiated tumors (e.g. Grade 4: OR = 6.510) were associated with higher mortality odds. Conversely, hormone receptor positive status was protective, reflecting improved outcomes for hormone-sensitive tumors. More regional lymph nodes examined increased survival odds, while older age significantly raised mortality risk. 
Racial disparities were evident, with Black patients facing higher odds of death compared to White patients (stepwise OR = 1.615; reweighted OR = 1.423) and patients in the "Other" category showing lower odds (stepwise OR = 0.651; reweighted OR = 0.667). 
Reweighting improved fairness for underrepresented groups, increasing the minority group’s ROC-AUC from 0.7313 to 0.7358 and narrowing the gap with the White group (0.7486). However, it may reduce generalizability to majority-dominant populations and alter predictor importance, requiring careful interpretation. Stepwise selection treated factor levels as independent variables (e.g., `x6th_stageIIIA` as a dummy), potentially excluding some levels and raising interpretability concerns. Marital status was retained in the final model despite weak significance due to its potential theoretical relevance, confounding effects, or fairness considerations. All three aspects—reweighting, factor level treatment, and marital status inclusion—require further research to ensure robustness and interpretability.

## Contribution
All members participated in group discussions, and editing reports.
Ada Guo drafted the abstract, introduction, and results-eda. 
Khue Nguyen analyzed and draft results, conclusion and limitations, refined results structure, add references. 
Yixin Zheng wrote the methods, revise the results, conclusion, limitation,
and constructed the Rmd file(cleaning, correlation matrix, Cramér's V,
assumption checks, feature selection, model, cross-validation, fairness
reweight, appendix).

## Reference
1.	Arnold M, Morgan E, Rumgay H, et al. Current and future burden of breast cancer: Global statistics for 2020 and 2040. Breast Off J Eur Soc Mastology. 2022;66:15-23. doi:10.1016/j.breast.2022.08.010
2.	Cao SS, Lu CT. Recent perspectives of breast cancer prognosis and predictive factors. Oncol Lett. 2016;12(5):3674-3678. doi:10.3892/ol.2016.5149
3.	Cancer of the Breast (Female) - Cancer Stat Facts. SEER. Accessed December 19, 2024. https://seer.cancer.gov/statfacts/html/breast.html
4.	Bundred NJ. Prognostic and predictive factors in breast cancer. Cancer Treat Rev. 2001;27(3):137-142. doi:10.1053/ctrv.2000.0207
5.	Soerjomataram I, Louwman MWJ, Ribot JG, Roukema JA, Coebergh JWW. An overview of prognostic factors for long-term survivors of breast cancer. Breast Cancer Res Treat. 2008;107(3):309-330. doi:10.1007/s10549-007-9556-1
6.	Phung MT, Tin Tin S, Elwood JM. Prognostic models for breast cancer: a systematic review. BMC Cancer. 2019;19(1):230. doi:10.1186/s12885-019-5442-6


## Table, Plots, and Code Results

### Tables


Table: Skim Summary for Categorical Variables

|skim_variable       | n_missing| complete_rate|factor.ordered | factor.n_unique|factor.top_counts                         |
|:-------------------|---------:|-------------:|:--------------|---------------:|:-----------------------------------------|
|race                |         0|             1|FALSE          |               3|Whi: 3413, Oth: 320, Bla: 291             |
|marital_status      |         0|             1|FALSE          |               5|Mar: 2643, Sin: 615, Div: 486, Wid: 235   |
|t_stage             |         0|             1|FALSE          |               4|T2: 1786, T1: 1603, T3: 533, T4: 102      |
|n_stage             |         0|             1|FALSE          |               3|N1: 2732, N2: 820, N3: 472                |
|x6th_stage          |         0|             1|FALSE          |               5|IIA: 1305, IIB: 1130, III: 1050, III: 472 |
|differentiate       |         0|             1|FALSE          |               4|Mod: 2351, Poo: 1111, Wel: 543, Und: 19   |
|grade               |         0|             1|FALSE          |               4|2: 2351, 3: 1111, 1: 543, 4: 19           |
|a_stage             |         0|             1|FALSE          |               2|Reg: 3932, Dis: 92                        |
|estrogen_status     |         0|             1|FALSE          |               2|Pos: 3755, Neg: 269                       |
|progesterone_status |         0|             1|FALSE          |               2|Pos: 3326, Neg: 698                       |
|status              |         0|             1|FALSE          |               2|Ali: 3408, Dea: 616                       |



Table: Skim Summary for Numeric Variables

|skim_variable          | n_missing| complete_rate|      mean|        sd| p0| p25| p50| p75| p100|hist  |
|:----------------------|---------:|-------------:|---------:|---------:|--:|---:|---:|---:|----:|:-----|
|age                    |         0|             1| 53.972167|  8.963134| 30|  47|  54|  61|   69|▁▃▇▇▇ |
|tumor_size             |         0|             1| 30.473658| 21.119696|  1|  16|  25|  38|  140|▇▃▁▁▁ |
|regional_node_examined |         0|             1| 14.357107|  8.099675|  1|   9|  14|  19|   61|▇▇▁▁▁ |
|reginol_node_positive  |         0|             1|  4.158052|  5.109331|  1|   1|   2|   5|   46|▇▁▁▁▁ |



Table: Summary Statistics Grouped by Survival Status

|status | mean_age|   sd_age| mean_tumor_size| sd_tumor_size| prop_white| prop_black_other| n_obs|
|:------|--------:|--------:|---------------:|-------------:|----------:|----------------:|-----:|
|Alive  | 53.75910| 8.808420|        29.26878|      20.30317|  0.8518192|        0.1481808|  3408|
|Dead   | 55.15097| 9.698291|        37.13961|      24.11611|  0.8279221|        0.1720779|   616|



Table: Variance Inflation Factors for Predictors

|Variable               |     GVIF| Df| GVIF_Ratio|
|:----------------------|--------:|--:|----------:|
|age                    | 1.106908|  1|   1.052097|
|race                   | 1.058083|  2|   1.014215|
|marital_status         | 1.127489|  4|   1.015112|
|x6th_stage             | 1.967732|  4|   1.088293|
|grade                  | 1.118473|  3|   1.018836|
|a_stage                | 1.210950|  1|   1.100432|
|tumor_size             | 1.365304|  1|   1.168462|
|estrogen_status        | 1.484914|  1|   1.218570|
|progesterone_status    | 1.434692|  1|   1.197786|
|regional_node_examined | 1.225729|  1|   1.107127|



Table: Unstable Coefficients

|Variable    |  Full_Coef|   Full_SE| No_Outliers_Coef| No_Outliers_SE| Robust_Coef| Robust_SE|
|:-----------|----------:|---------:|----------------:|--------------:|-----------:|---------:|
|(Intercept) | -5.8924387| 1.3069930|       -30.590617|    438.7266805|  -5.0273109| 1.3799307|
|raceOther   | -0.4272352| 0.2010365|        -2.877142|      0.7253748|  -0.5745467| 0.2281736|
|grade2      |  0.5309961| 0.1831397|        16.658587|    438.7223333|   0.4079614| 0.1935342|
|grade3      |  0.9060030| 0.1917058|        17.208447|    438.7223392|   0.7801358| 0.2013946|
|grade4      |  1.8504135| 0.5421565|        17.639998|    438.7259010|   1.6966710| 0.5472605|



Table: Stepwise Model Results

|Predictor                   | Estimate| Std_Error| Odds_Ratio| X95..CI..Lower.| X95..CI..Upper.|P.Value  |
|:---------------------------|--------:|---------:|----------:|---------------:|---------------:|:--------|
|(Intercept)                 |   -5.540|     1.236|      0.004|           0.000|           0.044|7.38e-06 |
|raceBlack                   |    0.480|     0.160|      1.615|           1.180|           2.212|0.002794 |
|raceOther                   |   -0.429|     0.201|      0.651|           0.439|           0.965|0.032767 |
|marital_statusMarried       |   -0.226|     0.140|      0.798|           0.607|           1.050|0.106502 |
|marital_statusSeparated     |    0.684|     0.381|      1.983|           0.940|           4.181|0.072218 |
|marital_statusSingle        |   -0.036|     0.173|      0.965|           0.688|           1.354|0.836915 |
|marital_statusWidowed       |    0.032|     0.218|      1.033|           0.673|           1.584|0.882727 |
|x6th_stageIIB               |    0.523|     0.144|      1.688|           1.273|           2.238|0.000278 |
|x6th_stageIIIA              |    0.987|     0.141|      2.683|           2.035|           3.539|2.71e-12 |
|x6th_stageIIIB              |    1.573|     0.302|      4.820|           2.667|           8.714|1.92e-07 |
|x6th_stageIIIC              |    2.039|     0.161|      7.682|           5.607|          10.526|< 2e-16  |
|grade2                      |    0.533|     0.183|      1.703|           1.190|           2.438|0.003610 |
|grade3                      |    0.911|     0.192|      2.486|           1.708|           3.618|1.99e-06 |
|grade4                      |    1.873|     0.542|      6.510|           2.251|          18.828|0.000546 |
|estrogen_statusPositive     |   -0.723|     0.175|      0.485|           0.344|           0.684|3.76e-05 |
|progesterone_statusPositive |   -0.568|     0.127|      0.567|           0.442|           0.726|7.27e-06 |
|rn_examined_log             |   -0.298|     0.080|      0.742|           0.634|           0.868|0.000193 |
|age_log                     |    1.096|     0.294|      2.992|           1.682|           5.321|0.000192 |



Table: Reweighted Logistic Regression Model Results

|Predictor                   | Estimate| Std_Error| Odds_Ratio| X95..CI..Lower.| X95..CI..Upper.|   P.Value|
|:---------------------------|--------:|---------:|----------:|---------------:|---------------:|---------:|
|(Intercept)                 |   -4.065|     1.775|      0.017|           0.001|           0.556| 0.0220000|
|raceBlack                   |    0.353|     0.166|      1.423|           1.027|           1.971| 0.0337700|
|raceOther                   |   -0.405|     0.189|      0.667|           0.460|           0.967| 0.0324200|
|marital_statusMarried       |   -0.328|     0.222|      0.720|           0.466|           1.113| 0.1397100|
|marital_statusSeparated     |    0.820|     0.474|      2.270|           0.896|           5.748| 0.0838600|
|`marital_statusSingle `     |    0.418|     0.243|      1.519|           0.944|           2.443| 0.0850800|
|marital_statusWidowed       |    0.427|     0.301|      1.533|           0.850|           2.766| 0.1560400|
|x6th_stageIIB               |    0.516|     0.209|      1.675|           1.113|           2.522| 0.0133900|
|x6th_stageIIIA              |    0.918|     0.206|      2.505|           1.672|           3.754| 0.0000086|
|x6th_stageIIIB              |    1.426|     0.449|      4.163|           1.727|          10.032| 0.0014800|
|x6th_stageIIIC              |    1.833|     0.234|      6.255|           3.956|           9.889| 0.0000000|
|grade2                      |    0.389|     0.263|      1.476|           0.881|           2.472| 0.1395800|
|grade3                      |    0.656|     0.274|      1.926|           1.126|           3.295| 0.0167000|
|grade4                      |    1.626|     0.826|      5.081|           1.007|          25.647| 0.0490700|
|estrogen_statusPositive     |   -0.559|     0.258|      0.572|           0.345|           0.947| 0.0300200|
|progesterone_statusPositive |   -0.288|     0.197|      0.750|           0.509|           1.104| 0.1449600|
|rn_examined_log             |   -0.172|     0.121|      0.842|           0.665|           1.067| 0.1551800|
|age_log                     |    0.607|     0.418|      1.835|           0.808|           4.164| 0.1467700|



Table: Comparison of ROC-AUC Values Across Models and Racial Groups

|Model Type |  White|  Black|  Other| Minority|
|:----------|------:|------:|------:|--------:|
|Original   | 0.7504| 0.7021| 0.6584|   0.7313|
|Reweighted | 0.7302| 0.7189| 0.6962|   0.7526|


### Plots

![Cramér's V Associations](/assets/reports/biostat-1-breast-cancer/plots/cramerV_association.png)

![Survival Status by Race](/assets/reports/biostat-1-breast-cancer/plots/race_proportional_barplot.png)

![Survival Status by Combined Race
Groups](/assets/reports/biostat-1-breast-cancer/plots/race_combined_proportional_barplot.png)

![Histograms for Original Continuous
Variables](/assets/reports/biostat-1-breast-cancer/plots/original_histograms_grid.png)

![Histograms for Log-Transformed Continuous
Variables](/assets/reports/biostat-1-breast-cancer/plots/log_transformed_histograms_grid.png)

![Age by Survival Status](/assets/reports/biostat-1-breast-cancer/plots/age_by_status_boxplot.png)

![Tumor Size by Survival Status](/assets/reports/biostat-1-breast-cancer/plots/tumor_size_by_status_boxplot.png)

![Tumor Size by Race and Survival
Status](/assets/reports/biostat-1-breast-cancer/plots/tumor_size_by_race_status_boxplot.png)

![Regional Node Examined by Survival
Status](/assets/reports/biostat-1-breast-cancer/plots/rn_examined_by_status_boxplot.png)

![Regional Node Positive by Survival
Status](/assets/reports/biostat-1-breast-cancer/plots/rn_positive_by_status_boxplot.png)

![Correlation Matrix for Continuous
Variables](/assets/reports/biostat-1-breast-cancer/plots/correlation_matrix_plot.png)

![Log Odds Relationship with Predictors](/assets/reports/biostat-1-breast-cancer/plots/logit_grid_plot.png)

![Cook's Distance for Outlier Detection](/assets/reports/biostat-1-breast-cancer/plots/cooks_distance_plot.png)


### Code Results

For full code results, please refer to the `.txt` files available in the
`results` folder of the GitHub repository: https://github.com/Yixin-Zheng/p8130_finalproject.
