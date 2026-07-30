# Signals in Time: Forecasting and Time Series

*Module 10 — technical register. For readers who have thought about spectra, stationarity, and autocorrelation.*

---

## 0. The one-paragraph version

Time series break the assumption underneath everything in Modules 5–8: observations are not independent draws. Successive points are correlated, which means effective sample size is far below row count, naive standard errors are too small, and random cross-validation is invalid. The structure this introduces is also the opportunity — trend, seasonality, and autocorrelation are exploitable signal. The organizing decomposition is level + trend + seasonality + remainder, and most classical methods are ways of extrapolating those components with different assumptions about how each evolves. Two facts govern practice. First, **seasonal-naive baselines are surprisingly hard to beat**, and any forecasting project that hasn't compared against one has not established that it works. Second, **prediction intervals from every standard method are too narrow**, because they account for innovation variance but not for parameter or model uncertainty; empirical coverage on backtests is the only trustworthy check.

---

## 1. What changes when data has a time index

| Assumption elsewhere in the course | What happens in time series |
|---|---|
| Rows are independent | Successive rows are correlated; effective $n \ll$ row count |
| Random CV splits are valid | Random splits train on the future; must use rolling origin (Module 6, §5) |
| The data-generating process is stable | Usually non-stationary — mean, variance, and structure drift |
| More data is unambiguously better | Older data may come from a different regime |
| Error is a single number | Error grows with horizon; a 1-step and 12-step forecast are different problems |

The autocorrelation point is worth quantifying. For an AR(1) process with correlation $\phi$, the variance of the sample mean is inflated by roughly $(1+\phi)/(1-\phi)$. At $\phi = 0.9$ that's a factor of 19 — your 1,000 daily observations carry about as much information as 50 independent ones. Any inference that ignores this will be dramatically overconfident.

---

## 2. Decomposition

$$y_t = \text{level}_t + \text{trend}_t + \text{seasonality}_t + \text{remainder}_t$$

(or multiplicatively, $y_t = L_t \cdot T_t \cdot S_t \cdot R_t$, which becomes additive under a log transform — the standard reason to log a series whose seasonal amplitude grows with its level).

**STL decomposition** (seasonal-trend using loess) is the workhorse: robust to outliers, allows the seasonal pattern to evolve, handles any seasonal period. Run it first on any new series. What it reveals:

- Whether the trend is linear, damped, or regime-changing
- Whether seasonal amplitude is constant (additive) or proportional (multiplicative)
- Whether the remainder is white noise or still structured — structure in the remainder means unmodeled signal
- Where the outliers and level shifts are

Multiple seasonalities are common in operational data — daily and weekly for web traffic, weekly and annual for retail — and require methods that support them (MSTL, TBATS, or Fourier terms as regressors).

---

## 3. Stationarity

A stationary series has constant mean, variance, and autocovariance structure. Most classical machinery assumes it, and most real series violate it.

**Differencing** ($\Delta y_t = y_t - y_{t-1}$) removes a stochastic trend; seasonal differencing ($y_t - y_{t-m}$) removes seasonality. The ADF and KPSS tests indicate how much differencing is needed — they test opposite null hypotheses and are best used together.

**Over-differencing is a real error**, not just wasted effort: it introduces negative autocorrelation into the residuals and inflates forecast variance. Difference the minimum necessary.

**Variance non-stationarity** is handled separately, by a log or Box-Cox transform. If the seasonal swings grow with the level — as they do for almost anything growing multiplicatively — transform before differencing.

### ACF and PACF

The autocorrelation function and its partial counterpart identify structure:

- **ACF cutting off after lag $q$**, PACF decaying → MA($q$)
- **PACF cutting off after lag $p$**, ACF decaying → AR($p$)
- Both decaying → mixed ARMA
- **Spikes at multiples of $m$** → seasonal structure
- Slow linear decay → non-stationary, difference first

