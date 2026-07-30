# What Is This Analysis For? A Plain-Language Guide to Framing and Metrics

*Module 1 — plain-language register. What an analysis is for, and how to choose what to measure.*

---

## The short version

Most failed analyses fail before anyone writes a line of code. They fail because nobody pinned down what decision the work was supposed to inform, what exactly was being measured, or what "success" would look like in numbers.

Three things have to be settled before you start:

1. **The decision.** What will someone do differently depending on the answer?
2. **The question.** Precisely what quantity, for which people, over what time window, compared to what?
3. **The measurement.** What number are you actually going to compute, and how far is it from the thing you care about?

Every technique in the rest of this course — validation, evaluation, monitoring — makes your answer *more accurate*. None of them can make it the *right question*. A rigorously validated model of the wrong thing is worse than nothing, because it comes wrapped in credibility.

---

## Part 1: Start with the decision

The first question is never "what data do we have." It's:

> **What would we do differently depending on the answer?**

If nothing changes for any plausible answer, the analysis is worth zero no matter how well it's done. Say that out loud, kindly, early. It's one of the most valuable things an analyst does.

### The intake form

Make every request fill this in before work starts:

| Question | Example answer |
|---|---|
| What decision is this for? | Whether to extend the free trial from 14 to 30 days |
| Who makes it? | Growth PM, with pricing sign-off |
| What are the options? | Keep 14, go to 30, compromise at 21 |
| When is it needed? | Roadmap lock in six weeks |
| What result would make us change? | Revenue per signup up 2% or more, no rise in support load |
| What result would make us keep things as-is? | Anything else |
| Can we undo it? | Yes, but existing trials run for 60 more days |

Two useful things drop out immediately.

**The "2%" sets how precise you have to be.** That number determines how much data you need and whether the test is even feasible. It's also exactly what Module 3 needs for a power calculation and Module 7 needs for setting a threshold. Getting it agreed *before* results arrive prevents the familiar argument where a 0.4% lift gets relitigated as a success.

**Reversibility sets how much rigor is warranted.** A cheap, reversible decision deserves a fast, rough answer. An expensive, irreversible one deserves the full apparatus. Spending six weeks on a decision someone can undo in an afternoon is a real cost, not thoroughness.

### Which mistake is worse?

Get this on paper early. Is it worse to flag a good customer as a fraud risk, or to miss a real fraud? By roughly how much? You don't need precision — "missing fraud is about ten times worse" is enough — but you need *something*, because that ratio determines your decision threshold later. Without it, someone picks 50/50 by default and nobody notices.

---

## Part 2: Pin down the question

"Reduce churn" is a topic, not a question. A question specifies four things:

- **Who** — which customers? New signups only? Excluding enterprise accounts? Excluding people who never activated?
- **What** — what exactly counts as the outcome? Define it so two analysts would compute the same number.
- **When** — over what window? Measured from what starting point?
- **Compared to what** — versus doing nothing? Versus the current approach? "Nothing" is usually not well-defined.

If any of these is fuzzy, two people will compute different numbers, both will be defensible, and the meeting will be about definitions instead of the decision.

### Defining the outcome is harder than it looks

"Churn" isn't a definition. **"No active session in the 30 days following day 60 after signup"** is.

Three traps here, and they cause real damage:

**How long do you wait?** If churn means "inactive for 30 days," you cannot know whether last week's signups churned. Your data is always at least a month stale. That constrains everything downstream, and it's better known now than discovered later.

**What about people who haven't had time?** Someone who signed up three weeks ago can't have a 30-day churn label yet. Dropping them sounds harmless but quietly restricts your analysis to older customers, who are different in ways that matter. If timing is central to your question, this is a signal that you need survival analysis rather than a yes/no model.

**Does your data secretly contain the answer?** This is the big one. If you're predicting churn in November using data through November, you may have features that only exist *because* the person churned — a cancellation-page visit, a final support ticket.

The rule: **everything you use as an input must be knowable strictly before the outcome window opens.** Draw the timeline on a whiteboard — inputs from here to here, outcome measured from here to here — and check they don't overlap. Almost every leakage disaster caught in Module 6 was created at this step.

### Watch out for who's missing

If you only analyze customers who completed onboarding, you've filtered your data by something that's partly a *result* of what you're studying. That's the collider problem from Module 2, and it manufactures fake patterns.

Define your population as early in the journey as you can, and treat "didn't make it that far" as an outcome to explain rather than a row to delete.

---

## Part 3: Choosing what to measure

Your metric is a stand-in for what you actually care about. The distance between the two is real, and no amount of extra data closes it.

Ask four questions of any candidate metric:

**Does it measure the right thing?** "Engagement" measured by number of sessions rewards a confusing interface that makes people come back more often to finish one task.

**Can it move in time?** Lifetime value is the right concept and a terrible metric for a two-week test — it's noisy and takes years to observe. You often need a short-horizon proxy, which is fine as long as you say so.

