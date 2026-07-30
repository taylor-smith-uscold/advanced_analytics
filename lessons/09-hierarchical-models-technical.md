# Borrowing Strength: Hierarchical Models and Partial Pooling

*Module 9 — technical register. For readers who have combined measurements by inverse-variance weighting.*

---

## 0. The one-paragraph version

You need an estimate for each of 400 stores, and the stores have between 8 and 80,000 observations each. Estimating each separately gives you unusable noise for the small ones; pooling everything into one number throws away real differences. **Partial pooling** interpolates: each group's estimate is a precision-weighted average of its own data and the population mean, with the weight determined by how much data the group has and how much groups genuinely differ. The shrinkage factor is $\tau^2/(\tau^2 + \sigma^2/n_j)$ — which is exactly inverse-variance weighting of two measurements, one from the group and one from the population. This is the same shrinkage as ridge regression from Module 5, with one crucial upgrade: the strength of the prior is **estimated from the data** rather than tuned by cross-validation. The groups tell you how much they differ, and that determines how much each one borrows.

---

## 1. The problem

A concrete case: conversion rate by sales representative.

| Rep | Trials | Conversions | Raw rate |
|---|---|---|---|
| A | 4 | 3 | **75%** |
| B | 1,200 | 372 | 31% |
| C | 6 | 0 | **0%** |
| D | 890 | 249 | 28% |

Rep A leads the leaderboard on four trials. Rep C is bottom on six. Neither number carries information worth acting on, but both will be acted on if you publish the table — small-sample groups populate both extremes of any ranking, mechanically.

Two standard responses, both wrong:

**Complete pooling.** Report the overall rate for everyone. Discards all genuine between-rep variation, which is presumably the point of the analysis.

**No pooling.** Report each rep's own rate. Maximum-variance estimates for small groups; the ranking is mostly noise.

**A minimum-sample cutoff** ("exclude reps with fewer than 30 trials") is the common patch, and it's a crude version of the right answer: it treats evidence as binary when it is continuous, discards the partial information small groups do carry, and makes the cutoff itself an arbitrary hyperparameter.

---

## 2. The estimator

Model group $j$'s observed mean $\bar y_j$ as a draw around a group-level true value $\theta_j$, and the $\theta_j$ as draws around a population mean $\mu$:

$$\bar y_j \mid \theta_j \sim \mathcal{N}(\theta_j,\ \sigma^2/n_j), \qquad \theta_j \sim \mathcal{N}(\mu,\ \tau^2)$$

The posterior mean is

$$\hat\theta_j = \lambda_j \bar y_j + (1-\lambda_j)\,\mu, \qquad \lambda_j = \frac{\tau^2}{\tau^2 + \sigma^2/n_j}$$

### Read the shrinkage factor

$\lambda_j$ is the **fraction of weight on the group's own data**, and it is precisely the inverse-variance weighting used to combine two independent measurements — one from within the group (precision $n_j/\sigma^2$), one from the population (precision $1/\tau^2$).

Its behavior is exactly right in every limit:

| Condition | $\lambda_j$ | Behavior |
|---|---|---|
| $n_j$ large | $\to 1$ | Group speaks for itself |
| $n_j$ small | $\to 0$ | Group is pulled to the population mean |
| $\tau^2$ large (groups genuinely differ) | $\to 1$ | Less pooling — the population mean isn't informative about this group |
| $\tau^2 \to 0$ (groups are alike) | $\to 0$ | Complete pooling |
| $\sigma^2$ large (noisy observations) | $\downarrow$ | More pooling |

**Each group gets its own amount of shrinkage**, determined by its own sample size. This is what a minimum-sample cutoff crudely approximates with a step function.

### The connection to Module 5

Ridge regression is the special case where the prior variance is fixed by a hyperparameter $\lambda$ chosen by cross-validation. Here, $\tau^2$ is **estimated from the between-group spread in the data itself**. The groups collectively reveal how different groups are, and that determines how much any individual group should borrow.

This is a strict improvement when you have a grouping structure: the regularization strength is identified rather than tuned. It also means the amount of pooling is *interpretable* — $\tau$ is a real quantity with units, the standard deviation of true group effects, and stakeholders can reason about it.

### James–Stein

The surprising theoretical backing: for three or more groups, shrinking every group's estimate toward the grand mean has **lower total squared error than using each group's own mean** — always, regardless of the true values. This is Stein's paradox, and it establishes that partial pooling isn't a conservative hedge but a strictly better estimator under squared-error loss.

---

## 3. Fitting

**Empirical Bayes / method of moments.** Estimate $\mu$ and $\tau^2$ from the observed between-group variance (subtracting the within-group sampling contribution), then plug in. Fast, transparent, and adequate for a leaderboard or a ranking. Understates uncertainty slightly because it treats estimated hyperparameters as known.

**Mixed-effects / multilevel models.** `lme4::lmer` in R, `statsmodels.MixedLM` in Python. Random intercepts by group, optionally random slopes:

```
outcome ~ 1 + treatment + (1 + treatment | store)
```

This estimates a store-specific intercept *and* a store-specific treatment effect, both partially pooled, with the correlation between them estimated too.

**Full Bayesian.** Stan, PyMC, `brms`. Necessary when you want proper posterior intervals on the group effects, when the hierarchy is deep (rep within region within country), or when the likelihood isn't Gaussian. Slower, and worth it for high-stakes recurring estimates.

### Practical notes

