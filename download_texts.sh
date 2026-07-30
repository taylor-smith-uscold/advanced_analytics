#!/usr/bin/env bash
# Advanced Analytics — core reading list downloader
#
# One primary reading per module for the 16-module syllabus at
# https://taylor-smith-uscold.github.io/advanced_analytics/
#
# Usage:   bash download_texts.sh [output_dir]
# Default output_dir is ./backup_advanced_analytics_readings
#
# Most primaries are author-published web books with no sanctioned PDF, so
# this script fetches six PDFs and writes a linked reading list covering all
# sixteen modules.
#
# LICENSING
#   [CC]   Creative Commons; may be redistributed (check the variant).
#   [FREE] Free to download, NOT licensed for redistribution. Link to the
#          publisher page from your LMS rather than re-hosting the file.

set -uo pipefail

OUT="${1:-advanced_analytics_readings}"
mkdir -p "$OUT"
LIST="$OUT/READING_LIST.md"

ok=0; failed=0

# get <module> <license> <filename> <direct_pdf_url> <landing_page>
get () {
  local mod="$1" lic="$2" name="$3" url="$4" landing="$5"
  local dest="$OUT/${mod}_${name}"

  if [[ -f "$dest" ]]; then
    echo "  = $mod  $name (already present)"
    ok=$((ok+1)); return 0
  fi

  if curl -fsSL --max-time 120 --retry 2 -o "$dest" "$url" 2>/dev/null \
     && [[ -s "$dest" ]] && head -c 4 "$dest" | grep -q '%PDF'; then
    echo "  + $mod  $name  [$lic]"
    ok=$((ok+1)); return 0
  else
    rm -f "$dest"
    echo "  ! $mod  $name  -> fetch by hand from $landing"
    failed=$((failed+1)); return 1
  fi
}

echo "Downloading to: $OUT"
echo ""

# ISLP (modules 05, 06, 07, 08, 12) is deliberately NOT downloaded. It is
# [FREE] -- free to read, not licensed for redistribution -- so per the policy
# above we link the publisher instead of mirroring the file. The old direct URL
# (statlearning.com/media/ISLP_website.pdf) now 404s in any case; the book is
# served through a Google Drive redirect that curl cannot follow unattended.
echo "  - 05-08-12  ISLP  [FREE] link-only, see https://www.statlearning.com/"

get "11" "CC" "angelopoulos_bates_conformal_prediction.pdf" \
  "https://arxiv.org/pdf/2107.07511" \
  "https://arxiv.org/abs/2107.07511"

get "14" "FREE" "sculley_hidden_technical_debt_in_ml.pdf" \
  "https://papers.nips.cc/paper_files/paper/2015/file/86df7dcfd896fcaf2674f757a2463eba-Paper.pdf" \
  "https://papers.nips.cc/paper_files/paper/2015"

get "15" "CC" "barocas_hardt_narayanan_fairness_and_ml.pdf" \
  "https://fairmlbook.org/pdf/fairmlbook.pdf" \
  "https://fairmlbook.org/"

get "15" "CC" "mitchell_model_cards.pdf" \
  "https://arxiv.org/pdf/1810.03993" \
  "https://arxiv.org/abs/1810.03993"

get "15" "CC" "gebru_datasheets_for_datasets.pdf" \
  "https://arxiv.org/pdf/1803.09010" \
  "https://arxiv.org/abs/1803.09010"

cat > "$LIST" << 'MD_EOF'
# Advanced Analytics — core reading list

One primary reading per module. PDFs sit alongside this file; everything
else is an author-published web book, linked here.

## Arc I — Getting the question right

| # | Module | Primary reading |
|---|---|---|
| 01 | Problem Framing & Metric Design | Google, *Rules of Machine Learning*, rules 1–3 and 12–14 — <https://developers.google.com/machine-learning/guides/rules-of-ml> |
| 02 | Causal Inference | Cunningham, *Causal Inference: The Mixtape*, ch. 3–4 — <https://mixtape.scunning.com/> |
| 03 | Experimentation & A/B Testing | Kohavi et al., experimentation paper archive (CUPED, SRM, rules of thumb) — <https://exp-platform.com/> |

## Arc II — Getting the model right

| # | Module | Primary reading |
|---|---|---|
| 04 | Data Quality, Missingness & Features | van Buuren, *Flexible Imputation of Missing Data* (2e), ch. 1–2 — <https://stefvanbuuren.name/fimd/> |
| 05 | Scaling & Regularization | **ISLP ch. 6** (PDF in this folder) |
| 06 | Cross-Validation | **ISLP ch. 5** |
| 07 | Evaluating & Reporting Performance | **ISLP ch. 4.4–4.5**, plus scikit-learn calibration guide — <https://scikit-learn.org/stable/modules/calibration.html> |
| 08 | Trees, Bagging & Gradient Boosting | **ISLP ch. 8**, plus XGBoost *Introduction to Boosted Trees* — <https://xgboost.readthedocs.io/en/stable/tutorials/model.html> |
| 09 | Hierarchical Models & Partial Pooling | Martin, Kumar & Lao, *Bayesian Modeling and Computation in Python*, ch. 4–5 — <https://bayesiancomputationbook.com/welcome.html> |
| 10 | Time Series & Forecasting | Hyndman & Athanasopoulos, *Forecasting: Principles and Practice* (Python ed.), ch. 3, 5, 8 — <https://otexts.com/fpppy/> |
| 11 | Uncertainty & Inference | Angelopoulos & Bates, *A Gentle Introduction to Conformal Prediction* (PDF in this folder) |
| 12 | Unsupervised Methods | **ISLP ch. 12**, plus Wattenberg et al., *How to Use t-SNE Effectively* — <https://distill.pub/2016/misread-tsne/> |

## Arc III — Surviving the business

| # | Module | Primary reading |
|---|---|---|
| 13 | Interpretability & Explanation | Molnar, *Interpretable Machine Learning* — <https://christophm.github.io/interpretable-ml-book/> |
| 14 | Distribution Shift & Monitoring | Sculley et al., *Hidden Technical Debt in ML Systems* (PDF in this folder) |
| 15 | Fairness, Privacy & Governance | Barocas, Hardt & Narayanan, *Fairness and Machine Learning*, ch. 2–3 (PDF in this folder). Exercise templates: Mitchell et al., *Model Cards*; Gebru et al., *Datasheets for Datasets* (PDFs in this folder) |
| 16 | Communicating Analysis | Wilke, *Fundamentals of Data Visualization*, ch. 16 and 29 — <https://clauswilke.com/dataviz/> |

## Redistribution

ISLP is free to download but not licensed for redistribution — link to
<https://www.statlearning.com/> from the LMS rather than posting the PDF.
The Sculley paper is free via NeurIPS proceedings; link rather than mirror.
The remaining four PDFs are Creative Commons and may be re-hosted, subject
to the specific licence variant.
MD_EOF

echo ""
echo "-----------------------------------------------------"
echo "PDFs downloaded:   $ok / 5"
echo "Failed:            $failed"
echo ""
echo "Reading list for all 16 modules: $LIST"
