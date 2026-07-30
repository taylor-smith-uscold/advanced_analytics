# Did Anyone Act On It? Communicating Analysis

*Module 16 — technical register. For readers who would rather be precise than persuasive, and need to be both.*

---

## 0. The one-paragraph version

An analysis that doesn't change a decision has the same value as one that was never run, and the most common cause of that failure is not analytical error but communication structure. Three specific technical problems recur. **Uncertainty gets stripped**, because intervals are inconvenient in a headline — so the framing has to make the interval load-bearing rather than decorative. **Precision gets misstated**, because software prints ten digits and nobody rounds to what the interval supports. **Assumptions get relegated**, because the appendix is where inconvenient conditions go — and for observational work the assumptions *are* the result, since the statistical interval is rarely the dominant uncertainty (Module 11, §7). The organizing principle is inversion: state the conclusion and its consequence first, then support it. Analysts trained to build arguments forward, from method to result, are trained in exactly the wrong order for an audience that stops reading after the third paragraph.

---

## 1. Invert the structure

Your working order is: question → data → method → validation → result → implication. Your reader's order is the reverse, and they may not reach the end.

**Bottom line up front.** Open with the conclusion and what it implies for the decision, then support it in descending order of importance. This is the standard structure for briefing documents in every field where decisions are made under time pressure, and it exists because readers stop early.

```
1. What we found, and what we recommend               (2 sentences)
2. How confident we are, and what would change it     (2 sentences)
3. The evidence                                        (1 page)
4. Method, assumptions, and robustness checks          (as long as needed)
5. Appendix                                            (everything)
```

A reader who stops after line 1 should still have the correct conclusion. A reader who stops after line 2 should know how much to rely on it.

**The result is not the finding.** "Retention is 4 points higher in the treatment group" is a result. "We should roll out to all regions; the expected annual value is £2.1M and the main risk is that the effect fades after novelty" is a finding. The translation from one to the other is your job, not the reader's — and if you don't do it, someone less qualified will.

---

## 2. Communicating uncertainty without losing the audience

### The failure mode in both directions

Overstate certainty and you'll eventually be wrong in a way that costs your credibility permanently. Hedge everything and you'll be routed around — the decision gets made without you, on worse information.

The resolution is to make the uncertainty **decision-relevant** rather than decorative:

> ✗ "The effect is 3.2% (95% CI: −0.4% to 6.8%), though there is considerable uncertainty and further research is warranted."
>
> ✓ "Best estimate is a 3.2% lift. The data is consistent with anything from slightly negative to nearly 7%. Since we ship at anything above 1%, the honest position is that we don't yet know whether this clears the bar — two more weeks of data would resolve it."

Same interval. The second version tells the reader what to *do* with it.

### Frequencies over probabilities

People reason more reliably about natural frequencies than about percentages or conditional probabilities. This is a robust psychological finding with a direct application:

> ✗ "The test has 90% sensitivity and a 5% false positive rate, with 1% prevalence."
>
> ✓ "Out of 1,000 people, 10 have it. We'll catch 9 of them. We'll also flag 50 healthy people. So of about 59 flagged, only 9 are real — roughly one in seven."

The second version prevents the base-rate error rather than merely providing the inputs for someone else to make it. Use it whenever you present precision, recall, or any conditional probability to a general audience.

### Round to what you can support

If your interval is ±4 points, report "about 62%," not "61.7431%." Reporting digits beyond your precision is a false claim about the quality of your evidence, and technically literate readers will notice.

A useful rule: **round the estimate to roughly one-tenth of the interval width.** Interval of ±4 → nearest 0.5. Interval of ±0.2 → nearest 0.05.

### Say what the interval doesn't cover

For observational work especially, add one sentence: *"This range reflects sampling variation only. It does not account for the possibility that the groups differed in ways we couldn't measure — see the sensitivity analysis."*

That sentence is often the most important one in the document (Module 11, §7).

---

## 3. Assumptions belong in the summary

For anything non-experimental, the assumptions are load-bearing. Putting them in an appendix implies they're details, which mis-signals where the actual uncertainty lives.

The format that works:

> **What has to be true for this conclusion to hold:** that stores adopting early would have followed the same sales trend as late adopters, absent the program. We checked this — pre-launch trends track closely for 14 months (chart on p.4). **What would break it:** if early-adopting stores were selected for growth potential in a way we haven't accounted for. **How much slack we have:** an unmeasured factor would need to be about twice as strong as anything we measured to eliminate the effect.

Three sentences. A non-technical reader can now interrogate your reasoning on the merits, which is the point.

**Stating limitations strengthens rather than weakens a case.** An analyst who names the weak points is more credible than one who doesn't, and — more practically — the weak points get found eventually. Better that you found them.

---

## 4. Visual honesty

