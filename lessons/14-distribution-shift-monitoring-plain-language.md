# Is It Still Working? A Plain-Language Guide to Monitoring Models

*Module 14 — plain-language register.*

---

## The short version

Models are trained on the past and deployed into the future. The world moves, and the model doesn't. Every deployed model is slowly going stale, and the only question is whether you'll notice before your users do.

Three kinds of change, needing three different responses:

1. **Your customers changed, but the underlying relationships didn't.** Often harmless.
2. **The mix of outcomes changed** — more fraud this month than last. Fixable by adjusting the model's output.
3. **The relationships themselves changed.** Fraudsters found a new technique; the old signals mean something different now. **Only retraining helps.**

And one problem that has no equivalent in testing: **your model's decisions determine what data you get next.** A model that blocks transactions never finds out whether they were fraudulent. A forecast that sets inventory limits how much you can sell. These loops corrupt every future retrain in the same direction, and — this is the dangerous part — **all your metrics look fine while it happens.**

---

## Part 1: Three ways the world moves

### Your customers changed

A marketing push brings in a younger audience. Your inputs now look different.

**This often doesn't hurt anything.** If the relationship between behavior and churn is the same for younger customers, the model still works. It only breaks if the new customers are unlike anything in training — the model then has to guess in unfamiliar territory.

So treat a "your data changed" alert as a prompt to investigate, not as an emergency.

### The mix of outcomes changed

Fraud rates rise every December. The signals still mean what they meant — there's just more of it.

Usually fixable by adjusting the model's output rather than rebuilding. The model still ranks correctly; its probability estimates are just calibrated to the wrong base rate.

### The relationships changed

Fraudsters shifted tactics. The pattern that meant "safe" last year now means "sophisticated attack."

**This is the serious one, and only retraining fixes it.** Adjusting outputs won't help — the model has learned something that's no longer true.

Worth knowing: **your inputs can look completely normal while this happens.** All your drift alerts stay green and the model is quietly wrong. That's why input monitoring alone isn't enough.

---

## Part 2: What to watch, and when you can see it

The practical constraint is that different signals arrive at different times.

| What you watch | Available |
|---|---|
| **Inputs** — feature distributions, missing rates, volume | **Right away** |
| **Outputs** — the distribution of predictions, how often the model says yes | **Right away** |
| **Outcomes** — was it actually right? | **Weeks or months later** |
| **System** — errors, latency, uptime | Right away |

Since you can't measure accuracy until outcomes arrive, inputs and outputs are your early warning.

**Output monitoring is usually the more useful of the two.** The distribution of predictions summarizes everything the model is doing across all features at once. If the fraction of customers flagged as high-risk jumps from 4% to 11% overnight, something happened — and that's a more actionable signal than a statistical test on one column.

### One warning about alerts

With enough data, **every feature will drift "significantly" every day.** Statistical significance is useless here.

Set your alerts on *how big* the change is, not on whether it's statistically detectable. Otherwise you'll get twenty alerts a day, everyone will ignore them, and your monitoring will be worse than none — because it creates the impression of coverage.

### A genuinely useful diagnostic

Train a quick model to distinguish "data from last month" versus "data from this month."

If it can't tell them apart, nothing meaningful changed. If it can, look at which features it used — those are exactly where your data moved. One model, and it both detects the change and localizes it.

---

## Part 3: When you can't see outcomes yet

If you find out whether a loan defaults after 18 months, you can't wait 18 months to notice a problem.

Useful stand-ins:

- **How often does the model say yes?** A sudden change means something.
- **Accuracy on the outcomes you *do* have.** Just remember they're not a random sample — quickly-resolved cases differ systematically from slow ones.
- **Does it still agree with the old model, or with a simple rule?**
- **How often do humans override it?**

**That last one is underrated.** If your review team is overturning the model more than they used to, they've noticed something before your dashboard did. Track the override rate and treat a rise as a real signal.

---

## Part 4: The feedback loop problem

This is the most important section, and it's the failure mode that testing can never reveal.

### You never learn about the ones you rejected

A credit model rejects an application. You never find out whether that person would have repaid.

Retrain next year on what you observed, and you're training only on **applications your current model approved**. The new model inherits the old one's blind spots and narrows further. Each generation gets more confident about a shrinking slice of the world.

**Your metrics look great throughout.** You're measuring accuracy on the cases the model already liked.

**The fix that works:** approve a small random fraction regardless of score. Yes, that means knowingly approving some applications the model dislikes. It costs money. It's also the only way to find out whether the model is right about them, and it's what keeps the system from slowly closing in on itself. Treat it as a data acquisition budget.

### The self-fulfilling forecast

Forecast low demand for a product → order less → sell less (you ran out) → next year's model sees lower sales → forecasts even lower.

The loop is stable, points downward, and **every metric looks fine at every step**, because you're comparing forecasts to the sales you allowed yourself to make.

Same shape with recommendations: an item never shown gets no clicks, which confirms it shouldn't be shown.

