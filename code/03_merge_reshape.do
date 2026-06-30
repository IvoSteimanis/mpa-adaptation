*--------------------------------------------------
* Fishery Game
* 03_merge_reshape.do
* START: 2023-05-30
* Authors: Maryia Makhnach, Ivo Steimanis
* Philipps University Marburg
*-------------------------------------------------


** Load cleaned survey data
use "$working_ANALYSIS\processed\survey_clean", clear
*get rid of surveys by respondents that did not participate in the game
drop if sample==1

*generate unique participant identifier
rename particip_no unified_pl_id
sort village unified_pl_id
gen unique_id = [_n]

*------------------------------------------------------------
* Clean up spelling and spacing in village names
*------------------------------------------------------------
replace village = strtrim(village)
replace village = subinstr(village, char(160), " ", .)
replace village = "Talotoan"    if village=="Talotu-an" | village=="Taloto-an"
replace village = "Paloc Bique" if village=="Paloc Bigque"
replace village = "Maliogliog" if village == "Maliog-liog"
replace village = "Cata-an" if village == "Cata-An"


*------------
***MERGING***
*------------
merge 1:1 unique_id using  "$working_ANALYSIS\processed\game_wide"
drop _merge


*unique group identifier
egen group_id = group(village treatment)

*------------------------------------------------------------------
* Derived variables for analysis (moved from 04_main_analysis.do
* and 05_suppl_analysis.do; consolidated 2026-05-07).
* These survive into both fishery_game_wide and fishery_game_long.
*------------------------------------------------------------------

* Control covariates (binary recodes from survey items)
gen married = 0
replace married = 1 if status==2
gen only_elementary = 0
replace only_elementary = 1 if educ == 1

* Reverse-coded CDP item: cdp16 is "I felt excessive regulations from authorities
* outside the group made it difficult to make our own rules." Higher raw value =
* more perceived external constraint. Reverse so higher = less perceived
* constraint, aligning with the Governance Quality direction.
cap gen exp_cdp16r = 10 - exp_cdp16

* (quiz100 = comprehension-quiz percent correct lives in quiz.dta and is
*  generated inline in 04_main_analysis.do after the merge; r1..r4 are not
*  in fishery_game_wide.dta so this block was a no-op.)

* Paper-consistent labels for control variables
lab var age "Age in years"
lab var gender "Female"
lab var married "Married"
lab var only_elementary "Only elementary education"
lab var hh_size "HH size"
lab var ymonth "Avg. monthly HH income in PHP"

save  "$working_ANALYSIS\processed\fishery_game_wide.dta", replace


*------------
***RESHAPING
*------------
sort unique_id

reshape long _@pl_payoff _@pl_area_choice	_@pl_effort_choice	_@pl_payoff_bef_punish	_@pl_punish_p1	_@pl_punish_p2	_@pl_punish_p3	_@pl_punish_p4	_@pl_punish_p5	_@pl_cost_of_punishing 	_@pl_punish_received	_@pl_smiley_p1	_@pl_smiley_p2	_@pl_smiley_p3	_@pl_smiley_p4	_@pl_smiley_p5	_@pl_sum_smiley_rec	_@pl_sum_smiley_sent	_@pl_discussion_choice	_@gr_low_state	_@gr_pr_low_state	_@gr_pr2_low_state	_@gr_fisher_entered	_@gr_fisher_not_entered	_@gr_fisher_high_effort	_@gr_fisher_high_A	_@gr_fisher_high_B	_@gr_prev_fisher_entered	_@gr_probability	_@gr_change	_@gr_pr_change	_@gr_area_recovered	_@gr_pr_area_recovered	_@gr_area_recov_comb	_@gr_discussion_voting	_@pl_area_choice_char	_@pl_effort_choice_char	_@pl_smileys_sent_char	_@pl_smileys_received_char	_@pl_punish_sent_char	_@pl_punish_received_char	_@pl_reveal_nothing_char	_@pl_decision_making_choice	_@pl_term_limit_choice	_@pl_area_rule_choice	_@pl_effort_rule_choice	_@pl_monitoring_rule_choice	_@pl_fines_rule_choice	_@pl_leader_role	_@pl_oper_rule_chg_chc	_@pl_cons_rule_chg_chc	_@pl_rule_chg_chc	_@pl_payoff_bef_monitoring	_@pl_detection_area	_@pl_detection_effort	_@pl_random_numb_detect	_@gr_probability_detect	_@gr_leader	_@gr_area_rule	_@gr_effort_rule	_@gr_monitoring_rule	_@gr_fines_rule	_@gr_oper_rule_voting	_@gr_cons_rule_voting	_@gr_rule_voting	_@gr_leader_half_period	_@gr_rep_consution	_@gr_random_numb, i(unique_id) j(round_number)

