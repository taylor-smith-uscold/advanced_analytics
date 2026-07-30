# Advanced Analytics — Course Syllabus

*An applied program in statistical learning, machine learning, and decision-oriented analysis.*

---

## Principles

1. Modules are organized around questions analysts are actually asked at work, not around a taxonomy of methods. Nothing is included because it is traditional.
2. Each module is written twice: a technical register for readers with quantitative backgrounds, and a plain-language register for everyone else. Both cover the same arguments and the same failure modes, with different machinery.
3. Every module closes with a table of failure modes, headed *Failure modes* in the technical register and *Warning signs* in the plain-language one. Read across the course, these accumulate into a diagnostic index, which is what people tend to reach for months later when something looks wrong.
4. Causal reasoning is introduced early, because it reframes everything downstream. Analysts who learn prediction first often spend years reading causal claims into correlational models.
5. Each module carries one applied exercise, specified in the tables below. The exercises are written against live company data rather than a teaching dataset, so no data ships with the course: the syllabus supplies the brief, the instructor supplies the dataset and the stakeholder request.

The **Applied exercise** column states what each exercise has to accomplish and what the participant should produce. It is a specification to be instantiated for your organization, not a worksheet to be handed out as written. Scoping the exercises against real requests is part of the preparation for running the course.

---

## Arc I — Getting the question right

These modules cover the work that happens before any model is fit, which is where most failed analyses go wrong.

| # | Module | Core question | Key concepts | Builds on | Applied exercise |
|---|---|---|---|---|---|
| 1 | **Problem Framing & Metric Design** | What decision is this analysis for? | Turning business goals into estimands; label definition and horizon; population selection; proxy metrics and Goodhart's law; cost-benefit framing; when *not* to build a model | — | Take a live stakeholder request; write the decision it serves, the estimand, and the cost of each error type |
| 2 | **Causal Inference** | Will this *work*, or does it just *correlate*? | Potential outcomes; identification vs estimation; DAGs; confounders, mediators, colliders; backdoor criterion; Simpson's paradox; matching, IPW, doubly robust; DiD, RDD, IV, synthetic control; sensitivity analysis | 1 | Re-analyze an existing "X drives Y" internal finding; draw the DAG and state what would have to be true |
| 3 | **Experimentation & A/B Testing** | How do we run a test we can trust? | Randomization units; power and MDE; the peeking problem; multiple comparisons; CUPED and variance reduction; interference and SUTVA; sample ratio mismatch; ITT vs per-protocol; the winner's curse | 2 | Design and power a real proposed test; write the pre-registration before it launches |

## Arc II — Getting the model right

The core statistical-learning material, running from data preparation through validation and reporting.

