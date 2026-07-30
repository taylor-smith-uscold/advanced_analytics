# Structure Without Labels: Unsupervised Methods

*Module 12 — technical register. For readers who know that a projection is a choice.*

> **Required reading —** ISLP ch. 12 · free PDF at [statlearning.com](https://www.statlearning.com/), plus Wattenberg et al., [*How to Use t-SNE Effectively*](https://distill.pub/2016/misread-tsne/)

---

## 0. The one-paragraph version

Unsupervised methods find structure without a target, which removes the safety net that every other module relies on: there is no held-out score to tell you the answer is wrong. This makes the field unusually productive of confident nonsense. Three cautions carry most of the weight. **k-means will return k clusters whether or not clusters exist** — it partitions space unconditionally, and the partition of a single Gaussian blob looks exactly as convincing in a slide deck as the partition of genuinely separated groups. **PCA is the SVD from Module 5** applied to the data matrix rather than the regression problem, which means it inherits the same scale-dependence: components are determined by whichever features have the largest variance, and variance depends on units. **t-SNE and UMAP distances are not distances** — between-cluster separation, relative sizes, and empty space in those plots are largely artifacts of the algorithm, not properties of the data. The discipline that replaces the missing held-out score is **stability**: structure that survives resampling is worth acting on, structure that doesn't is a picture.

---

## 1. Principal component analysis

Given centered $X$, PCA finds orthogonal directions of maximal variance — the eigenvectors of the covariance matrix, equivalently the right singular vectors $V$ from $X = UDV^\top$.

This is the same decomposition as Module 5, §1. There, the singular values told you which directions the data could resolve and which ridge should damp. Here, they tell you which directions carry variance and which you might discard. Same object, two readings.

**Standardize first.** The components maximize variance, and variance carries units. A feature in dollars will dominate one in fractions purely by scale — PC1 becomes "the dollar feature." Use the correlation matrix (i.e., standardize) unless all features share meaningful units.

### Interpretation and its limits

The proportion of variance explained by component $j$ is $d_j^2/\sum_k d_k^2$. A scree plot shows where it flattens.

Two things PCA does *not* give you:

- **Interpretable factors.** Components are constrained to be orthogonal and variance-maximizing, which rarely aligns with anything meaningful. A component loading on eleven features with mixed signs is a mathematical artifact, not a construct. If you want interpretable latent factors, use factor analysis with rotation, which is designed for it.
- **Predictive relevance.** Components are chosen without reference to the target. The direction of maximum variance may be irrelevant to $y$ — using top components as regression inputs (principal components regression) can discard exactly the signal you needed. Partial least squares uses the target and is usually the better choice if the goal is prediction.

**Sign and rotation are arbitrary.** Refit on slightly different data and components can flip sign or rotate within a near-degenerate subspace. Don't build stable business definitions on component values.

---

## 2. Clustering

### k-means

Minimizes within-cluster sum of squares by alternating assignment and centroid updates. Fast, scalable, and carrying strong implicit assumptions:

- Clusters are **spherical** in the feature space (it uses Euclidean distance)
- Clusters have **similar sizes and densities**
- Clusters are **convex and linearly separable**
- **$k$ is known**
- Features are **scaled** — otherwise distance is dominated by large-variance features, as in Module 5, §2.1

Violate these and k-means still returns an answer. It will slice an elongated cluster in half; it will split a dense cluster and merge sparse ones; it will partition a single Gaussian into $k$ tidy wedges.

**This is the central caution.** k-means does not test whether clusters exist. It partitions. The output has the same visual character either way, and a segmentation deck built on a partition of structureless data is indistinguishable, to its audience, from a real finding.

### Alternatives

| Method | Model | Good for | Watch |
|---|---|---|---|
| **Gaussian mixture** | Elliptical, soft assignment | Overlapping clusters; probabilistic membership | Covariance parameters; can overfit |
| **DBSCAN** | Density-connected regions | Arbitrary shapes; noise points; no $k$ needed | Sensitive to `eps`; struggles with varying density |
| **HDBSCAN** | Hierarchical density | Varying density; usually the best default of this family | Slower |
| **Agglomerative** | Nested merges | Dendrogram is genuinely informative; any distance metric | $O(n^2)$; linkage choice matters a lot |
| **Spectral** | Graph cut on similarity | Non-convex shapes | Doesn't scale; needs an affinity choice |

**Distance metric is a modeling decision.** Euclidean assumes comparable scaled dimensions; cosine ignores magnitude (appropriate for text and behavior vectors); Gower handles mixed types. For mixed categorical and continuous data, k-means on one-hot encodings is a common and poor default — k-prototypes or Gower-based hierarchical clustering are better.

### Choosing $k$

| Method | Interpretation | Weakness |
|---|---|---|
| **Elbow** | Where WCSS improvement flattens | Frequently no visible elbow; reader-dependent |
| **Silhouette** | Cohesion vs separation, $[-1,1]$ | Biased toward convex, balanced clusters |
| **Gap statistic** | Compares WCSS to a null reference | **Can indicate $k=1$** — the only common criterion that tests whether clusters exist at all |
| **BIC/AIC** (GMM) | Penalized likelihood | Requires the mixture model to be roughly right |

The gap statistic deserves the emphasis. Most criteria assume clustering is appropriate and only ask how many; the gap statistic compares against a null of no structure and can tell you the honest answer is one cluster. Run it before presenting a segmentation.

---

## 3. Stability is the substitute for validation

Without labels there is no test-set score. The replacement is **reproducibility under perturbation.**

**Consensus clustering:** cluster many bootstrap resamples (or random subsamples). For each pair of points, record how often they land together. A stable solution has a co-clustering matrix that is nearly block-diagonal; an unstable one is a smear.

**Split-half validation:** cluster half the data, train a classifier to predict cluster labels, apply it to the other half, and compare against clustering that half directly (Adjusted Rand Index).

**Perturbation:** add small noise, drop features, vary the seed. Solutions that reorganize under any of these were never there.

Report the stability, not just the solution. "Four segments, and the four-way structure reproduces in 92% of resamples" is a finding. "Four segments" alone is a picture.

---

## 4. Nonlinear embeddings: t-SNE and UMAP

These map high-dimensional data to 2D for visualization by preserving *local neighborhood* structure. They are excellent at revealing that groups exist, and systematically misleading about everything else.

**What is not meaningful in a t-SNE or UMAP plot:**

| Visual feature | Reality |
|---|---|
| Distance between clusters | Not meaningful. Two far-apart blobs may be adjacent in the original space |
| Cluster size / area | Not meaningful. t-SNE expands sparse regions and compresses dense ones |
| Empty space | Not meaningful |
| Overall shape or orientation | Not meaningful |
| Points being neighbors | **This is the one thing preserved** |

Both are also strongly hyperparameter-dependent: t-SNE's perplexity and UMAP's `n_neighbors` change the picture substantially. Different random seeds give different layouts. **Run several settings and only trust structure that persists across all of them.**

**Never cluster on t-SNE or UMAP coordinates.** The embedding distorts density and distance, so clusters found there are partly artifacts of the projection. Cluster in the original (or PCA-reduced) space and use the embedding only to display the result.

UMAP preserves more global structure than t-SNE and is faster, but the same cautions apply in weakened form. PCA, by contrast, is a linear projection where distances *are* interpretable — worth showing alongside, precisely because it's honest about what it loses.

---

## 5. Anomaly detection

The unsupervised framing of a problem that is usually semi-supervised in disguise.

| Method | Basis |
|---|---|
| **Isolation Forest** | Anomalies are easier to isolate by random splits; scales well |
| **Local Outlier Factor** | Local density relative to neighbors; catches local anomalies |
| **One-class SVM** | Boundary around the bulk of data; sensitive to parameters |
| **Autoencoder reconstruction error** | High error means unusual; needs volume |
| **Simple statistical rules** | Robust z-scores, quantile thresholds — often competitive and far easier to explain |

Two persistent difficulties:

**"Anomalous" and "interesting" are different.** Most statistical outliers are data errors, rare-but-legitimate cases, or new-but-benign behavior. Without labels there is no way to prioritize.

**You almost always have some labels.** Confirmed fraud cases, past incidents, analyst dispositions. Even a handful converts this into a supervised or PU-learning problem with far better performance. Ask before assuming the problem is unsupervised — teams frequently reach for anomaly detection when a small labeled set exists and would work better.

---

## 6. Failure modes

| Symptom | Likely cause |
|---|---|
| Clusters look clean, don't reproduce on a resample | No real structure; k-means partitioned noise |
| PC1 is essentially one feature | Data not standardized |
| Clusters correspond to activity level only | Unnormalized magnitude dominating; consider cosine distance |
| Segments unstable across quarters | Genuinely unstable structure, or drift (Module 14) |
| Beautiful t-SNE, meaningless clusters | Clustering was done in embedding space |
| Cluster interpretation flips between runs | Label permutation, or an unstable solution |
| DBSCAN marks most points as noise | `eps` too small; try HDBSCAN |
| Anomaly detector fires on known-good cases | Rare but legitimate; you need labels |
| Clusters explained entirely by one obvious variable | You did an expensive `GROUP BY` |

That last row is worth checking early. If the segments turn out to be "large / medium / small customers," a business rule on size would have been clearer, cheaper, and stable.

---

## 7. Practical recipe

1. **Ask what decision the segmentation serves** (Module 1). "Understand our customers" is not a decision; "assign three distinct outreach playbooks" is — and it fixes $k=3$ before you begin.
2. **Scale features**, and log-transform anything spanning orders of magnitude.
3. **Test whether clusters exist at all** — gap statistic, or Hopkins statistic — before choosing $k$.
4. **Try more than k-means.** HDBSCAN and GMM make different assumptions; agreement across methods is evidence.
5. **Assess stability** by resampling. Report it.
6. **Profile the clusters** against variables not used to build them. External validation is the closest thing to a held-out score available.
7. **Visualize with UMAP for exploration and PCA for honesty**, and cluster in neither.
8. **Check whether a simple rule reproduces the segments.** If so, use the rule.
9. **Re-run periodically** and measure drift. Segment definitions that shift silently will break every downstream process that depends on them.

---

## 8. Further reading

- Hastie, Tibshirani & Friedman, *The Elements of Statistical Learning*, ch. 14 — PCA, k-means, and the gap statistic.
- Wattenberg, Viégas & Johnson (2016), "How to use t-SNE effectively" (Distill) — interactive, and the fastest way to internalize §4. Essential before anyone on your team presents one.
- Campello, Moulavi & Sander (2013) — HDBSCAN.
- von Luxburg (2010), "Clustering stability: an overview" — the theory behind §3.
- Aggarwal, *Outlier Analysis* — comprehensive on §5.
