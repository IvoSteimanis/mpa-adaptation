*-------------------------------------------------------------------------------------------------------
* OVERVIEW
*-------------------------------------------------------------------------------------------------------
*   This script generates every numbered table and figure reported in the
*   main manuscript and Supplementary Information of:
*
*       Orsich, M., Steimanis, I., Burger, M. N., & Vollan, B. (2026).
*       "Structured rules, not broad autonomy, support adaptive
*        governance under climate stress."
*       Marburg University, School of Business and Economics.
*
*   Deposited de-identified data live in /data/clean and /processed; the raw
*   survey workbooks are restricted (not deposited) -- see README Section 6.
*   Main paper figures are written to /results/main/figures; SI figures and
*   tables to /results/si/figures and /results/si/tables (the paper has no
*   numbered main-text tables).
*   See README.md for a full output -> script mapping and replication
*   instructions.
*
*   Entry point: just `do run.do` from the replication_package/ directory.
*   Runtime: ~5 min for the public run (script 01 skipped); ~10 min full rebuild.
*
*   TO PERFORM A CLEAN RUN (authors only, with the restricted raw survey data
*   present), delete /results and re-run. Do NOT delete /processed in the public
*   package: it holds the deposited de-identified survey_clean.dta and
*   panel_clean.dta that the pipeline falls back on when the restricted raw
*   survey inputs are absent (see the entry-point guard below).
*-------------------------------------------------------------------------------------------------------


*--------------------------------------------------
* Set global Working Directory
*--------------------------------------------------
* Defines the current location of the replication package
global working_ANALYSIS: pwd


*--------------------------------------------------
* Program Setup
*--------------------------------------------------
* Initialize log and record system parameters
clear
set more off
cap mkdir "$working_ANALYSIS/code/logs"
cap log close
local datetime : di %tcCCYY.NN.DD!-HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$working_ANALYSIS/code/logs/`datetime'.log.txt"
log using "`logfile'", text

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"


*   Analyses were run on Windows 11 using Stata 19 (StataNow19 / StataBE-64).
version 19              // Required for mixed / reghdfe / coefplot syntax used downstream

* Reproducibility: fix the RNG seed AND the sort seed for the whole session so
* results do not depend on session state. Several steps use order-sensitive
* operations (e.g. `duplicates drop unique_id, force` to reduce to one row per
* participant); without a fixed sortseed the surviving row -- and hence a few
* SI-table values -- could differ depending on which scripts ran beforehand
* (e.g. when the entry-point guard skips 01). This pins them.
set seed 20260629
set sortseed 20260629

* Put the vendored user-written packages on the ado-path as a FALLBACK so the
* package is self-contained on a clean machine: code/libraries/stata/ ships
* grstyle, lcolrspace.mlib, and the scheme-swift_red.scheme used below. "+"
* appends (low priority) so any package already installed on the user's machine
* takes precedence; the vendored copies only fill gaps (e.g. the custom scheme).
* NOTE: the vendored snapshot is not guaranteed identical to the exact package
* versions used to produce the manuscript; see README Section 2.
adopath + "$working_ANALYSIS/code/libraries/stata"

