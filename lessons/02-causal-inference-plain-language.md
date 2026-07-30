# Does It Actually Work? A Plain-Language Guide to Causal Inference

*How to tell whether something causes an outcome, or just travels alongside it.*

---

## The short version

Your model can predict brilliantly and still tell you nothing about what to do.

"Customers who contact support churn three times as often" is a useful *prediction*. As a basis for *action* it's worse than useless — nobody thinks the fix is to make support harder to reach. People contact support because something's wrong, and the same wrongness makes them leave.

Almost every question a stakeholder actually asks is a causal one: *if we do this, will that happen?* Prediction can't answer it. Answering it requires either an experiment, or an argument — stated out loud, and usually impossible to prove — about why your comparison is fair.

This guide is about recognizing which question you're being asked, and what it takes to answer the causal one honestly.

---

## Part 1: Why prediction isn't enough

### The two questions

**Prediction:** "Among customers who did X, how many churned?" You watch and record.

**Causation:** "If we made customers do X, how many would churn?" You intervene.

These come apart whenever something else drives both X and the outcome. Some real examples:

| The finding | The tempting action | What's probably going on |
|---|---|---|
| Loyalty program members spend 40% more | Enroll everyone | Heavy spenders join loyalty programs |
| Customers contacted by a rep convert more | Contact everyone | Reps target customers likely to convert |
| Users of feature X churn less | Push feature X | Already-committed users explore more features |
| Coupon recipients buy more | Send more coupons | Coupons went to people already browsing |
| Bigger fires have more firefighters present | Send fewer firefighters | Fire size causes both |

The last one is obvious. The first four are the same structure, and they get acted on in real companies constantly, because they arrive wrapped in a well-validated model with a good cross-validation score.

**Predictive accuracy provides no protection here.** A model can be 95% accurate and still point the wrong way on every one of these.

### Two things to unlearn from earlier modules

**Regularized coefficients are not effect sizes.** Regularization shrinks coefficients toward zero *on purpose* — that was the whole point. They're deliberately biased. Reading one as "the effect of a one-unit change" adds a bias you introduced yourself on top of the confounding you haven't dealt with.

**Feature importance is not causal importance.** SHAP values tell you how much a feature moved *the model's prediction*. In the support-contact example, "contacted support" would have enormous importance — correctly, because it does predict churn. The importance score is right and the causal reading of it is wrong.

---

## Part 2: The problem, stated precisely

For any customer, there are two possible futures: what happens if we treat them, and what happens if we don't. The effect on that customer is the difference.

**You can only ever see one of them.** You send the discount or you don't. The other future is gone permanently.

This is the core difficulty, and it's not a data problem you can solve by collecting more. Individual effects are unknowable. What you can hope to estimate is an *average* effect across a group — and only if you can find a fair comparison group.

### Why the obvious comparison is unfair

Compare loyalty members to non-members and you get:

> **the true effect of the program** + **how different those people were to begin with**

The second term is usually large and there's no reason for it to be small. Loyalty members were already better customers before they joined. You're measuring the program's effect plus a pre-existing gap, with no way to separate them from that comparison alone.

Everything that follows is a technique for making the second term go away, or for bounding how big it could be.

---

## Part 3: Why experiments are special

If you assign the treatment by coin flip, the two groups are — on average — identical in every respect. Same spending history, same tenure, same enthusiasm, **same everything you never thought to measure.**

That last part is the crucial bit, and it's why randomization is qualitatively different from statistical adjustment rather than just more convenient.

> You can only control for confounders you measured. Randomization handles the ones you don't know exist.

This is why "we controlled for a lot of variables" is a much weaker claim than it sounds. It means you handled the confounders you thought of. The dangerous ones are usually the ones nobody listed.

**When you can run an experiment, run one.** A small clean test beats a large messy observational study. Module 3 covers how to run them without wrecking them. The rest of this guide is what to do when you genuinely can't.

---

## Part 4: Drawing the picture (and the three shapes)

Before analyzing anything, draw a diagram: boxes for variables, arrows for "this causes that."

This feels almost too simple to be useful. It isn't. **The arrows you leave out are your assumptions**, and drawing the picture forces you to say them out loud where colleagues can disagree. Most bad analyses would have been caught by fifteen minutes at a whiteboard with someone who knows the business.

Three shapes explain nearly everything.

### Shape 1: The confounder (control for it)

```
        Customer size
        /            \
       ↓              ↓
  Has a rep  ------>  Revenue
```

Company size drives both whether you assign a rep and how much they spend. This creates a fake association between reps and revenue. **Control for it** — compare like-sized customers to each other.

This is the one everybody knows.

### Shape 2: The mediator (do NOT control for it)

