*--------------------------------------------------
* Why Governance Autonomy Can Undermine Climate Resilience?
* Last update: 2026 - 02 - 18
* Authors: Ivo Steimanis, Maryia Orsich
*--------------------------------------------------

*--------------------------------------------------
* Description
*--------------------------------------------------
/* 
This do-files produces results for our main hypotheses. We are interested in how different degrees of involvement in fishing management affect rules selection and emergence, resource conservation, leader selection and (in)formal sanctioning. We are interested in four different treatment scenarios that range from little involvement and ownership (no or little possibility to change a blueprint) to high involvement and ownership in rule making. The experiment will be run on tablets using oTree and participants will be fishermen in the Philippines on Panay Island.
Treatment: 
‒	{it:Fixed}: Provided blueprint, no adjustments allowed
‒	{it:Constrained}: Provided blueprint, adjustments to operational rules allowed
‒	{it:Flexible}: Provided blueprint, adjustments to operational and constitutional rules allowed
‒	{it:Open}: No blueprint provided, establishment of rules with help of facilitator

*--------------------------------------------------
* 1) Resource-use and connected behavior 
*--------------------------------------------------
/*
-	RQ: Does the possibility of changing blueprint rules improve performance in the game? 
H1: The possibility of adjusting the blueprint lead to better resource conservation
o	Compare {it:Fixed} to {it:Constrained} and {it:Fixed} to {it:Flexible}

-	RQ: Does the possibility to refrain from a blueprint improve performance in the game? 
H2: The possibility of refraining from the blueprint lead to better resource conservation
o	Compare {it:Open} to {it:Fixed}, {it:Constrained} and {it:Flexible}

*/


*/
*--------------------------------------------------

*--------------------------------------------------
* Load Dataset
*--------------------------------------------------

*===========================================================================
* LONGITUDINAL PANEL — Fig. 2 (rule salience), Fig. 3 (governance enforcement), and Suppl. Table on enforcement predictors. Loaded first because the paper introduces the longitudinal evidence before the experiment.
*===========================================================================

**	Non-linear trajectory of rule salience following MPA establishment
cap restore
preserve
use "$working_ANALYSIS/processed/panel_clean.dta", clear

* All participant-level derivations (monitoring_failure, lack_rules,
* rule_change, rule_persistence, mpa_council_* recodes, mpa default,
* monitoring_issue + monitoring_issue_norm, f11* labels, control
* covariates) are now in 01_clean_survey.do's panel-cleaning block.

sum f6dynam f6cyan f6mesh f6season f6area f6season f11incr f11stock f11alt f11enf f11notake if mpa==1
tab rule_change
tab mpa_council_enforced mpa_council_monitoring

sort village_id year

* Collapse to village-year level for the longitudinal analysis
collapse (mean) rule_compliance rule_involvement monitoring_failure rule_persistence lack_rules f6areap f6seasonp f6speciesp f6areac f6seasonc f6speciesc rule_change mpa years_since_mpa mpa_council_enforced mpa_council_monitoring mpa_council_sanctions trust_norm enforcement_norm f7enf, by(village_id year)

foreach x of varlist rule_involvement monitoring_failure {
		replace `x'= 100*`x'
}

xtset village_id year

lab def mpa_lbl 0 "No MPA" 1 "MPA",replace
lab val mpa mpa_lbl

* Village-year enforcement regimes — post-collapse thresholding (cannot move
* to 01 because the input is the village-year mean of participant-level shares).
* Threshold = 80 (the values are already on the 0-100 scale after the recode + scaling in 01).
gen village_rules = 0 if mpa_council_enforced<80
replace village_rules = 1 if mpa_council_enforced >= 80
replace village_rules = . if mpa_council_enforced==.
gen village_monitoring = 0 if mpa_council_monitoring<80
replace village_monitoring = 1 if mpa_council_monitoring >= 80
replace village_monitoring = . if mpa_council_monitoring==.
gen village_sanctions = 0 if mpa_council_sanctions<80
replace village_sanctions = 1 if mpa_council_sanctions >= 80
replace village_sanctions = . if mpa_council_sanctions==.

tab village_rules village_monitoring if mpa==1

bys year: sum rule_compliance rule_involvement monitoring_failure rule_persistence lack_rules



*****************
* Figure 2 - Rule salience trajectory (4-panel lpoly with scatter + CI)
*****************

local xtitle_yrs xtitle("Years since MPA establishment", size(12pt))
local lineopts   lineopts(lcolor("$c_T1_text") lwidth(medthick))
local ciopts     ciopts(fcolor(gs8%30) lwidth(none))
local mopts      msize(small) mcolor("$c_T1_text%50")
local axis_lab   yla(0(20)100, nogrid labsize(11pt)) xla(0(5)30, nogrid labsize(11pt))