* Install any user-written package still missing from SSC (internet needed only
* on first run; the packages used for graph styling are vendored above).
foreach pkg in estout outreg frmttable balancetable cibar catplot coefplot grc1leg grstyle reghdfe ftools {
    cap which `pkg'
    if _rc {
        di "Installing missing package: `pkg'"
        cap ssc install `pkg', replace
    }
}

* Also try the grc1leg2 from grc1leg2 package (sometimes separate)
cap which grc1leg2
if _rc cap ssc install grc1leg2, replace

* Create directories for output files
cap mkdir "$working_ANALYSIS/data/clean"
cap mkdir "$working_ANALYSIS/processed"
cap mkdir "$working_ANALYSIS/results"
cap mkdir "$working_ANALYSIS/results/intermediate"
cap mkdir "$working_ANALYSIS/results/main"
cap mkdir "$working_ANALYSIS/results/main/figures"
cap mkdir "$working_ANALYSIS/results/si"
cap mkdir "$working_ANALYSIS/results/si/figures"
cap mkdir "$working_ANALYSIS/results/si/tables"
* -------------------------------------------------


*--------------------------------------------------
* Treatment color palette (matches experimental design figure)
* T1 Fixed Blueprint, T2 Constrained, T3 Flexible, T4 Open
* p1-p4 use the FILL colors (bar fills); accent/text colors below
* are available as globals for explicit use in figures.
*--------------------------------------------------
* Fills (used as default p1-p4 colors)
global c_T1_fill   "249 210 210"   // T1 light red
global c_T2_fill   "253 222 180"   // T2 light orange
global c_T3_fill   "195 225 210"   // T3 light green
global c_T4_fill   "160 210 170"   // T4 medium green

* Accent / text / outline colors (use for lcolor, mcolor in twoway plots)
* All four match Figure 1 (Analysis/experimental_design.tex) exactly.
* T4 is a very dark green so the T3-vs-T4 contrast is visible in bars and lines;
* Figure 1's openTxt is set to the same RGB.
global c_T1_text   "170 40 40"     // T1 dark red
global c_T2_text   "200 110 30"    // T2 dark orange
global c_T3_text   "30 130 100"    // T3 forest green
global c_T4_text   "0 65 25"       // T4 very dark green (was 30 120 60)

* Autonomy gradient stops -- 4-stop ramp through the four treatment text colors,
* identical to Figure 1's gradient bar (Analysis/experimental_design.tex).
* Currently unused in Stata plots; defined here so the palette stays in sync.
global c_grad_T1  "$c_T1_text"   // 170 40 40  (Fixed)
global c_grad_T2  "$c_T2_text"   // 200 110 30 (Constrained)
global c_grad_T3  "$c_T3_text"   // 30 130 100 (Flexible)
global c_grad_T4  "$c_T4_text"   // 0 65 25    (Open)

** Set general graph style
set scheme swift_red //select one scheme as reference scheme to work with
grstyle init
{
*Background color
grstyle set color white: background plotregion graphregion legend box textbox //

* Force all text to black (swift_red defaults to dark purple)
grstyle set color black: heading subheading axis_title body small_body text_option ///
    p#label p#boxlabel axis_label tick_label minortick_label key_label ///
    matrix_label legend_label sts_label
grstyle set color black: axis_line tick minortick

*Main colors: matches Figure 1 (T1 red, T2 orange, T3 forest green, T4 very dark
* green). Single grstyle call; otherwise the second call overwrites the first
* and bars revert to Stata defaults.
grstyle set color   "$c_T1_text" "$c_T2_text" "$c_T3_text" "$c_T4_text" "120 120 120" ///
                    "$c_T1_text" "$c_T2_text" "$c_T3_text" "$c_T4_text" "120 120 120" ///
                    "$c_T1_text" "$c_T2_text" "$c_T3_text" "$c_T4_text" "120 120 120" ///
                    : p# p#line p#lineplot p#bar p#area p#arealine p#pie histogram

*margins
grstyle set compact

*Font size -- print readability scale (~1.2x baseline)
grstyle set size 15pt: heading //titles (panel headers)
grstyle set size 13pt: subheading axis_title //axis titles
grstyle set size 12pt: p#label p#boxlabel body small_body text_option axis_label tick_label minortick_label key_label //all other text

}
* -------------------------------------------------


*--------------------------------------------------
* Run processing and analysis scripts
*--------------------------------------------------
* Entry-point guard
* -----------------
* 01_clean_survey.do rebuilds survey_clean.dta and panel_clean.dta FROM the raw
* survey workbooks. Those workbooks contain direct identifiers and are therefore
* NOT deposited (restricted; available from the authors under the IRB protocol).
*   - Author machine (raw present): 01 runs and rebuilds the de-identified
*     survey/panel data from scratch.
*   - Public replication (raw absent): 01 is skipped and the pipeline uses the
*     deposited de-identified processed/survey_clean.dta and panel_clean.dta.
* 02-05 run in both cases (02 reads the deposited fishery_game_raw.dta).
capture confirm file "$working_ANALYSIS/data/raw/Survey/3_-_Household-Survey-3 - Household-Survey.dta"
if _rc == 0 {
    di as txt ">>> Raw survey inputs found: running 01_clean_survey.do (full rebuild)."
    do "$working_ANALYSIS/code/01_clean_survey.do"
}
else {
    di as txt ">>> Raw survey inputs not present (restricted): skipping 01_clean_survey.do."
    di as txt ">>> Using the deposited de-identified survey_clean.dta / panel_clean.dta."
    capture confirm file "$working_ANALYSIS/processed/survey_clean.dta"
    if _rc {
        di as error "processed/survey_clean.dta not found. Do not delete /processed in the public package; it holds the deposited de-identified data."
        exit 601
    }
    capture confirm file "$working_ANALYSIS/processed/panel_clean.dta"
    if _rc {
        di as error "processed/panel_clean.dta not found. Do not delete /processed in the public package."
        exit 601
    }
}

* Cleaning / Generating + reshape
do "$working_ANALYSIS/code/02_clean_game.do"
do "$working_ANALYSIS/code/03_merge_reshape.do"

* Main paper figures and tables
do "$working_ANALYSIS/code/04_main_analysis.do"

* Supplementary information tables, figures, and robustness checks
do "$working_ANALYSIS/code/05_suppl_analysis.do"


* End log
di "End date and time: $S_DATE $S_TIME"
log close
 
 
 
** EOF