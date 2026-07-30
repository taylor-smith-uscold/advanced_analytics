# Revision log

A consistency and accuracy pass over all 33 lesson files. Prose, structure, and
argument are otherwise unchanged — nothing was rewritten for style, and no
module was reorganized beyond the section-ordering fixes listed below.

27 files touched. Modules 03 (technical) and the syllabus were read and checked
but needed no changes.

---

## 1. Structural consistency

**Section numbering.** Three technical modules had orphaned sub-numbered
sections that broke the pattern used by the other thirteen.

| File | Was | Now |
|---|---|---|
| `05-scaling-regularization-technical` | `6a. Failure modes`, then `7. How it all fits together` (with the recipe buried inside it as a sub-heading), `8. Further reading` | `7. Failure modes`, `8. How it all fits together`, `9. Practical recipe` (promoted out of §8), `10. Further reading` |
| `06-cross-validation-technical` | `9a. Failure modes`, `10.`, `11.` | `10. Failure modes`, `11. Practical recipe`, `12. Further reading` |
| `07-model-evaluation-technical` | `8. A reporting checklist`, `8a. Failure modes`, `9. Further reading` | `8. Failure modes`, `9. Practical recipe: a reporting checklist`, `10. Further reading` |

Every technical module now ends **Failure modes → Practical recipe → Further
reading**, in that order.

All cross-references of the form "(Module *n*, §*k*)" were checked against the
new numbering. None pointed at a renumbered section, so none needed updating.

**Missing sections.**

- `01-problem-framing-technical` — `8. Framing checklist` renamed
  `8. Practical recipe`, matching the other fifteen.
- `07-model-evaluation-plain-language` — added the `Putting it all together`
  section (three-things-to-remember format). It was the only plain-language
  module without one.

**Subtitles.** All 33 files now open with
`*Module N — <register> register. <one-line orientation>*`. Previously five
technical and five plain-language files used a freestanding descriptive line
with no module or register label, and eleven plain-language files had the label
with no orientation line. Existing descriptive text was preserved; the eleven
bare ones received a new one-line clause.

---

## 2. Register parity

Concepts present in the technical register but absent from the plain-language
one. In each case the plain version already carried the *argument* — these add
the vocabulary a reader will meet elsewhere, or fill a genuine gap.

| Module | Added |
|---|---|
| 02 plain | Doubly robust estimation — one paragraph, framed as "right if either model is right" |
| 03 plain | Names the **winner's curse**. The mechanism was already explained in full; the term wasn't attached to it |
| 07 plain | Proper scoring rules — Brier score and log loss, and why you can't game them |
| 10 plain | **Stationarity and differencing.** The only substantive gap found: the technical version devotes a section to it, the plain version had nothing. New subsection in Part 2 |
| 11 plain | Names *family-wise error rate* and *false discovery rate* against the two procedures already described |
| 15 plain | Names *disparate treatment* and *disparate impact* against the distinction already drawn |

Everything else checked out. Keyword searches initially flagged ~12 more gaps
(SUTVA, sample ratio mismatch, intention-to-treat, target encoding, cyclical
features, covariate shift, concept drift, silhouette, and others) but reading
the sections showed each concept fully covered in plain words by design. Those
were left alone.

---

## 3. Accuracy

**Citations.**

- `01-technical` — "Rose & Riolo, *The ML Test Score* (Breck et al., 2017)" was
  garbled; there are no such authors. Corrected to Breck, Cai, Nielsen, Salib &
  Sculley (2017).
- `10-technical` — "Stefan Hyndman" corrected to **Rob** Hyndman.

The remaining ~75 references across the corpus were checked against author,
year, and title. No other errors found.

**Technical corrections.**

- `02-technical §5.1` — IPW was described as weighting "by $1/e$", which is only
  the treated-unit weight. Corrected to $1/e(Z)$ for treated and $1/(1-e(Z))$
  for controls, with a note that the weights explode near the boundary — the
  overlap problem arriving as variance rather than bias.
- `02-technical §5.4` — the first-stage $F > 10$ rule of thumb was stated
  without qualification. It is now understood to be far too permissive; the text
  now presents it as a warning rather than a clearance and points to
  weak-identification-robust inference (Anderson–Rubin).
- `13-technical §4` — the partial dependence formula was written
  $\hat f_j(x) = \frac1n\sum_i \hat f(x, x_{-i})$, which mismatches the index on
  the held-out covariates. Rewritten as a displayed equation with
  $x_{-j}^{(i)}$ and a sentence explaining the sweep.
- `07-technical §3` — average precision was described as "the area under the PR
  curve". It is deliberately *not* the trapezoidal area, since interpolating
  between PR operating points is optimistic. Clarified, with the recommendation
  to prefer AP over trapezoidal AUPRC.
- `16-technical §2` — the rounding rule's two examples were inconsistent with
  each other (±4 → 0.5 follows the stated tenth-of-half-width rule; ±0.2 → 0.05
  is 2.5× coarser than it). Second example corrected to 0.02 and the rule
  restated.
- `15-technical §4` — Sweeney's re-identification result was given as "a large
  majority" with no figure. Now gives the original 87% estimate and notes that
  later replications put it nearer two-thirds, which doesn't change the
  conclusion.
- `04-technical §2` — "with 20 features at 5% missing each, over half the rows
  go" replaced with the exact figure: $0.95^{20} \approx 36\%$ of rows survive.

**Checked and found correct** (a partial list, recorded so the next pass doesn't
redo the work): the optimism/covariance identity and PRESS formula (06); the
MDE scaling law, the $z$-bracket of 2.8, and CUPED's $(1-\rho^2)$ variance
reduction (03); the bagging variance decomposition and the $e^{-1}$ OOB
fraction (08); the ridge spectral filter, effective degrees of freedom, the
soft-thresholding solution, and the Hoerl–Kennard result (05); the shrinkage
factor and its limits (09); the AR(1) variance inflation $(1+\phi)/(1-\phi)$
and the count of 30 ETS models (10); the conformal quantile
$\lceil (n+1)(1-\alpha)\rceil / n$ and the 64% family-wise error rate at
$m=20$ (11); the cost-optimal threshold $C_{FP}/(C_{FP}+C_{FN})$ and the Wilson
interval worked example (07); the Shapley axioms and the uniqueness claim (13);
the PSI bands (14); the Kleinberg/Chouldechova statement of the incompatibility
result (15).