drop _1subs_round_number _2subs_round_number _3subs_round_number _4subs_round_number _5subs_round_number _6subs_round_number _7subs_round_number _8subs_round_number _9subs_round_number _10subs_round_number _11subs_round_number _12subs_round_number _13subs_round_number _14subs_round_number _15subs_round_number _16subs_round_number _17subs_round_number _18subs_round_number


*labelling new variables
lab var unified_pl_id "Unified player id that they manually filled in at the start (21-40)"
lab var id_in_session "Participant's id in the game (1-20)"
lab var village "Village name"
lab var time_started_utc "Time and date of the game"
lab var P1_pl_total_payoff "Player's payoff in Period 1"
lab var P2_pl_total_payoff "Player's payoff in Period 2"
lab var P3_pl_total_payoff "Player's payoff in Period 3"
lab var sessioncode "Session code"
lab var id_in_gr "Player's id in the group (1-5)"

lab var round_number "Round number"

lab var treatment "Treatment group (1-4)"

lab var draw_ball "What period was paid off according to the ball participants had drawn from the bag (1/2/3)"

lab var _pl_payoff "Player's payoff for the current round"
lab var _pl_area_choice "Player's choice in which area to go fishing (protected or not protected)"
lab var _pl_effort_choice "Player's choice what effort to use (normal or high)"
lab var _pl_payoff_bef_punish "Payoff before punishment"
lab var _pl_punish_p1 "How much money to invest in punishing player 1 of the group"
lab var _pl_punish_p2 "How much money to invest in punishing player 2 of the group"
lab var _pl_punish_p3 "How much money to invest in punishing player 3 of the group"
lab var _pl_punish_p4 "How much money to invest in punishing player 4 of the group"
lab var _pl_punish_p5 "How much money to invest in punishing player 5 of the group"
lab var _pl_cost_of_punishing  "How much money was spent on punishment"
lab var _pl_punish_received "How much money will be withdrawed because of received punishment"
lab var _pl_smiley_p1 "Decision to send frown smiley to player 1 of the group"
lab var _pl_smiley_p2 "Decision to send frown smiley to player 2 of the group"
lab var _pl_smiley_p3 "Decision to send frown smiley to player 3 of the group"
lab var _pl_smiley_p4 "Decision to send frown smiley to player 4 of the group"
lab var _pl_smiley_p5 "Decision to send frown smiley to player 5 of the group"
lab var _pl_sum_smiley_rec "How many frown smileys were received"
lab var _pl_sum_smiley_sent "How many frown smileys were sent"
lab var _pl_discussion_choice "Player's choice whether to have a discussion in the group"
lab var _gr_low_state "Whether the area is in low state in the end of the current round"
lab var _gr_pr_low_state "Whether the area was in low state in previous round"
lab var _gr_pr2_low_state "Whether the area was in low state two rounds ago"
lab var _gr_fisher_entered "Number of fishermen that entered the spawning area"
lab var _gr_fisher_not_entered "Number of fishermen that didn't entered the spawning area"
lab var _gr_fisher_high_effort "Number of fishermen that used high efforts"
lab var _gr_fisher_high_A "Number of fishermen who used high efforts and entered spawning area"
lab var _gr_fisher_high_B "Number of fishermen who used high efforts and didn't entered spawning area"
lab var _gr_prev_fisher_entered "Number fishermen entered spawning area in previous round"
lab var _gr_probability "Group probability to switch from High state to Low state"
lab var _gr_change "Whether the area has changed its state: from High to Low OR from Low to High"
lab var _gr_pr_change "Whether the area has changed its state: from High to Low OR from Low to High in previous round"
lab var _gr_area_recovered "Whether the area can recover in the current round"
lab var _gr_pr_area_recovered "Whether the area could recover in previous round"
lab var _gr_area_recov_comb "Recovery status. Recovery status. Whether nobody entered spawning area for 2 rounds and now it can recover"
lab var _gr_discussion_voting "Whether the group voted to have a discussion"
lab var _pl_area_choice_char "Whether the 'area choice' characteristics was chosen to be revealed for the leader election"
lab var _pl_effort_choice_char "Whether the 'effort choice' characteristics was chosen to be revealed for the leader election"
lab var _pl_smileys_sent_char "Whether the 'frown smiley sent' characteristics was chosen to be revealed for the leader election"
lab var _pl_smileys_received_char "Whether the 'frowm smiley received' characteristics was chosen to be revealed for the leader election"
lab var _pl_punish_sent_char "Whether the 'amount invested in punishing' characteristics was chosen to be revealed for the leader election"
lab var _pl_punish_received_char "Whether the 'amount withdrawn as a result of punishing' characteristics was chosen to be revealed for the leader election"
lab var _pl_reveal_nothing_char "Whether the player decided to reveal nothing"
lab var _pl_decision_making_choice "Player's decision what rules will apply to counselling setting"
lab var _pl_term_limit_choice "Player's decision on the term limit for the leader"
lab var _pl_area_rule_choice "Player's decision what rules will apply to fishing ground rules"
lab var _pl_effort_rule_choice "Player's decision what rules will apply to fishing method rules"
lab var _pl_monitoring_rule_choice "Player's decision what rules will apply to monitoring rules"
lab var _pl_fines_rule_choice "Player's decision what rules will apply to monetary fines rules"
lab var _pl_leader_role "Whether the player is the leader of the group"
lab var _pl_oper_rule_chg_chc "Player's decision whether s/he wants to change the operational rules"
lab var _pl_cons_rule_chg_chc "Player's decision whether s/he wants to change the constitutional rules"
lab var _pl_rule_chg_chc "Only T4. Player's decision whether s/he wants to change the rules"
lab var _pl_payoff_bef_monitoring "Player's payoff before monitoring"
lab var _pl_detection_area "Whether the detection happened after the fishing ground rule violation"
lab var _pl_detection_effort "Whether the detection happened after the fishing method rule violation"
lab var _pl_random_numb_detect "Random number for the player’s rule breaking detection probability"
lab var _gr_probability_detect "Group probability to be detected for rule violations"
lab var _gr_leader "Leader's id in the group"
lab var _gr_area_rule "Fishing ground rules chosen by the group"
lab var _gr_effort_rule "Fishing methods rule chosen by the group"
lab var _gr_monitoring_rule "Monitoring rule chosen by the group"
lab var _gr_fines_rule "Monetary fines rule chsen by the group"
lab var _gr_oper_rule_voting "Majority vote decision on whether to change operational rules"
lab var _gr_cons_rule_voting "Majority vote decision on whether to change constitutional rules"
lab var _gr_rule_voting "Only T4. Group decision on whether to change the rules"
lab var _gr_leader_half_period "Group decision for the leader's term"
lab var _gr_rep_consution "Group decision on counselling setting"
lab var _gr_random_numb "Random number for the ground deterioration probability"



