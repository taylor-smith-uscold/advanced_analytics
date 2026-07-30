# Choosing the Observable: Problem Framing and Metric Design

*Module 1 — technical register. For readers comfortable with estimands, loss functions, and expected utility.*

---

## 0. The one-paragraph version

An analysis is an instrument, and like any instrument it measures what it was built to measure rather than what you wanted. The framing stage is where you choose the observable, and it is where most projects fail — silently, before any modeling error can be detected downstream. Three things have to be pinned down: the **decision** the analysis serves, the **estimand** (the precise quantity that would inform that decision, for which population, over what horizon), and the **measurement** (an observable proxy for the estimand, plus an honest account of the gap between them). Every subsequent module — validation, evaluation, monitoring — is machinery for estimating the estimand accurately. None of it can rescue a badly chosen one. A perfectly validated model of the wrong quantity is worse than no model, because it carries the authority of rigor.

---

## 1. The instrument analogy, taken literally

You never measure the quantity of interest. You measure a detector response and infer the quantity through a chain of assumptions: response function, efficiency, acceptance, background. If any link is mischaracterized, the number is wrong in a way that no amount of statistics will reveal, because the statistical error bar describes the precision of the wrong thing.

Analytics has the same structure and usually less discipline about it:

| Physics | Analytics |
|---|---|
| Quantity of interest | Estimand ("effect of the discount on lifetime value") |
| Observable | Metric ("30-day revenue per assigned user") |
| Detector response | Instrumentation, logging, event definitions |
| Acceptance / efficiency | Which users are eligible and observable |
| Background | Confounding, seasonality, concurrent launches |
| Systematic uncertainty | The proxy gap, plus everything above |

The framing stage is where you write down this chain. If you can't, you don't yet have an analysis; you have a request.

---

## 2. Start from the decision, not the data

The first question is not "what data do we have" but:

> **What action would change depending on the answer, and who takes it?**

This is a value-of-information question. If no action changes for any plausible answer, the expected value of the analysis is zero regardless of its quality, and you should say so rather than build it.

Concretely, force the requester to complete this table before you start:

| Field | Example |
|---|---|
| Decision | Whether to extend the free trial from 14 to 30 days |
| Decision-maker | Growth PM, with pricing sign-off |
| Options | 14 days (status quo), 30 days, 21 days |
| Deadline | Roadmap lock, six weeks |
| What would make us choose 30 | Net revenue per signup up ≥2% with no support-cost regression |
| What would make us keep 14 | Anything else |
| Reversibility | Reversible, but with a 60-day contractual tail |

Two things fall out of this immediately. First, the **decision threshold** ("≥2%") determines the precision you need, which determines the sample size and the method — this is the practical-significance boundary that Module 3 requires and that Module 7 needs for cost-based thresholds. Second, the **reversibility** determines how much evidence is warranted. A reversible, cheap decision deserves a fast, rough answer. An irreversible one deserves the full apparatus.

**Asymmetry of errors is a framing input, not an analysis detail.** Establish $C_{FP}$ and $C_{FN}$ here, in business units, so Module 7 can set thresholds and Module 3 can set the MDE.

---

## 3. Specifying the estimand

An estimand is a fully specified quantity: *what*, *for whom*, *when*, *compared to what*. Ambiguity in any slot produces two analysts computing different numbers and both being right.

The **PICOT** framing from clinical research transfers cleanly:

- **Population** — inclusion and exclusion criteria. New signups only? Excluding enterprise? Excluding users who churned before exposure?
- **Intervention / exposure** — precisely what is done, at what dose.
- **Comparator** — versus what alternative? "Versus nothing" is rarely well-defined; the status quo is a specific alternative with its own dynamics.
- **Outcome** — the target, defined operationally.
- **Time** — measurement horizon and follow-up window.

### Label definition is where leakage is born

For supervised problems the estimand becomes a label, and label construction is a design decision with three recurring traps.

**Horizon.** "Churn" is not a label; "no active session in the 30 days following day 60 after signup" is. The horizon determines how long you must wait before a label exists, which determines how stale your training data is, which constrains everything downstream.

**Censoring.** Users who signed up three weeks ago cannot yet have a 30-day churn label. Dropping them selects on tenure and biases the training set toward older cohorts. This is a survival-analysis problem being flattened into classification, and if time-to-event matters, use the right tool (see the optional survival module) rather than binarizing.

**Temporal leakage in the label window.** If the feature window and label window overlap, features encode the outcome. The rule: **all features must be computable strictly before the label window opens.** Write the timeline down as a diagram before writing SQL. Most leakage found in Module 6 was created here.

### The population you can observe is not the population you care about

You typically want the effect on *everyone*, but observe only those who reached some funnel stage. Restricting to observed users is conditioning on a post-treatment variable — collider structure from Module 2 — and reintroduces the bias you were trying to avoid. Define the population at the earliest point of randomization or eligibility, and treat non-observation as an outcome rather than a filter.

---

## 4. Metrics: validity before precision

The metric is the observable that stands in for the estimand. The gap between them is a **construct validity** problem, and it's a systematic, not a statistical, one — it doesn't shrink with sample size.

Four questions for any candidate metric:

