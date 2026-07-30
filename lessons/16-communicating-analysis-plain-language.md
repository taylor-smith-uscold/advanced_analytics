# Did Anyone Act On It? A Plain-Language Guide to Communicating Analysis

*Module 16 — plain-language register. How to report an analysis so that someone acts on it.*

---

## The short version

An analysis nobody acts on is worth exactly as much as one you never did. And the usual reason for that isn't bad analysis — it's how the work got presented.

Three things go wrong most often:

1. **The conclusion is buried.** You built the argument the way you did the work — question, data, method, result. Your reader stops after paragraph two.
2. **The uncertainty gets stripped off.** Your careful range becomes a single confident number by the time it reaches a slide.
3. **The assumptions end up in an appendix**, which tells the reader they're details. For most non-experimental work, the assumptions *are* the result.

The fix for all three is the same: **put the conclusion first, make the uncertainty part of the headline rather than a footnote to it, and state your assumptions where people will read them.**

---

## Part 1: Backwards from how you worked

You did the work in this order: question, data, method, checks, result, what it means.

**Present it in reverse.**

```
1. What we found and what we should do        (2 sentences)
2. How sure we are, and what would change it  (2 sentences)
3. The evidence                                (a page)
4. How we did it, and what we're assuming      (as long as needed)
5. Everything else                             (appendix)
```

Someone who reads only the first two sentences should come away with the right conclusion. Someone who reads four should know how much to lean on it.

This feels wrong the first few times. You want to earn the conclusion by showing the work. But an executive reading twelve documents before a meeting will read your first paragraph and possibly nothing else — and if the conclusion isn't there, they'll construct their own.

### A result is not a finding

**Result:** "Customers in the treatment group renewed 4 percentage points more often."

**Finding:** "We should roll this out everywhere. It's worth roughly £2M a year. The main risk is that the effect fades once the novelty wears off — we'd know by month three."

The second one is a decision. Translating from the first to the second is your job. If you leave it undone, someone with less context will do it for you, and they'll do it worse.

---

## Part 2: Uncertainty people can use

### Both failure directions are real

Sound too certain and you'll eventually be badly wrong in public, and you don't fully recover from that.

Hedge everything and people stop asking you. The decision still gets made — just without your input.

The way through is to make the uncertainty **useful** rather than defensive:

> ❌ "The effect is 3.2%, though with considerable uncertainty, and further investigation is warranted."
>
> ✅ "Best guess is a 3.2% lift. The data is consistent with anything from slightly negative to almost 7%. We ship at anything over 1% — so honestly, we don't yet know if this clears the bar. Two more weeks would settle it."

Same uncertainty. The second one tells someone what to *do* about it, including what would resolve it.

### Use counts, not percentages

People reason far better about "9 out of 59" than about "90% sensitivity with 1% prevalence." This is well established, and it's an easy win.

> ❌ "The model catches 90% of fraud with a 5% false positive rate."
>
> ✅ "Out of 1,000 transactions, about 10 are fraud. We'll catch 9 of them. We'll also flag around 50 legitimate ones. So of roughly 59 alerts, 9 are real — about one in seven."

The second version *prevents* the misunderstanding rather than just providing the ingredients for it. Use counts any time you're presenting accuracy, precision, or recall to a non-technical audience.

### Don't report more digits than you can defend

If your range is give-or-take four points, say "about 62%," not "61.74%."

Extra digits look rigorous and are actually a false claim about how good your evidence is. Anyone quantitative in the room will notice, and it's a cheap way to lose credibility.

### Add the sentence about what your range doesn't cover

For anything that isn't a controlled experiment:

> "This range reflects the randomness in our sample. It doesn't account for the possibility that the two groups differed in ways we couldn't measure."

That's frequently the most important sentence in the whole document (Module 11).

---

## Part 3: Put the assumptions where people will read them

For any non-experimental analysis, your conclusion rests on something you can't prove. Putting that in an appendix implies it's a technicality.

A format that works, in three sentences:

> **What has to be true:** that the stores who adopted early would have followed the same sales trend as the ones who adopted later, if nothing had changed. **We checked this** — their trends track closely for the 14 months before launch (chart on page 4). **What would break it:** if early adopters were chosen for growth potential in a way we haven't accounted for. An unmeasured factor would need to be about twice as strong as anything we measured to wipe out the result.

Any reader can now push back on the reasoning itself, which is exactly what you want.

**Naming your weak points makes you more credible, not less.** People trust an analyst who volunteers limitations. And practically: the weak points get found eventually. Much better that you found them.

---

## Part 4: Charts that don't mislead

| Do this | Because |
|---|---|
| **Start bar charts at zero** | The bar's length is the message. Cutting the axis exaggerates differences. (Line charts over time are fine not starting at zero) |
| **Avoid two different y-axes** | You can make any two lines look related by choosing the scales. Use two stacked charts instead |
| **Avoid pie charts with more than three slices** | People judge angles badly. A sorted bar chart is always clearer |
| **Show the uncertainty** | Error bars or shaded bands. A bare dot implies precision you don't have |
| **Show the spread, not just averages** | Two groups with identical averages can be completely different |
| **Sort by value, not alphabetically** | |
| **Label lines directly** | Legends make people look back and forth |
| **Put the point in the title** | |