* Additional variables
*period identifier
gen period = .
replace period = 1 if round_number <=6
replace period = 2 if round_number > 6 & round_number <= 12
replace period = 3 if round_number > 12

*group voting
gen majority_vote = 0 if treatment >2 & round_number >6
replace majority_vote = 1 if _gr_rep_consution == 0 
gen majority_vote1 = majority_vote*100
gen _gr_rep_consution1 = _gr_rep_consution*100
gen _gr_leader_period = 0 if treatment >2 & round_number >6
replace _gr_leader_period = 1 if _gr_leader_half_period == 0 
gen _gr_leader_period1 = _gr_leader_period*100
gen _gr_leader_half_period1 = _gr_leader_half_period*100

*rules
gen no_area_rule = 0 if round_number >6
replace  no_area_rule = 1 if _gr_area_rule == 0
gen no_area_rule_pl = 0 if round_number>6
replace no_area_rule_pl = 1 if _pl_area_rule_choice == 0

gen no_effort_rule = 0 if round_number >6
replace  no_effort_rule = 1 if _gr_effort_rule == 0

gen monit_rule1 = 0 if round_number >6
gen monit_rule2 = 0 if round_number >6
gen monit_rule3 = 0 if round_number >6
replace  monit_rule1 = 1 if _gr_monitoring_rule == 1
replace  monit_rule2 = 1 if _gr_monitoring_rule == 2
replace  monit_rule3 = 1 if _gr_monitoring_rule == 3

