# Designing Tests That Can Be Trusted: Experimentation and A/B Testing

*Module 3 — technical register. For readers who have thought about counting statistics, systematic checks, and blind analysis.*

> **Required reading —** Kohavi et al., experimentation paper archive — CUPED, SRM, and the rules of thumb · [exp-platform.com](https://exp-platform.com/)

---

## 0. The one-paragraph version

Randomization is the only identification strategy that requires no untestable assumption about confounding, which is why an experiment beats a large observational study almost every time. But randomization only protects the *assignment*; everything downstream can still be wrecked. The recurring failure is the one from Module 6 in a new costume: **any quantity you optimize against stops being a valid measurement.** Peeking at results and stopping when significant is optimizing against your p-value. Testing twenty metrics and reporting the one that moved is optimizing against your metric set. Slicing by segment until something appears is optimizing against your segmentation. Each inflates false positives by an amount that is large, calculable, and routinely ignored. The discipline that fixes all three is the same: decide what you will measure and when you will stop, before you start.

---

## 1. Why randomize

From Module 2: the naive comparison between treated and untreated groups equals the true effect plus a selection term, and the selection term has no reason to be small. Random assignment makes it exactly zero in expectation, because treatment is now independent of every potential outcome — balanced on observed covariates *and* on the ones you never measured.

This is the entire value proposition, and it's worth being precise about what it does and doesn't buy:

**What randomization guarantees:** the two groups are draws from the same population. Any difference in outcomes is either your treatment or chance, and chance is quantifiable.

**What it does not guarantee:** that you measured the right thing, that your units are independent, that the effect generalizes beyond your test population, that your assignment mechanism worked, or that your analysis is honest. Sections 4–8 are about these.

---

## 2. Design decisions, made before launch

### The randomization unit

Assign at the level where interference is minimized and where the outcome is measured. Common choices: user, session, device, account, cluster, geography, time window.

**The unit of randomization must match the unit of analysis.** If you randomize by user but analyze by session, your observations are not independent — sessions from the same user are correlated — and your naive standard errors will be too small, sometimes by a factor of two or more. You will find significant results that aren't. Either analyze at the randomization unit, or use cluster-robust standard errors.

### The metric hierarchy

| Type | Role | Example |
|---|---|---|
| **Primary / OEC** | The one metric that decides ship/no-ship | Revenue per user |
| **Secondary** | Explain *why* the primary moved | Conversion rate, average order value |
| **Guardrail** | Must not degrade, regardless of the primary | Page latency, unsubscribe rate, support contacts |

Pick **one** primary metric. Two primaries is zero primaries — it guarantees a post-hoc argument about which one counted.

The primary metric must be sensitive enough to move within your test duration and aligned with long-term value. This is where most experimentation programs quietly fail: teams optimize a short-term proxy (clicks) that trades against the thing they actually want (retention). Goodhart's law is not a joke about metrics; it's the default outcome.

### Pre-registration

Write down, before launch: the hypothesis, the primary metric, the sample size and duration, the segments you'll examine, and the decision rule. Timestamp it.

This is the blind-analysis discipline from physics, and it exists for the same reason: the number of analysis choices available after seeing data is large enough that a determined analyst can find significance in noise without ever consciously cheating. Fixing the choices in advance removes the degrees of freedom.

---

## 3. Power, and the $1/\text{MDE}^2$ scaling law

Before running anything, determine the **minimum detectable effect** — the smallest true effect your test could reliably detect. For a two-sample comparison of means with equal allocation:

$$\mathrm{MDE} \approx (z_{1-\alpha/2} + z_{1-\beta})\sqrt{\frac{2\sigma^2}{n}}$$

At the conventional $\alpha = 0.05$, $\beta = 0.2$, the bracket is about 2.8. Inverting:

$$n \approx \frac{2\sigma^2 (z_{1-\alpha/2}+z_{1-\beta})^2}{\mathrm{MDE}^2} \;\propto\; \frac{\sigma^2}{\mathrm{MDE}^2}$$

**The scaling is the point: $n \propto 1/\mathrm{MDE}^2$.** Halving the effect you want to detect quadruples the sample. This is the same $\sqrt{N}$ behavior as any counting experiment, and it has a blunt organizational consequence: detecting a 0.5% lift is a hundred times more expensive than detecting a 5% lift. Most proposed tests are asking for the former with the traffic budget for the latter.

**Run the power calculation before the test, and act on it.** If the MDE is 8% and nobody believes the feature does more than 2%, you are about to spend three weeks learning nothing. That is a decision to make in advance, not a result to discover afterward.

### Underpowered tests don't just fail to find things

This is the point that most changes behavior, and it deserves emphasis.

When power is low, the *only* results that clear the significance threshold are ones where noise happened to push the estimate far from zero. Conditional on being significant, the estimate is therefore **inflated**. Gelman and Carlin call these Type M (magnitude) and Type S (sign) errors.

At 20% power, a statistically significant estimate is on average roughly **twice** the true effect, and has a non-trivial chance of carrying the wrong sign entirely. Your significant result is not a small win discovered against the odds — it is a systematically exaggerated one.

This is the mechanism behind the "winner's curse" in experimentation programs: teams ship the biggest-looking winners, which are disproportionately the noisiest estimates, and the aggregate lift never materializes in the annual numbers. If you routinely run underpowered tests and ship the winners, your program will report gains it does not deliver.

---

## 4. The peeking problem

Fixed-horizon significance tests are valid **only at a fixed horizon**. Checking the dashboard daily and stopping when $p < 0.05$ is not a slightly liberal version of the test — it's a different procedure with a different, much worse false-positive rate.

With continuous monitoring and no correction, the probability of crossing $p<0.05$ at *some* point during a test with no true effect is far above 5% — commonly 20–40% for realistic checking cadences, and by the law of the iterated logarithm it approaches **1** as the horizon grows. Run long enough, check often enough, and every null test eventually "wins."

The connection to the rest of the course is exact. This is the same principle as the test set in Module 6: *the moment you use a measurement to make a decision, it stops being a clean measurement.* Peeking uses the p-value to decide when to stop, so the p-value no longer means what it claims.

**Legitimate solutions:**

| Approach | How it works | When to use |
|---|---|---|
| **Fixed horizon** | Set $n$ and duration in advance; look once | Default; simplest to get right |
| **Group sequential** | Pre-planned interim looks with an alpha-spending function (O'Brien–Fleming, Pocock) | You need a few pre-scheduled early-stop opportunities |
| **Always-valid inference** | Sequential p-values and confidence sequences (mSPRT) valid at every time point | Continuous dashboards; most modern platforms use this |
| **Bayesian** | Report posterior on the effect | Fine, but a posterior probability is not a false-positive rate — stopping rules still affect your operating characteristics |

If your platform shows a live significance readout, it must be always-valid, or the readout is misleading by construction. Check what yours does.

---

## 5. Multiple comparisons

Twenty metrics, no true effects, $\alpha = 0.05$ each: the expected number of significant results is one. You will find it, and it will have a story.

Add segments — mobile vs desktop, new vs returning, by region, by tier — and the multiplicity compounds fast. This is the "garden of forking paths": even without deliberately fishing, an analyst who *would have* investigated different slices depending on what the data looked like has effectively performed many tests.

**Corrections:**

- **Bonferroni / Holm** control the family-wise error rate — the probability of *any* false positive. Conservative. Appropriate for guardrails, where a single false alarm is costly.
- **Benjamini–Hochberg** controls the false discovery rate — the expected *fraction* of your discoveries that are false. Much more powerful with many metrics. Appropriate for exploratory secondary metrics.

**The structural fix is the metric hierarchy from §2.** One primary metric, tested at full $\alpha$, decides the ship. Secondary metrics are explanatory and get FDR control. Guardrails are one-sided degradation checks with FWER control. Subgroup findings are **hypothesis-generating only** — they justify a new experiment, never a conclusion.

---

## 6. Variance reduction: the highest-leverage technique nobody uses

Since $n \propto \sigma^2/\mathrm{MDE}^2$, reducing $\sigma^2$ is exactly as valuable as increasing $n$ — and is often far cheaper.

### CUPED

Use a pre-experiment covariate $X$ (typically the same metric measured before the test) to adjust the outcome:

$$Y^{\text{adj}} = Y - \theta(X - \bar X), \qquad \theta = \frac{\mathrm{Cov}(Y,X)}{\mathrm{Var}(X)}$$

The adjusted metric is unbiased for the same effect, with variance reduced by a factor of $(1 - \rho^2)$, where $\rho$ is the correlation between pre- and in-experiment behavior.

For metrics like revenue per user, where last month strongly predicts this month, $\rho \approx 0.7$ is common — a **50% variance reduction, equivalent to doubling your traffic, for free.**

**The physical analogy is exact:** this is common-mode rejection. You have a noisy signal and a reference channel that carries the noise but not the effect. Subtract the reference and the shared fluctuation cancels, leaving the signal. It's a lock-in amplifier for experiments.

### Other approaches

- **Stratification / blocking.** Randomize within strata (platform, tenure, country) to guarantee balance rather than merely expecting it. Reduces variance and removes an obvious critique.
- **Regression adjustment.** Include pre-treatment covariates in the analysis model. Similar effect to CUPED; use Lin's estimator with treatment interactions to stay robust.
- **Trimming or winsorizing.** Revenue metrics are heavy-tailed, and a single whale can dominate a treatment arm. Cap at a high percentile, pre-specify the cap, and report both capped and uncapped results.

---

## 7. Threats to validity

Randomization is necessary, not sufficient. These are the systematics.

### Sample ratio mismatch

You intended a 50/50 split and observed 50.4/49.6. With large $n$ that deviation can be wildly improbable. A chi-square test on the assignment counts is the single most valuable automated check in an experimentation platform.

**An SRM invalidates the test.** It means the randomization or logging pipeline is broken — bots filtered asymmetrically, a redirect failing for one arm, an assignment call happening after a page render that itself differs by arm. The bias from whatever caused it typically dwarfs the effect you're measuring. Do not "adjust for" an SRM. Find the bug, fix it, rerun.

This is the trigger-efficiency check of experimentation: cheap, automatic, and it catches broken instrumentation before you interpret a result.

### Interference (SUTVA violations)

Standard analysis assumes one unit's treatment doesn't affect another's outcome. Violations are common and structural:

- **Social features** — treated users interact with control users, contaminating the control arm.
- **Marketplaces** — treatment sellers capturing demand *takes it from* control sellers, so the measured lift is partly transfer, not creation. This biases the estimate *away from zero* and is the reason marketplace A/B results routinely fail to replicate at full rollout.
- **Shared resources** — a treatment that consumes more capacity slows the control arm.

**Fixes:** cluster randomization (by geography, market, or social component), switchback designs (alternate the whole system between conditions over time), or budget-split designs for ad auctions.

### Novelty and primacy

New UI gets clicked because it's new; power users are temporarily slowed by change. Both decay. A one-week test on a UI change may measure the transient rather than the steady state.

**Diagnostic:** plot the effect by day, and separately for new vs. existing users. A monotonically decaying effect among existing users is a novelty signature. Run long enough to see the plateau.

### Attrition and survivorship

If treatment changes *who remains in the sample* — churning users, uninstalls, opt-outs — then your endpoint comparison conditions on post-treatment survival. This is collider conditioning from Module 2, and it reintroduces exactly the confounding randomization was meant to eliminate.

**Fix:** analyze on the originally randomized population (intention-to-treat), and treat differential attrition as a primary outcome in its own right.

---

## 8. Analysis

**Intention-to-treat.** Analyze every unit in the arm it was assigned to, regardless of whether it received or complied with the treatment. Dropping non-compliers destroys randomization, because compliance is a post-treatment variable that correlates with everything.

ITT answers *"what happens if we launch this?"* — usually the decision-relevant question, since at launch you also can't force compliance. If you want the effect on compliers, use assignment as an instrument (Module 2, §5.4) to recover the CACE.

**Ratio metrics need care.** Metrics like click-through rate, where numerator and denominator both vary across users, need the delta method or a bootstrap for correct standard errors. Naive binomial formulas at the event level ignore user-level clustering and understate uncertainty.

**Report confidence intervals, not p-values.** "+2.1% [−0.3%, +4.5%]" communicates the decision-relevant content: the effect is probably positive, possibly zero, plausibly meaningful. "$p = 0.09$" communicates almost nothing and invites a binary reading of a continuous result.

**Distinguish statistical from practical significance.** With ten million users, a 0.02% lift is detectable and irrelevant. Set the practically-significant threshold before launch and compare the confidence interval against it. Four outcomes worth distinguishing: significant and meaningful, significant and trivial, inconclusive, and conclusively-no-effect (CI tight and inside the trivial zone) — the last is a genuine and valuable result that programs habitually mislabel as failure.

---

## 9. Beyond the two-arm test

| Design | Use for | Watch out for |
|---|---|---|
| **Multi-armed (A/B/n)** | Several variants at once | Multiplicity; correct for the number of arms |
| **Factorial** | Multiple changes and their interactions | Interactions need much more power than main effects |
| **Multi-armed bandits** | Many low-stakes variants, continuous optimization | Adaptive allocation breaks standard inference; excellent for maximizing reward, poor for *measuring* effects |
| **Switchback** | System-level treatments with strong interference | Temporal autocorrelation; needs careful period length |
| **Interleaving** | Ranking and search comparisons | Very sensitive, but the estimand is relative preference, not absolute impact |
| **Holdout groups** | Cumulative effect of many launches over a quarter | Long-run contamination; users leaking between groups |

On bandits specifically: they optimize cumulative reward, not inferential quality. If the goal is "learn the effect size," run a fixed experiment. If the goal is "route traffic to whatever works," a bandit is appropriate — but don't then report the winner's lift as if it came from a clean test, because adaptive allocation makes those estimates biased.

---

## 10. Failure modes

| Symptom | Likely cause |
|---|---|
| Traffic split isn't exactly as configured | SRM — broken assignment or logging; the result is invalid |
| Result became significant right when someone checked | Peeking; the p-value isn't valid at that stopping point |
| One segment shows a huge effect, overall shows nothing | Multiplicity; hypothesis-generating at best |
| Effect large in week 1, gone by week 3 | Novelty; the steady state is what matters |
| Significant win, but shipping it moves no company metric | Underpowered test → inflated estimate; or a proxy metric that doesn't translate |
| Marketplace test shows a big lift, full rollout shows none | Interference — you measured transfer between arms, not creation |
| Confidence intervals suspiciously tight | Analysis unit finer than randomization unit; clustering ignored |
| Primary metric flat, three secondaries moved | You have no result; you have hypotheses for the next test |

---

## 11. Practical recipe

1. **State the hypothesis and the decision rule.** What will we do if it wins, loses, or comes out flat?
2. **Choose one primary metric**, plus secondaries and guardrails.
3. **Pick the randomization unit** to minimize interference; make the analysis unit match it.
4. **Run the power calculation.** If the MDE exceeds any plausible effect, redesign or don't run it.
5. **Apply variance reduction** — CUPED and stratification — *before* deciding you need more traffic.
6. **Pre-register** the whole plan, timestamped.
7. **Run an A/A test** on the platform periodically. It should produce significant results about 5% of the time. If not, the platform is broken.
8. **Check SRM automatically**, every day, and halt on failure.
9. **Don't peek** unless your platform provides always-valid inference or you pre-planned interim analyses.
10. **Analyze ITT**, report confidence intervals, compare against the pre-set practical threshold.
11. **Write the result down whether it won or not.** A file of honest nulls is a real organizational asset, and its absence is why teams re-run the same failed idea every eighteen months.

---

## 12. Further reading

- Kohavi, Tang & Xu, *Trustworthy Online Controlled Experiments* — the practitioner's standard. SRM, interference, novelty, metric design, and organizational structure, all from large-scale industrial experience.
- Deng, Xu, Kohavi & Walker (2013), "Improving the sensitivity of online controlled experiments by utilizing pre-experiment data" — the CUPED paper.
- Johari, Koomen, Pekelis & Walsh (2017), "Peeking at A/B tests: why it matters and what to do about it" — quantifies the peeking inflation and derives always-valid alternatives.
- Gelman & Carlin (2014), "Beyond power calculations: assessing Type S and Type M errors" — why underpowered significant results are exaggerated.
- Gelman & Loken (2013), "The garden of forking paths" — how honest analysts generate false positives without ever running multiple tests.
- Blake & Coey (2014), "Why marketplace experimentation is harder than it seems" — interference in two-sided markets.
