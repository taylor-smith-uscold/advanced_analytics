# Finding Groups Without Answers: A Plain-Language Guide to Unsupervised Methods

*Module 12 — plain-language register. How to look for groups in data, and how to tell whether they're real.*

---

## The short version

Every other module in this course has a safety net: you hold out data, you check whether the model got the answers right. Unsupervised methods have no answers to get right. You're looking for structure without knowing what structure is there.

This makes the area unusually good at producing confident nonsense. Three things will protect you:

1. **Clustering algorithms will find clusters whether or not any exist.** Ask for four segments and you'll get four segments — from genuinely distinct groups, or from a single undifferentiated blob. **The slide looks identical either way.**
2. **Those beautiful colorful scatter plots (t-SNE, UMAP) lie about distance.** How far apart two blobs appear, how big they look, the empty space between them — none of it means anything.
3. **Since you can't check the answer, check whether it reproduces.** Structure that survives on a different sample of your data is real. Structure that doesn't was a picture.

---

## Part 1: The problem with segmentation

Here's an experiment worth running once, personally.

Generate a cloud of random points with no structure at all — one undifferentiated blob. Run k-means and ask for four clusters.

**You'll get four clean, tidy, well-separated-looking clusters.** They'll have distinct centers. You can profile them. You can give them names. You can build a slide deck.

There's nothing there. The algorithm just cut the blob into four pieces, because that's what you asked it to do.

**k-means doesn't check whether clusters exist. It partitions.** And the output of partitioning noise looks exactly like the output of finding real groups, especially by the time it reaches a presentation.

This is not a rare edge case. Customer data is frequently one continuous spread along a few dimensions — spend more, engage more — with no natural breaks. Segmentation exercises on such data produce segments, get named, get operationalized, and quietly fail to reproduce next quarter.

### Test for structure first

There's a specific tool for this: the **gap statistic**. Unlike most methods for choosing the number of clusters, it compares your data against random data with no structure — and it **can tell you the answer is one cluster.**

Run it before presenting any segmentation. If it says one, you've learned something genuinely valuable about your customers, and you've saved everyone from a segmentation that would have dissolved.

---

## Part 2: Clustering methods

### k-means, and what it assumes

The most common method. Pick a number of clusters, and it finds groupings that minimize how spread out each one is.

It quietly assumes:

- Clusters are roughly **round blobs** of **similar size**
- You know **how many** there are
- Your features are **on comparable scales** (Module 5 — otherwise the biggest-numbered feature dominates)

When these don't hold, it doesn't warn you. It just gives a worse answer with the same confidence: slicing an elongated group in half, or splitting one dense group while merging two sparse ones.

### Alternatives worth knowing

| Method | Why you'd use it |
|---|---|
| **HDBSCAN** | Finds clusters of any shape, figures out the number itself, and **labels genuinely unusual points as noise** instead of forcing them somewhere. Often the best default |
| **Gaussian mixtures** | Allows stretched, overlapping clusters; gives you "60% likely group A" instead of a hard assignment |
| **Hierarchical clustering** | Produces a tree, so you can see structure at multiple levels of granularity. The tree itself is often the useful output |

**Try more than one.** If k-means, HDBSCAN, and a mixture model broadly agree, that's real evidence. If they disagree completely, the structure isn't there.

### "Distance" is a decision

Most methods need to measure how similar two customers are, and how you measure changes everything.

Two customers who behave identically but at different volumes — one spends $1,000/month, one spends $100/month on exactly the same things — look *far apart* by ordinary distance and *identical* by "cosine" distance, which ignores magnitude and compares only patterns.

Which is right depends on your question. If you want to separate big from small, ordinary. If you want to find behavioral types regardless of size, cosine. **Decide this deliberately** — many segmentations accidentally produce "big customers / medium customers / small customers" because nobody thought about it.

---

## Part 3: Check that it reproduces

With no answers to check against, the substitute is: **does the same structure appear if I use different data?**

**Do this:** take a random 80% of your data, cluster it. Take a different random 80%, cluster that. Do it twenty times. Do the same groups keep appearing?

If yes, you've found something. If the clusters reorganize each time, you found nothing.

**Also try:** vary the random starting seed. Drop a feature. Add a little noise. Real structure survives all of these; fabricated structure doesn't.

**Report it.** "Four segments" is a claim. "Four segments, and the four-way split reproduces in 92% of resamples" is a finding — and it's the sentence that separates a segmentation people can build on from one they'll quietly abandon.

---

## Part 4: The colorful scatter plots lie

You've seen these — thousands of points in 2D, colored by group, with clean-looking islands. They come from t-SNE or UMAP.

They're genuinely useful for one thing: showing you that distinct groups exist. They're **actively misleading** about almost everything else.

