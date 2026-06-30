*--------------------------------------------------
* Fishery Game
* 01_clean_survey.do
* START: 2022-02-11
* Authors: Max Burger
* Philipps University Marburg
*-------------------------------------------------


*--------------------------------------------------

*--------------------------------------------------
* Description
*--------------------------------------------------
/*
  1) IMPORT SURVEYS
     A) Household Survey
	 B) Pre-Experiment Survey
	 C) Post-Experiment Survey
	 *) Merge Pre- and Post-Experiment Surveys
	 
  2) MERGE GROUPS TO SURVEYS
     A) Organizations to which participants belong
	 B) Fishing nets
  
  3) CLEANING: RENAME
  
  4) ADJUST ERRORS IN DATA COLLECTION
  
  5) GENERATE
*/
*--------------------------------------------------







*--------
* 1) IMPORT SURVEY, MERGE & APPEND
*----------

// KOBO TO STATA
// A. Household Survey
kobo2stata using "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey.xlsx", xlsform("$working_ANALYSIS\data\raw\Survey\3 - Household-Survey.xls") surveylabel("label::English") choiceslabel("label::English")
use "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-3 - Household-Survey", clear
gen sample = 1
lab define sample1 1 "HH-Interview" 2 "Experiment" 
lab var sample sample1
save "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-3 - Household-Survey", replace




// B. Pre-Experiment Survey
kobo2stata using "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent.xlsx", xlsform("$working_ANALYSIS\data\raw\Survey\1 - Pre-Exp-Consent.xls") surveylabel("label::English") choiceslabel("label::English")
use "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-1 - Pre-Exp-Consent", clear
gen sample = 2
lab define sample1 1 "HH-Interview" 2 "Experiment"
lab var sample sample1

* ===== Anonymize enumerator names for public replication package =====
* Mapping (alphabetical): S01..S11 = Ayza, Darven, Elle, Elsan, Frelyn, Jemma,
*                                   Kenneth, Mariecris, Marlo, Sheila, Shomie
capture confirm string variable s1
if !_rc {
    replace s1 = "S01" if s1 == "Ayza"
    replace s1 = "S02" if s1 == "Darven"
    replace s1 = "S03" if s1 == "Elle"
    replace s1 = "S04" if s1 == "Elsan"
    replace s1 = "S05" if s1 == "Frelyn"
    replace s1 = "S06" if s1 == "Jemma"
    replace s1 = "S07" if s1 == "Kenneth"
    replace s1 = "S08" if s1 == "Mariecris"
    replace s1 = "S09" if s1 == "Marlo"
    replace s1 = "S10" if s1 == "Sheila"
    replace s1 = "S11" if s1 == "Shomie"
}

/*
Person left after general instructions
One participant left just after the general instructions and was replaced; the pre-test was repeated afterwards. As a result, particip_no 25 in Bucaya appears twice, and the earlier record is deleted below.
*/
drop if s3 == "Bucaya" & particip_no == 25 & s1 == "S01" // formerly enumerator name; now anonymized

/*
Wrong participant number entered
In Igdalaguit the wrong participant number was entered. The participant who should have been No. 31 was recorded under No. 21. The correction was made using the field Registration sheet (participant names are held in restricted raw data and are not deposited).
*/
* Participant-number correction in Igdalaguit (one mis-entered record) was applied
* on the restricted raw data using the respondent's name as the match key. The name
* is not deposited; the correction is already reflected in the de-identified data.
* Original (name withheld for deposit):
* replace particip_no = 31 if s3 == "Igdalaguit" & sd1_intro == "[name withheld]"

save "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-1 - Pre-Exp-Consent", replace

// C. Post-Experiment Survey
kobo2stata using "$working_ANALYSIS\data\raw\Survey\2_-_Post-Exp-Survey.xlsx", xlsform("$working_ANALYSIS\data\raw\Survey\2 - Post-Exp-Survey.xls") surveylabel("label::English") choiceslabel("label::English")

// * Merge Pre-Experiment survey with Post-Experiment
* Load pre-exp
use "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-1 - Pre-Exp-Consent", clear
* Merge with post-exp
merge 1:1 particip_no s3 using "$working_ANALYSIS\data\raw\Survey\2_-_Post-Exp-Survey-2 - Post-Exp-Survey.dta", force // some variables specifications differ: byte/str35/etc. (!!!)
drop _merge

* ===== Anonymize enumerator names again after merge (post-exp survey may carry raw names) =====
capture confirm string variable s1
if !_rc {
    replace s1 = "S01" if s1 == "Ayza"
    replace s1 = "S02" if s1 == "Darven"
    replace s1 = "S03" if s1 == "Elle"
    replace s1 = "S04" if s1 == "Elsan"
    replace s1 = "S05" if s1 == "Frelyn"
    replace s1 = "S06" if s1 == "Jemma"
    replace s1 = "S07" if s1 == "Kenneth"
    replace s1 = "S08" if s1 == "Mariecris"
    replace s1 = "S09" if s1 == "Marlo"
    replace s1 = "S10" if s1 == "Sheila"
    replace s1 = "S11" if s1 == "Shomie"
}

save "$working_ANALYSIS\data\raw\Survey\experiment_import", replace








*--------
* 2) MERGE GROUPS TO SURVEYS
*----------

//  A) Organizations to which participants belong
** Pre-Experiment Survey
* No Cap (Group-No <= 5)
use "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-Module_G0_1", clear
keep group_pos sd27 sd27_other sd26 sd28 sd28_which sd32 _parent_index
reshape wide sd27 sd27_other sd26 sd28 sd28_which sd32 , i(_parent_index) j(group_pos)

