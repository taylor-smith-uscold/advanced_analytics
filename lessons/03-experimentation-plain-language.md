# Running Tests You Can Trust: A Plain-Language Guide to Experimentation

*How to design an A/B test that gives you a real answer — and how to spot one that doesn't.*

---

## The short version

An experiment is the only way to find out whether something works without relying on assumptions you can't verify. Flip a coin, treat half, compare. That simple move solves the entire problem from the causal inference module: the two groups are the same in every respect, including all the things you never thought to measure.

But randomizing the assignment is only the first step. Almost everything downstream can still ruin the result, and the ways it happens are predictable:

- **Checking results until you see a win** turns a 5% false-positive rate into something closer to 30%.
- **Tracking twenty metrics** guarantees one looks significant by accident.
- **Running a test too small to detect your effect** doesn't just fail — it makes any "win" you do find a systematic exaggeration.

All three are the same mistake in different clothes: **anything you optimize against stops being a measurement.** The fix is also the same: decide what you're measuring and when you'll stop, before you start.

---

## Part 1: Why experiments are worth the trouble

From the causal module: comparing customers who did something to customers who didn't gives you the real effect *plus* however different those people were to begin with. That second part is usually large.

Randomly assigning the treatment makes the second part zero. The groups are the same on average — same spending history, same tenure, same enthusiasm, **same everything you didn't measure.**

That last part is what you're paying for. Statistical adjustment can only handle confounders you knew to collect. Randomization handles the ones nobody listed.

**What randomization does *not* give you:** a guarantee that you measured the right thing, that your users don't affect each other, that your assignment code works, that the effect lasts, or that your analysis was honest. Those are the rest of this guide.

---

## Part 2: Decisions to make before launch

### What are you randomizing?

Usually users. Sometimes sessions, accounts, stores, or entire cities.

**Whatever you randomize, analyze at that same level.** If you randomize by user but count sessions, you're treating one person's ten sessions as ten independent pieces of evidence. They aren't — they're one person behaving consistently. Your uncertainty estimate comes out far too small, and you'll declare victories that aren't there.

This is a common and invisible bug. The result looks great; the error bars are fiction.

### Pick ONE primary metric

Three tiers:

| Tier | Purpose | Example |
|---|---|---|
| **Primary** | The single number that decides ship or don't | Revenue per user |
| **Secondary** | Help explain *why* the primary moved | Conversion rate, order size |
| **Guardrails** | Must not get worse, no matter what | Page load time, unsubscribe rate, support tickets |

**One primary. Not two.** Two primary metrics guarantees an argument after the fact about which one counted, and that argument is always won by whichever one moved.

Choosing the primary metric is the most consequential decision in the whole test, and it's usually made carelessly. If you pick something easy to move (clicks) that trades off against what you actually want (retention), you'll run a successful experimentation program that makes the business worse. This happens constantly.

### Write the plan down first

Before launch, record: the hypothesis, the primary metric, how long you'll run, how many users you need, which segments you'll look at, and what you'll do for each possible outcome. Timestamp it.

The reason isn't bureaucratic. After seeing data, there are *dozens* of defensible-looking choices available — which outliers to drop, which window to use, which segment to highlight — and picking among them after the fact will find you a significant result in pure noise without you ever feeling like you cheated. Fixing the choices in advance removes the option.

---

## Part 3: Power — will this test even work?

Before running anything, ask: **what's the smallest effect this test could reliably detect?**

If the answer is "8%" and nobody thinks the feature does more than 2%, you're about to spend three weeks and a chunk of traffic learning nothing. **That's a decision to make beforehand, not a disappointment to discover after.**

### The rule that governs everything

> **To detect an effect half as large, you need four times the sample.**

Effects get expensive fast. Detecting a 5% lift might take a week. Detecting a 0.5% lift — ten times smaller — takes **a hundred times the traffic**. Most proposed tests are hoping for tiny effects on the traffic budget of large ones.

Run the calculation. There are free calculators; it takes two minutes. It's the highest-value two minutes in the whole process.

### The part that changes how you'll read every result

Here's the counterintuitive bit, and it's the most important thing in this document.

**When a test is underpowered, the wins it finds are systematically exaggerated.**

Think about why. If your test is too small, the only way anything crosses the significance line is if random noise happened to push the estimate way up. So *among the results that reach significance*, the estimates are inflated — not by a little.

At the power levels typical of hurried tests, a "significant" result is on average about **twice** the true effect, and has a real chance of pointing the wrong direction entirely.