**Partial fix:** record what was *available*, not just what was chosen or sold. If you log that you had 3 units left and sold all 3, you know demand was *at least* 3 — which is different from knowing demand was 3.

### The model changes the thing it predicts

Your churn model flags at-risk customers. The retention team calls them. They don't churn.

Now the model looks *wrong* — it predicted churn that didn't happen. It's being penalized for working.

Any honest evaluation needs a group who get flagged but receive no intervention, so you can see what would have happened. That's an experiment (Module 3), and it's the only way to measure whether the whole system is doing anything.

---

## Part 5: When it was broken from the start

Not everything is drift. Sometimes the model never worked in production, because production data was different from day one.

Common causes:

- **The feature is computed differently** in training and in production — different code, different logic, subtle mismatch.
- **The feature is computed at a different time.** A "customer's 30-day spend" calculated in a nightly batch isn't the same as one calculated at the moment of the request.
- **Your training data got corrected after the fact.** This one is nasty: warehouse tables often get retroactively updated. Your training data contains values that **did not exist** when the prediction would have been made. The model learns from information it will never have in production, and offline validation shows nothing wrong at all.

**The definitive test:** log the exact set of inputs the model used in production, then re-run them offline. Any difference between what you logged and what your training pipeline produces is the problem.

Do this once when you launch. It takes an afternoon and catches a class of bug that can otherwise persist for months.

---

## Part 6: Retraining and deploying safely

### When to retrain

**On a schedule** (monthly) — simple, predictable, fine for stable domains.
**When something triggers it** — drift or performance decline. More responsive, needs reliable detection.
**Continuously** — for fast-moving domains, with the highest operational risk.

**Retraining isn't automatically safe.** If your data has been corrupted, retraining bakes it in. If you have a feedback loop, retraining accelerates it. **Every retrained model needs the same validation as the original**, plus a head-to-head comparison against the model it replaces.

### How much history to use

More data is better, but old data may describe a world that no longer exists.

Rule of thumb: if things change gradually, use a rolling recent window. If your data has annual seasonality, **keep at least a full year** — otherwise you'll train a model that has never seen December.

### Roll out carefully

1. **Shadow mode** — the new model makes predictions but nothing acts on them. Compare against the current one.
2. **Canary** — send 5% of traffic. Watch closely.
3. **A/B test** — the only way to know whether the new model actually improves business outcomes rather than offline metrics (Module 3).
4. **Keep the old version ready to redeploy** in minutes.

Version everything — the model, the data it trained on, the code. When something goes wrong at 3am, you need to be able to reproduce exactly what happened.

---

## Part 7: Warning signs

| What you see | What's probably happening |
|---|---|
| Model metrics fine, business metrics falling | A feedback loop, or you're measuring the wrong thing |
| Bad from day one | Training-serving mismatch, not drift |
| Drift alerts firing constantly | Thresholds set on statistical significance rather than size |
| Nothing drifted, performance collapsed | The relationships changed — retrain |
| Data drifted, performance is fine | Often harmless; investigate, don't panic |
| Accuracy climbing over time | Suspicious — you may be measuring only cases the model already liked |
| Retrained model is worse | Bad recent data, or a feedback loop |
| Human override rate rising | Your reviewers noticed something first |
| A feature is suddenly all blank | Upstream pipeline broke — this is why you monitor missing rates |

---

## Putting it all together

**The recipe:**

1. **Log everything** the model saw and said, with the version number. Nothing else works without this.
2. **Save a snapshot of your training data distribution** as the reference to compare against.
3. **Monitor four things** — inputs, outputs, outcomes, and system health — knowing they arrive at different times.
4. **Set alert thresholds on size, not significance**, tuned so people actually read them.
5. **Track proxy signals** while waiting for outcomes, especially the human override rate.
6. **Write down every feedback loop** in your system. Where your model's decision means you never learn the answer, build in a randomized holdout.
7. **Verify training-serving consistency** at launch by re-scoring logged production inputs.
8. **Decide the retraining policy up front** — when, how much history, what has to pass, when to roll back.
9. **Roll out through shadow, canary, then A/B.** Never straight to production.
10. **Recheck performance by subgroup** on every retrain (Module 15). Drift is rarely uniform, and an overall number can hide a collapse in one population.

**Three things to remember if you remember nothing else:**

- **Your model's decisions shape the data you get next.** If you never learn what happened to the cases you rejected, you need a randomized holdout — and it's worth the cost.
- **"Nothing drifted" doesn't mean "still working."** The relationships can change while the inputs look identical.
- **Alerts nobody reads are worse than no alerts**, because they create false comfort. Tune for a handful a month, not a handful a day.

---

## Where to go next

- **Short and essential:** "Hidden Technical Debt in Machine Learning Systems" (Sculley et al., Google) — nine pages on why ML systems decay. The feedback-loop discussion is the origin of Part 4.
- **Practical:** Evidently AI's open-source documentation is a good, concrete tour of drift metrics and how to set them up.
- **On what actually goes wrong:** "Challenges in Deploying Machine Learning: a Survey of Case Studies" — real failures from real deployments.
