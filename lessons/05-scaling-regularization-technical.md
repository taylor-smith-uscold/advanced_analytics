# Conditioning, Priors, and Cutoffs: Scaling and Regularization in Linear Models

*A guide for someone who already thinks in units, normal modes, and Lagrange multipliers.*

---

## 0. The one-paragraph version

Fitting a linear model is solving an inverse problem. Real design matrices are nearly degenerate, so the naive least-squares solution is badly conditioned: tiny changes in the data produce huge changes in the fitted parameters. **Feature scaling** fixes the part of that problem caused by using incompatible units. **Regularization** fixes the part caused by genuine near-degeneracy in the data, by adding an energy penalty on the parameters — equivalently, by imposing a prior, equivalently by imposing a constraint via a Lagrange multiplier. That multiplier, $\lambda$, is a **hyperparameter**: a knob you cannot read off the training data, so you set it by out-of-sample measurement (cross-validation). The three ideas are not independent topics. The penalty is only meaningful once the features are scaled, and the scaling choice silently determines what the penalty means.

---

## 1. Setup and notation

We have $n$ observations, each with $p$ features. Stack them into a design matrix $X \in \mathbb{R}^{n\times p}$ and targets $y \in \mathbb{R}^n$. The linear model is

$$\hat{y} = X\beta + \beta_0$$

and ordinary least squares (OLS) minimizes the residual sum of squares

$$\mathcal{L}_{\text{OLS}}(\beta) = \lVert y - X\beta \rVert_2^2 ,$$

with the familiar solution $\hat\beta = (X^\top X)^{-1} X^\top y$.

Two objects will do most of the work in this document.

**The singular value decomposition.** Write $X = U D V^\top$, with $D = \mathrm{diag}(d_1 \ge d_2 \ge \dots \ge d_p)$. The columns of $V$ are directions in *feature space* — the normal modes of your data. The $d_j$ tell you how much the data actually varies along each mode. This is the same decomposition you'd use to find principal axes of an inertia tensor.

**The condition number.** $\kappa = d_1/d_p$. It measures how elongated the data ellipsoid is. It is the single most useful diagnostic number in this whole subject.

---

## 2. Feature scaling

### 2.1 The dimensional-analysis argument

Suppose you are predicting the period of some laboratory oscillator from features: length in metres ($\sim 10^{-1}$), mass in grams ($\sim 10^{2}$), drive frequency in Hz ($\sim 10^{4}$), and a dimensionless damping ratio ($\sim 10^{-2}$).

Any algorithm that computes a Euclidean distance between two samples,

$$\lVert x_i - x_j\rVert_2^2 = \sum_k (x_{ik}-x_{jk})^2,$$

is adding metres-squared to grams-squared to hertz-squared. This is not a physical quantity. It is dimensionally incoherent, and its numerical value is dominated by whichever feature happens to carry the largest numbers — which is a fact about your choice of units, not about nature. Switch mass from grams to kilograms and the "distance" between two samples changes, so a $k$-nearest-neighbours model returns different neighbours. Nothing about the system changed.

This affects everything that has a notion of length in feature space: $k$-NN, $k$-means, SVMs with RBF kernels, PCA, and any penalized regression. It does *not* affect decision trees and their ensembles, which only ever ask "is $x_k > t$?" — a question invariant under any monotone rescaling of a single feature.

What you are really doing when you standardize is **non-dimensionalization**, exactly as in fluid dynamics when you construct the Reynolds number, or in scattering when you measure lengths in units of the Bohr radius. You divide each quantity by a characteristic scale drawn from the problem itself, so that all remaining numbers are $O(1)$ and comparisons between them are meaningful.

### 2.2 The conditioning argument

Now a subtler point, and one worth being precise about, because a lot of tutorials get it wrong.

**Plain OLS is equivariant under rescaling of features.** If you replace $X \to XS$ for an invertible diagonal $S$, the fitted coefficients become $S^{-1}\hat\beta$, and the *predictions are identical*. So in exact arithmetic, scaling does not change what OLS predicts. Anyone who tells you unregularized OLS "needs" scaling for statistical reasons is overstating it.

