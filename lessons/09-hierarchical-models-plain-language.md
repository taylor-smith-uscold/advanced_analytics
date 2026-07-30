# Small Groups, Thin Data: A Plain-Language Guide to Partial Pooling

*Module 9 — plain-language register.*

---

## The short version

You need a number for each store, each sales rep, each product, each region. Some have thousands of observations. Some have four.

Report each one's own raw number and your leaderboard fills up with noise — the top and bottom will both be dominated by tiny samples, mechanically, every time. Report the company average for everyone and you've erased the real differences you were asked to find.

**Partial pooling** does the sensible thing in between: each group's estimate is a blend of its own data and the overall average, with the blend determined by how much data that group has. Groups with lots of data mostly speak for themselves. Groups with almost none get pulled toward the average.

It's the same shrinkage idea from Module 5, with one big improvement: **the amount of pulling is calculated from your data rather than tuned.** The groups themselves tell you how different groups really are, and that sets how much each one should borrow from the others.

---

## Part 1: The problem, in a table

Conversion rates by sales rep:

| Rep | Attempts | Conversions | Raw rate |
|---|---|---|---|
| Alice | 4 | 3 | **75%** |
| Ben | 1,200 | 372 | 31% |
| Carla | 6 | 0 | **0%** |
| Dan | 890 | 249 | 28% |

Publish this and Alice is your top performer and Carla is on a performance plan. Both numbers are meaningless — four attempts and six attempts tell you almost nothing.

And this isn't a fluke of these particular numbers. **Small groups will always be over-represented at both ends of any ranking**, because small samples produce extreme results in both directions. Any leaderboard built on raw rates is partly a ranking of who has the least data.

### The two obvious answers are both wrong

**"Just use the company average for everyone"** — throws away all the real differences, which is presumably why you were asked.

**"Just use each rep's own number"** — that's the table above.

**"Only include reps with 30+ attempts"** — this is the common fix, and it's a rough approximation of the right answer. But it treats evidence as all-or-nothing when it's really a continuum: 29 attempts tells you something, 31 attempts doesn't tell you a lot. And you had to invent the number 30 from nowhere.

---

## Part 2: The idea

Blend each rep's own number with the overall average, weighted by how much you can trust each one.

Alice has 4 attempts. Almost no information. So her estimate should sit close to the company average, nudged slightly upward because those four went well.

Ben has 1,200 attempts. Plenty of information. His estimate should be essentially his own number.

Applied to the table above (with a company average around 30%):

| Rep | Attempts | Raw rate | Adjusted estimate |
|---|---|---|---|
| Alice | 4 | 75% | 34% |
| Ben | 1,200 | 31% | 31% |
| Carla | 6 | 0% | 27% |
| Dan | 890 | 28% | 28% |

Ben and Dan barely move. Alice and Carla move most of the way to the average — but not all the way, and they end up on the correct sides of it, which is all their data actually supports.

**Every group gets its own amount of adjustment**, determined by its own sample size. That's the continuous version of the "30+ attempts" cutoff.

### What controls the blend

Three things:

**How much data the group has.** More data, less adjustment. This is the main one.

**How different the groups genuinely are.** If your reps really do vary a lot in skill, the company average isn't very informative about any individual, so less adjustment. If everyone performs about the same, the average is highly informative, so more.

**Here's the good part: the second one is calculated from your data.** You don't set it. You don't tune it. The spread among the well-measured groups reveals how much genuine variation exists, and that automatically determines how much the poorly-measured groups should borrow.

This is the improvement over Module 5's regularization, where you had to cross-validate to find the penalty strength. Here the grouping structure identifies it for you.

**How noisy individual observations are.** Noisier measurements mean more adjustment.

---

## Part 3: Why this isn't a hedge

It's tempting to see this as playing it safe — softening extreme numbers to avoid embarrassment.