forvalues i = 1/4 {
rename sd27`i' org`i'_type
lab var org`i'_type "Org `i': Type"
rename sd27_other`i' org`i'_othspec
lab var org`i'_othspec "Org `i': Type other (specify)"
rename sd26`i' org`i'_name
lab var org`i'_name "Org `i': Name of organization"
rename sd28`i' org`i'_pos
lab var org`i'_pos "Org `i': Position"
rename sd28_which`i' org`i'_pos_name
lab var org`i'_pos_name "Org `i': Name of position"
rename sd32`i' org`i'_engage
lab var org`i'_engage "Org `i': How often do you engage in activities of organization?"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\groups_pre_exp", replace


* With Cap (Group-No > 5)
use "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-Module_G0_1_2", clear
foreach var in group_pos sd26_intro sd27 sd27_other sd26 sd28 sd28_which sd32 {
rename `var'_cap `var' 
}

keep group_pos sd27 sd27_other sd26 sd28 sd28_which sd32 _parent_index
reshape wide sd27 sd27_other sd26 sd28 sd28_which sd32 , i(_parent_index) j(group_pos)

forvalues i = 1/5 {
rename sd27`i' org`i'_type
lab var org`i'_type "Org `i': Type"
rename sd27_other`i' org`i'_othspec
lab var org`i'_othspec "Org `i': Type other (specify)"
rename sd26`i' org`i'_name
lab var org`i'_name "Org `i': Name of organization"
rename sd28`i' org`i'_pos
lab var org`i'_pos "Org `i': Position"
rename sd28_which`i' org`i'_pos_name
lab var org`i'_pos_name "Org `i': Name of position"
rename sd32`i' org`i'_engage
lab var org`i'_engage "Org `i': How often do you engage in activities of organization?"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\groups_pre_exp_cap", replace


// Household Survey
* No Cap (Group-No <= 5)
use "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-Module_G0_1", clear
keep group_pos sd27 sd27_other sd26 sd28 sd28_which sd32 _parent_index
reshape wide sd27 sd27_other sd26 sd28 sd28_which sd32 , i(_parent_index) j(group_pos)

forvalues i = 1/4 {
rename sd27`i' org`i'_type
lab var org`i'_type "Org `i': Type"
rename sd27_other`i' org`i'_othspec
lab var org`i'_othspec "Org `i': Type other (specify)"
rename sd26`i' org`i'_name
lab var org`i'_name "Org `i': Name of organization"
rename sd28`i' org`i'_pos
lab var org`i'_pos "Org `i': Position"
rename sd28_which`i' org`i'_pos_name
lab var org`i'_pos_name "Org `i': Name of position"
rename sd32`i' org`i'_engage
lab var org`i'_engage "Org `i': How often do you engage in activities of organization?"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\groups_hh_survey", replace


* With Cap (Group-No > 5)
use "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-Module_G0_1_2", clear
foreach var in group_pos sd26_intro sd27 sd27_other sd26 sd28 sd28_which sd32 {
rename `var'_cap `var' 
}

keep group_pos sd27 sd27_other sd26 sd28 sd28_which sd32 _parent_index
reshape wide sd27 sd27_other sd26 sd28 sd28_which sd32 , i(_parent_index) j(group_pos)

forvalues i = 1/5 {
rename sd27`i' org`i'_type
lab var org`i'_type "Org `i': Type"
rename sd27_other`i' org`i'_othspec
lab var org`i'_othspec "Org `i': Type other (specify)"
rename sd26`i' org`i'_name
lab var org`i'_name "Org `i': Name of organization"
rename sd28`i' org`i'_pos
lab var org`i'_pos "Org `i': Position"
rename sd28_which`i' org`i'_pos_name
lab var org`i'_pos_name "Org `i': Name of position"
rename sd32`i' org`i'_engage
lab var org`i'_engage "Org `i': How often do you engage in activities of organization?"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\groups_hh_survey_cap", replace




// B) Fishing Nets [Repeating sections saved]
** Pre-experiment survey
use "$working_ANALYSIS\data\raw\Survey\2_-_Post-Exp-Survey-Module_B3_3", clear
keep net_pos e1_3 e1_2 e1_4 e1_5 _parent_index
reshape wide e1_3 e1_2 e1_4 e1_5 , i(_parent_index) j(net_pos)

forvalues i = 1/5 {
rename e1_3`i' net`i'_mesh_size
lab var net`i'_mesh_size "Net `i': Mesh size"
rename e1_2`i' net`i'_purpose
lab var net`i'_purpose "Net `i': Used for what?"
rename e1_4`i' net`i'_length
lab var net`i'_length "Net `i': Length of net"
rename e1_5`i' net`i'_number
lab var net`i'_number "Net `i': Amount of nets of this type"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\nets_exp", replace


** Household survey
use "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-Module_B3_3", clear
keep net_pos e1_3 e1_2 e1_4 e1_5 _parent_index
reshape wide e1_3 e1_2 e1_4 e1_5 , i(_parent_index) j(net_pos)

forvalues i = 1/4 {
rename e1_3`i' net`i'_mesh_size
lab var net`i'_mesh_size "Net `i': Mesh size"
rename e1_2`i' net`i'_purpose
lab var net`i'_purpose "Net `i': Used for what?"
rename e1_4`i' net`i'_length
lab var net`i'_length "Net `i': Length of net"
rename e1_5`i' net`i'_number
lab var net`i'_number "Net `i': Amount of nets of this type"
}
rename _parent_index _index
save "$working_ANALYSIS\data\raw\Survey\nets_hh_survey", replace




// Merge Pre-Experiment survey with Post-Experiment survey & group-data
* Merge with organization-data
use "$working_ANALYSIS\data\raw\Survey\experiment_import", clear
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\groups_pre_exp", force
drop _merge
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\groups_pre_exp_cap", force
drop _merge
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\nets_exp", force
drop _merge

dropmiss, force
save "$working_ANALYSIS\data\raw\Survey\experiment_complete", replace




// Merge HH-Survey with group-data
use "$working_ANALYSIS\data\raw\Survey\3_-_Household-Survey-3 - Household-Survey", clear
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\groups_hh_survey", force
drop _merge
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\groups_hh_survey_cap", force
drop _merge
merge 1:1 _index using "$working_ANALYSIS\data\raw\Survey\nets_hh_survey", force
drop _merge

dropmiss, force



// Append HH-Survey Epxeriment Survey
append using "$working_ANALYSIS\data\raw\Survey\experiment_complete" 

save "$working_ANALYSIS\data\raw\Survey\Phi_22_import", replace





** EOF














*-----------------------
* 3) CLEANING: RENAMING AND REPLACING MISSINGS
*-----------------------

use "$working_ANALYSIS\data\raw\Survey\Phi_22_import.dta", clear
dropmiss, force
rename *, lower


/* get list of variables & labels
preserve
describe, replace clear
export excel name vallab varlab using "$raw_data\labels_22.xlsx", firstrow(variables) replace

* (line removed 2026-05-07: hardcoded Max-Burger OneDrive path; canonical panel loaded later from data/clean/PHI_Panel_12_16_22.dta)
describe, replace clear
export excel name vallab  varlab using "$raw_data\labels_12_16.xlsx", firstrow(variables) replace
restore
*/




// SETUP
encode s1, generate(assist)
rename s3 village
rename start date
lab var date "Date of interview"
lab var consent "Do you want to participate?"

lab define sample1 2 "Experiment" 1 "Household-Survey"
lab val sample sample1
lab var sample "Sample"





// Socio-Economics
rename sd1_intro name
replace name = sd1_name if sd1_name != ""

rename sd1_nr phone_no
rename sd4 gender
rename sd6 hh_head
rename sd6_who hh_head_name
rename sd7 status
rename sd5 educ
rename sd5_1 educ_grade

* Income source
rename sd401 inc_labour
rename sd402 inc_business
rename sd403 inc_remittance
rename sd404 inc_pension
rename sd405 inc_fin_assist
rename sd406 inc_sen_assist
rename sd407 inc_uct
rename sd408 inc_in_kind
rename sd409 inc_support
rename sd4010 inc_other
rename sd4011 inc_none
rename sd41_1 labour_what
rename sd41_2 labour_average
rename sd41_3 labour_good
rename sd41_4 labour_bad
rename sd41_5 labour_regular
rename sd41_6 labour_more
rename sd42_1 labour2_what
rename sd42_2 labour2_average
rename sd42_3 labour2_good
rename sd42_4 labour2_bad
rename sd42_5 labour2_regular
rename sd42_6 labour2_more
rename sd43_1 labour3_what
rename sd43_2 labour3_average
rename sd43_3 labour3_good
rename sd43_4 labour3_bad
rename sd43_5 labour3_regular
rename sd44_1 business_what
rename sd44_2 business_average
rename sd44_3 business_good
rename sd44_4 business_bad
rename sd44_5 business_regular
rename sd45_1 remit_people
rename sd45_2 remit_average
rename sd45_3 remit_good
rename sd45_4 remit_bad
rename sd45_5 remit_regular
rename sd46_2 pension_average
rename sd46_5 pension_regular
rename sd47_2 fin_assist_average
rename sd47_5 fin_assist_regular
rename sd48_2 sen_assist_average
rename sd48_5 sen_assist_regular
rename sd61_2 in_kind_average
rename sd61_5 in_kind_regular
rename sd62_1 support_average
rename sd62_2 support_good
rename sd62_3 support_bad
rename sd62_4 support_regular
rename sd49_1 other_inc_what
rename sd49_2 other_inc_average
rename sd49_3 other_inc_good
rename sd49_4 other_inc_bad
rename sd49_5 other_inc_regular
rename sd49_6 other_inc2
rename sd50_2 other_inc2_average
rename sd50_3 other_inc2_good
rename sd50_4 other_inc2_bad
rename sd50_5 other_inc2_regular
rename sd50_6 other_inc3
rename sd52 ymonth

rename sd53 meals_12_months
rename sd54 meals
replace meals = 0 if meals_12_months == 0 // If they did not have to reduce meals in last 12 months, they were not asked whether they had to reduce meals in last month
rename sd55 savings
rename sd56 debts
rename sd57 debtsource
rename sd58_other debtsourcespec


lab var labour_what "Labour 1: Labour occupation type"
lab var labour_average "Labour 1: Average income"
lab var labour_good "Labour 1: Income in good month"
lab var labour_bad "Labour 1: Income in bad month"
lab var labour_regular "Labour 1: Receive regular income from this source"
lab var labour_more "Other labour income sources?"
lab var labour2_what "Labour 2: Labour occupation type"
lab var labour2_average "Labour 2: Average income"
lab var labour2_good "Labour 2: Income in good month"
lab var labour2_bad "Labour 2: Income in bad month"
lab var labour2_regular "Labour 2: Receive regular income from this source"
lab var labour2_more "Other labour income sources?"
lab var labour3_what "Labour 3: Labour occupation type"
lab var labour3_average "Labour 3: Average income"
lab var labour3_good "Labour 3: Income in good month"
lab var labour3_bad "Labour 3: Income in bad month"
lab var labour3_regular "Labour 3: Receive regular income from this source"
lab var business_what "Business: Bussiness type"
lab var business_average "Business: Average income"
lab var business_good "Business: Income in good month"
lab var business_bad "Business: Income in bad month"
lab var business_regular "Business: Receive regular income from this source"
lab var remit_people "From how many people do you receive remittances?"
lab var remit_average "Remittance: Average income"
lab var remit_good "Remittance: Income in good month"
lab var remit_bad "Remittance: Income in bad month"
lab var remit_regular "Remittance: Receive regular income from this source"
lab var in_kind_average "In-kind: Average income"
lab var in_kind_regular "In-kind: Receive regular income from this source"
lab var pension_average "Pension: Average income"
lab var pension_regular "Pension: Receive regular income from this source"
lab var fin_assist_average "Financial assist: Average income"
lab var fin_assist_regular "Financial assist: Receive regular income from this source"
lab var sen_assist_average "Senior assit: Average income"
lab var sen_assist_regular "Senior assit: Receive regular income from this source"
lab var support_average "Remittance: Average income"
lab var support_good "Remittance: Income in good month"
lab var support_bad "Remittance: Income in bad month"
lab var support_regular "Remittance: Receive regular income from this source"
lab var other_inc_what "Other 1: Occupation type"
lab var other_inc_average "Other 1: Average income"
lab var other_inc_good "Other 1: Income in good month"
lab var other_inc_bad "Other 1: Income in bad month"
lab var other_inc_regular "Other 1: Receive regular income from this source"
lab var other_inc2 "Other 2: Occupation type"
lab var other_inc2_average "Other 2: Average income"
lab var other_inc2_good "Other 2: Income in good month"
lab var other_inc2_bad "Other 2: Income in bad month"
lab var other_inc2_regular "Other 2: Receive regular income from this source"
lab var other_inc3 "Other occupation"
lab var ymonth "Average monthly household income"
lab var meals_12_months "How often did you eat less than you felt you should (last 12 months)"
lab var meals "Did anybody in the household reduce meals in the last month?"
lab var savings "How much savings does your household have?"
lab var debts "How much debts does your household have?"
lab var debtsource "Whom do you owe mainly?"
lab var debtsourcespec "Other (specify)"




* House own and material
rename sd59_1 house_own
rename sd59_2_length house_length
rename sd59_2_width house_width
rename sd59_4 land_own
rename sd59_51 roof_nipa
rename sd59_52 roof_bamboo
rename sd59_53 roof_wood
rename sd59_54 roof_cement
rename sd59_55 roof_iron
rename sd59_56 roof_stone
rename sd59_57 roof_makeshift
rename sd59_58 roof_hardiflex
rename sd59_59 roof_plywood
rename sd59_510 roof_tiles
rename sd59_511 roof_other
rename sd59_61 walls_nipa
rename sd59_62 walls_bamboo
rename sd59_63 walls_wood
rename sd59_64 walls_cement
rename sd59_65 walls_iron
rename sd59_66 walls_stone
rename sd59_67 walls_makeshift
rename sd59_68 walls_hardiflex
rename sd59_69 walls_plywood
rename sd59_610 walls_tiles
rename sd59_611 walls_other
rename sd59_71 floor_nipa
rename sd59_72 floor_bamboo
rename sd59_73 floor_wood
rename sd59_74 floor_cement
rename sd59_75 floor_iron
rename sd59_76 floor_stone
rename sd59_77 floor_makeshift
rename sd59_78 floor_hardiflex
rename sd59_79 floor_plywood
rename sd59_710 floor_tiles
rename sd59_711 floor_other
rename sd59_other material_other

lab var house_own "Do you own the house you are living in?"
lab var house_length "How big is your house (length)?"
lab var house_width "How big is your house (width)?"
lab var land_own "Do you own the land of the house you are living in?"



* Assetts
rename sd60_1 radio
rename sd60_2 television
rename sd60_3 cable
rename sd60_4 phone
rename sd60_5 computer
rename sd60_6 laptop
rename sd60_7 tablet
rename sd60_8 wifi
rename sd60_9 washing_mashine
rename sd60_10 rice_cooker
rename sd60_11 fridge
rename sd60_12 freezer
rename sd60_13 electric_fan
rename sd60_14 ac
rename sd60_15 stove
rename sd60_16 solar_power
rename sd60_17 generator
rename sd60_18 car
rename sd60_19 motor_cycle
rename sd60_20 tricycle
rename sd60_21 bicycle
rename sd60_22 tractor
rename sd60_23 motorized_boat
rename sd60_24 unmotorized_boat
rename sd60_25 agri_mat
rename sd8 brgy_always
rename sd9 brgy_years
rename sd10 brgy_before
rename sd121 move_family
rename sd122 move_hazards
rename sd123 move_conflicts
rename sd124 move_job
rename sd125 move_other
rename sd12_other move_other_what
rename sd13 brgy_home
lab var brgy_home "What place do you consider home?"
rename sd25 no_groups
lab var no_groups "To how many groups do you belong?"



lab var radio "Radio"
lab var television "Television"
lab var cable "Cable"
lab var phone "Mobile phone / Smart phone"
lab var computer "Computer"
lab var laptop "Laptop"
lab var tablet "Tablet"
lab var wifi "Wifi"
lab var washing_mashine "Washing Machine"
lab var rice_cooker "Rice Cooker"
lab var fridge "Fridge / Refrigerator"
lab var freezer "Freezer"
lab var electric_fan "Electric fan"
lab var ac "Aircondition"
lab var stove "Stove"
lab var solar_power "Solar power"
lab var generator "Generator"
lab var car "Car"
lab var motor_cycle "Motor cycle / scooter"
lab var tricycle "Tricicle"
lab var bicycle "Bicycle"
lab var tractor "Tractor"
lab var motorized_boat "Motorized Boat"
lab var unmotorized_boat "Unmotorized Boat"
lab var agri_mat "Agricultural Matierals"
lab var brgy_always "Have you been living always in this Barangay?"
lab var brgy_years "For how long have you been living in this Barangay?"
lab var brgy_before "Where did you live before moving to this Barangay?"

lab var phone_no "Phone number"
lab var gender "Gender"
lab var hh_head "Household head"
lab var hh_head_name "Name of household head"
lab var status "Marital status"
lab var educ "Education"
lab var educ_grade "Highest grade visited"
lab var inc_labour "Income source: Labour"
lab var inc_business "Income source: Business"
lab var inc_remittance "Income source: Remmitance"
lab var inc_pension "Income source: Pension"
lab var inc_fin_assist "Income source: Financial Assistance"
lab var inc_sen_assist "Income source: Senior assistance"
lab var inc_uct "Income source: Unconditional cash transfer"
lab var inc_in_kind "Income source: In-kind support"
lab var inc_support "Income source: Support from family and friends"
lab var inc_other "Income source: Other"
lab var inc_none "Income source: None"
lab var roof_nipa "Roof: Nipa (Banana palm leaf)"
lab var roof_bamboo "Roof: Bamboo"
lab var roof_wood "Roof: Wood"
lab var roof_cement "Roof: Cement"
lab var roof_iron "Roof: Iron"
lab var roof_stone "Roof: Stone"
lab var roof_makeshift "Roof: Makeshift"
lab var roof_hardiflex "Roof: Hardiflex"
lab var roof_plywood "Roof: Plywood"
lab var roof_tiles "Roof: Tiles"
lab var roof_other "Roof: Other"
lab var walls_nipa "Walls: Nipa (Banana palm leaf)"
lab var walls_bamboo "Walls: Bamboo"
lab var walls_wood "Walls: Wood"
lab var walls_cement "Walls: Cement"
lab var walls_iron "Walls: Iron"
lab var walls_stone "Walls: Stone"
lab var walls_makeshift "Walls: Makeshift"
lab var walls_hardiflex "Walls: Hardiflex"
lab var walls_plywood "Walls: Plywood"
lab var walls_tiles "Walls: Tiles"
lab var walls_other "Walls: Other"
lab var floor_nipa "Floor: Nipa (Banana palm leaf)"
lab var floor_bamboo "Floor: Bamboo"
lab var floor_wood "Floor: Wood"
lab var floor_cement "Floor: Cement"
lab var floor_iron "Floor: Iron"
lab var floor_stone "Floor: Stone"
lab var floor_makeshift "Floor: Makeshift"
lab var floor_hardiflex "Floor: Hardiflex"
lab var floor_plywood "Floor: Plywood"
lab var floor_tiles "Floor: Tiles"
lab var floor_other "Floor: Other"
lab var material_other "Material: Other"
lab var move_family "Reason for moving: Family (e.g. Moving in with my spouse, taking care of family members)"
lab var move_hazards "Reason for moving: Too many environmental hazards at old place"
lab var move_conflicts "Reason for moving: Conflicts with other people at old place"
lab var move_job "Reason for moving: Better job opportunities at new place"
lab var move_other "Reason for moving: Other"
lab var move_other_what "Reason for moving: Other (what)"

rename sd3 age
rename hh_size_permanent hh_size_total
rename age6 age6
rename age12 age12
rename age17 age1317
rename age60 age1860
rename age99 age60






// Groups
rename rg1_gov a3gov
rename rg1_prov a3prov
rename rg1_muni a3mun
rename rg1_captain a3cap
rename rg1_kagawat a3kaga
rename rg1_people a3brgy
rename rg1_fisher a3fish
rename rg1_ngo a3ngo
rename rg1_farmc a3farmc
rename rg1_mpa a3commit
rename rg1_fisher_associ a3assoc
rename rg1_church a3church
rename rg2_gov a3gov2
rename rg2_prov a3prov2
rename rg2_muni a3mun2
rename rg2_captain a3cap2
rename rg2_kagawat a3kaga2
rename rg2_people a3brgy2
rename rg2_fisher a3fish2
rename rg2_ngo a3ngo2
rename rg2_farmc a3farmc2
rename rg2_mpa a3commit2
rename rg2_fisher_associ a3assoc2
rename rg2_church a3church2
rename rg3_gov a3gov3
rename rg3_prov a3prov3
rename rg3_muni a3mun3
rename rg3_captain a3cap3
rename rg3_kagawat a3kaga3
rename rg3_relatives a3rela3
rename rg3_friends a3friend3
rename rg3_fisher a3fish3
rename rg3_neighb a3neigh3
rename rg3_ngo a3ngo3
rename rg3_farmc a3farmc3
rename rg3_mpa a3commit3
rename rg3_fisher_associ a3assoc3
rename rg3_church a3church3
rename rg3_bank a3bank3
rename rg3_insurance a3insurance3
rename rg3_gov_001 a3gov4
rename rg3_prov_001 a3prov4
rename rg3_muni_001 a3mun4
rename rg3_captain_001 a3cap4
rename rg3_kagawat_001 a3kaga4
rename rg3_relatives_001 a3rela4
rename rg3_friends_001 a3friend4
rename rg3_fisher_001 a3fish4
rename rg3_neighb_001 a3neigh4
rename rg3_ngo_001 a3ngo4
rename rg3_farmc_001 a3farmc4
rename rg3_mpa_001 a3commit4
rename rg3_fisher_associ_001 a3assoc4
rename rg3_church_001 a3church4
rename rg3_bank_001 a3bank4
rename rg3_insurance_001 a3insurance4
rename rg5_1 vote_brgy
rename rg5_2 vote_mun
rename rg5_3 vote_prov
rename rg5_4 vote_nat
rename rg7 a17migr
rename rg8 a17migrr

lab var a3gov "Trust in National government"
lab var a3prov "Trust in Provincial government"
lab var a3mun "Trust in Municipal/city government officials (LGU)"
lab var a3cap "Trust in Barangay captain"
lab var a3kaga "Trust in Barangay kagawat"
lab var a3brgy "Trust in People from your barangay"
lab var a3fish "Trust in Fishers from your barangay"
lab var a3ngo  "Trust in NGO's"
lab var a3farmc "Trust in FARMC"
lab var a3commit  "Trust in MPA committee"
lab var a3assoc  "Trust in Fishermen association"
lab var a3church  "Trust in Church"

lab var a3gov2  "Ask advice: National government"
lab var a3prov2  "Ask advice: Provincial government"
lab var a3mun2  "Ask advice: Municipal/city government officials (LGU)"
lab var a3cap2  "Ask advice: Barangay captain"
lab var a3kaga2  "Ask advice: Barangay kagawat"
lab var a3brgy2  "Ask advice: People from your barangay"
lab var a3fish2  "Ask advice: Fishers from your barangay"
lab var a3ngo2  "Ask advice: NGO's"
lab var a3farmc2  "Ask advice: FARMC"
lab var a3commit2 "Ask advice: MPA committee"
lab var a3assoc2 "Ask advice: Fishermen association"
lab var a3church2 "Ask advice: Church"

lab var a3gov3 "In emergency, believe would receive help from National government"
lab var a3prov3  "In emergency, believe would receive help from Provincial government"
lab var a3mun3  "In emergency, believe would receive help from Municipal/city government officials (LGU)"
lab var a3cap3 "In emergency, believe would receive help from Barangay captain"
lab var a3kaga3  "In emergency, believe would receive help from Barangay kagawat"
lab var a3rela3  "In emergency, believe would receive help from Relatives within Barangay"
lab var a3friend3  "In emergency, believe would receive help from Friends within Barangay"
lab var a3fish3 "In emergency, believe would receive help from Fishermen within Barangay"
lab var a3neigh3  "In emergency, believe would receive help from Neighbors"
lab var a3ngo3 "In emergency, believe would receive help from NGO"
lab var a3bank3  "In emergency, believe would receive help from My Bank"
lab var a3insurance3 "In emergency, believe would receive help from My insurance provider"
lab var a3farmc3 "In emergency, believe would receive help from FARMC"
lab var a3commit3 "In emergency, believe would receive help from MPA committee"
lab var a3assoc3 "In emergency, believe would receive help from Fishermen association"
lab var a3church3 "In emergency, believe would receive help from Church"

lab var a3gov4 "In emergency, did turn to National government"
lab var a3prov4  "In emergency, did turn to Provincial government"
lab var a3mun4  "In emergency, did turn to Municipal/city government officials (LGU)"
lab var a3cap4 "In emergency, did turn to Barangay captain"
lab var a3kaga4  "In emergency, did turn to Barangay kagawat"
lab var a3rela4 "In emergency, did turn to Relatives within Barangay"
lab var a3friend4  "In emergency, did turn to Friends within Barangay"
lab var a3fish4 "In emergency, did turn to Fishermen within Barangay"
lab var a3neigh4  "In emergency, did turn to Neighbors"
lab var a3ngo4 "In emergency, did turn to NGO"
lab var a3bank4 "In emergency, did turn to My Bank"
lab var a3insurance4 "In emergency, did turn to My insurance provider"
lab var a3farmc4 "In emergency, did turn to FARMC"
lab var a3commit4 "In emergency, did turn to MPA committee"
lab var a3assoc4 "In emergency, did turn to Fishermen association"
lab var a3church4 "In emergency, did turn to Church"

lab var vote_brgy "Voted in last barangay elections"
lab var vote_mun "Voted in last municipality elections"
lab var vote_prov "Voted in last provincial elections"
lab var vote_nat "Voted in last national elections"










// Vignette
lab define vignette 1 "Community impl., Big Transgr." 2 "Community impl., Small Transgr." 3 "Minicip. impl., Big Transgr." 4 "Municip impl., Small Transgr."
lab val vignette vignette

rename v1 v_behave	
lab var v_behave "Out of 10 how many would behave as Mr. Delacruz?"
rename v2 v_report	
lab var v_report "Out of 10 how many would report Mr. Delacruz?"
rename v3 v_sanctions	
lab var v_sanctions "How likely are sanctions like monetary fines going to prevent such rule-breaking?"
rename v4 v_appropriate	
lab var v_appropriate "How appropriate do you consider Mr. Delacruz' rule-breaking?"




// Experiment
rename exp1_1 exp_rule_area	
lab var exp_rule_area "Importance of rule: Prohibited to fish in spawning ground"
rename exp1_2 exp_rule_method
lab var exp_rule_method "Importance of rule: Prohibited to use intensive methods"
rename exp1_3 exp_rule_monitoring
lab var exp_rule_monitoring "Importance of rule: Monitoring installed to detect rule-breakers"
rename exp1_4 exp_rule_sanction	
lab var exp_rule_sanction "Importance of rule: Sanctions if detected rule-breaking"
rename exp2_t12 exp_decision
replace exp_decision=exp2_t3 if exp2_t3 != .
lab var exp_decision "Preference in decision making: Majority rule vs. leader decides"
rename exp3_1 exp_cdp1	
rename exp3_2 exp_cdp2	
rename exp3_3 exp_cdp3	
rename exp3_4 exp_cdp4	
rename exp3_5 exp_cdp5	
rename exp3_6 exp_cdp6	
rename exp3_7 exp_cdp7	
rename exp3_8 exp_cdp8	
rename exp3_9 exp_cdp9	
rename exp3_10 exp_cdp10	
rename exp3_11 exp_cdp11	
rename exp3_13 exp_cdp13	
rename exp3_14 exp_cdp14	
rename exp3_15 exp_cdp15	
rename exp3_16 exp_cdp16	
rename exp3_17 exp_cdp17	
rename exp3_18 exp_cdp18	
rename exp41 exp_fun	
rename exp42 exp_easy	
rename exp43 exp_interesting	
rename exp44 exp_frustrating	
rename exp45 exp_difficult	
rename exp46 exp_confusing	
rename exp47 exp_boring	
rename exp48 exp_tiring	
rename exp4_other exp_other	
rename exp5 exp_satisfied	
rename exp6 exp_understand	
rename exp7 exp_attention	
rename exp8 exp_decision_others	
rename exp9_1 exp_realism_p1	
rename exp9_2 exp_realism_p2	
rename exp9_3 exp_realism_p3	
rename exp10 exp_know_others	

pca exp_cdp1 exp_cdp2 exp_cdp3 exp_cdp4 exp_cdp5 exp_cdp6 exp_cdp7 exp_cdp8 exp_cdp9 exp_cdp10 exp_cdp11 exp_cdp13 exp_cdp14 exp_cdp15 exp_cdp16 exp_cdp17 exp_cdp18, comp(1)
estat kmo
predict cdp

// FISHING
rename f0_1 fishing	
rename mpa mpa_self	
rename f0_2 fishing_main_occ	
rename sd19_1 fishery	
rename sd19_2 fisherygood	
rename sd19_3 fisherybad	
rename f0_3 fishing_years	
rename f0_4 fishing_parents	
rename f0_5_1 fishing_6	
rename f0_5_2 fishing_12	
rename f0_5_3 fishing_17	
rename f0_5_4 fishing_60	
rename f0_5_5 fishing_99	
	
* Gear owned by interviewee
rename e11 own_net	
rename e12 own_spear_gun	
rename e13 own_hook	
rename e14 own_unmotor_boat	
rename e15 own_motor_boat	
rename e1_other own_other	
rename e1_1 own_nets_no	

* Gear used by interviewee
rename f21 use_net	
rename f22 use_spear_gun	
rename f23 use_hook	
rename f2_other use_other	
	
* Gear used by others in community
rename f31 f1net	
rename f32 f1spear	
rename f33 f1hook	
rename f3_other f1other	

* Fishing in groups
rename f4 f2groups	
rename f51 f2self	
rename f52 f2othfish	
rename f53 f2buy	
rename f54 f2coop	
rename f55 f2family	
rename f5_other f2other	
rename f6 f2num	
rename f7 f2same	

* Last high season	
rename f9_1_11 high_january
lab var high_january "Last high season: January"
rename f9_1_12 high_february
lab var high_february "Last high season: February"
rename f9_1_13 high_march
lab var high_march "Last high season: March"
rename f9_1_14 high_april
lab var high_april "Last high season: April"
rename f9_1_15 high_may
lab var high_may "Last high season: May"
rename f9_1_16 high_june
lab var high_june "Last high season: June"
rename f9_1_17 high_july
lab var high_july "Last high season: July"
rename f9_1_18 high_august
lab var high_august "Last high season: August"
rename f9_1_19 high_september
lab var high_september "Last high season: September"
rename f9_1_110 high_october
lab var high_october "Last high season: October"
rename f9_1_111 high_november
lab var high_november "Last high season: November"
rename f9_1_112 high_december
lab var high_december "Last high season: December"
rename f9_1_2 high_fish	
rename f9_2 high_fish_exclusive	
rename f9_31 high_tuna	
lab var high_tuna "Mainly fished Tuna"
rename f9_32 high_balanchong	
lab var high_balanchong "Mainly fished Balanchong"
rename f9_33 high_bangus	
lab var high_bangus "Mainly fished Bangus"
rename f9_34 high_bugoang	
lab var high_bugoang "Mainly fished Bugoang"
rename f9_35 high_bulaw	
lab var high_bulaw "Mainly fished Bulaw"
rename f9_36 high_crab	
lab var high_crab "Mainly fished Crab"
rename f9_37 high_maya	
lab var high_maya "Mainly fished Maya"
rename f9_38 high_pisugo	
lab var high_pisugo "Mainly fished Pisugo"
rename f9_39 high_tuloy	
lab var high_tuloy "Mainly fished Tuloy"
rename f9_310 high_ubakan	
lab var high_ubakan "Mainly fished Ubekan"
rename f9_311 hith_other	
lab var hith_other "Mainly fished Other"
rename f9_312 high_none	
lab var high_none "Mainly fished None of the above"
rename f9_3_other1 high_other1	
lab var high_other1 "Other fish 1:"
rename f9_3_other2 high_other2	
lab var high_other2 "Other fish 2:"
rename f9_3_other3 high_other3	
lab var high_other3 "Other fish 3:"
rename f9_3_other4 high_other4	
lab var high_other4 "Other fish 4:"
rename f9_3_other5 high_other5	
lab var high_other5 "Other fish 5:"
rename f9_4_1 high_tuna_kg	
lab var high_tuna_kg "Average catch of Tuna in high season (kg per week)"
rename f9_4_2 high_balanchong_kg	
lab var high_balanchong_kg "Average catch of Balanchong in high season (kg per week)"
rename f9_4_3 high_bangus_kg	
lab var high_bangus_kg "Average catch of Bangus in high season (kg per week)"
rename f9_4_4 high_bugoang_kg	
lab var high_bugoang_kg "Average catch of Bugoang in high season (kg per week)"
rename f9_4_5 high_bulaw_kg	
lab var high_bulaw_kg "Average catch of Bulaw in high season (kg per week)"
rename f9_4_6 high_crab_kg	
lab var high_crab_kg "Average catch of Crab in high season (kg per week)"
rename f9_4_7 high_maya_kg	
lab var high_maya_kg "Average catch of Maya Maya in high season (kg per week)"
rename f9_4_8 high_pisugo_kg	
lab var high_pisugo_kg "Average catch of Pisugo in high season (kg per week)"
rename f9_4_9 high_tuloy_kg	
lab var high_tuloy_kg "Average catch of Tuloy in high season (kg per week)"
rename f9_4_10 high_ubakan_kg	
lab var high_ubakan_kg "Average catch of Ubakan in high season (kg per week)"
rename f9_4_11 high_other1_kg	
lab var high_other1_kg "Average catch of Other 1 in high season (kg per week)"
rename f9_4_12 high_other2_kg	
lab var high_other2_kg "Average catch of Other 2 in high season (kg per week)"
rename f9_4_13 high_other3_kg	
lab var high_other3_kg "Average catch of Other 3 in high season (kg per week)"
rename f9_4_14 high_other4_kg	
lab var high_other4_kg "Average catch of Other 4 in high season (kg per week)"
rename f9_4_15 high_other5_kg	
lab var high_other5_kg "Average catch of Other 5 in high season (kg per week)"

* Relation to other fisher in barangay / neighbouring barangays
rename f10 a5b	
rename f11 a5n	

* Resources diminished/recovered/stayed the same
rename f12_1 f3corals	
rename f12_2 f3reef_fish	
rename f12_3 f3large_fish	
rename f12_4 f3mangroves	
rename f12_5 f3seaweed	
rename f12_6 f3other_diminish	
lab var f3other_diminish "What other resources diminished"
rename f12_7 f3other_same	
lab var f3other_same "What other resources stayed the same"
rename f12_8 f3other_recover	
lab var f3other_recover "What other resources recovered"
rename f12_8_001 f3why
lab var f3why "Why do you think the resources recovered?"
rename f12_9 f4why	

* Problems in area
rename f13_1 f5corr	
rename f13_2 f5law	
rename f13_3 f5monit	
rename f13_4 f5monits	
rename f13_5 f5indu	
rename f13_6 f5rec	
rename f13_7 f5state	
rename f13_8 f5many	
rename f13_9 f5zone	
rename f13_10 f5poll	
rename f13_11 f5org	
rename f13_12 f5rules	
rename f13_13 f5price	
rename f13_14 f5alt	
rename f13_15 f5tec	
rename f13_16 f5disp	
rename f13_17 f5togh	
rename f13_18 f5steal	
rename f13_19 f5viol	
rename f13_20 f5credit	
rename f13_21 f5uncert	
rename f13_22 f5rulbaran	
rename f13_23 f5rulnonbaran	

* Rules
rename f15_1 f6area	
rename f15_2 f6areag	
rename f15_3 f6areac
rename f15_4 f6areap
rename f16_1 f6cyan	
rename f16_2 f6cyang	
rename f16_3 f6cyanc	
rename f16_4 f6cyanp	
rename f17_1 f6dynam	
rename f17_2 f6dynamg	
rename f17_3 f6dynamc	
rename f17_4 f6dynamp	
rename f18_1 f6mesh	
rename f18_5 f6meshs	
rename f18_2 f6meshg	
rename f18_3 f6meshc	
rename f18_4 f6meshp	
rename f19_1 f6season	
rename f19_2 f6seasong	
rename f19_3 f6seasonc	
rename f19_4 f6seasonp	
rename f21_1 f6species	
rename f21_2 f6speciesg	
rename f21_3 f6speciesc	
rename f21_4 f6speciesp	
rename f22_1 f6oth	
rename f22_5 f6othspec	
rename f22_2 f6othg	
rename f22_3 f6othc	
rename f22_4 f6othp	
rename f22_6 f6oth2	
rename f23_5 f6othspec2	
rename f23_2 f6othg2	
rename f23_3 f6othc2	
rename f23_4 f6othp2	
rename f23_6 f6oth3	

* RUles are enforced
rename f25 f7enf	
rename f26 f7compl	
rename f27 f7auth	

* Representation through organization
rename f28_1 f7bfarmc	
rename f28_2 f7fish	
rename f28_3 f7mpa	
rename f28_4 f7bantay_dagat	
rename f28_5_which f7othspec	
rename f28_5_rate f7othrate	

* Perception of MPA
rename f29_1 f11incr	
rename f29_2 f11stock	
rename f29_3 f11alt	
rename f29_4 f11enf	
rename f29_5 f11notake	
rename f30_1 mpa_council_part	
rename f31_2 mpa_counil_lead	
rename f31_2_which mpa_counil_lead_which	
rename f31_3 mpa_counil_meet	
rename f31_3_other mpa_counil_meet_other	
rename f31_4 mpa_council_meet_attend	
rename f31_5 mpa_council_fee	
rename f31_6 mpa_council_engage	
rename f32_1 mpa_council_term	
rename f32_2 mpa_council_rule	
rename f32_3 mpa_council_decisions	
rename f32_4 mpa_council_enforced	
rename f32_5 mpa_council_monitoring	
rename f32_6 mpa_council_sanctions	
rename cdp1_1 mpa_cdp1_1	
rename cdp1_2 mpa_cdp1_2	
rename cdp1_3 mpa_cdp1_3	
rename cdp1_4 mpa_cdp1_4	
rename cdp2_1 mpa_cdp2_1	
rename cdp2_2 mpa_cdp2_2	
rename cdp2_3 mpa_cdp2_3	
rename cdp3_1 mpa_cdp3_1	
rename cdp3_2 mpa_cdp3_2	
rename cdp4 mpa_cdp4	
rename cdp5_1 mpa_cdp5_1	
rename cdp5_2 mpa_cdp5_2	
rename cdp5_3 mpa_cdp5_3	
rename cdp6_1 mpa_cdp6_1	
rename cdp6_2 mpa_cdp6_2	
rename cdp6_3 mpa_cdp6_3	
rename cdp7_1 mpa_cdp7_1	
rename cdp7_2 mpa_cdp7_2	
rename cdp7_3 mpa_cdp7_3	
rename cdp8_1 mpa_cdp8_1	
rename cdp8_2 mpa_cdp8_2	




** Ladders and agency
* Life ladder
rename ld1_1 ladder_life_now 
rename ld1_2 ladder_life_future 
rename ld1_3 ladder_life_aspiration


* Econ ladder
rename ld2_1 ladder_econ_now 
rename ld2_years1 ladder_econ_years 
rename ld2_2 ladder_econ_before 
rename ld2_years2 ladder_econ_before_years
rename econ_ladder_max ladder_econ_max 
rename econ_ladder_min ladder_econ_min
rename econ_ladder_expect ladder_econ_future
rename econ_ladder_aspiration ladder_econ_aspiration
rename driver1 econ_driver_job 
rename driver2 econ_driver_work 
rename driver3 econ_driver_city 
rename driver4 econ_driver_abroad 
rename driver5 econ_driver_network
rename driver6 econ_driver_support 
rename driver7 econ_driver_god 
rename driver8 econ_driver_nothing 
rename driver9 econ_driver_risks 
rename driver10 econ_driver_edu 
rename driver11 econ_driver_skills 
rename driver12 econ_driver_born
rename driver13 econ_driver_fair 
rename driver14 econ_driver_reckless
rename driver16 econ_driver_none
rename driver_other econ_driver_other 
rename barrier1 econ_barrier_job 
rename barrier2 econ_barrier_move 
rename barrier3 econ_barrier_network 
rename barrier4 econ_barrier_support 
rename barrier5 econ_barrier_hazard 
rename barrier6 econ_barrier_health 
rename barrier7 econ_barrier_expenses 
rename barrier8 econ_barrier_abilities 
rename barrier9 econ_barrier_perseverance 
rename barrier10 econ_barrier_badluck
rename barrier11 econ_barrier_family 
rename barrier12 econ_barrier_fair 
rename barrier13 econ_barrier_egoistic 
rename barrier15 econ_barrier_none
rename barrier_other econ_barrier_other 

* Agency
rename ld6_1 econ_aspiration 
rename ld6_2 econ_knowledge
rename ld6_3 econ_agency1 
rename ld6_4 econ_agency2 
rename ld6_5 econ_agency3 
rename ld6_6 econ_agency7 
rename ld6_7 econ_agency8




// Life Events

* Major life events
rename le1_type1 mle1_type	
lab var mle1_type "Major life event 1: Type"
rename le1_type1_other mle1_type_other	
lab var mle1_type_other "Major life event 1: Type other"
rename le1_year1 mle1_year	
lab var mle1_year "Major life event 1: Year"
rename le1_type2 mle2_type	
lab var mle2_type "Major life event 2: Type"
rename le1_type2_other mle2_type_other	
lab var mle2_type_other "Major life event 2: Type other"
rename le1_year2 mle2_year	
lab var mle2_year "Major life event 2: Year"
rename le1_type3 mle3_type	
lab var mle3_type "Major life event 3: Type"
rename le1_type3_other mle3_type_other	
lab var mle3_type_other "Major life event 3: Type other"
rename le1_year3 mle3_year	
lab var mle3_year "Major life event 3: Year"



* Stressful life events (only asked if natural disaster not mentioned in question on any events)
rename le2_type1 sle1_type	
lab var sle1_type "Stressful life event 1: Type"
rename le2_type1_other sle1_type_other	
lab var sle1_type_other "Stressful life event 1: Type other"
rename le2_year1 sle1_year	
lab var sle1_year "Stressful life event 1: Year"
rename le2_type2 sle2_type	
lab var sle2_type "Stressful life event 2: Type"
rename le2_type2_other sle2_type_other	
lab var sle2_type_other "Stressful life event 2: Type other"
rename le2_year2 sle2_year	
lab var sle2_year "Stressful life event 2: Year"
rename le2_type3 sle3_type	
lab var sle3_type "Stressful life event 3: Type"
rename le2_type3_other sle3_type_other	
lab var sle3_type_other "Stressful life event 3: Type other"
rename le2_year3 sle3_year	
lab var sle3_year "Stressful life event 3: Year"


* Effect of Disaster/Calamity life event on risk, worries, solidarity, preparedness and trust in council
rename le3_1 le_disaster_risk
rename le3_2 le_disaster_worries
rename le3_3 le_disaster_solidarity
rename le3_4 le_disaster_prepare
rename le3_5 le_disaster_council



* Rating of the effect of life events on life
forvalues i = 1/6 {
replace le4_`i' = le4_`i'_other if le4_`i'_other != . 
}
rename le4_1 mle1_effect	
lab var mle1_effect "Major life event 1: Effect on life"
rename le4_2 mle2_effect	
lab var mle2_effect "Major life event 2: Effect on life"
rename le4_3 mle3_effect	
lab var mle3_effect "Major life event 3: Effect on life"
rename le4_4 sle1_effect	
lab var sle1_effect "Stressful life event 1: Effect on life"
rename le4_5 sle2_effect	
lab var sle2_effect "Stressful life event 2: Effect on life"
rename le4_6 sle3_effect	
lab var sle3_effect "Stressful life event 3: Effect on life"




// Yolanda
rename y1 yolanda_affected
rename y2 yolanda_rec_econ
rename y3 yolanda_rec_emot
rename y4_1 yolanda_trauma1
rename y4_2 yolanda_trauma2
rename y4_3 yolanda_trauma3
rename y4_4 yolanda_trauma4
rename y4_5 yolanda_trauma5
rename y4_6 yolanda_trauma6
rename y4_7 yolanda_trauma7





// Risks feared, occured in last 12 month, and last serious emergency sitaution

* Risks feared: What are the main risks you fear? 
rename r11 fear_disaster_belongings	
lab var fear_disaster_belongings "Fear: Natural disaster affecting property/personal belongings"
rename r12 fear_disaster_business	
lab var fear_disaster_business "Fear: Natural disaster affecting business/occupation"
rename r13 fear_weather_belongings	
lab var fear_weather_belongings "Fear: Bad weather affecting property/personal belongings"
rename r14 fear_weather_business	
lab var fear_weather_business "Fear: Bad weather disaster affecting business/occupation"
rename r15 fear_fire	
lab var fear_fire "Fear: Fire"
rename r16 fear_job	
lab var fear_job "Fear: Loss of Job"
rename r17 fear_health	
lab var fear_health "Fear: Health related emergency of household member"
rename r18 fear_death	
lab var fear_death "Fear: Dearh of household member"
rename r19 fear_illness_others	
lab var fear_illness_others "Fear: Illness & death of household member of working age"
rename r110 fear_theft	
lab var fear_theft "Fear: Victim of theft/violence"
rename r111 fear_pandemic	
lab var fear_pandemic "Fear: Pandemic"
rename r113 fear_none	
lab var fear_none "Fear: None"
rename r1_other1 fear_other1	
lab var fear_other1 "Fear:  Other"
rename r1_other2 fear_other2	
lab var fear_other2 "Fear:  Other"

* Occured in last 12 months: During the last 12 months, which of the following shocks has your household experienced? 
rename r2_what1 occur_disaster_belongings	
lab var occur_disaster_belongings "Occured last 12 months: Natural disaster affecting property/personal belongings"
rename r2_what2 occur_disaster_business	
lab var occur_disaster_business  "Occured last 12 months: Natural disaster affecting business/occupation"
rename r2_what3 occur_weather_belongings	
lab var occur_weather_belongings  "Occured last 12 months: Bad weather affecting property/personal belongings"
rename r2_what4 occur_weather_business	
lab var occur_weather_business  "Occured last 12 months: Bad weather disaster affecting business/occupation"
rename r2_what5 occur_fire	
lab var occur_fire  "Occured last 12 months: Fire"
rename r2_what6 occur_job	
lab var occur_job "Occured last 12 months: Loss of Job"
rename r2_what7 occur_health	
lab var occur_health "Occured last 12 months: Health related emergency of household member"
rename r2_what8 occur_death	
lab var occur_death "Occured last 12 months: Dearh of household member"
rename r2_what9 occur_illness_others	
lab var occur_illness_others "Occured last 12 months: Illness & death of household member of working age"
rename r2_what10 occur_theft	
lab var occur_theft "Occured last 12 months: Victim of theft/violence"
rename r2_what11 occur_pandemic	
lab var occur_pandemic "Occured last 12 months: Pandemic"
rename r2_what13 occur_none	
lab var occur_none "Occured last 12 months: None"
rename r2_other1 occur_other1	
lab var occur_other1 "Occured last 12 months:  Other"


* Last serious emergency: 
* a) What was the last serious emergency situation your household experienced
rename r3_what last_emerg	
rename r3_other last_emerg_other	
* b) When was it? (month/year)
rename r3_last_year last_emerg_year	
lab var last_emerg_year "Year of last serious emergency"
rename r3_last_months last_emerg_month	
lab var last_emerg_month "Month of last serious emergency"
* c) If natural disaster, bad weather, or disease: Were others in barangay seriously affected as well?
rename r3_village last_emerg_village	
* d) How did you react?
rename r3_react1 emerg_loan	
lab var emerg_loan "How did household react: Take a loan"
rename r3_react2 emerg_gift	
lab var emerg_gift "How did household react: Receive monetary gift"
rename r3_react3 emerg_help	
lab var emerg_help "How did household react: Nonfinancial help (food, labor)"
rename r3_react4 emerg_savings	
lab var emerg_savings "How did household react: Using savings"
rename r3_react5 emerg_insurance	
lab var emerg_insurance "How did household react: Insurance benefits"
rename r3_react6 emerg_assets	
lab var emerg_assets "How did household react: Sale of assets"
rename r3_react7 emerg_assistance	
lab var emerg_assistance "How did household react: Assistance of state/NGO"
rename r3_react8 emerg_work_more	
lab var emerg_work_more "How did household react: Working more"
rename r3_react9 emerg_consume_less	
lab var emerg_consume_less "How did household react: Consuming less"
rename r3_react11 emerg_none	
lab var emerg_none "How did household react: None of th above"
rename r3_react_other emerg_other	
lab var emerg_other "How did household react: Other"