*A: Lack of rules (top row — no x-axis title)
lpoly lack_rules years_since_mpa if mpa==1, ci ///
    `lineopts' `ciopts' `mopts' ///
    legend(off) ///
    title("{bf:A} Lack of rules", size(14pt)) ///
    xtitle("") ytitle("Share agreeing", size(12pt)) ///
    bwidth(4) `axis_lab' note("") ///
    xsize(3.165) ysize(2.8)
cap noisily gr save "$working_ANALYSIS/results/intermediate/lack_rules_since_establishment.gph", replace

*B: Lack of monitoring (top row — no x-axis title)
lpoly monitoring_failure years_since_mpa if mpa==1, ci ///
    `lineopts' `ciopts' `mopts' ///
    legend(off) ///
    title("{bf:B} Lack of monitoring", size(14pt)) ///
    xtitle("") ytitle("Share agreeing", size(12pt)) ///
    bwidth(4) `axis_lab' note("") ///
    xsize(3.165) ysize(2.8)
cap noisily gr save "$working_ANALYSIS/results/intermediate/monitoring_failure_since_establishment.gph", replace

*C: Rule non-compliance (bottom row — x-axis title shown)
lpoly rule_compliance years_since_mpa if mpa==1, ci ///
    `lineopts' `ciopts' `mopts' ///
    legend(off) ///
    title("{bf:C} Rule non-compliance", size(14pt)) ///
    `xtitle_yrs' ytitle("Mean non-compliance", size(12pt)) ///
    bwidth(4) `axis_lab' note("") ///
    xsize(3.165) ysize(2.8)
cap noisily gr save "$working_ANALYSIS/results/intermediate/compliance_since_establishment.gph", replace

*D: Rule involvement (bottom row — x-axis title shown)
lpoly rule_involvement years_since_mpa if mpa==1, ci ///
    `lineopts' `ciopts' `mopts' ///
    legend(off) ///
    title("{bf:D} Rule involvement", size(14pt)) ///
    `xtitle_yrs' ytitle("Share involved", size(12pt)) ///
    bwidth(4) `axis_lab' note("") ///
    xsize(3.165) ysize(2.8)
cap noisily gr save "$working_ANALYSIS/results/intermediate/rule_involvement_since_establishment.gph", replace


gr combine  "$working_ANALYSIS/results/intermediate/lack_rules_since_establishment.gph" "$working_ANALYSIS/results/intermediate/monitoring_failure_since_establishment.gph" "$working_ANALYSIS/results/intermediate/compliance_since_establishment.gph" "$working_ANALYSIS/results/intermediate/rule_involvement_since_establishment.gph" , xsize(6.5) ysize(5.5) imargin(small) rows(2) iscale(1)
cap noisily gr save "$working_ANALYSIS/results/intermediate/figure2_rule_salience_trajectory.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_rule_salience_trajectory.png", replace  width(7800)


eststo governance_enforcement: reg f7enf trust_norm years_since_mpa rule_involvement rule_compliance, vce(cluster village_id)
estadd scalar R2 = e(r2)
estadd scalar N_clusters = e(N_clust)

* Suppl. Table — survey_enforcement_predictors.rtf — moved to 05_suppl_analysis.do.
* (The regression `governance_enforcement` above stays here because it feeds
* the marginsplot for Fig 3.)

*****************
* Figure 3 - Governance enforcement (3-panel marginsplot)
*****************

eststo governance_enforcement: reg f7enf trust_norm years_since_mpa rule_involvement rule_compliance, vce(cluster village_id)
margins, at(trust_norm = (60(10)100)) atmeans
marginsplot, ///
    title("{bf: A} Trust in peer fishers", size(10pt)) ///
    xtitle("Trust score", size(9pt)) ///
    ytitle("Enforcement (days/yr)", size(9pt)) ///
    yla(0(5)15, nogrid labsize(8pt)) xla(60(10)100, nogrid labsize(8pt)) ///
    recast(line) ///
    ciopts(recast(rarea) fcolor(gs8%30) lwidth(none)) ///
    plot1opts(lcolor("$c_T1_text") lwidth(medthick)) ///
    xsize(3.165) ysize(2)
cap noisily gr save "$working_ANALYSIS/results/intermediate/trust_enforcment.gph", replace

reg f7enf trust_norm years_since_mpa rule_involvement rule_compliance, vce(cluster village_id)
margins, at(years_since_mpa = (1(5)26)) atmeans
marginsplot, ///
    title("{bf: B} MPA maturity", size(10pt)) ///
    xtitle("Maturity in years", size(9pt)) ///
    ytitle("") ///
    yla(0(5)15, nogrid labsize(8pt)) xla(1(5)26, nogrid labsize(8pt)) ///
    recast(line) ///
    ciopts(recast(rarea) fcolor(gs8%30) lwidth(none)) ///
    plot1opts(lcolor("$c_T1_text") lwidth(medthick)) ///
    xsize(3.165) ysize(2)
