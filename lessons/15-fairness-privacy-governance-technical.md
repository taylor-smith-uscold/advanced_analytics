# Should We Ship This? Fairness, Privacy, and Governance

*Module 15 — technical register. For readers who want the impossibility results stated precisely.*

> **Required reading —** Barocas, Hardt & Narayanan, *Fairness and Machine Learning*, ch. 2–3 · [PDF](advanced_analytics_readings/15_barocas_hardt_narayanan_fairness_and_ml.pdf)
>
> **Exercise templates —** Mitchell et al., *Model Cards for Model Reporting* · [PDF](advanced_analytics_readings/15_mitchell_model_cards.pdf) — and Gebru et al., *Datasheets for Datasets* · [PDF](advanced_analytics_readings/15_gebru_datasheets_for_datasets.pdf)

---

## 0. The one-paragraph version

Aggregate performance can be excellent while performance in a subpopulation is unusable, and no metric in Module 7 will reveal this unless you disaggregate. That much is a straightforward measurement obligation. The harder material is that **the common fairness criteria are mathematically incompatible**: when base rates differ between groups, a model cannot simultaneously satisfy calibration within groups and equal false-positive and false-negative rates across them, except in degenerate cases. This is a theorem, not an engineering shortfall, which means the choice among criteria is a normative decision that belongs to the business and its legal counsel, informed by the analyst rather than made by the analyst. Alongside this sit two practical obligations: **privacy**, where the operative fact is that anonymization by removing identifiers does not work, and **governance**, where the operative fact is that a model nobody documented cannot be reviewed, debugged, or defended.

---

## 1. Disaggregate before anything else

The minimum obligation, and the one that catches most real problems.

Report your Module 7 metrics broken down by every subgroup you can define: demographic where lawful and available, and also by tenure, geography, channel, device, product line, and data-completeness status. Report **per-group sample sizes and confidence intervals** alongside — small groups will look extreme for the reasons Module 9 explains, and partial pooling is the appropriate stabilizer.

Common patterns worth looking for specifically:

- **Fewer training examples → worse performance.** The most frequent mechanism by far, and it compounds: a group underserved historically generates less data, so the model serves it worse, so it stays underserved.
- **Different base rates → different calibration.** A model calibrated on the pooled population is typically miscalibrated within groups.
- **Feature availability differs.** If a predictive feature is systematically missing for one group, effective model quality differs even with identical code.
- **Proxy features.** Postcode, device type, and browsing patterns encode demographics with substantial fidelity. **Removing a protected attribute does not remove its influence** — it removes your ability to measure it, which is strictly worse. "Fairness through unawareness" is not a defensible strategy.

Also check **coverage of prediction intervals by group** (Module 11, §6) and **abstention/error rates by group**, not just point accuracy.

---

## 2. The incompatibility result

Three natural criteria:

| Criterion | Formal statement | Plain meaning |
|---|---|---|
| **Demographic parity** | $P(\hat Y = 1 \mid A) $ equal across groups | Equal selection rates |
| **Equalized odds** | $P(\hat Y=1 \mid Y=y, A)$ equal across groups for $y \in \{0,1\}$ | Equal error rates both ways |
| **Calibration within groups** | $P(Y=1\mid \hat p = p, A)$ equal across groups | A score of 0.7 means the same thing in every group |

**Kleinberg, Mullainathan & Raghavan (2016) and Chouldechova (2017):** if base rates $P(Y=1\mid A)$ differ between groups, no classifier can satisfy calibration and equalized odds simultaneously, except when prediction is perfect or the base rates are equal.

The mechanism is direct. Under differing prevalence, calibrated scores imply different score distributions per group, which imply different error-rate trade-offs at any threshold. There is no clever architecture that escapes it; it's a constraint on the joint distribution.

**Demographic parity and equalized odds also conflict** whenever base rates differ: equal selection rates then require unequal error rates, by construction.

### Consequences for practice

