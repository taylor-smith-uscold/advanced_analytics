# Should We Ship This? A Plain-Language Guide to Fairness, Privacy, and Governance

*Module 15 — plain-language register.*

---

## The short version

A model can score 94% overall and be nearly useless for one group of your customers. Nothing in Module 7 will show you this unless you deliberately break the numbers down.

That part is straightforward — measure it and you'll find it. The harder part is what to do next, and here there's a genuinely surprising result:

> **The common definitions of "fair" are mathematically incompatible.** When two groups have different underlying rates of the thing you're predicting, you cannot satisfy all of them at once. This is proven, not a limitation of current technology.

Which means the choice among them is a **business and legal decision**, not a technical one. Your job is to make the trade-off visible and quantified, and to bring it to the people who own the decision — not to resolve it at your desk.

Alongside that sit two practical realities: **removing names and IDs does not make data anonymous**, and **a model nobody documented can't be reviewed, fixed, or defended.**

---

## Part 1: Break down every number

The single most valuable thing in this module, and it's not complicated: **report your metrics separately for each group**, not just overall.

Groups worth checking: demographics where you lawfully can, plus tenure, region, channel, device, product line, and — often revealing — whether the customer has complete data.

**Include how many people are in each group and the uncertainty range.** Small groups will look extreme for the reasons in Module 9, and you'll chase noise if you don't account for that.

### What you'll usually find, and why

**Less data means worse performance.** The most common mechanism by far, and it feeds itself: a group you've historically served less generates less data, so the model serves them worse, so they stay underserved.

**Different underlying rates mean different accuracy.** If one group genuinely has different characteristics, a model tuned on the overall population will fit them less well.

**Missing information.** If a useful field is systematically blank for one group, they get worse predictions from identical code.

### The move that doesn't work

**Removing the sensitive attribute from your model does not remove its influence.**

Postcode, device type, browsing patterns, purchase history, and name all carry demographic information. Drop "gender" and the model reconstructs it from the rest with substantial accuracy.

What you've actually done is remove your ability to *measure* whether the model treats groups differently. That's strictly worse — the disparity persists and you can no longer see it.

**Test this directly:** try to predict the sensitive attribute from your other features. If you can do it well, that attribute is effectively still in your model.

---

## Part 2: The result that surprises people

Three reasonable-sounding definitions of fairness:

| Definition | What it asks for |
|---|---|
| **Equal selection rates** | Approve the same percentage of each group |
| **Equal error rates** | Same false-alarm rate and same miss rate for each group |
| **Scores mean the same thing** | A "70% risk" means 70% for everyone |

Each is defensible. Each has been proposed as *the* definition.

**They cannot all be satisfied at once** — not by a better algorithm, not by more data, not by anything — whenever the two groups have different underlying rates of the outcome. It's a proven mathematical result from 2016 and 2017.

The reason, roughly: if scores mean the same thing in both groups, and one group genuinely has more of the outcome, then that group will have more people scoring high, which forces the error rates to differ. You can shift which one is unequal. You cannot make them all equal.

This came up publicly in the debate over the COMPAS criminal risk tool. One side showed the scores were equally accurate across racial groups; the other showed the error rates differed substantially. **Both were correct.** They were measuring different definitions, and the theorem says both could not have been satisfied.

### What this means for you

**You have to choose, and the choice isn't technical.** Which definition matters depends on what your decision does and who bears each kind of mistake:

- If a score gets handed to a human who acts on it as a risk estimate, "scores mean the same thing" matters most — otherwise you're feeding them misleading numbers.
- If a wrong decision directly harms someone, equal error rates matter most.
- If equal access is the actual goal, equal selection rates matter most.

**Your job is to show the trade-off, not to pick.** Produce the options — here's what each definition costs in accuracy, and in the other definitions — and bring it to the people accountable, with legal counsel in the room.

If a vendor tells you their product is fair by all definitions simultaneously, they're either working in a special case or misdescribing what they do.

### One thing worth checking first

**Is the difference in underlying rates real, or an artifact of how you measured it?**

If your label is "was arrested" standing in for "committed an offense," or "was diagnosed" standing in for "was ill," the difference in rates might reflect differences in *detection* rather than differences in *occurrence*.

That's a Module 1 problem — your metric isn't measuring what you think — and fixing it can matter more than any adjustment to the model.

---

## Part 3: What you can actually do

Three places to intervene:

**Before training** — reweight or resample your data so underrepresented groups carry more influence. Simple, works with any model, gives you limited control over the final result.

**During training** — build fairness constraints into what the model optimizes. Most direct control, requires more engineering.

**After training** — use different score thresholds for different groups. Simple, effective, and transparent about what you're doing.

**Important caveat on that last one:** using a protected attribute explicitly in your decision rule **may be illegal**, in several jurisdictions, even when your intent is to reduce disparity. This is genuinely contested legal territory and it varies by country and industry.

**Talk to legal before implementing any of these.** The set of things that work technically and the set of things you're allowed to do are different, and only the overlap is shippable.

One distinction that helps in those conversations: **treating people differently because of a protected characteristic** is a different legal question from **a neutral rule that happens to affect groups differently.** Most ML fairness concerns are the second kind, where the question becomes whether the practice is justified and whether a less harmful alternative exists. Which means **documenting the alternatives you tried is legally useful**, not just good hygiene.