cap noisily gr save "$working_ANALYSIS/results/intermediate/mpa_maturity_enforcement.gph", replace

reg f7enf trust_norm years_since_mpa rule_involvement rule_compliance, vce(cluster village_id)
margins, at(rule_involvement = (0(20)100)) atmeans
marginsplot, ///
    title("{bf: C} Rule involvement", size(10pt)) ///
    xtitle("Involvement score", size(9pt)) ///
    ytitle("") ///
    yla(0(5)15, nogrid labsize(8pt)) xla(0(20)100, nogrid labsize(8pt)) ///
    recast(line) ///
    ciopts(recast(rarea) fcolor(gs8%30) lwidth(none)) ///
    plot1opts(lcolor("$c_T1_text") lwidth(medthick)) ///
    xsize(3.165) ysize(2)
cap noisily gr save "$working_ANALYSIS/results/intermediate/involvement_enforcement.gph", replace


gr combine  "$working_ANALYSIS/results/intermediate/trust_enforcment.gph" "$working_ANALYSIS/results/intermediate/mpa_maturity_enforcement.gph" "$working_ANALYSIS/results/intermediate/involvement_enforcement.gph" , xsize(6.5) ysize(2.5) imargin(small) rows(1) iscale(1)
cap noisily gr save "$working_ANALYSIS/results/intermediate/figure3_governance_enforcement.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_governance_enforcement_predicted.png", replace  width(7800)


restore

*===========================================================================
* EXPERIMENT — GAME LONG FORMAT — Fig. 4 (treatment effects under climate shock, main result), Fig. 5 (CDP perceptions), Fig. 6 (institutional redesign), Fig. 7 (endogenous enforcement regimes), plus SI tables and SI figures (Phase 1+2 baseline DiD, state-over-time, area+method choices, punishment descriptive).
*===========================================================================

use "$working_ANALYSIS/processed/fishery_game_long.dta", clear
drop if  village=="Batonan-Sur" /// they played twice (first time data was not saved)

encode village, gen(village_id)

* Analysis-level globals only — all derived variables now live in
* 03_merge_reshape.do (saved into fishery_game_long.dta) since 2026-05-07.
global controls age gender married only_elementary hh_size ymonth
bys treatment : tab enforcement_type if round_number==7
bys treatment : tab enforcement_type if round_number==12
bys treatment : tab enforcement_type if round_number==18


*-----------------------------------------------------------
*Game Conservation Outcomes: PERIOD 3 - CLIMATE SHOCK (IN the paper)
*-----------------------------------------------------------

** Fig. 4. Non-compliance and resource collapse across treatments
** Panel A: Strip plots showing group-level Phase 3 means + treatment mean with 95% CI

* --- Panel A left: Non-compliance rate ---
cap restore
preserve
keep if period == 3
collapse (mean) destructive_choice100, by(treatment group_id)
set seed 12345
gen t_jitter = treatment + (runiform()-0.5)*0.35

tempfile grp_data
save `grp_data'

collapse (mean) tmean=destructive_choice100 (sd) tsd=destructive_choice100 (count) tn=destructive_choice100, by(treatment)
gen tse = tsd / sqrt(tn)
gen tll = tmean - invttail(tn-1, 0.025)*tse
gen tul = tmean + invttail(tn-1, 0.025)*tse

tempfile treat_stats
save `treat_stats'

use `grp_data', clear
merge m:1 treatment using `treat_stats', nogen

twoway ///
    (scatter destructive_choice100 t_jitter if treatment==1, msymbol(O) msize(small) mcolor("$c_T1_text"*0.4)) ///
    (scatter destructive_choice100 t_jitter if treatment==2, msymbol(O) msize(small) mcolor("$c_T2_text"*0.4)) ///
    (scatter destructive_choice100 t_jitter if treatment==3, msymbol(O) msize(small) mcolor("$c_T3_text"*0.4)) ///
    (scatter destructive_choice100 t_jitter if treatment==4, msymbol(O) msize(small) mcolor("$c_T4_text"*0.4)) ///
    (rcap tul tll treatment, lcolor(gs2) lwidth(medthick)) ///
    (scatter tmean treatment, msymbol(D) msize(medium) mfcolor(white) mlcolor(gs2) mlwidth(medthick)), ///
    title("Non-compliance", size(13pt)) ///
    ytitle("Share in %", size(12pt)) ///
    yla(0(10)55, nogrid labsize(11pt)) ///
    xla(1 "{it:Fixed}" 2 "{it:Constr.}" 3 "{it:Flexible}" 4 "{it:Open}", nogrid labsize(10pt)) ///
    xsc(range(0.5 4.5)) ///
    legend(off) xsize(3.5) ysize(3) ///
    graphregion(margin(0 0 0 0)) plotregion(margin(0 0 0 0))
