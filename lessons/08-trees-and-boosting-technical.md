# Ensembles: Trees, Bagging, and Gradient Boosting

*Module 8 — technical register. For readers who know that averaging independent measurements beats averaging correlated ones.*

---

## 0. The one-paragraph version

A single decision tree is a piecewise-constant function fitted greedily. It is interpretable, cheap, invariant to monotone feature transforms — and has appallingly high variance, because an early split changes everything below it. The two ways of fixing this are worth understanding as distinct physical strategies. **Bagging** averages many high-variance, low-bias trees fitted to resampled data; the variance falls as $\rho\sigma^2 + (1-\rho)\sigma^2/B$, which says that averaging helps only to the extent the errors are *uncorrelated* — the correlation term is a noise floor that more trees cannot lower, and random feature subsampling exists purely to push $\rho$ down. **Boosting** instead fits low-variance, high-bias stumps sequentially, each correcting the current residual, which is perturbation theory: build the answer order by order, with a small coefficient (the learning rate) on each correction. Boosting has more knobs and wins more often on tabular data, which is why gradient-boosted trees remain the default for business problems and why deep learning has not displaced them there.

---

## 1. The single tree

Recursive binary partitioning: at each node, choose the feature and cut point minimizing an impurity criterion; recurse; predict the mean (regression) or class proportion (classification) in each leaf.

| Task | Criterion |
|---|---|
| Regression | Variance / SSE reduction |
| Classification | Gini impurity or entropy |

Properties worth noting because they carry through to the ensembles:

- **Invariant to monotone transforms of individual features.** Splits ask "is $x_j > t$?", and that question survives any rescaling. This is why Module 5's standardization is unnecessary here — the one common model family where it genuinely doesn't matter.
- **Handles mixed types and missing values naturally.** Modern implementations learn a default direction per split for missing values (Module 4, §2).
- **Captures interactions automatically.** Every path down the tree is a conjunction of conditions.
- **Cannot extrapolate.** Predictions are leaf means, bounded by the training targets' range. A tree trained on prices from \$10–\$100 will never predict \$150, regardless of how far out the features go. For extrapolating trends — most obviously in forecasting (Module 10) — this is disqualifying, and the standard fix is to model the trend separately and let the tree handle the residual.
- **High variance.** Resample the data and the top split can change, restructuring the whole tree. Two trees on 90% samples of the same data can look entirely different while predicting similarly — the instability is in the structure, and it's why single-tree "interpretability" is less valuable than it appears.

Greedy splitting is myopic: it can't see a split that's only valuable in combination with a later one (XOR structure defeats a shallow greedy tree). Ensembles partially compensate.

---

## 2. Bagging: averaging down uncorrelated error

Fit $B$ trees on bootstrap resamples, average their predictions. The variance of the average of $B$ identically distributed variables with pairwise correlation $\rho$ is

$$\rho\sigma^2 + \frac{1-\rho}{B}\sigma^2 .$$

Read the two terms carefully, because they contain the entire design logic of random forests:

- The **second term** vanishes as $B\to\infty$. This is ordinary $1/\sqrt{N}$ averaging, and it means more trees never hurt — they just stop helping. There's no overfitting risk in $B$.
- The **first term does not vanish.** It's a floor set by how correlated the trees are.

Anyone who has combined measurements with a shared systematic will recognize this immediately: **correlated errors don't average down.** Adding more trees that all make the same mistake buys nothing, exactly as adding more runs with the same miscalibrated instrument doesn't reduce the calibration error.

### Random forests: engineering $\rho$ downward

Bootstrapping alone leaves trees strongly correlated, because a dominant feature gets chosen as the top split in nearly every tree. Random forests add **feature subsampling**: at each split, consider only a random subset of $m$ features (typically $\sqrt{p}$ for classification, $p/3$ for regression).

This deliberately makes each individual tree *worse* in order to make them *less alike*, lowering $\rho$ and thus the floor. It's a direct bias-for-decorrelation trade, and it's the single idea that makes random forests work.

$m$ is the main hyperparameter: small $m$ means more decorrelation but weaker trees.

### Out-of-bag estimation

Each bootstrap sample omits about $e^{-1} \approx 37\%$ of rows. Predicting each row using only the trees that didn't see it gives a validation estimate **for free**, without a separate CV loop (Module 6, §9).

