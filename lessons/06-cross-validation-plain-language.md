# Cross-Validation: How to Know If Your Model Actually Works

*A plain-language guide — no heavy math required.*

---

## The short version

You want to know how your model will perform on data it has never seen. That's the only thing that matters, and you can't measure it directly — you only have the data you have.

The score your model gets on the data it was trained on is not that number. It's always too good, sometimes absurdly so, because the model has already seen the answers.

**Cross-validation** is the standard workaround: repeatedly hide part of your data from the model, train without it, and see how the model does on the hidden part. Done carefully, this gives an honest estimate. Done carelessly — and there are many ways to be careless — it gives you a confident number that's completely wrong, which is worse than having no number at all.

---

## Part 1: Why the training score is a lie

### The practice exam problem

Imagine a student who studies for an exam by taking the same practice test over and over, with the answer key. Eventually they score 100%. Have they learned the material, or memorized 40 answers?

You can't tell from that score. The only way to find out is to give them questions they haven't seen.

Machine learning models are exactly this student, and by default they're graded on the practice test. A model that's flexible enough will get a perfect training score on *any* data — including pure random noise — by memorizing every point individually. Its training score tells you nothing about whether it learned anything.

### It's not a small effect

This isn't a matter of a few percentage points. Some models can achieve *literally zero* training error on data with no pattern in it at all. A nearest-neighbor model that predicts based on the single closest training example will always find itself as its own closest match. Perfect score, zero knowledge.

The more flexible the model, the bigger the gap. And the gap has a specific cause worth understanding: **it comes from the model responding to individual data points.** A model that bends to accommodate each observation is chasing noise. A rigid model can't, so it doesn't. That's the same mechanism regularization pushes back against, seen from a different angle.

### The consequence

**You cannot evaluate a model on data it was trained on.** There's no correction factor, no rule of thumb. You need data the model has never touched.

---

## Part 2: The simplest fix, and why it isn't enough

Set aside 20–30% of your data. Train on the rest. Test on the part you set aside.

This works, and for large datasets it's often all you need. But with limited data it has two problems:

**The estimate is noisy.** If you hold out 40 examples, your accuracy estimate could easily be off by several percentage points just from which 40 you happened to pick. Two models that differ by 3% are indistinguishable, and a single split gives you no way to know that.

**You're wasting data twice over.** You trained on only 70% of what you have, so your evaluated model is worse than the one you'll eventually deploy (trained on everything). And the 30% you held out contributed nothing to learning.

Cross-validation solves both.

---

## Part 3: k-fold cross-validation

The standard approach:

1. Chop the data into 5 equal chunks ("folds").
2. Train on chunks 1–4, test on chunk 5. Record the score.
3. Train on chunks 1,2,3,5, test on chunk 4. Record.
4. ...and so on, until every chunk has served as the test set once.
5. Average the 5 scores.

Every data point gets used for training four times and for testing exactly once — and when it's used for testing, the model genuinely hasn't seen it. You get five estimates instead of one, so you can average out the luck of the draw, and each model trains on 80% of the data instead of 70%.

### How many folds?

There's a trade-off:

- **Few folds (like 3):** each model trains on less data, so each is weaker than your final model — your estimate comes out pessimistic. But the estimate is stable.
- **Many folds (like 20, or one per data point):** each model trains on nearly everything, so the estimate is accurate. But the training sets almost completely overlap, so the individual scores are nearly the same measurement repeated — averaging them doesn't help as much as you'd hope. And it's slow.

**5 or 10 folds is the standard answer.** Use 10 if you can afford the compute. This is not a deep question; don't agonize over it.

### If your data is small, repeat it

Run the whole 5-fold process several times with different random chunk assignments and average. This washes out the effect of one unlucky partition. Cheap and worth doing whenever you have a few hundred examples rather than a few hundred thousand.

---

## Part 4: Two different jobs (don't mix them up)

There are two reasons to hold out data, and confusing them causes most of the trouble in this area.

**Job 1 — Choosing.** Which model? Which settings? How much regularization? Here you need the *ranking* to be right. If every candidate's score is a bit optimistic in the same way, you'll still pick the right one.

**Job 2 — Reporting.** How good is my final model? Here you need the *number itself* to be right, because you're going to tell people it.

