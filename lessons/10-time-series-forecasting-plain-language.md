# Forecasting: A Plain-Language Guide to Time Series

*Module 10 — plain-language register. How to forecast, and how to tell whether the forecast is any good.*

---

## The short version

Data with a time index breaks the main assumption behind everything in Modules 5–8: that each row is an independent observation. Today looks like yesterday. December looks like last December. That connection is both a problem and an opportunity.

The problem: your thousand daily observations don't contain a thousand observations' worth of information, and random train/test splitting means training on the future to predict the past.

The opportunity: trend and seasonality are real, learnable patterns.

Two things to carry out of this module:

1. **"Same as last year" is a shockingly hard baseline to beat.** A large fraction of forecasting projects produce something worse than this and never find out, because nobody computed it.
2. **Every standard forecasting tool gives prediction ranges that are too narrow.** If yours says 95%, the truth is probably closer to 75%. Check it, don't trust it.

---

## Part 1: What's different about time data

| Usually true | With time series |
|---|---|
| Each row is independent | Consecutive rows are closely related |
| Random train/test splits work | Random splits train on the future — must split by time |
| More history is better | Old data may come from a different era |
| The world is stable | It isn't; things drift and occasionally break |
| One error number describes the model | Error grows with how far ahead you're predicting |

That last one matters more than people expect. Predicting tomorrow and predicting next quarter are **different problems**, and a model that's excellent at one can be poor at the other. Always evaluate at the horizon you actually need to act on.

---

## Part 2: Break the series into parts

Almost any series is usefully split into four pieces:

- **Level** — where it sits right now
- **Trend** — which way it's heading
- **Seasonality** — repeating patterns (weekly, annual, monthly)
- **Everything else** — noise, one-offs, and anything you haven't modeled

Standard tools do this automatically (look up "STL decomposition" — one line of code in R or Python). **Run it on any new series before doing anything else.** It shows you:

- Whether the trend is steady, accelerating, or has broken
- Whether the seasonal pattern is fixed in size or grows as the series grows
- Whether there's leftover structure in the remainder — which means you're missing something
- Where the outliers and sudden shifts are

### One transformation that matters

If the seasonal swings get *bigger* as the series grows — December is +200 when sales are 1,000, and +2,000 when sales are 10,000 — then take the log of the series first. That converts "swings proportional to size" into "swings of constant size," which nearly every method handles better.

This is common. Anything growing multiplicatively behaves this way.

### Series that won't sit still

Most forecasting methods work best on a series that is, loosely, *statistically settled*: no persistent drift, roughly constant amount of wobble, patterns that mean the same thing in 2019 and 2026. The technical word is **stationary**, and almost no real business series is.

The two standard remedies are worth recognizing when you see them in someone's method write-up:

- **Differencing** — modeling the change from one period to the next rather than the level itself. A series that climbs steadily isn't settled, but its month-to-month *changes* often are. The seasonal version subtracts the same month last year, which strips out an annual pattern the same way.
- **Logging** — the transformation described just above, which handles swings that grow with the level.

Two things to watch for. First, differencing more than the minimum needed is a real error, not just wasted effort: it injects artificial jitter and makes forecasts less certain rather than more. Second, differencing changes what the model is predicting, so the forecasts have to be converted back to levels before anyone reads them — a step that occasionally goes wrong silently.

The practical version: your tooling will usually decide how much differencing to apply automatically, and it's usually right. What you should insist on is that someone plotted the series first and can say in words why it needed the treatment it got.

### Watch for multiple seasonal patterns

Web traffic has a daily rhythm *and* a weekly one. Retail has weekly *and* annual. Many simple tools only handle one, and will quietly do a poor job. Check whether your series has more than one, and pick a method that supports it.

---

## Part 3: Always start with the dumb baselines

Before any modeling, compute these:

| Baseline | What it predicts |
|---|---|
| **Naive** | Tomorrow = today |
| **Seasonal naive** | Next December = last December |
| **Drift** | Today's value plus the average historical slope |
| **Average** | The historical mean |

**Seasonal naive is the one to beat**, and it's genuinely hard. It captures seasonality perfectly and adapts to the recent level automatically.

An uncomfortable number of forecasting projects deliver models that lose to it. The projects don't find out because nobody ran the comparison — the model is compared only against "what we did before," or against nothing at all.

**Report your model's improvement over seasonal naive, not just its error.** If the improvement is small, ship the baseline. It's simpler, faster, never breaks, and needs no maintenance.

---

## Part 4: The methods worth knowing

### Exponential smoothing

Weighted averages where recent observations count more, with separate handling for level, trend, and seasonality. Decades old, extremely well tested, and still competitive with anything.

**One feature worth asking for by name: a *damped* trend.** This means the projected trend flattens out as you look further ahead, rather than continuing forever in a straight line. It's more realistic — growth rates don't persist indefinitely — and it's one of the most reliably good forecasting methods in existence. Straight-line extrapolation of a trend twelve months out is a standard way to produce a forecast that makes you look silly.

### ARIMA

Models the relationship between a value and its recent history directly. Automatic tools (`auto.arima` in R, `pmdarima` in Python) will search the options for you.

Fit both this and exponential smoothing and compare — they're good at slightly different things and neither dominates.

**The version that usually wins: adding known drivers.** Promotions, price changes, holidays, marketing spend, store openings. Most business series are driven substantially by things you already know about in advance, and putting them in the model is usually where the real accuracy gain comes from — much more than choosing a fancier method.

### Machine learning approaches

You can treat forecasting as ordinary prediction: build features from lags ("sales 7 days ago"), rolling averages, and calendar effects, then use gradient boosting from Module 8.

