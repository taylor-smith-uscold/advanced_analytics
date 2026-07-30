# Is the Data Telling You What You Think? A Plain-Language Guide to Data Quality and Features

*Module 4 — plain-language register. How to tell whether your data means what you think it means.*

---

## The short version

Before you model anything, you have a pile of numbers that someone else's software wrote down, for reasons you probably don't know. Values are missing for reasons that matter. Categories have no natural ordering but get one anyway. Timestamps hide patterns that most models can't see. And every field is an imperfect record of something real.

Two ideas do most of the work in this module:

1. **A badly measured input doesn't just look noisy — it looks unimportant.** Measurement error systematically shrinks a variable's apparent effect. Fixing your tracking can beat any amount of model tuning.
2. **Anything you calculate from the data is part of your model.** Filling in missing values, capping outliers, encoding categories — all of it must happen *inside* your cross-validation, not before it. This is the same leakage rule from Module 6, wearing four different disguises.

---

## Part 1: Look at the actual data

Not the summary. The actual rows.

Sort them a few ways, scroll through them, and plot each column. Here's what that catches that a summary table never will:

- **Fake values pretending to be real.** `-999` for "unknown." `1900-01-01` for "no date." Income of `0` where it means "didn't answer." Latitude `0`, which puts your customer in the ocean off West Africa.
- **Mixed units.** One system reports grams, another kilograms, and a pipeline merged them last March.
- **Values piling up at a limit.** A stack of records at exactly 100, or 999, means something got cut off.
- **Timestamp chaos.** Mixed time zones. Daylight saving gaps. The time the record was *loaded* recorded as the time the event *happened*.
- **Duplicates** from a system that retried a failed write.

### The single most useful chart

**Plot each field's daily volume and average against time.**

Pipeline breaks, tracking changes, backfills, and schema migrations all show up as sudden steps or gaps. This one chart finds more real problems than any other diagnostic, and it takes minutes.

If you see a step change in a feature, find out what happened on that date before you model anything. Often the answer is "we changed how we log it," which means your historical data and your future data are different things wearing the same column name.

---

## Part 2: Missing data

### Why it's missing matters more than how much

Three situations, and they need different responses:

**1. Missing for no particular reason.** A sensor drops readings randomly. Annoying but harmless — you just have less data.

**2. Missing for a reason you can see in other columns.** Older records lack a field added in 2023. You can see the date, so you can account for it. Filling in the gaps sensibly works here.

**3. Missing *because of* what the value was.** High earners decline to state income. People with bad experiences don't fill out the survey.

**The third case can't be fixed from your data**, because the information you'd need is exactly what's missing. The honest response is to say so, and to test how much your conclusion would change under different assumptions about the missing values.

**You can't tell case 2 from case 3 by looking at the data.** You're making a judgment call based on how the data was collected. Write down which one you're assuming.

*(If you meet these in documentation, the standard names are MCAR, MAR, and MNAR — "missing completely at random," "missing at random," and "missing not at random," matching cases 1, 2, and 3. The names are unhelpfully similar; the three descriptions above are what matter.)*

### How to fill gaps

| Approach | When it's reasonable |
|---|---|
| **Drop incomplete rows** | Only when very little is missing and it's case 1. With 20 columns at 5% missing each, you lose over half your rows |
| **Fill with the average** | Fast, and it distorts things — it fakes certainty and flattens real relationships |
| **Predict the missing value from other columns** | Usually much better; standard tools do this |
| **Let the model handle it** | Modern tree models (XGBoost, LightGBM) handle gaps natively and often do it best |

### Add a "was this missing?" column

Alongside any filled-in value, add a yes/no flag for whether it was originally missing.

Sometimes the *fact* of missingness predicts better than the value. An optional profile field only gets filled in by engaged users, so "left it blank" is real information.

**But be suspicious if that flag becomes your top predictor.** Ask what process fills that field. If it gets populated as a *result* of the thing you're predicting, you've found leakage, not insight.