// Expected future exposure & adaptation
* What do you think how severe will the threat posed by typhoons,  sea level rise, and  floods at the place you are currently living at be in the future?
rename r4 cc_severity

* Did you take any measures to protect your house and land from typhoons, sea leve
rename r5 cc_adapt

* Please tell me, what kind of measures did you take?
rename r61 adapt_house
rename r62 adapt_land
rename r63 adapt_store
rename r6_other adapt_other

* Please tell me, why did you not take any adaptation measures?
rename r71 no_adapt_proteced
rename r72 no_adapt_severity
rename r73 no_adapt_resources
rename r74 no_adapt_knowhow
rename r75 no_adapt_move
rename r76 no_adapt_move_anyways
rename r77 no_adapt_dk
rename r7_other no_adapt_other

* I feel uncertain about the best options to adapt to climate change.
rename r8_1 cc_uncertain

* I feel that climate change is too big for me to be able to adapt.
rename r8_2 cc_agency







// T.	Prediction of solidarity behavior
* Did you participate in the workshop in 2016?
*particip_2016
rename particip_2016 particip_2016_self

*... Do you remember this task?
* soli_remember

* Do you think that in villages which suffered greater destruction, people on average gave less, more, or equally compared to villages with less destruction?
* soli_give_general


* On average, how much do you think, did those in less affected / more affected / your villages 
*soli_give_lessa
*soli_give_morea
*soli_give_yourv





