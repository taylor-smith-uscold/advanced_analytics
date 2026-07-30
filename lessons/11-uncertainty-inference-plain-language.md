# How Sure Are We? A Plain-Language Guide to Uncertainty

*Module 11 — plain-language register. What an error bar is, and what it doesn't cover.*

> **Required reading —** Angelopoulos & Bates, *A Gentle Introduction to Conformal Prediction* · [PDF](advanced_analytics_readings/11_angelopoulos_bates_conformal_prediction.pdf)

---

## The short version

A number without a range is half a result. "Churn will be 8.2%" is a claim; "churn will be 8.2%, probably between 6 and 11" is information someone can plan around.

Three distinctions do most of the work here:

1. **A range around an average is much narrower than a range around an individual.** Mixing these up is the single most common uncertainty error, and it usually understates the real spread by a factor of ten.
2. **Some uncertainty shrinks with more data; some doesn't.** Knowing which kind you have answers "should we collect more?"
3. **The range your software prints only covers random sampling variation.** It says nothing about whether your model, your assumptions, or your data collection were right — and those are usually the bigger problem.

The practical toolkit is small: the **bootstrap** for almost any error bar you need, and **conformal prediction** for honest ranges around individual predictions.

---

## Part 1: The mistake that matters most

Two completely different questions:

**"What's the average spend for customers like this?"** → Maybe $340, plus or minus $12.

**"What will *this particular customer* spend?"** → Maybe $340, plus or minus $180.

Same model, same prediction, wildly different ranges. The second includes all the person-to-person variability that the average smooths away.

The standard names: the narrow one is a **confidence interval** (about an average), the wide one is a **prediction interval** (about an individual outcome). Worth knowing, because software labels them this way and rarely explains the difference.

Here's why the difference matters so much: **the first range keeps shrinking as you collect more data. The second one doesn't.** With a million customers you'll know the average very precisely — and you'll still have almost no idea what any individual will do, because people vary.

**Almost every business question is about the individual.** Will *this* customer churn? Will *this* store hit its target? How much stock does *this* SKU need?

**And almost every automatically-produced range is the average one.** Your software's default is usually the narrow interval, and it gets pasted into a slide as if it described individual outcomes.

If a forecast says "1,200 ± 30" and the actual weekly numbers bounce between 900 and 1,500, you're looking at this error.

---

## Part 2: Two kinds of uncertainty

**Uncertainty from genuine randomness.** Some customers churn, some don't, and no amount of data will tell you which in advance. Coin flips are unpredictable even when you know the coin is fair.

**Uncertainty from not knowing enough.** You're not sure whether the effect is 3% or 5% because you only have 400 observations.

The second kind shrinks with more data. **The first kind never does.**

This distinction answers a question you'll be asked constantly: *"Can we make the forecast more precise?"*

If your range is dominated by real variability, the answer is no — not with more rows. The process genuinely is that variable, and the honest response is to say so and discuss whether a different question, or better inputs, would help. Promising a tighter number and then collecting more data is a way to waste a quarter.

### The kind nobody counts

There's a third kind that standard methods ignore entirely: **maybe your model is just wrong.**

Every error bar you compute assumes the model form is correct. It doesn't account for the possibility that a different set of features, or a different algorithm, would have given a materially different answer.

This is a big part of why forecast ranges are consistently too narrow (Module 10). A practical partial fix: build the model several reasonable ways and see how much the answers differ. If three sensible approaches disagree by more than your stated error bar, your error bar is too small.

---

## Part 3: The bootstrap — one technique for almost everything

Most useful uncertainty tool for practical work, and the idea is simple enough to explain in a sentence:

> **Pretend your sample is the population. Draw new samples from it, with replacement, and see how much your answer moves.**

Concretely: you have 500 customers and computed a median spend. Randomly draw 500 customers *from your 500, allowing repeats*, recompute the median. Do that a thousand times. You now have a thousand medians, and their spread is your uncertainty.

**Why this is valuable:** it works for *anything* you can compute. Medians, ratios, AUC, the difference between two models, the 90th percentile, correlation. No formulas required, no assumptions about distributions.

### Three ways to get it wrong

**Resample the wrong thing when your data has groups.** If you have 50 customers with 20 orders each, resampling *orders* pretends you have 1,000 independent pieces of information. You have 50. **Resample customers, not orders** — the same grouping issue as Module 6.

**Resample the wrong thing with time series.** Shuffling days destroys the fact that consecutive days are related. Resample contiguous *chunks* instead.

**Use it with very little data.** Below roughly 20 observations, your sample isn't a good enough stand-in for the population.

### Comparing two models: do it in pairs

Common mistake: compute a range for Model A, a range for Model B, notice they overlap, conclude there's no difference.

**Overlapping ranges do not mean no difference.** They can overlap substantially while the difference is clearly real.

The right method: for each bootstrap round, evaluate **both models on the same resampled data**, and record the *difference*. Then look at the spread of those differences.

This is much more sensitive, because hard cases are hard for both models — comparing them head-to-head on identical data cancels out that shared difficulty. Two models can look statistically indistinguishable by the overlap method and clearly distinguishable when compared properly.

---

## Part 4: Testing many things at once

Test 20 things at the usual threshold when nothing is really going on, and you'll find about one "significant" result. Test 100 and you'll find five.

Standard corrections:

