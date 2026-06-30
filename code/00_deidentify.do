*-------------------------------------------------------------------------------------------------------
* 00_deidentify.do
*-------------------------------------------------------------------------------------------------------
*   ONE-TIME de-identification of the pre-built input datasets that ship with
*   the replication package. Run once by the authors before deposit; it is NOT
*   part of the standard run.do pipeline (replicators receive already
*   de-identified inputs and never need to run this).
*
*   What it does:
*     - PHI_Panel_12_16_22.dta : drops direct identifiers (respondent / household-
*       head / organization / social-network / reference / interviewer names and
*       phone numbers) in place. None are used in any analysis.
*
*   What it checks but does NOT change (inspected; no direct identifiers found):
*     - fishery_game_raw.dta : only oTree admin hashes (participantcode,
*       sessioncode), behavioral histories, and village. No names or phone numbers.
*     - quiz.dta             : village + quiz answer items (q1-q4). No identifiers.
*
*   The survey datasets (survey_clean.dta) are de-identified inside
*   01_clean_survey.do at the point they are written; the raw survey workbooks
*   that contain identifiers are NOT deposited (restricted, available from the
*   authors under the IRB protocol).
*
*   The identified originals are backed up outside the package, in
*   _CONFIDENTIAL_originals_DO_NOT_UPLOAD/ at the project root, and are never
*   deposited.
*
*   Entry point: run from the replication_package/ directory after the originals
*   have been backed up.  cap drop keeps every step idempotent.
*-------------------------------------------------------------------------------------------------------

clear
set more off
global working_ANALYSIS: pwd

di as txt "De-identifying data/clean/PHI_Panel_12_16_22.dta ..."
use "$working_ANALYSIS/data/clean/PHI_Panel_12_16_22.dta", clear

* Direct identifiers (names + phone)
cap drop name phone_no hh_head_name name_panel interv
cap drop org1_name org2_name org3_name org4_name org5_name
cap drop org1_pos_name org2_pos_name org3_pos_name org4_pos_name org5_pos_name
* Third-party names (social network, partners, references)
cap drop f8name1 f8name2 f8name3 f8name4 f8name5
cap drop a14partn a14partn1 a14ref a14ref1 a14ref2 a14ref3

* Drop ALL open-ended free-text string fields (comments, "...please specify",
* write-ins): respondents occasionally typed names or phone numbers into these,
* and none are used in any analysis. Keep only geographic fields + the
* anonymized enumerator code (assist).
ds, has(type string)
local _strs `r(varlist)'
local _keepstr prov munic village municipality province region country assist
local _dropstr : list _strs - _keepstr
if "`_dropstr'" != "" drop `_dropstr'

compress
save "$working_ANALYSIS/data/clean/PHI_Panel_12_16_22.dta", replace
di as result "PHI_Panel_12_16_22.dta de-identified and re-saved."

di as txt "fishery_game_raw.dta and quiz.dta inspected: no direct identifiers; left unchanged."
di "DEID_DONE"
