# Error Bars: Uncertainty and Inference

*Module 11 — technical register. For readers who consider a number without an uncertainty to be incomplete.*

---

## 0. The one-paragraph version

Every estimate is a draw from a sampling distribution, and reporting the draw without its width is reporting half the result. Three distinctions organize the subject. **Confidence versus prediction intervals**: one covers a parameter, the other a future observation, and they differ by the irreducible noise term — confusing them understates uncertainty by an order of magnitude on individual predictions. **Aleatoric versus epistemic uncertainty**: noise that more data cannot reduce, versus ignorance that it can; the distinction determines whether "collect more data" is a sensible response. **Statistical versus systematic**: the interval you compute describes sampling variability only, and in observational work it is almost never the dominant term. The bootstrap covers most practical needs for the first kind, and **conformal prediction** provides distribution-free coverage guarantees for individual predictions from any model — the natural complement to the calibration material in Module 7.

---

## 1. What an interval is for

An estimate $\hat\theta$ is a function of a particular sample. Draw a different sample and you get a different value. The sampling distribution describes that variability; an interval summarizes it.

**The interpretation of a 95% confidence interval is a property of the procedure, not of the particular interval.** Repeat the sampling and construction many times and 95% of the resulting intervals contain the true value. The one you have either contains it or doesn't.

This matters for communication (Module 16): stakeholders reliably read intervals as probability statements about the parameter. A Bayesian credible interval *is* that statement, which is one reason to prefer Bayesian framing when the audience will interpret it that way regardless.

---

## 2. Confidence versus prediction intervals

The distinction most often botched in practice.

For a linear model at a new point $x_0$:

$$\text{CI for } \mathbb{E}[y|x_0]: \quad \hat y_0 \pm t\,\hat\sigma\sqrt{x_0^\top(X^\top X)^{-1}x_0}$$

$$\text{PI for } y_0: \quad \hat y_0 \pm t\,\hat\sigma\sqrt{1 + x_0^\top(X^\top X)^{-1}x_0}$$

The difference is the $1$ inside the radical: the irreducible noise in a single new observation.

**Consequences:**

- The confidence interval shrinks toward zero as $n \to \infty$. The prediction interval converges to $\pm t\hat\sigma$ and **never shrinks below the noise floor**.
- With large $n$ the two differ by an order of magnitude.
- "Our forecast is 1,200 ± 30" is almost certainly a confidence interval being misused as a prediction interval. The right question is whether the audience wants to know the *average* for such customers, or what *this* customer will do.

Nearly every business question about an individual case needs a prediction interval. Nearly every automatically-produced interval is a confidence interval.

---

## 3. Aleatoric versus epistemic

| | **Aleatoric** | **Epistemic** |
|---|---|---|
| Source | Genuine randomness in the process | Ignorance about the model or parameters |
| Reducible by more data? | **No** | **Yes** |
| Example | Which customer churns this month | Which coefficient value is right |
| Shows up as | Residual spread | Parameter uncertainty, model uncertainty |

The practical value of the distinction is that it answers "should we collect more data?" If your interval is dominated by aleatoric noise, more data will not narrow it, and the honest answer to a stakeholder asking for a tighter forecast is that the process is that variable — better features or a different question, not more rows.

**Model uncertainty is the neglected third term.** Standard intervals condition on the model being correct. They do not account for the possibility that a different specification, a different feature set, or a different algorithm would have given a materially different answer. This is why forecast intervals under-cover (Module 10, §5) and why ensembling across model specifications is a defensible way to widen intervals honestly.

---

## 4. The bootstrap

Resample the data with replacement, recompute the statistic, repeat $B$ times, use the resulting distribution.

The justification: the empirical distribution is your best estimate of the population, so resampling from it mimics resampling from the population. It works for statistics with no closed-form standard error — medians, ratios, AUC, correlation, differences of quantiles, anything from your metrics module.