**Is more clearly better?** Support contacts going down could mean a better product, or a help page nobody can find.

**How would someone cheat it?** Not maliciously — just following incentives. Assume the cheapest path to moving the number will eventually get found, because it always does.

### Goodhart's law, and why it's the default

> **When a measure becomes a target, it stops being a good measure.**

The reason is mechanical, not cynical. Your proxy correlates with what you care about *across the behavior you've seen so far*. Optimizing hard pushes you into territory where that correlation was never tested — and the cheapest way to move the proxy out there is usually the way that doesn't move the real thing.

Defenses that work:

- **Use a hierarchy, not one number.** One primary metric decides. Secondary metrics explain. **Guardrails** must not get worse — page speed, complaint rate, refunds, unsubscribes. Guardrails are your main protection, because they fence off the cheap exploits.
- **Keep a long-term holdout.** A small group that gets none of this quarter's launches, so you can check the cumulative effect against something real.
- **Recheck the proxy periodically.** Does clicking still predict retention the way it did last year? Proxies decay.

---

## Part 4: When not to build a model

A model earns its keep when the decision is (a) repeated, (b) genuinely uncertain in a way data can help with, and (c) actionable at the moment the prediction arrives.

Miss any one and something simpler is better:

| Situation | Do this instead |
|---|---|
| One-time decision | Just analyze it directly, or run a test |
| Nobody can act when the prediction arrives | Nothing — the prediction is inert |
| A simple rule gets most of the value | Ship the rule; monitor it |
| The real problem is that the data is wrong | Fix the instrumentation first |
| The decision is already made and needs justification | Say so plainly |

### Always name the trivial baseline first

What score does "guess the most common outcome" get? Or "predict the same as last month"? Or the heuristic the team uses today?

Establish this at the *start*, not at evaluation time. It's the bar your project has to clear to be worth building and maintaining, and knowing it early prevents the deflating end-of-quarter discovery that a sophisticated model ties the existing rule of thumb.

---

## Part 5: Constraints that change everything

Ask these before modeling, because each one rules methods in or out:

- **How fast must the answer come?** This is the *latency* budget, and a tight one rules out slow feature pipelines entirely.
- **Will the inputs exist when you need them?** A field that's in the warehouse but not available live is unusable. This mismatch is the single most common reason a model works in testing and fails in production.
- **Does anyone need to know *why*?** Regulated decisions often require an explainable reason, which limits your model choices (Module 13).
- **How many can we act on?** If sales can call 200 leads a week, you don't need a good model overall — you need the *top 200* to be right. That changes the metric entirely.
- **How often can it be retrained?**

The capacity question is worth dwelling on. "Predict who will churn" and "give me the 200 people most worth calling" sound similar and are different problems with different metrics. Finding this out after you've built the model wastes the cycle.

---

## Part 6: Warning signs

| What you see | What went wrong at framing |
|---|---|
| "Great model, nobody uses it" | No decision identified, or no action possible when it fires |
| Two analysts, two answers, same data | The question was never pinned down |
| Works in testing, fails in production | Inputs aren't available at decision time |
| Metric improved, business didn't | The proxy drifted from the real goal |
| Can't get enough precision to decide | Nobody checked feasibility before starting |
| Leakage discovered late | Input and outcome windows overlapped from the start |
| Endless debate about what the result means | No agreed decision rule beforehand |

---

## Putting it all together

**The checklist:**

1. **Name the decision, the person making it, and the options.**
2. **Agree the threshold** — how big does the effect have to be to matter? — and roughly how much worse one kind of error is than the other.
3. **Write the question precisely** — who, what, when, compared to what.
4. **Draw the timeline.** Inputs before outcomes, with no overlap.
5. **Pick one primary metric**, plus explanatory ones and guardrails. Ask how it could be gamed.
6. **State the trivial baseline** you have to beat.
7. **List the practical constraints** — speed, data availability, capacity, explainability.
8. **Ask honestly whether a model is the right tool.**
9. **Circulate all of the above and get agreement before analyzing.** Disagreements are cheap now and expensive later.

**Three things to remember if you remember nothing else:**

- **If no decision changes, don't do the analysis.** Saying this early is a service, not an obstruction.
- **Agree what "big enough to matter" means before you see results.** Afterwards, everyone's threshold mysteriously matches the number that appeared.
- **Anything that becomes a target stops measuring what it used to.** Set guardrails, because someone will eventually find the cheap way to move your metric.

---

## Where to go next

- *Trustworthy Online Controlled Experiments* (Kohavi, Tang & Xu) — chapters on metric design and guardrails are the best practical treatment anywhere.
- *How to Measure Anything* (Douglas Hubbard) — how to think about whether an analysis is worth doing, and how to talk to stakeholders about it.
- *Thinking in Bets* (Annie Duke) — separating decision quality from outcome quality, useful for the reversibility conversation.
