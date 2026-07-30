# Trees, Forests, and Boosting: A Plain-Language Guide

*Module 8 — plain-language register.*

---

## The short version

A decision tree is a flowchart of yes/no questions that a computer builds automatically. It's easy to understand and surprisingly weak on its own — mostly because it's *unstable*. Change a few rows of data and you get a completely different tree.

Two ways to fix that, and they're genuinely different strategies:

- **Random forests** build hundreds of trees on slightly different slices of the data and average them. Averaging cancels out individual mistakes — but only the mistakes that *differ* between trees. Errors they all share don't cancel at all.
- **Gradient boosting** builds trees one at a time, where each new tree focuses on what the current model is still getting wrong. Small correction, then another, then another.

Boosting usually wins on business data, which is why gradient-boosted trees remain the default for tabular problems and why deep learning hasn't taken over here despite dominating images and text.

---

## Part 1: What a single tree does

A tree asks a sequence of yes/no questions:

```
Is tenure > 90 days?
├─ No  → Has support ticket?
│        ├─ Yes → 45% churn risk
│        └─ No  → 22% churn risk
└─ Yes → Monthly spend > $200?
         ├─ Yes →  4% churn risk
         └─ No  → 11% churn risk
```

The computer picks each question by trying every possible split and choosing the one that best separates the outcomes, then repeats within each branch.

### What's good about it

**You don't need to scale anything.** This is the one model family where Module 5's scaling requirement genuinely doesn't apply. "Is spending over $200?" gives the same answer whether you measure in dollars or cents.

**It handles missing values, mixed data types, and categories naturally.**

**It finds combinations by itself.** Every path down the tree is automatically an "if this AND this AND this" rule. Linear models need you to specify those combinations manually.

### What's bad about it

**It can't predict outside what it's seen.** A tree's prediction is always the average of some group of training examples. If your training prices ranged from $10 to $100, the tree will never predict $150, no matter how extreme the inputs get.

This matters enormously for anything with a trend. A tree trained on three years of growing sales **cannot forecast growth** — it will predict a flat line at the historical average. If you're forecasting (Module 10), you have to handle the trend separately and let the tree work on what's left over.

**It's unstable.** Drop 10% of your rows at random and rebuild, and you can get a completely different-looking tree. This is why "the tree is interpretable" is less useful than it sounds — you can read it, but you can't trust that it would look the same tomorrow.

---

## Part 2: Random forests — averaging away the noise

Build 500 trees, each on a random sample of your data, and average the predictions.

This works for the same reason repeating a measurement works: individual errors are random, and averaging cancels them out.

### The catch that explains everything

**Averaging only cancels the errors that differ between trees.** Errors they all make together — technically, *correlated* errors — don't cancel at all, no matter how many trees you add.

This is worth sitting with, because it's the reason random forests are built the way they are. If every tree makes the same mistake, having 5,000 of them is no better than having 5. It's like repeating a measurement with an instrument that reads 2% low: more repetitions won't fix a shared error.

So the trick isn't just building lots of trees. **It's building lots of trees that make *different* mistakes.**

### How forests force trees to differ

Random forests do something that sounds counterproductive: at each question, the tree is only allowed to consider a **random subset of the available features.**

Why deliberately handicap each tree? Because otherwise the strongest feature gets picked first in nearly every tree, and they all end up similar — all making the same mistakes. Restricting the choices forces trees to explore different structures.

**Each individual tree gets worse. The forest gets better.** That trade is the central idea.

### A free validation score ("out-of-bag" error)

Because each tree only sees about two-thirds of the data, every row has a set of trees that never saw it. Scoring each row with just those trees gives you a validation estimate at no extra cost. Libraries call this the **out-of-bag** (OOB) score, and it's usually one setting away.

Handy — but it doesn't respect grouped or time-ordered data. If Module 6 told you that you need grouped or temporal splits, this shortcut won't give them to you.

---

## Part 3: Boosting — fixing mistakes in sequence

Different strategy entirely:

1. Build a small, weak tree. It's mediocre.
2. Look at what it got wrong.
3. Build a second small tree that focuses on those errors.
4. Add a *fraction* of that second tree's correction to the model.
5. Repeat, hundreds or thousands of times.

The model is the accumulation of many small corrections. Each one handles a bit of what's left over.

The intuition: you're sculpting. Rough shape first, then progressively finer corrections. Each pass removes less material than the last.

### The two dials that matter most

**Learning rate** — how much of each correction to apply. Small values (0.05) mean each tree nudges the model gently.

**Number of trees** — how many corrections to make.

These trade against each other: halve the learning rate and you need about twice as many trees. Small learning rate with many trees generally works better — many gentle corrections beat a few aggressive ones — at the cost of taking longer.

**The practical approach:** set the learning rate small, then let *early stopping* decide the number of trees. Early stopping just means: keep adding trees while validation performance improves, stop when it doesn't. This turns "how many trees" from a thing you tune into a thing that handles itself.

### Boosting can overfit; forests basically can't

Important difference. Adding trees to a forest never hurts — extra trees just stop helping. Adding trees to a boosted model **eventually makes it worse**, because it starts correcting for noise rather than signal.

**Always use early stopping with boosting.** It's not optional.

### Which to use