You should still scale, for two reasons.

**Numerical conditioning.** Forming $X^\top X$ squares the condition number: $\kappa(X^\top X) = \kappa(X)^2$. If your features span six orders of magnitude in scale, you can lose a dozen digits of precision, and the matrix may be numerically singular even when it is mathematically invertible. (This is the same reason you never solve a stiff linear system by explicitly inverting the matrix.)

**Optimization geometry.** Gradient descent on a quadratic loss is motion in an anisotropic potential well. The Hessian is $H = 2X^\top X$, with eigenvalues $2d_j^2$. Gradient descent is stable only if the step size satisfies $\eta < 2/\lambda_{\max}(H)$, but convergence along the softest direction proceeds at rate $\sim(1 - \eta\lambda_{\min})$. The number of iterations therefore scales like the condition number $\kappa^2$.

Physically: you have coupled normal modes with wildly different stiffnesses, you're forced to take timesteps set by the stiffest mode, and you have to wait for the softest mode to relax. It's a stiff ODE. The optimizer zig-zags across a narrow valley instead of running down it. Standardizing the features makes the well closer to isotropic, and the descent path close to a straight line.

This is also why the *learning rate* is a hyperparameter whose good value depends on your scaling choice. Change your units and you must retune $\eta$. Standardize, and $\eta \sim 10^{-2}$ tends to work across problems — which is a large part of why standardization became routine.

### 2.3 The methods, and when each is right

| Transform | Formula | Use when |
|---|---|---|
| Standardization (z-score) | $(x - \mu)/\sigma$ | Default. Feature is roughly unimodal; you want zero mean, unit variance. |
| Min–max | $(x - x_{\min})/(x_{\max}-x_{\min})$ | You need a bounded range (image pixels, bounded physical quantities). Sensitive to outliers. |
| Robust scaling | $(x - \mathrm{med})/\mathrm{IQR}$ | Heavy tails, outliers, contaminated detector channels. |
| Log transform | $\log(x + c)$ | Positive, multiplicatively-varying, or power-law quantities: energies, fluxes, cross-sections, particle counts. |
| Unit norm (per row) | $x_i / \lVert x_i\rVert$ | Only the *direction* of the feature vector matters — spectra where overall intensity is a nuisance. |

The log transform deserves emphasis for physical data. If a quantity spans decades and its distribution is roughly log-normal or a power law, standardizing it in linear space produces a feature where 99% of the samples sit in a tiny sliver near zero and a handful of points sit at $+30\sigma$. Take the log *first*, then standardize. You are choosing a coordinate in which the variable is well-behaved, and that is a modelling decision, not a preprocessing detail.

### 2.4 The thing everyone gets wrong: fit on train only

Compute $\mu$ and $\sigma$ **from the training set only**, then apply those same numbers to validation and test data.

If you standardize using statistics from the full dataset, information about the test set has leaked into your training procedure, and your held-out error is no longer an unbiased estimate of generalization error. It is exactly the failure mode a blind analysis is designed to prevent: you have looked at the data you were going to use to check yourself.

In practice this means putting the scaler *inside* your cross-validation loop, not before it — one reason `scikit-learn`'s `Pipeline` exists.

---

## 3. Why regularization is necessary

### 3.1 Near-degeneracy makes the inverse problem ill-posed

Consider what happens when two features are strongly correlated — say you recorded both a temperature in Celsius and (nearly) the same temperature from a second sensor. Then $X^\top X$ has a small eigenvalue: a direction $v$ in feature space along which the data barely varies.

Write the OLS solution in the SVD basis:

$$\hat\beta_{\text{OLS}} = \sum_{j=1}^{p} \frac{u_j^\top y}{d_j}\, v_j .$$

Every mode with a small $d_j$ contributes with a large $1/d_j$ prefactor. The noise component of $y$ along $u_j$ is amplified by $1/d_j$. The fit responds to a direction the data cannot resolve, and it responds violently. Concretely: two enormous coefficients of opposite sign on the two temperature sensors, nearly cancelling. The model has learned "the difference between the two thermometers," which is pure noise, and it is relying on that difference heavily.