Here's the problem. Suppose you try 200 different settings and report the best score you saw. That score isn't an estimate of how good your model is — it's the **maximum of 200 noisy measurements**. Even if every setting were equally good, the best-looking one would score above average purely by luck. You've picked the luckiest measurement and called it your result.

### The three-way split

| Portion | What it's for | When you use it |
|---|---|---|
| **Training** | Fitting the model | Constantly |
| **Validation** | Comparing options, picking settings | Many times |
| **Test** | The number you report | **Once. At the end.** |

The rule about the test set is absolute and it's the one people break: **if you look at the test score, change something, and look again, you no longer have a test set.** You've turned it into a validation set, and your final number is now optimistic by an amount nobody can estimate.

Split it off at the very beginning. Put it away. Don't look at it until you're done.

---

## Part 5: Splitting your data the right way

Plain k-fold assumes each row of your data is an independent, interchangeable example. Very often it isn't, and every violation has a matching fix.

### The question to ask

**"When this model is deployed, what will a new example actually look like?"**

Your validation setup should reproduce that situation. If new examples will come from patients you've never seen, then your held-out data must contain patients you've never seen. If they'll come from next month, your held-out data must come from later in time. Match the split to the deployment.

### Stratified splitting (for classification)

If only 5% of your examples are positive, random chunking might hand you a fold with almost none. Stratified splitting keeps the same class proportions in every fold.

**Use this by default for classification.** It reduces noise and costs nothing.

### Grouped splitting

Does your data have clusters of related rows? Multiple readings per patient. Multiple photos of the same object. Multiple transactions from one customer. Multiple runs from one machine.

Rows within a cluster are near-duplicates. If random splitting puts some of a patient's readings in training and others in testing, the model can score well by recognizing *the patient*, not by learning the medical pattern. Your validation is measuring the wrong skill entirely.

**Fix:** keep each cluster entirely on one side of the split. Every reading from patient #47 goes to training, or all of them go to testing — never both.

### Time-based splitting

For anything with a time order — sales, sensor readings, prices, user behavior — random splitting means training on the future to predict the past. Your model gets to see next week while predicting this week, a luxury it will never have in production.

**Fix:** always train on earlier data and test on later data. Slide the window forward to get multiple folds.

One extra subtlety: if your data is autocorrelated (today looks a lot like yesterday), examples right at the boundary between training and test are nearly the same example. Leave a small gap between the two — drop a few days on either side of the cut — to keep the boundary clean.

---

## Part 6: When you both tune and report (nested cross-validation)

If you use cross-validation to *choose* settings, you can't also use it to *report* performance — same problem as before, one level up.

The fix is two loops:

- **Inner loop:** within each training portion, run cross-validation to pick the best settings.
- **Outer loop:** take those settings, train, and evaluate on a fold that the inner loop never saw.

The outer scores estimate how well **the whole procedure, including the tuning**, performs — which is the honest thing to report, because tuning is part of what you'd do with new data.

It costs more compute, which is why people skip it. Skipping it is mostly harmless when you tried three settings on 50,000 examples. It can inflate your result by several percentage points when you tried five hundred settings on 300 examples — exactly the situation where people are most tempted to skip it.

One thing that surprises people: different outer folds may pick different settings. That's fine. It's telling you your choice of settings isn't very stable, which is genuinely useful to know.

---

## Part 7: Leakage — the mistake that looks like success

**Leakage** is any way information about your test data sneaks into training. It's the most common serious error in applied machine learning, and it's dangerous precisely because it doesn't look like an error. It looks like a great result.

The warning sign is a result that's **too good**. If your model suddenly hits 99% on a problem experts find hard, the overwhelmingly likely explanation is leakage, not genius.

| Type | What it looks like | How to avoid it |
|---|---|---|
| **Preprocessing leakage** | Scaling, filling in missing values, or selecting features using the whole dataset before splitting | Put every data-dependent step inside a pipeline, inside the CV loop |
| **Target leakage** | An input that's secretly a consequence of the answer — using "medication prescribed" to predict "has the disease" | For each input, ask: was this actually available *before* the outcome happened? |
| **Duplicate leakage** | The same or near-identical rows on both sides of the split | Deduplicate; use grouped splitting |
| **Time leakage** | Any use of future information | Time-based splits with a gap |
| **Test-set shopping** | Trying many things and reporting the best test score | Nested CV; a test set you truly touch once |

### The feature-selection trap