// Personality
/* Risk
Please tell me, in general, how willing or unwilling you are to take risks. Please tell us on a scale of 0-10, where 0 means “completely unwilling to take risks” and a 10 means you are “very willing to take risks”.
*/
rename p1 risk	
lab var risk "How willing or unwilling you are to take risks? (0 not at all, 10 very)"

/* Time
On a scale of 0-10, where 0 means “completely unwilling to do so” and 10 means “ very willing to do so”, how willing are you to give up something that is beneficial for you today in order to benefit more from that in the future?
*/
rename p2 patient	
lab var patient "How willing are you to give up something that is beneficial for you today in order to benefit more from that in the future? (0 not at all, 10 very)"

/* Pro-sociality
When someone does me a favor, I am willing to return it. [Positive reciprocity]
If I am treated very unjustly, I will take revenge at the first occasion, even if there is a cost to do so. [Negative reciprocity]
I am very willing to give to good causes without expecting anything in return. [Altruism]
*/
rename p3_1 recip_pos	
lab var recip_pos "When someone does me a favor, I am willing to return it."
rename p3_2 recip_neg	
lab var recip_neg "If I am treated very unjustly, I will take revenge"
rename p3_3 altruism	
lab var altruism "I am very willing to give to good causes without expecting anything in return."

/* Trust
Generally speaking, would you say that most people can be trusted or that you need to be very careful in dealing with people?
*/
rename p4 a1trust	