This is the standard pathology of an ill-posed inverse problem, and physicists have a name for the standard cure: **Tikhonov regularization**. Ridge regression *is* Tikhonov regularization. You have probably already met it in image deconvolution or in unfolding a detector response.

### 3.2 Bias–variance: paying for stability

Decompose the expected squared error at a point:

$$\mathbb{E}\big[(y - \hat{f}(x))^2\big] = \underbrace{\sigma^2}_{\text{irreducible}} + \underbrace{\big(\mathbb{E}[\hat f] - f\big)^2}_{\text{bias}^2} + \underbrace{\mathrm{Var}[\hat f]}_{\text{variance}} .$$

OLS is unbiased (given a correctly specified model), and among unbiased linear estimators it has minimum variance. That sounds optimal until you notice that *unbiasedness was never the goal*. Prediction error is the goal. Accepting a little bias in exchange for a large reduction in variance is a good trade whenever $\kappa$ is large — and there is a theorem (Hoerl–Kennard) guaranteeing that *some* $\lambda > 0$ strictly improves expected squared error over OLS.

The analogy: an unbiased estimator with enormous variance is a measurement apparatus with no systematic error and terrible resolution. You would happily accept a small, well-understood systematic to cut your statistical error by a factor of five.

---

## 4. The penalties

All three are the same construction with a different norm:

$$\hat\beta = \arg\min_\beta \Big\{ \lVert y - X\beta\rVert_2^2 + \lambda \, \Omega(\beta) \Big\}.$$

$\Omega$ is a penalty on the size of the parameters — an energy cost for a large model. $\lambda$ sets the exchange rate between fitting the data and keeping the parameters small.

### 4.1 Ridge (L2): $\Omega = \lVert\beta\rVert_2^2$

**Closed form.** $\hat\beta_{\text{ridge}} = (X^\top X + \lambda I)^{-1}X^\top y$. You have added $\lambda$ to every eigenvalue of $X^\top X$, lifting it away from zero. The matrix is now invertible even when $p > n$.

**Spectral filtering.** In the SVD basis,

$$\hat\beta_{\text{ridge}} = \sum_j \frac{d_j}{d_j^2 + \lambda}\, (u_j^\top y)\, v_j .$$

Compare with the OLS coefficient $1/d_j$. Ridge multiplies mode $j$ by the shrinkage factor

$$\frac{d_j^2}{d_j^2+\lambda} .$$

This is a low-pass filter in mode space, with $\sqrt{\lambda}$ playing the role of a cutoff singular value. Modes with $d_j \gg \sqrt\lambda$ pass essentially untouched; modes with $d_j \ll \sqrt\lambda$ are suppressed quadratically. Ridge does not treat all directions equally — it leaves the well-measured directions alone and damps the ones the data cannot resolve. That is precisely the behaviour you want, and it is worth staring at until it feels obvious.

The **effective degrees of freedom** follow immediately:

$$\mathrm{df}(\lambda) = \sum_j \frac{d_j^2}{d_j^2+\lambda},$$

running from $p$ at $\lambda=0$ down to $0$ as $\lambda\to\infty$. This is a continuous parameter count. The model doesn't lose parameters as you regularize; it loses *resolution*, mode by mode.

**Mechanical reading.** The objective is a quadratic data-fidelity term plus $\lambda\lVert\beta\rVert^2$ — a harmonic restoring force pulling $\beta$ toward the origin. The solution is the equilibrium where the "data spring" and the "prior spring" balance. Increasing $\lambda$ stiffens the prior spring.

**Bayesian reading.** Put a Gaussian prior $\beta \sim \mathcal{N}(0, \tau^2 I)$ and Gaussian noise $\sigma^2$. The log-posterior is

$$\log p(\beta \mid y) = -\frac{1}{2\sigma^2}\lVert y - X\beta\rVert^2 - \frac{1}{2\tau^2}\lVert\beta\rVert^2 + \text{const},$$

