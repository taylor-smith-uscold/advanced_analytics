# Estimating What You Can't Measure Directly: Cross-Validation

*Module 6 — technical register. For readers comfortable with resampling, systematic errors, and blind analysis.*

---

## 0. The one-paragraph version

The quantity you care about — how well your model will do on data it has never seen — is not observable. You have one finite sample, and any performance number computed on data the model was fitted to is biased optimistically, because the fit has already absorbed that data's noise. **Cross-validation** is a resampling scheme that estimates the unobservable quantity by repeatedly hiding part of your data from the fitting procedure and measuring what happens. It is the same move as the jackknife or the bootstrap in error analysis: use the internal structure of one sample to estimate a property of the population. The whole subject is about doing that honestly, which mostly means being disciplined about what the model was allowed to see and when.

---

## 1. The quantity of interest

Let $\hat f$ be a model fitted on a training set $\mathcal{T}$. Define:

**Training error** — average loss over $\mathcal{T}$ itself.

**Generalization error** — expected loss on a fresh draw from the same distribution:
$$\mathrm{Err} = \mathbb{E}_{(x,y)\sim P}\big[L\big(y, \hat f(x)\big)\big].$$

Training error is a downward-biased estimate of $\mathrm{Err}$, and the bias grows with model flexibility. This is not a subtle effect: a $k$-nearest-neighbour model with $k=1$ has *exactly zero* training error and can be worthless. A polynomial of degree $n-1$ passes exactly through $n$ points.

The gap has a name and a formula. For squared-error loss, the **optimism** of the training error is
$$\mathbb{E}[\mathrm{Err}] - \mathbb{E}[\overline{\mathrm{err}}] = \frac{2}{n}\sum_{i=1}^n \mathrm{Cov}(\hat y_i, y_i).$$

Read that covariance term carefully, because it says exactly what's going on: **optimism is proportional to how much the fitted value at point $i$ responds to the observed value at point $i$.** A model that chases each data point individually is heavily optimistic. A rigid model is not. This is why "degrees of freedom" and "overfitting" and "self-influence" are all the same idea wearing different hats — and it's the mechanism regularization defuses.

The practical consequence: you cannot evaluate a model on data used to fit it. Not approximately, not with a correction factor you eyeballed. You need held-out data.

---

## 2. Two different jobs, often conflated

Keep these separate, because the correct procedure differs:

**Model selection** — choosing between candidates. Which regularization strength? Which feature set? Ridge or elastic net? You need *relative* accuracy: the ranking must be right, and a common bias across candidates is tolerable.

**Model assessment** — estimating the performance of your final chosen model, to report. You need *absolute* accuracy, and any optimism goes straight into your published number.

Using the same held-out data for both is the single most common methodological error in applied ML. If you tried 200 hyperparameter settings and reported the best validation score, that number is not an estimate of generalization error — it's the maximum of 200 noisy estimates, and the maximum of noisy estimates is biased high by construction. You have optimized against the noise in your own measurement.

The classical remedy is a **three-way split**:

| Split | Used for | Model sees it? |
|---|---|---|
| Train | Fitting parameters | Yes, directly |
| Validation | Choosing hyperparameters, early stopping | Indirectly, through your choices |
| Test | Final reported number | Once, at the end |

Touch the test set once. If you look at test performance, change something, and look again, it has become a validation set and you no longer have a test set.

---

## 3. Simple hold-out and why it isn't enough

Split off 20–30%, fit on the rest, evaluate. Fast, unbiased in principle, and unusable in practice for small $n$ for two reasons:

**Variance.** With 200 samples, a 20% holdout is 40 points. Your accuracy estimate has a standard error of several percentage points. Two models differing by 3% are indistinguishable, and you'd never know it from a single split.

**Pessimistic bias.** You fitted on 70% of the data, but you'll deploy a model fitted on 100%. Since learning curves are increasing, the holdout estimate systematically understates the final model's performance.

Cross-validation attacks both: reuse every point as test data exactly once, and train on a larger fraction each time.

---

## 4. $k$-fold cross-validation

Partition the data into $k$ roughly equal folds. For each fold $j$: fit on the other $k-1$ folds, evaluate on fold $j$. Average the $k$ scores.

$$\mathrm{CV}_{(k)} = \frac{1}{n}\sum_{i=1}^{n} L\big(y_i, \hat f^{-\kappa(i)}(x_i)\big)$$

where $\kappa(i)$ is the fold containing $i$ and $\hat f^{-\kappa(i)}$ is the model fitted without that fold. Every point contributes exactly once, and it always contributes a genuinely out-of-sample prediction.

### Choosing $k$: a bias–variance trade in its own right

- **Small $k$** (e.g. 2): each fit uses only half the data, so each model is worse than the one you'll deploy — **pessimistic bias**. But the $k$ training sets overlap little, so the averaged estimate has lower variance.
- **Large $k$** (e.g. $k=n$, leave-one-out): each fit uses nearly all the data, so bias is nearly zero. But the $n$ training sets are almost identical, so the $n$ error terms are highly correlated, and averaging correlated quantities buys you much less variance reduction than averaging independent ones. Also: $n$ fits.