```
  Price increase → Satisfaction drops → Churn
```

Here price genuinely causes churn, *by way of* satisfaction. If you control for satisfaction, you're comparing customers who got a price increase to those who didn't **while holding their happiness constant** — which erases the mechanism you were trying to measure. You'll conclude price doesn't matter.

**Controlling for a mediator hides real effects.** This is a common and expensive mistake.

### Shape 3: The collider (controlling for it CREATES a fake effect)

This one is genuinely surprising, and it's why "just control for everything" is wrong.

```
  Résumé strength → HIRED ← Interview performance
```

Among *everyone who applied*, résumé strength and interview performance are probably positively related. Among *the people you hired*, they're often negatively related — because you'll hire a weak résumé if the interview was spectacular, and a mediocre interviewer with a stellar background.

Look only at hires, and you'll "discover" that good résumés predict worse interviews. Nothing caused that. **Your selection did.**

**Why this matters more than it sounds:** any analysis restricted to a filtered group is doing this. Active customers only. Completed orders only. Accounts that survived the first year. If the filter depends on both the thing you're studying and the outcome, you've created an association out of nothing.

### The rule

**Control for confounders. Never control for mediators or colliders.**

And notice: which one a variable *is* cannot be determined from the data. It comes from your understanding of the business. Two analysts with the same dataset and different diagrams get different answers, and both are doing the statistics correctly.

### Simpson's paradox

Sometimes a pattern flips when you break it into groups. A treatment looks worse overall but better in every single subgroup — because the sicker patients got treated more often.

Which answer is right? **It depends entirely on the diagram.** If severity causes both treatment and outcome, trust the subgroups. If treatment causes severity, trust the aggregate. The numbers alone can't tell you, and this is the clearest demonstration that causal questions need more than data.

---

## Part 5: Five strategies when you can't experiment

Each one buys its answer with a different assumption. Pick the one whose assumption is most believable in your situation.

### 1. Adjustment and matching

**The idea:** find comparable untreated units and compare like with like.

**Methods:** include controls in a regression, or match each treated unit to similar untreated ones, or weight units by how likely they were to be treated (propensity scores).

**The assumption:** you measured everything that matters. Untestable, and usually the weakest link.

**Check overlap.** For every kind of treated customer, do comparable untreated ones exist? If enterprise accounts *always* get a rep, no amount of adjustment tells you what a rep does for an enterprise account. Your data contains no counterpart. Look at the distributions before trusting any adjustment — if they barely overlap, you're extrapolating, not comparing.

### 2. Difference-in-differences

**The idea:** compare the *change* in a treated group to the *change* in an untreated one. Any constant difference between the groups cancels out.

Rolled out a new pricing model in the West region? Compare West's before-and-after change to East's over the same window.

**The assumption:** absent the change, the two regions' trends would have moved in parallel. They can be at completely different levels — that's fine, it cancels. They just have to move together.

**How to check it:** plot both regions for many periods before the change. The lines should move in parallel. If West was already pulling away, the assumption fails and you'll misattribute an existing trend to your intervention. **This plot is the whole argument** — don't run the analysis without it.

