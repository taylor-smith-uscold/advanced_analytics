# Calibrating the Apparatus: Data Quality, Missingness, and Feature Engineering

*Module 4 — technical register. For readers who have debugged a detector before trusting its output.*

---

## 0. The one-paragraph version

Before any model, there is a measurement chain, and it has systematics. Values are missing for reasons that are themselves informative; categorical fields carry no natural metric; timestamps encode cyclical structure that a linear model cannot see; and every quantity you record is a noisy proxy for the thing that actually generated the outcome. Two results organize this module. First, **measurement error in a predictor biases its coefficient toward zero** — regression dilution — so poor instrumentation doesn't merely add noise, it systematically understates effects. Second, **every transformation estimated from data is a model**, and must therefore live inside the cross-validation fold with everything else. Imputation, scaling, target encoding, and outlier trimming all learn parameters; fitting them on the full dataset is the same leakage error in four different costumes.

---

## 1. Look at the data first

Before summary statistics, look at raw records. Not `df.describe()` — actual rows, sorted several ways, and marginal distributions plotted.

What this catches that summaries don't:

- Sentinel values masquerading as data: `-999`, `1900-01-01`, `99999` for unknown income, `0` for missing latitude (which puts customers in the Gulf of Guinea).
- Unit inconsistencies across sources — grams and kilograms in one column after a pipeline merge.
- Truncation and saturation — a pile-up at exactly 100 or 999 means the instrument clipped.
- Timestamp pathologies: timezone mixtures, DST discontinuities, epoch-zero defaults, ingestion time recorded as event time.
- Duplicate rows from retried writes.
- Distribution changes at known dates — a schema migration or tracker change, visible as a step in a daily plot.

**Plot every feature's daily volume and mean against time.** This single diagnostic catches more real problems than any other, because it exposes pipeline breaks, schema changes, and backfills as discontinuities. It is the analytics equivalent of watching a control channel across runs.

---

## 2. Missing data

### The three mechanisms

| Mechanism | Definition | Consequence |
|---|---|---|
| **MCAR** — missing completely at random | Missingness independent of everything | Complete-case analysis unbiased, just less efficient |
| **MAR** — missing at random | Missingness depends only on *observed* variables | Correctable by conditioning on observed data (imputation works) |
| **MNAR** — missing not at random | Missingness depends on the *unobserved* value itself | Not correctable from the data alone; requires assumptions or external information |

The distinction is not decorative. High earners declining to state income is MNAR: the probability of missingness depends on the missing value. No imputation recovers it, because the information required is precisely what's absent. Sensitivity analysis in the style of Module 2, §6 is the honest response — assume a range of plausible offsets and report how conclusions move.

