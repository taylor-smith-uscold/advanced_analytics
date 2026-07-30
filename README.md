# Advanced Analytics — Course Reader

An applied program in statistical learning, machine learning, and decision-oriented analysis, delivered as a single self-contained web reader.

**Read it here:** https://taylor-smith-uscold.github.io/advanced_analytics/

## About

Sixteen modules, each written twice. Every topic appears in a **technical** register — the mathematics, assumptions, and failure modes — and in a **plain-language** register that explains the same idea to a non-specialist stakeholder. A switch in the interface moves between them, so the reader can meet the material at whichever level the moment calls for, and see how one translates into the other.

The modules are organized into three arcs:

| Arc | Focus | Modules |
| --- | --- | --- |
| I | Getting the question right | 01–03 |
| II | Getting the model right | 04–12 |
| III | Surviving the business | 13–16 |

Arc I covers problem framing and metric design, causal inference, and experimentation. Arc II runs from data quality and feature construction through regularization, cross-validation, performance evaluation, gradient boosting, hierarchical models, forecasting, uncertainty, and unsupervised methods. Arc III turns outward: interpretability, distribution shift and monitoring, fairness and governance, and communicating analysis.

Every module opens with the question it exists to answer — *What decision is this analysis for?*, and so on — because the framing is the point.

## Features

- Two registers per module, switchable in place
- Full-text search across every document
- LaTeX math rendered with KaTeX
- Light and dark themes
- Reading preferences persist between visits
- Responsive down to mobile widths

## Structure

```
index.html          reader interface — styles, scripts, and fonts, inlined
lessons/            lesson prose, one markdown file per document
.nojekyll           disables Jekyll processing on GitHub Pages
```

Lesson text lives in `lessons/` as plain markdown, named `NN-topic-register.md`. To revise a lesson, edit its file and commit — nothing needs rebuilding. To add one, drop the file in `lessons/` and add a matching entry to the `DATA` object in `index.html`, where the `file` field carries the filename stem.

## Technical notes

There is no build step and no server-side code. The interface is a single HTML file with all styles, scripts, and web fonts inlined; lesson files are fetched at load and indexed for search.

Because the reader fetches its content at runtime, opening `index.html` directly from disk will not work — browsers block `fetch` on `file://` URLs. To preview locally, serve the directory over HTTP:

```
python3 -m http.server
```

Then visit `http://localhost:8000/`.

The empty `.nojekyll` file is required for GitHub Pages: the bundled KaTeX source contains brace sequences that Jekyll's template engine would otherwise consume, breaking math rendering.

Reading preferences are stored in `localStorage` under the `aa:` prefix.

## Deploying

Push to a repository and enable GitHub Pages under **Settings → Pages**, selecting the branch and `/ (root)` as the source. Include `.nojekyll` in the commit — GitHub's web uploader skips dotfiles, so create it through **Add file → Create new file** if you are not using Git directly.
