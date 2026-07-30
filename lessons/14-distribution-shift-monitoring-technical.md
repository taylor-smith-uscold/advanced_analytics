# Is It Still Working? Distribution Shift and Monitoring

*Module 14 — technical register. For readers who monitor a control channel because instruments drift.*

> **Required reading —** Sculley et al., *Hidden Technical Debt in Machine Learning Systems* · free PDF via [NeurIPS proceedings](https://papers.nips.cc/paper_files/paper/2015/file/86df7dcfd896fcaf2674f757a2463eba-Paper.pdf)

---

## 0. The one-paragraph version

A model is a fitted description of a distribution that no longer holds the moment you deploy it. Three kinds of drift matter and have different remedies: **covariate shift** ($P(X)$ changes, $P(Y|X)$ stable — often benign, correctable by reweighting), **label shift** ($P(Y)$ changes — correctable by adjusting the prior), and **concept drift** ($P(Y|X)$ changes — the relationship itself has moved, and only retraining helps). Cutting across all three is the failure mode with no analogue in offline evaluation: **feedback loops**, where the model's own decisions determine what data you subsequently observe. A fraud model that blocks transactions never learns whether those transactions were fraudulent; a demand forecast that sets inventory censors the demand it could have served. These loops corrupt every retrain in a consistent direction and are invisible to standard monitoring, because the metrics computed on the data you *do* see look fine. The organizing principle is that monitoring must cover inputs, outputs, and outcomes separately, because they degrade at different times and only the first is available immediately.

---

## 1. A taxonomy of shift

Write the joint as $P(X, Y) = P(Y|X)P(X) = P(X|Y)P(Y)$. Different factorizations change:

| Type | What changes | What's stable | Example | Remedy |
|---|---|---|---|---|
| **Covariate shift** | $P(X)$ | $P(Y\|X)$ | Marketing shifts your traffic to a younger segment | Importance weighting; often no action needed |
| **Label shift** | $P(Y)$ | $P(X\|Y)$ | Fraud base rate rises seasonally | Prior correction on outputs; recalibrate |
| **Concept drift** | $P(Y\|X)$ | possibly $P(X)$ | Fraudsters change tactics; the same features now mean something different | **Retrain. Nothing else works** |

**Covariate shift alone need not degrade performance** — if the model is correct everywhere and the new inputs fall inside its training support, it will do fine. Degradation happens when the new region is one the model was never fitted on, which is why a drift alert should be read as "check whether we're extrapolating," not "the model is broken."

Concept drift is the serious one, and it comes in profiles: **sudden** (a policy change, a product launch), **gradual** (evolving preferences), **incremental** (slow parameter drift), and **recurring** (seasonality, which is a predictable regime alternation and should be modeled, not treated as drift).

---

## 2. What to monitor, and when it's observable

The critical operational fact: these become available at different times.

| Layer | What | Available |
|---|---|---|
| **Inputs** | Feature distributions, null rates, cardinality, volume | **Immediately** |
| **Outputs** | Prediction distribution, score percentiles, action rates | **Immediately** |
| **Outcomes** | Accuracy, AUC, calibration, business metrics | **After the label horizon** — days to months |
| **System** | Latency, error rates, throughput, version | Immediately |

Because outcomes lag, input and output monitoring are your early warning system. But note the asymmetry: **input drift is neither necessary nor sufficient for performance degradation.** Features can shift harmlessly; performance can collapse with stable inputs (that's concept drift). Monitor both, and treat input alerts as triggers for investigation rather than as incidents.

**Output drift is often the more sensitive signal**, because the prediction distribution aggregates all features through the model — the thing that actually matters. A sudden shift in the fraction of scores above your threshold is more actionable than a KS test on a single feature.

---

## 3. Detection methods

| Method | Applies to | Notes |
|---|---|---|
| **PSI** (population stability index) | Binned continuous or categorical | Industry standard in credit. Conventions: <0.1 stable, 0.1–0.25 moderate, >0.25 significant |
| **KS statistic** | Continuous | Sensitive; needs a reference window |
| **Chi-square** | Categorical | Watch small expected counts |
| **KL / JS divergence** | Distributions | JS is symmetric and bounded; preferable |
| **MMD** | Multivariate | Kernel-based; catches joint shifts univariate tests miss |
| **Domain classifier** | Multivariate | Train a classifier to distinguish old from new data. **AUC ≈ 0.5 means no detectable shift**; high AUC means shift, and its feature importances tell you *where*. The most informative single diagnostic |

**Statistical significance is not operational significance.** With millions of rows, every feature drifts significantly every day. Set thresholds on *effect size* (PSI, or a standardized mean difference), not p-values, or your alerts will be pure noise and get ignored — which is worse than not having them.

**Multivariate shift can hide from univariate tests.** Every marginal can look unchanged while the correlation structure moves. The domain classifier catches this; per-feature tests don't.

---

## 4. Monitoring performance when labels are delayed

The standard difficulty: you need outcomes to compute accuracy, and outcomes arrive late or never.

**Proxy signals available immediately:**
- Prediction distribution stability
- Score-threshold crossing rates
- Calibration on whatever labels *have* arrived (partial, biased toward fast-resolving cases — note this)
- Agreement with a champion model or a simple rule
- Downstream operational metrics: approval rates, queue volumes, override rates

**Human override rate is an underused early signal.** If reviewers overturn the model more often than last month, something has changed, and you'll see it well before labels close.

**Delayed-label bias:** early-arriving labels are not a random sample. Fraud confirmed within a week differs systematically from fraud discovered at chargeback. Computing metrics on matured labels only, with a stated maturity window, avoids a moving-target metric.

---

## 5. Feedback loops

The failure mode with no offline analogue, and the most consequential material in this module.

### Censored outcomes

A credit model rejects applicants. You never observe whether rejects would have repaid. Retraining on approved-only data means the model learns $P(\text{default} \mid X, \text{approved})$ while you need $P(\text{default}\mid X)$ — and the approved set is precisely the set the current model liked. Each generation narrows further.

This is **selection on a post-treatment variable** — the collider structure from Module 2, §4 — appearing in a production loop.

Mitigations:
- **Randomized holdout:** approve a small random fraction regardless of score. Directly buys the counterfactual data. Expensive, and usually worth it.
- **Reject inference** methods, with stated assumptions.
- **Exploration bonuses** near the decision boundary, where information is densest.

### Self-fulfilling predictions

Forecast low demand → order less inventory → sell less → next model trains on lower sales → forecasts lower demand. The loop is stable, monotone downward, and every metric on observed data looks fine.

Same structure: a recommender that never shows an item generates no engagement data for it, confirming that it shouldn't be shown.

**Log what was available, not just what was chosen.** Recording the full candidate set with propensities enables counterfactual evaluation later; without it, the data cannot support the question.

### Direct interference

The model's action changes the world it predicts: a churn model triggers retention offers, so predicted churners churn less, so the model looks miscalibrated — it is being penalized for working. Any evaluation that ignores the intervention is measuring the wrong thing, and the honest evaluation requires a holdout group who receive no action (Module 3).

---

## 6. Training-serving skew

Distinct from drift: the data was different from day one.

| Cause | Detection |
|---|---|
| Different code paths for training and serving features | Log serving features; compare distributions against training |
| Time-of-computation differences (a feature computed at midnight batch vs. request time) | Compare paired values on the same entities |
| Missing-value handling differing between environments | Explicit null-rate comparison |
| Training on backfilled data unavailable in real time | Point-in-time correctness audit |

**The backfill case is the most insidious.** A warehouse table that gets corrected retroactively means your training data contains values that did not exist at prediction time — a leakage source that looks like nothing in offline validation and destroys production performance. Any feature store worth using enforces point-in-time correctness for this reason.

**The definitive test:** log the exact feature vector used at serving time, then re-score it offline. Any discrepancy is skew.

---

## 7. Retraining and deployment

### Triggers

| Strategy | When appropriate |
|---|---|
| **Scheduled** (weekly/monthly) | Stable domains; simple to operate |
| **Triggered** by drift or performance | Responsive; needs reliable detection and guards against thrashing |
| **Continuous / online** | Fast-moving domains; highest operational risk |

Retraining is not free of risk: it can propagate corrupted data, and in feedback-loop settings it can accelerate the loop. **Every retrain needs the same validation gate as the original**, plus a comparison against the incumbent on a common holdout.

### Window policy

Longer windows give more data and more stale data. Under gradual drift, sliding or exponentially-weighted windows outperform expanding ones. Under recurring seasonal patterns, keep full cycles — don't truncate to a window shorter than a year on annually seasonal data.

### Safe rollout

- **Shadow mode.** Serve predictions without acting; compare to the incumbent.
- **Canary.** Route a small traffic fraction; monitor guardrails.
- **A/B.** The correct way to evaluate a model *change* (Module 3), and the only one that measures business impact rather than offline accuracy.
- **Automated rollback** on guardrail breach, with the previous version retained and immediately deployable.

Version everything — model, features, training data snapshot, code — so that any production number can be reproduced. Without this, incident investigation is guesswork.

---

## 8. Failure modes

| Symptom | Likely cause |
|---|---|
| Offline metrics fine, business metrics falling | Feedback loop, or the offline metric is a poor proxy (Module 1) |
| Model degraded from day one | Training-serving skew, not drift |
| Drift alerts fire constantly | Thresholds on p-values instead of effect sizes |
| No feature drift, performance collapsed | Concept drift; retrain |
| Feature drift, performance fine | Benign covariate shift; check extrapolation, don't panic |
| Accuracy improves over time on approved cases only | Selection narrowing — the censored-outcome loop |
| Retrained model worse than the old one | Corrupted recent data, or the loop; check the holdout comparison |
| Calibration degrades faster than ranking | Label shift; adjust the prior rather than retraining wholesale |
| A feature silently became all-null | Upstream pipeline break — this is why null-rate monitoring exists |

---

## 9. Practical recipe

1. **Log the exact serving feature vector and prediction**, with model version, for every request. Without this, nothing else works.
2. **Establish a reference window** from training data, and define drift metrics against it.
3. **Monitor four layers** — inputs, outputs, outcomes, system — with different latencies and different alert severities.
4. **Set thresholds on effect size**, tuned so alerts are rare enough to be read.
5. **Run a domain classifier periodically**; its AUC and feature importances localize any shift.
6. **Track proxy signals** for the label-delay gap, especially human override rates.
7. **Identify every feedback loop** in the system explicitly, and instrument a randomized holdout wherever the model's decision censors the outcome.
8. **Define the retraining policy in advance** — trigger, window, validation gate, rollback criteria.
9. **Deploy through shadow → canary → A/B**, never directly.
10. **Re-check subgroup performance on every retrain** (Module 15). Drift is rarely uniform across populations, and aggregate metrics hide localized collapse.

---

## 10. Further reading

- Sculley et al. (2015), "Hidden technical debt in machine learning systems" — feedback loops, entanglement, and why ML systems decay. Short and essential.
- Breck et al. (2017), "The ML Test Score" — a concrete production-readiness rubric, much of it about monitoring.
- Gama et al. (2014), "A survey on concept drift adaptation" — the taxonomy and detection methods in §1 and §3.
- Rabanser, Günnemann & Lipton (2019), "Failing loudly: an empirical study of methods for detecting dataset shift" — evaluates detection approaches; the domain-classifier result is the practical takeaway.
- Lipton, Wang & Smola (2018), "Detecting and correcting for label shift with black box predictors" — the prior-correction method for §1.
- Paleyes, Urma & Lawrence (2022), "Challenges in deploying machine learning: a survey of case studies" — what actually goes wrong, from practice.