**This is why experimentation programs report gains that never show up in the annual numbers.** Teams ship the biggest-looking winners. The biggest-looking winners are disproportionately the noisiest measurements. Add up a year of exaggerated wins and the total is a number nobody can find in the P&L.

The lesson: a small test that produces a big significant win is *more* suspicious, not less.

---

## Part 4: The peeking problem

You launch on Monday. You check Tuesday — nothing. Wednesday — nothing. Thursday — significant! Ship it.

**That result is not valid, and the effect is not small.**

The 5% false-positive rate assumes you look **once**, at a predetermined time. Every additional look is another chance for random fluctuation to cross the line. Check daily for two weeks and the real false-positive rate is more like 20–30%.

And it gets worse: with enough checking over a long enough period, a test with *no real effect at all* will eventually show significance essentially **every time**. Random walks wander. Given enough looks, they wander across the line.

The connection to the cross-validation module is exact: **you used the p-value to decide when to stop, so the p-value no longer measures what it claims.** Same as looking at your test set, changing something, and looking again.

### What to do instead

- **Fix the duration in advance and look once.** Simplest, always correct. Also lets the test run through a full weekly cycle, which you want anyway.
- **Pre-plan your interim checks.** There are standard methods that let you look, say, three times at scheduled points using stricter thresholds.
- **Use always-valid statistics.** Modern experimentation platforms use methods designed to be checked continuously. If yours does, peek freely.

**Find out which one your platform uses.** If it shows a live significance readout without always-valid inference underneath, that readout is misleading by design, and everyone on your team is being fooled by it daily.

---

## Part 5: Testing lots of things at once

Track twenty metrics on a treatment that does nothing, and **one will look significant.** That's just what a 5% error rate means, applied twenty times. It will also have a compelling story attached, because humans are excellent at generating those.

Add segments — mobile vs desktop, new vs returning, by region, by tier — and the count multiplies fast. Even without deliberately fishing, an analyst who *would have looked at different slices* depending on what the data showed has effectively run many tests.

**The structural fix is the metric hierarchy.** One primary metric decides the outcome. Secondary metrics explain it. Guardrails check for damage.

**And treat every subgroup finding as a hypothesis, not a conclusion.** "It didn't work overall, but it worked great for mobile users in Germany" is a reason to run a new test on mobile users in Germany. It is never a reason to ship.

If you must test many metrics formally, ask your statistician about Benjamini–Hochberg corrections. But the discipline matters more than the correction.

---

## Part 6: Getting more out of less traffic

Since sample size scales with the *square* of the effect you're chasing, anything that reduces noise is as valuable as more traffic — and is usually cheaper and faster.

### The single best trick: use pre-experiment data

If you know how much each user spent *last month*, you can subtract out most of the natural variation between users before comparing groups. The technique is called **CUPED**, and it works because last month's spending predicts this month's but has nothing to do with which arm you assigned them to.

For metrics like revenue per user, this routinely cuts noise by **half — the equivalent of doubling your traffic, for free.** Most experimentation platforms support it. Many teams don't turn it on.

The intuition: you have a noisy measurement and a reference that captures the noise but not the effect. Subtract the reference, the shared wobble cancels, the signal stays.

### Other options

- **Balance the groups on purpose.** Rather than hoping randomization evens out platform or tenure, randomize *within* each category so balance is guaranteed.
- **Cap extreme values.** Revenue is heavy-tailed, and one enormous customer landing in the treatment arm can swamp everything. Decide on a cap *before* the test and report results both ways.

---

## Part 7: Things that break a valid-looking test

### The traffic split is slightly off

You configured 50/50 and got 50.4/49.6. With millions of users, that's not rounding — it's a signal that something's broken. Bots filtered from one arm. A redirect failing. Assignment logged after a page render that differs by arm.

**This invalidates the test.** Whatever caused the imbalance is almost certainly biasing your result by more than the effect you're measuring. Don't adjust for it. Find the bug and rerun.

Automate this check. It's cheap, and it catches broken instrumentation before anyone interprets a number.

### Your users affect each other

Standard analysis assumes one user's treatment doesn't change another user's outcome. Often false:

- **Social features** — treated users interact with control users, contaminating the comparison.
- **Marketplaces** — if treated sellers get more visibility, they take demand *from* control sellers. Your measured lift is partly transfer, not creation, so it looks great in the test and evaporates at full rollout. This is the standard reason marketplace tests overpromise.
- **Shared capacity** — a treatment that uses more resources slows down the control arm.

**Fix:** randomize whole groups instead — cities, markets, or communities — so effects stay contained.

### The effect is just novelty

