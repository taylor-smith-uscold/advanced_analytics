# Measuring Success: Accuracy, ROC Curves, and What They Hide

*Module 7 — plain-language register. How to report how well a model works — no heavy math required.*

---

## The short version

Every performance score is a **summary**, and every summary throws something away. Accuracy throws away the fact that one class might be a hundred times rarer than the other. ROC curves throw away how many false alarms you'll actually get. Precision throws away everything about the cases you correctly ignored.

None of these are wrong. They answer different questions. The skill is picking the one that matches the decision your model will actually be used for, saying what you left out, and putting an honest uncertainty on the number.

The single most common reporting failure is quoting one number — usually accuracy — that happens to look good, without mentioning what it conceals.

---

## Part 1: Regression — when you're predicting a number

### The main options

**RMSE (root mean squared error)** — the typical size of your errors, in the same units as what you're predicting. Predicting house prices? An RMSE of $32,000 means something immediately. Because errors are squared before averaging, big misses count disproportionately: one prediction off by $100,000 hurts as much as a hundred off by $10,000.

**MAE (mean absolute error)** — the average error size, no squaring. Also in your original units, and more resistant to a handful of extreme cases. It answers "how far off am I typically?" in the most literal sense.

Which to use is a real decision, not a formality. It determines what "good" means:

> If a few enormous errors are catastrophic (structural loads, medication doses, safety margins), use RMSE — you want the model to fear its worst cases. If occasional big misses are tolerable and you care about typical performance, use MAE.

**A useful diagnostic:** if RMSE is much larger than MAE, your errors are lopsided — mostly small, with a few big failures. Go find those failures. They're usually a specific subgroup your model handles badly, and that's actionable information a single score won't give you.

### R² and its limits

**R²** answers: how much better is my model than just predicting the average every time? An R² of 0.75 means you've explained 75% of the variation. It has no units, so unlike RMSE you can compare it across different problems.

Two things to know:

**It depends on how varied your test data is.** The same model scores higher R² on a more diverse sample, because the "just predict the average" baseline it's being compared against is worse there. Comparing R² across two datasets partly compares the datasets, not the models.

**R² can be negative** on new data. That means your model is doing worse than predicting the average — which is real, useful information, not a bug.

### Always look at the errors, not just the score

Every number above compresses hundreds of individual errors into one figure. Plot them:

- **Errors against predicted value.** If errors grow as predictions get larger, or if there's a curve, your model is systematically wrong in a fixable way.
- **Errors against each input.** Structure here tells you exactly which variable is being mishandled.

Two models with identical R² can be right and wrong in completely different ways. The plot shows you; the number doesn't.

---

## Part 2: Classification — the confusion matrix is the real thing

For a yes/no prediction, everything comes down to four counts:

|  | **Model says yes** | **Model says no** |
|---|---|---|
| **Actually yes** | True positive ✅ | False negative ❌ (a miss) |
| **Actually no** | False positive ❌ (a false alarm) | True negative ✅ |

Every classification score you've ever heard of is just some ratio of these four numbers. Learning the metrics is mostly learning which ratios are useful and what each one ignores.

**Look at this table for your model before you look at any score derived from it.** It contains more information than all of them combined.

### Accuracy: the one everybody quotes, usually wrongly

Accuracy is the fraction you got right. Intuitive, and often badly misleading.

Suppose 1 in 1,000 transactions is fraudulent. The model "nothing is ever fraud" is **99.9% accurate**. It's also completely worthless — it catches zero fraud.

Any real model you build will score somewhere around 99.9% too, and will look, superficially, like it's barely doing anything. Accuracy is dominated by whichever class is common, and hides total failure on the class you actually built the model for.

> **If you quote accuracy, quote the base rate next to it.** "94% accurate" means something very different when 50% of cases are positive than when 3% are. Without that context, the number is uninterpretable.

### Precision and recall

These two split the problem into the questions people actually care about.