gen fines_rule1 = 0 if round_number >6
gen fines_rule2 = 0 if round_number >6
gen fines_rule3 = 0 if round_number >6
replace  fines_rule1 = 1 if _gr_fines_rule == 1
replace  fines_rule2 = 1 if _gr_fines_rule == 2
replace  fines_rule3 = 1 if _gr_fines_rule == 3

*------------------------------------------------------------------
* Canonical treatment labels — paper-consistent (italic short forms)
* T1=Fixed, T2=Constrained, T3=Flexible, T4=Open. Single source of
* truth: do NOT redefine these in 04 / 05. Use `lab val treatment
* treat_lbl` if a downstream script needs to re-apply.
*------------------------------------------------------------------
label define treat_lbl ///
    1 "{it:Fixed}" ///
    2 "{it:Constrained}" ///
    3 "{it:Flexible}" ///
    4 "{it:Open}", replace
label values treatment treat_lbl
lab var treatment "Treatment"

label define periodlabel 1 "Period 1" 2 "Period 2" 3 "Period 3"
label values (period) periodlabel

label define monitoringlabel1 1 "None" 2 "Low level" 3 "High level"
label values (_gr_monitoring_rule _gr_fines_rule) monitoringlabel1

label define construlelabel 0 "Majority vote" 1 "Leader decides"
label values (_gr_rep_consution) construlelabel

label define area_rulelabel 0 "No rule" 1 "Only regular ground"
label values (_gr_area_rule) area_rulelabel

label define effort_rulelabel 0 "No rule" 1 "Only normal effort"
label values (_gr_effort_rule) effort_rulelabel

*drop all missing variables
dropmiss, force

*generate additional variables



***---------------
*IMPORTANT NOTE!
*Due to the technical features of the oTree programming, variable "_gr_low_state" reflects the area state AT THE END OF THE ROUND. The problem here is that the actual change (recovery or deterioration) of the area happens at the very end of the round too which means that technically we record area state for the next round with this variable. Example: All participants went to the regular ground in round 1 and 2. Area recovers. Variable "_gr_low_state" in round 2 will reflect "high state", however, participants played round 2 in a low state because their payoffs are calculated based on the state at the beginning of the round. So for the correct reflection of an area state, we have to use variable "_gr_pr_low_state" because it records area state at the end of the previous round which is exactly the same as the area state in the beginning of the current round. 
replace _gr_low_state = _gr_pr_low_state
gen high_state100= (1-_gr_low_state)*100
lab var high_state100 "Fishing Ground in High State (in %)"
gen area100= _pl_area_choice*100
gen effort100= _pl_effort_choice*100
lab var area100 "Fishing in protected area (in %))"
lab var effort100 "Fishing with high effort (in %)"

