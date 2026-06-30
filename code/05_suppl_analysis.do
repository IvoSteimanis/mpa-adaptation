*--------------------------------------------------
* Description
*--------------------------------------------------
/* 
This do-files produces the results for additional analysis performed in Supplementary Information.
*/
*--------------------------------------------------
* Load Dataset
*--------------------------------------------------

use "$working_ANALYSIS/processed/fishery_game_long.dta", clear

drop if  village=="Batonan-Sur" /// they played twice (first time data was not saved)

encode village, gen(village_id)

*--------------------------------------------------
* Preparation
*--------------------------------------------------
global controls age gender married only_elementary hh_size ymonth

* Survey-only socio-economic indicators specific to the suppl. balance table
gen fish_main_occup = 0
replace fish_main_occup = 1 if fishing_main_occ < 3
gen skipped_meals = 0
replace skipped_meals = 1 if meals_12_months>1
gen no_savings = 0
replace no_savings = 1 if savings==0
gen yes_debts = 0
replace yes_debts = 1 if debts ==2 | debts==3

label var fish_main_occup "Fishing as main occupation"
label var fishery "Average income from fishing"
label var fishing_years "Years engaged in fishing"
label var meals_12_months "Less than enough meals in the last 12 month"
label define meals_12_months 0 "Never" 1 "Some months but not every month" 2 "Almost every month" 3 "Almost every week" 4 "Almost every day"
label var skipped_meals "Undernutrition on a monthly or more frequent basis"
label var no_savings "No savings"
label var yes_debts "In debt with more than 1000 PhP"

bys treatment : tab enforcement_type if round_number==7
bys treatment : tab enforcement_type if round_number==12
bys treatment : tab enforcement_type if round_number==18

*-----------------------------------------------------------
* Rule CHOICES across treatments before Game & Limited Changes
*-----------------------------------------------------------
** Suppl. Fig. 3 "Initial rule choices reveal flawed and inconsistent
** institutional designs" is built in PowerPoint, not Stata.
** Source file: Analysis/intial_rule_choices.pptx
** (The earlier Stata catplot draft has been removed -- it was missing the
** primary varlist and only ever ran under cap noisily.)

***************************

* (Suppl. Fig. -- "(Lack of) rule adaptation by treatment and phase")
* rule_change and individ_rule_change_call are now created in 03_merge_reshape.do.
bys  period: tab1 rule_change if treatment > 1

* (Supplem. Fig. 4 in  SI "(Lack of) rule adaptation by treatment and phase")
* rule_change and individ_rule_change_call are now created in 03_merge_reshape.do.

bys  period: tab1 rule_change if treatment > 1


cap restore
preserve
drop if treatment==1
drop if period==1

collapse (mean) rule_change individ_rule_change_call _gr_discussion_voting, by(group_id village_id treatment round_number)
xtset group_id round_number

twoway (scatter village_id round_number if rule_change!=0,           msymbol(diamond) msize(medlarge) mcolor(cranberry)) ///
       (scatter village_id round_number if individ_rule_change_call!=0, msymbol(circle)  msize(medsmall) mcolor(orange)) ///
       (scatter village_id round_number if _gr_discussion_voting!=0,    msymbol(square)  msize(vsmall)   mcolor(navy%70)), ///
    by(treatment, note("") rows(1) graphregion(margin(small))) ///
    ylab(1(1)21, valuelabel labsize(7pt) angle(0) noticks) ///
    ytitle("Village", size(9pt)) ///
    xla(7(1)18, nogrid labsize(8pt)) xtitle("Round number", size(9pt)) xline(12.5) ///
    subtitle(, size(10pt) margin(small) bcolor(none)) ///
    legend(order(1 "Successful rule change" 2 "Individual vote to change rules" 3 "Group discussion to change rules") rows(1) size(8pt) pos(6) ring(1)) ///
    xsize(5) ysize(2.5) scale(1)
cap noisily gr save  "$working_ANALYSIS/results/intermediate/fig_rule_inertia_game.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_rule_inertia_game.png", replace width(3165)
restore




***************************
*** TABLES for SUPPLEMENTARY INFORMATION
***************************

*****************
* Supplem. Table 4 Balance table - Socio-economic characteristics of a sample
*****************

gen treat_1 = (treatment == 1)
gen treat_2 = (treatment == 2)
gen treat_3 = (treatment == 3)
gen treat_4 = (treatment == 4)

global depvarlist age gender married only_elementary hh_size ymonth fish_main_occup fishery fishing_years skipped_meals no_savings yes_debts

cap restore
preserve
duplicates drop unique_id, force

gen all = 1
cap which balancetable
if _rc ssc install balancetable, replace
cap noisily balancetable (mean if all==1) (mean if treatment==1) (mean if treatment==2) (mean if treatment==3) (mean if treatment==4) (diff treat_2 if treatment!=3&treatment!=4 ) (diff treat_3 if treatment!=2&treatment!=4) (diff treat_4 if treatment!=2&treatment!=3) $depvarlist using "$working_ANALYSIS/results/si/tables/balance_table.xls", replace format(%9.2fc) varlabels vce(robust) ctitles("All(`=_N')" "T1" "T2" "T3" "T4") pvalues
restore

*Below is Wilcoxon test for differences in treatmnets from T1 for all variables in depvarlist (control variables) /// I do this Wilcoxon ranksum test separately because I can't run it inside balancetable command. Balance table has columns with difference in means (ttest as far as I understood), but it's preferrable to use Wilcoxon test because it doesn't assume normal distribution of data as ttest does. However, as far I see, there is no difference in results between Wilcoxon and ttest.

cap restore
preserve
duplicates drop unique_id, force

foreach var of global depvarlist {
	ranksum `var' if treatment<3, exact by(treat_2)
	gen p_`var'_2 = r(p) 
	egen signif_level_`var'_2 = cut(p_`var'_2), at(0.001 0.05 0.1) label
	
}

foreach var of global depvarlist {	
	ranksum `var' if treatment!=2&treatment!=4, exact by(treat_3)
	gen p_`var'_3 = r(p)
	egen signif_level_`var'_3 = cut(p_`var'_3), at(0.001 0.05 0.1) label
}

foreach var of global depvarlist {	
	ranksum `var' if treatment!=2&treatment!=3, exact by(treat_4)
	gen p_`var'_4 = r(p)
	egen signif_level_`var'_4 = cut(p_`var'_4), at(0.001 0.05 0.1) label
}
restore 

*****************
* Supplem. Table 5 - Association governance factors and enforcement participation
* IS LOCATED IN THE MAIN DO-FILE
*****************


*****************
* Supplem. Table 6 Treatment effects relative to open access baseline
* Supplem. Table 7 Treatments effects in response to climate stress
*****************

* Phase 1,2