This one is worth spelling out because it's so common and so catastrophic.

Suppose you have 10,000 candidate inputs. You check which ones correlate with the outcome **across your whole dataset**, keep the best 50, then cross-validate a model using those 50. You get a fantastic score.

That score is meaningless. The selection step already looked at every label, including the ones you're about to "hold out." You can reproduce this effect with **completely random data** — 10,000 columns of noise will still contain 50 that happen to correlate with your target, and your cross-validation will happily confirm that they predict it.

The screening must happen *inside* the loop, using only that fold's training data. Same rule as scaling, for the same reason.

---

## Part 8: Reading your results honestly

### Look at the spread, not just the average

If your 5 folds score 0.81, 0.84, 0.83, 0.82, 0.84 — that's a stable model. If they score 0.62, 0.91, 0.75, 0.88, 0.79 — the average of 0.79 is hiding something. Maybe your data has subgroups the model handles very differently, or maybe you just have too little data. Either way, don't report the average alone.

**A caution:** don't turn that spread into a formal confidence interval. The folds aren't independent — their training sets overlap heavily — so the usual formulas understate the real uncertainty. Treat fold-to-fold variation as a stability check, not as proper error bars. If you need real error bars, get them from a genuinely separate test set.

### When results are close, take the simpler model

Cross-validation scores are noisy, and near the top the differences are often smaller than the noise. If a more heavily regularized model scores within the noise of the best one, take it. Simpler models tend to hold up better on genuinely new data.

### Learning curves tell you what to do next

Plot your training score and validation score against how much data you trained on. The shape diagnoses the problem:

- **Both scores are bad, and close together** → your model is too simple. More data won't help. Use a more flexible model or better inputs.
- **Training score good, validation score much worse, gap still closing** → you're overfitting. More data will help, and so will stronger regularization.
- **Both good, close together** → you're done.

This tells you *which lever to pull*, which is worth far more than another decimal place on a single score.

---

## Part 9: Warning signs

| What you see | What's probably happening |
|---|---|
| Validation score much better than the final test score | Leakage somewhere — preprocessing, feature selection, or duplicates |
| Suspiciously good result on a hard problem | Leakage. Assume it until you've ruled it out |
| Fold scores all over the place | Too little data, or subgroups the model handles very differently |
| The score improves every time you adjust something | You're now fitting the validation data; you need a fresh holdout |
| Works in testing, fails on new customers or a new month | Your split didn't match the real situation — needed grouped or time-based |
| A model built from screened features looks amazing | The screening happened outside the folds |
| Error bars from the folds look very tight | The folds overlap, so those aren't real error bars |
| The test set has been looked at more than once | It's a validation set now |

---

## Putting it all together

**The recipe:**

1. **Split off a test set before you do anything else.** Put it away.
2. **Ask what a "new example" means** at deployment — new row, new person, new time period. Choose your split type to match: stratified, grouped, or time-based.
3. **Wrap every data-dependent step in a pipeline** so scaling and feature selection happen inside each fold.
4. **Use 5- or 10-fold cross-validation**, stratified for classification, repeated if your dataset is small.
5. **Do all tuning inside the training data.** If you'll report the tuned score, use nested CV.
6. **Report the spread across folds**, not just the mean.
7. **Retrain on all your training data** with the settings you chose. That's the model you ship.
8. **Evaluate on the test set once.** That's your number, whatever it is.
9. **If it looks too good, go hunting for leakage.** It's usually leakage.

**Three things to remember if you remember nothing else:**

- A score on data the model has seen is not a measure of anything. The model already knows the answers.
- Any number you optimized against, you can no longer trust as a measurement. If you tuned on it, it's a validation score, not a result.
- Your split has to mirror the real situation. If your model will meet new patients, new time periods, or new locations, your validation must too — otherwise you're measuring a skill your model won't get to use.

---

## Where to go next

- **Hands-on:** `scikit-learn`'s user guide on cross-validation — clear diagrams of every splitting strategy, with runnable code. The `Pipeline` documentation is the practical answer to preprocessing leakage.
- **Deeper but readable:** *An Introduction to Statistical Learning*, chapter 5 — covers resampling methods at a comfortable level. Free online.
- **On leakage specifically:** Kapoor & Narayanan's survey of leakage in published scientific machine learning is a sobering read, and very accessible — it catalogs the same handful of mistakes appearing across dozens of fields.