*Calculate deteriotion probability based on decisions + baseline probability
* -------------------------------
* Step 0: set baseline probability
* -------------------------------
gen prob_base = 0.10
replace prob_base = 0.30 if period==3

* -------------------------------
* Step 1: count choices per group-round
* -------------------------------
bysort group_id round_number: egen n_spawn = total(_pl_area_choice==1)
bysort group_id round_number: egen n_high_spawn = total(_pl_area_choice==1 & _pl_effort_choice==1)
bysort group_id round_number: egen n_high_normal = total(_pl_area_choice==0 & _pl_effort_choice==1)

* -------------------------------
* Step 2: spawning area increments
* -------------------------------
gen spawn_inc = cond(n_spawn==1,0.30, ///
               cond(n_spawn==2,0.50, ///
               cond(n_spawn==3,0.80, ///
               cond(inlist(n_spawn,4,5),1.00,0))))

* high effort in spawning
gen high_spawn_inc = cond(n_high_spawn==1,0.10, ///
                    cond(n_high_spawn==2,0.20, ///
                    cond(n_high_spawn==3,0.30,0)))

* high effort in normal area
gen high_norm_inc = cond(n_high_normal==1,0.05, ///
                    cond(n_high_normal==2,0.10, ///
                    cond(n_high_normal==3,0.15, ///
                    cond(n_high_normal==4,0.30, ///
                    cond(n_high_normal==5,0.50,0)))))

gen prob_temp12 = prob_base + spawn_inc + high_spawn_inc + high_norm_inc


* -------------------------------
* Step 4: Phase 3 fragility adjustments
* -------------------------------
gen spawn_inc3 = cond(n_spawn==1,0.20, ///
               cond(n_spawn==2,0.50, ///
               cond(n_spawn==3,1.00, ///
               cond(inlist(n_spawn,4,5),1.00,0))))

* high effort in spawning
gen high_spawn_inc3 = cond(n_high_spawn==1,0.10, ///
                    cond(n_high_spawn==2,0.30,0))

* high effort in normal area
gen high_norm_inc3 = cond(n_high_normal==1,0.15, ///
                    cond(n_high_normal==2,0.25, ///
                    cond(n_high_normal==3,0.35, ///
                    cond(n_high_normal==4,0.50, ///
                    cond(n_high_normal==5,0.65,0)))))

gen prob_temp3 = prob_base + spawn_inc3 + high_spawn_inc3 + high_norm_inc3

* -------------------------------
* Step 5: final probability
* -------------------------------
gen prob_final = prob_temp12 if period < 3
replace prob_final = prob_temp3 if period== 3
replace prob_final = 1 if prob_final>1


gen prob_low100 = 100*prob_final
lab var prob_low100 "Deterioration Probability"

* Paper-consistent labels for primary outcomes
lab var high_state100 "High Resource State"
lab var area100  "Fishing in protected area (in %)"
lab var effort100 "Fishing with high effort (in %)"

*------------------------------------------------------------------
* Long-format derived variables for analysis (consolidated from
* 04_main_analysis.do and 05_suppl_analysis.do; 2026-05-07).
* Anything that needs to land in fishery_game_long.dta goes here.
*------------------------------------------------------------------

* Non-compliance (destructive fishing) at the individual-round level.
* "Destructive" = chose the protected spawning area (Area A) OR used
* high effort. Either action constitutes a rule violation.
gen destructive_choice = 0
replace destructive_choice = 1 if (_pl_area_choice==1 | _pl_effort_choice==1)
lab var destructive_choice "Destructive behavior"

gen destructive_choice100 = destructive_choice * 100
lab var destructive_choice100 "Non-compliance Rate"