**Precision:** *Of the cases I flagged, how many were real?*
This matters when acting on a positive is costly — an unnecessary biopsy, a wasted investigation, a fraud alert that freezes a real customer's card.

**Recall:** *Of the real cases, how many did I catch?*
This matters when missing one is costly — an undetected tumor, a security breach, a failing part on an aircraft.

**They trade off, always.** You can hit 100% recall by flagging everything — you'll catch every real case, and your precision will be terrible. You can hit high precision by flagging only the one case you're absolutely certain about — and miss almost everything.

Quoting one without the other is close to meaningless. Any impressive-sounding recall figure needs its precision alongside it, and vice versa.

### Worked example

Cancer screening on 10,000 people, of whom 100 actually have the disease. Your model flags 500 people, and 80 of them are genuinely sick.

- **Recall = 80/100 = 80%.** You caught four out of five real cases.
- **Precision = 80/500 = 16%.** Of the people you alarmed, five out of six are healthy.
- **Accuracy = 95.8%.** Which tells you essentially nothing.

Whether this model is good depends entirely on context. For an initial screen followed by a cheap confirmatory test, 80% recall is valuable and the false alarms are manageable. For anything that triggers an invasive procedure, 16% precision is unacceptable.

**The same model, the same numbers, opposite conclusions.** That's why the metric has to match the decision.

### F1: combining them

**F1** blends precision and recall into one number, in a way that's dragged down by whichever is worse. You can't compensate for terrible precision with excellent recall.

Useful when you need a single figure. But note the assumption baked in: F1 treats false alarms and misses as equally bad. That's rarely true. If misses are worse, there are weighted versions (F2 leans toward recall, F0.5 toward precision) — pick deliberately rather than defaulting.

Also worth knowing: F1 completely ignores true negatives. That's appropriate when the negatives are boring background, and misleading when correctly clearing them is part of the job.

---

## Part 3: The threshold, and curves that sweep across it

### Models don't output yes/no — they output a score

Almost every classifier gives you a number: a confidence, a probability, a risk score. Something has to convert that into a decision, and that something is a **threshold**. Flag it if the score is above 0.5, say.

That threshold is a choice, and it's usually made by accident. But every number in Part 2 depends on it. Slide it lower and recall goes up while precision goes down; slide it higher and the reverse. **You haven't measured one model — you've measured one model at one arbitrary setting.**

This confuses two separate things:

1. Does the model *rank* well — does it tend to give real positives higher scores than negatives? (a property of the model)
2. Where should we set the cutoff? (a decision about costs)

Curves separate these by sweeping the threshold across every possible value.

### The ROC curve

For each possible threshold, plot two things:

- How many real positives you catch (the **true positive rate**, which is just recall)
- How many negatives you wrongly flag, as a *fraction of all negatives* (the **false positive rate**)

Sweeping from a very permissive threshold to a very strict one traces a curve.

- A model with no skill traces the diagonal line.
- A perfect model goes straight up the left edge and along the top.
- The further toward the top-left corner, the better.

**AUC** ("area under the curve") is the single-number summary, and it has a nice plain meaning:

> AUC is the probability that a randomly chosen positive case scores higher than a randomly chosen negative case.

0.5 is coin-flipping. 1.0 is perfect separation. 0.8 means: pick one real case and one non-case at random, and 80% of the time the model rates the real one higher.

### The ROC trap

Here's the thing about ROC that catches people out.

The false positive rate is *a fraction of all negatives*. If negatives vastly outnumber positives, a tiny-looking false positive rate is an enormous number of false alarms.

Concretely: 1,000,000 legitimate transactions, 1,000 fraudulent ones. Your model catches 90% of fraud with a 1% false positive rate. On an ROC plot that's a beautiful curve, way up in the top-left.

Now count actual cases. 1% of a million is **10,000 false alarms**, against 900 real catches. Precision is about 8% — twelve out of thirteen alerts are wrong. Your fraud team quits.

The curve was fine. The system is unusable.