| | **Random forest** | **Boosting** |
|---|---|---|
| Trees are built | All at once, independently | One at a time, each fixing the last |
| Extra trees | Never hurt | Can hurt — needs early stopping |
| Tuning needed | Little; good out of the box | More; the dials interact |
| Typical accuracy | Good | Usually better |
| If your labels are noisy | **More reliable** | Worse — it chases the mislabeled rows |
| Speed to a decent result | Faster | Slower |

That noisy-labels row is practical, not theoretical. Boosting works by focusing on what it's still getting wrong — and a mislabeled row is permanently wrong, so boosting keeps trying to fit it. If your labels come from a messy manual process, a random forest is often the safer bet.

---

## Part 4: What to actually use

Three good libraries, all fine:

- **XGBoost** — the established standard, extremely well documented.
- **LightGBM** — fastest on big data, handles categories natively. A good default.
- **CatBoost** — best when you have lots of categorical fields; strong out of the box.

### The settings worth tuning

In roughly this order:

1. **Learning rate** — set it to 0.05 and leave it alone.
2. **Number of trees** — early stopping handles it.
3. **Tree depth** — the main control on complexity. Deeper trees find more elaborate combinations and overfit more easily. 3–8 is typical.
4. **Minimum samples per leaf** — the best protection against fitting tiny random pockets of data. Underrated.
5. **Row and column sampling** — use ~80% of each per tree. Adds useful diversity.

Use **random search** rather than trying every combination (Module 5, Part 6). Only two or three of these matter for any given dataset, and a grid wastes most of its effort on the rest.

### Two capabilities worth knowing about

**Monotonic constraints.** You can force the model to always move one direction with a feature — higher income can never lower a credit score. When domain knowledge supports it, this costs almost no accuracy and gives you a model that's defensible to a regulator and won't produce embarrassing individual predictions.

**Custom error costs.** If missing a fraud case is ten times worse than a false alarm, you can build that directly into how the model learns, rather than only fixing it at the threshold.

---

## Part 5: Why deep learning hasn't taken over here

Neural networks dominate images, audio, and text. On spreadsheet-style data they usually **tie or lose** to boosted trees, while requiring far more tuning.

The reasons hold up well:

- **Business relationships are often threshold-like** — something changes at 90 days, or above $200. Trees represent that exactly; smooth networks approximate it awkwardly.
- **Trees ignore useless features gracefully.** Networks get distracted by them.
- **Columns in a table have no natural order or geometry.** The structural assumptions that make networks powerful on images (nearby pixels relate) simply don't apply to columns.

Neural approaches do earn their place when you have text or images alongside your table, or extremely high-cardinality categories.

**Default to boosted trees on tabular data.** If someone wants to use a neural network, ask for the benchmark.

---

## Part 6: What you give up

- **No extrapolation.** Worth repeating because it surprises people every time.
- **Not readable.** A thousand trees is not a flowchart anyone can follow. You need Module 13's tools.
- **The built-in importance scores are misleading.** Every library has a `feature_importances_` attribute, and it's **biased toward features with many distinct values** — a customer ID will look important. Use permutation importance or SHAP instead. This one trips up a lot of people because the biased version is the default.
- **The probabilities are usually overconfident.** If you need real probabilities rather than a ranking, calibrate them (Module 7, Part 4).

---

## Part 7: Warning signs

| What you see | What's probably happening |
|---|---|
| Forest fine, boosting much worse | Noisy labels, or you forgot early stopping |
| Training keeps improving, validation gets worse | No early stopping; learning rate too high |
| Model won't predict above its historical range | Trees can't extrapolate — model the trend separately |
| A customer ID shows up as an important feature | The built-in importance measure is biased; switch methods |
| Great ranking, but the probabilities are off | Boosted trees need calibration |
| Free validation score much better than proper CV | Grouped or time-ordered data that the shortcut ignores |
| Huge improvement over your linear baseline | Check for leakage first — trees find leaks very efficiently |

---

## Putting it all together

**The recipe:**

1. **Start with a regularized linear model** as your baseline (Module 5). If trees don't clearly beat it, keep the simpler one.
2. **Use LightGBM or XGBoost with defaults**, learning rate 0.05, early stopping switched on.
3. **Don't bother scaling.** It does nothing here.
4. **Let the library handle categories** rather than one-hot encoding everything.
5. **Random search** over depth, minimum leaf size, and sampling rates. About 50 tries gets most of the benefit.
6. **Keep your validation honest** — grouped or time-based splits per Module 6.
7. **Add monotonic constraints** where the business logic supports them.
8. **Calibrate** if you need real probabilities.
9. **Explain with SHAP or permutation importance** — never the built-in scores.
10. **Check how big and slow the model is** before promising real-time predictions.

**Three things to remember if you remember nothing else:**

- **Trees can't predict outside their training range.** Anything with a trend needs the trend handled separately, or your forecast will be a flat line.
- **Averaging only cancels errors that differ.** That's why forests deliberately weaken individual trees — to make them disagree.
- **Always use early stopping with boosting.** Unlike a forest, more trees eventually makes it worse.

---

## Where to go next

- **Practical:** the LightGBM "Parameters Tuning" documentation — short, concrete, and honest about which settings matter.
- **Conceptual:** *An Introduction to Statistical Learning*, chapter 8 — trees, bagging, and boosting at a comfortable level. Free online.
- **On the tabular question:** Grinsztajn et al. (2022), "Why do tree-based models still outperform deep learning on tabular data?" — careful benchmarks and a convincing explanation.
