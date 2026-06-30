# Replication Package

[![DOI](https://zenodo.org/badge/1284087332.svg)](https://zenodo.org/badge/latestdoi/1284087332)

**Paper:** *Structured rules, not broad autonomy, support adaptive governance under climate stress*
**Authors:** Maryia Orsich†, Ivo Steimanis†, Maximilian Nicolaus Burger, Björn Vollan  
† Maryia Orsich and Ivo Steimanis contributed equally.
**Affiliation:** Marburg University, School of Business and Economics
**Corresponding author:** Björn Vollan, [bjoern.vollan@wiwi.uni-marburg.de](mailto:bjoern.vollan@wiwi.uni-marburg.de)
**Replication-package contact:** Ivo Steimanis, [i.steimanis@gmail.com](mailto:i.steimanis@gmail.com)

This package reproduces every numbered table and figure in the main manuscript and the Supplementary Information from the de-identified data delivered in `data/clean/` and `processed/`. The Stata pipeline runs with one command (~5 minutes). Three figures require separate manual rendering: Figure 5 (R), Figure 6 (R), and Figure 9 (Python); see instructions below.

The raw survey workbooks, the raw oTree session CSVs, and the photographs of Open-Design (T4) rule sheets contain direct identifiers and are therefore **not deposited**; they are restricted and available from the authors under the IRB protocol. The data-cleaning scripts that build the analysis datasets from those raw inputs (`00_deidentify.do`, `01_clean_survey.do`) are included for transparency; the analysis itself reproduces from the de-identified data shipped here. See the Data Availability Statement (Section 6).

---

## 1. Quick start

From the `replication_package/` directory in Stata 19:

```
. do run.do
```

`run.do` sets the working directory to its own location, installs missing user-written packages from SSC, creates `results/` subfolders, and then executes the analysis scripts. A timestamped log lands in `code/logs/`. Main paper figures go to `results/main/figures/`; SI outputs go to `results/si/figures/` and `results/si/tables/`. The paper has no numbered main-text tables; the tables it references (e.g. S5, S28) are part of the Supplementary Information and are written to `results/si/tables/`.

**Entry-point guard.** `01_clean_survey.do` rebuilds `survey_clean.dta` and `panel_clean.dta` from the restricted raw survey workbooks. Because those are not deposited, `run.do` detects their absence and **skips `01`**, using the de-identified `processed/survey_clean.dta` and `processed/panel_clean.dta` shipped in the package. Scripts `02 → 05` then run normally (`02` reads the deposited `data/clean/fishery_game_raw.dta`). On the authors' machine, with the restricted raw present, `01` runs and rebuilds everything from scratch.

For a clean rebuild of the outputs, delete `results/` and re-run `run.do`. **Do not delete `processed/`** in the public package: it holds the deposited de-identified analysis datasets the pipeline falls back on.

**Figures not produced by `run.do`:**

```
# Figure 5 (CDP perceived governance raincloud) — requires R 4.3+
Rscript code/fig5_cdp_raincloud.R

# Figure 6 (enforcement regime transitions) — requires R 4.3+
Rscript code/fig6_enforcement_flow.R

# Figure 9 (study sites map) — requires Python 3.9+
python code/make_study_site_map.py
```

All scripts use relative paths and should be run from the `replication_package/` directory. `run.do` must be run first to generate the `processed/` datasets that Figures 5 and 6 depend on.

---

## 2. Software and computational requirements

| Component | Version | Notes |
|---|---|---|
| **Stata** | **19** (StataNow19 / StataBE-64) | Set via `version 19` at the top of `run.do`. Earlier Stata versions are not supported because parts of `mixed`, `reghdfe`, and `coefplot` rely on Stata 17+ syntax. |
| Stata user-written packages | latest from SSC | `estout`, `outreg`, `frmttable`, `balancetable`, `cibar`, `catplot`, `coefplot`, `grc1leg`, `grc1leg2`, `grstyle`, `reghdfe`, `ftools`. `run.do` checks each with `cap which` and installs any missing one via `ssc install … , replace`. Internet access required on first run. |
| **R** | 4.3+ | Needed for Fig. 5 (`fig5_cdp_raincloud.R`) and Fig. 6 (`fig6_enforcement_flow.R`). Required packages: `haven`, `dplyr`, `tidyr`, `ggplot2`, `ggalluvial`, `ggsignif`, `fixest`, `scales`, `showtext`, `sysfonts`. Not invoked by `run.do`; render manually. |
| **Python** | 3.9+ | Only needed for the study-sites map (Fig. 9): `code/make_study_site_map.py`. Required packages: `cartopy`, `matplotlib`, `numpy`. Not invoked by `run.do`; render manually. |
| Operating system | Windows 10/11, macOS 12+, or Linux | Tested on Windows 11 with Stata 19 BE. |
| Disk | ~500 MB free | Intermediate `.dta` files in `processed/` total ~95 MB; `results/` adds ~50 MB. |

**Runtime:** ~5 minutes for public replication (script `01` is skipped because the raw survey inputs are restricted); ~10 minutes for a full rebuild from raw on the authors' machine. Measured on a 2024-class laptop (8-core CPU, 16 GB RAM). Approximate per-script breakdown for a full rebuild:

| Script | Runtime |
|---|---|
| `01_clean_survey.do` | ~2 min |
| `02_clean_game.do` | ~3 min |
| `03_merge_reshape.do` | ~30 sec |
| `04_main_analysis.do` | ~2 min |
| `05_suppl_analysis.do` | ~5–8 min |

---

## 3. Package structure

```
replication_package/
├── run.do                       Master script; this is the entry point.
├── README.md                    This file.
│
├── code/
│   ├── 00_deidentify.do         One-time de-identification of the pre-built inputs
│   │                            (authors only; not part of the standard run).
│   ├── 01_clean_survey.do       Builds survey_clean.dta + panel_clean.dta from the
│   │                            (restricted) raw survey workbooks; de-identifies on save.
│   ├── 02_clean_game.do         Cleans the deposited fishery_game_raw.dta into a panel.
│   ├── 03_merge_reshape.do      Merges survey + game; emits long & wide panels.
│   ├── 04_main_analysis.do      Main paper Figures 2–4, 7–8 + Table S5.
│   ├── 05_suppl_analysis.do     All SI figures and tables; robustness checks.
│   ├── _install_stata_packages.do   Optional: pre-install all Stata packages.
│   ├── fig5_cdp_raincloud.R     R: perceived governance raincloud (paper Fig. 5).
│   ├── fig6_enforcement_flow.R  R: enforcement regime flow diagram (paper Fig. 6).
│   ├── make_study_site_map.py   Python: study-sites map (paper Fig. 9).
│   ├── robustness_outlier_check.do  Standalone: outlier group sensitivity check.
│   ├── libraries/stata/         Vendored copies of user-written packages (fallback).
│   └── logs/                    Auto-generated run logs (timestamped).
│
├── data/
│   ├── raw/
│   │   └── Game/
│   │       ├── <22 village CSVs>            De-identified oTree session exports, one per
│   │       │                                village (participant labels / MTurk / session
│   │       │                                labels removed). Provenance for fishery_game_raw.dta.
│   │       ├── Discussions/                 De-identified group-discussion coding (free-text
│   │       │                                note columns removed; numeric category codes kept).
│   │       └── Quiz/                        Comprehension-quiz item-level scores (xlsx; no
│   │                                        identifiers). NOTE: the raw Survey workbooks and
│   │                                        the T4 rule photos remain RESTRICTED (see Section 6).
│   └── clean/                               De-identified pre-built inputs (ship as-is):
│       ├── PHI_Panel_12_16_22.dta           19-village longitudinal panel (2012/16/22).
│       ├── fishery_game_raw.dta             Merged raw oTree game export (read by 02).
│       └── quiz.dta                         Comprehension-quiz scores (read by 05).
│
├── processed/
│   Derived analysis-ready datasets emitted by 03; consumed by 04 / 05.
│   ├── survey_clean.dta              one row per participant (post-experiment survey)
│   ├── fishery_game_long.dta         one row per participant × round (18 rounds × 5 fishers × 84 groups)
│   ├── fishery_game_wide.dta         one row per participant; round-by-round columns flattened
│   ├── game_wide.dta                 one row per group; round-by-round columns flattened
│   └── panel_clean.dta               19-village longitudinal panel (2012, 2016, 2022)
│
├── documentation/
│   Codebooks. Each .docx documents variables in the corresponding .dta file.
│   ├── Codebook_Survey_22.docx       documents the survey variables (de-identified survey at processed/survey_clean.dta; raw workbook restricted)
│   ├── Codebook_Game_22.docx         maps to data/clean/fishery_game_raw.dta and the game panels
│   ├── Codebook_Panel_12_16_22_.docx maps to data/clean/PHI_Panel_12_16_22.dta
│   ├── Quiz (English and Haligaynon).docx  maps to data/raw/Game/Quiz/Quiz_results_all.xlsx
│   ├── Discussions_content.docx      documents the group-discussion coding (underlying workbook restricted)
│   └── Kobo_Post-Exp-Survey_7.xls    XLSForm instrument used in Kobo for the post-experiment survey
│
└── results/                          Auto-created by run.do
    ├── main/
    │   └── figures/                  Main paper .png figures
    ├── si/
    │   ├── figures/                  SI .png figures
    │   └── tables/                  SI .rtf tables
    └── intermediate/                 .gph (Stata graph objects) and partial-figure components
```

---

## 4. Output → script mapping

### 4.1 Main paper figures and tables

| Output | Script | Output file |
|---|---|---|
| Figure 1 (Experimental design) | externally produced (TikZ) | not in this package |
| Figure 2 (Rule-salience trajectory) | `04_main_analysis.do` | `results/main/figures/fig_rule_salience_trajectory.png` |
| Figure 3 (Governance / enforcement predictors) | `04_main_analysis.do` | `results/main/figures/fig_governance_enforcement_predicted.png` |
| Figure 4 (Treatment effects under climate shock) | `04_main_analysis.do` | `results/main/figures/fig_treatment_effects_climate_shock.png` |
| Figure 5 (Perceived governance raincloud) | `fig5_cdp_raincloud.R` | `results/main/figures/fig_cdp_treatment_effects_raincloud.png` |
| Figure 6 (Enforcement regime transitions) | `fig6_enforcement_flow.R` | `results/main/figures/fig_enforcement_flow.png` |
| Figure 7 (Endogenous regimes coefplot) | `04_main_analysis.do` | `results/main/figures/fig_endogenous_enforcement_coefplot.png` |
| Figure 8 (Endgame deterioration + leadership) | `04_main_analysis.do` | `results/main/figures/fig_endgame_leader.png` |
| Figure 9 (Study sites map) | `make_study_site_map.py` | `results/main/figures/fig_study_sites_map.png` |

`04_main_analysis.do` also writes `results/main/figures/fig_cdp_treatment_effects_coefplot.png`, a coefficient-plot companion to Figure 5 (perceived governance / CDP treatment effects).

### 4.2 Supplementary Information

#### Tables

| SI table | Script | Output file in `results/si/tables/` |
|---|---|---|
| S5 (Survey enforcement predictors) | `04_main_analysis.do` | `survey_enforcement_predictors.rtf` |
| S6 (Socioeconomic balance across treatments) | `05_suppl_analysis.do` | `balance_table.xls` |
| S7 (Parallel trends test, Phase 2) | `05_suppl_analysis.do` | `parallel_trends_phase2.rtf` |
| S8 (DiD Phase 1 → Phase 2) | `05_suppl_analysis.do` | `did_baseline_to_governance.rtf` |
| S9 (DiD Phase 2 → Phase 3, treatments) | `05_suppl_analysis.do` | `did_governance_to_climate_shock.rtf` |
| S10 (DiD Phase 3, endogenous regimes) | `05_suppl_analysis.do` | `did_enforcement_regimes_climate_shock.rtf` |
| S11 (Robustness: Batonan-Sur included) | `05_suppl_analysis.do` | `did_robustness_batonansur.rtf` |
| S12 (Robustness: group fixed effects) | `05_suppl_analysis.do` | `did_robustness_group_fe.rtf` |
| S13 (Robustness: comprehension subset) | `05_suppl_analysis.do` | `did_robustness_comprehension.rtf` |
| S17–S19 (Endgame drop-rounds: non-compliance / deterioration / high-state) | `05_suppl_analysis.do` | `endgame_droprounds_{noncompliance,deterioration,highstate}.rtf` |
| S20–S22 (Endgame interactions: same outcomes) | `05_suppl_analysis.do` | `endgame_interactions_{noncompliance,deterioration,highstate}.rtf` |
| S23 (Logistic endgame per treatment) | `05_suppl_analysis.do` | `endgame_per_treatment_logit.rtf` |
| S24 (Constitutional / enforcement channels) | `05_suppl_analysis.do` | `constitutional_enforcement_channels.rtf` |
| S25 (Mechanism robustness) | `05_suppl_analysis.do` | `mechanism_robustness.rtf` |
| S26 (Rule-change vote logit) | `05_suppl_analysis.do` | `rule_change_vote_logit.rtf` |
| S28 (CDP treatment effects) | `04_main_analysis.do` | `cdp_treatment_effects.rtf` |
| Phase 1 baseline equivalence across treatments | `05_suppl_analysis.do` | `phase1_baseline_equivalence.rtf` |
| Perception summary (post-experiment survey) | `05_suppl_analysis.do` | `perception_summary.rtf` |
| Enforcement regime by treatment (counts) | `05_suppl_analysis.do` | `tab1a_enforcement_by_treatment.csv` |

SI tables that contain only definitions, payoff matrices, or item lists (e.g. S1–S4, S14–S16, S27) are typeset directly in the SI text and have no generating script.

#### Figures

| SI figure | Script | Output file in `results/si/figures/` |
|---|---|---|
| Round-by-round outcomes (3 panels, all rounds) | `05_suppl_analysis.do` | `fig_outcomes_over_rounds.png` |
| Area / methods choices over rounds | `05_suppl_analysis.do` | `fig_area_methods_over_rounds.png` |
| T4 area-method choice composition | `05_suppl_analysis.do` | `fig_choice4_byphase.png` |
| Game earnings by phase | `05_suppl_analysis.do` | `fig_game_earnings_by_phase.png` |
| Endgame 3-panel (constitutional + enforcement channels) | `05_suppl_analysis.do` | `fig_endgame_3panel.png` |
| Rule adaptation by panel | `05_suppl_analysis.do` | `fig_rule_adaptation_by_panel.png` |
| Area / method choices (rule menu) | `05_suppl_analysis.do` | `fig_area_method_choices.png` |
| Punishment descriptive | `05_suppl_analysis.do` | `fig_punishment_descriptive.png` |
| Problems with fisheries (post-exp survey) | `05_suppl_analysis.do` | `fig_problems_fisheries.png` |
| Comprehension quiz by treatment | `05_suppl_analysis.do` | `fig_comprehension_quiz_by_treatment.png` |
| Rule-inertia game | `05_suppl_analysis.do` | `fig_rule_inertia_game.png` |

---

## 5. Data sources

### Primary data (collected by the authors)

1. **Lab-in-the-field experiment, Capiz Province, Philippines, 2022.**
   - 420 small-scale fishers in 84 groups across 21 villages, on the four-arm autonomy gradient (T1 *Fixed* / T2 *Constrained* / T3 *Flexible* / T4 *Open*) with announced climate-shock phase.
   - Game data: the raw oTree session exports (22 CSVs in `data/raw/Game/`, one per village session) are deposited de-identified -- participant labels, MTurk worker/assignment IDs, and session labels are removed; the merged, analysis-ready export is at `data/clean/fishery_game_raw.dta` (the input to `02`).
   - Quiz scores: KoboCollect, in `data/raw/Game/Quiz/Quiz_results_all.xlsx` (no identifiers); also deposited de-identified as `data/clean/quiz.dta`.
   - Group-discussion coding: `data/raw/Game/Discussions/Discussions_content.xlsx`, deposited de-identified with the free-text note columns (`a_notes`, `b_notes`, `general_remarks`) removed; the numeric category codes are retained.
   - Open-Design (T4) rule photographs are restricted (handwriting that could identify participants); available from the authors under the IRB protocol.

2. **Pre-experiment consent, post-experiment survey, household survey, 2022.**
   - KoboCollect XLSForms. The raw workbooks (`.xlsx`/`.dta`) carry direct identifiers and are restricted (not deposited). The de-identified analysis dataset built from them is deposited at `processed/survey_clean.dta`.

3. **Three-wave longitudinal panel, 2012 / 2016 / 2022.**
   - 19 MPA villages in Capiz Province, Philippines.
   - Cleaned by the authors from prior survey waves; lives at `data/clean/PHI_Panel_12_16_22.dta`. Used for the motivating field patterns (paper Figs 2 and 3) only.

### Reference / instrument files

- `documentation/Kobo_Post-Exp-Survey_7.xls` — XLSForm used in KoboCollect for the post-experiment survey (verbatim instrument).
- `documentation/Quiz (English and Haligaynon).docx` — comprehension-quiz items in both English and Hiligaynon.

### No external API or third-party download is required for replication.

All data needed to reproduce every table and figure is included in `data/clean/` and `processed/`.

---

## 6. Data Availability Statement

The de-identified individual-, group-, and village-level data needed to reproduce every result in the paper and Supplementary Information are included in this package under `data/clean/` and `processed/`. No external data sources are required.

**What was removed.** Direct identifiers were dropped from all deposited datasets: respondent name, phone number, household-head name, the names and position titles of organizations the respondent belongs to, and (in the longitudinal panel) social-network member names, partner/reference names, the interviewer name, and the panel name field. Field assistants are anonymized to S01–S11. All open-ended free-text survey fields (free-text comments and "...please specify" write-ins) are also dropped from the deposited survey and panel datasets, because respondents occasionally entered names or phone numbers there; only geographic fields (province/municipality/village) and the anonymized enumerator code are kept among the string variables. In the deposited raw oTree session CSVs, the participant labels, MTurk worker/assignment IDs, and session labels are removed; in the deposited group-discussion workbook, the free-text note columns (`a_notes`, `b_notes`, `general_remarks`) are removed. The de-identification is performed in `00_deidentify.do` (pre-built panel input) and in `01_clean_survey.do` (survey data, dropped at the point of saving); both scripts are included so the removal is auditable. GPS coordinates are retained only at the village-centroid level at one-decimal resolution (~10 km); exact household locations are not deposited.

**What is restricted (not deposited).** The raw survey workbooks (consent form, post-experiment survey, household survey) and the photographs of Open-Design (T4) rule sheets contain direct identifiers or handwriting that could identify participants; these are held by the authors and are available on reasonable request under the IRB protocol. The survey-cleaning code that consumes the raw workbooks is included for transparency but is not required to reproduce the published results, which run from the deposited de-identified data.

The replication package source is hosted at https://github.com/IvoSteimanis/mpa-adaptation and archived on Zenodo (concept DOI https://doi.org/10.5281/zenodo.21065050, which always resolves to the latest version).

---

## 7. Ethics / IRB

The study was reviewed and approved by the Philippine Social Science Council Ethics Review Board (PSSC-SSERB), reference number CC-22-54 (full review). All participants gave written and recorded oral informed consent in Hiligaynon prior to participation. Participation was voluntary and compensated at fair-market rates calibrated to local fisher day-wages.

---

## 8. License

This replication package is released under the **Creative Commons Attribution 4.0 International License (CC BY 4.0)**.

You are free to share and adapt the materials with attribution. See [https://creativecommons.org/licenses/by/4.0/](https://creativecommons.org/licenses/by/4.0/).

The vendored third-party Stata packages in `code/libraries/stata/` are distributed under their original authors' licenses (see each package's `.pkg` / `.hlp` files).

---

## 9. Citation

If you use this package in your own research, please cite the paper:

> Orsich, M., Steimanis, I., Burger, M. N., & Vollan, B. (2026). *Structured rules, not broad autonomy, support adaptive governance under climate stress.* Working paper. https://doi.org/10.5281/zenodo.21065050

---

## 10. Contact

Questions, bug reports, or replication issues: please contact Ivo Steimanis at [i.steimanis@gmail.com](mailto:i.steimanis@gmail.com).

For substantive questions about the paper, contact corresponding author Björn Vollan at [bjoern.vollan@wiwi.uni-marburg.de](mailto:bjoern.vollan@wiwi.uni-marburg.de).