### The rule you can't break

Calculate your fill-in values from the training data only, inside each cross-validation fold. Computing the average across your whole dataset and then splitting means the validation set influenced your training. Same rule as scaling in Module 5, same reason.

---

## Part 3: Sloppy measurement makes things look unimportant

This one is underappreciated and worth internalizing.

If a field is recorded with a lot of noise — an imprecise survey question, an unreliable tracker, a rough estimate — the model doesn't just get less confident about it. **The model systematically understates how much it matters.**

The consequences:

- **A weak-looking feature might be a strong one, badly measured.** Before you drop it, ask how reliably it's recorded.
- **Feature importance rankings partly measure data quality.** A well-tracked mediocre signal will outrank a poorly-tracked strong one.
- **Fixing instrumentation can beat fixing models.** If a key input is measured badly, improving the tracking will move your results further than any amount of tuning. This is rarely anyone's first instinct and is often the right answer.

---

## Part 4: Turning categories into numbers

Models need numbers. Categories aren't numbers. However you convert them, you're imposing something.

| Approach | How it works | Watch out |
|---|---|---|
| **One column per category** | "Region" becomes North/South/East/West flags | Explodes with many categories (e.g. zip codes) |
| **Number per category** | North=1, South=2, East=3 | **Only for genuinely ordered things.** Otherwise you've told the model East is between South and West, and it will believe you |
| **Replace with the average outcome** | "Region North" → average revenue in North | Powerful and dangerous — see below |
| **Replace with how common it is** | Cheap, sometimes surprisingly useful | Loses meaning |
| **Let the model handle it** | LightGBM and CatBoost do this natively | Usually the best option for tree models |

### The average-outcome trap

Replacing a category with its average outcome uses the answer. If you compute those averages across your whole training set, **each row's encoding includes that row's own outcome.** A category that appears once gets encoded as exactly its own answer.

Your validation score will look phenomenal. Your production model will be useless.

Doing this correctly requires computing each row's encoding from *other* folds of data, plus pulling rare categories toward the overall average so a category with three examples doesn't get an extreme value. (That pulling-toward-the-average idea is exactly the shrinkage from Module 5, and Module 9 develops it properly.)

**If this technique is in your pipeline and nobody explicitly built the out-of-fold version, assume it's leaking.**

### Plan for categories you've never seen

Production will show you a region, product code, or device type that wasn't in your training data. Decide what happens then — before it happens at 2am.

---

## Part 5: Building useful features

### Dates are goldmines, usually wasted

**Wrap-around time.** Hour 23 and hour 0 are one hour apart, but as plain numbers they're 23 apart. Many models take that literally. There's a standard fix (encoding the hour as a position on a circle) that costs two columns and fixes it properly.

**Use elapsed time, not calendar dates.** "Days since signup," "days since last purchase," "account age" all generalize to new customers. A raw date doesn't — your model just learns that 2024 was different from 2023.

**Calendar effects are often the biggest driver in the data.** Holidays, paydays, weekends, month-end, fiscal quarter close. If you're modeling anything commercial and haven't included these, you're leaving the largest patterns on the table.

### Summarize history, carefully

Most predictive power in business data comes from summarizing what someone did recently: how many times, how much, how recently, and whether it's trending up or down.

Trailing windows (last 7 / 30 / 90 days) are the standard tool. The ratio of a short window to a long one captures *acceleration*, which often predicts better than the level does.

**Every one of these windows must end before your outcome window begins.** This is where temporal leakage usually gets introduced, because it's easy to write a query that quietly includes the present.

### Ratios usually beat raw numbers

Revenue *per user*, errors *per session*, usage *as a fraction of allowance*. These stay meaningful as things grow; raw totals don't.

---

## Part 6: Outliers

"Outlier" isn't a property of a data point. It's a statement that the point doesn't fit your assumptions. Three different situations:

| Type | Example | What to do |
|---|---|---|
| **Actual error** | Age of 300; negative revenue | Remove it, and fix the pipeline that produced it |
| **Genuinely extreme** | Your biggest customer | **Keep it.** It's real, and it might be the most important row you have |
| **A different population** | Bot traffic mixed with real users | Separate them and model separately |

For heavy-tailed things like revenue, where one enormous customer can swamp everything, common options are capping values at a high percentile, or working in log terms.

**Decide the rule before you look at results.** Choosing a cap after seeing which cap gives the nicest answer is fitting your data to your conclusion.

---

## Part 7: What goes inside the fold

The clean test: **does this step learn anything from the data?** If yes, it belongs inside cross-validation.

| Step | Learns from data? | Inside the fold? |
|---|---|---|
| Scaling | Yes (averages, spreads) | **Yes** |
| Filling missing values | Yes | **Yes** |
| Average-outcome encoding | Yes | **Yes**, out-of-fold |
| Choosing which features to keep | Yes | **Yes** |
| Capping outliers | Yes (percentiles) | **Yes** |
| Balancing classes | Yes (creates rows) | **Yes** — training data only |
| Taking a log | No | Either |
| Ratios you defined yourself | No | Either |

### One specific warning about balancing

If your positive class is rare, a common move is to duplicate or synthesize positive examples. **Do this only on the training portion, never before splitting.** If you generate synthetic rows from your data and then split, near-copies land on both sides and your validation score becomes fiction.

Often you don't need balancing at all — adjusting your decision threshold (Module 7) achieves the same goal without distorting the model.

---

## Part 8: Warning signs

| What you see | What's probably happening |
|---|---|
| One feature is implausibly powerful | Leakage — check when that field gets populated |
| Great in testing, poor in production | Something learned from data outside its fold, or a field isn't available live |
| Performance falls off a cliff on a specific date | Tracking or schema change — check your daily plots |
| An effect is smaller than domain experts expect | Possibly measurement noise shrinking it |
| A column has two humps or a weird spike | Fake "unknown" values, or two populations mixed together |
| Rare categories with extreme values | Average-outcome encoding without smoothing |
| Weekend and holiday predictions are bad | No calendar features |
| Model crashes on a new category | No plan for unseen values |

---

## Putting it all together

**The recipe:**

1. **Look at raw rows** and plot every field over time before anything else.
2. **Hunt for fake values** — suspiciously round numbers, impossible values, piles at a boundary.
3. **For each column with gaps, decide why** they're missing and write down your assumption.
4. **Add "was missing" flags**; fill gaps inside the fold.
5. **Pick category encodings** based on how many categories there are and what model you're using.
6. **Draw the timeline** and check every historical window closes before the outcome window opens.
7. **Build features with meaning** — elapsed times, trailing summaries, ratios, calendar effects.
8. **Decide the outlier rule in advance**, and report results both ways.
9. **Put the whole thing in a pipeline.** If a step learns from data, it goes inside.
10. **Write a data dictionary** — what each field means, where it comes from, whether it's available at prediction time, and its known problems. Module 14's monitoring depends on this existing.

**Three things to remember if you remember nothing else:**

- **Plot every field against time.** Pipeline breaks and tracking changes look like steps, and they'll ruin a model silently.
- **Badly measured inputs look unimportant.** Before dropping a weak feature, ask whether it's actually weak or just noisy.
- **Anything computed from data goes inside the fold.** Filling gaps, capping outliers, encoding categories, balancing classes — all of it. Learning this once saves you a career's worth of results that were too good to be true.

---

## Where to go next

- **Practical:** `scikit-learn`'s `Pipeline` and `ColumnTransformer` documentation — the mechanics of doing all of this correctly.
- **On missing data:** *Flexible Imputation of Missing Data* by Stef van Buuren — free online, readable, the standard practical reference.
- **On features:** *Feature Engineering for Machine Learning* by Zheng & Casari — broad and hands-on.
- **On production reality:** Google's "Rules of Machine Learning" — short, free, and unusually honest about what actually goes wrong.