so the MAP estimate is exactly ridge with $\lambda = \sigma^2/\tau^2$. The regularization strength is the ratio of noise variance to prior variance — noisier data, or a tighter prior belief, means more shrinkage. This is the cleanest way to understand what $\lambda$ *is*.

### 4.2 Lasso (L1): $\Omega = \lVert\beta\rVert_1$

Replace the sum of squares with the sum of absolute values. No closed form (the objective is non-differentiable at $\beta_j = 0$), but it's convex and coordinate descent solves it quickly.

The consequence is qualitative, not quantitative: **the lasso sets coefficients exactly to zero**. It performs variable selection as part of the fit.

**Why the corners matter.** Use the constrained form. By Lagrangian duality, the penalized problem is equivalent to

$$\min_\beta \lVert y-X\beta\rVert_2^2 \quad \text{subject to} \quad \Omega(\beta) \le t,$$

with $\lambda$ the Lagrange multiplier conjugate to the budget $t$. Now picture the geometry in two dimensions: the level sets of the RSS are ellipses centred on $\hat\beta_{\text{OLS}}$, and the solution is where the smallest such ellipse first touches the feasible region.

- For L2 the feasible region is a **disc**. Its boundary is smooth, so a generic ellipse touches it at a generic point with both coordinates nonzero.
- For L1 it is a **diamond**, with vertices on the axes. A generic ellipse expanding outward is quite likely to hit a *corner* first — and at a corner, one coordinate is exactly zero.

Sparsity is a consequence of the non-smoothness of the L1 ball. In higher dimensions the diamond has low-dimensional edges and faces everywhere, and hitting one means zeroing out a whole set of coefficients.

**In one dimension** (orthonormal $X$) the two penalties have explicit forms that make the difference vivid:

$$\hat\beta^{\text{ridge}}_j = \frac{\hat\beta_j}{1+\lambda}, \qquad \hat\beta^{\text{lasso}}_j = \mathrm{sign}(\hat\beta_j)\big(|\hat\beta_j| - \lambda/2\big)_+ .$$

Ridge scales everything down proportionally. Lasso translates everything toward zero by a fixed amount and clips at zero — soft thresholding, the same operation used in wavelet denoising.

**Bayesian reading.** L1 is the MAP estimate under a **Laplace** prior $p(\beta_j) \propto e^{-|\beta_j|/b}$. The Laplace density has a sharp peak at zero and heavier tails than a Gaussian. You are asserting a belief that most coefficients are negligible but a few may be large — which is exactly the situation in a high-dimensional screening problem with a few real effects.

**Where it struggles.** Given a group of highly correlated features, the lasso tends to pick one arbitrarily and zero the rest. If two sensors measure the same quantity, that's tolerable; if you're trying to identify *which* physical variables matter, it is misleading, and the choice is unstable under resampling. Also, when $p > n$, the lasso selects at most $n$ variables.

### 4.3 Elastic Net: the convex combination

$$\Omega(\beta) = \alpha\lVert\beta\rVert_1 + \frac{1-\alpha}{2}\lVert\beta\rVert_2^2 .$$

Two hyperparameters: $\lambda$ for overall strength, $\alpha \in [0,1]$ for the mix ($\alpha=1$ is lasso, $\alpha=0$ is ridge).