Anyone who has read a power spectrum will find this familiar: you're inspecting the correlation structure to identify the generating process, and the seasonal spikes are the harmonics.

---

## 4. Methods, and when each is appropriate

### Baselines — establish these first

| Baseline | Forecast | Appropriate for |
|---|---|---|
| **Naive** | $\hat y_{t+h} = y_t$ | Random-walk-like series |
| **Seasonal naive** | $\hat y_{t+h} = y_{t+h-m}$ | Anything with seasonality |
| **Drift** | Last value plus average historical slope | Trending series |
| **Mean** | Historical average | Stable, non-trending |

**Seasonal naive is the bar.** It is genuinely hard to beat on many business series, and an enormous amount of forecasting effort produces models that don't. Compute it first, on the same backtest, and report your model's improvement over it — not just its absolute error.

### Exponential smoothing (ETS)

Weighted averages with geometrically decaying weights, in a state-space framework with components for error, trend, and season (each additive, multiplicative, or absent — 30 combinations, selectable by AICc).

**Damped trend** is worth knowing specifically: it flattens the extrapolated trend at long horizons, and empirically it is one of the most reliable forecasting methods that exists. Undamped linear trends extrapolated far ahead are a standard way to produce absurd forecasts.

### ARIMA

Models the autocorrelation structure directly: AR terms (regression on lags), I (differencing), MA terms (regression on past errors), plus seasonal counterparts. `auto.arima` and `pmdarima` search the order space by information criterion.

ETS and ARIMA overlap but aren't nested — some ETS models have no ARIMA equivalent and vice versa. Fit both, compare on backtests.

**ARIMAX / dynamic regression** adds exogenous predictors — price, promotion, weather, holidays — while retaining the error structure. This is usually where real gains come from, because most business series are driven by things you know about in advance.

### Regression with time features

Treat forecasting as supervised learning: lags, rolling aggregates, calendar features, Fourier terms for seasonality, then any model from Module 8.

**One critical constraint: trees cannot extrapolate** (Module 8, §1). A gradient-boosted model trained on a growing series will forecast a flat line at the historical maximum. The fix is to detrend first — model the trend explicitly, fit the tree to the residual, add the trend back — or to model differences rather than levels.

Strengths: multiple series in one model, many exogenous features, non-linear interactions. Weaknesses: no native uncertainty quantification, extrapolation failure, and it will happily use leaked future information if your feature windows are sloppy (Module 4, §5).

### Prophet

Decomposable additive model with piecewise-linear trend, Fourier seasonality, and holiday effects. Fast, robust to missing data, easy for non-specialists. Benchmarks generally show it underperforming ETS and ARIMA on accuracy while being far more convenient — a reasonable trade for many-series operational forecasting, a poor one when accuracy is the point.

---

## 5. Evaluation

### Backtesting

**Rolling-origin evaluation** (Module 6, §5): fit on data through time $t$, forecast $h$ ahead, score, roll forward. Two variants — expanding window (use all history) and sliding window (fixed length, better under regime change).

Critically: **evaluate at the horizon you actually need.** A model tuned on 1-step-ahead error may be poor at 12 steps, and operational decisions usually depend on the longer horizon. Report error by horizon, not averaged over horizons.

### Metrics

| Metric | Notes |
|---|---|
| **RMSE / MAE** | In series units; not comparable across series of different scale |
| **MAPE** | Scale-free but undefined at zero, unbounded near it, and asymmetric — penalizes over-forecasting more, biasing forecasts low. Widely used, and best avoided |
| **MASE** | MAE scaled by the in-sample naive forecast's MAE. Scale-free, defined at zero, interpretable: <1 beats naive. **The best default** |
| **Pinball loss** | For quantile forecasts; what you need if you're forecasting intervals rather than points |
| **Coverage** | Fraction of actuals inside the prediction interval. Should match the nominal level |

### Prediction intervals are too narrow