| What you see | What it means |
|---|---|
| Two clusters far apart | **Nothing.** They might be adjacent in reality |
| One cluster much bigger | **Nothing.** The algorithm expands sparse regions and squashes dense ones |
| Empty space between groups | **Nothing** |
| The overall shape | **Nothing** |
| Two points sitting next to each other | **This part is real** — they're genuinely similar |

Only local neighborhoods are preserved. Everything about the global layout is an artifact of the algorithm.

Two practical consequences:

**Run it with several settings.** Both methods have a knob (perplexity, n_neighbors) that substantially changes the picture. So does the random seed. **Only trust structure that appears under all of them.** If your three islands merge into one when you change a setting, they were one.

**Never cluster on these coordinates.** This is a common and serious error. The projection distorts distance, so clusters found in that space are partly manufactured by the projection. **Cluster on your real data; use the plot only to display the result.**

If you want an honest 2D picture, add a PCA plot alongside. It's less pretty and its distances mean something.

---

## Part 5: PCA — squeezing many columns into a few

PCA finds the directions along which your data varies most and lets you describe each record with a handful of numbers instead of fifty.

Two things to know:

**Scale first.** PCA chases variance, and variance depends on units. Leave a revenue column in dollars next to a satisfaction score out of 5, and your first component will simply be revenue. Standardize everything first (Module 5).

**The components usually aren't interpretable.** People try hard to name them — "this one is engagement, this one is price sensitivity" — and usually it's storytelling. The components are chosen by a mathematical criterion (maximum variance, at right angles to each other) that has no reason to line up with meaningful concepts. If you specifically want interpretable underlying factors, use factor analysis, which is designed for that.

---

## Part 6: Finding unusual records

Related task: spot the records that don't look like the others. Fraud, equipment failures, data errors.

Reasonable tools: **Isolation Forest** (fast, works well, good default), **Local Outlier Factor**, or often just **robust statistical rules** — which are competitive and far easier to explain to an auditor.

Two things that matter more than the method choice:

**"Unusual" isn't the same as "important."** Most statistical outliers are typos, or legitimate rare cases, or new-but-harmless behavior. Without labels, you can't rank what's worth investigating, and you'll hand your fraud team a queue that's mostly noise.

**You probably have some labels.** Confirmed fraud cases. Past incidents. Things analysts flagged. **Even a few dozen** turns this into a supervised problem that will work far better.

Ask this before starting. Teams routinely reach for anomaly detection when a small labeled set exists and would do a much better job.

---

## Part 7: Warning signs

| What you see | What's probably happening |
|---|---|
| Clean clusters that don't reproduce on a resample | No real structure — you partitioned noise |
| First PCA component is basically one column | Didn't scale the data |
| Segments are just "high / medium / low activity" | Magnitude dominating; try cosine distance |
| Segments changed completely this quarter | Unstable structure, or the world moved (Module 14) |
| Gorgeous t-SNE plot, meaningless segments | Clustered on the plot coordinates |
| HDBSCAN calls most points "noise" | Settings too strict — adjust |
| Anomaly detector flags obviously fine records | Rare ≠ problematic; you need labels |
| **The segments turn out to be one obvious variable** | You did an expensive `GROUP BY` |

That last one is worth checking early and honestly. If your four segments map almost perfectly onto company size, you didn't need clustering — a business rule would be clearer, cheaper, stable, and explicable to anyone.

---

## Putting it all together

**The recipe:**

1. **Ask what decision this serves** (Module 1). "Understand our customers better" isn't a decision. "Assign one of three outreach playbooks" is — and it tells you the answer is three, before you start.
2. **Scale your features**, and log anything spanning orders of magnitude.
3. **Test whether clusters exist at all** — gap statistic — before picking a number.
4. **Try several methods.** Agreement is evidence; disagreement is a warning.
5. **Check that it reproduces** on resampled data. Report that number.
6. **Describe the clusters using variables you didn't cluster on.** If your segments differ meaningfully on things the algorithm never saw, that's the closest thing to real validation available.
7. **Use UMAP to explore, PCA for honest distances** — and cluster on neither.
8. **Check whether a simple rule reproduces your segments.** If it does, ship the rule.
9. **Re-run periodically.** Segment definitions that quietly shift will break everything downstream.

**Three things to remember if you remember nothing else:**

- **Ask for four clusters and you'll get four clusters, structure or not.** Test whether groups exist before deciding how many there are.
- **Distances in t-SNE and UMAP plots are meaningless.** Only "these two points are neighbors" survives. Never cluster on those coordinates.
- **Since you can't check the answer, check the reproducibility.** If it doesn't survive a resample, don't build a business process on it.

---

## Where to go next

- **Essential, and takes ten minutes:** "How to Use t-SNE Effectively" on Distill.pub — interactive examples that show exactly how the plots mislead. Have everyone on your team read this before they present one.
- **Practical:** the HDBSCAN documentation has an unusually good comparison of clustering algorithms and their assumptions.
- **Conceptual:** *An Introduction to Statistical Learning*, chapter 12 — PCA and clustering at a comfortable level. Free online.