$k = 5$ or $10$ is the standard compromise, and the empirical evidence for it is decent. Use $k=10$ when compute allows.

### Leave-one-out has a special property for linear models

For any linear smoother — OLS, ridge, splines — where $\hat y = Hy$ for a hat matrix $H$ that doesn't depend on $y$, leave-one-out error has a **closed form requiring only the single full fit**:

$$\mathrm{CV}_{(n)} = \frac{1}{n}\sum_{i=1}^n \left(\frac{y_i - \hat y_i}{1 - h_{ii}}\right)^2 .$$

This is the PRESS statistic. The diagonal element $h_{ii}$ is the **leverage** of point $i$ — how strongly it pulls its own fitted value. The formula says: inflate each residual by a factor that accounts for how much the point flattered itself. High-leverage points get their residuals blown up the most, which is exactly right, and it's the same $\mathrm{Cov}(\hat y_i, y_i)$ mechanism from §1 made concrete.

This is why `RidgeCV` can scan a hundred values of $\lambda$ almost instantly.

### The jackknife connection

Leave-one-out cross-validation *is* the jackknife applied to prediction error. If you've used the jackknife to estimate the bias and variance of an estimator, you already have the right instinct here: systematically delete one observation at a time, watch how the answer moves, and use that movement to infer sensitivity to the sample. CV asks the same question about predictions rather than parameters.

---

## 5. Variants for structured data

The default $k$-fold assumes your samples are i.i.d. draws. They usually aren't, and every violation has a matching variant.

### Stratified $k$-fold

For classification, especially with rare classes, random splitting can hand you a fold with two positives in it — or zero. Stratified folds preserve the class proportions in every fold. **Use this by default for classification.** It reduces variance at no cost.

### Grouped CV

If your data has clusters — several measurements per subject, per detector run, per production batch, per patient — then two rows from the same cluster are not independent. Random splitting puts near-duplicates on both sides, and the model can succeed by recognizing the cluster rather than learning the pattern.

The result is an evaluation that measures interpolation within known clusters when what you need is generalization to new clusters. Use `GroupKFold` or leave-one-group-out, keeping every cluster entirely on one side.

**Ask yourself: what does a new sample look like at deployment?** If it will come from a subject you've never seen, then your validation must also be on subjects you've never seen. The split has to mirror the deployment shift.

### Time series

Random splitting on temporal data trains on the future to predict the past. Two structured alternatives:

**Forward chaining** (expanding window): fit on $[1,t]$, test on $[t+1, t+h]$; slide forward. Mirrors how the model will actually be used. Downside: early folds train on little data.

**Rolling window** (fixed width): fit on $[t-w, t]$, test on $[t+1, t+h]$. Better if the process is non-stationary and old data is stale.

Two refinements that matter when observations are autocorrelated or labels are built from forward-looking windows:

- **Purging**: drop training samples whose label horizon overlaps the test period. Otherwise information about the test window is inside the training labels.
- **Embargo**: additionally drop a buffer of training samples immediately after the test block, since serial correlation leaks across the boundary.

These come from financial ML but apply to any autocorrelated series — sensor drift, climate records, anything with memory.

### Repeated $k$-fold

Run $k$-fold several times with different random partitions and average. Reduces the variance coming from the arbitrary choice of partition. Cheap insurance when $n$ is small.

---

## 6. Nested cross-validation

When you both tune and report, you need two nested loops:

- **Inner loop** (on the training portion of each outer fold): select hyperparameters by CV.
- **Outer loop**: refit with the selected hyperparameters on that fold's training portion and evaluate on the untouched outer test fold.

The outer scores estimate the performance of *the whole procedure including its tuning*, which is the honest thing to report — because tuning is part of what you'd do on new data.

Cost is $k_{\text{outer}} \times k_{\text{inner}} \times |\text{grid}|$ fits, which is why people skip it. The optimism from skipping it is small when the grid is small and $n$ is large, and can be several percentage points when the grid is large and $n$ is small — precisely the regime where people are most tempted to skip it.

Note the outer folds may select *different* hyperparameters. That's fine and even informative: it tells you how stable your selection is. Nested CV evaluates the procedure, not a specific parameter setting.

---

## 7. Leakage: the systematic error that fakes a discovery

Leakage is any path by which information about the evaluation data reaches the fitting procedure. It is the dominant failure mode in applied ML, and it looks like success, which is what makes it dangerous. The tell is a result that's too good — the analogue of a five-sigma bump that turns out to be a cable.

| Type | What it looks like | Fix |
|---|---|---|
| **Preprocessing leakage** | Scaling, imputation, PCA, or feature selection fitted on all data before splitting | Put every fitted transform inside a `Pipeline`, inside the CV loop |
| **Target leakage** | A feature that is a proxy for, or downstream of, the outcome (`treatment_prescribed` predicting `has_disease`) | Audit each feature: was it available *before* the outcome? |
| **Duplicate leakage** | Exact or near-duplicate rows straddling the split | Deduplicate; use grouped splits |
| **Temporal leakage** | Any use of future information | Time-based splits; purge and embargo |
| **Selection-on-test** | Trying many models and reporting the best test score | Nested CV; a genuinely untouched test set |