OOB error is a genuine convenience, with two caveats: it corresponds roughly to leave-one-out CV, and it is *not* valid when rows are grouped or temporally ordered — the same structural concerns from Module 6, §5 apply, and bootstrapping ignores them.

---

## 3. Boosting: successive corrections

Boosting builds an additive model stagewise:

$$F_m(x) = F_{m-1}(x) + \nu \cdot h_m(x)$$

where $h_m$ is a small tree fitted to the *current errors* and $\nu$ is the learning rate.

Gradient boosting makes "errors" precise: $h_m$ is fitted to the negative gradient of the loss with respect to the current predictions. For squared error that's exactly the residuals; for log-loss it's something else, which is why the framework generalizes to any differentiable loss — including quantile loss for prediction intervals and custom asymmetric losses for cost-sensitive problems (Module 1, §2).

**The structural analogy is perturbation theory.** You have an approximate solution; you compute what it fails to explain; you fit a small correction; you add it with a small coefficient and repeat. Each order captures less than the last. Take too many orders with too large a coefficient and you fit noise; take too few and you've truncated the expansion early.

### Why the learning rate and tree count trade off

$\nu$ and $M$ are coupled: halving $\nu$ roughly doubles the $M$ you need. Small $\nu$ (0.01–0.05) with large $M$ generalizes better — many small corrections explore the function space more finely than few large ones — at proportional compute cost.

**Practical approach:** fix $\nu$ small, use early stopping on a validation set to choose $M$, then tune the tree-structure parameters. This makes $M$ effectively free rather than a search dimension.

### Bagging vs boosting

| | **Bagging / RF** | **Boosting** |
|---|---|---|
| Base learners | Deep, low-bias, high-variance | Shallow, high-bias, low-variance |
| Fitting | Parallel, independent | Sequential, each on prior errors |
| Reduces primarily | Variance | Bias |
| More trees | Never hurts | **Can overfit** — needs early stopping |
| Depth | Grow deep | 3–8 typically; depth sets interaction order |
| Tuning burden | Low; works near defaults | Higher; more knobs and they interact |
| Typical accuracy | Good | Usually better on tabular data |
| Robustness to noisy labels | Better | Worse — it will chase the mislabeled points |

The last row matters in practice: boosting's mechanism is to focus on what it currently gets wrong, and a mislabeled row is permanently wrong. With substantial label noise, a random forest is often the safer choice.

---

## 4. Modern implementations

| Library | Distinguishing features |
|---|---|
| **XGBoost** | Explicit L1/L2 penalties on leaf weights; second-order (Newton) split objective; sparsity-aware |
| **LightGBM** | Histogram binning and leaf-wise growth — fastest on large data; native categoricals; `num_leaves` is the key capacity knob |
| **CatBoost** | Ordered boosting to prevent target leakage in categorical encoding; strong defaults; excellent with high-cardinality categoricals |

**The regularization here is the same machinery as Module 5**, applied to a different parameterization. XGBoost's objective includes $\gamma T + \frac12\lambda\sum_j w_j^2 + \alpha\sum_j |w_j|$ over $T$ leaves with weights $w_j$: a complexity cost per leaf plus ridge and lasso penalties on leaf values. Elastic net, on tree leaves.

### The hyperparameters that matter

Tune roughly in this order:

1. **Learning rate** — set small (0.05), leave it.
2. **Number of trees** — early stopping, not search.
3. **Max depth / num_leaves** — the main capacity control; depth $d$ permits $d$-way interactions.
4. **min_child_weight / min_samples_leaf** — the strongest guard against fitting tiny noisy regions.
5. **subsample, colsample_bytree** — stochastic gradient boosting; 0.8 is a reasonable default and adds decorrelation.
6. **reg_lambda, reg_alpha** — explicit penalties.

Random search over this space beats grid search decisively (Module 5, §6.3): only two or three of these matter for any given dataset, and a grid burns its budget on the rest.

### Useful capabilities

- **Monotonic constraints.** Force the model to be monotone in a feature. Where domain knowledge says higher income cannot decrease creditworthiness, this buys real interpretability and regulatory defensibility at almost no accuracy cost (Module 13, Module 15).
- **Custom objectives.** Asymmetric costs from Module 1 can go directly into the loss rather than being handled only at the threshold.
- **Quantile loss.** Fit several quantiles for prediction intervals (Module 11).
- **Native categorical handling** — usually beats one-hot encoding (Module 4, §4).

