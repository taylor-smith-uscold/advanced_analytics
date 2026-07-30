# Why Did the Model Say That? Interpretability and Explanation

*Module 13 — technical register. For readers who want to know what an attribution actually attributes.*

---

## 0. The one-paragraph version

Explanation methods answer a narrower question than people assume. They describe **how a particular fitted model's output responds to its inputs** — not how the world works, and not what would happen if you intervened. The gap is the entire content of Module 2, and no attribution method closes it. Beyond that, the methods have specific and important failure modes under correlated features: permutation importance evaluates the model on input combinations that never occur, partial dependence averages over a marginal distribution that includes impossible points, and SHAP's two variants (interventional and conditional) answer different questions and can rank features differently on the same model. The practical stance is: use these tools to *debug and describe the model*, use Module 2's tools to make claims about the world, and prefer built-in constraints — monotonicity, additivity, limited interaction depth — when explanation actually matters, because a model that is interpretable by construction needs no post-hoc reconstruction.

---

## 1. Three different questions

Precision here prevents most misuse:

| Question | Method | Valid claim |
|---|---|---|
| What does this model do? | Global attribution, PDP, ALE | About the model |
| Why this prediction? | SHAP, LIME, counterfactuals | About the model, on this input |
| What happens if we intervene? | **Module 2** | About the world |

**Only the third informs action**, and no explanation method delivers it. A feature can be the most important input to a churn model and be entirely non-causal — the support-contact example from Module 2, §1 is exactly this. SHAP will correctly assign it high attribution, because it does drive the prediction. Acting on that attribution is the error.

Global versus local also matters: a globally unimportant feature can dominate an individual prediction, and a globally important one can be irrelevant to a specific case. Choose the scope to match the question.

---

## 2. Coefficients

For a linear model, $\beta_j$ is the change in prediction per unit change in $x_j$, holding others fixed. Four cautions:

- **Scale-dependent.** Compare standardized coefficients, or you're ranking units (Module 5, §5).
- **Regularized coefficients are shrunk on purpose.** Their magnitudes are biased low, and lasso's selection among correlated features is arbitrary and unstable across resamples.
- **"Holding others fixed"** may describe an impossible state if features are correlated.
- **Not causal** unless a Module 2 identification argument holds.

Coefficient *stability* is worth measuring directly: bootstrap the fit and look at the spread of each coefficient. Wide, sign-flipping distributions mean the model has not identified that feature's role, which is information the point estimate hides.

---

## 3. Permutation importance

Shuffle a feature's column, measure the drop in performance, repeat. Model-agnostic, measures effect on *performance* rather than on the fitting process.

**The correlated-feature problem.** Shuffling breaks the joint distribution. If height and weight are correlated, permuting height creates 150cm/120kg records that never occur, and the model is evaluated far off the data manifold — where it was never fitted and its behavior is arbitrary. The resulting importance is not trustworthy.

Correlation also **splits credit**: two duplicate features each show near-zero importance, because permuting one leaves the other to carry the signal. A naive reading concludes neither matters.

Mitigations: permute correlated features as a *group*; or use conditional permutation; or use drop-column importance (refit without the feature — expensive but unambiguous).

**Compute on held-out data.** Permutation importance on training data measures what the model memorized.

**Never use impurity-based importance** (`feature_importances_` in tree libraries). It is biased toward high-cardinality and continuous features — a random ID column can rank near the top — and it's computed on training data. It is the default in every library and should be treated as a bug (Module 8, §6).

---

## 4. Partial dependence, ICE, ALE

**PDP.** Average the model's prediction over the dataset while sweeping one feature: $\hat f_j(x) = \frac1n\sum_i \hat f(x, x_{-i})$.

The assumption is **independence between $x_j$ and the rest**. Under correlation, the average includes impossible combinations, and the curve is a description of model behavior in regions with no data.

**ICE plots.** The same computation, per observation, plotted as individual lines rather than an average. Essential companion: if the ICE lines are heterogeneous — some rising, some falling — the PDP average is meaningless, and you have discovered an interaction. Always plot ICE alongside PDP.

**ALE.** Accumulated local effects computes the effect using only *local* changes within small intervals of the feature's actual distribution, then accumulates. This avoids extrapolation entirely and is the correct default under correlated features. Slightly harder to explain, substantially more trustworthy.

---

## 5. SHAP

Attributes a prediction to features using Shapley values from cooperative game theory: the average marginal contribution of a feature across all orderings of feature inclusion.

**The axioms it satisfies:** efficiency (attributions sum to the prediction minus the baseline), symmetry, dummy, and additivity. This uniqueness result is why SHAP is the default — it's the only attribution satisfying all four.

**TreeSHAP** computes it exactly for tree ensembles in polynomial time, which is why it's practical.

### What the axioms do and don't guarantee

Efficiency is a *decomposition* guarantee. It says attributions sum correctly. It says nothing about whether the decomposition is causally meaningful, and the axioms hold equally well for a model fitted to noise.

### Interventional versus conditional SHAP

This distinction is under-appreciated and can reverse conclusions.

- **Interventional (marginal).** Replace absent features with values from the marginal distribution. Answers "what does *this model* use?" Attributes zero to a feature the model ignores, even if that feature is informative in the world. Evaluates off-manifold, like PDP.
- **Conditional (observational).** Replace absent features by sampling from the conditional distribution given the present ones. Answers "what does this feature *tell us*?" Spreads credit across correlated features, so an unused-but-correlated feature receives non-zero attribution.

