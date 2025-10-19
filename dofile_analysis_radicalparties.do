*POPPA analysis**

use "https://github.com/apaparini/RadicalParties_DiD/blob/200f6c6c117f45e8df21989a158dd5c9a14bf648/poppa_integrated.dta" 

decode country, gen(country_name)

keep if inlist(family, 1, 6)

kountry country_name, from(other) stuck
gen ISOcountry= _ISO3N_
keep if inlist(ISOcountry, 56, 203, 642, 703)

sort ISOcountry party_name_original
by ISOcountry party_name_original: gen dup = cond(_N==1,0,_n)

drop if dup>1
drop dup

gen party_name = party_name_original

**ThePopuList 3.0 analysis**

recode populist_startnobl (1900=1989) (2100=2022)
recode farright_startnobl (1900=1989) (2100=2022)
recode farleft_startnobl (1900=1989) (2100=2022)
recode populist_endnobl (1900=1989) (2100=2022)
recode farright_endnobl (1900=1989) (2100=2022)
recode farleft_endnobl (1900=1989) (2100=2022)

keep if (farright == 1 | farleft_bl == 1) & (farright_bl == 0 | farleft_bl == 0)

kountry country, from(other) stuck
gen ISOcountry= _ISO3N_

keep if inlist(ISOcountry, 56, 203, 642, 703)

drop if ISOcountry == 56 & party_name_short == "VB"
drop if ISOcountry == 703 & party_name_short == "L'SNS"

save "D:\Anto\Analysis of Democracy\TIPSA\The PopuList\ThePopuList_controls"

**Merge with my resulting list of banned parties**

import excel "D:\Anto\Analysis of Democracy\TIPSA\banned_parties", sheet("parties") firstrow clear

merge 1:1 ISOcountry party_name using  "D:\Anto\Analysis of Democracy\TIPSA\The PopuList\ThePopuList_controls"

recode ban (. = 0)

keep party_name country_name party_name_english party_name_short farright farleft ISOcountry ban

save "D:\Anto\Analysis of Democracy\TIPSA\controls+banned"

**ïntegrate with the electoral support database**

import excel "D:\Anto\Analysis of Democracy\TIPSA\Paty bans\electoral_support", sheet("results") firstrow clear

kountry country, from(other) stuck
gen ISOcountry= _ISO3N_

merge m:1 ISOcountry party_name_short using "D:\Anto\Analysis of Democracy\TIPSA\controls+banned"

keep if _merge == 3
drop _merge

encode party_name, gen(party_id)

**Define it as panel data**

xtset party_id time

**Create the treatment variable**

gen treatment = 0

**Czech Republic ban
replace treatment = 1 if party_id == 2 & time >= 4

**Belgium ban
replace treatment = 1 if party_id == 18 & time >= 3

**Romania ban
replace treatment = 1 if party_id == 9 & time >= 3

**Slovakia ban
replace treatment = 1 if party_id == 6 & time >= 3

destring vote_number, replace

**Run the regression models**

eststo: reg vote_share treatment
eststo: xtreg vote_share farright if treatment == 1
eststo: reg D.vote_share treatment
eststo: reg D.vote_share treatment i.ISOcountry farright


esttab using partybanned.rtf, replace se r2 ar2  label scalars(rmse) drop(*.ISOcountry)

