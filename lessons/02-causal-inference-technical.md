# Correlation, Intervention, and Identification: Causal Inference

*Module 2 — technical register. For readers who understand the difference between observing a system and perturbing it.*

> **Required reading —** Cunningham, *Causal Inference: The Mixtape*, ch. 3–4 · [mixtape.scunning.com](https://mixtape.scunning.com/)

---

## 0. The one-paragraph version

Every model in the preceding documents estimates $P(Y \mid X)$ — what $Y$ tends to be when we *observe* $X$. Almost every business question is about $P(Y \mid do(X))$ — what $Y$ would be if we *set* $X$. These are different quantities, and no amount of predictive accuracy converts one into the other. The gap is bridged by **identification**: an argument, external to the data, that the causal quantity is determined by the observable distribution. Identification is where the intellectual work happens; estimation is comparatively routine. Randomization identifies causal effects by construction. Without it, you rely on assumptions — parallel trends, exclusion restrictions, no unmeasured confounding — that are typically untestable, which means your job is to state them explicitly and quantify how badly wrong they'd have to be to overturn your conclusion. This is systematic uncertainty budgeting, not statistics.

---

## 1. Two different questions

Consider a model that predicts churn, and finds that customers who contact support churn at three times the base rate. The coefficient is large, stable, and cross-validates beautifully.

**As a prediction, it's fine.** Flag those customers; the model will be right about them more often than chance.

**As a basis for action, it's silent.** Should we reduce support contacts? Obviously not — the causal arrow almost certainly runs the other way. People contact support because something is wrong, and the same something makes them leave.

Formally, the observational conditional distribution $P(Y \mid X = x)$ answers *"among units where $X$ happens to equal $x$, what is $Y$?"* The interventional distribution $P(Y \mid do(X = x))$ answers *"if we reached in and set $X$ to $x$ for everyone, what would $Y$ be?"* The `do` operator deletes the arrows *into* $X$ — it severs $X$ from whatever normally determines it. Conditioning does not.

Two consequences for anyone who has read the earlier documents in this course:

- **Regularized coefficients are not effect estimates.** You shrank them deliberately, toward zero, trading bias for variance. They are biased *by construction*. Reading a ridge coefficient as an effect size compounds the confounding problem with a bias you introduced on purpose.
- **Feature importance is not causal importance.** A SHAP value tells you how much a feature moved *this model's prediction*. Under collinearity, importance is distributed among correlated features essentially arbitrarily — the same degeneracy that made lasso's selection unstable.

---

## 2. Potential outcomes

For each unit $i$ and a binary treatment $D \in \{0,1\}$, define two potential outcomes: $Y_i(1)$ if treated, $Y_i(0)$ if not. The individual treatment effect is $\tau_i = Y_i(1) - Y_i(0)$.

**The fundamental problem of causal inference:** you observe $Y_i = D_i Y_i(1) + (1-D_i)Y_i(0)$ — exactly one of the two. The other is counterfactual and permanently unobservable. Individual effects are not identified, period. This is a missing-data problem where half the data is missing by logical necessity, not by accident.

What *is* potentially identifiable are averages:

| Estimand | Definition | Answers |
|---|---|---|
| **ATE** | $\mathbb{E}[Y(1) - Y(0)]$ | Effect of treating everyone |
| **ATT** | $\mathbb{E}[Y(1)-Y(0) \mid D=1]$ | Effect on those actually treated |
| **CATE** | $\mathbb{E}[Y(1)-Y(0) \mid X=x]$ | Effect for a subgroup |
| **LATE** | $\mathbb{E}[Y(1)-Y(0) \mid \text{compliers}]$ | Effect on those an instrument moves |

These can differ substantially, and papers argue past each other constantly by estimating one and discussing another. **Name your estimand before you touch the data** — it's the causal analogue of pre-registering your metric.

### Why the naive comparison fails

The observed difference in means decomposes exactly:

$$\underbrace{\mathbb{E}[Y \mid D=1] - \mathbb{E}[Y \mid D=0]}_{\text{what you compute}} = \underbrace{\mathbb{E}[Y(1)-Y(0)\mid D=1]}_{\text{ATT}} + \underbrace{\mathbb{E}[Y(0)\mid D=1] - \mathbb{E}[Y(0)\mid D=0]}_{\text{selection bias}}$$

The second term asks: **would the treated and untreated groups have differed anyway, absent treatment?** For loyalty programs, sales outreach, or feature adoption, the answer is emphatically yes — those groups were different before anything happened. The selection bias term is frequently larger than the effect you're trying to measure, and it has no reason to be small.

---

## 3. What randomization buys

Random assignment makes $D \perp \{Y(0), Y(1)\}$. The selection term vanishes because treated and control groups are draws from the same population — **in expectation, balanced on every covariate, observed and unobserved alike.**

That last clause is the whole point, and it's why randomization is qualitatively different from statistical adjustment rather than just more convenient. You can only adjust for confounders you measured. Randomization handles the ones you never thought of.

The mechanism is worth stating in interventional language: randomization *is* the `do` operator, physically implemented. It severs every arrow into $D$ and replaces them with a coin flip that, by construction, has no common cause with anything else in the system.

When you can randomize, do. Module 3 covers how to do it without wrecking it. The rest of this document is about what to do when you can't.

---

## 4. Graphs: the language for stating assumptions

A DAG encodes your qualitative causal beliefs. Nodes are variables, arrows are direct causal effects, and — critically — *absent* arrows are the substantive claims. Drawing the graph forces you to commit to assumptions you'd otherwise leave implicit.

Three elementary structures generate all the behavior:

### Fork (confounder): $X \leftarrow Z \rightarrow Y$

$Z$ causes both. $X$ and $Y$ are correlated with no causal relation between them. **Conditioning on $Z$ removes the spurious association.** This is the case everyone knows.

### Chain (mediator): $X \rightarrow M \rightarrow Y$

$X$ affects $Y$ through $M$. $X$ and $Y$ are correlated, causally. **Conditioning on $M$ blocks the path and removes part of the very effect you're trying to measure.** Controlling for a mediator is a common and serious error: if you regress churn on price *and* on customer satisfaction, and price affects churn largely by making people unhappy, you've just adjusted away most of the price effect.

### Collider: $X \rightarrow C \leftarrow Y$

$X$ and $Y$ both cause $C$, and are marginally independent. **Conditioning on $C$ creates a spurious association between them.**

This one is genuinely counterintuitive and is the reason "control for everything you have" is wrong.

**A physical version.** A detector records total energy $C = S + N$, signal plus noise, with $S$ and $N$ independent. Select events in a narrow window of total energy — condition on $C$ — and within that slice, $S$ and $N$ are now perfectly anticorrelated: a large signal *must* be accompanied by small noise to land in the window. You selected on a sum and induced a correlation between its independent components. No physics changed; the selection did it.

**A business version.** Among the candidates your company *hired*, interview performance and prior experience are often negatively correlated — you'll hire someone with a weak résumé if they interviewed brilliantly, and vice versa. In the applicant pool the two may be positively correlated. Analyze only hires, and you'll "discover" that interviews predict nothing, or that experience hurts.

Note that **selection into your dataset is conditioning on a collider** whenever the selection depends on both cause and outcome. Any analysis restricted to active customers, completed transactions, or surviving accounts is at risk. This is the same structure as survivorship bias.

### The backdoor criterion

A path from $X$ to $Y$ is *blocked* if it contains a non-collider you conditioned on, or a collider you did **not** condition on (and none of whose descendants you conditioned on). To identify the effect of $X$ on $Y$, find a set $Z$ that blocks every backdoor path (every path with an arrow pointing into $X$) while leaving the directed paths open.

The practical algorithm: **control for confounders, not for mediators or colliders.** Which is which is not a statistical question — it's determined by the DAG, which comes from domain knowledge. The data cannot tell you.

### Simpson's paradox

An association can reverse sign when you stratify. Treatment looks worse overall but better within every severity level, because severe cases were preferentially treated.

The paradox isn't statistical; it's causal. Whether to trust the aggregate or the strata depends on whether severity is a confounder (stratify) or a mediator (don't). **The same numbers support opposite conclusions depending on a graph you can't estimate from them.**

---

## 5. Identification strategies without randomization

Each strategy buys identification with a different assumption. Choose based on which assumption is most defensible in your setting, not on which method is fashionable.

### 5.1 Adjustment (backdoor)

**Assumption:** conditional ignorability — no unmeasured confounding given $Z$ — plus positivity, $0 < P(D=1 \mid Z) < 1$ for all relevant $Z$.

**Methods:**
- **Regression adjustment.** Include $Z$ in an outcome model. Sensitive to functional form.
- **Propensity scores.** Model $e(Z) = P(D=1\mid Z)$, then match, stratify, or weight (IPW: treated units by $1/e(Z)$, controls by $1/(1-e(Z))$). The key result (Rosenbaum & Rubin) is that conditioning on the *scalar* $e(Z)$ suffices — a dimension-reduction that makes high-dimensional adjustment tractable. Note that the weights blow up as $e(Z)$ approaches 0 or 1, which is the same overlap problem below arriving as variance rather than as bias.
- **Doubly robust / AIPW.** Combine an outcome model and a propensity model; consistent if *either* is correctly specified. Strictly better than betting on one.

**Check overlap.** Plot the propensity score distributions by treatment group. If they barely overlap, there's no comparable control for your treated units, and any estimate is extrapolation dressed as inference. Trim to the common support and say that you did — it changes your estimand to something local, which is honest.

**Positivity failures are often structural.** If enterprise customers *always* get a dedicated rep, no adjustment recovers the effect of a rep for enterprise customers. The data contains no counterfactual.

### 5.2 Difference-in-differences

**Setting:** some units get treated at a known time; others don't. Compare the *change* in treated units to the *change* in controls.

**Assumption: parallel trends.** Absent treatment, the two groups' outcomes would have moved in parallel. This permits arbitrary *level* differences — the groups can be entirely different in baseline — but forbids differential *trends*.

**How to interrogate it:** plot the event study — outcomes for both groups over many periods before and after. Pre-treatment leads should be flat and centered on zero. Divergence before treatment falsifies the assumption directly. This plot is not optional; it's the entire evidentiary basis of the method.

**The staggered-adoption trap.** When units adopt at different times, the standard two-way fixed effects regression does *not* estimate a sensible average effect. It implicitly uses already-treated units as controls for later-treated ones, and under heterogeneous or dynamic effects this can produce **negative weights** — the estimate can carry the wrong sign even when every unit's true effect is positive. Use the modern estimators (Callaway–Sant'Anna, Sun–Abraham, or stacked event studies) whenever adoption timing varies. This is recent enough that plenty of internal analyses still get it wrong.

### 5.3 Regression discontinuity

**Setting:** treatment is assigned by a threshold on a continuous running variable — credit score above 700, spend above a tier cutoff, test score above a cutoff.

**Assumption:** everything else varies smoothly through the cutoff. Units just above and just below are comparable, so the discontinuity in outcome at the boundary is the effect. This is as close to a randomized experiment as observational data gets, and the assumption is unusually credible.

**Diagnostics:**
- **Density test.** If units can manipulate their position, they'll bunch on the favorable side. A discontinuity in the *density* of the running variable falsifies the design.
- **Covariate smoothness.** Pre-determined covariates should not jump at the cutoff.

**Bandwidth is a bias-variance trade** — narrow windows are more credible but noisier — which is exactly the hyperparameter problem from Module 5, and there are data-driven selectors for it.

**Limitation:** you identify a *local* effect at the cutoff. It says nothing about units far from it.

### 5.4 Instrumental variables

**Setting:** you can't manipulate $X$, but you can find a $Z$ that shifts $X$ and affects $Y$ *only through* $X$.

Three assumptions:
1. **Relevance** — $Z$ actually moves $X$. Testable.
2. **Exclusion restriction** — $Z$ affects $Y$ through no other channel. **Untestable, and usually the weak point.**
3. **Monotonicity** — $Z$ pushes everyone in the same direction, no defiers.

**The physical intuition:** an instrument is an external drive that couples to the system through exactly one channel. You wiggle $Z$, watch $Y$ respond, and attribute the response to the one path that exists. If the drive couples to a second mode you didn't account for, your inferred coupling constant is contaminated — and nothing in the response tells you that happened.

**Weak instruments are dangerous, not merely inefficient.** When relevance is marginal, the 2SLS estimator is biased toward OLS and its confidence intervals badly undercover. A weak instrument gives you a confidently wrong answer.

The familiar rule of thumb is a first-stage $F > 10$, and it is worth knowing that this bar is now understood to be far too low: subsequent work on the distribution of the first-stage $F$ shows that conventional 2SLS inference requires very much larger values before it is trustworthy. Treat $F$ near 10 as a warning, not a clearance, and prefer inference procedures that are robust to weak identification (Anderson–Rubin confidence sets) when the instrument is not overwhelmingly strong.

**Estimand:** IV recovers LATE — the effect on *compliers*, the subpopulation the instrument actually moves. If compliers are unrepresentative, LATE is not ATE, and the distinction is often material.

### 5.5 Synthetic control

**Setting:** one treated unit (a market, a store, a country), several untreated ones, long pre-period.

Construct a weighted combination of control units that tracks the treated unit's pre-treatment trajectory closely, then use it as the counterfactual. Weights are constrained non-negative and summing to one, which prevents extrapolation beyond the convex hull of the donors.

Best-suited to a single large intervention — a regional launch, a pricing change in one market. Inference is via placebo tests: apply the method to untreated units and see how often you get an effect as large.

---

## 6. Sensitivity analysis: budgeting the systematic

Every non-experimental identification rests on an untestable assumption. Since you cannot verify it, quantify how much violation your conclusion survives.

- **E-value.** How strong would an unmeasured confounder's association with both treatment and outcome have to be to explain away the estimate? If the answer is a risk ratio of 1.3 and you have measured covariates with associations of 2.0, you have learned essentially nothing. If the answer is 8, your finding is fairly robust.
- **Rosenbaum bounds** for matched designs — how much hidden bias in assignment odds would overturn significance.
- **Negative controls.** Find an outcome your treatment *cannot* plausibly affect, and an exposure that cannot plausibly affect your outcome. If your method finds effects there, it's detecting confounding, not causation.
- **Placebo timing.** Run the analysis pretending treatment happened a year earlier. You should find nothing.

This is precisely a systematic uncertainty budget. The statistical error bar is rarely the binding constraint in observational work — the systematic is — and reporting only the former is the field's most common form of overconfidence.

---

## 7. Heterogeneous effects, and where ML actually belongs

Average effects hide the question stakeholders care about: *who* should we treat?

**CATE estimation** targets $\tau(x) = \mathbb{E}[Y(1)-Y(0)\mid X=x]$. Approaches include meta-learners (S-, T-, X-learner) built on any base model, and causal forests, which adapt tree-splitting to maximize heterogeneity in effects rather than in outcomes.

**The connection to the earlier modules is direct.** Standard cross-validation doesn't work here — you never observe $\tau_i$, so there's no label to score against. This forces alternatives: honest splitting (use one subsample to choose splits and another to estimate effects within them), and evaluation via uplift/Qini curves rather than accuracy.

**Double / debiased machine learning** is the cleanest synthesis of this course's material. Use flexible regularized ML to estimate the nuisance functions — the outcome model $\mathbb{E}[Y \mid Z]$ and the propensity $\mathbb{E}[D \mid Z]$ — but plug them into a moment condition constructed to be *orthogonal* to first-order errors in those nuisances, and use **cross-fitting** (estimate nuisances on one fold, the effect on another) to prevent the model's overfitting from leaking into the effect estimate.

Why this matters: naive plug-in of a regularized model gives a biased effect estimate, because regularization bias — the very bias you introduced deliberately in Module 5 — doesn't vanish at the rate needed for valid inference. Orthogonalization makes the estimate insensitive to it to first order; cross-fitting handles the overfitting. It's the same discipline as keeping the scaler inside the CV fold, applied to a harder problem.

---

## 8. Failure modes

| Symptom | What's likely going on |
|---|---|
| "Users of feature X churn less" | Reverse causation or confounding by engagement |
| Effect shrinks dramatically when a control is added | The added variable is a confounder — or a mediator, and you just adjusted away the effect |
| Effect appears only after adding many controls | Possible collider conditioning; check the DAG |
| Matched groups look balanced, effect is huge | Balance on observables says nothing about unobservables; run a sensitivity analysis |
| DiD estimate with staggered adoption | Likely a two-way-fixed-effects artifact; use a modern estimator |
| IV result differs wildly from OLS | Check first-stage $F$; weak instrument, or the exclusion restriction fails |
| Analysis restricted to active/surviving units | Collider conditioning by selection |
| Aggregate and subgroup results disagree in sign | Simpson's paradox; resolve with the DAG, not with more data |
| Very precise estimate from observational data | Statistical error isn't your binding constraint; where's the systematic? |

---

## 9. Practical recipe

1. **State the decision.** What would we do differently depending on the answer? If nothing, stop.
2. **Name the estimand.** ATE, ATT, or CATE — for which population, over what horizon.
3. **Draw the DAG** before looking at the data, with domain experts in the room. The absent arrows are the assumptions.
4. **Ask whether you can randomize.** Seriously, and more than once. A small clean experiment beats a large dirty observational study.
5. **Choose an identification strategy** by which assumption is most defensible here — not by method familiarity.
6. **Classify every covariate** as confounder, mediator, collider, or irrelevant. Control for the first group only.
7. **Check the design's own diagnostics** — overlap, pre-trends, density at the cutoff, first-stage strength.
8. **Estimate**, using cross-fitting if ML is anywhere in the pipeline.
9. **Run sensitivity analysis and negative controls.** Report how fragile the conclusion is.
10. **Write the assumptions in the summary**, not the appendix. They are the result as much as the point estimate.

---

## 10. Further reading

- Cunningham, *Causal Inference: The Mixtape* — the best applied introduction; free online, code included.
- Angrist & Pischke, *Mostly Harmless Econometrics* — the design-based tradition, IV/DiD/RDD done properly.
- Hernán & Robins, *Causal Inference: What If* — free; the rigorous potential-outcomes treatment, with the clearest exposition of positivity and of colliders.
- Pearl & Mackenzie, *The Book of Why* — the graphical intuition, accessible.
- Chernozhukov et al. (2018), "Double/debiased machine learning" — the orthogonalization and cross-fitting result behind §7.
- Callaway & Sant'Anna (2021) and Goodman-Bacon (2021) — what goes wrong with staggered DiD and how to fix it.
- VanderWeele & Ding (2017), "Sensitivity analysis: introducing the E-value."