> **ROC tells you about the model. Precision tells you about deployment.** When positives are rare, always compute the real counts.

### The precision–recall curve

Same idea, different axes: plot precision against recall as the threshold sweeps. This one *does* respond to how rare your positive class is, which for rare-event problems is exactly what you want.

One critical detail: **the baseline isn't the diagonal.** A random classifier's precision equals the fraction of cases that are positive — 0.1% in the fraud example. So a PR curve sitting at 30% precision is doing *three hundred times* better than chance, even though 30% sounds unimpressive. Always note the baseline, or the curve can't be read.

**Rule of thumb: if your positive class is rare and it's the one you care about, lead with the precision–recall curve.**

### Look at the curve, not just the area

AUC averages over every threshold, including ones you'd never use. If you'll operate at 95% recall or better, only the far end of the curve matters — and two models with identical AUC can differ enormously there.

Find your intended operating point on the curve and report the numbers *there*.

---

## Part 4: Are the probabilities real? (Calibration)

Ranking isn't everything. A model can rank cases perfectly and still produce probabilities that are nonsense — and if anyone uses those probabilities as actual numbers (expected costs, risk communicated to a patient, automated decisions), that matters.

**Calibration** means: among all the cases you assigned 30% to, about 30% should turn out positive.

The weather forecast is the intuitive example. When a forecaster says "30% chance of rain," you want it to rain on about 30% of those days. A forecaster who says 30% and it rains 80% of the time is miscalibrated — even if they perfectly rank rainy days above dry ones.

**These are separate properties.** A model whose outputs are all between 0.49 and 0.51 can have a perfect AUC — it ranks flawlessly — while its "probabilities" are meaningless. Conversely, a model that always outputs the overall base rate is perfectly calibrated and completely useless.

### Checking and fixing it

**To check:** group your predictions into buckets (0–10%, 10–20%, and so on), and for each bucket compare the average predicted probability to the fraction that actually turned out positive. Plot them. Points should sit near the diagonal. Systematically below it means your model is overconfident.

**Overconfidence is the norm.** Boosted trees and neural networks are usually far more confident than they deserve to be.

**To fix:** there are standard post-hoc corrections (Platt scaling and isotonic regression) that learn a mapping from your model's raw scores to honest probabilities. Fit them on held-out data, never on the training data.

**To score it in one number:** the two standard measures are the **Brier score** (the average squared gap between the predicted probability and what actually happened) and **log loss** (which punishes confident mistakes far more harshly). Both have a property worth knowing about: the only way to score well is to report what you actually believe. Shading your probabilities toward the middle to look cautious, or toward the extremes to look decisive, makes your score worse either way. That's exactly what you want from a scoring rule, and it's why these two are used rather than something more intuitive.

A nice detail that clarifies the whole distinction: these corrections **don't change AUC at all**. They only stretch and squeeze the scores without reordering them. They fix the numbers, not the ranking — because those were always two separate things.

---

## Part 5: Setting the threshold on purpose

The default threshold of 0.5 encodes a hidden assumption: that a false alarm and a miss are equally bad. That's almost never true, and almost never stated.

Decide it from costs instead. If a miss is nine times worse than a false alarm, your threshold should be much lower than 0.5 — you should be willing to accept many more false alarms to avoid a miss. (Roughly: threshold at 0.1.)

If you genuinely can't put numbers on the costs, you can still frame it usefully:

> *"Maximize precision, subject to recall being at least 95%."*

That's a well-posed choice, and it forces the cost conversation into the open rather than leaving it to a library default.

**Pick your threshold using validation data, not your test set.** It's a setting like any other, and tuning it on test data contaminates your final number.

---

## Part 6: More than two classes

With several categories, you get a bigger confusion matrix and you have to decide how to average per-class scores. The choice matters:

- **Macro-averaging** — treat every class equally, regardless of size. Rare classes count as much as common ones. Use when small categories matter.
- **Micro-averaging** — treat every *example* equally. Dominated by the common classes.
- **Weighted averaging** — in between; can hide poor performance on small classes.