- **Non-Gaussian outcomes.** For rates, use a beta-binomial or logistic mixed model rather than shrinking raw proportions — the Gaussian formula misbehaves near 0 and 1, which is exactly where small groups land.
- **Few groups.** With under ~5 groups, $\tau^2$ is poorly identified. Use a weakly informative prior or fixed effects instead.
- **Unmodeled heterogeneity.** If groups differ systematically in ways you can measure (store size, region, tenure), put those in as group-level predictors. Shrinking toward a *conditional* mean is much better than shrinking toward the grand mean: a small rural store should be pulled toward other small rural stores, not toward the average of all stores.

---

## 4. Varying slopes: effects that differ by group

The natural extension is letting the *effect* vary, not just the level:

$$y_{ij} = \alpha_j + \beta_j x_{ij} + \varepsilon_{ij}, \qquad (\alpha_j, \beta_j) \sim \mathcal{N}\big((\mu_\alpha,\mu_\beta),\ \Sigma\big)$$

Now each group has its own slope, partially pooled toward the population slope. This is the natural home for the heterogeneous-treatment-effect question from Module 2, §7 when the heterogeneity follows a known grouping: instead of estimating 400 independent store-level treatment effects (mostly noise) or one global effect (hiding real variation), you get 400 stabilized estimates with the shrinkage set by the data.

Estimating $\Sigma$ also gives you the correlation between intercept and slope — whether high-baseline stores respond more or less to the treatment — which is often the substantive finding.

---

## 5. Where this applies

| Situation | Grouping | Why it helps |
|---|---|---|
| Rep, store, or region performance | Entity | Small entities don't dominate rankings by noise |
| A/B test effects by segment | Segment | Stabilizes subgroup effects that Module 3 warns against reading naively |
| Product ratings with few reviews | Product | A 5.0 from two reviews shouldn't outrank a 4.7 from four hundred |
| Forecasts for many SKUs | SKU / category | Sparse SKUs borrow from their category (Module 10) |
| Survey estimates for small cells | Demographic × geography | The core of MRP |
| Anomaly thresholds per entity | Entity | Per-entity baselines without overfitting sparse entities |

**The segment-effects case deserves emphasis.** Module 3 tells you to treat subgroup findings as hypotheses, largely because independently estimated subgroup effects are noisy and the extremes are selected. A hierarchical model addresses the underlying problem directly — it shrinks extreme subgroup estimates toward the overall effect in proportion to their unreliability, which substantially reduces the multiple-comparisons problem rather than merely correcting the p-values for it. Gelman's framing is that with a multilevel model you have fewer comparisons to worry about, because the estimates are no longer free to be extreme.

---

## 6. Failure modes

| Symptom | Likely cause |
|---|---|
| Small groups still extreme | Not actually pooling; check $\lambda_j$ per group |
| Everything shrunk to the mean | $\tau^2$ estimated near zero — either groups really are alike, or too few groups to identify it |
| Estimates worse than no-pooling on large groups | Shouldn't happen; check that $\lambda_j \to 1$ as $n_j$ grows |
| Rates shrinking past 0 or 1 | Gaussian model on a bounded outcome; use beta-binomial or logistic |
| Convergence warnings in `lmer` | Overparameterized random-effects structure; simplify |
| Group means clearly explained by group size | Add group-level predictors; shrink toward a conditional mean |
| Stakeholder objects that "the numbers were changed" | Real communication issue — see below |

**On that last row:** the objection is legitimate-sounding and needs a prepared answer. Frame it as *reliability weighting*, not adjustment: "Rep A's 75% is based on four trials. Our best estimate of her true rate, accounting for how little data that is, is 34%. If she keeps converting at that pace over fifty trials, the estimate will move most of the way to her observed rate." Showing the estimate's movement with $n$ makes the mechanism intuitive and defensible.

---

## 7. Practical recipe

1. **Identify the grouping** and count observations per group. Wide imbalance is the signal for this method.
2. **Compute the three baselines** — complete pooling, no pooling, partial pooling — and plot them together against group size. The classic shrinkage plot is the best explanatory artifact you will produce.
3. **Choose the likelihood** to match the outcome: Gaussian for continuous, binomial/beta-binomial for rates, Poisson for counts.
4. **Add group-level predictors** for measurable systematic differences.
5. **Fit** with `lmer`/`MixedLM` for standard cases, Stan/PyMC when you need posterior intervals or deep hierarchies.
6. **Report $\tau$** — the estimated spread of true group effects. It tells stakeholders how much real variation exists, separate from noise.
7. **Report intervals per group**, not just point estimates. Small groups should visibly have wide ones.
8. **Validate by group**, using grouped cross-validation (Module 6, §5) — held-out groups, not held-out rows.
9. **Prepare the explanation** before publishing a changed leaderboard.

---

## 8. Further reading

- Gelman & Hill, *Data Analysis Using Regression and Multilevel/Hierarchical Models* — the standard applied reference; chapter 12 is the clearest introduction to partial pooling anywhere.
- McElreath, *Statistical Rethinking*, ch. 13 — outstanding intuition-building, with the reedfrog example that makes shrinkage click. Lectures free on YouTube.
- Efron & Morris (1977), "Stein's paradox in statistics" — the baseball example; short, non-technical, and still the best popular explanation of why shrinkage works.
- Gelman, Hill & Yajima (2012), "Why we (usually) don't have to worry about multiple comparisons" — the §5 argument about subgroup effects.
- Gelman, Lax & Phillips on MRP — small-area estimation from survey data.