The constraint region is a diamond with rounded-out faces: it still has corners (so you keep sparsity) but is strictly convex along the faces (so you keep ridge's stability). The practical payoff is the **grouping effect**: correlated predictors receive *similar* coefficients and tend to enter or leave the model together, rather than one being chosen arbitrarily.

The degeneracy language is apt here. A set of perfectly correlated features is a flat direction of the loss — the data cannot distinguish among the infinitely many coefficient vectors that share out the total effect. Pure L1 breaks that degeneracy arbitrarily; the strictly convex L2 component lifts it in a symmetric way, selecting the solution that spreads weight evenly. Use elastic net when $p$ is large, features are correlated in blocks, and you want a sparse model you can trust.

---

## 5. Where scaling and regularization collide

This is the most important connection in the document, and it is the one most often left implicit.

**A penalty on $\lVert\beta\rVert$ is not scale-invariant.** Recall that under $X\to XS$, OLS coefficients transform as $\beta \to S^{-1}\beta$ with predictions unchanged. But the penalty $\lambda\lVert S^{-1}\beta\rVert^2$ is *not* the same function — so ridge and lasso solutions **do** change under rescaling, and their predictions change too.

Concretely: express a length in millimetres instead of metres and its coefficient shrinks by $1000$. Now the penalty barely notices that coefficient, so that feature is effectively unregularized. Meanwhile a feature measured in units that make its coefficient large gets crushed. **Your choice of units becomes a choice of prior**, applied inconsistently and unintentionally across features.

Standardizing first is what makes the penalty coherent: after standardization, all coefficients are "change in $y$ per one-standard-deviation change in that feature," which is a comparable quantity across features, and a single scalar $\lambda$ applies the same prior to all of them.

Two corollaries:

- **Never penalize the intercept.** $\beta_0$ sets the overall level of $y$; shrinking it toward zero asserts that $y$ is near zero, which is an arbitrary claim about your choice of origin. Standard implementations exclude it. Centering the features (and often $y$) decouples the intercept from the rest of the problem entirely.
- **If you deliberately want unequal shrinkage** — say, one feature is a well-established physical predictor and the rest are speculative — do it explicitly with a generalized penalty $\beta^\top \Gamma^\top \Gamma \beta$ or per-feature weights, not by accident through your unit choices.

---

## 6. Hyperparameter tuning

### 6.1 What makes a parameter a *hyper*parameter

$\beta$ is fitted by minimizing the training objective. $\lambda$ cannot be: the training objective is monotonically improved by $\lambda \to 0$, which returns you to OLS. The quantity $\lambda$ controls is *generalization*, and generalization is not visible in the training data. So it must be set by measuring performance on data the fit has not seen.

The cleanest analogy is a **renormalization scale or cutoff**. $\sqrt\lambda$ is a cutoff in singular-value space (§4.1): it separates the modes you trust from the modes you discard as unresolved. Where to put the cutoff is not determined by the theory — it's determined by where your data's resolution actually gives out, which you have to measure.

The same logic covers learning rate, network depth, number of trees, kernel bandwidth, and the polynomial degree in a basis expansion.

### 6.2 Cross-validation

$k$-fold CV: partition the training data into $k$ folds; for each fold, fit on the other $k-1$ and evaluate on the held-out one; average. Repeat over a grid of $\lambda$ and take the minimizer. $k=5$ or $10$ is standard — small $k$ gives higher bias (each fit uses less data), large $k$ gives higher variance and more compute.

Practical notes:

- **Search $\lambda$ on a log grid.** $\lambda$ is a ratio of variances (§4.1) and matters multiplicatively. Something like `np.logspace(-4, 4, 50)`. Searching linearly wastes almost all your evaluations on one decade.
- **The scaler goes inside the fold.** Refit $\mu,\sigma$ on each training split. Otherwise you leak, per §2.4.
- **The CV curve is noisy near its minimum.** The *one-standard-error rule* — take the largest $\lambda$ whose CV error is within one standard error of the best — is a defensible convention: when several models are statistically indistinguishable, prefer the simpler one. It's Occam with an error bar.
- **Respect the structure of your data.** Time series need forward-chaining splits, not random ones, or you are training on the future. Grouped data (multiple measurements per specimen, per run, per detector) needs group-wise splits, or near-duplicates straddle the split and you measure interpolation instead of generalization.
- **Nested CV** if you need an honest estimate of the tuned model's performance: an inner loop selects $\lambda$, an outer loop evaluates. Selecting on the same data you report is a subtle form of overfitting — you have optimized over the noise in the validation estimate.

### 6.3 Search strategies

**Grid search** is exhaustive and fine for one or two hyperparameters — ridge and lasso qualify.

**Random search** beats grid search once you have more than a few dimensions, for a reason that's easy to state: usually only a couple of hyperparameters actually matter, and a grid wastes its budget evaluating the irrelevant ones repeatedly at the same values of the important ones. With $n$ random draws you get $n$ distinct values along *every* axis.

**Bayesian optimization** (Gaussian-process or TPE-based) builds a surrogate model of the validation-error surface and samples where the expected improvement is largest. Worth it when a single fit is expensive; overkill for ridge on a laptop.

**Warm-started paths.** For lasso and elastic net, algorithms like LARS or coordinate descent with warm starts compute the entire solution path $\hat\beta(\lambda)$ for a whole grid at roughly the cost of a single fit — the solution at one $\lambda$ initializes the next. Plotting the coefficient paths (each $\beta_j$ against $\log\lambda$) is a genuinely informative diagnostic: you see the order in which variables enter, and how stable that order is.

---

## 6a. Failure modes

| Symptom | Likely cause |
|---|---|
| Enormous coefficients of opposite sign on two features | Near-collinearity; the model is fitting the difference between near-duplicates. Regularize |
| Gradient descent oscillates or converges glacially | Ill-conditioned Hessian from unscaled features; standardize |
| Ridge/lasso results change when you change units | Expected — the penalty isn't scale-invariant. You forgot to standardize first |
| One feature is effectively unpenalized | Its units make its coefficient tiny; standardize |
| Lasso picks a different feature on every resample | Correlated group; use elastic net |
| CV curve is flat across orders of magnitude of $\lambda$ | Regularization isn't binding; the problem may be well-conditioned already |
| Best $\lambda$ sits at the edge of your grid | Extend the grid — the optimum is outside it |
| Intercept shrunk toward zero | You penalized it; exclude it |
| Test score much worse than CV score | Scaler fitted outside the fold (Module 6) |

---

## 7. How it all fits together

$$\text{units} \;\longrightarrow\; \text{scaling} \;\longrightarrow\; \text{meaning of } \Omega(\beta) \;\longrightarrow\; \text{choice of } \lambda \;\longrightarrow\; \text{effective df} \;\longrightarrow\; \text{bias--variance}$$

- **Conditioning is the common thread.** Bad units and genuine collinearity both show up as a large $\kappa$. Scaling removes the artificial contribution; regularization handles the real one.
- **Every penalty is a prior.** L2 ↔ Gaussian, L1 ↔ Laplace, elastic net ↔ their mixture. $\lambda$ is a variance ratio.
- **Every penalty is a constraint.** $\lambda$ is the Lagrange multiplier dual to a budget on $\lVert\beta\rVert$; the geometry of the feasible set determines whether you get shrinkage (smooth boundary) or sparsity (corners).
- **Regularization is a cutoff.** Ridge is an explicit low-pass filter on the data's normal modes, with $\sqrt\lambda$ as the cutoff. Effective degrees of freedom is the continuous parameter count that results.
- **Tuning is measurement.** The cutoff isn't given by theory, so you measure it out-of-sample — with the same discipline about not peeking that you'd apply to a blind analysis.

### A workable default recipe

1. Look at each feature's distribution. Log-transform the ones spanning decades.
2. Build a pipeline: `StandardScaler` → `ElasticNet` (or `Ridge` if you don't need sparsity).
3. Cross-validate over a log grid in $\lambda$, and a coarse grid in $\alpha$ if using elastic net, with the scaler inside the folds.
4. Check the condition number of the scaled design matrix. If $\kappa \gtrsim 10^3$, expect regularization to matter a lot and expect L1's variable selection to be unstable.
5. Report performance on a test set that was never involved in step 3.

---

## 8. Further reading

- Hastie, Tibshirani & Friedman, *The Elements of Statistical Learning*, ch. 3 — the standard reference; the SVD treatment of ridge in §3.4.1 is where the spectral-filter picture above comes from.
- Zou & Hastie (2005), "Regularization and variable selection via the elastic net" — the grouping effect, derived properly.
- Bergstra & Bengio (2012), "Random search for hyper-parameter optimization" — the argument in §6.3, with experiments.
- Hansen, *Discrete Inverse Problems* — Tikhonov regularization and L-curves, written for people who came to this from physics rather than statistics.