Feature selection deserves a specific warning. Screening 10,000 features for correlation with the target **on the full dataset**, then cross-validating a model on the surviving 50, produces spectacular and entirely fake accuracy — even when the features are pure random noise. The selection step already used every label. It must live inside the CV loop.

---

## 8. Reading a CV result honestly

### The standard error is not what you think

The $k$ fold scores are **not independent** — their training sets overlap heavily — so $s/\sqrt{k}$ underestimates the true uncertainty. Bengio and Grandvalet showed there is no unbiased estimator of the variance of $k$-fold CV. So use the fold-to-fold spread as a rough guide to stability, not as a rigorous confidence interval, and be skeptical of significance tests built on it. If you need real error bars on a final number, bootstrap a genuinely held-out test set.

### The one-standard-error rule

Among settings whose CV score is within one standard error of the best, choose the most regularized. It's a convention rather than a theorem, but a defensible one: the CV curve is flat and noisy near its optimum, and when candidates are statistically indistinguishable, the simpler model tends to transfer better.

### Learning curves

Plot training and validation error against training set size. The shapes diagnose the problem:

- **Both high, converged together** → underfitting. More data won't help; you need a more flexible model or better features.
- **Large persistent gap, validation still falling** → overfitting. More data or stronger regularization will help.
- **Both low and converged** → done.

This tells you *which* intervention to try, which is worth far more than another decimal place on a single number.

---

## 9. Alternatives and relatives

**Bootstrap.** Resample $n$ points with replacement, fit, evaluate on the out-of-bag points (about 36.8% of the sample, since $(1-1/n)^n \to e^{-1}$). Gives smooth estimates and natural confidence intervals, but is biased pessimistically because each bootstrap sample contains only ~63% unique points. The .632 and .632+ estimators correct for this by blending with training error. Reasonable for very small $n$.

**Out-of-bag error.** For bagged ensembles — random forests especially — you get this for free: each tree has its own out-of-bag set, so OOB error is a built-in CV estimate at no extra cost.

**Analytic criteria.** AIC, BIC, and Mallows' $C_p$ estimate the optimism from §1 directly rather than resampling, using an effective parameter count. Fast, but they rely on assumptions (correct model class, known noise variance, effective df you can compute) that often fail for modern models. CV makes fewer assumptions; use it unless the fits are prohibitively expensive.

---

## 10. Failure modes

| Symptom | Likely cause |
|---|---|
| CV score far better than test score | Leakage — preprocessing, selection, or duplicates crossing the split |
| Result is spectacular on a hard problem | Leakage, until proven otherwise |
| Fold scores vary enormously | Too little data, or heterogeneous subpopulations; report the spread |
| CV score improves every time you tweak something | You're fitting the validation set; you need nested CV or a fresh holdout |
| Model validates well, fails on new subjects/sites/periods | Split type didn't match deployment — needed grouped or temporal splits |
| Feature selection produced a great model from noise | Screening done outside the fold |
| Standard error looks implausibly small | Fold scores aren't independent; don't treat them as a confidence interval |
| LOOCV disagrees sharply with 5-fold | High-leverage points, or grouped structure the bootstrap/LOO ignores |
| Test score keeps getting checked | It stopped being a test set at the second look |

---

## 11. Practical recipe

1. **Split off a test set first**, before you look at anything. Put it away.
2. **Decide what a "new sample" means** at deployment — new row, new subject, new time period, new site. Choose the split type to match: stratified, grouped, or temporal.
3. **Wrap every fitted transform in a pipeline** so scaling, imputation, and selection all happen inside each fold.
4. **Use $k=5$ or $10$**, stratified for classification, repeated if $n$ is small.
5. **Tune inside the training data.** If the tuned score is what you'll report, use nested CV.
6. **Report the fold-to-fold spread**, not just the mean, and treat it as a stability diagnostic rather than a confidence interval.
7. **Refit on all the training data** with the chosen settings — that's the model you ship.
8. **Evaluate on the test set once.** Whatever you get, that's the number.
9. **If the result looks too good, hunt for leakage** before celebrating. It's usually leakage.

---

## 12. Further reading

- Hastie, Tibshirani & Friedman, *The Elements of Statistical Learning*, ch. 7 — optimism, effective degrees of freedom, and the "wrong way / right way" feature-selection example in §7.10.2, which is worth reading even if you read nothing else.
- Arlot & Celisse (2010), "A survey of cross-validation procedures for model selection" — thorough and rigorous.
- Bengio & Grandvalet (2004), "No unbiased estimator of the variance of k-fold cross-validation" — the reason to distrust naive CV error bars.
- Varoquaux (2018), "Cross-validation failure: small sample sizes lead to large error bars" — sobering empirical work on how noisy CV really is in small-$n$ regimes.
- Kapoor & Narayanan (2023), "Leakage and the reproducibility crisis in ML-based science" — a survey of leakage failures across published scientific literature.