**MCAR is testable in part (Little's test); MAR versus MNAR is not testable from observed data.** You are choosing an assumption, so state it.

### Methods

| Method | Notes |
|---|---|
| **Complete-case deletion** | Unbiased only under MCAR. Discards data fast in wide tables — with 20 features at 5% missing each, over half the rows go |
| **Mean/median imputation** | Fast, and it distorts: shrinks variance, attenuates correlations, creates a spike at the mean |
| **Model-based (MICE, kNN, iterative)** | Preserves relationships far better; standard choice under MAR |
| **Multiple imputation** | Generate $m$ completed datasets, analyze each, pool via Rubin's rules. The only common approach that propagates imputation uncertainty into your standard errors |
| **Native handling** | LightGBM/XGBoost learn a default direction per split. Often the best option for tree models — no imputation needed |

### Missingness is a feature

Add a binary indicator alongside any imputed column. If a field is missing for a reason connected to the outcome — an optional profile field completed only by engaged users — the indicator can outperform the value itself.

This is also a warning: **an unusually predictive missingness indicator often signals leakage.** If `discount_code_is_null` is your top feature, ask what process fills that field and whether it runs before or after the outcome.

### The fold rule

Imputation estimates parameters (means, medians, conditional models) from data. Estimating them on the full dataset leaks the validation set's distribution into training. **Fit imputers inside the CV fold**, same as scalers (Module 6, §7).

---

## 3. Measurement error, and why it's not just noise

Suppose the true predictor is $X^*$ but you observe $X = X^* + u$ with independent noise $u$. The OLS coefficient converges not to $\beta$ but to

$$\beta \cdot \frac{\sigma^2_{X^*}}{\sigma^2_{X^*} + \sigma^2_u}$$

— attenuated toward zero by the reliability ratio. **Noisy measurement doesn't just widen your error bars, it systematically shrinks your estimated effects.** A feature with a real effect can look unimportant purely because it's badly measured.

Three consequences for practice:

1. **Feature importance is confounded with measurement quality.** A well-instrumented mediocre predictor will outrank a poorly-instrumented strong one. This compounds the caution in Module 13.
2. **In multivariate settings the bias is not confined to the noisy variable** — it propagates to correlated regressors, and the sign is not guaranteed.
3. **Improving instrumentation can beat improving models.** If a key feature is measured with 40% noise, fixing the tracker will move your metric more than any hyperparameter search.

Note the relationship to Module 5: attenuation is a shrinkage you didn't choose, on top of the shrinkage you did.

---

## 4. Encoding categorical variables

Categories carry no metric. Any encoding imposes one, and the imposition has consequences.

| Encoding | Mechanism | Watch for |
|---|---|---|
| **One-hot** | Indicator per level | Dimension blowup at high cardinality; interacts badly with L1 (arbitrary level selection) |
| **Ordinal** | Integer per level | Only valid for genuinely ordered levels — otherwise you assert a false metric that linear models will use |
| **Target / mean encoding** | Replace level with the mean outcome for that level | **Leakage-prone; see below** |
| **Frequency** | Replace with level frequency | Cheap, sometimes surprisingly effective |
| **Hashing** | Hash to fixed dimension | Collisions; no inverse mapping for debugging |
| **Learned embeddings** | Dense vector per level | Needs volume; useful for very high cardinality |
| **Native categorical** | LightGBM/CatBoost partition levels directly | Usually the best option for trees |

### Target encoding is the canonical leakage machine

Replacing a category with its mean outcome uses the label. Computed naively over the whole training set, each row's encoding contains that row's own label — a level appearing once encodes its own target exactly. The model discovers this and validation looks superb.

Correct implementations require **out-of-fold encoding** (compute a row's encoding from other folds only) plus **smoothing toward the global mean** for rare levels:

$$\tilde y_\ell = \frac{n_\ell \bar y_\ell + m \bar y}{n_\ell + m}$$

which is partial pooling — the same shrinkage that Module 9 develops properly, and the same idea as ridge from Module 5, applied to category means.

**Rule: if target encoding is in your pipeline and you didn't implement the out-of-fold scheme explicitly, assume it's leaking.**

### Unseen levels

Production will present levels absent from training. Decide the policy explicitly — map to an `<UNKNOWN>` bucket present in training, or fall back to the global mean — rather than discovering it as a runtime error.

---

## 5. Feature construction

### Time

Timestamps are among the richest and most commonly wasted fields.

- **Cyclical encoding.** Hour-of-day as an integer tells a linear model that 23 and 0 are maximally distant. Encode as $(\sin 2\pi h/24, \cos 2\pi h/24)$ so the metric wraps. Same for day-of-week, month, day-of-year. Trees can approximate this with splits, but linear and distance-based models cannot.
- **Elapsed time**, not absolute time: days since signup, days since last purchase, tenure. These generalize; a raw date does not.
- **Calendar effects**: holidays, paydays, business-day counts, fiscal periods. Frequently the largest single driver in commercial data.

### Aggregations and windows

Most tabular signal comes from aggregating event histories: count, sum, mean, max, trend, and recency over trailing windows (7/30/90 days). Ratios of short to long windows capture acceleration, which is often more predictive than level.

**Every window must close strictly before the label window opens** (Module 1, §3). Aggregation code is where temporal leakage is most often introduced, because it's easy to write a query that silently includes the present.

### Ratios, interactions, domain transforms

Domain-meaningful ratios (revenue per user, error rate per session, utilization) usually beat their components — they're the dimensionless groups of the problem, and they generalize across scale.

Trees find interactions automatically; linear models don't, so explicit interaction terms matter more there. Log-transform multiplicatively-varying quantities before modeling (Module 5, §2.3).

### Discretization

Binning a continuous variable discards information and is occasionally right: when the relationship is genuinely threshold-like, when you need interpretable buckets for a business rule, or when robustness to outliers matters more than resolution. **Choose cut points from domain knowledge, never from the target** — supervised binning on the full dataset is leakage.

---

## 6. Outliers

"Outlier" is not a property of a point; it's a statement about your model's assumptions. Three cases, three treatments:

| Type | Example | Treatment |
|---|---|---|
| **Error** | Age 300; negative revenue | Fix or remove, and fix the pipeline |
| **Legitimate extreme** | A whale customer | Keep. It's real, and it may be the population that matters most |
| **Different population** | Bot traffic mixed with humans | Segment and model separately |

For heavy-tailed targets — revenue is the standard case — the decision is a modeling one:

- **Winsorize** at a pre-specified percentile; report both capped and uncapped results.
- **Log-transform**, if the target is positive and multiplicative.
- **Robust loss** (Huber, quantile) rather than squared error.
- **Model the tail separately** — a two-part model for zero-inflated and heavy-tailed data.

**Set the rule before seeing results.** Choosing a cap after observing the effect it produces is optimizing against your own measurement (Module 6's recurring theme).

---

## 7. Pipeline discipline

Every step that estimates parameters from data belongs inside the fold:

| Step | Learns from data? | In-fold? |
|---|---|---|
| Scaling | Mean, sd | **Yes** |
| Imputation | Central values, models | **Yes** |
| Target encoding | Category means | **Yes**, out-of-fold |
| Feature selection | Which features | **Yes** |
| PCA / dimensionality reduction | Components | **Yes** |
| Outlier caps | Percentiles | **Yes** |
| Class balancing (SMOTE etc.) | Synthetic points | **Yes** — and only on training folds, never on validation |
| One-hot with a fixed schema | No | Either |
| Log transform | No | Either |
| Domain-defined ratios | No | Either |

The last three are safe because they estimate nothing. Everything above them must be a fitted transformer inside a `Pipeline`.

**Balancing deserves a specific warning.** Oversampling before splitting places synthetic copies of training rows into the validation set, and near-duplicates across the split produce spectacular, fake scores. Balance the training fold only — and note that for well-calibrated probability models, balancing is often unnecessary; adjusting the decision threshold (Module 7, §5) usually serves better.

---

## 8. Failure modes

| Symptom | Likely cause |
|---|---|
| One feature dominates implausibly | Leakage — check when the field is populated relative to the outcome |
| CV excellent, production poor | In-fold rule violated somewhere, or training-serving skew |
| Model degrades sharply on a specific date | Schema change or tracker break; check daily volume plots |
| Coefficients smaller than domain knowledge suggests | Attenuation from measurement error |
| Bimodal or spiky feature distribution | Sentinel values, or two populations merged |
| Rare categories with extreme target means | Unsmoothed target encoding |
| Model fails on new categorical levels | No unseen-level policy |
| Weekend/holiday predictions systematically off | Missing calendar features |
| Imputation indicator is a top feature | Informative missingness — or leakage; investigate before celebrating |

---

## 9. Practical recipe

1. **Profile first.** Row counts, null rates, cardinality, min/max, and a daily volume plot per feature.
2. **Hunt sentinels.** Anything suspiciously round, negative where it can't be, or piled up at a boundary.
3. **Classify missingness** as MCAR/MAR/MNAR per column, and write the assumption down.
4. **Add indicators** for meaningful missingness; impute inside the fold.
5. **Choose encodings** by cardinality and model type; use out-of-fold target encoding or don't use it.
6. **Build the timeline explicitly** and verify every aggregation window closes before the label window.
7. **Construct features with domain meaning** — elapsed times, cyclical encodings, ratios, trailing aggregates.
8. **Decide outlier policy in advance**, and report sensitivity to it.
9. **Assemble everything as a fitted pipeline.** If a step learns anything, it goes inside.
10. **Document each feature**: source, definition, availability at inference, refresh cadence, known issues. This document is what makes Module 14's monitoring possible.

---

## 10. Further reading

- Little & Rubin, *Statistical Analysis with Missing Data* — the canonical treatment of MCAR/MAR/MNAR and multiple imputation.
- van Buuren, *Flexible Imputation of Missing Data* — free online, practical, the MICE reference.
- Carroll et al., *Measurement Error in Nonlinear Models* — attenuation and its corrections, if measurement quality is central to your work.
- Micci-Barreca (2001) — the original smoothed target-encoding scheme.
- Zheng & Casari, *Feature Engineering for Machine Learning* — practical breadth on transforms and encodings.
- Google's "Rules of Machine Learning" (Zinkevich) — the production-engineering perspective on features and pipelines; short and unusually candid.