* Group-level destructive-behavior indicators used in S26 (rule-change vote)
* logit. destructive_choice_group = 1 if any group member defected this round;
* lagged_destructive_choice1 = 1-round lag (skipping the phase boundaries at
* rounds 7 and 13 where lag would cross a phase break).
* destructive_choice_group = 1 if ANY group member defected this round (true
* group max over players; egen, not the row-wise max, which only flagged the
* individual). lagged_destructive_choice1 lags that group indicator one round
* WITHIN player (bysort group_id unique_id) so the lag is a proper 1-round lag
* rather than an order-dependent neighbouring player-row; missing at the phase
* starts (rounds 7, 13) where a lag would cross a phase break.
bysort group_id round_number: egen byte destructive_choice_group = max(destructive_choice)
bysort group_id unique_id (round_number): gen byte lagged_destructive_choice1 = ///
    destructive_choice_group[_n-1] if round_number != 7 & round_number != 13
lab var destructive_choice_group       "Gr. - Any defection (this round)"
lab var lagged_destructive_choice1     "Gr. - Any defection (t-1)"

* Endgame indicator — final two rounds of any phase (used for the endgame-
* effect logits and within-treatment mechanism analysis).
gen endgame_round = 0
replace endgame_round = 1 if round_number == 17 | round_number == 18
lab var endgame_round "Final 2 rounds"

* Rule-change variables (group-level: any majority vote to change rules;
* individual-level: did the player call for a rule change?).
gen rule_change = 0
replace rule_change = 1 if _gr_oper_rule_voting==1 | _gr_cons_rule_voting==1 | _gr_rule_voting==1
lab var rule_change "Rule change (group)"

gen individ_rule_change_call = 0
replace individ_rule_change_call = 1 if _pl_oper_rule_chg_chc==1 | _pl_cons_rule_chg_chc==1 | _pl_rule_chg_chc==1
lab var individ_rule_change_call "Voted for rule change"

* Enforcement-regime classification (3-level): Coherent (monitoring AND
* fines), Voluntary (neither), or Incoherent (one but not both).
gen enforcement_type = .
replace enforcement_type = 1 if _gr_monitoring_rule >  1 & _gr_fines_rule >  1
replace enforcement_type = 2 if _gr_monitoring_rule == 1 & _gr_fines_rule == 1
replace enforcement_type = 3 if _gr_monitoring_rule >  1 & _gr_fines_rule == 1
replace enforcement_type = 3 if _gr_monitoring_rule == 1 & _gr_fines_rule >  1
label define enforcement_lbl ///
    1 "{it:Coherent (M+F)}" ///
    2 "{it:Voluntary (None)}" ///
    3 "{it:Incoherent (M or F)}", replace
label values enforcement_type enforcement_lbl
lab var enforcement_type "Enforcement regime"

* Within-T3 partition: weak vs strong area+effort rules
gen weak_MPA = 1
replace weak_MPA = 0 if _gr_area_rule==1 & _gr_effort_rule==1
lab var weak_MPA "Weak MPA (no area+effort rules)"
gen t3_strong = 0
replace t3_strong = 1 if treatment==3 & weak_MPA==0
gen t3_weak = 0
replace t3_weak = 1 if treatment==3 & weak_MPA==1
lab var t3_strong "T3 strong (area+effort rules)"
lab var t3_weak   "T3 weak (no area+effort rules)"

* Paper-tiger flag — monitoring rule chosen but no fine attached.
gen is_paper_tiger = 0
replace is_paper_tiger = 1 if _gr_monitoring_rule == 1 & _gr_fines_rule > 1
lab var is_paper_tiger "Paper-tiger (monitoring, no fine)"

* Punishment-use indicators
gen any_punishment = 0
replace any_punishment = 1 if _pl_cost_of_punishing > 0
egen n_punish = total(any_punishment), by(unique_id)
lab var any_punishment "Any monetary punishment this round"
lab var n_punish        "Number of rounds the player punished"


*-------
* Save
*-------
save "$working_ANALYSIS\processed\fishery_game_long.dta", replace




**EOF