**One serious trap:** if different regions adopted at different times, the standard regression everyone reaches for can produce badly wrong answers — including the wrong *sign*, even when the true effect is positive everywhere. It quietly uses already-treated regions as controls for later ones. If your rollout was staggered, look up the modern estimators (Callaway–Sant'Anna is the common one), or you'll get a confidently incorrect number.

### 3. Threshold comparisons (regression discontinuity)

**The idea:** if a rule assigns treatment at a cutoff — spend over $10,000 gets premium support — then customers just above and just below the line are nearly identical, except for the treatment.

Compare $9,900 customers to $10,100 customers. Any jump in outcomes at the boundary is the effect.

**The assumption:** nothing else changes discontinuously at the cutoff, and customers can't manipulate which side they land on.

**Check:** are customers bunching just above $10,000? That means they're gaming the threshold, and the two sides aren't comparable. Plot the distribution of the running variable and look for a spike.

**Limitation:** you learn the effect *near the cutoff*. It says nothing about your $500 customers.

### 4. Instruments

**The idea:** find something that nudges treatment for essentially random reasons and affects the outcome no other way. Distance to the nearest store. A staffing shortage. A random ordering in a queue.

**The assumption:** your instrument affects the outcome *only* through the treatment. Untestable, and where these arguments almost always break.

**Two cautions.** First, if the instrument barely moves the treatment, the method doesn't just get imprecise — it gets *biased*, and the confidence interval lies to you. Second, you learn the effect only on the people the instrument actually moved, who may not resemble anyone you care about.

Powerful when the story is airtight. Most instrument stories are not airtight.

### 5. Synthetic control

**The idea:** one market got the treatment. Build a weighted blend of other markets that closely tracked it *before* the change, and use that blend as the counterfactual.

Good for one-off, large interventions: a regional launch, a single market's price change. Requires a long, clean pre-period.

---

## Part 6: If you can't prove the assumption, bound it ("sensitivity analysis")

Every non-experimental method rests on something you can't verify. Since you can't prove it, ask **how wrong it would have to be to change your conclusion.** This is called *sensitivity analysis*, and it is the single most persuasive thing you can add to an observational result.

- **How strong would a hidden confounder need to be?** There are standard ways to compute this. If the answer is "about as strong as the variables you already measured," you've learned nothing. If it's "five times stronger than anything we've ever observed," your result is fairly solid.
- **Negative controls.** Find an outcome your treatment obviously *can't* affect. Run the same analysis. If you find an effect, your method is detecting confounding, not causation. This is a smoke test and it catches a lot.
- **Fake timing.** Pretend the change happened a year earlier and re-run. You should find nothing.

The habit here: **your uncertainty is not the confidence interval.** In observational work, the confidence interval is usually the smallest source of doubt. Reporting it alone is the most common way analysts oversell a finding.

---

## Part 7: Who should we treat? (Effects that vary)

Averages hide the actionable question. If a discount lifts revenue 3% on average, that could mean everyone gains 3%, or that 20% of customers gain 15% and everyone else gains nothing — and the second case is a completely different business decision.

Estimating effects per-segment ("uplift modeling") is a real and useful technique. Two warnings:

**You can't validate it the usual way.** There's no ground-truth "effect" column to score against, because you never observe both futures for anyone. The cross-validation machinery from Module 6 doesn't directly apply, and specialized evaluation (uplift curves) is required.

**If you're using machine learning anywhere in a causal estimate, the regularization bias contaminates the answer.** There's a standard fix — estimate the nuisance pieces on one slice of data and the effect on another, using a specifically constructed formula. It's the same instinct as keeping your scaler inside the cross-validation fold, applied to a harder problem. If your team is doing this, make sure they're doing it with a library that implements it properly rather than assembling it by hand.

---

## Part 8: Warning signs

| What you see | What's probably happening |
|---|---|
| "Users of feature X churn less" | Reverse causation — committed users explore more |
| The effect vanishes when you add a control | That control is a confounder — or a mediator, and you just erased the effect |
| The effect only appears after adding many controls | You may have opened a fake path; check the diagram |
| Groups look perfectly balanced after matching | Balanced on what you measured. Says nothing about what you didn't |
| Staggered rollout, standard regression | Likely producing a wrong number, possibly the wrong sign |
| Analysis covers only active/surviving customers | Selection is manufacturing associations |
| Overall result contradicts every subgroup | Simpson's paradox — resolve with the diagram, not more data |
| Very tight confidence interval on observational data | The confidence interval isn't your real uncertainty |

---

## Putting it all together

**The recipe:**

1. **Ask what decision this serves.** What would we do differently depending on the answer? If nothing, stop here.
2. **Ask whether you can run an experiment.** Ask twice. It's almost always more feasible than people assume.
3. **Draw the diagram** with someone who knows the business, before touching the data.
4. **Sort every variable** into confounder, mediator, collider, or irrelevant. Control for the first group only.
5. **Pick the strategy whose assumption you can actually defend** in this situation.
6. **Run the design's own check** — overlap, parallel pre-trends, no bunching at the cutoff.
7. **Test how fragile it is.** Negative controls, fake timing, hidden-confounder strength.
8. **Put the assumptions in the executive summary**, not the appendix. They're as much the finding as the number is.

**Three things to remember if you remember nothing else:**

- **A great model tells you what to expect, not what to do.** Those are different questions and predictive accuracy doesn't bridge them.
- **"We controlled for a lot of variables" is a weak defense.** You controlled for what you thought of. And controlling for the wrong variables actively creates problems — mediators hide real effects, colliders invent fake ones.
- **Say your assumptions out loud.** Every non-experimental result rests on something unprovable. The professional move isn't to hide that, it's to state it and show how much violation your conclusion survives.

---

## Where to go next

- **Best starting point:** *Causal Inference: The Mixtape* by Scott Cunningham — free online, applied, with code. Written for practitioners rather than theorists.
- **The intuitive version:** *The Book of Why* by Judea Pearl — makes the diagrams click. No math required.
- **The practical econometrics:** *Mastering 'Metrics* by Angrist & Pischke — short, readable, covers difference-in-differences, thresholds, and instruments with real examples.
- **For rigor when you need it:** *Causal Inference: What If* by Hernán & Robins — free online, and the clearest treatment of colliders and overlap anywhere.
