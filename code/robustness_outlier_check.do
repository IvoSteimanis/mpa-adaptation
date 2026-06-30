* Robustness: identify and drop outlier group with ~75% deterioration probability
* Quick check whether DiD treatment effects survive without this group

capture log close _all

if "$working_ANALYSIS" == "" {
    global working_ANALYSIS: pwd
}
global controls age gender married only_elementary hh_size ymonth

use "$working_ANALYSIS/processed/fishery_game_long.dta", clear
drop if village=="Batonan-Sur"

* --- Identify the outlier group ---
preserve
collapse (mean) prob_low100 destructive_choice100, by(treatment group_id)
gsort -prob_low100
di _n "=== Top 5 groups by Phase 3 deterioration probability ==="
list treatment group_id prob_low100 destructive_choice100 in 1/5

local outlier_group = group_id[1]
local outlier_treat = treatment[1]
local outlier_prob  = prob_low100[1]
di _n "Outlier group: `outlier_group' (T`outlier_treat'), prob_low100 = `outlier_prob'"
restore

* --- Baseline: full sample DiD (same as 04_main_analysis.do) ---
di _n "=== BASELINE: Full sample ==="

cap restore
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset unique_id round_number
mixed destructive_choice100 i.treatment##i.period $controls if period > 1, || group_id: || unique_id:, vce(robust)
est store baseline_nc
restore

cap restore
preserve
collapse (mean) prob_low100 $controls, by(treatment group_id round_number period)
xtset group_id round_number
mixed prob_low100 i.treatment##i.period $controls if period>1, || group_id:, vce(robust)
est store baseline_det
restore

* --- Robustness: drop outlier group ---
di _n "=== ROBUSTNESS: Dropping group `outlier_group' ==="

cap restore
preserve
drop if group_id == `outlier_group'
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset unique_id round_number
mixed destructive_choice100 i.treatment##i.period $controls if period > 1, || group_id: || unique_id:, vce(robust)
est store robust_nc
restore

cap restore
preserve
drop if group_id == `outlier_group'
collapse (mean) prob_low100 $controls, by(treatment group_id round_number period)
xtset group_id round_number
mixed prob_low100 i.treatment##i.period $controls if period>1, || group_id:, vce(robust)
est store robust_det
restore

* --- Compare ---
di _n "=== COMPARISON: Non-compliance DiD ==="
est table baseline_nc robust_nc, keep(2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) b(%5.2f) se(%5.2f) stats(N)

di _n "=== COMPARISON: Deterioration probability DiD ==="
est table baseline_det robust_det, keep(2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) b(%5.2f) se(%5.2f) stats(N)

di _n "=== Done ==="