cap noisily gr save "$working_ANALYSIS/results/intermediate/absolute_differences_part3_a.gph", replace
restore

* --- Panel A right: Deterioration probability ---
cap restore
preserve
keep if period == 3
collapse (mean) prob_low100, by(treatment group_id)
set seed 12345
gen t_jitter = treatment + (runiform()-0.5)*0.35

tempfile grp_data
save `grp_data'

collapse (mean) tmean=prob_low100 (sd) tsd=prob_low100 (count) tn=prob_low100, by(treatment)
gen tse = tsd / sqrt(tn)
gen tll = tmean - invttail(tn-1, 0.025)*tse
gen tul = tmean + invttail(tn-1, 0.025)*tse

tempfile treat_stats
save `treat_stats'

use `grp_data', clear
merge m:1 treatment using `treat_stats', nogen

twoway ///
    (scatter prob_low100 t_jitter if treatment==1, msymbol(O) msize(small) mcolor("$c_T1_text"*0.4)) ///
    (scatter prob_low100 t_jitter if treatment==2, msymbol(O) msize(small) mcolor("$c_T2_text"*0.4)) ///
    (scatter prob_low100 t_jitter if treatment==3, msymbol(O) msize(small) mcolor("$c_T3_text"*0.4)) ///
    (scatter prob_low100 t_jitter if treatment==4, msymbol(O) msize(small) mcolor("$c_T4_text"*0.4)) ///
    (rcap tul tll treatment, lcolor(gs2) lwidth(medthick)) ///
    (scatter tmean treatment, msymbol(D) msize(medium) mfcolor(white) mlcolor(gs2) mlwidth(medthick)), ///
    title("Deterioration probability", size(13pt)) ///
    ytitle("Probability in %", size(12pt)) ///
    yla(0(10)80, nogrid labsize(11pt)) ///
    xla(1 "{it:Fixed}" 2 "{it:Constr.}" 3 "{it:Flexible}" 4 "{it:Open}", nogrid labsize(10pt)) ///
    xsc(range(0.5 4.5)) ///
    yline(30, lpattern(dash) lcolor(gs10) lwidth(thin)) ///
    text(22 2.5 "{it:design baseline (30%)}", size(vsmall) color(gs6)) ///
    legend(off) xsize(3.5) ysize(3) ///
    graphregion(margin(0 0 0 0)) plotregion(margin(0 0 0 0))
cap noisily gr save "$working_ANALYSIS/results/intermediate/absolute_differences_part3_b.gph", replace
restore

* --- Combine Panel A ---
graph combine "$working_ANALYSIS/results/intermediate/absolute_differences_part3_a" "$working_ANALYSIS/results/intermediate/absolute_differences_part3_b", title("{bf:A} Group-level outcomes, Phase 3 (N = 84 groups)", size(13pt)) graphregion(margin(0 0 6 0)) xsize(6.5) ysize(3) rows(1) iscale(1)
cap noisily gr save "$working_ANALYSIS/results/intermediate/absolute_differences_part3.gph", replace


** Regression analysis of treatment effects
*individual destructive behavior
cap restore
preserve
collapse (mean) destructive_choice100 $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table2_1: mixed destructive_choice100 i.treatment##i.period  $controls if period > 1, || group_id: || unique_id: , vce(robust)
restore

*group level outcomes: group probability of going to low-state & actual outcome
cap restore
preserve
collapse (mean) prob_low100 high_state100 $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table2_2: mixed prob_low100 i.treatment##i.period $controls if period>1, || group_id:  , vce(robust)
eststo table2_3: mixed high_state100 i.treatment##i.period $controls if period>1, || group_id:  , vce(robust)
restore


* SI Table — did_governance_to_climate_shock.rtf is now produced in 05_suppl_analysis.do.