**One critical warning: trees cannot extrapolate.** A boosted model trained on three years of growth will forecast a **flat line**. It can only predict values it has seen before.

The fix: model the trend separately, have the tree predict what's left over, then add the trend back. Or predict *changes* rather than *levels*. If you skip this, you'll get a confident, well-validated, completely useless forecast.

ML approaches shine when you have many related series (thousands of SKUs) or many external drivers. They're weaker at giving honest uncertainty ranges.

### Prophet

Facebook's forecasting tool. Easy to use, handles missing data and holidays gracefully, good for non-specialists.

Benchmarks generally show it's **less accurate** than exponential smoothing or ARIMA, while being much more convenient. That's a fine trade when you're forecasting a thousand series operationally and nobody has time to tune. It's a poor trade when accuracy is the whole point.

---

## Part 5: Testing a forecast properly

### Roll forward through time

Fit on data through March, predict April, score it. Fit through April, predict May, score it. Keep rolling.

This mirrors how the model will actually be used and is the only valid way to evaluate a forecast. **Never** use random train/test splits here.

Two versions: use all history each time (good if the world is stable) or a fixed recent window (better if things change).

**Report error separately by horizon** — one month out, three months out, twelve months out. Averaging across horizons hides the fact that your model is fine near-term and useless at the horizon your planners actually use.

### Which error measure

**Avoid MAPE** (mean absolute percentage error), despite its popularity. It breaks when values are near zero, and it penalizes over-forecasting more than under-forecasting — so optimizing it systematically biases your forecasts low. That's a real business cost hiding inside a metric choice.

**Use MASE instead.** It compares your error to the naive forecast's error. Below 1 means you beat naive; above 1 means you didn't. It works with zeros, it's comparable across series, and it builds the baseline comparison into the number itself.

### Check your uncertainty ranges — they're probably wrong

Every standard method produces prediction intervals. **They are consistently too narrow.**

The reason: they account for the randomness the model expects, but not for the fact that the model itself might be wrong or its settings mis-estimated. Both matter, sometimes a lot.

In practice, intervals labeled 95% often contain the actual value only 70–85% of the time.

**Check it on your backtest.** Count how often reality landed inside your range. If it's 78% when you promised 95%, say so, and either widen the ranges or use a method with honest coverage (Module 11 covers conformal prediction, which is designed exactly for this).

Planning inventory or capacity on intervals that are 20 points too narrow is expensive, and it's invisible until it isn't.

---

## Part 6: Complications you'll hit

**Forecasts that don't add up.** Forecast each product separately and each region separately, and the numbers won't reconcile with the total. There are standard reconciliation methods that fix this — and they usually make every level *more* accurate, because information gets shared across the hierarchy (the same borrowing-strength idea as Module 9).

**Lots of zeros.** Spare parts and slow-moving items sell nothing most weeks. Standard methods handle this badly and MAPE breaks completely. Look up Croston's method or use count-based models.

**The world changed.** Pandemics, pricing overhauls, a competitor leaving. Old data now describes a different world. Options are to use only recent data, or explicitly flag the break in the model. **Automated tools will not notice this** — you have to.

**Your forecast changes the outcome.** If your demand forecast sets inventory, and low inventory caps sales, then next year you'll train on the sales you *allowed*, not the demand that existed. The forecast becomes self-fulfilling and drifts steadily downward. This is a real, common, and expensive trap (more in Module 14).

---

## Part 7: Warning signs

| What you see | What's probably happening |
|---|---|
| Your model loses to "same as last year" | Very common. Consider shipping the baseline |
| Forecast is flat despite an obvious trend | Tree-based model that can't extrapolate |
| Great in testing, bad in production | Random splits, or features that peeked at the future |
| Reality falls outside your ranges too often | Standard intervals are too narrow — check coverage |
| Long-range forecast is wildly high or low | Undamped trend running away; use damping |
| Accuracy suddenly collapsed | Something changed in the world |
| Regional forecasts don't sum to the national one | Need reconciliation |
| MAPE looks great, planners are unhappy | The metric is biasing your forecasts low |

---

## Putting it all together

**The recipe:**

1. **Plot the series** — full history, years overlaid, then a decomposition. Most insight is visual.
2. **Compute seasonal naive** on a proper rolling backtest. That's your bar.
3. **Log the series** if seasonal swings grow with the level.
4. **Fit exponential smoothing and auto-ARIMA.** Fast, strong, often enough.
5. **Add the drivers you already know about** — promotions, prices, holidays. Usually the biggest win available.
6. **Consider ML** if you have many series or many external variables — and detrend first.
7. **Backtest by rolling forward**, reporting error by horizon, using MASE.
8. **Check whether your prediction ranges actually cover** what happened.
9. **Reconcile** if you forecast at multiple levels.
10. **Plan for regime changes** — when to retrain, when to discard old data.

**Three things to remember if you remember nothing else:**

- **Beat "same as last year" before doing anything else.** If you can't, ship it and move on.
- **Tree models can't forecast a trend.** They will predict a flat line and look confident doing it.
- **Your prediction ranges are too narrow.** Measure coverage on a backtest rather than trusting the label.

---

## Where to go next

- **The standard reference:** *Forecasting: Principles and Practice* by Hyndman & Athanasopoulos — free online, excellent, with both R and Python versions. If you read one thing, read chapter 3 (baselines and evaluation).
- **On what actually works:** the M4 and M5 forecasting competition results. The recurring finding — that simple methods and combinations perform extremely well — is worth knowing before you commit to something complicated.
- **Practical tools:** `statsforecast` (Python) is fast and implements the strong classical baselines properly.