1. **Validity** — does it actually measure the construct? "Engagement" measured by session count rewards a confusing UI that requires more sessions per task.
2. **Sensitivity** — can it move detectably within the decision timeframe? Lifetime value is the right construct and a hopeless metric for a two-week test; its variance is enormous and its horizon is years.
3. **Directionality** — is more unambiguously better? Support contacts down could mean a better product or a hidden help page.
4. **Gameability** — what's the cheapest way to move it without creating value? Assume someone will find that path, because incentives eventually locate it.

### Goodhart's law is the default, not the exception

> When a measure becomes a target, it ceases to be a good measure.

The mechanism is precise: any proxy correlates with the construct across the *historical* range of behavior. Optimization pushes you outside that range, into the region where the correlation was never established — and where the cheapest way to move the proxy is precisely the way that doesn't move the construct.

The structural defenses:

- **A hierarchy, not a single number.** One primary decision metric, secondaries for mechanism, guardrails that must not degrade (Module 3, §2).
- **Guardrails are the main protection.** They bound the space of cheap exploits. Latency, complaint rate, refund rate, unsubscribe rate.
- **Long-horizon holdouts.** Reserve a small group that receives no launches for a quarter, to measure cumulative effect against the long-run construct.
- **Periodic revalidation.** Re-check that the proxy still correlates with the construct. It decays.

### Composite metrics (OEC)

Combining several metrics into one decision criterion, $\mathrm{OEC} = \sum_k w_k \tilde m_k$ over standardized components, has one real virtue — it forces the trade-off to be stated in advance rather than argued after results arrive. Its cost is interpretability: a moved OEC needs decomposition to be actionable. Set the weights from the business cost model in §2, not by intuition, and never adjust them after seeing results.

---

## 5. When not to build a model

A model is justified when a decision is (a) repeated, (b) made under uncertainty that data can reduce, and (c) actionable at the point of prediction. Failing any one of those, prefer something simpler.

| Situation | Better than a model |
|---|---|
| One-time decision | Direct analysis, or a well-run experiment |
| No action available at prediction time | Nothing — the prediction is inert |
| A simple rule captures most of the value | The rule, monitored |
| The real problem is measurement | Fix instrumentation first |
| Stakeholder wants justification for a decision already taken | Say so, out loud |
| Question is causal, data is observational, no design available | Module 2's toolkit, with stated assumptions — not a predictive model |

**Always establish the trivial baseline in this stage**, not at evaluation time: majority class, last value, current heuristic, human performance. It sets the bar the project must clear to be worth its maintenance cost, and stating it early prevents the familiar end-of-project discovery that a boosted ensemble ties the existing rule.

---

## 6. Actionability constraints are design constraints

Elicit these before modeling, because each one eliminates methods:

- **Latency budget** — real-time scoring rules out heavy feature pipelines.
- **Feature availability at inference** — a feature present in the warehouse but not in the serving path is unusable. This is training-serving skew (Module 14) and it is created here.
- **Explainability requirements** — regulated decisions may mandate reason codes, constraining you toward monotone or additive models (Module 13).
- **Capacity** — if the sales team can call 200 leads a week, you need a good *ranking* at the top of the list, and precision@200 is your metric. Global AUC is not.
- **Update cadence** — how stale can the model be before the decision degrades?

The capacity point deserves emphasis: it converts a classification problem into a ranking problem and changes the evaluation metric entirely. Discovering it after modeling wastes the cycle.

---

## 7. Failure modes

| Symptom | Framing error upstream |
|---|---|
| "Great model, nobody uses it" | No decision identified, or no action available at prediction time |
| Two analysts, two different numbers, same data | Estimand underspecified — population, horizon, or comparator |
| Model works offline, fails in production | Features unavailable at inference; framing ignored the serving path |
| Metric improves, business doesn't | Proxy gap; Goodhart |
| Impossible to hit the required precision | Estimand chosen without a power calculation |
| Test set full of impossible-to-label rows | Censoring not handled in the label definition |
| Leakage found late in validation | Feature and label windows overlap by construction |
| Stakeholders dispute the result's meaning | Decision rule not agreed before the analysis |

---

## 8. Practical recipe

1. **Name the decision, the decision-maker, and the alternatives.**
2. **State the decision threshold** in business units, and the cost of each error type.
3. **Write the estimand** — population, exposure, comparator, outcome, horizon.
4. **Draw the timeline** — feature window, label window, decision point. Verify no overlap.
5. **Choose the primary metric**, plus secondaries and guardrails. Interrogate validity, sensitivity, directionality, gameability.
6. **State the trivial baseline** and the value of beating it.
7. **List the deployment constraints** — latency, feature availability, capacity, explainability, cadence.
8. **Decide whether a model is warranted at all.** Write down what you'd do instead.
9. **Circulate the framing document and get sign-off before analysis.** Disagreements found here are cheap; found after results, they are political.

---

## 9. Further reading

- Kohavi, Tang & Xu, *Trustworthy Online Controlled Experiments*, ch. 6–7 — metric design, OECs, and guardrails from large-scale practice.
- Manheim & Garrabrant (2018), "Categorizing variants of Goodhart's Law" — a precise taxonomy of the ways proxies fail under optimization.
- Jacobs & Wallach (2021), "Measurement and fairness" — construct validity applied to ML measurement; the clearest treatment of the proxy gap.
- Breck, Cai, Nielsen, Salib & Sculley (2017), "The ML Test Score" — a production-readiness rubric that starts from framing and deployment constraints.
- Hubbard, *How to Measure Anything* — value of information and decision-first framing, for the stakeholder conversation.