### Variants

| Variant | Use |
|---|---|
| **Percentile** | Default. Take the 2.5th and 97.5th percentiles of the bootstrap distribution |
| **BCa** | Corrects bias and skew; better coverage, more computation. Preferred for skewed statistics |
| **Cluster / block** | Resample *groups*, not rows, when data is clustered — the Module 6 grouping issue applies to the bootstrap too |
| **Block (moving)** | Resample contiguous blocks for time series, to preserve autocorrelation |
| **Parametric** | Simulate from a fitted model rather than resampling; useful when $n$ is small |

$B = 1{,}000$ is adequate for intervals; use $B = 10{,}000$ for tail quantiles.

### Where it fails

- **Extremes.** The bootstrap cannot estimate the distribution of a maximum — resamples never exceed the observed max.
- **Dependence.** Naive row resampling destroys correlation structure. Use block or cluster variants.
- **Very small $n$.** The empirical distribution is a poor stand-in for the population below about 20 observations.
- **Non-smooth statistics.** Coverage can be poor for statistics with discontinuous behavior.

### The paired comparison

For comparing two models, resample the test set once per replicate and evaluate **both** models on the same resample, then bootstrap the *difference*. Because errors are correlated across models — hard cases are hard for both — the paired difference has much lower variance than the difference of independently computed intervals.

Practical implication: **two overlapping confidence intervals do not imply a non-significant difference.** This mistake is extremely common in model comparison tables. Compute the interval on the difference directly.

---

## 5. Multiple comparisons

Testing $m$ hypotheses at level $\alpha$ each gives a family-wise error rate approaching $1 - (1-\alpha)^m$. At $m=20$, $\alpha=0.05$, that's 64%.

| Procedure | Controls | Character |
|---|---|---|
| **Bonferroni** | FWER | Test at $\alpha/m$. Simple, conservative |
| **Holm** | FWER | Step-down; uniformly more powerful than Bonferroni, no extra assumptions. Use instead |
| **Benjamini–Hochberg** | FDR | Controls the expected *proportion* of false discoveries. Much more powerful with many tests |
| **Hierarchical modeling** | — | Shrinks extreme estimates directly (Module 9, §5) |

**Choose by the cost structure.** FWER control when any single false positive is costly (a guardrail breach, a safety claim). FDR control when you're screening many candidates and tolerate a known fraction of false leads.

The hierarchical-model route is worth taking seriously as an alternative rather than an addition: partial pooling attacks the reason extreme estimates arise, rather than adjusting the threshold after the fact.

**None of this helps with the garden of forking paths** (Module 3, §5). Corrections apply to tests you performed; they cannot account for the tests you would have performed had the data looked different. Pre-registration is the only remedy for that.

---

## 6. Conformal prediction

The most useful recent addition to the applied toolkit, and the natural extension of Module 7's calibration material.

**The guarantee:** given exchangeable data, split conformal prediction produces prediction sets with **marginal coverage of at least $1-\alpha$**, for *any* underlying model, with no distributional assumptions.

### Split conformal, in four steps

1. Fit your model on a training set.
2. On a held-out calibration set, compute nonconformity scores — for regression, $s_i = |y_i - \hat f(x_i)|$.
3. Let $q$ be the $\lceil (n+1)(1-\alpha)\rceil / n$ empirical quantile of those scores.
4. For a new point, the prediction interval is $\hat f(x_{new}) \pm q$.

That's it. The coverage guarantee is finite-sample and exact, and holds regardless of whether your model is any good. A bad model yields wide intervals, not broken coverage — which is exactly the behavior you want.

### Adaptivity

Basic split conformal gives **constant-width** intervals, which is wrong under heteroscedasticity. Two fixes:

- **Normalized scores**: $s_i = |y_i - \hat f(x_i)| / \hat\sigma(x_i)$, using a fitted difficulty estimate.
- **Conformalized quantile regression (CQR)**: fit quantile regressions for the lower and upper targets, then conformalize the residuals. Intervals adapt to local difficulty while retaining the guarantee. This is the recommended default.