| # | Module | Core question | Key concepts | Builds on | Applied exercise |
|---|---|---|---|---|---|
| 4 | **Data Quality, Missingness & Feature Engineering** | Is the data telling me what I think it is? | MCAR/MAR/MNAR; imputation inside the fold; categorical encoding and target-encoding leakage; dates and cyclical features; outliers as a modeling decision; missingness as signal | 1 | Audit a production feature table; document every transform and where it could leak |
| 5 | **Scaling & Regularization** | Why does my model have absurd coefficients? | Units and comparability; conditioning; bias-variance; L1/L2/Elastic Net; penalties as priors and as constraints; why scaling must precede regularization | 4 | Fit a regularized model on a wide internal dataset; plot the coefficient path |
| 6 | **Cross-Validation** | How do I know this will work on new data? | Training-error optimism; k-fold; stratified, grouped, and temporal splits; nested CV; the leakage taxonomy; learning curves | 5 | Rebuild an existing model's validation with the correct split type; compare the two scores |
| 7 | **Evaluating & Reporting Performance** | How good is it, really? | Confusion matrix; accuracy under imbalance; precision/recall; ROC vs PR curves; calibration; cost-based thresholds; uncertainty on metrics | 6 | Re-report an existing model with baseline, curve, operating point, and error bars |
| 8 | **Trees, Bagging & Gradient Boosting** | What should I actually reach for on tabular data? | Splitting criteria; variance reduction by bagging; boosting as sequential error-fitting; out-of-bag error; key hyperparameters; why deep learning rarely wins on tabular data | 5, 6 | Benchmark a boosted model against the current production model, tuned honestly |
| 9 | **Hierarchical Models & Partial Pooling** | How do I estimate per-store/rep/region with thin data? | Complete vs no vs partial pooling; shrinkage as learned regularization; random effects; when small groups should borrow strength | 5 | Produce per-segment estimates for a segment set with wildly uneven sample sizes |
| 10 | **Time Series & Forecasting** | What happens next, and how sure are we? | Trend/seasonality decomposition; stationarity; autocorrelation; backtesting; hierarchical forecasts; why seasonal-naive baselines are hard to beat; prediction intervals | 6 | Backtest a live forecast against a seasonal-naive baseline |
| 11 | **Uncertainty & Inference** | What's the error bar? | Bootstrap; confidence vs prediction intervals; multiple testing (FWER, FDR); conformal prediction for distribution-free coverage | 7 | Add calibrated prediction intervals to an existing point-forecast model |
| 12 | **Unsupervised Methods** | What structure is in here — and is it real? | PCA; k-means and its assumptions; density-based clustering; UMAP/t-SNE and what their distances don't mean; cluster validation and stability | 5 | Stress-test an existing segmentation: does it reproduce on a resample? |

## Arc III — Surviving the business

What happens once a model or an analysis leaves the analyst's hands, and where deployed work tends to fail.

| # | Module | Core question | Key concepts | Builds on | Applied exercise |
|---|---|---|---|---|---|
| 13 | **Interpretability & Explanation** | Why did the model say that? | Coefficients vs importance; permutation importance under correlation; partial dependence and ALE; SHAP and what additivity does and doesn't guarantee; importance ≠ causation | 2, 8 | Explain a production model's decision to a non-technical stakeholder, in writing |
| 14 | **Distribution Shift & Monitoring** | Is it still working? | Covariate shift vs concept drift; training-serving skew; feedback loops and censored outcomes; monitoring, alerting, retraining cadence | 6, 7 | Design the monitoring plan for a model already in production |
| 15 | **Fairness, Privacy & Model Governance** | Should we ship this? | Subgroup performance; competing fairness definitions and their incompatibility; disparate impact; privacy basics; model documentation and risk review | 7 | Write a model card for an existing production model, including subgroup breakdowns |
| 16 | **Communicating Analysis** | Did anyone act on it? | Leading with the decision; conveying uncertainty without hedging into uselessness; visual honesty; pre-empting the questions; writing for people who'll skim | All | Present one of the earlier exercises to a non-technical audience; get critiqued on the framing, not the math |

---

## Optional modules

These are scoped but not yet written. Add them according to the work your teams actually do.

| Module | Add if | Key concepts |
|---|---|---|
| **Survival Analysis** | You model churn, retention, or any time-to-event | Censoring; Kaplan-Meier; Cox models; why flattening to binary classification loses information and biases results |
| **Ranking & Recommenders** | You have a discovery or search surface | NDCG, MAP, MRR; position bias; counterfactual evaluation from logged policies; cold start |
| **Optimization & Decision Models** | You allocate budget, inventory, or staff | Linear and integer programming; constrained allocation; connecting a predictive model to a decision layer |
| **Simulation & Monte Carlo** | Analysts do scenario planning or risk work | Sampling from fitted distributions; propagating uncertainty; sensitivity analysis; when a simulation beats a closed form |
| **Bandits & Adaptive Assignment** | You run many low-stakes experiments continuously | Explore-exploit; Thompson sampling; when bandits are appropriate and when they quietly destroy inference |
| **NLP & LLM Evaluation** | Teams are shipping text or LLM features | Embeddings; evaluation without ground truth; LLM-as-judge and its biases; prompt sensitivity as a variance problem |