These can differ a lot. Saying "F1 = 0.82" without specifying which averaging you used doesn't convey much.

And again: **look at the full confusion matrix.** Knowing that your model confuses two genuinely similar categories is a completely different situation from knowing it dumps everything into the largest class — and no averaged score distinguishes them.

---

## Part 7: Put an error bar on it

An accuracy of "84.7%" measured on 200 test examples is false precision. The real uncertainty on that number is roughly ±5 percentage points. The third digit is noise.

**Simple approach:** for accuracy or any percentage, standard formulas give you a confidence interval from the test set size. Use one.

**General approach (the bootstrap):** resample your test set with replacement, recompute the metric, repeat a thousand times, and look at the spread. This works for any metric, including AUC, and it's easy to implement.

**Comparing two models:** evaluate both on the *same* resampled test sets and look at the distribution of the *difference*. Hard examples tend to be hard for both models, and comparing them head-to-head on identical data cancels out that shared difficulty — giving a much more sensitive comparison than eyeballing two separate confidence intervals.

The habit worth building: **no number without an uncertainty, and no claim that one model beats another without checking the gap is bigger than the noise.**

---

## Part 8: A reporting checklist

1. **State the baseline.** What does "always guess the majority class" or "always predict the average" score? Every metric is only meaningful relative to that.
2. **State the class balance.** Without it, accuracy and precision can't be interpreted.
3. **Report a curve and a specific operating point.** AUC for the model's overall quality; precision and recall at your actual threshold for what deployment looks like.
4. **Show the confusion matrix.** It contains everything.
5. **Say why your threshold is where it is**, in terms of costs.
6. **Check calibration** if anyone will use the probabilities as numbers.
7. **Give uncertainties**, and don't report more digits than they justify.
8. **Describe the test set** — how it was separated, whether it's from a different time or population, and how many times you looked at it.
9. **Break the results down by subgroup.** An overall score can look fine while the model fails badly for a specific population. That's both a scientific problem and, often, an ethical one.

## Part 9: Warning signs

| What you see | What's probably happening |
|---|---|
| Impressive accuracy on rare-event data | The model predicts the common class; check recall on the rare one |
| Great AUC, unusable in practice | Rare positives — count the actual false alarms |
| Score improved after "one more tweak" | You're fitting the test set; that number is now optimistic |
| Model beats everything by a wide margin | Data leakage, until proven otherwise |
| Confident predictions that are often wrong | Miscalibration; apply a correction on held-out data |
| Test score much worse than validation | Leakage in your validation setup, or the test data is genuinely different |

---

## Putting it all together

**Three things to remember if you remember nothing else:**

- **Every single-number score is a summary that hides something specific.** Accuracy hides the class balance. AUC hides the operating point and how many false alarms you'll actually field. Precision hides everything you correctly let through. Pick the one that matches the decision, and say what you dropped.
- **A number with no baseline and no error bar isn't a result.** 85% accuracy means nothing until you know what predicting the majority class would have scored, and how much a different test sample would have moved it.
- **Ranking well and being right about probabilities are two different achievements.** A model can do the first perfectly while failing the second completely, and only one of those matters if someone downstream multiplies your probability by a dollar amount.

---

## Where to go next

- **Hands-on:** `scikit-learn`'s "Metrics and scoring" user guide — every metric here with code and worked examples, including the plotting utilities for ROC, PR, and calibration curves.
- **On ROC specifically:** Tom Fawcett's *"An Introduction to ROC Analysis"* is the standard reference and is genuinely readable without a statistics background.
- **On why PR beats ROC for rare events:** Saito & Rehmsmeier (2015) — the title says the argument and the paper demonstrates it clearly with pictures.
- **Deeper:** *An Introduction to Statistical Learning*, chapter 4 — classification and evaluation at a comfortable level. Free online.
