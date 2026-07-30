# Explaining a Model: A Plain-Language Guide

*Module 13 — plain-language register. How to explain what a model is doing, and what those explanations don't mean.*

> **Required reading —** Molnar, *Interpretable Machine Learning* · [christophm.github.io/interpretable-ml-book](https://christophm.github.io/interpretable-ml-book/)

---

## The short version

Stakeholders ask "why did it say that?" — and with modern models you can't just point at a coefficient. A boosted ensemble of a thousand trees isn't something anyone can read.

There's a good toolkit for this. But it answers a narrower question than people think:

> **These tools tell you how *the model* uses its inputs. They do not tell you how the world works.**

That distinction is the entire content of Module 2, and no explanation tool bridges it. A model can lean heavily on "contacted support" to predict churn — correctly, because it does predict churn — and reducing support contacts would do nothing. The explanation is right. The causal reading of it is wrong, and it's the most common mistake in this area by a wide margin.

The other thing to know: **when your inputs are correlated with each other, most of these methods misbehave** in specific, predictable ways. Knowing which ones and how is most of what makes this module useful.

---

## Part 1: Three questions people confuse

| The question | The tool | What you can honestly claim |
|---|---|---|
| "What is this model doing?" | Feature importance | Something about the model |
| "Why this particular prediction?" | SHAP, counterfactuals | Something about the model, on this case |
| "What if we change something?" | **Module 2** | Something about the world |

**Only the third one supports a decision to act.** None of the tools in this module answer it.

Say this out loud in the meeting. When someone sees "discount code" at the top of a SHAP chart and proposes sending more discount codes, the answer is: "That tells us the model uses it to predict. Whether sending more would *cause* more purchases is a different question — and we'd need an experiment."

---

## Part 2: Global importance — what matters overall

### The right way: permutation importance

Scramble one column at random and see how much worse the model gets. Big drop, important feature. No drop, irrelevant.

Simple, intuitive, works with any model. **Compute it on held-out data**, not training data — otherwise you're measuring what the model memorized.

### The trap: the default importance score is misleading

Every tree library has a built-in `feature_importances_`. **It's biased.** It systematically inflates features with many distinct values — a customer ID or a timestamp can rank near the top just for having lots of unique values.

It's also the default, which means it's what most people use.

**Use permutation importance or SHAP instead.** This is the single most common technical mistake in this area.

### The other trap: correlated features hide each other

Suppose you have two nearly identical features — "days since last login" and "days since last purchase," which move together.

Scramble the first: the model barely suffers, because the second still carries the information. Scramble the second: same.

**Both look unimportant. Together they're your strongest signal.**

If you see two features you expect to matter both scoring near zero, check whether they're correlated. The fix is to scramble them *together* as a group, or to check correlations before you interpret any importance ranking.

There's a related problem worth knowing about. Scrambling a column creates combinations that never happen in reality — a customer with 400 days since login and 2 days since purchase. The model has never seen anything like that, so its behavior there is essentially arbitrary, and your importance score partly reflects that arbitrary behavior. It's another reason to check for correlation first.

---

## Part 3: The shape of an effect

Importance tells you *whether* a feature matters. Usually you want to know *how* — does risk rise steadily with tenure, or drop off a cliff at 90 days?

### Partial dependence plots, and their companion

A partial dependence plot sweeps one feature across its range and shows the average predicted outcome. Widely used.

**Always plot the individual lines alongside the average.** (These are called ICE plots; one line per customer instead of one average line.)

Here's why it matters: suppose a price increase makes half your customers more likely to churn and the other half less. The average is a **flat line**, and the partial dependence plot says "price doesn't matter." The individual lines immediately reveal two opposing groups — which is a much more interesting finding than either "matters" or "doesn't."

Averages hide exactly the kind of structure you most want to find.

### A better default: ALE plots

Partial dependence plots have the same correlated-features problem as permutation importance — they average over combinations that don't exist.

**ALE plots** (accumulated local effects) avoid this by only looking at small changes within regions where you actually have data. Slightly harder to explain, considerably more trustworthy. If your features are correlated — and they usually are — prefer these.

---

## Part 4: SHAP — explaining one prediction

The current standard for "why did the model say *this* about *this* case."

For a single prediction, SHAP splits it into contributions:

```
Baseline (average customer):        12% churn risk
+ 34 days since last login:         +18%
+ 2 support tickets this month:      +9%
+ tenure of 3 years:                 -6%
+ premium plan:                      -4%
─────────────────────────────────────────
This customer:                       29% churn risk
```

The contributions add up exactly to the prediction. That's a mathematical guarantee, and it's the main reason SHAP became the default — it's the only method with that property plus a few other sensible ones.

### Four things to know

**It explains the model, not reality.** Repeating this because it's where the damage happens. The chart above says the model *uses* login recency. It does not say that getting this customer to log in would reduce their risk.

**Everything is relative to a baseline.** "18% higher" than *what*? Usually the average customer, but you can choose a different reference, and the story changes. State which one you used.

**Correlated features split credit somewhat arbitrarily.** If two features carry the same information, the split between them isn't meaningful. Don't build a narrative on the exact ratio.

**There are two versions, and they can disagree.** Depending on the library and settings, SHAP answers either "what does this model actually use?" or "what does this feature tell us about the outcome?" These give different rankings when features are correlated. Neither is wrong; they're different questions. If your SHAP numbers change after a library upgrade, this is usually why.

**For presenting:** a single-prediction waterfall chart (like the one above) plus a simple bar chart of average importance works far better with stakeholders than the dense colorful beeswarm plots. Save those for your own analysis.

---

## Part 5: Counterfactuals — usually what people actually want

Instead of "here's how much each factor contributed," say:

> "This application would have been approved with £4,000 more annual income, or with one fewer missed payment."

**This is usually more useful than attribution**, especially for anyone on the receiving end of a decision. It's concrete, actionable, and it's the format regulators generally expect.

Two rules when generating them:

- **Only suggest things that can change.** "You'd be approved if you were ten years younger" is not a recommendation.
- **Only suggest realistic combinations.** The counterfactual should describe a person who could actually exist.

---

## Part 6: Or build a model you don't have to explain

There's a strong argument that for high-stakes decisions, you should use a model that's understandable by design rather than a black box plus a reconstruction of what it probably did.

Options that cost less accuracy than you'd expect:

**Monotonic constraints.** Force the model to always move one way with a feature — more income never lowers a credit score. Supported directly in XGBoost and LightGBM (Module 8). Usually costs almost nothing in accuracy, and it eliminates a whole class of embarrassing individual predictions.

**Explainable Boosting Machines (EBMs).** Learn a separate curve for each feature and add them up. You get an actual plottable graph per feature showing exactly what the model does — no approximation. Often competitive with full gradient boosting on tabular data. Genuinely underused.

**Simple models.** A regularized linear model or a shallow tree. Always benchmark these first (Module 8) — you may find the interpretability is free.

The underlying argument: an explanation of a black box is an *approximation* of what the model does, and you can't fully verify how good the approximation is. A model that's transparent by construction has no gap.

---

## Part 7: Explanations are a great leakage detector

Underrated benefit. **Show your explanations to someone who knows the business.**

If the model leans on something a domain expert finds implausible, you've almost certainly found a bug — usually leakage (Module 4). Fields that shouldn't matter but do are how leakage announces itself.

This is one of the highest-value uses of these tools, and it happens in a thirty-minute conversation.

---

## Part 8: Warning signs

| What you see | What's probably happening |
|---|---|
| An ID or timestamp ranks as important | Leakage — or you used the biased default importance |
| Two features you know matter both score zero | They're correlated and hiding each other |
| An effect plot is flat but the feature clearly matters | Opposing groups cancelling — plot individual lines |
| Explanations change a lot between retrains | Correlated features; consider constraints or a simpler model |
| SHAP and permutation importance disagree | They answer different questions; both can be right |
| SHAP numbers changed after a library update | Probably a switch between the two versions |
| Stakeholder acted on an explanation, nothing improved | It was read as causal |
| An expert says a top feature makes no sense | Investigate — usually leakage, occasionally a real discovery |

---

## Putting it all together

**The recipe:**

1. **Say which question you're answering** — what the model does, why this case, or what happens if we act. If it's the third, you need Module 2.
2. **Try an interpretable model first.** EBM, monotone boosting, regularized linear. Check what the accuracy actually costs.
3. **Check your feature correlations** before interpreting anything. They determine which methods you can trust.
4. **Overall importance:** permutation importance on held-out data. Never the built-in scores.
5. **Effect shapes:** ALE plots, or partial dependence *with individual lines shown*.
6. **Individual explanations:** SHAP, stating your baseline.
7. **Check stability** — refit on resampled data and see if the explanation holds. If it swings around, the model hasn't really pinned that down.
8. **Give end users counterfactuals**, not attributions.
9. **Show the explanations to a domain expert.** Best leakage detector you have.
10. **Write down how you generated them** for your model documentation (Module 15).

**Three things to remember if you remember nothing else:**

- **These tools explain the model, not the world.** A feature can dominate every explanation and be entirely non-causal. Say this before someone acts on it.
- **The built-in importance score is biased toward high-cardinality features.** Use permutation importance or SHAP.
- **Correlated features break most of these methods** in specific ways — hiding each other in importance rankings, splitting SHAP credit arbitrarily. Always check correlation first.

---

## Where to go next

- **The reference:** *Interpretable Machine Learning* by Christoph Molnar — free online, comprehensive, readable. The best single resource on this topic.
- **Practical:** the `shap` library's documentation has good examples of every plot type and when to use each.
- **Worth reading, even to disagree:** Cynthia Rudin's "Stop Explaining Black Box Machine Learning Models for High Stakes Decisions" — the argument for interpretable-by-design models.
- **Try it:** `interpret` (Microsoft's InterpretML) makes EBMs a one-liner. Worth benchmarking against your current model.
