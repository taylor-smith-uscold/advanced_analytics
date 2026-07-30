# Reporting Model Performance: Confusion Matrices, ROC, and Calibration

*Module 7 — technical register. For readers who think in efficiency and purity, signal and background, and error bars.*

> **Required reading —** ISLP ch. 4.4–4.5 · free PDF at [statlearning.com](https://www.statlearning.com/), plus the scikit-learn [calibration guide](https://scikit-learn.org/stable/modules/calibration.html)

---

## 0. The one-paragraph version

A performance metric is a **projection**. The full description of a classifier's behaviour is a joint distribution over predictions and truth; every scalar score you can quote is a low-dimensional shadow of it, and each one discards something different. Accuracy discards the class balance and the cost asymmetry. ROC-AUC discards the operating point and the prevalence. Precision discards everything about the negatives you correctly rejected. None of them is wrong; they answer different questions. The job of reporting well is to pick the projection that matches the decision your model will actually be used for, quote it with an uncertainty, and be explicit about what you threw away.

---

## 1. Regression metrics

### The main three

**Mean squared error**, $\mathrm{MSE} = \frac1n\sum (y_i - \hat y_i)^2$, and its square root **RMSE**. RMSE carries the units of $y$, which makes it directly interpretable — an RMSE of 3.2 K on a temperature model means something immediately. Squaring makes it dominated by the worst predictions: one point off by 10 contributes as much as a hundred points off by 1.

**Mean absolute error**, $\mathrm{MAE} = \frac1n\sum|y_i - \hat y_i|$. Also in units of $y$, robust to outliers, and a more honest summary of typical performance when your data has a heavy tail.

The choice between them is a statement about your loss function, and it changes what the model optimizes toward: minimizing squared error estimates the conditional **mean**; minimizing absolute error estimates the conditional **median**. If your targets are skewed, those are different quantities, and you should know which one you want.

**RMSE $\gg$ MAE** is itself a diagnostic. It tells you the error distribution has a heavy tail — a few large failures rather than uniform mediocrity. Go find them; they're usually a distinct subpopulation your model handles badly.

### $R^2$ — and what it doesn't tell you

$$R^2 = 1 - \frac{\sum(y_i - \hat y_i)^2}{\sum(y_i - \bar y)^2}$$

This is the fraction of variance in $y$ explained by the model. Being a ratio, it's dimensionless and comparable across problems in a way RMSE isn't.

Two cautions, both about the denominator. First, $R^2$ is a comparison against the trivial "predict the mean" baseline, so it depends on how variable your test set happens to be. **The same model gets a higher $R^2$ on a more heterogeneous sample.** Comparing $R^2$ across datasets is comparing the difficulty of the datasets as much as the quality of the models. Second, on a test set $R^2$ can be negative — that just means your model is worse than predicting the mean, which is real information.

Note also that $R^2$ says nothing about whether the model is *right*. Anscombe's quartet is the canonical demonstration: four datasets with essentially identical regression fits and $R^2$, and completely different structures. Plot your residuals.

### MAPE and the divide-by-zero problem

Mean absolute percentage error is popular in forecasting because it's scale-free, but it's badly behaved: undefined at $y=0$, unbounded for small $y$, and asymmetric — it penalizes overprediction more than underprediction, so minimizing it biases forecasts low. If you need a relative error measure, consider working in log space or using a symmetric or scaled alternative.

### Look at the residuals

Every metric above is a single number summarizing $n$ residuals. Plot them:

- **Residuals vs. fitted values** — curvature means you're missing a nonlinear term; a fan shape means heteroscedasticity (error variance depending on the prediction), which invalidates naive uncertainty estimates.
- **Residuals vs. each feature** — structure here tells you exactly which variable is mis-modelled.
- **Q–Q plot of residuals** — checks the noise-distribution assumption.

If you learned to check residuals in a lab course before quoting a fit, the instinct transfers directly and most ML practitioners don't have it.

---

## 2. Classification: the confusion matrix is the real object

For binary classification with a fixed decision threshold, everything reduces to four counts:

|  | **Predicted positive** | **Predicted negative** |
|---|---|---|
| **Actually positive** | TP | FN |
| **Actually negative** | FP | TN |

Every scalar classification metric is a function of these four numbers. Learning the metrics is mostly learning which ratios people find useful and what each one ignores.

### The physics translation

If you've done a rare-event search, you already know these quantities under different names:

| ML term | Formula | Physics term |
|---|---|---|
| Recall / sensitivity / TPR | TP / (TP + FN) | **Signal efficiency** |
| Precision / PPV | TP / (TP + FP) | **Purity** of the selected sample |
| False positive rate | FP / (FP + TN) | **Background acceptance** (1 − rejection) |
| Specificity / TNR | TN / (TN + FP) | **Background rejection** |
| Threshold | — | **Cut** |

The tension is the familiar one: loosen the cut and you keep more signal but admit more background; tighten it and your sample is purer but you've thrown away real events. There is no setting that wins on both, and where you sit on that curve is a decision about the analysis, not a property of the classifier.

### Accuracy and why it's usually the wrong headline

$\mathrm{Accuracy} = (TP+TN)/n$. Intuitive, and nearly useless when classes are imbalanced.

If 1 in 1,000 events is signal, the classifier "everything is background" scores 99.9% accuracy. Any model you build will be compared against that number and will look, superficially, like it barely helps. Accuracy is dominated by the majority class and hides complete failure on the minority — which is generally the class you built the model for.

**Always state the base rate alongside accuracy**, or don't quote accuracy. The comparison that matters is against the trivial baseline, not against 100%.

### Precision, recall, and F

**Precision** answers: *of the things I flagged, what fraction were real?* This is what matters when acting on a positive is expensive — an unnecessary surgery, a wasted investigation, a false fraud alert on a real customer.

**Recall** answers: *of the real things, what fraction did I catch?* This is what matters when missing one is expensive — a missed tumour, an undetected intrusion.

They trade off against each other as you move the threshold, so quoting one without the other is close to meaningless. You can get 100% recall by flagging everything.

**F1** is their harmonic mean, $2PR/(P+R)$. The harmonic mean is used because it's dominated by the smaller of the two — you can't compensate for terrible precision with excellent recall. **F$_\beta$** generalizes it, weighting recall $\beta$ times as heavily as precision; $\beta = 2$ if misses are worse, $\beta = 0.5$ if false alarms are worse. Choosing $\beta$ is choosing a cost ratio, so choose it deliberately rather than defaulting to F1.

Note what F1 ignores: **true negatives entirely**. That's appropriate when negatives are an uninteresting background, and misleading when correctly rejecting them is part of the job.

### Matthews correlation coefficient

MCC is the correlation coefficient between predicted and true labels, using all four cells, ranging from −1 to +1 with 0 meaning chance. It's the most reliable single-number summary under class imbalance: unlike F1 it doesn't ignore true negatives, and unlike accuracy it isn't fooled by the majority class. Worth reporting when you're forced to give one number.

---

## 3. Threshold-free evaluation: ROC and PR curves

Most classifiers don't output labels — they output a **score** $s(x)$, and a threshold turns that score into a decision. Every metric in §2 therefore depends on a threshold you chose. That conflates two separate questions:

1. Does the model **rank** positives above negatives? (a property of the model)
2. Where should the cut go? (a decision about costs)

Curve-based metrics answer the first by sweeping the threshold across its whole range.

### The ROC curve

Plot **TPR against FPR** as the threshold sweeps from permissive to strict. Equivalently, signal efficiency against background acceptance — the same curve you'd draw to choose a cut in a selection analysis.

- The diagonal is random guessing.
- The top-left corner is perfection.
- The curve is monotone and reparametrization-invariant: any strictly increasing transform of the scores gives the identical curve. **ROC measures ranking quality only, and is blind to the actual score values.**

**AUC** is the area underneath, and it has a clean probabilistic meaning:

> AUC is the probability that a randomly chosen positive receives a higher score than a randomly chosen negative.

(This is the normalized Mann–Whitney $U$ statistic, so AUC is a rank statistic, with everything that implies about robustness.) AUC = 0.5 is chance; AUC = 1.0 is perfect separation. AUC below 0.5 means your ranking is inverted, which is usually a sign-flip bug.

### The property that makes ROC both useful and dangerous

Both axes are normalized *within* a class: TPR divides by the number of positives, FPR by the number of negatives. So **the ROC curve is invariant to class balance.** Change the prevalence from 50% to 0.1% and the curve doesn't move.

That's a genuine virtue for characterizing the model — you get a property of the classifier that isn't contaminated by the sampling of your test set.

It's also a trap for deployment. Consider 1,000,000 negatives, 1,000 positives, and a model at TPR = 0.9, FPR = 0.01. That looks excellent on an ROC plot. But 1% of a million is 10,000 false positives against 900 true ones — a precision of about 8%. Ninety-two out of every hundred alerts are wrong. The ROC curve is fine; the system is unusable.

**ROC-AUC tells you about the model. Precision tells you about the deployment.** Report both.

### The precision–recall curve

Plot **precision against recall** over the same threshold sweep. This does depend on prevalence — deliberately.

- The baseline for a random classifier is a horizontal line at $y = $ prevalence, not a diagonal. Always draw it; a PR curve without its baseline is uninterpretable.
- The summary statistic is **average precision**: the mean of the precisions attained at each threshold, weighted by the increase in recall that threshold buys. It is often described loosely as "the area under the PR curve," but it is deliberately *not* the trapezoidal area — trapezoidal interpolation between PR points is optimistic, because the PR curve is not linear between operating points. Prefer average precision to a trapezoidal AUPRC.

For rare positives, PR curves are far more informative than ROC, because they're sensitive to exactly the thing ROC hides: the flood of false positives from a large negative class. The rule of thumb: **if the positive class is rare and it's the class you care about, lead with the PR curve.**

### Reading a curve, not just its area

The area is an average over *all* thresholds, including ones you would never use. If you'll operate at 90% recall or better, then only the right-hand end of the PR curve is relevant, and two models with identical AUC can differ enormously there. Look at the curve near your intended operating point, and consider reporting a partial AUC or a fixed-recall precision instead.

---

## 4. Calibration: are the probabilities real?

Ranking is not everything. A model can rank perfectly and still output probabilities that are systematically wrong — and if any downstream decision uses the probability as a number (expected cost, expected value, risk communication), that matters.

**Calibration**: among all cases assigned probability $\approx p$, the empirical frequency of positives should be $\approx p$. Of the days forecast at 30% rain, it should rain about 30% of the time.

**Discrimination and calibration are independent.** A model that outputs $0.5 + \epsilon\cdot s(x)$ for tiny $\epsilon$ has perfect AUC and useless probabilities. Conversely, a model that always outputs the base rate is perfectly calibrated and completely uninformative.

### Measuring it

**Reliability diagram.** Bin predictions by score, plot mean predicted probability against observed frequency, compare to the diagonal. Systematic deviation above the diagonal means underconfidence, below means overconfidence.

**Brier score.** Mean squared error of the predicted probabilities, $\frac1n\sum(p_i - y_i)^2$. Decomposes cleanly into calibration + refinement terms.

**Log loss** (cross-entropy), $-\frac1n\sum[y_i\log p_i + (1-y_i)\log(1-p_i)]$. Punishes confident mistakes savagely — a confident wrong prediction at $p \to 0$ or $1$ contributes unboundedly.

Both are **proper scoring rules**: they are minimized, in expectation, only by reporting your true beliefs. There is no way to game them by shading your probabilities, which is exactly the property you want from a scoring rule.

### Fixing it

Poorly calibrated models are common: SVMs and boosted trees are typically overconfident, and modern neural networks are notoriously so. Two standard post-hoc fixes, both fitted **on held-out data** (never on the training set, or you're just refitting the training noise):

- **Platt scaling** — fit a logistic function to map scores to probabilities. Parametric, works with little data.
- **Isotonic regression** — fit a monotone step function. More flexible, needs more data, can overfit.

Both are monotone transforms, so **neither changes the ROC curve or AUC at all** — they change the numbers, not the ranking. That fact is a good check on whether you've understood the distinction.

---

## 5. Choosing the operating point

The threshold should come from costs, not from convention. A default of 0.5 encodes the assumption that a false positive and a false negative are equally bad, which is almost never true and is rarely stated.

With costs $C_{FP}$ and $C_{FN}$, the expected-cost-minimizing threshold on a calibrated probability is

$$p^* = \frac{C_{FP}}{C_{FP} + C_{FN}}.$$

If a miss is nine times worse than a false alarm, threshold at 0.1. Note that this requires calibrated probabilities to be meaningful — another reason calibration matters.

If you genuinely can't quantify the costs, you can still constrain the problem: *"maximize precision subject to recall ≥ 0.95"* is a well-posed operating-point choice and forces the cost conversation into the open.

**Select the threshold on validation data, not test data.** It's a hyperparameter like any other.

---

## 6. Multi-class, and averaging

With $K$ classes, the confusion matrix is $K \times K$ and per-class metrics get averaged. How you average is a substantive choice:

- **Macro** — unweighted mean over classes. Every class counts equally, so rare classes have full influence. Use when small classes matter as much as big ones.
- **Micro** — pool all TP/FP/FN across classes, then compute. Every *sample* counts equally, so it's dominated by frequent classes. For single-label problems, micro-F1 equals accuracy.
- **Weighted** — mean weighted by class support. A compromise; can obscure minority-class failure.

Quoting "F1 = 0.82" for a multi-class problem without saying which averaging you used is uninformative — the three numbers can differ by a lot.

**Always look at the full confusion matrix, not just the summary.** It shows you *which* classes are confused with which, and that pattern is where the actionable information lives — confusions between visually similar classes mean something quite different from confusions with the majority class.

---

## 7. Uncertainty: put an error bar on it

An accuracy of 0.847 quoted to three decimals from a 200-sample test set is a false precision that no experimentalist would tolerate, and it's routine in ML papers.

**Analytic interval.** For accuracy or any proportion, a Wilson score interval on $n$ test samples. With $n = 200$ and $\hat p = 0.85$, the 95% interval is roughly $[0.79, 0.89]$. Your third decimal place is noise.

**Bootstrap.** Resample the test set with replacement, recompute the metric, repeat 1,000 times, take percentiles. This works for any metric including AUC and average precision, and it's the practical default.

**Comparing two models.** Use *paired* resampling — evaluate both models on the same resampled test sets and bootstrap the difference. The models' errors are correlated (hard examples are hard for both), and paired comparison exploits that, giving much tighter intervals than comparing independent CIs. For classifiers on the same test set, McNemar's test on the discordant pairs is the classical exact alternative.

The habit to import from physics: **no number without an uncertainty, and no comparison without asking whether the difference exceeds it.**

---

## 8. Failure modes

| Symptom | What's actually going on |
|---|---|
| High accuracy on imbalanced data | Model predicts the majority class; check per-class recall |
| Great AUC, unusable in production | Rare positives; look at the PR curve and absolute FP counts |
| Metrics improved after "just one more tweak" | You're fitting the test set; that number is now optimistic |
| Model beats the state of the art by a wide margin | Leakage, until proven otherwise |
| Confident, wrong probabilities | Miscalibration; fit Platt or isotonic on held-out data |
| Test score much worse than CV score | Distribution shift or leakage in the CV setup |

---

## 9. Practical recipe: a reporting checklist

1. **State the baseline.** Majority class for classification, mean predictor for regression. Every metric is only interpretable relative to it.
2. **State the class balance.** Without prevalence, precision and accuracy can't be interpreted.
3. **Report a threshold-free curve and a fixed operating point.** AUC or average precision for model quality; precision/recall at your chosen threshold for what deployment looks like.
4. **Show the confusion matrix.** It contains more information than any scalar derived from it.
5. **Justify the threshold** in terms of costs, and say what they are.
6. **Check calibration** if any downstream decision uses the probability as a number.
7. **Quote uncertainties**, and don't report more digits than they support.
8. **Say what the test set was** — how it was split, whether it's temporally or demographically distinct, and whether it was used more than once.
9. **Break performance down by subgroup.** Aggregate metrics hide failures concentrated in specific populations, which is both a scientific and an ethical problem.

---

## 10. Further reading

- Fawcett (2006), "An introduction to ROC analysis" — the standard readable treatment; covers ROC convex hulls and iso-cost lines.
- Saito & Rehmsmeier (2015), "The precision-recall plot is more informative than the ROC plot when evaluating binary classifiers on imbalanced datasets" — the title is the argument, and it's well demonstrated.
- Guo et al. (2017), "On calibration of modern neural networks" — documents how badly miscalibrated large networks are and evaluates the fixes.
- Gneiting & Raftery (2007), "Strictly proper scoring rules, prediction, and estimation" — the theory of why Brier and log loss are the right objects.
- Hastie, Tibshirani & Friedman, *The Elements of Statistical Learning*, ch. 7 — loss functions and evaluation in the broader model-assessment context.