*individual destructive behavior
cap restore
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table1_1: mixed destructive_choice100 i.treatment##i.period $controls if period <3, || group_id: || unique_id: , vce(robust) coeflegend
*matrix list e(b)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_u = exp(_b[lns2_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_u = sd_u^2
scalar var_e = sd_e^2
scalar total = var_g + var_u + var_e

scalar ICC_group = var_g/total
scalar ICC_indiv = var_u/total

estadd scalar ICC_group = ICC_group
estadd scalar ICC_indiv = ICC_indiv

* ----- Group counts -----
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]
scalar N_unique  = Ng[1,2]

estadd scalar Groups = N_groupid
estadd scalar Individuals = N_unique

restore

*group level analysis: group probabiliyt of going to low-state
cap restore
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table1_2: mixed prob_low100 i.treatment##i.period $controls if period <3, || group_id:  , vce(robust)
*matrix list e(b)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

eststo table1_3: mixed high_state100 i.treatment##i.period $controls if period <3, || group_id:  , vce(robust) 

estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

restore

esttab table1_1 table1_2 table1_3  using "$working_ANALYSIS/results/si/tables/did_baseline_to_governance.rtf", keep(2.treatment 3.treatment 4.treatment 2.period 2.treatment#2.period 3.treatment#2.period 4.treatment#2.period age gender married only_elementary hh_size ymonth _cons) nogaps label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) stats(N Groups Individuals ICC_group ICC_indiv, labels("N" "Groups" "Individuals" "ICC (group)" "ICC (indiv|group)") fmt(%4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nonotes addnotes("Notes: Multilevel regression modeling non-compliance, deterioration probability and state of the fishing ground  as a function of treatment and period. Robust standard errors in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01") replace

* (orphan stats() line removed -- not attached to esttab)

* Phase 3 (Suppl. Table 7)

*individual destructive behavior
cap restore
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table2_1: mixed destructive_choice100 i.treatment##i.period  $controls if period > 1, || group_id: || unique_id: , vce(robust)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_u = exp(_b[lns2_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_u = sd_u^2
scalar var_e = sd_e^2
scalar total = var_g + var_u + var_e

scalar ICC_group = var_g/total
scalar ICC_indiv = var_u/total

estadd scalar ICC_group = ICC_group
estadd scalar ICC_indiv = ICC_indiv

* ----- Group counts -----
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]
scalar N_unique  = Ng[1,2]

estadd scalar Groups = N_groupid
estadd scalar Individuals = N_unique

* --- Store p-values for multiple testing (main T×Phase3 terms) ---

test 2.treatment#3.period
scalar p1 = r(p)

test 3.treatment#3.period
scalar p2 = r(p)

test 4.treatment#3.period
scalar p3 = r(p)

restore

*group level outcomes: group probability of going to low-state & actual outcome
cap restore
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table2_2: mixed prob_low100 i.treatment##i.period $controls if period>1, || group_id:  , vce(robust)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

eststo table2_3: mixed high_state100 i.treatment##i.period $controls if period>1, || group_id:  , vce(robust)

estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid
restore


esttab table2_1 table2_2 table2_3   using "$working_ANALYSIS/results/si/tables/did_governance_to_climate_shock.rtf", keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period age gender married only_elementary hh_size ymonth _cons) nogaps label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) stats(N Groups Individuals ICC_group ICC_indiv, labels("N" "Groups" "Individuals" "ICC (group)" "ICC (indiv|group)") fmt(%4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nonotes addnotes("Notes: Multilevel regression modeling non-compliance, deterioration probability and state of the fishing ground  as a function of treatment and period. Robust standard errors in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01") replace

*******************************
***Supplem. Table 8 - DESTRUCTIVE BEHAVIOR *** AKA *** Parallel trends test for Phase 2
*******************************

* 1. Round-by-round trajectories by treatment for the three main outcomes
*    (combined into a single SI figure: figureS_outcomes_over_rounds)

* --- Panel A: Non-compliance over 18 rounds ---
cap restore
preserve
collapse (mean) destructive_choice100, by(treatment round_number)
twoway (line destructive_choice100 round_number if treatment==1, lp(solid)     recast(connected) lcolor("$c_T1_text") mcolor("$c_T1_text") msymbol(T)) ///
       (line destructive_choice100 round_number if treatment==2, lp(dash)      recast(connected) lcolor("$c_T2_text") mcolor("$c_T2_text") msymbol(S)) ///
       (line destructive_choice100 round_number if treatment==3, lp(shortdash) recast(connected) lcolor("$c_T3_text") mcolor("$c_T3_text") msymbol(D)) ///
       (line destructive_choice100 round_number if treatment==4, lp(longdash)  recast(connected) lcolor("$c_T4_text") mcolor("$c_T4_text") msymbol(O)), ///
       title("{bf:A} Non-compliance Rate", size(11pt)) ///
       legend(off) ///
       ytitle("Share of cases", size(9pt)) xtitle("Round number", size(9pt)) ///
       xla(1(1)18, nogrid labsize(8pt)) ///
       ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%" 20 "20%", nogrid labsize(8pt)) ///
       xline(6.5 12.5, lstyle(reference)) ///
       graphregion(margin(zero))
gr save "$working_ANALYSIS/results/intermediate/_traj_noncomp.gph", replace
restore

* --- Panel B: Deterioration probability over 18 rounds ---
cap restore
preserve
collapse (mean) prob_low100, by(treatment round_number)
twoway (line prob_low100 round_number if treatment==1, lp(solid)     recast(connected) lcolor("$c_T1_text") mcolor("$c_T1_text") msymbol(T)) ///
       (line prob_low100 round_number if treatment==2, lp(dash)      recast(connected) lcolor("$c_T2_text") mcolor("$c_T2_text") msymbol(S)) ///
       (line prob_low100 round_number if treatment==3, lp(shortdash) recast(connected) lcolor("$c_T3_text") mcolor("$c_T3_text") msymbol(D)) ///
       (line prob_low100 round_number if treatment==4, lp(longdash)  recast(connected) lcolor("$c_T4_text") mcolor("$c_T4_text") msymbol(O)), ///
       title("{bf:B} Deterioration Probability", size(11pt)) ///
       legend(off) ///
       ytitle("Probability of stock collapse", size(9pt)) xtitle("Round number", size(9pt)) ///
       xla(1(1)18, nogrid labsize(8pt)) ///
       ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%", nogrid labsize(8pt)) ///
       xline(6.5 12.5, lstyle(reference)) ///
       graphregion(margin(zero))
gr save "$working_ANALYSIS/results/intermediate/_traj_prob.gph", replace
restore

* --- Panel C: High-resource state over 18 rounds ---
cap restore
preserve
collapse (mean) high_state100, by(treatment round_number)
twoway (line high_state100 round_number if treatment==1, lp(solid)     recast(connected) lcolor("$c_T1_text") mcolor("$c_T1_text") msymbol(T)) ///
       (line high_state100 round_number if treatment==2, lp(dash)      recast(connected) lcolor("$c_T2_text") mcolor("$c_T2_text") msymbol(S)) ///
       (line high_state100 round_number if treatment==3, lp(shortdash) recast(connected) lcolor("$c_T3_text") mcolor("$c_T3_text") msymbol(D)) ///
       (line high_state100 round_number if treatment==4, lp(longdash)  recast(connected) lcolor("$c_T4_text") mcolor("$c_T4_text") msymbol(O)), ///
       title("{bf:C} High Resource State", size(11pt)) ///
       legend(on order(1 "{it:Fixed} (T1)" 2 "{it:Constrained} (T2)" 3 "{it:Flexible} (T3)" 4 "{it:Open} (T4)") rows(1) pos(6) ring(1) size(9pt)) ///
       ytitle("Share of groups", size(9pt)) xtitle("Round number", size(9pt)) ///
       xla(1(1)18, nogrid labsize(8pt)) ///
       ylabel(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", nogrid labsize(8pt)) ///
       xline(6.5 12.5, lstyle(reference)) ///
       graphregion(margin(zero))
gr save "$working_ANALYSIS/results/intermediate/_traj_state.gph", replace
restore

* --- Combine 3 panels (single legend at bottom from Panel C) ---
cap noisily grc1leg "$working_ANALYSIS/results/intermediate/_traj_noncomp.gph" ///
                    "$working_ANALYSIS/results/intermediate/_traj_prob.gph" ///
                    "$working_ANALYSIS/results/intermediate/_traj_state.gph", ///
            rows(3) xsize(7) ysize(8) ///
            legendfrom("$working_ANALYSIS/results/intermediate/_traj_state.gph")
gr save   "$working_ANALYSIS/results/intermediate/figureS_outcomes_over_rounds.gph", replace
gr export "$working_ANALYSIS/results/si/figures/fig_outcomes_over_rounds.png", replace width(2400)

* (Standalone destr.png removed 2026-05-04 — superseded by 3-panel
*  figureS_outcomes_over_rounds.png above.)


*===========================================================================
* Fig. S7: Round-by-round trajectories of the two component decisions.
*   Panel A: share entering the protected spawning area (_pl_area_choice).
*   Panel B: share using intensive (destructive) methods (_pl_effort_choice).
*   Treatments overlaid as lines; phase boundaries marked.
* Fig. S8: Composition of non-compliance, by treatment x phase.
*   Four-category partition: Compliant / Methods only / Area only / Both.
*   Compliant excluded from the bar; bars sum to 100% within each cell.
*===========================================================================

* Component-share variables for the trajectory figure.
cap drop area100
cap drop methods100
gen byte area100    = _pl_area_choice   * 100
gen byte methods100 = _pl_effort_choice * 100
label var area100    "Spawning area entry (%)"
label var methods100 "Intensive methods (%)"

* Joint partition variable for the composition figure.
cap drop choice4
gen byte choice4 = .
replace choice4 = 1 if _pl_area_choice == 0 & _pl_effort_choice == 0
replace choice4 = 2 if _pl_area_choice == 0 & _pl_effort_choice == 1
replace choice4 = 3 if _pl_area_choice == 1 & _pl_effort_choice == 0
replace choice4 = 4 if _pl_area_choice == 1 & _pl_effort_choice == 1
label define choice4_lbl 1 "Compliant" 2 "Methods only" 3 "Area only" 4 "Both", replace
label values choice4 choice4_lbl
label var choice4 "Joint area-method choice"

* --- Fig. S7: two-panel trajectories (area + methods) by treatment. ---
cap restore
preserve
collapse (mean) area100 methods100, by(treatment round_number)

twoway (line area100 round_number if treatment==1, lp(solid)     recast(connected) lcolor("$c_T1_text") mcolor("$c_T1_text") msymbol(T)) ///
       (line area100 round_number if treatment==2, lp(dash)      recast(connected) lcolor("$c_T2_text") mcolor("$c_T2_text") msymbol(S)) ///
       (line area100 round_number if treatment==3, lp(shortdash) recast(connected) lcolor("$c_T3_text") mcolor("$c_T3_text") msymbol(D)) ///
       (line area100 round_number if treatment==4, lp(longdash)  recast(connected) lcolor("$c_T4_text") mcolor("$c_T4_text") msymbol(O)), ///
       title("{bf:A} Spawning area entry", size(11pt)) ///
       legend(off) ///
       ytitle("Share of fisher-rounds", size(9pt)) xtitle("Round", size(9pt)) ///
       xla(1(1)18, nogrid labsize(8pt)) ///
       ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%", nogrid labsize(8pt)) ///
       xline(6.5 12.5, lpattern(dash) lcolor(gs10)) ///
       graphregion(margin(zero)) name(_traj_area, replace)
gr save "$working_ANALYSIS/results/intermediate/_traj_area.gph", replace

twoway (line methods100 round_number if treatment==1, lp(solid)     recast(connected) lcolor("$c_T1_text") mcolor("$c_T1_text") msymbol(T)) ///
       (line methods100 round_number if treatment==2, lp(dash)      recast(connected) lcolor("$c_T2_text") mcolor("$c_T2_text") msymbol(S)) ///
       (line methods100 round_number if treatment==3, lp(shortdash) recast(connected) lcolor("$c_T3_text") mcolor("$c_T3_text") msymbol(D)) ///
       (line methods100 round_number if treatment==4, lp(longdash)  recast(connected) lcolor("$c_T4_text") mcolor("$c_T4_text") msymbol(O)), ///
       title("{bf:B} Intensive (destructive) methods", size(11pt)) ///
       legend(on order(1 "{it:Fixed} (T1)" 2 "{it:Constrained} (T2)" 3 "{it:Flexible} (T3)" 4 "{it:Open} (T4)") rows(1) pos(6) size(9pt)) ///
       ytitle("Share of fisher-rounds", size(9pt)) xtitle("Round", size(9pt)) ///
       xla(1(1)18, nogrid labsize(8pt)) ///
       ylabel(0 "0%" 5 "5%" 10 "10%" 15 "15%", nogrid labsize(8pt)) ///
       xline(6.5 12.5, lpattern(dash) lcolor(gs10)) ///
       graphregion(margin(zero)) name(_traj_methods, replace)
gr save "$working_ANALYSIS/results/intermediate/_traj_methods.gph", replace

cap noisily grc1leg "$working_ANALYSIS/results/intermediate/_traj_area.gph" ///
                    "$working_ANALYSIS/results/intermediate/_traj_methods.gph", ///
            rows(1) xsize(9) ysize(4) ///
            legendfrom("$working_ANALYSIS/results/intermediate/_traj_methods.gph")
gr save   "$working_ANALYSIS/results/intermediate/figureS7_area_methods_traj.gph", replace
gr export "$working_ANALYSIS/results/si/figures/fig_area_methods_over_rounds.png", replace width(2400)
restore

* --- Composition of non-compliance, by treatment x phase. ---
*     Each bar sums to 100% of non-compliers in its cell.
*     n_NC (count of non-compliant fisher-rounds) shown in each row label.
*     Severity-ramp colors: yellow -> orange -> red.
cap restore
preserve
gen byte _is_nc      = (choice4 > 1)
gen byte _is_methods = (choice4 == 2)
gen byte _is_area    = (choice4 == 3)
gen byte _is_both    = (choice4 == 4)

collapse (sum) _is_methods _is_area _is_both _is_nc, by(period treatment)

gen pct_methods = _is_methods / _is_nc * 100
gen pct_area    = _is_area    / _is_nc * 100
gen pct_both    = _is_both    / _is_nc * 100

local trt_names    `" "Fixed" "Constrained" "Flexible" "Open" "'
local phase_titles `" "Phase 1: Baseline" "Phase 2: Governance" "Phase 3: Climate shock" "'

forvalues p = 1/3 {
    cap label drop lbl_p`p'
    forvalues t = 1/4 {
        local nm : word `t' of `trt_names'
        qui sum _is_nc if treatment == `t' & period == `p', mean
        local nv = r(mean)
        label define lbl_p`p' `t' `"`nm' (n=`nv')"', modify
    }
    cap drop trt_lbl_p`p'
    gen trt_lbl_p`p' = treatment if period == `p'
    label values trt_lbl_p`p' lbl_p`p'

    local ttl : word `p' of `phase_titles'

    if `p' == 3 {
        local legopt `"legend(on order(1 "Methods only" 2 "Area only" 3 "Both") rows(1) pos(6) size(9pt))"'
    }
    else {
        local legopt "legend(off)"
    }

    graph hbar (sum) pct_methods pct_area pct_both if period == `p', ///
        over(trt_lbl_p`p', label(labsize(8pt))) ///
        stack ///
        bar(1, color("255 215 0")) ///
        bar(2, color("255 140 0")) ///
        bar(3, color("178 34 34")) ///
        blabel(bar, format(%2.0f) position(center) color(white) size(8pt)) ///
        `legopt' ///
        ytitle("Composition of non-compliance (%)", size(9pt)) ///
        ylabel(0(25)100, nogrid labsize(8pt)) ///
        title("`ttl'", size(11pt)) ///
        graphregion(margin(zero)) name(_choice4_p`p', replace)
    gr save "$working_ANALYSIS/results/intermediate/_choice4_p`p'.gph", replace
}

cap noisily grc1leg "$working_ANALYSIS/results/intermediate/_choice4_p1.gph" ///
                    "$working_ANALYSIS/results/intermediate/_choice4_p2.gph" ///
                    "$working_ANALYSIS/results/intermediate/_choice4_p3.gph", ///
            rows(1) xsize(11) ysize(4) ///
            legendfrom("$working_ANALYSIS/results/intermediate/_choice4_p3.gph")
gr save   "$working_ANALYSIS/results/intermediate/figureS7b_choice4_bar.gph", replace
gr export "$working_ANALYSIS/results/si/figures/fig_choice4_byphase.png", replace width(2400)
restore

* --- Fig. S1 (renumbered): game earnings by treatment x phase ---
* Strip plot showing distribution of per-phase earnings across players, by treatment.
* Variables: P1_pl_total_payoff, P2_pl_total_payoff, P3_pl_total_payoff (PHP).
cap ssc install stripplot, replace

cap restore
preserve
use "$working_ANALYSIS/processed/fishery_game_wide.dta", clear

* Reshape phase-payoff variables to long
keep unique_id treatment P1_pl_total_payoff P2_pl_total_payoff P3_pl_total_payoff
rename P1_pl_total_payoff phase_payoff1
rename P2_pl_total_payoff phase_payoff2
rename P3_pl_total_payoff phase_payoff3
reshape long phase_payoff, i(unique_id) j(phase)
label define phase_lbl 1 "Phase 1 (baseline)" 2 "Phase 2 (governance)" 3 "Phase 3 (climate shock)", replace
label values phase phase_lbl

* Canonical treatment labels (T1=Fixed ... T4=Open) -- re-apply inline because
* the value label sometimes does not survive the keep + reshape above.
label define treat_lbl 1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}", replace
label values treatment treat_lbl

stripplot phase_payoff if !missing(phase_payoff, treatment, phase), ///
    over(treatment) by(phase, cols(3) compact note("") title("") imargin(small)) ///
    vertical jitter(3) ///
    msymbol(oh) msize(0.9) mcolor(navy) ///
    box(lwidth(thin) blcolor(black) bfcolor(none) barwidth(0.45)) ///
    yla(100(50)400, nogrid labsize(8pt)) ///
    ytitle("Per-phase earnings (PHP)", size(9pt)) ///
    xla(, labsize(9pt)) xtitle("") ///
    subtitle(, size(10pt) margin(small) bcolor(none)) ///
    xsize(7) ysize(4) ///
    graphregion(margin(small) color(white))

cap noisily gr save   "$working_ANALYSIS/results/intermediate/figureS_game_earnings.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_game_earnings_by_phase.png", replace width(2400)
restore

{
/*drop destr_choice_1 destr_choice_2 destr_choice_3
bysort treatment: egen destr_choice_1 = mean(destructive_choice) if period==1
bysort treatment: egen destr_choice_2 = mean(destructive_choice) if period==2
bysort treatment: egen destr_choice_3 = mean(destructive_choice) if period==3

*Period 1 vs period 2 vs period 3
cap restore
preserve 
*drop if period==3
collapse (mean) destr_choice_1 destr_choice_2 destr_choice_3, by(treatment period)

graph bar (mean) destr_choice_1 destr_choice_2 destr_choice_3, over(treatment) title("{bf: B} Destructive behavior incidents") ytitle("Share of cases") ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "15%" 0.2 "20%", nogrid) bargap(0) legend(label(1 "Phase 1") label(2 "Phase 2") label(3 "Phase 3"))
*gr display, scale(1.2)
gr save  "$working_ANALYSIS/results/intermediate/viol.gph", replace
gr export  "$working_ANALYSIS/results/si/figures/fig_destructive_violins.tif", replace


graph combine "$working_ANALYSIS/results/intermediate/destr.gph" "$working_ANALYSIS/results/intermediate/viol.gph", col(2) xsize(10.000) ysize(3.000) saving("$working_ANALYSIS/results/dest_incid_combined.gph", replace)
gr display, scale(1.4)
gr export  "$working_ANALYSIS/results/si/figures/fig_destructive_incidence_combined.tif", replace
*/
}

* USED - 2. Formal pre-trend test (treat x round, jointly insignific.)
cap restore   // clear any dangling preserve from the dead-code block above
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  

eststo table8_1: mixed destructive_choice100 i.treatment##c.round_number $controls if period==2, || group_id:  || unique_id: , vce(robust)
testparm i.treatment#c.round_number
eststo table8_1: mixed destructive_choice100 i.treatment##c.round_number $controls if period==2, || group_id:  || unique_id: , vce(robust)

estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_u = exp(_b[lns2_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_u = sd_u^2
scalar var_e = sd_e^2
scalar total = var_g + var_u + var_e

scalar ICC_group = var_g/total
scalar ICC_indiv = var_u/total

estadd scalar ICC_group = ICC_group
estadd scalar ICC_indiv = ICC_indiv

matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]
scalar N_unique  = Ng[1,2]

estadd scalar Groups = N_groupid
estadd scalar Individuals = N_unique
restore

*group level outcomes: group probability of going to low-state & actual outcome
cap restore
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table8_2: mixed prob_low100 i.treatment##c.round_number $controls if period==2, || group_id:  , vce(robust)
testparm i.treatment#c.round_number

eststo table8_2: mixed prob_low100 i.treatment##c.round_number $controls if period==2, || group_id:  , vce(robust)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid


eststo table8_3: mixed high_state100 i.treatment##c.round_number $controls if period==2, || group_id:  , vce(robust)
testparm i.treatment#c.round_number

eststo table8_3: mixed high_state100 i.treatment##c.round_number $controls if period==2, || group_id:  , vce(robust)
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

restore


esttab table8_1 table8_2 table8_3 using "$working_ANALYSIS/results/si/tables/parallel_trends_phase2.rtf", keep(2.treatment 3.treatment 4.treatment round_number 2.treatment#c.round_number 3.treatment#c.round_number 4.treatment#c.round_number age gender married only_elementary hh_size ymonth _cons) nogaps label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) stats(N Groups Individuals ICC_group ICC_indiv, labels("N" "Groups" "Individuals" "ICC (group)" "ICC (indiv|group)") fmt(%4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nonotes addnotes("Notes: Multilevel regression modeling non-compliance, deterioration probability and state of the fishing ground  as a function of treatment and period. Robust standard errors in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01") replace
	


************************************
* Supplem. Table 9 Climate shock across endogenously selected enforcement regime
************************************
*endogenously chosen enforcement regimes
*individual destructive behavior
cap restore
preserve
collapse (mean) destructive_choice100 enforcement_type $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table3_1: mixed destructive_choice100  i.enforcement_type##i.period $controls  if period>1, || group_id: || unique_id: , vce(robust) 
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_u = exp(_b[lns2_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_u = sd_u^2
scalar var_e = sd_e^2
scalar total = var_g + var_u + var_e

scalar ICC_group = var_g/total
scalar ICC_indiv = var_u/total

estadd scalar ICC_group = ICC_group
estadd scalar ICC_indiv = ICC_indiv

matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]
scalar N_unique  = Ng[1,2]

estadd scalar Groups = N_groupid
estadd scalar Individuals = N_unique

restore

*group outcomes
cap restore
preserve
collapse (mean) prob_low100 high_state100 enforcement_type $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table3_2: mixed prob_low100 i.enforcement_type##i.period $controls if period>1, || group_id:  , vce(robust)  
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

eststo table3_3: mixed high_state100 i.enforcement_type##i.period $controls if period>1, || group_id:  , vce(robust) 
estat icc
scalar sd_g = exp(_b[lns1_1_1:_cons])
scalar sd_e = exp(_b[lnsig_e:_cons])

scalar var_g = sd_g^2
scalar var_e = sd_e^2
scalar total = var_g + var_e

scalar ICC_group = var_g/total

estadd scalar ICC_group = ICC_group
matrix Ng = e(N_g)
matrix list Ng
scalar N_groupid = Ng[1,1]

estadd scalar Groups = N_groupid

restore

esttab table3_1 table3_2 table3_3  using "$working_ANALYSIS/results/si/tables/did_enforcement_regimes_climate_shock.rtf", keep(2.enforcement_type 3.enforcement_type 3.period 2.enforcement_type#3.period 3.enforcement_type#3.period age gender married only_elementary hh_size ymonth _cons) nogaps label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) stats(N Groups Individuals ICC_group ICC_indiv, labels("N" "Groups" "Individuals" "ICC (group)" "ICC (indiv|group)") fmt(%4.0f %4.0f %4.0f %4.2f))  star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nonotes addnotes("Notes: Multilevel regression modeling non-compliance, deterioration probability and state of the fishing ground  as a function of enforcement regime and period. Robust standard errors in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01") replace


*===========================================================================
* Table S28 — Treatment effects on perceived autonomy, social cohesion, and
* governance quality (alpha-averaged composites; matches main paper Fig. 5).
*
* 2026-05-08: Replaced the prior PCA-based block (overall_quality /
* perceived_friction / perceived_autonomy) so the SI table reflects the
* same alpha-averaged scales as Fig. 5 of the main paper. The PCA loadings
* table that previously sat below was also dropped; it was an orphan
* (not referenced anywhere in the SI).
*===========================================================================

cap restore
preserve
keep if round_number == 1
duplicates drop unique_id, force

* --- Social Cohesion: 5-item alpha-averaged composite (alpha ≈ 0.72) ---
cap drop social_cohesion
alpha exp_cdp1 exp_cdp5 exp_cdp6 exp_cdp10 exp_cdp14, gen(social_cohesion) item
local alpha_sc : di %4.2f r(alpha)
di "Cronbach's alpha — Social Cohesion: `alpha_sc'"
lab var social_cohesion "Social Cohesion (perceived)"

* --- Governance Quality: 5-item alpha-averaged composite (alpha ≈ 0.80) ---
* Excluded by design (see SI S3.8 for rationale):
*   cdp13 ("impartial mediator") -- no third-party arbiter exists in any treatment
*   cdp17 ("leader had enough power") -- leader role endogenous to treatment
*   cdp16r ("excessive external regulation") -- measures perceived regulatory
*           burden, not internal governance quality; does not behave as a
*           manipulation check (corr with cdp18 = -0.18; 2-item alpha = 0.28).
cap drop governance_quality
alpha exp_cdp7 exp_cdp8 exp_cdp9 exp_cdp11 exp_cdp15, gen(governance_quality) item
local alpha_gq : di %4.2f r(alpha)
di "Cronbach's alpha — Governance Quality: `alpha_gq'"
lab var governance_quality "Governance Quality (perceived)"

* --- Standardize to z-scores ---
foreach var of varlist exp_cdp18 social_cohesion governance_quality {
    qui sum `var'
    cap drop z_`var'
    gen z_`var' = (`var' - r(mean)) / r(sd)
}
lab var z_exp_cdp18          "Autonomy (z-score)"
lab var z_social_cohesion    "Social Cohesion (perceived) (z-score)"
lab var z_governance_quality "Governance Quality (perceived) (z-score)"

* --- Cleaner display labels for control rows in Table S28 ---
lab var age              "Age in years"
lab var gender           "Female"
lab var married          "Married"
lab var only_elementary  "Only elementary education"
lab var hh_size          "HH size"
lab var ymonth           "HH income in PHP"

* --- Regressions: Autonomy, Social Cohesion, Governance Quality ---
* Six-column layout: each outcome reported without (cols 1, 3, 5) and with
* (cols 2, 4, 6) enumerator (assist) fixed effects so readers can see that
* between-RA variation in question delivery does not move the treatment
* coefficients.
eststo clear
eststo m_aut:    reg exp_cdp18            i.treatment $controls,           cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "No"
eststo m_aut_fe: reg exp_cdp18            i.treatment $controls i.assist,  cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "Yes"
eststo m_sc:     reg social_cohesion      i.treatment $controls,           cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "No"
eststo m_sc_fe:  reg social_cohesion      i.treatment $controls i.assist,  cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "Yes"
eststo m_gq:     reg governance_quality    i.treatment $controls,          cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "No"
eststo m_gq_fe:  reg governance_quality    i.treatment $controls i.assist, cluster(group_id)
estadd scalar R2  = e(r2)
estadd local FE   "Yes"

esttab m_aut m_aut_fe m_sc m_sc_fe m_gq m_gq_fe ///
    using "$working_ANALYSIS/results/si/tables/cdp_treatment_effects.rtf", ///
    keep(2.treatment 3.treatment 4.treatment $controls _cons) ///
    nogaps label se(%4.2f) b(%4.2f) ///
    stats(FE N N_clust R2, labels("Enumerator FE" "N" "Clusters" "R-squared") fmt(%s %4.0f %4.0f %4.2f)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Autonomy" "Autonomy w/ FE" "Cohesion" "Cohesion w/ FE" "Gov. Quality" "Gov. Quality w/ FE") ///
    varlabels(_cons "Constant") ///
    nonotes addnotes("Notes: OLS regressions with group-clustered standard errors. Each outcome is shown without (cols 1, 3, 5) and with (cols 2, 4, 6) enumerator fixed effects (assist). Dependent variables are on the raw 0-10 Likert scale: (cols 1-2) the autonomy manipulation check (single item), (cols 3-4) Social Cohesion (5-item alpha-averaged scale, alpha = `alpha_sc'), and (cols 5-6) Governance Quality (5-item alpha-averaged scale, alpha = `alpha_gq'). Item composition is documented in Table S27. {it:Fixed} (T1) is the omitted reference category. Standard errors in parentheses. * p < 0.10, ** p < 0.05, *** p < 0.01.") replace

restore



************************************
* Supplem. Table 12 Logistic Regression Predicting Individual Support for Rule Change
************************************
***2. Logit regression model to test what affects rule change intensions

* rule_change, individ_rule_change_call, destructive_choice_group,
* lagged_destructive_choice1 are now created in 03_merge_reshape.do.

global controls age gender married only_elementary hh_size ymonth

cap restore   // close the Suppl Table 11 PCA preserve before starting Table 12 logit
preserve
drop if period==1
drop if treatment==1

* Cleaner Table S26 variable labels (overrides the descriptive labels from 03)
* — paper-consistent, more explicit about what each indicator captures.
label var individ_rule_change_call    "Voted for rule change"
label var _pl_leader_role             "Ind. - Leader role (this round)"
label var _pl_discussion_choice       "Ind. - Called for discussion"
label var _gr_low_state               "Gr. - Resource at low state (t-1)"
label var destructive_choice_group    "Gr. - Any defection (this round)"
label var lagged_destructive_choice1  "Gr. - Any defection (t-1)"

xtset  unique_id round_number

eststo table_vote: logit individ_rule_change_call _pl_leader_role _pl_discussion_choice _gr_low_state destructive_choice_group lagged_destructive_choice1  $controls, cluster(group_id)
estadd scalar pseudoR2 = e(r2_p)

* Robustness/mechanism table (Table S26): drop controls from display per
* user direction 2026-05-07; mention in addnotes that they are included.
esttab table_vote using "$working_ANALYSIS/results/si/tables/rule_change_vote_logit.rtf", drop($controls _cons) nogaps label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.3f) stats(N N_clust pseudoR2, labels("N" "Cluster" "Pseudo R-squared") fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) mtitles("Voted for rule change") varlabels(,elist(weight:_cons "{break}{hline @width}")) nonotes addnotes("Notes: Logistic regression of individual support for rule change (constitutional and/or operational), Phases 2 and 3 only. (Ind.) = individual-level regressor; (Gr.) = group-level regressor constructed from peers. (t-1) = one-round lag. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Standard errors clustered at the group level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01") replace

*************************
*** Endgame effect - Suppl. Table S22
*************************
* endgame_round is now created in 03_merge_reshape.do.

cap restore
preserve
drop if period!=3

gen high_state = high_state100/100
* Logistic regression for phase 3 to test treatment and endgame effects

logit destructive_choice i.treatment##i.endgame_round i.endgame_round##i.high_state, cluster(group_id)

eststo table1: logit destructive_choice i.endgame_round##i.high_state if treatment==1, cluster(group_id)
estadd scalar pseudoR2 = e(r2_p)
eststo table2: logit destructive_choice i.endgame_round##i.high_state if treatment==2, cluster(group_id)
estadd scalar pseudoR2 = e(r2_p)
eststo table3: logit destructive_choice i.endgame_round##i.high_state if treatment==3, cluster(group_id)
estadd scalar pseudoR2 = e(r2_p)
eststo table4: logit destructive_choice i.endgame_round##i.high_state if treatment==4, cluster(group_id)
estadd scalar pseudoR2 = e(r2_p)

* Per-treatment endgame logit: this specification omits individual controls
* by design; the within-treatment endgame mechanism is identified from the
* round x resource-state interaction. Note in addnotes flags this so reviewers
* don't expect controls.
esttab table1 table2 table3 table4 using "$working_ANALYSIS/results/si/tables/endgame_per_treatment_logit.rtf", nogaps label nobaselevels mtitles("{it:Fixed} (T1)" "{it:Constrained} (T2)" "{it:Flexible} (T3)" "{it:Open} (T4)") se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.3f) stats(N N_clust pseudoR2, labels("N" "Cluster" "Pseudo R-squared") fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) nonotes addnotes("Notes: Treatment-specific logistic regressions of non-compliance on a Final-2-rounds dummy interacted with the high-resource-state indicator (Phase 3 only). Final 2 rounds is a dummy equal to one in rounds 17-18 and zero in rounds 13-16. High Resource State indicates that the resource is in the high-stock condition. Each model includes 21 groups, with standard errors clustered at the group level. T1 has fewer observations (N=525 vs 630) because rounds in which destructive actions perfectly predicted the outcome were dropped from the logistic estimation. Standard errors in parentheses: * p<0.10, ** p<0.05, *** p<0.01.") replace

cap restore

*--------------------------------------------------
* (a) Phase 1 baseline equivalence across treatments
*--------------------------------------------------
* Tests that BEHAVIORAL outcomes in Phase 1 (open-access, rounds 1-6, no governance)
* do not differ across the four treatment assignments. T1 (Fixed) is omitted reference.
* Joint F-test for any treatment difference is reported per outcome.

eststo clear

di _n(2) "============================================================"
di "PHASE 1 BASELINE EQUIVALENCE"
di "============================================================"

* destructive_choice100: individual-round level
eststo p1_dest: mixed destructive_choice100 i.treatment $controls if period==1, ///
    || group_id: || unique_id: , vce(robust)
test 2.treatment 3.treatment 4.treatment
estadd scalar joint_p = r(p)
estadd scalar joint_F = r(F)

* prob_low100: group-round level
eststo p1_prob: mixed prob_low100 i.treatment $controls if period==1, ///
    || group_id: , vce(robust)
test 2.treatment 3.treatment 4.treatment
estadd scalar joint_p = r(p)
estadd scalar joint_F = r(F)

* high_state100: group-round level
eststo p1_high: mixed high_state100 i.treatment $controls if period==1, ///
    || group_id: , vce(robust)
test 2.treatment 3.treatment 4.treatment
estadd scalar joint_p = r(p)
estadd scalar joint_F = r(F)

esttab p1_dest p1_prob p1_high ///
    using "$working_ANALYSIS/results/si/tables/phase1_baseline_equivalence.rtf", ///
    replace ///
    keep(2.treatment 3.treatment 4.treatment _cons) ///
    nogaps label se b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("Non-compliance" "Deterioration prob." "High resource state") ///
    stats(joint_F joint_p N_g N, fmt(%9.2f %9.3f %9.0f %9.0f) ///
        labels("Joint F (T2=T3=T4=0)" "Joint p" "Groups" "N (obs)")) ///
    title("Supplementary Table. Phase 1 baseline equivalence across treatments") ///
    addnotes("Multilevel mixed-effects models with random intercepts at group and (where applicable) participant level; robust standard errors." ///
             "Sample restricted to Phase 1 (rounds 1-6, open-access baseline before any governance is introduced)." ///
             "{it:Fixed} (T1) is the omitted reference. Joint F-test reports H0: T2=T3=T4=0." ///
             "Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity." ///
             "Failure to reject H0 supports the random-assignment claim that pre-treatment behavioral outcomes are balanced across arms." ///
             "* p<0.10, ** p<0.05, *** p<0.01")

di _n(2) "Phase 1 balance table written to: $working_ANALYSIS/results/si/tables/phase1_baseline_equivalence.rtf"

*--------------------------------------------------
* (b) DiD with group fixed effects
*--------------------------------------------------
* Re-estimates the main DiD specifications (Suppl Table 7) with group fixed effects
* via areg. Group FE absorb any time-invariant group-level variation, including
* the field-team member assigned to each group (group-constant by design).
* Treatment main effects are absorbed by group FE since treatment is randomized
* at the group level. Treatment x Phase 3 interactions are identified from
* within-group variation across phases.

eststo clear

di _n(2) "============================================================"
di "DiD WITH GROUP FIXED EFFECTS"
di "============================================================"

* destructive_choice100: individual-round level
eststo grp_dest:  areg destructive_choice100 i.treatment##i.period $controls if period > 1, ///
    absorb(group_id) vce(cluster group_id)

* prob_low100: group-round level
eststo grp_prob:  areg prob_low100 i.treatment##i.period $controls if period > 1, ///
    absorb(group_id) vce(cluster group_id)

* high_state100: group-round level
eststo grp_high:  areg high_state100 i.treatment##i.period $controls if period > 1, ///
    absorb(group_id) vce(cluster group_id)

esttab grp_dest grp_prob grp_high ///
    using "$working_ANALYSIS/results/si/tables/did_robustness_group_fe.rtf", ///
    replace ///
    keep(3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period _cons) ///
    nogaps label se b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("Non-compliance" "Deterioration prob." "High resource state") ///
    stats(N_clust N, fmt(%9.0f %9.0f) labels("Groups" "N (obs)")) ///
    title("Supplementary Table. DiD estimates with group fixed effects") ///
    addnotes("Specifications mirror Supplementary Table 7 with group fixed effects (areg, absorb(group_id))." ///
             "Group fixed effects absorb all time-invariant group-level variation, including the field-team member assigned to each group." ///
             "Treatment main effects are absorbed by group fixed effects (treatment is randomly assigned at the group level)." ///
             "{it:Fixed} (T1) and Phase 2 are the omitted reference categories. Standard errors clustered at the group level." ///
             "Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity." ///
             "* p<0.10, ** p<0.05, *** p<0.01")

di _n(2) "DiD with group FE table written to: $working_ANALYSIS/results/si/tables/did_robustness_group_fe.rtf"


*===========================================================================
* SECTION S3.Y — SAMPLE ROBUSTNESS: INCLUDING BATONAN-SUR
* Re-estimates the main DiD specifications (Suppl Table 7) on the expanded
* sample including Batonan-Sur (the village that played twice; first session
* data lost, only second session retained). N goes from 420 to 440 participants.
* Originally in 06_robust_analysis.do (now archived).
*===========================================================================

di _n(2) "============================================================"
di "SAMPLE ROBUSTNESS: INCLUDING BATONAN-SUR"
di "============================================================"

* Reload data WITHOUT dropping Batonan-Sur, re-prep variables
preserve

use "$working_ANALYSIS/processed/fishery_game_long.dta", clear
* Note: NOT dropping Batonan-Sur this time
encode village, gen(village_id)

* married, only_elementary, destructive_choice, destructive_choice100 etc.
* are already in fishery_game_long.dta (created in 03_merge_reshape.do).
local controls_bs age gender married only_elementary hh_size ymonth

eststo clear

* Individual-round level
eststo bs_dest: mixed destructive_choice100 i.treatment##i.period `controls_bs' if period > 1, ///
    || group_id: || unique_id: , vce(robust)

* Group-round level
eststo bs_prob: mixed prob_low100 i.treatment##i.period `controls_bs' if period > 1, ///
    || group_id: , vce(robust)

eststo bs_high: mixed high_state100 i.treatment##i.period `controls_bs' if period > 1, ///
    || group_id: , vce(robust)

esttab bs_dest bs_prob bs_high ///
    using "$working_ANALYSIS/results/si/tables/did_robustness_batonansur.rtf", ///
    replace ///
    keep(2.treatment 3.treatment 4.treatment 3.period ///
         2.treatment#3.period 3.treatment#3.period 4.treatment#3.period _cons) ///
    nogaps label se b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("Non-compliance" "Deterioration prob." "High resource state") ///
    stats(N_g N, fmt(%9.0f %9.0f) labels("Groups" "N (obs)")) ///
    title("Supplementary Table. DiD estimates including the village that played twice (Batonan-Sur)") ///
    addnotes("Specifications mirror Supplementary Table 7 estimated on the expanded sample including Batonan-Sur (the village that participated twice; only the second session is retained because the first session's data were lost)." ///
             "Sample size: 440 participants in 22 villages (vs. 420 in 21 villages in the main analysis)." ///
             "{it:Fixed} (T1) and Phase 2 are the omitted reference categories." ///
             "Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity." ///
             "Multilevel mixed-effects models with random intercepts at group (and participant where applicable) level; robust standard errors." ///
             "* p<0.10, ** p<0.05, *** p<0.01")

di _n(2) "Batonan-Sur sample robustness table written to: $working_ANALYSIS/results/si/tables/did_robustness_batonansur.rtf"

restore


*===========================================================================
* SECTION S3.5 — ENDGAME ANALYSIS
* Is T3/T4 underperformance in Period 3 driven by endgame effects?
* Three approaches:
*   1. Add endgame dummy to existing DiD specs
*   2. Drop last round(s) and re-run main specs
*   3. Round-by-round visuals within Period 3
* Originally in 07_endgame_analysis.do (now archived).
*===========================================================================

di _n(2) "============================================================"
di "SECTION S3.5: ENDGAME ANALYSIS"
di "============================================================"

*--------------------------------------------------
* APPROACH 1: Endgame dummy in DiD specifications
*--------------------------------------------------
* If DiD coefficients shrink substantially -> endgame is driving results.

* 1A. Individual-level: Non-compliance
preserve
collapse (mean) destructive_choice100 $controls, ///
    by(treatment unique_id round_number period group_id)
gen lastround = inlist(round_number, 12, 18)
gen lastround_game = (round_number == 18)
lab var lastround "Phase end (rounds 12, 18)"
lab var lastround_game "Game end (round 18)"
xtset unique_id round_number

eststo nc_orig: mixed destructive_choice100 i.treatment##i.period $controls if period > 1, || group_id: || unique_id:, vce(robust)
eststo nc_eg1: mixed destructive_choice100 i.treatment##i.period c.lastround $controls if period > 1, || group_id: || unique_id:, vce(robust)
eststo nc_eg2: mixed destructive_choice100 i.treatment##i.period i.treatment#c.lastround c.lastround $controls if period > 1, || group_id: || unique_id:, vce(robust)
eststo nc_eg3: mixed destructive_choice100 i.treatment##i.period i.treatment#c.lastround_game c.lastround_game $controls if period > 1, || group_id: || unique_id:, vce(robust)
restore

esttab nc_orig nc_eg1 nc_eg2 nc_eg3 ///
    using "$working_ANALYSIS/results/si/tables/endgame_interactions_noncompliance.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period ///
        2.treatment#3.period 3.treatment#3.period 4.treatment#3.period ///
        lastround 2.treatment#c.lastround 3.treatment#c.lastround 4.treatment#c.lastround ///
        lastround_game 2.treatment#c.lastround_game 3.treatment#c.lastround_game 4.treatment#c.lastround_game) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Original" "+ Endgame" "+ T x Endgame" "+ T x Game End") ///
    nonotes addnotes("Notes: Endgame analysis for non-compliance rate. Last round = final round of each period (12, 18); game end = round 18 only. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace

* 1B. Group-level: Deterioration probability & High resource state
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
gen lastround = inlist(round_number, 12, 18)
gen lastround_game = (round_number == 18)
lab var lastround "Phase end (rounds 12, 18)"
lab var lastround_game "Game end (round 18)"
xtset group_id round_number

eststo dp_orig: mixed prob_low100 i.treatment##i.period $controls if period > 1, || group_id:, vce(robust)
eststo dp_eg1: mixed prob_low100 i.treatment##i.period c.lastround $controls if period > 1, || group_id:, vce(robust)
eststo dp_eg2: mixed prob_low100 i.treatment##i.period i.treatment#c.lastround c.lastround $controls if period > 1, || group_id:, vce(robust)
eststo dp_eg3: mixed prob_low100 i.treatment##i.period i.treatment#c.lastround_game c.lastround_game $controls if period > 1, || group_id:, vce(robust)

eststo hr_orig: mixed high_state100 i.treatment##i.period $controls if period > 1, || group_id:, vce(robust)
eststo hr_eg1: mixed high_state100 i.treatment##i.period c.lastround $controls if period > 1, || group_id:, vce(robust)
eststo hr_eg2: mixed high_state100 i.treatment##i.period i.treatment#c.lastround c.lastround $controls if period > 1, || group_id:, vce(robust)
eststo hr_eg3: mixed high_state100 i.treatment##i.period i.treatment#c.lastround_game c.lastround_game $controls if period > 1, || group_id:, vce(robust)
restore

esttab dp_orig dp_eg1 dp_eg2 dp_eg3 using "$working_ANALYSIS/results/si/tables/endgame_interactions_deterioration.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period lastround 2.treatment#c.lastround 3.treatment#c.lastround 4.treatment#c.lastround lastround_game 2.treatment#c.lastround_game 3.treatment#c.lastround_game 4.treatment#c.lastround_game) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Original" "+ Endgame" "+ T x Endgame" "+ T x Game End") ///
    nonotes addnotes("Notes: Endgame analysis for deterioration probability. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace

esttab hr_orig hr_eg1 hr_eg2 hr_eg3 using "$working_ANALYSIS/results/si/tables/endgame_interactions_highstate.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period lastround 2.treatment#c.lastround 3.treatment#c.lastround 4.treatment#c.lastround lastround_game 2.treatment#c.lastround_game 3.treatment#c.lastround_game 4.treatment#c.lastround_game) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Original" "+ Endgame" "+ T x Endgame" "+ T x Game End") ///
    nonotes addnotes("Notes: Endgame analysis for high resource state. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace

*--------------------------------------------------
* APPROACH 2: Drop last round(s) and re-run
*--------------------------------------------------
* Backward induction shows defection is individually optimal in BOTH the
* last and second-to-last rounds. Dropping rounds 11-12 and 17-18 is justified.

* 2A. Individual: Non-compliance
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset unique_id round_number
eststo drop_nc0: mixed destructive_choice100 i.treatment##i.period $controls if period > 1, || group_id: || unique_id:, vce(robust)
eststo drop_nc1: mixed destructive_choice100 i.treatment##i.period $controls if period > 1 & round_number != 18, || group_id: || unique_id:, vce(robust)
eststo drop_nc2: mixed destructive_choice100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 12, 18), || group_id: || unique_id:, vce(robust)
eststo drop_nc3: mixed destructive_choice100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 11, 12, 17, 18), || group_id: || unique_id:, vce(robust)

esttab drop_nc0 drop_nc1 drop_nc2 drop_nc3 using "$working_ANALYSIS/results/si/tables/endgame_droprounds_noncompliance.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("All rounds" "Drop r18" "Drop r12,18" "Drop r11-12,17-18") ///
    nonotes addnotes("Notes: Non-compliance DiD with progressively more endgame rounds dropped. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace
restore

* 2B. Group: Deterioration probability & High resource state
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
xtset group_id round_number

eststo drop_dp0: mixed prob_low100 i.treatment##i.period $controls if period > 1, || group_id:, vce(robust)
eststo drop_dp1: mixed prob_low100 i.treatment##i.period $controls if period > 1 & round_number != 18, || group_id:, vce(robust)
eststo drop_dp2: mixed prob_low100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 12, 18), || group_id:, vce(robust)
eststo drop_dp3: mixed prob_low100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 11, 12, 17, 18), || group_id:, vce(robust)

eststo drop_hr0: mixed high_state100 i.treatment##i.period $controls if period > 1, || group_id:, vce(robust)
eststo drop_hr1: mixed high_state100 i.treatment##i.period $controls if period > 1 & round_number != 18, || group_id:, vce(robust)
eststo drop_hr2: mixed high_state100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 12, 18), || group_id:, vce(robust)
eststo drop_hr3: mixed high_state100 i.treatment##i.period $controls if period > 1 & !inlist(round_number, 11, 12, 17, 18), || group_id:, vce(robust)

esttab drop_dp0 drop_dp1 drop_dp2 drop_dp3 using "$working_ANALYSIS/results/si/tables/endgame_droprounds_deterioration.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("All rounds" "Drop r18" "Drop r12,18" "Drop r11-12,17-18") ///
    nonotes addnotes("Notes: Deterioration probability DiD with progressively more endgame rounds dropped. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace

esttab drop_hr0 drop_hr1 drop_hr2 drop_hr3 using "$working_ANALYSIS/results/si/tables/endgame_droprounds_highstate.rtf", ///
    keep(2.treatment 3.treatment 4.treatment 3.period 2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) ///
    nogaps label se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("All rounds" "Drop r18" "Drop r12,18" "Drop r11-12,17-18") ///
    nonotes addnotes("Notes: High resource state DiD with progressively more endgame rounds dropped. Models include individual controls (age, gender, marital status, education, household size, income), omitted from display for clarity. Robust SE in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace
restore

*--------------------------------------------------
* APPROACH 3: Round-by-round visuals (Period 3)
* Uses treatment colors from run.do globals
*--------------------------------------------------
preserve
collapse (mean) destructive_choice100 prob_low100 high_state100, by(treatment round_number)

twoway ///
    (connected destructive_choice100 round_number if treatment==1, lp(solid) msymbol(T) lcolor("$c_T1_text") mcolor("$c_T1_text")) ///
    (connected destructive_choice100 round_number if treatment==2, lp(dash) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text")) ///
    (connected destructive_choice100 round_number if treatment==3, lp(shortdash) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text")) ///
    (connected destructive_choice100 round_number if treatment==4, lp(longdash) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text")) ///
    if inrange(round_number, 13, 18), ///
    title("{bf:A} Non-compliance by round (Period 3)", size(10pt)) ///
    xtitle("Round") ytitle("Non-compliance rate (%)") ///
    xla(13(1)18, nogrid) yla(, nogrid) xline(17.5, lp(dot) lc(gs10)) ///
    legend(order(1 "T1: Fixed" 2 "T2: Constrained" 3 "T3: Flexible" 4 "T4: Open") rows(1) pos(6) size(7pt)) ///
    xsize(4) ysize(3)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS3a_noncompliance.gph", replace

twoway ///
    (connected prob_low100 round_number if treatment==1, lp(solid) msymbol(T) lcolor("$c_T1_text") mcolor("$c_T1_text")) ///
    (connected prob_low100 round_number if treatment==2, lp(dash) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text")) ///
    (connected prob_low100 round_number if treatment==3, lp(shortdash) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text")) ///
    (connected prob_low100 round_number if treatment==4, lp(longdash) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text")) ///
    if inrange(round_number, 13, 18), ///
    title("{bf:B} Deterioration probability by round (Period 3)", size(10pt)) ///
    xtitle("Round") ytitle("Deterioration probability (%)") ///
    xla(13(1)18, nogrid) yla(, nogrid) xline(17.5, lp(dot) lc(gs10)) ///
    legend(order(1 "T1: Fixed" 2 "T2: Constrained" 3 "T3: Flexible" 4 "T4: Open") rows(1) pos(6) size(7pt)) ///
    xsize(4) ysize(3)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS3b_deterioration.gph", replace

twoway ///
    (connected high_state100 round_number if treatment==1, lp(solid) msymbol(T) lcolor("$c_T1_text") mcolor("$c_T1_text")) ///
    (connected high_state100 round_number if treatment==2, lp(dash) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text")) ///
    (connected high_state100 round_number if treatment==3, lp(shortdash) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text")) ///
    (connected high_state100 round_number if treatment==4, lp(longdash) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text")) ///
    if inrange(round_number, 13, 18), ///
    title("{bf:C} High resource state by round (Period 3)", size(10pt)) ///
    xtitle("Round") ytitle("High resource state (%)") ///
    xla(13(1)18, nogrid) yla(, nogrid) xline(17.5, lp(dot) lc(gs10)) ///
    legend(order(1 "T1: Fixed" 2 "T2: Constrained" 3 "T3: Flexible" 4 "T4: Open") rows(1) pos(6) size(7pt)) ///
    xsize(4) ysize(3)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS3c_highstate.gph", replace
restore


*===========================================================================
* SECTION S3.6 — ENDGAME MECHANISM
* Why T3/T4 spike in rounds 17-18 but T1/T2 don't.
* Tests two channels:
*   (1) ENFORCEMENT: T3/T4 more often lack coherent enforcement.
*   (2) CONSTITUTIONAL: only T3/T4 could choose "leader decides" vs majority.
* Key contrast: voluntary-enforcement groups in T2 vs T3/T4, holding
* enforcement constant (none) so only constitutional authority varies.
* Originally in 09_endgame_mechanism_analysis.do (now archived).
* ENDOGENEITY CAVEAT: _gr_rep_consution is endogenous in T3/T4; interpret
* within-treatment splits as descriptive/suggestive.
*===========================================================================

di _n(2) "============================================================"
di "SECTION S3.6: ENDGAME MECHANISM"
di "============================================================"

* Generate constitutional authority indicator and endgame indicator
cap drop has_const_authority
gen has_const_authority = inlist(treatment, 3, 4)
lab var has_const_authority "Constitutional authority (T3/T4)"

cap drop endgame
cap drop endgame_r18
gen endgame = inlist(round_number, 17, 18)
lab var endgame "Final 2 rounds"
gen endgame_r18 = (round_number == 18)
lab var endgame_r18 "Round 18 only"

label define const_lbl 0 "Majority vote" 1 "Leader decides", replace
cap label values _gr_rep_consution const_lbl

*--------------------------------------------------
* 1. Descriptive cross-tabs at round 13 (start of Phase 3)
*--------------------------------------------------
di _n "Enforcement type x treatment at round 13:"
tab treatment enforcement_type if round_number == 13, row nofreq

di _n "Constitutional rule x treatment at round 13 (T3/T4 only):"
tab treatment _gr_rep_consution if round_number == 13 & treatment > 2, row nofreq

preserve
keep if round_number == 13
collapse (count) n=unique_id, by(treatment enforcement_type)
reshape wide n, i(treatment) j(enforcement_type)
rename n1 coherent
rename n2 voluntary
rename n3 incoherent
egen total = rowtotal(coherent voluntary incoherent)
gen pct_coherent = coherent / total * 100
gen pct_voluntary = voluntary / total * 100
gen pct_incoherent = incoherent / total * 100
format pct_* %4.1f
list treatment coherent voluntary incoherent total pct_coherent pct_voluntary pct_incoherent, noobs
export delimited "$working_ANALYSIS/results/si/tables/tab1a_enforcement_by_treatment.csv", replace
restore

*--------------------------------------------------
* 2. Round-by-round figures (mechanism evidence)
*    Uses treatment text colors from run.do globals
*--------------------------------------------------
* 2A. Within T3: by constitutional rule
preserve
keep if treatment == 3 & period == 3
collapse (mean) destructive_choice100, by(_gr_rep_consution round_number)
twoway ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 0, lp(solid) msymbol(S) lcolor("$c_T3_text") mcolor("$c_T3_text") lw(medthick)) ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 1, lp(dash) msymbol(D) lcolor("$c_T1_text") mcolor("$c_T1_text") lw(medthick)), ///
    title("{bf:A} T3 Flexible: decision rule and endgame", size(10pt)) ///
    xtitle("Round") ytitle("Non-compliance rate (%)") ///
    xla(13(1)18, nogrid) yla(0(5)30, nogrid) xline(16.5, lp(dot) lc(gs10)) ///
    legend(order(1 "Majority vote" 2 "Leader decides") rows(1) pos(6) size(8pt)) ///
    xsize(4) ysize(3.5)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS6a_t3_constitution.gph", replace
* PNG export removed 2026-05-08: this panel is consumed only by gr combine
* below to build fig_endgame_3panel.png (Fig. S in SI). The standalone
* fig_t3_constitution.png is not referenced anywhere.
restore

* 2B. Within T4: by constitutional rule
* Use the same color encoding as Panel A (Majority = T3 green, Leader = T1 red)
* so the shared legend on the combined figure is interpretable. Panel header
* still identifies the treatment.
preserve
keep if treatment == 4 & period == 3
collapse (mean) destructive_choice100, by(_gr_rep_consution round_number)
twoway ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 0, lp(solid) msymbol(S) lcolor("$c_T3_text") mcolor("$c_T3_text") lw(medthick)) ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 1, lp(dash) msymbol(D) lcolor("$c_T1_text") mcolor("$c_T1_text") lw(medthick)), ///
    title("{bf:B} T4 Open: decision rule and endgame", size(10pt)) ///
    xtitle("Round") ytitle("Non-compliance rate (%)") ///
    xla(13(1)18, nogrid) yla(0(5)30, nogrid) xline(16.5, lp(dot) lc(gs10)) ///
    legend(order(1 "Majority vote" 2 "Leader decides") rows(1) pos(6) size(8pt)) ///
    xsize(4) ysize(3.5)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS6b_t4_constitution.gph", replace
* PNG export removed 2026-05-08: panel feeds fig_endgame_3panel.png only.
restore

* 2C. Panel C: enforcement-regime channel pooled across all treatments.
* Non-compliance over rounds 13-18 (Phase 3) by enforcement_type
* (1=Coherent, 2=Voluntary, 3=Incoherent). T1 is always coherent by design;
* T2-T4 groups end up in any of the three regimes via their rule choices.
preserve
keep if period == 3 & !missing(enforcement_type)
collapse (mean) destructive_choice100, by(enforcement_type round_number)
twoway ///
    (connected destructive_choice100 round_number if enforcement_type == 1, lp(solid)     msymbol(O) lcolor("$c_T3_text") mcolor("$c_T3_text") lw(medthick)) ///
    (connected destructive_choice100 round_number if enforcement_type == 2, lp(dash)      msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text") lw(medthick)) ///
    (connected destructive_choice100 round_number if enforcement_type == 3, lp(longdash)  msymbol(D) lcolor("$c_T1_text") mcolor("$c_T1_text") lw(medthick)), ///
    title("{bf:C} Enforcement regime and endgame (all treatments)", size(10pt)) ///
    xtitle("Round") ytitle("Non-compliance rate (%)") ///
    xla(13(1)18, nogrid) yla(0(5)30, nogrid) xline(16.5, lp(dot) lc(gs10)) ///
    legend(order(1 "Coherent (M+F)" 2 "Voluntary (None)" 3 "Incoherent (M or F)") rows(1) pos(6) size(8pt)) ///
    xsize(4) ysize(3.5)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS6c_enforcement.gph", replace
* PNG export removed 2026-05-08: panel feeds fig_endgame_3panel.png only.
restore

* 2D. Combine Panels A + B + C into a single 3-panel figure (Fig. S8 in SI).
* Each panel keeps its own legend because the three legends differ (Majority/
* Leader for A and B; Coherent/Voluntary/Incoherent for C). gr combine without
* grc1leg2 since the legend categories differ across panels.
gr combine ///
    "$working_ANALYSIS/results/intermediate/suppl_figureS6a_t3_constitution.gph" ///
    "$working_ANALYSIS/results/intermediate/suppl_figureS6b_t4_constitution.gph" ///
    "$working_ANALYSIS/results/intermediate/suppl_figureS6c_enforcement.gph", ///
    cols(3) xsize(12) ysize(3.5) imargin(small) graphregion(margin(small))
gr save "$working_ANALYSIS/results/intermediate/fig_endgame_3panel.gph", replace
gr export "$working_ANALYSIS/results/si/figures/fig_endgame_3panel.png", replace width(4500)

* 2D. SMOKING GUN: T2-voluntary vs T3-voluntary
* REMOVED 2026-05-08: this exploratory diagnostic ("Panel D") was a standalone
* PNG (fig_voluntary_regime.png) that did not enter the SI. The "{bf:D}" header
* dates from a 4-panel layout that was reduced to 3 panels (A/B/C combined
* into fig_endgame_3panel.png). The diagnostic remains documented here for
* reference; restore the block if reviewers ask for the T2-voluntary vs.
* T3-voluntary head-to-head visual.
/*
preserve
keep if period == 3 & enforcement_type == 2 & inlist(treatment, 2, 3)
collapse (mean) destructive_choice100, by(treatment round_number)
twoway ///
    (connected destructive_choice100 round_number if treatment == 2, lp(solid) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text") lw(medthick)) ///
    (connected destructive_choice100 round_number if treatment == 3, lp(dash) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text") lw(medthick)), ///
    title("Voluntary-enforcement groups: T2 vs T3", size(10pt)) ///
    subtitle("Same enforcement (none); only constitutional authority varies", size(8pt)) ///
    xtitle("Round") ytitle("Non-compliance rate (%)") ///
    xla(13(1)18, nogrid) yla(0(5)30, nogrid) xline(16.5, lp(dot) lc(gs10)) ///
    legend(order(1 "T2 Constrained - no const. authority" 2 "T3 Flexible - has const. authority") rows(2) pos(6) size(7pt)) ///
    note("T4 excluded (0 voluntary-enforcement groups). All groups chose voluntary enforcement (no monitoring, no fines).", size(7pt)) ///
    xsize(4.5) ysize(3.5)
gr save "$working_ANALYSIS/results/intermediate/suppl_figureS6d_voluntary.gph", replace
gr export "$working_ANALYSIS/results/si/figures/fig_voluntary_regime.png", replace width(3000)
restore
*/

*--------------------------------------------------
* Mechanism regressions: constitutional and enforcement channels
* Produces one combined SI table (S24).
* Col 1 (m3a): T3+T4 only, Phase 3 -- endgame x constitutional rule.
* Col 2 (m3e): All treatments, Phase 3 -- const_authority x endgame x enforcement.
* m3b/m3c/m3d (enforcement-only, horse race, T x endgame x enforcement)
* and the leader-behavior block (m4a/m4b + leader-vs-nonleader figure)
* were dropped 2026-05-08 to align Stata outputs with what the SI actually
* uses (no orphan RTFs).
*--------------------------------------------------
preserve
collapse (mean) destructive_choice100 $controls _pl_leader_role, ///
    by(treatment unique_id round_number period group_id ///
    enforcement_type _gr_rep_consution has_const_authority endgame)
xtset unique_id round_number

* T3+T4, Phase 3: endgame x constitutional rule.
eststo m3a: mixed destructive_choice100 c.endgame##i._gr_rep_consution $controls if period == 3 & treatment > 2, || group_id: || unique_id:, vce(robust)
di _n "Net endgame effect for leader-decides (endgame + leader x endgame):"
lincom c.endgame + 1._gr_rep_consution#c.endgame

* All treatments, Phase 3: const_authority x endgame x enforcement (pooled).
eststo m3e: mixed destructive_choice100 c.has_const_authority##c.endgame##i.enforcement_type $controls if period == 3, || group_id: || unique_id:, vce(robust)
di _n "Net endgame effect for const-authority:"
lincom c.endgame + c.has_const_authority#c.endgame
restore

esttab m3a m3e using "$working_ANALYSIS/results/si/tables/constitutional_enforcement_channels.rtf", ///
    drop($controls _cons) nogaps label nobaselevels se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("T3+T4 (Phase 3)" "T1-T4 (Phase 3)") ///
    nonotes addnotes("Notes: Mixed-effects models with group- and individual-level random effects. Column 1 estimates the within-decentralised-treatments mechanism using observations from {it:Flexible} (T3) and {it:Open} (T4) in Phase 3, with constitutional rule (leader decides) interacted with a final-2-rounds dummy (rounds 17-18). Column 2 pools all treatments (T1-T4) in Phase 3 and uses an indicator for constitutional authority interacted with the final-2-rounds dummy and enforcement regime. All specifications include individual-level controls (age, gender, marital status, education, household size, income), omitted from display. Robust standard errors clustered at the group level in parentheses: * p<0.10, ** p<0.05, *** p<0.01") replace

*--------------------------------------------------
* Robustness: alternative endgame definitions (Table S25 in SI).
*--------------------------------------------------
preserve
collapse (mean) destructive_choice100 $controls _pl_leader_role, ///
    by(treatment unique_id round_number period group_id ///
    enforcement_type _gr_rep_consution has_const_authority endgame endgame_r18)
xtset unique_id round_number

gen endgame_p2 = inlist(round_number, 11, 12)
lab var endgame_p2 "Phase 2 placebo (rounds 11-12)"

eststo r5a: mixed destructive_choice100 c.endgame_r18##i._gr_rep_consution $controls if period == 3 & treatment > 2, || group_id: || unique_id:, vce(robust)
eststo r5b: mixed destructive_choice100 c.round_number##i._gr_rep_consution $controls if period == 3 & treatment > 2, || group_id: || unique_id:, vce(robust)
eststo r5c: mixed destructive_choice100 c.endgame_p2##i._gr_rep_consution $controls if period == 2 & treatment > 2, || group_id: || unique_id:, vce(robust)
eststo r5d: mixed destructive_choice100 c.endgame##i._gr_rep_consution if period == 3 & treatment > 2, || group_id: || unique_id:, vce(robust)
restore

esttab r5a r5b r5c r5d using "$working_ANALYSIS/results/si/tables/mechanism_robustness.rtf", ///
    drop($controls _cons) nogaps label nobaselevels se(%4.2f) b(%4.2f) stats(N, labels("N") fmt(%4.0f)) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Round 18 only" "Continuous round" "Phase 2 placebo" "No controls") ///
    nonotes addnotes("Notes: Mixed-effects models for the constitutional channel under alternative specifications. Sample: {it:Flexible} (T3) and {it:Open} (T4), Phase 3 unless noted. Col 1: replaces the Final-2-rounds dummy with a Round-18-only dummy. Col 2: continuous round trend instead of an endgame dummy. Col 3: Phase 2 placebo using rounds 11-12. Col 4: drops individual controls (other columns include them but suppress in display). Robust standard errors clustered at the group level in parentheses: * p<0.10, ** p<0.05, *** p<0.01.") replace




*===========================================================================
* SI FIGURES (migrated from 04_main_analysis.do, 2026-05-07)
* All blocks below were originally in 04 but produce SI artefacts only;
* moving them here keeps 04 focused on main paper outputs (Figs 2-7).
*===========================================================================

*--------------------------------------------------------------------------
* SI Table -- survey_enforcement_predictors.rtf
* OLS of monthly enforcement participation (f7enf, days/year) on trust,
* MPA maturity, rule involvement and rule compliance. Cluster SE by village.
* Same regression feeds the marginsplot for Fig 3 in 04.
*--------------------------------------------------------------------------
cap restore
preserve
use "$working_ANALYSIS/processed/panel_clean.dta", clear
* Collapse to village-year (matching 04's longitudinal-panel collapse) so
* the SE matches the published Fig 3 marginsplot.
collapse (mean) f7enf trust_norm years_since_mpa rule_involvement rule_compliance, by(village_id year)

* Match 04_main_analysis.do scaling: rule_involvement is a 0-1 share at the
* village-year level after collapse; multiply by 100 so the regression
* coefficient is per percentage point (consistent with main-paper Fig. 3
* x-axis 0-100 and the SI body text "Rule involvement (0-100)").
replace rule_involvement = 100 * rule_involvement

* Variable labels for the table (esttab uses these in place of var names).
lab var trust_norm        "Trust in peers (60-100)"
lab var years_since_mpa   "MPA maturity (1-26)"
lab var rule_involvement  "Rule involvement (0-100)"
lab var rule_compliance   "Rule non-compliance (0-51)"
lab var f7enf             "Enforcement participation (days/year)"

eststo governance_enforcement: reg f7enf trust_norm years_since_mpa rule_involvement rule_compliance, vce(cluster village_id)
estadd scalar R2 = e(r2)
estadd scalar N_clusters = e(N_clust)

esttab governance_enforcement using "$working_ANALYSIS/results/si/tables/survey_enforcement_predictors.rtf", nogaps label se(%4.2f) b(%4.2f) stats(N N_clusters R2, labels("N (village-year)" "Villages" "R-squared") fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(_cons "Constant") nonotes addnotes("Notes: OLS regression of monthly enforcement participation (days/year) on social trust, MPA maturity, rule involvement, and rule compliance. Standard errors clustered by village in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.") replace
restore

*--------------------------------------------------------------------------
* SI Figure -- fig_rule_adaptation_by_panel.png
* Operational vs constitutional rule changes and group discussion over rounds.
*--------------------------------------------------------------------------
cap restore
* EXTRA/ How often did they choose to change operational and constitutional rules over all rounds by treatments:

*operational
cap restore
preserve
collapse (mean)  _gr_oper_rule_voting _gr_cons_rule_voting _gr_discussion_voting, by(treatment round_number)

twoway (line _gr_cons_rule_voting round_number if treatment==1, lp(solid) recast(connected) msymbol(T)) ///
	(line _gr_cons_rule_voting round_number if treatment==2, lp(dash) recast(connected) msymbol(S)) ///
	(line _gr_cons_rule_voting round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D)) ///
	(line _gr_cons_rule_voting round_number if treatment==4, lp(longdash) recast(connected) msymbol(O)) if round_number>6, title("{bf: A} Constitutional rule changes")  leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(small) rows(1)) ytitle("Share (in %)") xtitle("Round number")xla(7(1)18, nogrid) ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "20%", nogrid) 
cap noisily gr save  "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_a.gph", replace


twoway (line _gr_oper_rule_voting round_number if treatment==1, lp(solid) recast(connected) msymbol(T)) ///
	(line _gr_oper_rule_voting round_number if treatment==2, lp(dash) recast(connected) msymbol(S)) ///
	(line _gr_oper_rule_voting round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D)) ///
	(line _gr_oper_rule_voting round_number if treatment==4, lp(longdash) recast(connected) msymbol(O)) if round_number>6, title("{bf: B} Operational rule changes")  leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(small) rows(3)) ytitle("Share (in %)") xtitle("Round number") xla(7(1)18, nogrid) ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "20%", nogrid)  
cap noisily gr save  "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_b.gph", replace


twoway (line _gr_discussion_voting round_number if treatment==1, lp(solid) recast(connected) msymbol(T)) ///
	(line _gr_discussion_voting round_number if treatment==2, lp(dash) recast(connected) msymbol(S)) ///
	(line _gr_discussion_voting round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D)) ///
	(line _gr_discussion_voting round_number if treatment==4, lp(longdash) recast(connected) msymbol(O)) if round_number>6, title("{bf: C} Group discussion")  leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(small) rows(3)) ytitle("Share (in %)") xtitle("Round number") xla(7(1)18, nogrid) ylabel(0 "0%" 0.05 "5%" 0.1 "10%" 0.15 "20%", nogrid) 
cap noisily gr save  "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_c.gph", replace

restore

*combine graphs
cap noisily grc1leg  "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_a" "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_b" "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_c", xsize(4) ysize(3) cols(2)  legendfrom("$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_a")
cap noisily gr save  "$working_ANALYSIS/results/intermediate/suppl_suppl_figureS5_rule_adaptation_combined.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_rule_adaptation_by_panel.png", replace width(3165)
*--------------------------------------------------------------------------
* SI Figure -- fig_area_method_choices.png
* Player choices across rounds (area + intensive methods), by treatment x period.
*--------------------------------------------------------------------------
cap restore
use "$working_ANALYSIS/processed/fishery_game_long.dta", clear
drop if village=="Batonan-Sur"
**Player choices across rounds (area and effort):
* Use the pre-scaled `area100` and `effort100` variables created in
* 03_merge_reshape.do; do NOT scale `_pl_area_choice` / `_pl_effort_choice`
* in place (they are still needed in raw 0/1 form by 05_suppl_analysis.do).
sum area100

cibar area100,  over1(treatment) over2(period)  graphopts(title("{bf:A} Fishing in Spawning Area", size(11pt)) yla(0(2)10, nogrid noticks) xla(, nogrid noticks) ytitle("Share in %", size(10pt)) xsize(3) ysize(2) legend(ring(1) pos(6) rows(1) size(10pt)) graphregion(color(white)) plotregion(style(none)))
cap noisily gr save  "$working_ANALYSIS/results/intermediate/area_choice.gph", replace

sum effort100

cibar effort100,  over1(treatment) over2(period)  graphopts(title("{bf:C} Fishing with Intensive Methods", size(11pt)) yla(0(2)10, nogrid noticks) xla(, nogrid noticks) ytitle("Share in %", size(10pt)) xsize(3) ysize(2) legend(ring(1) pos(6) rows(1) size(10pt)) graphregion(color(white)) plotregion(style(none)))
cap noisily gr save  "$working_ANALYSIS/results/intermediate/method_choice.gph", replace



cap restore
preserve
collapse (mean)  area100 effort100  , by(treatment round_number)

twoway (line area100 round_number if treatment==1, lp(solid) recast(connected) msymbol(T)) ///
	(line area100 round_number if treatment==2, lp(dash) recast(connected) msymbol(S)) ///
	(line area100 round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D)) ///
	(line area100 round_number if treatment==4, lp(longdash) recast(connected) msymbol(O)), title("{bf:B} Fishing in Spawning Area", size(11pt)) leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(10pt) rows(1)) ytitle("Share (in %)", size(10pt)) xtitle("Round number", size(10pt)) xla(1(1)18, nogrid) yla(0(2)10, nogrid) xline(6.5 12.5, lstyle(reference))
cap noisily gr save  "$working_ANALYSIS/results/intermediate/trend_area.gph", replace


twoway (line effort100 round_number if treatment==1, lp(solid) recast(connected) msymbol(T)) ///
	(line effort100 round_number if treatment==2, lp(dash) recast(connected) msymbol(S)) ///
	(line effort100 round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D)) ///
	(line effort100 round_number if treatment==4, lp(longdash) recast(connected) msymbol(O)), title("{bf:D} Fishing with Intensive Methods", size(11pt)) leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(10pt) rows(1)) ytitle("Share (in %)", size(10pt)) xtitle("Round number", size(10pt)) xla(1(1)18, nogrid) yla(0(2)10, nogrid) xline(6.5 12.5, lstyle(reference))
cap noisily gr save  "$working_ANALYSIS/results/intermediate/trend_methods.gph", replace
restore

cap noisily grc1leg  "$working_ANALYSIS/results/intermediate/area_choice" "$working_ANALYSIS/results/intermediate/trend_area" "$working_ANALYSIS/results/intermediate/method_choice" "$working_ANALYSIS/results/intermediate/trend_methods", xsize(4) ysize(3) cols(2) 
cap noisily gr save  "$working_ANALYSIS/results/intermediate/fig_area_method_choices.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_area_method_choices.png", replace width(3165)
*--------------------------------------------------------------------------
* SI Figure -- fig_punishment_descriptive.png
* 2-panel descriptive: monetary punishment + frowny smileys per round, by treatment.
*--------------------------------------------------------------------------
cap restore
use "$working_ANALYSIS/processed/fishery_game_long.dta", clear
drop if village=="Batonan-Sur"
***********************

*PUNISHMENT — descriptive only (formal regression dropped 2026-05-07)
* `any_punishment` and `n_punish` are now created in 03_merge_reshape.do.
tab n_punish if round_number==1
* 88% of players never punished, 7% punished once, 7 players punished more than 10 times
bys group_id: tab n_punish if treatment==2
bys treatment: tab n_punish


*--------------------------------------------------------------------------
* Suppl. Fig. (punishment) — 2-panel descriptive figure showing how rarely
* the formal punishment channels were used at the individual level.
* Substantive message: a small minority of players engaged each channel in
* any given round, with no systematic differences across treatments or phases.
*
* Plotting share-of-players (not totals) so the y-axis matches an individual
* outcome reading: "what fraction of fishers used this channel this round?"
* Panel A: share who paid any monetary punishment (>0 PHP).
* Panel B: share who sent any frowny smiley (>0 smileys).
*--------------------------------------------------------------------------
cap restore
preserve

* Player-round binary indicators
* `any_punishment` (monetary) is created in 03_merge_reshape.do.
gen any_smiley = _pl_sum_smiley_sent > 0 if !missing(_pl_sum_smiley_sent)
lab var any_smiley "Any frowny smiley sent this round"

collapse (mean) any_punishment any_smiley, by(treatment round_number)

* Convert to percent (0-100) so axis reads as % of fishers
replace any_punishment = 100 * any_punishment
replace any_smiley     = 100 * any_smiley

* Panel A — Share of fishers who paid any monetary punishment, by round x treatment
twoway (line any_punishment round_number if treatment==1, lp(solid)     recast(connected) msymbol(T) lcolor("$c_T1_text") mcolor("$c_T1_text")) ///
       (line any_punishment round_number if treatment==2, lp(dash)      recast(connected) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text")) ///
       (line any_punishment round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text")) ///
       (line any_punishment round_number if treatment==4, lp(longdash)  recast(connected) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text")), ///
    title("{bf:A} Share of fishers who paid to punish", size(11pt)) ///
    leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(9pt) rows(1)) ///
    ytitle("Share of fishers (%)", size(9pt)) ///
    xtitle("Round number", size(9pt)) ///
    xla(1(1)18, nogrid labsize(8pt)) yla(0(2)10, nogrid labsize(8pt)) ///
    xline(6.5 12.5, lstyle(reference)) ///
    xsize(3) ysize(2) ///
    graphregion(color(white)) plotregion(style(none))
cap noisily gr save "$working_ANALYSIS/results/intermediate/punish_invest.gph", replace

* Panel B — Share of fishers who sent any frowny smiley, by round x treatment
twoway (line any_smiley round_number if treatment==1, lp(solid)     recast(connected) msymbol(T) lcolor("$c_T1_text") mcolor("$c_T1_text")) ///
       (line any_smiley round_number if treatment==2, lp(dash)      recast(connected) msymbol(S) lcolor("$c_T2_text") mcolor("$c_T2_text")) ///
       (line any_smiley round_number if treatment==3, lp(shortdash) recast(connected) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text")) ///
       (line any_smiley round_number if treatment==4, lp(longdash)  recast(connected) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text")), ///
    title("{bf:B} Share of fishers who sent a frowny smiley", size(11pt)) ///
    leg(on order(1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}") size(9pt) rows(1)) ///
    ytitle("Share of fishers (%)", size(9pt)) ///
    xtitle("Round number", size(9pt)) ///
    xla(1(1)18, nogrid labsize(8pt)) yla(0(2)10, nogrid labsize(8pt)) ///
    xline(6.5 12.5, lstyle(reference)) ///
    xsize(3) ysize(2) ///
    graphregion(color(white)) plotregion(style(none))
cap noisily gr save "$working_ANALYSIS/results/intermediate/punish_smileys.gph", replace
restore

cap noisily grc1leg ///
    "$working_ANALYSIS/results/intermediate/punish_invest" ///
    "$working_ANALYSIS/results/intermediate/punish_smileys", ///
    xsize(6) ysize(2.5) rows(1) ///
    legendfrom("$working_ANALYSIS/results/intermediate/punish_invest")
cap noisily gr save  "$working_ANALYSIS/results/intermediate/fig_punishment_descriptive.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_punishment_descriptive.png", replace width(3165)


*--------------------------------------------------------------------------
* SI Figure -- fig_problems_fisheries.png
* Strip plot: 7 perceived problem items by MPA status (post-experiment survey).
*--------------------------------------------------------------------------
*===========================================================================
* EXPERIMENT — GAME WIDE FORMAT — Suppl. figure on perceived problems related to fisheries (post-experiment survey items only).
*===========================================================================

**	The psychological impact of institutional design choice
use "$working_ANALYSIS/processed/fishery_game_wide.dta", clear

* Derived variables (married, only_elementary, exp_cdp16r) and the canonical
* treat_lbl now live in 03_merge_reshape.do.
global controls age gender married only_elementary hh_size ymonth

*problems related to fisheries — strip plot with box overlay (replaces bar-of-means)
sum f5corr f5law f5monits f5zone f5org f5rules f5togh
lab def mpa1 0 "No MPA" 1 "MPA", replace
lab value mpa mpa1

cap which catplot
if _rc cap ssc install catplot, replace

cap restore
preserve
rename f5corr  prob1
rename f5law   prob2
rename f5monits prob3
rename f5zone  prob4
rename f5org   prob5
rename f5rules prob6
rename f5togh  prob7

* Reduce to one obs per participant before reshape (these are survey items, not panel)
duplicates drop unique_id, force
reshape long prob, i(unique_id) j(prob_lab)

* Distinct labels — verify f5law vs f5rules wording in codebook before submission
lab def prob_lab1 1 "Corruption" 2 "Law enforcement" 3 "Monitoring" 4 "Zoning" ///
                  5 "Organization" 6 "Rule clarity" 7 "Togetherness", replace
lab val prob_lab prob_lab1

* Severity labels for the stacked-bar legend
lab def prob_severity 1 "1 (low)" 2 "2" 3 "3" 4 "4" 5 "5 (high)", replace
lab val prob prob_severity

* Stacked bar chart: 7 panels (one per item); within each panel two bars
* (No MPA vs MPA) normalized to 100% and split by Likert severity 1-5.
* Diverging palette so "low problem" reads green, "high problem" reads red,
* neutral mid-point grey -- the MPA vs non-MPA contrast pops visually.
* Pre-compute percentages within each (mpa x prob_lab) cell so each bar sums
* to exactly 100%. catplot's percent(mpa) ignores by(prob_lab) and normalises
* across all panels combined, capping bars at ~14% (1/7), which is the bug
* you saw earlier.
contract prob mpa prob_lab if !missing(prob, mpa, prob_lab)
bysort mpa prob_lab: egen _cell_n = total(_freq)
gen pct = 100 * _freq / _cell_n
keep prob mpa prob_lab pct
reshape wide pct, i(mpa prob_lab) j(prob)
* Fill cells with no observations at a given Likert level (otherwise graph bar
* drops the bar entirely instead of leaving a gap)
forvalues k = 1/5 {
    cap confirm variable pct`k'
    if _rc gen pct`k' = 0
    replace pct`k' = 0 if missing(pct`k')
    lab var pct`k' "`k'"
}

graph bar (mean) pct1 pct2 pct3 pct4 pct5, ///
    over(mpa) by(prob_lab, cols(4) note("") title("") imargin(small) ///
                 graphregion(margin(small))) ///
    stack ///
    bar(1, color("26 150 65"))   /// 1 = low problem
    bar(2, color("166 217 106")) /// 2
    bar(3, color("200 200 200")) /// 3 = neutral
    bar(4, color("253 174 97"))  /// 4
    bar(5, color("215 25 28"))   /// 5 = high problem
    blabel(bar, format(%3.0f) pos(center) size(7pt) color(black)) ///
    yla(0(20)100, nogrid labsize(8pt)) ///
    ytitle("Share of fishers (%)", size(9pt)) ///
    legend(rows(1) pos(6) ring(1) size(8pt) ///
        order(1 "1 (low)" 2 "2" 3 "3" 4 "4" 5 "5 (high)") ///
        title("Perceived severity", size(8pt))) ///
    xsize(8) ysize(5)

cap noisily gr save "$working_ANALYSIS/results/intermediate/suppl_problems_fisheries.gph", replace
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_problems_fisheries.png", replace width(3000)
cap restore
*--------------------------------------------------------------------------
* SI Figure -- fig_comprehension_quiz_by_treatment.png
* Strip plot of comprehension quiz scores by treatment (panel_clean + quiz.dta).
*--------------------------------------------------------------------------
*===========================================================================
* SI FIG — Comprehension quiz by treatment (strip plot)
* Lives in its own block at the end because it requires panel_clean + a merge
* with quiz.dta on (unified_pl_id, village). Conceptually an SI figure rather
* than part of the main panel analysis above.
*===========================================================================


preserve
use "$working_ANALYSIS/processed/panel_clean.dta", clear
* panel_clean keeps the raw key `particip_no`; quiz.dta uses `unified_pl_id`.
* Rename here so the historical merge (m:m on unified_pl_id + village) works.
cap rename particip_no unified_pl_id
merge m:m unified_pl_id village using "$working_ANALYSIS/data/clean/quiz.dta", generate(gh)

* `unique_id` lives in fishery_game_long (created in 03_merge_reshape.do as
* gen unique_id = _n after sorting on village + unified_pl_id). panel_clean
* never carried it, so synthesise it here from the same key so the historical
* dedup + collapse logic below still works.
egen unique_id = group(village unified_pl_id)

* quiz100 stays inline because r1-r4 only exist after the quiz.dta merge above
* (they live in quiz.dta, not in fishery_game_long / panel_clean).
gen quiz100 = ((r1+r2+r3+r4)/4)*100
lab var quiz100 "Comprehension quiz (% correct)"

sort unique_id
quietly by unique_id: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop if gh==2
bysort treatment: sum quiz100
tab quiz100 treatment if quiz100>=50, col row

* Convert quiz100 to a 5-level ordinal (0/25/50/75/100) so catplot can
* stack the score-share within each treatment bar.
gen quiz_cat = .
replace quiz_cat = 1 if quiz100 == 0
replace quiz_cat = 2 if quiz100 == 25
replace quiz_cat = 3 if quiz100 == 50
replace quiz_cat = 4 if quiz100 == 75
replace quiz_cat = 5 if quiz100 == 100
lab def quiz_cat_lbl 1 "0%" 2 "25%" 3 "50%" 4 "75%" 5 "100%", replace
lab val quiz_cat quiz_cat_lbl

* panel_clean carries the long pre-canonical treatment labels ("Fixed Blueprint",
* "Constrained Co-management", "Full self-governance"). Override with the
* canonical short italic labels (T1=Fixed, T2=Constrained, T3=Flexible, T4=Open)
* defined in 03_merge_reshape.do so the bar labels in this figure match every
* other figure in the paper.
label define treat_lbl 1 "{it:Fixed}" 2 "{it:Constrained}" 3 "{it:Flexible}" 4 "{it:Open}", replace
label values treatment treat_lbl

cap which catplot
if _rc cap ssc install catplot, replace

* Stacked bar chart: one bar per treatment, normalized to 100% and split by
* quiz score (0/25/50/75/100). Diverging palette: red = below comprehension
* threshold (0/25%), neutral grey at 50%, greens at 75/100% so the eye
* immediately separates competent from non-competent participants.
catplot quiz_cat if !missing(quiz_cat, treatment), ///
    over(treatment) ///
    stack asyvar percent(treatment) vertical ///
    bar(1, color("215 25 28"))   /// 0%
    bar(2, color("253 174 97"))  /// 25%
    bar(3, color("200 200 200")) /// 50%
    bar(4, color("166 217 106")) /// 75%
    bar(5, color("26 150 65"))   /// 100%
    blabel(bar, format(%3.0f) pos(center) size(9pt) color(black)) ///
    yla(0(20)100, nogrid labsize(11pt)) ///
    ytitle("Share of fishers (%)", size(12pt)) ///
    l1title("") b1title("") ///
    legend(rows(1) pos(6) ring(1) size(10pt) ///
        order(1 "0%" 2 "25%" 3 "50%" 4 "75%" 5 "100%") ///
        title("Quiz score (% correct)", size(10pt))) ///
    xsize(7) ysize(4) ///
    graphregion(margin(zero)) ///
    saving("$working_ANALYSIS/results/intermediate/fig_comprehension_quiz_by_treatment.gph", replace)
cap noisily gr export "$working_ANALYSIS/results/si/figures/fig_comprehension_quiz_by_treatment.png", replace width(3000)

* Treatment-pair ttests on quiz scores (kept for reference; not exported)
duplicates drop unique_id, force
drop if quiz100<50
collapse (mean) quiz100, by(treatment unique_id)
ttest quiz100 if (treatment==2 | treatment==1), by(treatment)
ttest quiz100 if (treatment==2 | treatment==3), by(treatment)
ttest quiz100 if (treatment==2 | treatment==4), by(treatment)
restore




*===========================================================================
* SECTION S3.3 - COMPREHENSION SUBSET ROBUSTNESS
* Re-estimate the main DiD specifications (Suppl. Table did_governance_to_climate_shock)
* under TWO comprehension-quiz cutoffs (>=2 of 4 correct, and >=3 of 4
* correct), giving a 6-column table: (1)-(3) at >=50%, (4)-(6) at >=75%.
*===========================================================================

di _n(2) "============================================================"
di "COMPREHENSION SUBSET ROBUSTNESS (>=50 AND >=75)"
di "============================================================"

eststo clear

* Reload long-format experimental data. The preceding block ended in wide
* format (fishery_game_wide.dta loaded at line 1680, restored at line 1849
* after a panel_clean detour). round_number / period / group_id only exist in
* the long file -- without this reload, the collapse below errors r(111).
cap restore
use "$working_ANALYSIS/processed/fishery_game_long.dta", clear

* ---- Full-sample baseline (no quiz restriction) ----
cap restore
preserve
collapse (mean) destructive_choice100 $controls, ///
    by(treatment unique_id round_number period group_id)
xtset unique_id round_number
eststo cs_dest_all: mixed destructive_choice100 i.treatment##i.period $controls if period > 1, ///
    || group_id: || unique_id: , vce(robust)
matrix Ng = e(N_g)
estadd scalar Groups      = Ng[1,1]
estadd scalar Individuals = Ng[1,2]
restore

cap restore
preserve
collapse (mean) prob_low100 high_state100 $controls, ///
    by(treatment group_id round_number period)
xtset group_id round_number
eststo cs_prob_all: mixed prob_low100 i.treatment##i.period $controls if period > 1, ///
    || group_id: , vce(robust)
matrix Ng = e(N_g)
estadd scalar Groups = Ng[1,1]

eststo cs_high_all: mixed high_state100 i.treatment##i.period $controls if period > 1, ///
    || group_id: , vce(robust)
matrix Ng = e(N_g)
estadd scalar Groups = Ng[1,1]
restore

* ---- Quiz-restricted samples (>=50% and >=75% correct) ----
foreach cutoff in 50 75 {

    cap restore
    preserve
    merge m:1 unified_pl_id village using "$working_ANALYSIS/data/clean/quiz.dta", ///
        keep(match) keepusing(r1 r2 r3 r4) generate(_mq)
    gen quiz100 = ((r1+r2+r3+r4)/4)*100
    keep if quiz100 >= `cutoff'

    di _n "Cutoff `cutoff': N participants kept = " _N

    collapse (mean) destructive_choice100 $controls, ///
        by(treatment unique_id round_number period group_id)
    xtset unique_id round_number
    eststo cs_dest_`cutoff': mixed destructive_choice100 i.treatment##i.period $controls if period > 1, ///
        || group_id: || unique_id: , vce(robust)
    matrix Ng = e(N_g)
    estadd scalar Groups      = Ng[1,1]
    estadd scalar Individuals = Ng[1,2]
    restore

    cap restore
    preserve
    merge m:1 unified_pl_id village using "$working_ANALYSIS/data/clean/quiz.dta", ///
        keep(match) keepusing(r1 r2 r3 r4) generate(_mq)
    gen quiz100 = ((r1+r2+r3+r4)/4)*100
    keep if quiz100 >= `cutoff'

    collapse (mean) prob_low100 high_state100 $controls, ///
        by(treatment group_id round_number period)
    xtset group_id round_number
    eststo cs_prob_`cutoff': mixed prob_low100 i.treatment##i.period $controls if period > 1, ///
        || group_id: , vce(robust)
    matrix Ng = e(N_g)
    estadd scalar Groups = Ng[1,1]

    eststo cs_high_`cutoff': mixed high_state100 i.treatment##i.period $controls if period > 1, ///
        || group_id: , vce(robust)
    matrix Ng = e(N_g)
    estadd scalar Groups = Ng[1,1]
    restore
}

* Show only the three main coefficients of interest (Treatment x Phase 3
* interactions). Nine columns total: three per outcome panel
* (Full / Quiz>=50% / Quiz>=75%).
esttab ///
    cs_dest_all cs_dest_50 cs_dest_75 ///
    cs_prob_all cs_prob_50 cs_prob_75 ///
    cs_high_all cs_high_50 cs_high_75 ///
    using "$working_ANALYSIS/results/si/tables/did_robustness_comprehension.rtf", ///
    replace ///
    keep(2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) ///
    nogaps label se b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mgroups("Non-compliance" "Deterioration prob." "High resource state", ///
            pattern(1 0 0 1 0 0 1 0 0) span) ///
    mtitle("Full" "Quiz>=50%" "Quiz>=75%" ///
           "Full" "Quiz>=50%" "Quiz>=75%" ///
           "Full" "Quiz>=50%" "Quiz>=75%") ///
    coeflabel(2.treatment#3.period "{it:Constrained} x Phase 3" ///
              3.treatment#3.period "{it:Flexible}   x Phase 3" ///
              4.treatment#3.period "{it:Open}       x Phase 3") ///
    stats(Groups Individuals N, fmt(%9.0f %9.0f %9.0f) labels("Groups" "Individuals" "N (obs)")) ///
    title("Supplementary Table. DiD estimates - Treatment x Phase 3 interactions by comprehension-quiz cutoff") ///
    addnotes("Specifications mirror Suppl. Table 7 (did_governance_to_climate_shock). Only the three main coefficients of interest (Treatment x Phase 3 interactions) are reported. Each outcome panel shows three sample restrictions: 'Full' is the unrestricted sample, 'Quiz>=50%' restricts to participants who answered at least two of four comprehension-quiz items correctly, 'Quiz>=75%' tightens to at least three of four." ///
             "{it:Fixed} (T1) and Phase 2 are the omitted reference categories." ///
             "Models include treatment level effects, the Phase 3 dummy, and individual controls (age, gender, marital status, education, household size, income), omitted from display." ///
             "Multilevel mixed-effects models with random intercepts at group (and participant where applicable) level; robust standard errors." ///
             "* p<0.10, ** p<0.05, *** p<0.01")

di _n(2) "Comprehension subset robustness (9-col) table written to: $working_ANALYSIS/results/si/tables/did_robustness_comprehension.rtf"

* Post-process the RTF so the mgroups outcome headers span 3 columns in Word
* (esttab's RTF backend leaves the outcome labels in a single cell).
shell python "$working_ANALYSIS/../../scripts/fix_rtf_mgroup_span.py" "$working_ANALYSIS/results/si/tables/did_robustness_comprehension.rtf"


*===========================================================================
* SECTION S1.4 / S1.5 - PARTICIPANT PERCEPTION OF THE GAME
* Builds a single by-treatment summary table from the post-experiment
* survey items (renamed in 01_clean_survey.do):
*   - exp_understand                         comprehension self-report (1-5)
*   - exp_fun, exp_confusing, exp_difficult  multi-select 0/1 -> %
*   - exp_attention, exp_decision_others     yes/no 0/1 -> %
*   - exp_know_others                        integer (0-4)
*   - exp_realism_p1/p2/p3                   perceived realism per phase (1-5)
*   - exp_rule_area/method/monitoring/sanction  rule importance (1-5)
*===========================================================================

di _n(2) "============================================================"
di "PERCEPTION SUMMARY BY TREATMENT"
di "============================================================"

cap restore
preserve

* One observation per participant
keep if round_number == 1
duplicates drop unique_id, force

* Convert binary indicators (multi-select / yes-no) to percentages for display
foreach v in exp_fun exp_easy exp_interesting exp_frustrating exp_difficult ///
             exp_confusing exp_boring exp_tiring exp_attention exp_decision_others {
    cap confirm variable `v'
    if _rc == 0 replace `v' = `v' * 100
}

* Display labels (kept short for table width)
lab var exp_understand        "Understood instructions (1-5)"
lab var exp_fun               "Found game fun (%)"
lab var exp_confusing         "Found game confusing (%)"
lab var exp_difficult         "Found game difficult (%)"
lab var exp_attention         "Paid attention to others (%)"
lab var exp_decision_others   "Influenced by others' decisions (%)"
lab var exp_know_others       "Group members known privately (0-4)"
lab var exp_realism_p1        "Realism: Phase 1 - no rules (1-5)"
lab var exp_realism_p2        "Realism: Phase 2 - governance (1-5)"
lab var exp_realism_p3        "Realism: Phase 3 - climate shock (1-5)"
lab var exp_rule_area         "Rule importance: area restriction (1-5)"
lab var exp_rule_method       "Rule importance: method restriction (1-5)"
lab var exp_rule_monitoring   "Rule importance: monitoring (1-5)"
lab var exp_rule_sanction     "Rule importance: sanctions (1-5)"

local pvars exp_understand exp_fun exp_confusing exp_difficult ///
            exp_attention exp_decision_others exp_know_others ///
            exp_realism_p1 exp_realism_p2 exp_realism_p3 ///
            exp_rule_area exp_rule_method exp_rule_monitoring exp_rule_sanction

eststo clear
eststo all: estpost summarize `pvars'
eststo t1:  estpost summarize `pvars' if treatment==1
eststo t2:  estpost summarize `pvars' if treatment==2
eststo t3:  estpost summarize `pvars' if treatment==3
eststo t4:  estpost summarize `pvars' if treatment==4

esttab all t1 t2 t3 t4 ///
    using "$working_ANALYSIS/results/si/tables/perception_summary.rtf", ///
    replace cells("mean(fmt(%9.2f))") ///
    label nonumber noobs ///
    mtitle("All" "Fixed (T1)" "Constrained (T2)" "Flexible (T3)" "Open (T4)") ///
    title("Supplementary Table. Participant perception of the game by treatment") ///
    addnotes("Means by treatment from the post-experiment survey, one observation per participant (N=420)." ///
             "Items on a 1-5 scale unless marked '(\%)'; '(\%)' denotes the share of participants endorsing the option." ///
             "Treatments: T1 = Fixed Blueprint, T2 = Constrained Co-management, T3 = Flexible Co-management, T4 = Open Design." ///
             "exp_attention/exp_decision_others coded Yes=100/No=0 for percentage display.")

* Sample sizes and the full distribution for the realism block (used in the SI text)
di _n "Per-treatment Ns (one obs per participant):"
tab treatment

di _n "Distribution of comprehension-quiz score (%):"
* Re-merge quiz to print the underlying distribution alongside the perception block
merge m:1 unified_pl_id village using "$working_ANALYSIS/data/clean/quiz.dta", ///
    keep(match master) keepusing(r1 r2 r3 r4) generate(_mq2)
cap gen quiz100b = ((r1+r2+r3+r4)/4)*100
tab quiz100b

restore

di _n(2) "Perception summary table written to: $working_ANALYSIS/results/si/tables/perception_summary.rtf"


*===========================================================================
* END OF SI ANALYSIS
*===========================================================================
di _n(2) "============================================================"
di "05_suppl_analysis.do completed."
di "All SI tables and figures have been generated to $working_ANALYSIS/results/"
di "============================================================"



* EOF