| Practice | Why |
|---|---|
| **Start bar charts at zero** | Bar length encodes magnitude; truncating misrepresents ratios. Line charts showing change over time need not start at zero |
| **Avoid dual y-axes** | The apparent correlation depends entirely on arbitrary scaling. Use two panels or index both to 100 |
| **Avoid pie charts beyond ~3 slices** | Angle is judged poorly; a sorted bar chart is strictly better |
| **Show uncertainty** | Error bars, bands, or overlaid distributions. A bare point estimate implies precision you don't have |
| **Show the data, not just the summary** | Distributions beat means; Anscombe's quartet is the standard demonstration |
| **Order categories meaningfully** | By value, not alphabetically |
| **Direct-label series** | Legends impose a lookup cost on every reading |
| **One chart, one message** | Put the message in the title: "Churn fell 3 points after the pricing change," not "Churn by month" |

That last row is the highest-leverage item on the list. A descriptive title asks the reader to derive the point; an assertive title states it. If you can't write an assertive title, the chart may not have a point.

**Check color choices for colorblind readers** — around 8% of men have some form of color vision deficiency, and red/green encoding of good/bad is the most common failure. Use viridis-family palettes, or encode redundantly with shape or position.

---

## 5. Anticipating the room

Before presenting, write down the three questions most likely to be asked and prepare the answers. The recurring set:

| Question | What it's really asking | Preparation |
|---|---|---|
| "Could it be [confounder]?" | Do you understand my domain? | Have the DAG and the checks you ran |
| "What about [segment]?" | This affects my area | Pre-compute the main segments, with intervals and the multiplicity caveat |
| "Why doesn't this match [other dashboard]?" | Which number do I trust? | **Reconcile before presenting.** Know the definitional difference |
| "How confident are you?" | Can I stake my reputation on it? | Give a calibrated verbal answer, not a p-value |
| "Just give me one number" | I need something for the slide | Give the number *and* the one condition attached |

The dashboard-reconciliation item causes more damage to analytical credibility than any other single thing. If your number disagrees with a number an executive already has, that discrepancy will consume the meeting regardless of your findings. **Find it first, explain it in one sentence, move on.**

### On "just give me one number"

Refusing to give a number reads as evasion and costs you the room. Give one, with its condition attached:

> "One number: 4%. That's the lift if the effect holds up outside our test markets, which is the main open question."

You've provided the number and made the caveat inseparable from it, which is more effective than a caveat delivered separately and forgotten.

---

## 6. Negative and null results

Most analyses find nothing conclusive, and most organizations handle this badly — the work goes unwritten and gets repeated in eighteen months.

The distinction that matters (Module 3, §8):

- **"We found no significant effect"** — often uninformative. It may mean the test was underpowered.
- **"We can rule out an effect larger than 1.5%"** — informative. A tight interval around zero is a real finding.

Report the interval, not the p-value, and state which of these you have. *"The effect is between −0.5% and +0.8%, so we can rule out anything worth building on"* is a conclusive result and should be written up as one.

**Maintain a searchable record of what was tried and what happened**, including nulls. This is one of the highest-return, lowest-cost pieces of analytical infrastructure a team can build, and its absence is why the same idea gets re-proposed every couple of years.

---

## 7. Failure modes

| Symptom | Likely cause |
|---|---|
| Analysis correct, nothing changed | No decision identified (Module 1), or buried conclusion |
| Meeting consumed by a number mismatch | Didn't reconcile against existing reporting first |
| Result overstated in a downstream retelling | Uncertainty was separable from the headline |
| "But what about X?" derails the room | Didn't anticipate the obvious objection |
| Stakeholders act on a subgroup finding you flagged as tentative | Caveat wasn't attached to the number itself |
| Nobody read past page one | Correct — write for that |
| Same question re-analyzed a year later | No record of the earlier work |
| Credibility damaged by one wrong call | Certainty was overstated at the time |

---

## 8. Practical recipe

1. **Write the conclusion first**, in two sentences, before writing anything else. If you can't, you don't have one yet.
2. **State the decision it informs** and what you recommend.
3. **Put the uncertainty in the second paragraph**, framed against the decision threshold from Module 1.
4. **Put the assumptions in the summary** — what must be true, what would break it, how much slack there is.
5. **Round to the precision your interval supports.**
6. **Use frequencies** for anything conditional.
7. **Reconcile with existing reporting** before you present.
8. **Give every chart an assertive title** and show uncertainty on it.
9. **Prepare three anticipated questions** with answers.
10. **Write up nulls too**, framed as what you can rule out, and keep them findable.

---

## 9. Further reading

- Minto, *The Pyramid Principle* — the canonical treatment of conclusion-first structure. Dry, and the structure is worth adopting wholesale.
- Gigerenzer & Hoffrage (1995) on natural frequencies — the evidence behind §2, and the clearest demonstration of how much presentation format affects reasoning.
- Cairo, *How Charts Lie* — accessible, practical, and the best single source on §4.
- Tufte, *The Visual Display of Quantitative Information* — the classic; read for principles rather than prescriptions.
- Spiegelhalter, Pearson & Short (2011), "Visualizing uncertainty about the future" — a survey of what actually works for communicating intervals to non-specialists.
- Gelman & Greenland (2019) on "uncertainty intervals" — framing that survives contact with a general audience.