New things get clicked because they're new. Power users get temporarily slowed by any change and then adapt. Both fade.

**Check:** plot the effect by day, separately for new and existing users. If it's decaying steadily among existing users, you're measuring novelty. Run longer until it flattens out.

### Users dropping out

If your treatment makes some users leave, and you compare only those who stayed, you've broken randomization — the remaining groups are no longer comparable. This is exactly the selection problem from the causal module.

**Fix:** analyze everyone you originally assigned, and treat differential dropout as a finding in its own right.

---

## Part 8: Analyzing and reporting

### Count everyone you assigned

Include every user in the arm you assigned them to, even if they never saw the feature, didn't finish onboarding, or ignored the email.

Dropping non-participants feels reasonable and destroys the experiment. The people who engaged are systematically different from those who didn't — that's why they engaged — so comparing engagers to the whole control group reintroduces exactly the bias randomization removed.

It also answers the right question: at launch, you also can't force anyone to use the feature.

### Report intervals, not verdicts

**"+2.1%, somewhere between −0.3% and +4.5%"** tells a decision-maker what they need: probably positive, possibly nothing, plausibly worthwhile.

**"p = 0.09, not significant"** tells them almost nothing and invites the wrong binary reading.

### Statistical significance isn't business significance

With ten million users you can detect a 0.02% lift. You probably shouldn't care about it.

Decide *before* the test how big an effect would actually be worth shipping. Then compare your interval to that line. Four genuinely different outcomes:

1. **Significant and big enough** → ship
2. **Significant but trivially small** → statistically real, practically pointless
3. **Inconclusive** → the interval spans both meaningful and nothing; you learned little
4. **Confidently no effect** → tight interval centered near zero

Number 4 is a **real result** and a valuable one. Teams routinely file it as failure, then re-run the same idea two years later.

---

## Part 9: Warning signs

| What you see | What's probably happening |
|---|---|
| Split isn't exactly what you configured | Something's broken; result is invalid |
| Went significant right when someone checked | Peeking; that p-value doesn't mean what it says |
| One segment shows a big effect, overall shows nothing | Multiple comparisons; it's a hypothesis, not a finding |
| Big in week 1, gone by week 3 | Novelty effect |
| Significant win that never shows up in company numbers | Underpowered test producing inflated estimates |
| Marketplace test wins big, full rollout does nothing | Treatment took business from the control arm |
| Error bars look surprisingly tight | Analyzing at a finer level than you randomized |
| Primary flat, three secondaries moved | No result — you have ideas for the next test |

---

## Putting it all together

**The recipe:**

1. **Write the hypothesis and the decision rule.** What happens if it wins, loses, or comes out flat?
2. **Pick one primary metric**, plus secondaries and guardrails.
3. **Choose the randomization unit** so users don't affect each other; analyze at that same level.
4. **Run the power calculation.** If the detectable effect is bigger than any plausible real effect, redesign or don't run it.
5. **Turn on CUPED and stratification** before concluding you need more traffic.
6. **Write the plan down, timestamped.**
7. **Run periodic A/A tests** — treatment identical to control. Should show significance about 5% of the time. If it doesn't, your platform is broken and every result is suspect.
8. **Check the traffic split daily.** Halt on mismatch.
9. **Don't peek** unless your platform is built for it.
10. **Analyze everyone assigned**, report intervals, compare to your pre-set threshold.
11. **Record the result either way.** A library of honest nulls is a real asset, and its absence is why the same failed idea gets proposed every eighteen months.

**Three things to remember if you remember nothing else:**

- **Run the power calculation first.** An underpowered test isn't just a wasted test — the "wins" it produces are systematically exaggerated, which is worse than no answer.
- **Decide when you'll stop before you start.** Checking until you like the number turns a 5% error rate into something like 30%.
- **One primary metric, chosen carefully.** Everything else is explanation. Subgroup findings are hypotheses for the next test, never conclusions from this one.

---

## Where to go next

- **The practitioner's standard:** *Trustworthy Online Controlled Experiments* by Kohavi, Tang & Xu — written from running experiments at scale at Microsoft, Amazon, and Airbnb. Practical, direct, and full of real failures. If your team reads one book, this is it.
- **On peeking:** Johari et al., "Peeking at A/B Tests" — quantifies exactly how bad it gets and explains what modern platforms do about it.
- **On exaggerated wins:** Gelman & Carlin, "Beyond Power Calculations" — the source of the underpowered-tests-inflate-effects argument in Part 3.
- **On variance reduction:** the original CUPED paper (Deng et al., 2013) is short and readable.