---

## Part 4: Privacy

### Removing names doesn't anonymize data

The classic demonstration: **postcode, date of birth, and sex uniquely identify most people.** Strip every name and ID from your dataset and a substantial majority of individuals are still identifiable by anyone with a second dataset to cross-reference.

Behavioral data is worse. A handful of location pings, or a few movie ratings, is often enough.

**Assume any detailed per-person dataset is re-identifiable.** Plan accordingly rather than relying on identifier removal.

### What actually helps

- **Aggregate, with minimum group sizes.** Common and practical. Watch out for releasing overlapping cuts — two reports that differ by one person reveal that person.
- **Differential privacy.** Adds carefully calibrated noise with a mathematical guarantee about what can be learned about any individual. Real accuracy cost, real protection. The serious option when you need one.
- **Synthetic data.** Convenient for sharing — but **not automatically private.** A generator trained on your data can reproduce real records. Don't assume "synthetic" means safe.

### Models remember things

Large models can reproduce training examples. It's also often possible to determine whether a *specific person* was in the training data, just by querying the model.

If your model is accessible externally and was trained on sensitive information, this is a real exposure. Worth an explicit assessment.

**Sensible baseline:** collect less, delete on a schedule, restrict access by role, don't use sensitive fields as inputs without a specific justification, and check what your model's outputs could reveal.

---

## Part 5: Documentation and oversight

### Write a model card

The test: **could a competent stranger read this and decide whether to use the model for their purpose?**

Cover: what it's for and what it's *not* for; what data trained it and what's missing from that data; performance overall **and by group**; which fairness definition you chose and why; where it's known to fail; who owns it; how often it retrains; what's monitored.

**Write it during development, not at review time.** A card written afterward documents what you remember, not what you did.

### Scale scrutiny to consequence

Not every model needs the full treatment:

| Stakes | Examples | What's needed |
|---|---|---|
| **High** | Credit, hiring, healthcare, housing | Independent review, fairness assessment, legal sign-off, an appeals route, ongoing monitoring |
| **Medium** | Meaningful business impact, limited effect on individuals | Peer review, documentation, monitoring |
| **Low** | Internal, easily reversed | Documentation and basic monitoring |

Applying heavy governance to low-stakes models creates paperwork nobody reads and undermines compliance where it matters.

### Make human oversight real

"A human reviews it" is often theatre. If your reviewer approves 99.7% of recommendations, they aren't providing oversight — they're providing a signature.

People defer to automated systems by default. Real oversight has to be designed for:

- Reviewers see **why** the model decided what it did (Module 13)
- They have the information and standing to disagree
- **Their override rate is tracked** — if it drops to near zero, oversight has stopped happening
- They aren't under throughput pressure that makes disagreeing expensive

**And people affected by a decision need a way to challenge it** — one that reaches a human who can actually change the outcome.

---

## Part 6: Warning signs

| What you see | What's probably happening |
|---|---|
| Great overall numbers, complaints from one segment | You never broke the numbers down |
| Removed the sensitive field, nothing changed | Proxies — it's still in there |
| Fairness metrics conflict and won't reconcile | Expected. That's the theorem |
| Subgroup numbers bouncing around | Small samples — use ranges (Module 9) |
| Disparity showed up only after launch | Feedback loop (Module 14) |
| "Anonymized" data got re-identified | Removing IDs isn't anonymization |
| Reviewers approve nearly everything | Oversight in name only |
| Nobody can explain a decision from last year | No versioning |
| Model being used for something it wasn't built for | Intended use wasn't documented |

---

## Putting it all together

**The recipe:**

1. **Break down every metric by every group you can define.** From the first evaluation, not at review time.
2. **Show sample sizes and ranges** for each group.
3. **Test for proxies** — try predicting the sensitive attribute from your other features.
4. **Present the fairness trade-off as options with costs**, and bring it to the accountable people with legal in the room.
5. **Question the label** before adjusting the model — is the difference real or a measurement artifact?
6. **Assess privacy exposure** — what could someone learn about an individual from your outputs?
7. **Match your governance to the stakes.**
8. **Write the model card while building.**
9. **Version everything** so any past decision can be reconstructed.
10. **Design oversight that can actually change outcomes**, and track override rates to prove it does.

**Three things to remember if you remember nothing else:**

- **A good overall number can hide a bad one.** Disaggregate everything, always. It's the highest-value habit in this module and it costs almost nothing.
- **The fairness definitions genuinely can't all be satisfied.** Don't promise otherwise, and don't make the choice alone — surface it as a business decision with quantified costs.
- **Removing identifiers isn't anonymizing.** Postcode, birth date, and sex are enough to pick most people out of a crowd.

---

## Where to go next

- **The reference:** *Fairness and Machine Learning* by Barocas, Hardt & Narayanan — free online, and the clearest explanation of the impossibility result.
- **Practical templates:** "Model Cards for Model Reporting" (Mitchell et al.) and "Datasheets for Datasets" (Gebru et al.) — both short, both give you a template you can adopt this week.
- **Tools:** Microsoft's `Fairlearn` and IBM's `AIF360` implement the disaggregated metrics and mitigation methods discussed here.
- **On the limits of technical fixes:** "Fairness and Abstraction in Sociotechnical Systems" (Selbst et al.) — a useful corrective to the idea that this is a modeling problem.