That last one is the biggest win available. Compare:

- ❌ "Monthly Churn Rate by Segment"
- ✅ "Enterprise churn doubled after the March pricing change"

The first asks the reader to figure out why they're looking at this. The second tells them.

If you can't write an assertive title for a chart, ask whether the chart has a point.

**One accessibility note:** about 8% of men have some degree of colorblindness, and red/green for good/bad is the most common problem. Use a colorblind-safe palette (viridis is the standard) or make sure color isn't the only thing carrying the meaning.

---

## Part 5: Prepare for the room

Before presenting, write down the three questions most likely to come, and your answers. They're usually from this list:

| The question | What they're really asking | Be ready with |
|---|---|---|
| "Couldn't it be [other explanation]?" | Do you know my business? | Your diagram and the checks you ran |
| "What about [their segment]?" | Does this affect me? | Pre-computed segment numbers, with the caveat |
| "Why doesn't this match the dashboard?" | Which number do I believe? | **The reconciliation, done beforehand** |
| "How confident are you?" | Can I put my name on this? | A plain-language answer, not a p-value |
| "Just give me one number" | I need something for the slide | The number, with its condition attached |

### The dashboard question deserves special attention

If your number contradicts a number someone already has, **that discrepancy will consume the entire meeting** regardless of what you found.

Find it before the meeting. Understand exactly why the two differ — usually a definitional difference in the date range, the population, or what counts as an event. Have a one-sentence explanation ready.

This single habit protects more analytical credibility than any other.

### On "just give me one number"

Refusing sounds evasive and costs you the room. Give a number, with the condition welded to it:

> "One number: 4%. That's assuming it holds up outside our test markets, which is the main thing we don't know yet."

You've answered the question and made the caveat travel with the number, which is far more effective than a caveat delivered separately and forgotten by lunch.

---

## Part 6: Write up the ones that found nothing

Most analyses don't find a clear answer. Most organizations handle this by not writing them up — and then re-running the same investigation eighteen months later.

There's an important distinction:

**"We didn't find a significant effect"** — often means nothing. The test may have been too small to detect anything.

**"We can rule out any effect bigger than 1.5%"** — that's a real finding, and often a valuable one.

Report the range, and say which of these you have. "The effect is somewhere between −0.5% and +0.8%, so there's nothing here worth building on" is a **conclusive result**. Write it up as one.

**Keep a searchable record of what's been tried and what happened**, including the nulls. It's one of the cheapest and most valuable things an analytics team can maintain, and its absence is exactly why the same idea gets proposed every couple of years.

---

## Part 7: Warning signs

| What you see | What went wrong |
|---|---|
| The analysis was right, nothing changed | No decision identified (Module 1), or the conclusion was buried |
| The meeting was about a number mismatch | Didn't reconcile beforehand |
| Your finding got overstated downstream | The caveat wasn't attached to the number |
| One question derailed everything | Didn't anticipate the obvious objection |
| People acted on a tentative subgroup result | The caveat was too easy to separate |
| Nobody read past page one | Normal — write for it |
| Someone re-asked your question a year later | No record of the first analysis |
| One wrong call damaged your credibility badly | You'd sounded too certain |

---

## Putting it all together

**The recipe:**

1. **Write your conclusion first**, in two sentences, before anything else. If you can't, you don't have one yet.
2. **Say what decision it's for and what you'd do.**
3. **Put the uncertainty in the second paragraph**, framed against the threshold that matters.
4. **Put your assumptions in the summary** — what has to be true, what would break it, how much room you have.
5. **Round to what your range supports.**
6. **Use counts instead of percentages** for anything conditional.
7. **Reconcile with existing dashboards** before you present.
8. **Give every chart a title that states the point**, and show uncertainty on it.
9. **Prepare three likely questions.**
10. **Write up the null results too**, as what you can rule out. Keep them findable.

**Three things to remember if you remember nothing else:**

- **Conclusion first.** You built the argument forward; present it backwards. Most readers stop after two paragraphs.
- **Attach the caveat to the number.** A caveat delivered separately gets dropped by the time your finding reaches a slide.
- **Reconcile against existing reports before you present.** An unexplained discrepancy with a number someone already trusts will eat the whole meeting.

---

## Where to go next

- **On structure:** *The Pyramid Principle* by Barbara Minto — dry, and the conclusion-first structure is worth stealing wholesale.
- **On charts:** *How Charts Lie* by Alberto Cairo — accessible, practical, and full of real examples of misleading visuals.
- **On uncertainty:** anything by David Spiegelhalter, especially *The Art of Statistics* — he's the best living communicator of statistical uncertainty to general audiences, and the techniques are learnable.