Standard intervals from ETS, ARIMA, and most software account only for innovation variance — they assume the model form and parameters are correct. They exclude parameter uncertainty and model uncertainty, both of which matter.

Empirically, nominal 95% intervals from standard methods often achieve 70–85% coverage.

**Measure coverage on your backtest.** If it's 80% when you claimed 95%, either widen the intervals empirically or use a method with honest coverage — quantile regression, or conformal prediction (Module 11), which gives distribution-free coverage guarantees and is well suited to this.

---

## 6. Practical complications

### Hierarchical forecasts

Forecasts at SKU, category, region, and total levels won't sum consistently if produced independently. **Reconciliation** (MinT optimal reconciliation being the current standard) adjusts them to cohere, and typically *improves* accuracy at every level by pooling information across the hierarchy — the same borrowing-strength logic as Module 9.

### Intermittent demand

Series with many zeros — spare parts, slow-moving SKUs — break standard methods and standard metrics. Croston's method and its variants exist for this; so do zero-inflated and count models. MAPE is undefined here, which is another argument for MASE.

### Regime changes

Structural breaks — a pandemic, a pricing change, a competitor's exit — mean older data comes from a different process. Options: sliding windows, explicit intervention variables, or truncating history. **Automated model selection will not detect these**; you have to know your domain.

### The forecast affects the outcome

If a demand forecast drives inventory, and inventory constrains sales, then your realized sales are censored by your own forecast. You never observe demand you couldn't serve. This is the feedback loop from Module 14, and it silently biases every retrain downward.

---

## 7. Failure modes

| Symptom | Likely cause |
|---|---|
| Model loses to seasonal naive | Common. Ship the baseline, and check whether the extra complexity is worth anything |
| Forecast is a flat line despite a clear trend | Tree-based model that can't extrapolate; detrend first |
| Excellent backtest, poor live performance | Random CV splits, or leaked features from the future |
| Intervals nominally 95%, coverage ~75% | Standard intervals omit parameter and model uncertainty |
| Long-horizon forecasts implausibly extreme | Undamped trend; use damping |
| Sudden accuracy collapse | Regime change; automated selection won't catch it |
| Sub-forecasts don't sum to the total | No reconciliation step |
| MAPE looks great, business impact doesn't | Metric asymmetry biasing forecasts low, or near-zero denominators |

---

## 8. Practical recipe

1. **Plot the series.** Full history, then by year overlaid, then STL decomposition. Most of what you need is visible.
2. **Establish seasonal-naive on a proper backtest.** This is your bar.
3. **Handle variance first** — log or Box-Cox if seasonal amplitude grows with level.
4. **Fit ETS and auto-ARIMA.** Fast, strong, and often sufficient.
5. **Add known drivers** — promotions, prices, holidays, capacity — via dynamic regression. This is usually where the real gain is.
6. **Consider ML approaches** when you have many related series or many exogenous features; detrend first.
7. **Backtest with rolling origin**, reporting error by horizon and MASE against the naive baseline.
8. **Check interval coverage empirically.** Widen or use conformal methods if it's short.
9. **Reconcile** if you forecast at multiple aggregation levels.
10. **Monitor for regime change**, and plan the retraining and truncation policy in advance (Module 14).

---

## 9. Further reading

- Hyndman & Athanasopoulos, *Forecasting: Principles and Practice* — free online, the standard reference, with R and Python companions. Chapters 3 (baselines and evaluation), 6 (decomposition), 8 (ETS), 9 (ARIMA), 11 (hierarchical).
- Makridakis, Spiliotis & Assimakopoulos on the M4 and M5 competitions — large-scale empirical evidence on what actually works; the finding that combinations and simple methods perform strongly is worth internalizing.
- Wickramasuriya, Athanasopoulos & Hyndman (2019) — MinT optimal reconciliation.
- Stefan Hyndman's blog posts on why MAPE misbehaves — short and convincing.
- Petropoulos et al. (2022), "Forecasting: theory and practice" — a broad survey of current methods.