It isn't. There's a well-known mathematical result (Stein's paradox, from the 1950s) showing that when you're estimating three or more groups, **adjusting every estimate toward the overall average produces less total error than using each group's own number.** Not sometimes. Always, under standard assumptions.

This surprised statisticians when it was proved, and it still surprises people. The classic demonstration used baseball batting averages: early-season averages adjusted toward the league mean predicted end-of-season performance better than the raw early-season averages did — including for the players whose numbers got adjusted the most.

**You're not being cautious. You're being more accurate.**

---

## Part 4: How to actually do it

**Simplest approach:** the "add pseudo-observations" trick. Add a fixed number of imaginary observations at the overall average to every group before computing rates. If you add the equivalent of 20 attempts at the 30% average:

- Alice: (3 + 6) / (4 + 20) = 37%
- Ben: (372 + 6) / (1200 + 20) = 31%

Crude but surprisingly effective, and it's exactly what the proper method does — the maths just picks the right number of pseudo-observations for you rather than you guessing 20.

**Proper approach:** fit a *mixed-effects model* (also called multilevel or hierarchical). In R that's `lmer` from the `lme4` package; in Python, `statsmodels`' `MixedLM`. In R the formula looks like:

```
conversions ~ 1 + (1 | rep)
```

which reads as "an overall rate, plus a rep-specific adjustment that's partially pooled."

**When you need real uncertainty intervals** or have nested groups (rep within region within country), use a proper Bayesian tool — `brms` in R, PyMC or Stan in Python. Slower, and worth it for high-stakes recurring reports.

### Two practical notes

**Rates need the right model.** If you're working with percentages, use a method built for them rather than blindly applying an average-based formula — otherwise you can get adjusted rates below 0% or above 100%, which happens precisely for the small groups you were trying to fix.

**Use what you know about the groups.** If small rural stores genuinely differ from large urban ones, include store size and location in the model. Then a small rural store gets pulled toward *other small rural stores* rather than toward the company-wide average. Much better, and usually easy.

---

## Part 5: Effects that differ by group

The natural extension: instead of just "how does this store perform," ask "how much does this store respond to the promotion?"

You could estimate 400 separate promotion effects (mostly noise) or one company-wide effect (hiding real differences). Partial pooling gives you 400 stabilized estimates, each borrowing from the others by the right amount.

**This is directly useful for the subgroup problem from Module 3.** Module 3 warns you not to trust "it didn't work overall but worked great for mobile users in Germany" — because independently estimated subgroup effects are noisy, and you noticed that one *because* it was extreme.

Partial pooling attacks the root cause rather than patching the symptom. It shrinks extreme subgroup results toward the overall effect in proportion to how unreliable they are, so the spurious extremes largely disappear on their own. Instead of correcting p-values for many comparisons, you've made the estimates themselves better behaved.

---

## Part 6: Where you'll use this

| Situation | Why it helps |
|---|---|
| Rep, store, or region performance | Rankings stop being dominated by whoever has the least data |
| A/B test results by segment | Subgroup effects that are actually trustworthy |
| Product ratings | A 5.0 from two reviews shouldn't outrank a 4.7 from four hundred |
| Forecasts for many products | Slow-moving items borrow from their category |
| Any per-entity threshold or baseline | Sparse entities get sensible defaults automatically |

---

## Part 7: Explaining it to stakeholders

Expect this objection, and prepare for it: **"You changed Alice's number. Her rate is 75%."**

It's a fair-sounding challenge and it needs a good answer, not a technical one.

What works:

> "Alice converted 3 of 4. That's 75% *observed*. But with only four attempts, that number would swing wildly with one more result — one miss and she's at 60%. Our best estimate of what she'd do over a hundred attempts is 34%. That's still above average, and it will move toward whatever her real rate is as she does more. If she genuinely converts at 75%, that's exactly where the estimate will land."

Two things that land well:

**Show the adjustment shrinking with more data.** A chart of raw rate versus adjusted rate, sized by sample size, makes the mechanism obvious in a way words don't. Big dots barely move; small dots move a lot.

**Show the uncertainty ranges.** Alice's range is enormous, Ben's is narrow. Once people see that, the adjustment feels like an honest reflection of what you know rather than a manipulation.

---

## Part 8: Warning signs

| What you see | What's probably happening |
|---|---|
| Small groups still at the extremes | The pooling isn't actually applied, or is too weak |
| Everything collapsed to the average | Either groups genuinely are alike, or you have too few groups |
| Adjusted rates below 0% or above 100% | Using an averages-based method on percentages |
| Big groups getting adjusted a lot | Something's wrong — they should barely move |
| Group differences clearly track group size | Add size as a variable; pool toward similar groups |
| Stakeholders feel the numbers were manipulated | A communication problem — see Part 7 |

---

## Putting it all together

**The recipe:**

1. **Count observations per group.** Wide imbalance is the signal to use this.
2. **Compute all three versions** — everyone gets the average, everyone gets their own number, and the blend — and plot them together against group size. That chart is the best explanation you'll ever produce for this method.
3. **Use the right model for your outcome type** — especially for rates and percentages.
4. **Include what you know about the groups** so small groups borrow from similar ones.
5. **Report the ranges, not just the estimates.** Small groups should visibly have wide ones.
6. **Validate by holding out whole groups**, not random rows (Module 6).
7. **Prepare the explanation** before you publish an adjusted leaderboard.

**Three things to remember if you remember nothing else:**

- **Any raw leaderboard is partly a ranking of who has the least data.** Small samples land at both extremes automatically.
- **This isn't hedging — it's more accurate.** There's a theorem. Adjusted estimates beat raw ones on total error.
- **The amount of adjustment comes from your data, not your judgment.** How much real variation exists between groups determines how much any individual group should borrow.

---

## Where to go next

- **Best intuition:** *Statistical Rethinking* by Richard McElreath, chapter 13 — and the free lecture videos, which are excellent. This is the one that makes it click.
- **Best applied reference:** *Data Analysis Using Regression and Multilevel/Hierarchical Models* by Gelman & Hill.
- **Short and delightful:** Efron & Morris's 1977 *Scientific American* article on Stein's paradox, using baseball. A few pages, no math, and it's the clearest explanation of why this works.