*Panel B: DiD interactions only (Treatment x P3, vs Fixed reference)
coefplot (table2_1), bylabel(Non-compliance) || (table2_2), bylabel(Deterioration probability) || , ///
    xla(-20(10)20, nogrid labsize(11pt)) ///
    byopts(title("{bf:B} Treatment effects (DiD)", size(14pt) margin(t=1 b=1)) compact imargin(*1.5) rows(1) legend(off)) ///
    keep(2.treatment#3.period 3.treatment#3.period 4.treatment#3.period) ///
    order(4.treatment#3.period 3.treatment#3.period 2.treatment#3.period) ///
    coeflabels(2.treatment#3.period = "{it:Constrained}" 3.treatment#3.period = "{it:Flexible}" 4.treatment#3.period = "{it:Open}", labsize(12pt)) ///
    xline(0, lpattern(dash) lcolor(gs3)) ///
    xtitle("Regression estimated impact in %-points (relative to {it:Fixed})", size(12pt)) ///
    grid(none) levels(95) ///
    mlabel(cond(@pval<.05, string(@b,"%3.1f") + " [" + string(@ll,"%3.1f") + ", " + string(@ul,"%3.1f") + "]", string(@b,"%3.1f"))) ///
    msize(5pt) msymbol(O) mlabsize(8pt) mlabcolor(black) mlabposition(12) mlabgap(0.5) ///
    subtitle(, size(13pt) lstyle(none) margin(small) nobox justification(center) alignment(top) bmargin(top)) ///
    xsize(6.5) ysize(1.8) ///
    ciopts(lwidth(medthick) lcolor("80 80 80") recast(rcap)) ///
    mcolor("80 80 80") norecycle ///
    graphregion(margin(0 0 0 0)) plotregion(margin(2 0 2 0))
cap noisily gr save  "$working_ANALYSIS/results/intermediate/suppl_TE_phase3_intermediate.gph", replace


gr combine  "$working_ANALYSIS/results/intermediate/absolute_differences_part3" "$working_ANALYSIS/results/intermediate/suppl_TE_phase3_intermediate", plotregion(margin(0 0 0 0)) xsize(6.5) ysize(4.8) rows(2) imargin(zero) iscale(1)
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig_treatment_effects_climate_shock.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_treatment_effects_climate_shock.png", replace width(7800)


*-----------------------------------------------------------
* Enforcement regimes and rule changes 
*-----------------------------------------------------------
** Fig. 6  "Enforcement regime transitions" — now produced by
**         code/fig6_enforcement_flow.R  (R / ggalluvial).
**         Run manually:  Rscript code/fig6_enforcement_flow.R

tab enforcement_type, gen(enf_regime)
cap restore
preserve

collapse (mean) enf_regime1, by(group_id treatment round_number)

ttest enf_regime1 if treatment==2 & (round_number==7 | round_number==13), by(round_number)
restore

bys treatment: tab1 _gr_rep_consution _gr_leader_period _gr_area_rule _gr_effort_rule _gr_monitoring_rule _gr_fines_rule if round_number==7


cap restore
preserve
collapse (mean) enforcement_type $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
mlogit enforcement_type i.treatment $controls if period> 1 & treatment>1, cluster(group_id)
margins, dydx(treatment) post
restore


*-------------------------------------------
* Figure 7. Climate shock across endogenously
* selected enforcement regimes
*-------------------------------------------
*endogenously chosen enforcement regimes
*individual destructive behavior
cap restore
preserve
collapse (mean) destructive_choice100 enforcement_type $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table3_1: mixed destructive_choice100  i.enforcement_type##i.period $controls  if period>1, || group_id: || unique_id: , vce(robust) 
restore

*group outcomes
cap restore
preserve
collapse (mean) prob_low100 high_state100 enforcement_type $controls, by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table3_2: mixed prob_low100 i.enforcement_type##i.period $controls if period>1, || group_id:  , vce(robust)  
eststo table3_3: mixed high_state100 i.enforcement_type##i.period $controls if period>1, || group_id:  , vce(robust) 
restore

* SI Table — did_enforcement_regimes_climate_shock.rtf is now produced in 05_suppl_analysis.do.

* Non-compliance panel
coefplot (table3_1), ///
    xla(-15(5)15, nogrid labsize(11pt)) ///
    keep(2.enforcement_type 3.enforcement_type 2.enforcement_type#3.period 3.enforcement_type#3.period) ///
    coeflabels(2.enforcement_type = "{it:Voluntary}" 3.enforcement_type = "{it:Incoherent}" 2.enforcement_type#3.period = "{it:Voluntary} x P3" 3.enforcement_type#3.period = "{it:Incoherent} x P3", labsize(12pt)) ///
    groups(2.enforcement_type 3.enforcement_type = "{bf:P2}" 2.enforcement_type#3.period 3.enforcement_type#3.period = "{bf:DiD}", labsize(11pt) angle(vertical) gap(1)) ///
    yla(, nogrid labsize(11pt)) ///
    xline(0, lpattern(dash) lcolor(gs3)) ///
    title("Non-compliance", size(13pt)) ///
    xtitle("%-points relative to {it:Coherent}", size(11pt)) ///
    grid(none) levels(95) legend(off) ///
    mlabel(cond(@pval<.05, string(@b,"%3.1f") + " [" + string(@ll,"%3.1f") + ", " + string(@ul,"%3.1f") + "]", string(@b,"%3.1f"))) ///
    msize(5pt) msymbol(O) mlabsize(9pt) mlabcolor(black) mlabposition(12) mlabgap(0.5) ///
    xsize(3.5) ysize(2.2) ///
    ciopts(lwidth(medthick) lcolor("80 80 80") recast(rcap)) ///
    mcolor("80 80 80") graphregion(margin(0 0 0 0)) plotregion(margin(2 0 2 0))
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig7_noncompliance.gph", replace

* Deterioration probability panel
coefplot (table3_2), ///
    xla(-10(5)15, nogrid labsize(11pt)) ///
    keep(2.enforcement_type 3.enforcement_type 2.enforcement_type#3.period 3.enforcement_type#3.period) ///
    coeflabels(2.enforcement_type = "{it:Voluntary}" 3.enforcement_type = "{it:Incoherent}" 2.enforcement_type#3.period = "{it:Voluntary} x P3" 3.enforcement_type#3.period = "{it:Incoherent} x P3", labsize(12pt)) ///
    groups(2.enforcement_type 3.enforcement_type = "{bf:P2}" 2.enforcement_type#3.period 3.enforcement_type#3.period = "{bf:DiD}", labsize(11pt) angle(vertical) gap(1)) ///
    yla(, nogrid labsize(11pt)) ///
    xline(0, lpattern(dash) lcolor(gs3)) ///
    title("Deterioration probability", size(13pt)) ///
    xtitle("%-points relative to {it:Coherent}", size(11pt)) ///
    grid(none) levels(95) legend(off) ///
    mlabel(cond(@pval<.05, string(@b,"%3.1f") + " [" + string(@ll,"%3.1f") + ", " + string(@ul,"%3.1f") + "]", string(@b,"%3.1f"))) ///
    msize(5pt) msymbol(O) mlabsize(9pt) mlabcolor(black) mlabposition(12) mlabgap(0.5) ///
    xsize(3.5) ysize(2.2) ///
    ciopts(lwidth(medthick) lcolor("80 80 80") recast(rcap)) ///
    mcolor("80 80 80") graphregion(margin(0 0 0 0)) plotregion(margin(2 0 2 0))
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig7_deterioration.gph", replace

* Combine
graph combine "$working_ANALYSIS/results/intermediate/fig7_noncompliance" "$working_ANALYSIS/results/intermediate/fig7_deterioration", xsize(6.5) ysize(2.2) rows(1) iscale(1) imargin(small)
cap noisily gr save "$working_ANALYSIS/results/intermediate/figure7_endogenous_regimes.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_endogenous_enforcement_coefplot.png", replace width(7800)

*** Additional test on heterogenoues effects for {it:Flexible}:

*Weak institutional design
* weak_MPA, t3_strong, t3_weak, is_paper_tiger are now created in 03_merge_reshape.do.
* The treatment dummies (treat_1..treat_4) are still expanded inline because they are
* analysis-time scaffolding for the heterogeneity regressions in this section.
tab treatment, gen(treat_)

* Check the distribution
* This will show the proportion of groups (and observations within them) that fit this definition
tab treatment is_paper_tiger, row

cap restore
preserve
drop if period!=3 

collapse (mean) prob_low100 high_state100 $controls treat_2 t3_strong t3_weak treat_4 , by(treatment group_id round_number period)
xtset  group_id round_number  
eststo table2_1: mixed prob_low100 treat_2 t3_strong t3_weak treat_4 $controls , || group_id:  , vce(robust) 
eststo table2_2: mixed high_state100 treat_2 t3_strong t3_weak treat_4  $controls , || group_id:  , vce(robust) 
restore


*individual destructive behavior
cap restore
preserve
collapse (mean) area100 effort100 treat_2 t3_strong t3_weak   treat_4 $controls, by(treatment unique_id round_number period group_id)
xtset  unique_id round_number  
eststo table2_3: mixed area100 treat_2 t3_strong t3_weak   treat_4 $controls if period==3, || group_id: || unique_id: , vce(robust)
eststo table2_4: mixed effort100 treat_2 t3_strong t3_weak   treat_4 $controls if period==3, || group_id: || unique_id: , vce(robust)
restore




*-----------------------------------------------------
*** CORE DESIGN PRINCIPLES / 
*** CDP analysis: Social cohesion and governance quality (perceived)
*-----------------------------------------------------
/*
We use post-game survey data based on the ProSocial Core Design Principles (64) to capture participants' perceptions of group functioning. Survey items (0-10 Likert scale) are grouped into two conceptual dimensions: Social Cohesion, reflecting trust, fairness, belonging, and openness within the group, and Governance Quality, reflecting perceptions of decision-making, monitoring, leadership, conflict resolution, and institutional functioning. Three items were excluded from the analysis because their content was not well aligned with the experimental setting or the structure of the game (e.g., items referring to asking others for help, which was not a salient or feasible behavior, and could not occur without revealing individual identities). 

Type	Item	Full wording
Social Cohesion		cdp1	I felt a strong sense of belonging to the group.
Not used			cdp2	It was difficult to ask other members of this team for help.
Not used			cdp3	People in this team sometimes rejected others for being different.
Not used			cdp4	Some members received benefits disproportionate to their contributions
Social Cohesion		cdp5	No one would intentionally act in a way to undermine success of the group.
Social Cohesion		cdp6	Costs and benefits were shared equally in the group.
Governance quality	cdp7	Decisions followed a fair procedure in the group.
Governance quality	cdp8	All group members were involved in the decision-making.
Governance quality	cdp9	Group members monitored each other to check whether rules were obeyed.
Social Cohesion		cdp10	Group members encouraged helpful behaviors.
Governance quality	cdp11	Feedback was provided in a manner increasing helpful and decreasing unhelpful behaviors.
Governance quality	cdp13*	The group had a trusted and impartial person to resolve conflicts.
Social Cohesion		cdp14	Members were able to bring up problems and tough issues.
Governance quality	cdp15	Conflicts were solved in fast and fair manners in the group.
Governance quality	cdp16R	I felt excessive regulations from authorities outside the group made it
difficult to make our own rules.
Governance quality	cdp17	Our group leader had enough power to make decisions for the group.
Manipulation check	cdp18	We group members had enough authority to govern ourselves.


*/


* exp_cdp16r is now created in 03_merge_reshape.do (wide-format save).


******************************************************
preserve
keep if round_number==1
* --- Social Cohesion ---
alpha exp_cdp1 exp_cdp5 exp_cdp6 exp_cdp10 exp_cdp14, gen(social_cohesion) item
local alpha_cohesion = r(alpha)
di "Alpha — Social Cohesion: `alpha_cohesion'"
lab var social_cohesion "Social Cohesion (perceived)"

* --- Governance Quality (5 items) ---
* cdp18 (autonomy / "enough authority to govern ourselves") is reported separately
* as the manipulation check (column 1 of the CDP treatment-effects table).
* Excluded by design: cdp13 (impartial mediator -- no third-party arbiter exists in
* any treatment), cdp17 (leader authority -- leader role endogenous to treatment),
* cdp16r (perceived external regulation -- does not behave as a manipulation check
* and measures regulatory burden, not internal governance quality).
* See SI S3.8 for the item-selection rationale.
alpha exp_cdp7 exp_cdp8 exp_cdp9 exp_cdp11 exp_cdp15, gen(governance_quality) item
local alpha_governance = r(alpha)
di "Alpha — Governance Quality: `alpha_governance'"
lab var governance_quality "Governance Quality (perceived)"

* --- Standardize sub-indices (z-scores) ---
foreach var of varlist social_cohesion governance_quality exp_cdp18 {
    summarize `var'
    gen z_`var' = (`var' - r(mean)) / r(sd)
    local lbl : variable label `var'
    lab var z_`var' "`lbl' (z-score)"
}

* --- Regressions ---



duplicates drop unique_id, force

eststo manipulation_check:  reg z_exp_cdp18 i.treatment $controls i.assist, cluster(group_id)
estadd scalar R2 = e(r2)

eststo social_cohesion:  reg z_social_cohesion i.treatment $controls i.assist, cluster(group_id)
estadd scalar R2 = e(r2)
eststo governance_quality:   reg z_governance_quality i.treatment $controls i.assist, cluster(group_id)
estadd scalar R2 = e(r2)

* Fig. 5.	Treatment effects on perceived social cohesion and governance quality

coefplot  (manipulation_check), bylabel(Autonomy)  || ///
	(social_cohesion), bylabel(Social Cohesion) || ///
	(governance_quality), bylabel(Governance Quality) ||, ///
    xla(-0.2(0.2)0.8, nogrid labsize(11pt) format(%3.1f)) ///
	yla(, nogrid labsize(11pt)) ///
    byopts(compact imargin(*1.5) rows(1) legend(off)) ///
    keep(2.treatment 3.treatment 4.treatment) ///
    xline(0, lpattern(dash) lcolor(gs3)) ///
    xtitle("Estimated treatment effect in SD relative to {it:Fixed}", size(12pt)) ///
    grid(none) levels(95) ///
    mlabel(cond(@pval<.05, string(@b,"%4.2f") + " [" + string(@ll,"%4.2f") + ", " + string(@ul,"%4.2f") + "]", string(@b,"%4.2f"))) ///
    msize(5pt) msymbol(O) mlabsize(9pt) mlabcolor(black) mlabposition(12) mlabgap(3) ///
    subtitle(, size(13pt) lstyle(none) margin(medium) nobox justification(center) alignment(top) bmargin(top)) ///
    xsize(6.5) ysize(2.7) ///
    ciopts(lwidth(medthick) lcolor("80 80 80") recast(rcap)) ///
    mcolor("80 80 80") norecycle ///
    graphregion(margin(0 0 0 0)) plotregion(margin(0 0 8 0))
cap noisily gr save "$working_ANALYSIS/results/intermediate/figure5_perceived_CDPs.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_cdp_treatment_effects_coefplot.png", replace width(7800)
restore




*--------------------------------------------------
* Endgame deterioration and the role of leadership
*--------------------------------------------------

** Panel A: All four treatments, round-by-round non-compliance in Phase 3
preserve
keep if period == 3
collapse (mean) destructive_choice100, by(treatment round_number)

sum destructive_choice100 if treatment==1 & round_number==18, meanonly
local y1 = r(mean)
sum destructive_choice100 if treatment==2 & round_number==18, meanonly
local y2 = r(mean)
sum destructive_choice100 if treatment==3 & round_number==18, meanonly
local y3 = r(mean)
sum destructive_choice100 if treatment==4 & round_number==18, meanonly
local y4 = r(mean)

twoway ///
    (connected destructive_choice100 round_number if treatment == 1, ///
        lp(solid) msymbol(O) lcolor("$c_T1_text") mcolor("$c_T1_text") ///
        lw(medthick) msize(small)) ///
    (connected destructive_choice100 round_number if treatment == 2, ///
        lp(solid) msymbol(O) lcolor("$c_T2_text") mcolor("$c_T2_text") ///
        lw(medthick) msize(small)) ///
    (connected destructive_choice100 round_number if treatment == 3, ///
        lp(solid) msymbol(O) lcolor("$c_T3_text") mcolor("$c_T3_text") ///
        lw(medthick) msize(small)) ///
    (connected destructive_choice100 round_number if treatment == 4, ///
        lp(solid) msymbol(O) lcolor("$c_T4_text") mcolor("$c_T4_text") ///
        lw(medthick) msize(small)), ///
    title("{bf:A} Non-compliance by treatment", size(14pt)) ///
    xla(13(1)18, nogrid labsize(11pt)) ///
    yla(0(5)25, nogrid labsize(11pt)) ///
    xsc(range(13 19.5)) ///
    xline(16.5, lp(dot) lc(gs10)) ///
    xtitle("Round", size(12pt)) ytitle("Non-compliance rate (%)", size(12pt)) ///
    text(`y1' 18.2 "{it:Fixed}", size(9pt) color("$c_T1_text") placement(e)) ///
    text(`y2' 18.2 "{it:Constr.}", size(9pt) color("$c_T2_text") placement(e)) ///
    text(`y3' 18.2 "{it:Flexible}", size(9pt) color("$c_T3_text") placement(e)) ///
    text(`y4' 18.2 "{it:Open}", size(9pt) color("$c_T4_text") placement(e)) ///
    legend(off) ///
    xsize(3.5) ysize(3)
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig_endgame_panel_a.gph", replace
restore

** Panel B: Leader-decides vs majority-vote within T3+T4
preserve
keep if inlist(treatment, 3, 4) & period == 3
collapse (mean) destructive_choice100, by(_gr_rep_consution round_number)

label define const_lbl 0 "Majority vote" 1 "Leader decides", replace
label values _gr_rep_consution const_lbl

sum destructive_choice100 if _gr_rep_consution==0 & round_number==18, meanonly
local ymaj = r(mean)
sum destructive_choice100 if _gr_rep_consution==1 & round_number==18, meanonly
local yldr = r(mean)

twoway ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 0, ///
        lp(dash) msymbol(S) lcolor("120 120 120") mcolor("120 120 120") ///
        lw(medthick) msize(small)) ///
    (connected destructive_choice100 round_number if _gr_rep_consution == 1, ///
        lp(solid) msymbol(D) lcolor("$c_T3_text") mcolor("$c_T3_text") ///
        lw(medthick) msize(small)), ///
    title("{bf:B} Constitutional rule (T3+T4)", size(14pt)) ///
    xla(13(1)18, nogrid labsize(11pt)) ///
    yla(0(5)25, nogrid labsize(11pt)) ///
    xsc(range(13 20.5)) ///
    xline(16.5, lp(dot) lc(gs10)) ///
    xtitle("Round", size(12pt)) ytitle("Non-compliance rate (%)", size(12pt)) ///
    text(`ymaj' 18.2 "Majority vote", size(9pt) color("120 120 120") placement(e)) ///
    text(`yldr' 18.2 "Leader decides", size(9pt) color("$c_T3_text") placement(e)) ///
    legend(off) ///
    xsize(3.5) ysize(3)
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig_endgame_panel_b.gph", replace
restore

** Combine panels A + B
graph combine ///
    "$working_ANALYSIS/results/intermediate/fig_endgame_panel_a" ///
    "$working_ANALYSIS/results/intermediate/fig_endgame_panel_b", ///
    xsize(6.5) ysize(3) rows(1) iscale(1)
cap noisily gr save "$working_ANALYSIS/results/intermediate/fig_endgame_leader.gph", replace
cap noisily gr export "$working_ANALYSIS/results/main/figures/fig_endgame_leader.png", replace width(7800)


**EOF