### Classification

Produces prediction *sets* rather than single labels — {cat}, {cat, dog}, or occasionally the empty set. Set size is an honest and legible signal of difficulty, which is often more useful operationally than a probability: "the model is confident enough to name one class here, and can only narrow it to three there."

### Limits worth stating

- **Coverage is marginal, not conditional.** 90% coverage overall can hide 70% coverage in a subgroup. Group-conditional variants (Mondrian conformal) address this, and given Module 15, you should check per-subgroup coverage regardless.
- **Exchangeability is required**, so time series need adapted variants (ACI, EnbPI).
- **It quantifies uncertainty; it doesn't reduce it.** Wide intervals are information, not failure.

---

## 7. Where the interval isn't the real uncertainty

The computed interval describes sampling variability under an assumed model. In practice the dominant uncertainty is usually elsewhere:

| Source | Captured by standard intervals? |
|---|---|
| Sampling variability | Yes |
| Parameter uncertainty | Partly |
| Model specification | No |
| Confounding (Module 2) | No |
| Measurement error (Module 4) | No |
| Distribution shift (Module 14) | No |
| The proxy gap (Module 1) | No |

Reporting a tight interval on an observational estimate while ignoring these is precise about the wrong thing. Present the statistical interval alongside a stated sensitivity analysis, as Module 2, §6 requires.

---

## 8. Failure modes

| Symptom | Likely cause |
|---|---|
| Prediction intervals far too narrow | Reporting a confidence interval for an individual outcome |
| Intervals shrink with $n$ toward zero for individual predictions | Same error — a PI has a noise floor |
| Bootstrap CI too narrow on clustered data | Resampling rows instead of clusters |
| Bootstrap CI too narrow on time series | Resampling points instead of blocks |
| "Intervals overlap, so no difference" | Compare the difference directly with paired resampling |
| Many significant subgroup findings | No multiplicity control; or use hierarchical shrinkage |
| Conformal coverage fine overall, poor in a subgroup | Marginal coverage only; use group-conditional variants |
| More data doesn't tighten the interval | Aleatoric-dominated; more rows won't help |

---

## 9. Practical recipe

1. **Decide what the interval is about** — a parameter, or a future individual outcome. Choose CI or PI accordingly.
2. **Bootstrap by default** for any metric without a clean closed form, resampling at the level of dependence (rows, clusters, or blocks).
3. **Compare models with paired resampling** on the difference, never by eyeballing overlap.
4. **Control multiplicity explicitly** — Holm for critical tests, BH for screening, hierarchical shrinkage where there's a grouping.
5. **Use conformal prediction (CQR) for individual-prediction intervals** from any model, and validate empirical coverage on held-out data.
6. **Check coverage by subgroup**, not just overall.
7. **State what the interval does not cover** — model choice, confounding, shift, proxy gap.
8. **Round to the precision the interval supports.** Three decimal places on a ±5-point interval is noise dressed as rigor.

---

## 10. Further reading

- Efron & Tibshirani, *An Introduction to the Bootstrap* — the standard reference; still the clearest treatment of when the bootstrap works and when it doesn't.
- Angelopoulos & Bates (2021), "A gentle introduction to conformal prediction and distribution-free uncertainty quantification" — genuinely gentle, and the best entry point to §6.
- Romano, Patterson & Candès (2019), "Conformalized quantile regression" — the adaptive-interval method to use as a default.
- Benjamini & Hochberg (1995) — the FDR procedure.
- Hüllermeier & Waegeman (2021), "Aleatoric and epistemic uncertainty in machine learning" — a careful treatment of the §3 distinction.
- Gelman & Greenland (2019), "Are confidence intervals better termed 'uncertainty intervals'?" — on interpretation and communication.