/* Communtiy work
Altogether, how many times in the past 12 months did you participate in community activities for common development goals?
*/
rename p7 commwork_2022	

/* Optimism
The next question deals with optimism. Optimists are people who look to the future with confidence and who mostly expect good things to happen. How would you describe yourself? How optimistic are you in general?
*/
rename p5 a1opti	

/* Social desirability scale
Please tell me whether you agree with the following statements...
*/
rename p6_1 a2goss	
rename p6_2 a2adv	
rename p6_3 a2admit	
rename p6_4 a2preach	
rename p6_5 a2even	
rename p6_6 a2ins	
rename p6_7 a2smash	
rename p6_8 a2return	
rename p6_9 a2idea	
rename p6_10 a2hurt	














*---------------------
* 4) ADJSUT MISTAKES
*--------------------

/* MPA-Questions in non-MPA
In Paloc Bigque (05.09.) an experiment-workshop was conducted. These were planned for MPAs only. Therefore, the MPA-questions were asked by default in the post-experiment questionnaire. However, Paloc Bigque was used as fill-up to get the 20 villages however, it has no MPA. Therefore, all answers regarding the MPA will be set to missing by hand.
*/
foreach var in f7mpa f11incr f11stock f11alt f11enf	f11notake mpa_council_part mpa_counil_lead mpa_counil_meet mpa_council_meet_attend mpa_council_fee mpa_council_engage mpa_council_term mpa_council_rule mpa_council_decisions mpa_council_enforced mpa_council_monitoring mpa_council_sanctions mpa_cdp1_1 mpa_cdp1_2	mpa_cdp1_3 mpa_cdp1_4 mpa_cdp2_1 mpa_cdp2_2 mpa_cdp2_3 mpa_cdp3_1 mpa_cdp3_2 mpa_cdp4 mpa_cdp5_1 mpa_cdp5_2 mpa_cdp5_3 mpa_cdp6_1 mpa_cdp6_2 mpa_cdp6_3 mpa_cdp7_1	mpa_cdp7_2 mpa_cdp7_3 mpa_cdp8_1 mpa_cdp8_2	a3commit a3commit2 a3commit3 a3commit4 {
replace `var' = . if village == "Paloc Bique"
}

replace mpa_counil_lead_which = "" if village == "Paloc Bique"
replace mpa_counil_meet_other = "" if village == "Paloc Bique"


/* None-option missing in last emergency question
In the question on the last emergency in the Household interview, the answer possibility None was missing. In this case, 'other' was chosen and 'none' typed by hand. This problem was detected in XYZ [check field-notes]
*/


/* Phone number normalization removed during de-identification.
   phone_no is a direct identifier and is dropped from every deposited dataset
   (see the de-identification block below), so the original phone-formatting
   logic -- which referenced individual respondents by name -- is not
   reproduced in the public package. */



/* Income: None if other income was already chosen
In some cases the option "receive no income" was chosen while other options were chosen as well. In these cases none should be changed to 0.
*/
replace inc_none = 0 if inc_labour == 1 | inc_business == 1 | inc_remittance == 1 |  inc_pension == 1 | inc_fin_assist == 1 | inc_sen_assist == 1 | inc_uct == 1 | inc_in_kind == 1| inc_support == 1 | inc_other == 1 








*---------------
* 5) FORMAT VARIABLES
*----------------

// Set don't knows / don't want to tells to ds
ds, has(type numeric)
foreach v in `r(varlist)' {
replace `v' = .d if `v' == 99 | `v' == .99 | `v' == -99 | `v' == -991 | `v' == 88 | `v' == 88
}

// Summarize nones
replace comment = "None" if comment == "None,," | comment == "N0ne" | comment == "N9n4" | comment == "NONE" | comment == "Non..p.e" | comment == "Non3" | comment == "None " | comment == "None, " | comment == "None," | comment == "None,," | comment == "None,." | comment == " None." | comment == "None. " | comment == "None." | comment == "None.." | comment == "Nòne" | comment == "Wala" | comment == "Wala na"











*---------------
* 5) Generating
*---------------
// Setup variables

// Year
gen year = 2022
lab var year "Year"

// Treatment group
gen treat = .
replace treat = 1 if particip_no >=21 & particip_no <=25
replace treat = 2 if particip_no >=26 & particip_no <=30
replace treat = 3 if particip_no >=31 & particip_no <=35
replace treat = 4 if particip_no >=36 & particip_no <=40
lab var treat "Treatment variable experiment"
lab define treat1 1 "Nothing changeable" 2 "Fishing rules changeable" 3 "Fishing & council rules changeable" 4 "Own rules"
lab val treat treat1


// Time
* Module A
gen time_consent = round((time_start_a - time_start_consent) *60*24 , .1)
lab var time_consent "Time in Consent (min)"

gen time_a = round((time_start_g - time_start_a) *60*24)
lab var time_a "Time in Module A: Socioeconomics (min)"

gen time_exp = round((time_start_b - time_start_exp) *60*24)
lab var time_exp "Time in Module G (min)"

gen time_v = .
replace time_v = round((time_start_b - time_start_v) *60*24) if sample == 2
replace time_v = round((time_end_g   - time_start_v) *60*24) if sample == 1
lab var time_v "Time in Module V (min)"

gen time_b = round((time_start_c_no_mpa - time_start_b) *60*24) if time_start_c_no_mpa  != .
replace time_b = round((time_start_c_mpa - time_start_b) *60*24) if time_start_c_mpa  != .
lab var time_b "Time in Module B: Fishing (min)"

gen time_c =  round((time_start_d - time_start_c_no_mpa) *60*24)  if time_start_c_no_mpa  != .
replace time_c =  round((time_start_d - time_start_c_mpa) *60*24)  if time_start_c_mpa != .
lab var time_c "Time in Module C: Ladders (min)"

gen time_d = round((time_start_e - time_start_d) *60*24)
lab var time_d "Time in Module D: Life Events (min)"

gen time_e = round((time_start_e - time_start_d) *60*24)
lab var time_e "Time in Module E: Perception of Yolanda & Climate Events (min)"

gen time_g = round((time_start_v - time_start_g) *60*24)
lab var time_g "Time in Module G:  (min)"

gen time_t = round((time_start_h - time_start_t) *60*24)
lab var time_t "Time in Module T: Solidarity-task (min)"

gen time_h = round((time_start_network - time_start_h) *60*24)
lab var time_h "Time in Module H: Personality (min)"

gen time_network = round((time_end_network - time_start_network) *60*24)
lab var time_network "Time in Module Network (min)"

egen time_sum = rowtotal(time_consent time_a time_exp time_v time_b time_c time_d time_e time_g time_t time_h time_network)
lab var time_sum "Total time with participant (min)"


save "$working_ANALYSIS\data\raw\Survey\Survey_phi_2022_clean1", replace



// Add village level data
* Bug fix 2026-05-07: the previous `collapse (mean) helper, by(village prov munic
* population mpa households eyedis intens)` produced multiple rows per village
* whenever any of those covariates varied across the 3 panel waves (2012/2016/2022),
* breaking the m:1 merge below with r(459). Filter to the 2022 wave (matches the
* experiment-survey wave being merged) and force one row per village.
use "$working_ANALYSIS\data\clean\PHI_Panel_12_16_22.dta", clear
keep if year == 2022
keep prov munic village population mpa households eyedis intens
replace mpa = . if village == "Bucaya" | village == "Nanding Lopez" | village == "Talotoan" // unclear whether MPA existed
duplicates drop village, force
save "$working_ANALYSIS\data\raw\Survey\village_level_data", replace

use "$working_ANALYSIS\data\raw\Survey\Survey_phi_2022_clean1.dta", clear
merge m:1 village using "$working_ANALYSIS\data\raw\Survey\village_level_data.dta"














*-----
* Order
*----
order ///
/*setup*/ date prov munic village population mpa households eyedis intens particip_no year assist consent particip_no sample treat ///
/*A: Socioeconomics*/ name phone_no age gender hh_head hh_head_name status educ educ_grade hh_size_total hh_size age6 age12 age1317 age1860 age60 inc_labour inc_business inc_remittance inc_pension inc_fin_assist inc_sen_assist inc_uct inc_in_kind inc_support inc_other inc_none labour_what labour_average labour_good labour_bad labour_regular labour_more labour2_what labour2_average labour2_good labour2_bad labour2_regular labour2_more labour3_what labour3_average labour3_good labour3_bad labour3_regular business_what business_average business_good business_bad business_regular remit_people remit_average remit_good remit_bad remit_regular in_kind_average in_kind_regular pension_average pension_regular fin_assist_average fin_assist_regular sen_assist_average sen_assist_regular support_average support_good support_bad support_regular other_inc_what other_inc_average other_inc_good other_inc_bad other_inc_regular other_inc2 other_inc2_average other_inc2_good other_inc2_bad other_inc2_regular other_inc3 ymonth meals_12_months meals savings debts debtsource debtsourcespec house_own house_length house_width land_own roof_nipa roof_bamboo roof_wood roof_cement roof_iron roof_stone roof_makeshift roof_hardiflex roof_plywood roof_tiles roof_other walls_nipa walls_bamboo walls_wood walls_cement walls_iron walls_stone walls_makeshift walls_hardiflex walls_plywood walls_tiles walls_other floor_nipa floor_bamboo floor_wood floor_cement floor_iron floor_stone floor_makeshift floor_hardiflex floor_plywood floor_tiles floor_other material_other radio television cable phone computer laptop tablet wifi washing_mashine rice_cooker fridge freezer electric_fan ac stove solar_power generator car motor_cycle tricycle bicycle tractor motorized_boat unmotorized_boat agri_mat brgy_always brgy_years brgy_before move_family move_hazards move_conflicts move_job move_other_what brgy_home ///
/*G: Relation to groups*/ no_groups org1_type org1_othspec org1_name org1_pos org1_pos_name org1_engage org2_type org2_othspec org2_name org2_pos org2_pos_name org2_engage org3_type org3_othspec org3_name org3_pos org3_pos_name org3_engage org4_type org4_othspec org4_name org4_pos org4_pos_name org4_engage org5_type org5_othspec org5_name org5_pos org5_pos_name org5_engage a3gov a3prov a3mun a3cap a3kaga a3brgy a3fish a3ngo a3farmc a3commit a3assoc a3church a3gov2 a3prov2 a3mun2 a3cap2 a3kaga2 a3brgy2 a3fish2 a3ngo2 a3farmc2 a3commit2 a3assoc2 a3church2 a3gov3 a3prov3 a3mun3 a3cap3 a3kaga3 a3rela3 a3friend3 a3fish3 a3neigh3 a3ngo3 a3farmc3 a3commit3 a3assoc3 a3church3 a3bank3 a3insurance3 a3gov4 a3prov4 a3mun4 a3cap4 a3kaga4 a3rela4 a3friend4 a3fish4 a3neigh4 a3ngo4 a3farmc4 a3commit4 a3assoc4 a3church4 a3bank4 a3insurance4 vote_brgy vote_mun vote_prov vote_nat a17migr a17migrr ///
/*Vignette*/ vignette v_behave v_report v_sanctions v_appropriate ///
/*Experiment questions*/ exp_rule_area exp_rule_method exp_rule_monitoring exp_rule_sanction exp_decision exp_cdp1 exp_cdp2 exp_cdp3 exp_cdp4 exp_cdp5  exp_cdp6 exp_cdp7 exp_cdp8 exp_cdp9 exp_cdp10 exp_cdp11 exp_cdp13 exp_cdp14 exp_cdp15 exp_cdp16 exp_cdp17 exp_cdp18 exp_fun exp_easy exp_interesting exp_frustrating exp_difficult exp_confusing exp_boring exp_tiring exp_other exp_know_others exp_satisfied exp_understand exp_attention exp_decision_others exp_realism_p1 exp_realism_p2 exp_realism_p3 ///
/*B: Fishing*/ fishing mpa_self fishing_main_occ fishery fisherygood fisherybad fishing_years fishing_parents fishing_6 fishing_12 fishing_17 fishing_60 fishing_99 own_net own_spear_gun own_hook own_unmotor_boat own_motor_boat own_other own_nets_no net1_mesh_size net1_purpose net1_length net1_number net2_mesh_size net2_purpose net2_length net2_number net3_mesh_size net3_purpose net3_length net3_number net4_mesh_size net4_purpose net4_length net4_number net5_mesh_size net5_purpose net5_length net5_number /*f1mesh*/ use_net use_spear_gun use_hook  use_other f1net net1_mesh_size net1_purpose net1_length net1_number net2_mesh_size net2_purpose net2_length net2_number net3_mesh_size net3_purpose net3_length net3_number net4_mesh_size net4_purpose net4_length net4_number net5_mesh_size net5_purpose net5_length net5_number f1spear f1hook  f1other f2group f2num f2same f2self f2othfish f2buy f2family f2coop f2other high_january high_february high_march high_april high_may high_june high_july high_august high_september high_october high_november high_december high_fish high_fish_exclusive high_tuna high_balanchong high_bangus high_bugoang high_bulaw high_crab high_maya high_pisugo high_tuloy high_ubakan hith_other high_none high_other1 high_other2 high_other3 high_other4 high_other5 high_tuna_kg high_balanchong_kg high_bangus_kg high_bugoang_kg high_bulaw_kg high_crab_kg high_maya_kg high_pisugo_kg high_tuloy_kg high_ubakan_kg high_other1_kg high_other2_kg high_other3_kg high_other4_kg high_other5_kg a5b a5n f3corals f3reef_fish f3large_fish f3mangroves f3seaweed f3other_diminish f3other_same f3other_recover f3why f4why f5corr f5law f5monit f5monits f5indu f5rec f5state f5many f5zone f5poll f5org f5rules f5price f5alt f5tec f5disp f5togh f5steal f5viol f5credit f5uncert f5rulbaran f5rulnonbaran f6area f6areag f6areac f6areap f6cyan f6cyang f6cyanc f6cyanp f6dynam f6dynamg f6dynamc f6dynamp f6mesh f6meshs f6meshg f6meshc f6meshp f6season f6seasong f6seasonc f6seasonp f6species f6speciesg f6speciesc f6speciesp f6oth f6othspec f6othg f6othc f6othp f6oth2 f6othspec2 f6othg2 f6othc2 f6othp2 f6oth3 f7enf f7compl f7auth f7bfarmc f7fish f7mpa f7bantay_dagat f7othspec f7othrate f11incr f11stock f11alt f11enf f11notake mpa_council_part mpa_counil_lead mpa_counil_lead_which mpa_counil_meet mpa_counil_meet_other mpa_council_meet_attend mpa_council_fee mpa_council_engage mpa_council_term mpa_council_rule mpa_council_decisions mpa_council_enforced mpa_council_monitoring mpa_council_sanctions mpa_cdp1_1 mpa_cdp1_2 mpa_cdp1_3 mpa_cdp1_4 mpa_cdp2_1 mpa_cdp2_2 mpa_cdp2_3 mpa_cdp3_1 mpa_cdp3_2 mpa_cdp4 mpa_cdp5_1 mpa_cdp5_2 mpa_cdp5_3 mpa_cdp6_1 mpa_cdp6_2 mpa_cdp6_3 mpa_cdp7_1 mpa_cdp7_2 mpa_cdp7_3 mpa_cdp8_1 mpa_cdp8_2 ///
/*Life-Ladder*/ ladder_life_now ladder_life_future ladder_life_aspiration ladder_econ_now ladder_econ_years ladder_econ_before ladder_econ_before_years ladder_econ_max  ladder_econ_min ladder_econ_future  ladder_econ_aspiration econ_driver_job econ_driver_work econ_driver_city econ_driver_abroad econ_driver_network econ_driver_support econ_driver_god econ_driver_nothing econ_driver_risks econ_driver_edu econ_driver_skills econ_driver_born econ_driver_fair econ_driver_reckless econ_driver_none econ_driver_other econ_barrier_job econ_barrier_move econ_barrier_network econ_barrier_support econ_barrier_hazard econ_barrier_health econ_barrier_expenses econ_barrier_abilities econ_barrier_perseverance econ_barrier_badluck econ_barrier_family econ_barrier_fair econ_barrier_egoistic econ_barrier_none econ_barrier_other econ_aspiration econ_knowledge econ_agency1 econ_agency2 econ_agency3 econ_agency7 econ_agency8 ///
/*Life events*/ mle1_type mle1_type_other mle1_year mle2_type mle2_type_other mle2_year mle3_type mle3_type_other mle3_year sle1_type sle1_type_other sle1_year sle2_type sle2_type_other sle2_year sle3_type sle3_type_other sle3_year le_disaster_risk le_disaster_worries le_disaster_solidarity le_disaster_prepare le_disaster_risk le_disaster_worries le_disaster_solidarity le_disaster_prepare le_disaster_council mle1_effect mle2_effect mle3_effect sle1_effect sle2_effect sle3_effect ///
/*Yolanda*/ yolanda_affected yolanda_rec_econ yolanda_rec_emot yolanda_trauma1 yolanda_trauma2 yolanda_trauma3 yolanda_trauma4 yolanda_trauma5 yolanda_trauma6 yolanda_trauma7 ///
/*Fears,Experience, and Emergency situations*/ fear_disaster_business fear_weather_belongings fear_weather_business fear_fire fear_job fear_health fear_death fear_illness_others fear_theft fear_pandemic fear_none fear_other1 fear_other2 occur_disaster_belongings occur_disaster_business occur_weather_belongings occur_weather_business occur_fire occur_job occur_health occur_death occur_illness_others occur_theft occur_pandemic occur_none occur_other1 last_emerg  last_emerg_other last_emerg_year last_emerg_month  last_emerg_village emerg_loan emerg_gift emerg_help emerg_savings emerg_insurance emerg_assets emerg_assistance emerg_work_more emerg_consume_less emerg_none emerg_other ///
/*Climate change experience & expectations*/ cc_severity cc_adapt adapt_house adapt_land adapt_store adapt_other no_adapt_proteced no_adapt_severity no_adapt_resources no_adapt_knowhow no_adapt_move no_adapt_move_anyways no_adapt_dk no_adapt_other cc_uncertain cc_agency ///
/*Solidarity prediction*/ particip_2016_self soli_remember  soli_give_general soli_give_lessa soli_give_morea soli_give_yourv ///
/*Personality*/ risk patient recip_pos recip_neg altruism a1trust commwork_2022 a1opti a2goss a2adv a2admit a2preach a2even a2ins a2smash a2return a2idea a2hurt ///
comment time_consent time_a time_exp time_v time_b time_c time_d time_e time_g time_t time_h time_network time_sum



keep ///
/*setup*/ date prov munic village population mpa households eyedis intens particip_no year assist consent particip_no sample treat ///
/*A: Socioeconomics*/ name phone_no age gender hh_head hh_head_name status educ educ_grade hh_size_total hh_size age6 age12 age1317 age1860 age60 inc_labour inc_business inc_remittance inc_pension inc_fin_assist inc_sen_assist inc_uct inc_in_kind inc_support inc_other inc_none labour_what labour_average labour_good labour_bad labour_regular labour_more labour2_what labour2_average labour2_good labour2_bad labour2_regular labour2_more labour3_what labour3_average labour3_good labour3_bad labour3_regular business_what business_average business_good business_bad business_regular remit_people remit_average remit_good remit_bad remit_regular in_kind_average in_kind_regular pension_average pension_regular fin_assist_average fin_assist_regular sen_assist_average sen_assist_regular support_average support_good support_bad support_regular other_inc_what other_inc_average other_inc_good other_inc_bad other_inc_regular other_inc2 other_inc2_average other_inc2_good other_inc2_bad other_inc2_regular other_inc3 ymonth meals_12_months meals savings debts debtsource debtsourcespec house_own house_length house_width land_own roof_nipa roof_bamboo roof_wood roof_cement roof_iron roof_stone roof_makeshift roof_hardiflex roof_plywood roof_tiles roof_other walls_nipa walls_bamboo walls_wood walls_cement walls_iron walls_stone walls_makeshift walls_hardiflex walls_plywood walls_tiles walls_other floor_nipa floor_bamboo floor_wood floor_cement floor_iron floor_stone floor_makeshift floor_hardiflex floor_plywood floor_tiles floor_other material_other radio television cable phone computer laptop tablet wifi washing_mashine rice_cooker fridge freezer electric_fan ac stove solar_power generator car motor_cycle tricycle bicycle tractor motorized_boat unmotorized_boat agri_mat brgy_always brgy_years brgy_before move_family move_hazards move_conflicts move_job move_other_what brgy_home ///
/*G: Relation to groups*/ no_groups org1_type org1_othspec org1_name org1_pos org1_pos_name org1_engage org2_type org2_othspec org2_name org2_pos org2_pos_name org2_engage org3_type org3_othspec org3_name org3_pos org3_pos_name org3_engage org4_type org4_othspec org4_name org4_pos org4_pos_name org4_engage org5_type org5_othspec org5_name org5_pos org5_pos_name org5_engage a3gov a3prov a3mun a3cap a3kaga a3brgy a3fish a3ngo a3farmc a3commit a3assoc a3church a3gov2 a3prov2 a3mun2 a3cap2 a3kaga2 a3brgy2 a3fish2 a3ngo2 a3farmc2 a3commit2 a3assoc2 a3church2 a3gov3 a3prov3 a3mun3 a3cap3 a3kaga3 a3rela3 a3friend3 a3fish3 a3neigh3 a3ngo3 a3farmc3 a3commit3 a3assoc3 a3church3 a3bank3 a3insurance3 a3gov4 a3prov4 a3mun4 a3cap4 a3kaga4 a3rela4 a3friend4 a3fish4 a3neigh4 a3ngo4 a3farmc4 a3commit4 a3assoc4 a3church4 a3bank4 a3insurance4 vote_brgy vote_mun vote_prov vote_nat a17migr a17migrr ///
/*Vignette*/ vignette v_behave v_report v_sanctions v_appropriate ///
/*Experiment questions*/ exp_rule_area exp_rule_method exp_rule_monitoring exp_rule_sanction exp_decision cdp exp_cdp1 exp_cdp2 exp_cdp3 exp_cdp4 exp_cdp5  exp_cdp6 exp_cdp7 exp_cdp8 exp_cdp9 exp_cdp10 exp_cdp11 exp_cdp13 exp_cdp14 exp_cdp15 exp_cdp16 exp_cdp17 exp_cdp18 exp_fun exp_easy exp_interesting exp_frustrating exp_difficult exp_confusing exp_boring exp_tiring exp_other exp_know_others exp_satisfied exp_understand exp_attention exp_decision_others exp_realism_p1 exp_realism_p2 exp_realism_p3 ///
/*B: Fishing*/ fishing mpa_self fishing_main_occ fishery fisherygood fisherybad fishing_years fishing_parents fishing_6 fishing_12 fishing_17 fishing_60 fishing_99 own_net own_spear_gun own_hook own_unmotor_boat own_motor_boat own_other own_nets_no net1_mesh_size net1_purpose net1_length net1_number net2_mesh_size net2_purpose net2_length net2_number net3_mesh_size net3_purpose net3_length net3_number net4_mesh_size net4_purpose net4_length net4_number net5_mesh_size net5_purpose net5_length net5_number /*f1mesh*/ use_net use_spear_gun use_hook  use_other f1net net1_mesh_size net1_purpose net1_length net1_number net2_mesh_size net2_purpose net2_length net2_number net3_mesh_size net3_purpose net3_length net3_number net4_mesh_size net4_purpose net4_length net4_number net5_mesh_size net5_purpose net5_length net5_number f1spear f1hook  f1other f2group f2num f2same f2self f2othfish f2buy f2family f2coop f2other high_january high_february high_march high_april high_may high_june high_july high_august high_september high_october high_november high_december high_fish high_fish_exclusive high_tuna high_balanchong high_bangus high_bugoang high_bulaw high_crab high_maya high_pisugo high_tuloy high_ubakan hith_other high_none high_other1 high_other2 high_other3 high_other4 high_other5 high_tuna_kg high_balanchong_kg high_bangus_kg high_bugoang_kg high_bulaw_kg high_crab_kg high_maya_kg high_pisugo_kg high_tuloy_kg high_ubakan_kg high_other1_kg high_other2_kg high_other3_kg high_other4_kg high_other5_kg a5b a5n f3corals f3reef_fish f3large_fish f3mangroves f3seaweed f3other_diminish f3other_same f3other_recover f3why f4why f5corr f5law f5monit f5monits f5indu f5rec f5state f5many f5zone f5poll f5org f5rules f5price f5alt f5tec f5disp f5togh f5steal f5viol f5credit f5uncert f5rulbaran f5rulnonbaran f6area f6areag f6areac f6areap f6cyan f6cyang f6cyanc f6cyanp f6dynam f6dynamg f6dynamc f6dynamp f6mesh f6meshs f6meshg f6meshc f6meshp f6season f6seasong f6seasonc f6seasonp f6species f6speciesg f6speciesc f6speciesp f6oth f6othspec f6othg f6othc f6othp f6oth2 f6othspec2 f6othg2 f6othc2 f6othp2 f6oth3 f7enf f7compl f7auth f7bfarmc f7fish f7mpa f7bantay_dagat f7othspec f7othrate f11incr f11stock f11alt f11enf f11notake mpa_council_part mpa_counil_lead mpa_counil_lead_which mpa_counil_meet mpa_counil_meet_other mpa_council_meet_attend mpa_council_fee mpa_council_engage mpa_council_term mpa_council_rule mpa_council_decisions mpa_council_enforced mpa_council_monitoring mpa_council_sanctions mpa_cdp1_1 mpa_cdp1_2 mpa_cdp1_3 mpa_cdp1_4 mpa_cdp2_1 mpa_cdp2_2 mpa_cdp2_3 mpa_cdp3_1 mpa_cdp3_2 mpa_cdp4 mpa_cdp5_1 mpa_cdp5_2 mpa_cdp5_3 mpa_cdp6_1 mpa_cdp6_2 mpa_cdp6_3 mpa_cdp7_1 mpa_cdp7_2 mpa_cdp7_3 mpa_cdp8_1 mpa_cdp8_2 ///
/*Life-Ladder*/ ladder_life_now ladder_life_future ladder_life_aspiration ladder_econ_now ladder_econ_years ladder_econ_before ladder_econ_before_years ladder_econ_max  ladder_econ_min ladder_econ_future  ladder_econ_aspiration econ_driver_job econ_driver_work econ_driver_city econ_driver_abroad econ_driver_network econ_driver_support econ_driver_god econ_driver_nothing econ_driver_risks econ_driver_edu econ_driver_skills econ_driver_born econ_driver_fair econ_driver_reckless econ_driver_none econ_driver_other econ_barrier_job econ_barrier_move econ_barrier_network econ_barrier_support econ_barrier_hazard econ_barrier_health econ_barrier_expenses econ_barrier_abilities econ_barrier_perseverance econ_barrier_badluck econ_barrier_family econ_barrier_fair econ_barrier_egoistic econ_barrier_none econ_barrier_other econ_aspiration econ_knowledge econ_agency1 econ_agency2 econ_agency3 econ_agency7 econ_agency8 ///
/*Life events*/ mle1_type mle1_type_other mle1_year mle2_type mle2_type_other mle2_year mle3_type mle3_type_other mle3_year sle1_type sle1_type_other sle1_year sle2_type sle2_type_other sle2_year sle3_type sle3_type_other sle3_year le_disaster_risk le_disaster_worries le_disaster_solidarity le_disaster_prepare le_disaster_risk le_disaster_worries le_disaster_solidarity le_disaster_prepare le_disaster_council mle1_effect mle2_effect mle3_effect sle1_effect sle2_effect sle3_effect ///
/*Yolanda*/ yolanda_affected yolanda_rec_econ yolanda_rec_emot yolanda_trauma1 yolanda_trauma2 yolanda_trauma3 yolanda_trauma4 yolanda_trauma5 yolanda_trauma6 yolanda_trauma7 ///
/*Fears,Experience, and Emergency situations*/ fear_disaster_business fear_weather_belongings fear_weather_business fear_fire fear_job fear_health fear_death fear_illness_others fear_theft fear_pandemic fear_none fear_other1 fear_other2 occur_disaster_belongings occur_disaster_business occur_weather_belongings occur_weather_business occur_fire occur_job occur_health occur_death occur_illness_others occur_theft occur_pandemic occur_none occur_other1 last_emerg  last_emerg_other last_emerg_year last_emerg_month  last_emerg_village emerg_loan emerg_gift emerg_help emerg_savings emerg_insurance emerg_assets emerg_assistance emerg_work_more emerg_consume_less emerg_none emerg_other ///
/*Climate change experience & expectations*/ cc_severity cc_adapt adapt_house adapt_land adapt_store adapt_other no_adapt_proteced no_adapt_severity no_adapt_resources no_adapt_knowhow no_adapt_move no_adapt_move_anyways no_adapt_dk no_adapt_other cc_uncertain cc_agency ///
/*Solidarity prediction*/ particip_2016_self soli_remember  soli_give_general soli_give_lessa soli_give_morea soli_give_yourv ///
/*Personality*/ risk patient recip_pos recip_neg altruism a1trust commwork_2022 a1opti a2goss a2adv a2admit a2preach a2even a2ins a2smash a2return a2idea a2hurt ///
comment time_consent time_a time_exp time_v time_b time_c time_d time_e time_g time_t time_h time_network time_sum



*delete intermediate .dta files
erase "$working_ANALYSIS\data\raw\Survey\1_-_Pre-Exp-Consent-1 - Pre-Exp-Consent.dta"
erase "$working_ANALYSIS\data\raw\Survey\2_-_Post-Exp-Survey-2 - Post-Exp-Survey.dta"
erase "$working_ANALYSIS\data\raw\Survey\experiment_import.dta"
erase "$working_ANALYSIS\data\raw\Survey\groups_pre_exp.dta"
erase "$working_ANALYSIS\data\raw\Survey\groups_pre_exp_cap.dta"
erase "$working_ANALYSIS\data\raw\Survey\groups_hh_survey.dta"
erase "$working_ANALYSIS\data\raw\Survey\groups_hh_survey_cap.dta"
erase "$working_ANALYSIS\data\raw\Survey\nets_hh_survey.dta"
erase "$working_ANALYSIS\data\raw\Survey\experiment_complete.dta"
erase "$working_ANALYSIS\data\raw\Survey\Phi_22_import.dta"
erase "$working_ANALYSIS\data\raw\Survey\Survey_phi_2022_clean1.dta"
erase "$working_ANALYSIS\data\raw\Survey\village_level_data.dta"
erase "$working_ANALYSIS\data\raw\Survey\nets_exp.dta"






*===========================================================================
* De-identification (deposit): drop direct identifiers before saving.
* Removed: respondent name, phone number, household-head name, and the names
* and position titles of organizations the respondent belongs to. These are
* direct identifiers and are not used in any analysis (verified across 03-06).
* Enumerator names are already anonymized to S01-S11 earlier in this script.
* cap drop keeps the step idempotent if a variable is already absent.
*===========================================================================
cap drop name
cap drop phone_no
cap drop hh_head_name
cap drop org1_name org2_name org3_name org4_name org5_name
cap drop org1_pos_name org2_pos_name org3_pos_name org4_pos_name org5_pos_name

* Also drop ALL open-ended free-text string fields ("...please specify",
* comments, occupation/gear write-ins, etc.): respondents occasionally typed
* names or phone numbers into these, and none are used in any analysis. Keep
* only geographic fields and the anonymized enumerator code (assist).
* Whitelist-based so any free-text field is caught regardless of its name.
ds, has(type string)
local _strs `r(varlist)'
local _keepstr prov munic village municipality province region country assist
local _dropstr : list _strs - _keepstr
if "`_dropstr'" != "" drop `_dropstr'

*-------
* Sort & Save
*-----
sort date sample particip_no
save "$working_ANALYSIS\processed\survey_clean.dta", replace


*===========================================================================
* Longitudinal panel cleaning (PHI_Panel_12_16_22) — produces panel_clean.dta
* Consolidated from 04_main_analysis.do (2026-05-07).
* This block creates the survey-derived variables consumed by the
* longitudinal-panel analysis section in 04 (rule compliance, monitoring
* problems, MPA-council outcomes, etc.).
*===========================================================================

use "$working_ANALYSIS\data\clean\PHI_Panel_12_16_22.dta", clear

* Control covariates (binary recodes from raw survey items)
cap gen married = 0
cap replace married = 1 if status==2
cap gen only_elementary = 0
cap replace only_elementary = 1 if educ == 1

* Monitoring-problem composite (Cronbach's alpha across f5monit + f5monits)
* and 0-100 normalised version
cap alpha f5monit f5monits, gen(monitoring_issue)
cap summarize monitoring_issue, meanonly
cap gen monitoring_issue_norm = (monitoring_issue - r(min)) / (r(max) - r(min)) * 100
cap lab var monitoring_issue_norm "Monitoring is problematic"

* Survey-item agreement labels (used by f11* items in the panel analysis)
cap lab def agree_lbl 1 "Strongly Disagree" 2 "Disagree" 3 "Neither" 4 "Agree" 5 "Strongly Agree", replace
foreach x of varlist f11incr f11stock f11alt f11enf f11notake {
    cap lab val `x' agree_lbl
}