---

## 5. Why tabular data resists deep learning

Repeated benchmark studies find gradient-boosted trees matching or beating neural networks on tabular problems, with far less tuning. The explanations that hold up:

- **Tabular targets are often piecewise-constant or threshold-like**, which trees represent natively and smooth networks approximate awkwardly.
- **Trees are invariant to uninformative monotone transforms**; networks are not, and must learn to be.
- **Trees are robust to uninformative features**; networks degrade as irrelevant dimensions accumulate.
- **Columns aren't spatially or sequentially structured**, so the inductive biases that make CNNs and transformers powerful don't apply.

Where neural approaches do earn their place: very high-cardinality categoricals benefiting from learned embeddings, multimodal problems combining tabular data with text or images, and settings where transfer learning across related tasks pays.

**The practical default: start with gradient-boosted trees on tabular data.** Justify deviation with a benchmark, not a preference.

---

## 6. What you give up

- **Extrapolation.** Covered in §1, and it's the most common source of surprise. Any target with a trend needs the trend modeled outside the tree.
- **Smoothness.** Predictions are piecewise-constant, producing small discontinuities. Occasionally matters for downstream optimization.
- **Single-model interpretability.** A 1,000-tree ensemble is not readable; you need Module 13's tooling. Note that impurity-based feature importance — the default `feature_importances_` — is **biased toward high-cardinality and continuous features** and should not be trusted. Use permutation importance or SHAP.
- **Calibration.** Boosted trees are typically overconfident. If you need probabilities rather than a ranking, apply Module 7's calibration step.
- **Very high-dimensional sparse data.** Text bag-of-words and similar remain linear-model territory.

---

## 7. Failure modes

| Symptom | Likely cause |
|---|---|
| Forest fine, boosting much worse | Label noise, or no early stopping |
| Boosting keeps improving on train, worsens on validation | No early stopping; learning rate too high |
| Model can't predict beyond the historical range | Trees can't extrapolate; model the trend separately |
| `feature_importances_` dominated by an ID-like column | Impurity bias toward high cardinality; switch to permutation or SHAP |
| Excellent AUC, badly wrong probabilities | Boosted trees are miscalibrated by default |
| OOB error much better than proper CV | Grouped or temporal structure that bootstrapping ignores |
| Enormous accuracy gain over the linear baseline | Check for leakage before celebrating — trees find leaks efficiently |
| Predictions jump discontinuously across a threshold | Expected — piecewise-constant structure |

---

## 8. Practical recipe

1. **Baseline with a regularized linear model** (Module 5). If trees don't beat it meaningfully, prefer the simpler model.
2. **Start with LightGBM or XGBoost defaults**, learning rate 0.05, early stopping on a validation fold.
3. **Skip scaling.** It does nothing here.
4. **Use native categorical handling** rather than one-hot for high cardinality.
5. **Tune with random search** over depth, min_child_weight, subsample, colsample, and the penalties. Roughly 50 draws captures most of the gain.
6. **Keep the CV structure honest** — grouped or temporal splits as Module 6 requires. Trees find leakage faster than linear models do.
7. **Apply monotonic constraints** where domain knowledge supports them.
8. **Calibrate** if you need probabilities (Module 7, §4).
9. **Explain with permutation importance or SHAP**, never with impurity importance (Module 13).
10. **Record the ensemble's size and latency.** A 2,000-tree model may not fit a real-time serving budget (Module 1, §6).

---

## 9. Further reading

- Hastie, Tibshirani & Friedman, *The Elements of Statistical Learning*, ch. 9, 10, 15 — trees, boosting, and the random forest variance decomposition.
- Friedman (2001), "Greedy function approximation: a gradient boosting machine" — the original, and clearer than most summaries of it.
- Chen & Guestrin (2016), "XGBoost: a scalable tree boosting system" — the regularized objective and the systems engineering.
- Grinsztajn, Oyallon & Varoquaux (2022), "Why do tree-based models still outperform deep learning on tabular data?" — careful benchmarking plus the inductive-bias explanation in §5.
- Strobl et al. (2007) — the cardinality bias in impurity-based importance, and why to avoid it.