1. **You must choose.** Optimizing all three is not an option, and any vendor claiming to deliver it is either restricting to equal-base-rate settings or misdescribing what they do.
2. **The choice is normative, not technical.** Which criterion matters depends on what the decision does, who bears each error, and what the law requires. Calibration matters most when the score is used as an estimate of risk by downstream decision-makers. Equalized odds matters most when errors impose direct harm on individuals. Demographic parity matters most where equal access is itself the objective.
3. **The analyst's role is to quantify the trade-off, not to resolve it.** Produce the frontier — how much of each criterion is achievable jointly, and what each costs in accuracy — and bring it to the people accountable for the decision.
4. **Base-rate differences are frequently measurement artifacts.** If "arrests" stands in for "offenses," or "diagnosis" for "illness," the differing base rate may reflect differential detection rather than differential occurrence. That is a Module 1 construct-validity problem, and it can matter more than any post-hoc adjustment.

---

## 3. Intervention points

| Stage | Approach | Trade-off |
|---|---|---|
| **Pre-processing** | Reweighting, resampling, representation learning | Model-agnostic; limited control over final behavior |
| **In-processing** | Fairness constraints or regularizers in the objective | Most direct control; requires a custom training path |
| **Post-processing** | Group-specific thresholds | Simple, effective, often the most transparent — **and may constitute disparate treatment; take legal advice** |

That last caveat is substantive. In several jurisdictions, explicitly using a protected attribute in the decision rule is unlawful even when the intent is to reduce disparity. This is a live area with genuine legal disagreement and it varies by jurisdiction and domain. **The engineering options and the legal options are different sets, and the intersection is what you can actually ship.**

Note also the distinction between **disparate treatment** (differential treatment because of a protected attribute) and **disparate impact** (a neutral rule with differential effect). Most ML fairness concerns are of the second kind, where the standard analysis asks whether the practice is justified by business necessity and whether a less discriminatory alternative exists — which makes documenting your search over alternatives legally relevant, not just good practice.

---

## 4. Privacy

**Identifier removal is not anonymization.** Sweeney's result — that ZIP code, birth date, and sex together uniquely identify the large majority of the US population — is the canonical demonstration. (Her original estimate was 87%; later replications on other census data put it nearer two-thirds, which does not change the conclusion.) Re-identification from behavioral data — the Netflix Prize ratings, mobility traces, browsing histories — is easier still, because rich per-person records are close to unique by construction. Assume any such dataset is re-identifiable.

| Technique | Guarantee | Limitation |
|---|---|---|
| **k-anonymity** | Each record indistinguishable from $k-1$ others on quasi-identifiers | Vulnerable to homogeneity and background-knowledge attacks; $\ell$-diversity and $t$-closeness patch specific holes |
| **Differential privacy** | Bounded influence of any single record on the output, quantified by $\varepsilon$ | Real accuracy cost; budget composes across queries and must be tracked |
| **Aggregation with minimum cell sizes** | Practical, widely used | Vulnerable to differencing attacks across overlapping releases |
| **Synthetic data** | Convenient for sharing | **Not private by default** — a generator can memorize; needs DP guarantees to be trustworthy |
| **Federated learning** | Raw data stays local | Updates can leak; combine with DP |

**Models memorize.** Large models can reproduce training examples verbatim, and membership-inference attacks can determine whether a specific record was in the training set. If your model is externally queryable and was trained on sensitive data, this is a real exposure, not a theoretical one.

Practical baseline: minimize collection, set retention limits, restrict access by role, avoid sensitive attributes as features unless justified, and check what your model outputs can reveal about individuals.

---

## 5. Governance