* Monitoring-problem indicators (Likert items >= 4 = problem; missing if both raw items missing)

cap gen monitoring_failure = 0
cap replace monitoring_failure = 1 if f5monit >= 4 | f5monits >= 4
cap replace monitoring_failure = . if f5monit == . | f5monits == .
cap lab var monitoring_failure "Lack of monitoring is an important problem."

cap gen lack_rules = 0
cap replace lack_rules = 1 if f5law >= 4 | f5law >= 4
cap replace lack_rules = . if f5law == . | f5law == .
cap replace lack_rules = lack_rules * 100
cap lab var lack_rules "Lack of rules is an important problem."

* MPA council outcomes (rule revision history; village-level)
cap replace mpa_council_rule = . if mpa_council_rule == .d
cap gen rule_change = 0 if year==2022 & mpa==1
cap replace rule_change = 1 if mpa_council_rule != .
cap replace rule_change = 100 * rule_change
cap lab var rule_change "MPA rules were changed in the past 20 years (0/1)"

cap gen rule_persistence = 100 - rule_change
cap lab var rule_persistence "MPA rules never changed (0/1)"

* Compliance items
cap lab var f6areap    "Area Restriction Compliance"
cap lab var f6seasonp  "Seasonal Restriction Compliance"
cap lab var f6speciesp "Species Restriction Compliance"