Neither is wrong; they answer different questions. **For debugging a model, use interventional. For understanding what information is being used, conditional is closer.** For causal claims, neither — see §1.

Libraries default to one or the other depending on version and explainer. Know which you're getting.

### Practical cautions

- **Baseline choice matters.** Attributions are relative to a reference (dataset mean, a specific row, a subgroup). Different baselines, different explanations. State it.
- **Correlated features share credit arbitrarily** under interventional SHAP, in ways that don't reflect either feature's necessity.
- **Beeswarm plots are dense.** For stakeholder communication, a waterfall for a single prediction plus a bar chart of mean absolute SHAP is usually the right pair.
- **Sums are to the prediction, not the outcome.** SHAP explains what the model did, including when the model is wrong.

---

## 6. LIME, surrogates, counterfactuals

**LIME.** Fit a sparse linear model to the black box's behavior in a perturbed neighborhood of the point. Intuitive, and notoriously unstable — different random perturbations produce different explanations for the same prediction. If you use it, run it several times and check the explanation is stable. SHAP is generally preferable.

**Global surrogates.** Fit an interpretable model (shallow tree, linear model) to the black box's *predictions*. Useful only if fidelity is high; report the surrogate's $R^2$ against the black box. Low fidelity means you're explaining a different model.

**Counterfactual explanations.** "The application would have been approved if income were £4,000 higher." Often the most actionable format for an end user, and the format regulators tend to expect. Generate with the constraint that the counterfactual be *plausible* (on-manifold) and that it change only *actionable* features — telling someone to change their age is not a recommendation.

---

## 7. Interpretability by construction

Post-hoc explanation reconstructs an approximation of a model's behavior. Building constraints in gives you the real thing:

| Approach | Property |
|---|---|
| **Monotonic constraints** | Guaranteed direction per feature. Supported natively in XGBoost/LightGBM (Module 8, §4); typically near-zero accuracy cost |
| **GAMs / EBMs** | Additive models with learned per-feature shape functions. Each feature's effect is a plottable curve; Explainable Boosting Machines are frequently competitive with full boosting on tabular data |
| **Shallow depth limits** | Depth 2–3 caps interaction order, making SHAP interaction values tractable and the model closer to additive |
| **Sparse linear (lasso)** | Few features, signed coefficients |
| **Scorecards** | Binned, integer-weighted; the regulated-credit standard |

Rudin's argument is worth taking seriously: for high-stakes decisions, prefer an inherently interpretable model over a black box plus an explanation, because the explanation is an approximation whose fidelity you cannot fully verify. On tabular data the accuracy cost is often small — and EBMs make it smaller still.

---

## 8. Failure modes

| Symptom | Likely cause |
|---|---|
| An ID or timestamp is highly important | Leakage (Module 4), or impurity-bias if using `feature_importances_` |
| Two known-important features both look unimportant | Correlated pair splitting credit under permutation |
| PDP flat, but the feature clearly matters | Heterogeneous effects cancelling — plot ICE |
| PDP shows a strong effect in a region with no data | Extrapolation under correlation; use ALE |
| SHAP rankings differ from permutation rankings | Different questions (prediction attribution vs performance) — both can be right |
| SHAP explanations change between library versions | Interventional vs conditional default changed |
| LIME gives different answers on reruns | Known instability; prefer SHAP |
| Stakeholder acts on an attribution and nothing improves | Attribution read causally — Module 2 |
| Explanations are unstable across retrains | Correlated features; consider constraints or a simpler model |

---

## 9. Practical recipe

1. **State which of §1's three questions you're answering.** If it's the third, this module is the wrong toolkit.
2. **Consider an interpretable model first** — EBM, monotone GBM, sparse linear. Benchmark the accuracy cost before assuming you need a black box.
3. **Check feature correlation** before choosing methods; it determines which are trustworthy.
4. **Global view:** permutation importance on held-out data, grouping correlated features. Never impurity importance.
5. **Shape of effects:** ALE by default; PDP *with* ICE overlaid if you use it.
6. **Local view:** SHAP, with the baseline and variant stated explicitly.
7. **Check stability** — rerun explanations across bootstrap refits. Unstable explanations mean the model hasn't identified those roles.
8. **For end users, prefer counterfactuals** over attributions: actionable, and closer to what people actually want to know.
9. **Validate against domain knowledge.** If the model relies on something an expert finds implausible, investigate before deploying — this is one of the most effective leakage detectors available.
10. **Record the explanation setup** in the model documentation (Module 15).

---

## 10. Further reading

- Molnar, *Interpretable Machine Learning* — free online, the best comprehensive reference; chapters on PDP, ALE, and SHAP are the practical standard.
- Lundberg & Lee (2017), "A unified approach to interpreting model predictions" — the SHAP paper.
- Rudin (2019), "Stop explaining black box machine learning models for high stakes decisions" — the argument in §7; worth reading even if you disagree.
- Apley & Zhu (2020), "Visualizing the effects of predictor variables in black box supervised learning models" — the ALE paper and the clearest statement of PDP's extrapolation problem.
- Nori et al. (2019), "InterpretML" — EBMs, with the accuracy benchmarks.
- Chen, Janizek, Lundberg & Lee (2020), "True to the model or true to the data?" — the interventional/conditional distinction in §5.