---

## Suggested delivery

| Format | Detail |
|---|---|
| **Cadence** | One module per week over 16 weeks, or three intensive blocks by arc |
| **Session shape** | 45 minutes discussing the document, which is pre-read rather than lectured, followed by 45 minutes working the exercise on company data |
| **Registers** | Everyone receives the plain-language version; the technical version is an optional deeper read. Let people choose rather than assigning them a track |
| **Assessment** | The applied exercises, once instantiated on your own data, reviewed by peers. No exams |
| **Capstone** | Take one live business question end to end: frame it, identify the causal structure, design the test or model, validate it honestly, report it with uncertainty, and present it |

---

## Dependency map

```
1 Framing
 └─2 Causal Inference
    └─3 Experimentation
 └─4 Data Quality
    └─5 Scaling & Regularization
       └─6 Cross-Validation
          └─7 Evaluation & Reporting
             ├─8 Trees & Boosting
             ├─10 Time Series
             ├─11 Uncertainty
             ├─13 Interpretability  (also needs 2)
             ├─14 Monitoring
             └─15 Fairness & Governance
       ├─9 Hierarchical Models
       └─12 Unsupervised
16 Communication — runs throughout, assessed at the end
```

---

## Course files

Every module has two documents in the same folder: a technical register, for readers with quantitative backgrounds, and a plain-language register, in which mathematical requirements are minimized. Both cover the same arguments and the same failure modes.

| # | Module | Files |
|---|---|---|
| 01 | Problem Framing & Metric Design | `01-problem-framing-{technical, plain-language}.md` |
| 02 | Causal Inference | `02-causal-inference-{technical, plain-language}.md` |
| 03 | Experimentation & A/B Testing | `03-experimentation-{technical, plain-language}.md` |
| 04 | Data Quality, Missingness & Features | `04-data-quality-features-{technical, plain-language}.md` |
| 05 | Scaling & Regularization | `05-scaling-regularization-{technical, plain-language}.md` |
| 06 | Cross-Validation | `06-cross-validation-{technical, plain-language}.md` |
| 07 | Evaluating & Reporting Performance | `07-model-evaluation-{technical, plain-language}.md` |
| 08 | Trees, Bagging & Gradient Boosting | `08-trees-and-boosting-{technical, plain-language}.md` |
| 09 | Hierarchical Models & Partial Pooling | `09-hierarchical-models-{technical, plain-language}.md` |
| 10 | Time Series & Forecasting | `10-time-series-forecasting-{technical, plain-language}.md` |
| 11 | Uncertainty & Inference | `11-uncertainty-inference-{technical, plain-language}.md` |
| 12 | Unsupervised Methods | `12-unsupervised-methods-{technical, plain-language}.md` |
| 13 | Interpretability & Explanation | `13-interpretability-{technical, plain-language}.md` |
| 14 | Distribution Shift & Monitoring | `14-distribution-shift-monitoring-{technical, plain-language}.md` |
| 15 | Fairness, Privacy & Governance | `15-fairness-privacy-governance-{technical, plain-language}.md` |
| 16 | Communicating Analysis | `16-communicating-analysis-{technical, plain-language}.md` |

### Recurring themes

Five ideas recur across the sixteen modules. Naming them in session is what makes the material cohere into one argument rather than sixteen topics.

- Anything you optimize against stops being a measurement. Test sets (06), peeking at experiments (03), segment fishing (03, 11), choosing an outlier rule after seeing results (04), tuning a threshold on test data (07).
- Anything computed from data belongs inside the fold. Scaling (05), imputation and encoding (04), feature selection (06), class balancing (04).
- Shrinkage appears in four guises. Ridge and lasso (05), leaf-weight penalties in boosting (08), partial pooling (09), and smoothed target encoding (04).
- Prediction is not intervention. Established in 02, reinforced in 13 (importance is not causation) and 14 (feedback loops).
- Assumptions belong in the summary, not the appendix. 02, 11, 15, 16.