Governance exists because a model nobody documented cannot be reviewed, debugged, handed over, or defended — and because in regulated domains it is a legal requirement (SR 11-7 in US banking, the EU AI Act's obligations for high-risk systems, sector regulators elsewhere).

### Model cards

A model card should let a competent stranger evaluate fitness for their purpose:

- **Intended use**, and explicitly **out-of-scope uses**
- **Training data**: sources, period, size, known gaps and biases
- **Performance**: overall *and disaggregated*, with intervals
- **Fairness assessment**: which criterion was chosen, why, and what it cost
- **Limitations**: where it's known to fail
- **Ethical considerations and mitigations**
- **Maintenance**: owner, retrain cadence, monitoring plan, escalation path

### Tiering

Not every model warrants the same scrutiny. Tier by consequence:

| Tier | Characteristics | Requirements |
|---|---|---|
| **High** | Affects individuals' access to credit, employment, healthcare, housing; regulated; hard to reverse | Independent validation, documented fairness assessment, legal review, human appeal route, ongoing monitoring |
| **Medium** | Material business impact, limited individual effect | Peer review, documentation, monitoring |
| **Low** | Internal, reversible, low stakes | Documentation and basic monitoring |

Over-governing low-tier models produces theatre and erodes compliance with the parts that matter.

### Human oversight that is real

"Human in the loop" is often nominal — a reviewer who approves 99.7% of recommendations provides no oversight, and automation bias makes this the default outcome unless designed against.

Meaningful oversight requires: reviewers who see the *reasons* (Module 13), who have the information and authority to disagree, whose override rate is monitored (Module 14, §4), and who face no throughput incentive that makes disagreement costly.

**A contestability route matters independently.** People affected by an automated decision should be able to see the basis for it and challenge it, with a path that reaches a human who can actually change the outcome.

---

## 6. Failure modes

| Symptom | Likely cause |
|---|---|
| Strong aggregate metrics, complaints from one segment | Never disaggregated |
| Removed the protected attribute, disparity unchanged | Proxies; unawareness doesn't work |
| Fairness metrics conflict and can't all be fixed | Expected — that's the theorem |
| Subgroup metrics wildly unstable | Small samples; use intervals and partial pooling (Module 9) |
| Disparity appears only after deployment | Feedback loop (Module 14, §5) |
| "Anonymized" data re-identified | Identifier removal isn't anonymization |
| Human reviewers approve nearly everything | Automation bias; oversight is nominal |
| No one can explain a decision made 8 months ago | No versioning of model, data, and code |
| Model used for a purpose it wasn't validated for | Intended use not documented or not enforced |

---

## 7. Practical recipe

1. **Disaggregate every metric** by every subgroup you can lawfully construct. Do this from the first evaluation, not at review time.
2. **Report per-group intervals and sample sizes**; stabilize small groups with partial pooling.
3. **Check for proxies** — model the protected attribute from your features and see how well it's predicted. High predictability means the attribute is effectively present.
4. **Present the fairness trade-off as a frontier**, with the accuracy cost of each option, and bring it to the accountable decision-makers with legal counsel present.
5. **Interrogate the label itself** for measurement bias before adjusting the model.
6. **Assess privacy exposure**: what could be inferred about an individual from your model's outputs, and from any data you release?
7. **Tier the model by consequence** and apply proportionate scrutiny.
8. **Write the model card** during development, not at review — a card written afterward documents what you remember, not what you did.
9. **Version model, data, code, and decisions** so any past output is reproducible.
10. **Design oversight that can actually bite**, and monitor the override rate as evidence that it does.

---

## 8. Further reading

- Barocas, Hardt & Narayanan, *Fairness and Machine Learning* — free online, the standard reference; chapter 3 covers the impossibility results carefully.
- Kleinberg, Mullainathan & Raghavan (2016) and Chouldechova (2017) — the two independent formulations of §2.
- Mitchell et al. (2019), "Model cards for model reporting" — the template in §5.
- Gebru et al. (2021), "Datasheets for datasets" — the equivalent for training data.
- Dwork & Roth, *The Algorithmic Foundations of Differential Privacy* — the rigorous treatment of §4.
- Sweeney (2000) on re-identification — short, and the fastest way to internalize why identifier removal fails.
- Selbst et al. (2019), "Fairness and abstraction in sociotechnical systems" — on the limits of treating this as a modeling problem.