* Recode 2/3 -> 0 for council enforcement / monitoring / sanctions outcomes
cap replace mpa_council_enforced   = 0 if mpa_council_enforced==2  | mpa_council_enforced==3
cap replace mpa_council_monitoring = 0 if mpa_council_monitoring==2 | mpa_council_monitoring==3
cap replace mpa_council_sanctions  = 0 if mpa_council_sanctions==2  | mpa_council_sanctions==3

* MPA villages (treat missing as non-MPA)
cap replace mpa = 0 if mpa == .
cap lab var mpa "MPA"

* Scale share-style variables to percentages
foreach x of varlist mpa_council_enforced mpa_council_monitoring mpa_council_sanctions {
    cap replace `x' = 100 * `x'
}

* Village-level binary classification at 0.8 council-share threshold (after scaling -> 80)
cap gen village_rules = 0 if mpa_council_enforced < 80
cap replace village_rules = 1 if mpa_council_enforced >= 80
cap replace village_rules = . if mpa_council_enforced == .

cap gen village_monitoring = 0 if mpa_council_monitoring < 80
cap replace village_monitoring = 1 if mpa_council_monitoring >= 80
cap replace village_monitoring = . if mpa_council_monitoring == .

cap gen village_sanctions = 0 if mpa_council_sanctions < 80
cap replace village_sanctions = 1 if mpa_council_sanctions >= 80
cap replace village_sanctions = . if mpa_council_sanctions == .

*===========================================================================
* De-identification (deposit): drop direct identifiers from the panel before
* saving. The longitudinal panel input is also de-identified at source by
* 00_deidentify.do; this block is a defensive backstop so panel_clean is
* never written with identifiers even if run on a non-de-identified input.
* Includes social-network and reference person names (f8name*, a14partn*,
* a14ref*), interviewer name (interv), and the panel name field (name_panel).
* None are used in any analysis (verified across 04-06).
*===========================================================================
cap drop name phone_no hh_head_name name_panel interv
cap drop org1_name org2_name org3_name org4_name org5_name
cap drop org1_pos_name org2_pos_name org3_pos_name org4_pos_name org5_pos_name
cap drop f8name1 f8name2 f8name3 f8name4 f8name5
cap drop a14partn a14partn1 a14ref a14ref1 a14ref2 a14ref3

* Drop ALL open-ended free-text string fields (see the survey block above for
* rationale); keep only geographic fields + the anonymized enumerator code.
ds, has(type string)
local _strs `r(varlist)'
local _keepstr prov munic village municipality province region country assist
local _dropstr : list _strs - _keepstr
if "`_dropstr'" != "" drop `_dropstr'

compress
save "$working_ANALYSIS\processed\panel_clean.dta", replace



** EOF