- **Holm's method** — when any single false alarm is costly. Strict. (Use this rather than the better-known Bonferroni; it's strictly better and just as easy.) Methods of this kind control what's called the *family-wise error rate*: the chance of making **even one** false claim anywhere in the set.
- **Benjamini–Hochberg** — when you're screening lots of candidates and can tolerate a known fraction of false leads. Much more sensitive. This one controls the *false discovery rate*: not the chance of any error, but the expected **share** of your flagged findings that are wrong. Accepting that one in twenty of your leads is spurious is often a perfectly good trade when you're generating leads rather than making claims.
- **Hierarchical models (Module 9)** — worth considering as an *alternative* rather than an addition. Instead of adjusting thresholds after the fact, it shrinks extreme estimates toward the average, which removes most spurious extremes at the source.

**None of these fix the deeper problem.** Corrections account for the tests you *ran*. They can't account for the tests you *would have* run if the data had looked different — the segments you'd have checked, the outlier rule you'd have chosen. Only deciding in advance fixes that.

---

## Part 5: Conformal prediction — honest ranges around individual predictions

This is the most useful recent addition to the toolkit, and it's much simpler than its name suggests.

**What it gives you:** a range around each individual prediction that contains the true value the promised percentage of the time. From *any* model. With essentially no assumptions.

**How it works:**

1. Train your model normally.
2. On a held-out set the model never saw, record how far off it was for each row.
3. Find the 90th percentile of those errors — call it 45.
4. Your 90% prediction range for a new case is: prediction ± 45.

That's genuinely it. And the coverage guarantee holds.

**What makes it valuable:** it works even if your model is bad. A bad model produces *wide* ranges, not wrong coverage. Compare that to standard intervals, which quietly break when their assumptions fail.

### Two things to know

**The basic version gives every prediction the same width**, which is wrong when some cases are inherently harder. There's a better version (conformalized quantile regression) that adapts the width — narrow for easy cases, wide for hard ones — while keeping the guarantee. Use that one; libraries like `MAPIE` implement it directly.

**The guarantee is about your data overall, not about every subgroup.** You could have 90% coverage in total and only 70% for a particular customer segment. Given Module 15, check coverage by subgroup rather than trusting the headline number.

**For classification** it gives you a *set* of possible labels rather than one. Sometimes {fraud}, sometimes {fraud, review, legitimate}. The size of the set is an honest signal of how confused the model is — often more useful operationally than a probability, because "the model can't narrow this below three options" is directly actionable.

---

## Part 6: What your error bar doesn't cover

The range your software prints describes one thing: how much your answer would wobble if you'd collected a different random sample.

It says nothing about:

| Source of error | Covered by your error bar? |
|---|---|
| Random sampling variation | ✅ Yes |
| Whether your model form is right | ❌ No |
| Whether something else caused the effect (Module 2) | ❌ No |
| Whether your fields are measured accurately (Module 4) | ❌ No |
| Whether the world has changed since (Module 14) | ❌ No |
| Whether your metric measures what you care about (Module 1) | ❌ No |

In observational work — anything that isn't an experiment — the sampling variation is usually **the smallest** of these.

So a tight confidence interval on an observational finding is precise about the wrong thing. Report it, and report alongside it how much your conclusion would change if the assumptions were somewhat off (Module 2, Part 6).

---

## Part 7: Warning signs

| What you see | What's probably happening |
|---|---|
| Actual outcomes fall way outside your ranges | You reported an average range for an individual outcome |
| The range keeps shrinking as data grows, for individual predictions | Same error — individual ranges have a floor |
| Error bars look too tight on customer-level data | Bootstrapping rows instead of customers |
| "The ranges overlap, so no difference" | Wrong test — compare the difference directly |
| Lots of significant subgroup findings | No correction for multiple tests |
| Coverage fine overall, poor for one segment | Guarantees are overall, not per-group |
| More data isn't tightening things | Real variability, not ignorance — more data won't help |
| A result reported to four decimal places | The range doesn't support that precision |

---

## Putting it all together

**The recipe:**

1. **Ask what the range is about** — the average for a group, or one individual outcome? Pick the right one. This is the highest-value question in this module.
2. **Bootstrap for anything else** — resampling at the right level (customers, not orders; chunks, not days).
3. **Compare models in pairs**, on the same resampled data, looking at the difference.
4. **Correct for multiple tests**, or use hierarchical models to avoid needing to.
5. **Use conformal prediction for individual ranges**, and check the coverage actually holds on held-out data.
6. **Check coverage by segment**, not just overall.
7. **Say what your range doesn't cover** — model choice, confounding, measurement, drift.
8. **Round sensibly.** Four decimals on a ±5-point range is false precision.

**Three things to remember if you remember nothing else:**

- **A range around an average is not a range around an individual.** The second is far wider and never shrinks to zero. Almost every business question wants the second; almost every tool gives you the first.
- **Overlapping error bars don't mean no difference.** Compare the difference directly.
- **Your error bar covers sampling noise only.** In observational work that's usually the smallest thing you should be worried about.

---

## Where to go next

- **On conformal prediction:** "A Gentle Introduction to Conformal Prediction" by Angelopoulos & Bates — genuinely gentle, and the fastest route to using it. The `MAPIE` library (Python) implements everything discussed here.
- **On the bootstrap:** *An Introduction to the Bootstrap* by Efron & Tibshirani — the classic, and clear about the failure cases.
- **On communicating uncertainty:** Gelman & Greenland's short piece arguing these should be called "uncertainty intervals" — useful before your next stakeholder conversation.
