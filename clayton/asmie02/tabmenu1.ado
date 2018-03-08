*! Menu to prepare tables
*! Michael Hills 29/7/2002
*! version 3.1.0 (added graph option, removed excess code)

program define tabmenu1
version 7.0
syntax [varlist] [if] [in] [,CLEAR Display]

di

if "`clear'" == "clear" {
    macro drop TA*
    macro drop ta*
}

if "" == "$ta_sca" {global ta_sca 1}
if "" == "$ta_perc" {global ta_perc 100}
if "" == "$ta_pery" {global ta_pery 1000}
if "" == "$ta_mv" {global ta_mv 10}
if "" == "$ta_lev" {global ta_lev $S_level}


global TA_typ "binary metric failure count"
global TA_var "`varlist'"
cap window control, clear

/* response variable */

global TA_out1 "Select response"
global TA_out2 "variable" 
window control static TA_out1 5 5  70 9
window control static TA_out2 5 12 70 9
window control ssimple TA_var 5 22 50 80 ta_res

/* type of response */

global TA_out3 "Select type of"
global TA_out4 "response" 
window control static TA_out3 65 5  50 9
window control static TA_out4 65 12 50 9
window control ssimple TA_typ 65 22 50 80 ta_typ

/* Follow-up time */

global ta_fup1 "Select follow-up time"
global ta_fup2 "if appropriate" 
window control static ta_fup1 125 5  80 9
window control static ta_fup2 125 12 80 9
window control ssimple TA_var 125 22 50 80 ta_fup

/* explanatory variable */

global TA_exp1 "Select explanatory"
global TA_exp2 "variable for rows" 
window control static TA_exp1 5 115  80 9
window control static TA_exp2 5 122 80 9
window control ssimple TA_var 5 132 50 80 ta_exp

/* modifying variable */

global TA_mod1 "Select explanatory"
global TA_mod2 "variable for columns" 
window control static TA_mod1  75 115  80 9
window control static TA_mod2 75 122 80 9
window control ssimple TA_var  75 132 50 80 ta_mod

/* max values before too many for a table */

global TA_mv1 "Maximum no of values a row"
global TA_mv2 "or column variable can have"
window control edit  155 132 30 10 ta_mv
window control static TA_mv1 155 115 100 9
window control static TA_mv2 155 122 100 9


/* exit buttons */

global TA_exit "exit 3000" 
global TA_tab "exit 3002"
window control button "Exit"    200 85 40 10 TA_exit
window control button "Tables"  200 45 40 10 TA_tab

cap window dialog "Variable attributes" . . 260 250

if _rc==3000 {
  exit
}

/* basic error checking */

global ta_exp = ltrim("$ta_exp")
global ta_mod = ltrim("$ta_mod")
global ta_res = ltrim("$ta_res")

if "$ta_res"=="" {
    di as error "No response variable has been specified!"
    exit
}
else {
    cap confirm numeric variable $ta_res
    if _rc==7 {
        di as error "Response variable must be numeric"
        exit
  }
}
if "$ta_typ" == "" {
    di as error "Type of response variable must be selected"
    exit
}
if "$ta_exp"=="" {
    di as error "Explanatory variable must be specified"
    exit
}
if "$ta_res"=="$ta_exp" | "$ta_res"=="$ta_mod" {
    di as error "Variable occurs as both response and explanatory"
    exit
}
if "$ta_mod"=="$ta_exp" {
    di as error "Same variable occurs as both row and column"
    exit
}
qui inspect $ta_exp
if r(N_unique)>$ta_mv {
    di as error "More than $ta_mv values for row variable"
    exit
} 
if "$ta_mod" != "" {
    qui inspect $ta_mod
    if r(N_unique)>$ta_mv {
        di as error "More than $ta_mv values for column variable"
        exit
  } 
}
if "$ta_typ"=="failure" {
    cap assert $ta_res ==0 | $ta_res ==1 | $ta_res==.
    if _rc==9 {
        di as error "Failure response must be coded 0/1"
        exit
    }
}
if "$ta_typ"=="binary" {
    cap assert $ta_res ==0 | $ta_res ==1 | $ta_res==.
    if _rc==9 {
        di as error "Binary response must be coded 0/1"
        exit
    }
    cap assert "$ta_fup" == "" 
    if _rc==9 {
        di as error "Cannot have follow-up time with binary response"
        exit
    } 
}
if "$ta_typ"=="failure" | "$ta_typ"=="count"  {
    cap assert "$ta_fup" != ""
    if _rc==9 {
        di as error "Failure and count responses must have follow-up time"
        exit
    }
}


/* second menu */




window control check " Frequencies" 120 35 80 10 ta_fr
window control check " Confidence intervals/IQR" 120 55 100 10 ta_ci
window control check " Reverse rows and cols" 120 95 80 10 ta_rv
global TA_lev "Level of confidence"
window control static TA_lev 140 75 80 10
window control edit  120 75 15 10 ta_lev
window control check "Graph"     120 115 40 10 ta_gra
window control check "Log scale" 120 135 40 10 ta_log
 
if "$ta_typ"=="binary" {
    global TA_sca1 "The response is binary"
    window control static TA_sca1 10  5 80 10
    window control radbegin "Proportion" 10 35 70 10 ta_sca
    window control radend "Odds" 10 55 70 10 ta_sca
    window control edit 80 35 30 10 ta_perc
    global TA_per "per"
    window control static TA_per 65 36 15 10 
}
if "$ta_typ"=="metric" {
    global TA_sca3 "The response is metric"
    window control static TA_sca3 10  5 80 10
    window control radbegin "Mean" 10 35 70 10 ta_sca
    window control radio "Geometric mean" 10 55 70 10 ta_sca
    window control radend "Median" 10 75 70 10 ta_sca
}
if "$ta_typ"=="failure" {
    global TA_sca4 "The response is failure"
    window control static TA_sca4 10  5 80 10
    global TA_per "Rates per"
    window control static TA_per 10 35 35 10 
    window control edit 70 35 30 10 ta_pery
}
if "$ta_typ"=="count" {
    global TA_sca5 "The response is a count"
    window control static TA_sca5 10  5 80 10
    global TA_per "Rates per"
    window control static TA_per 10 36 40 10 
    window control edit 60 35 30 10 ta_pery
    global ta_sca 1
}

global TA_ok "exit 3001"
global TA_exit "exit 3000" 
window control button "OK" 10 140 30 10 TA_ok
window control button "Exit" 50 140 30 10 TA_exit

cap window dialog "Choosing the summary" 10 10 220 200

if _rc==3000 {
  exit
}

/* displays tabmenu2 command */

if "`display'"=="display" {
    local tabmenu2 "tabmenu2 `if' `in', res($ta_res) typ($ta_typ) row($ta_exp)"
    if "$ta_mod"!="" {local tabmenu2 "`tabmenu2' col($ta_mod)"}
    if "$ta_fup"!="" {local tabmenu2 "`tabmenu2' fup($ta_fup)"}
    if "$ta_typ"=="metric" {
        if $ta_sca==1 {local tabmenu2 "`tabmenu2' summ(mean)"}
        if $ta_sca==2 {local tabmenu2 "`tabmenu2' summ(gmean)"}
        if $ta_sca==3 {local tabmenu2 "`tabmenu2' summ(median)"}
    }
    if "$ta_typ"=="binary" {
        if $ta_sca==1 {local tabmenu2 "`tabmenu2' summ(prop)"}
        if $ta_sca==2 {local tabmenu2 "`tabmenu2' summ(odds)"}
    }
    if "$ta_typ"=="failure" {local tabmenu2 "`tabmenu2' summ(rate)"}
    if $ta_perc!=100 & $ta_sca==1 & "$ta_typ"!="metric"  {local tabmenu2 "`tabmenu2' perc($ta_perc)"}
    if $ta_pery!=1000 & $ta_sca==1 & "$ta_typ"!="metric"  {local tabmenu2 "`tabmenu2' pery($ta_pery)"}
    if $ta_mv!=10 {local tabmenu2 "`tabmenu2' maxval($ta_mv)"}
    if $ta_fr==1 {local tabmenu2 "`tabmenu2' fr"}
    if $ta_ci==1 {local tabmenu2 "`tabmenu2' ci"}
    if $ta_rv==1 {local tabmenu2 "`tabmenu2' rv"}
    if $ta_lev!=95 {local tabmenu2 "`tabmenu2' level($ta_lev)"}
    if $ta_gra==1 {local tabmenu2 "`tabmenu2' graph"}
    if $ta_log==1 {local tabmenu2 "`tabmenu2' log"}
    di
    di as res "`tabmenu2'"
    di
}

_mhtab `if' `in' , level($ta_lev)

end


program define _mhtab
version 7.0
syntax [if] [in] [,Level(integer $S_level)]
tempvar se hi low ci to odds rate iqr contents touse

marksample touse
markout `touse' $ta_res $ta_exp $ta_mod $ta_fup

preserve

di in gr "Response variable is: " in ye "$ta_res" in gr " which is "in ye "$ta_typ"
if "$ta_fup" != "" {
    di in gr "Follow-up time variable is: " in ye "$ta_fup"
}
di in gr "Row variable is: " in ye "$ta_exp "
if "$ta_mod"!="" {
    di in gr "Column variable is: " in ye "$ta_mod " 
}
/*
	Prints number of records used
*/

qui count if `touse'
di as text "Number of records used:    " as result r(N)        

if $ta_ci==1 {
    di as res `level' "%" as text " confidence intervals"
}
local mult = invnorm(`level'*0.005+0.5)

* binary

if "$ta_typ"=="binary" {

* proportions

    if  $ta_sca==1 {
        di in gr _n(1) "Summary using" in ye " proportions"    in gr " per " in ye $ta_perc
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res) replace
        qui gen `odds'=table2/(1-table2)
        qui gen `se' = sqrt(1/(table1*table2)+1/(table1*(1-table2)))
        qui gen `low' = `odds'/exp(`mult'* `se')
        qui gen `hi'    = `odds'*exp(`mult'* `se')
        qui replace `low' = $ta_perc*`low'/(1+`low')
        qui replace `hi'    = $ta_perc*`hi'/(1+`hi')
        qui replace table2=$ta_perc*table2	
    }

* odds

    if $ta_sca==2 {
        di in gr    _n(1) "Summary using" in ye " odds"
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res) replace
        qui gen `odds'=table2/(1-table2)
        qui gen `se' = sqrt(1/(table1*table2)+1/(table1*(1-table2)))
        qui gen `low' = `odds'/exp(`mult'* `se')
        qui gen `hi'    = `odds'*exp(`mult'* `se')
        qui replace table2=`odds'
    }
}

* failure or count

if "$ta_typ"=="failure" | "$ta_typ"=="count" {
        di in gr    _n(1) "Summary using" in ye " rates" in gr " per " in ye    $ta_pery
        qui table $ta_exp $ta_mod if `touse', c(freq sum $ta_res sum $ta_fup) replace
        qui gen `rate' = table2/table3*$ta_pery
        qui gen `se' = sqrt(1/table2)
        qui gen `low' = `rate'/exp(`mult'* `se')
        qui gen `hi'    = `rate'*exp(`mult'* `se')
        qui replace table2 = `rate'
}

if "$ta_typ"=="metric" {
    if $ta_sca==1 {
        di in gr    _n(1) "Summary using" in ye " means"
        qui table $ta_exp $ta_mod    if `touse', c(freq mean $ta_res sd $ta_res) replace
        qui gen `se' = table3/sqrt(table1)
        qui gen `low' = table2 - `mult'*`se'
        qui gen `hi' = table2 + `mult'*`se'
    }
    if $ta_sca==2 {
        di in gr    _n(1) "Summary using" in ye " geometric means"
        qui assert $ta_res > 0
        qui replace $ta_res=ln($ta_res)
        qui table $ta_exp $ta_mod if `touse', c(freq mean $ta_res sd $ta_res) replace
        qui gen `se' = table3/sqrt(table1)
        qui gen `low' = table2 - `mult'*`se'
        qui gen `hi' = table2 + `mult'*`se'
        qui replace table2=exp(table2)
        qui replace `low'=exp(`low')
        qui replace `hi'=exp(`hi')
    }
    if $ta_sca==3 {
        di in gr    _n(1) "Summary using" in ye " medians"
        qui table $ta_exp $ta_mod if `touse', c(freq med $ta_res p25 $ta_res p75 $ta_res) replace
        qui gen `low' = table3
        qui gen `hi' = table4
    }
}
qui gen str1 `to' = "-"
egen `ci' = concat(`low' `to' `hi'), punct(" ") format(%7.2f)
local contents "table2"
sort $ta_mod $ta_exp
if $ta_gra==1 & $ta_log==0 {
graph table2 $ta_exp, sort c(l) xlab ylab l1("response")  by($ta_mod)
}
if $ta_gra==1 & $ta_log==1 {
graph table2 $ta_exp, c(l) xlab ylab l1("response")  ylog by($ta_mod)
}
if $ta_fr==1 { local contents "table1 `contents'"}
if $ta_ci==1 { local contents "`contents' `ci'" }
label var table2 $ta_res
label var `ci' "$ta_lev% CI"
if "$ta_typ"=="binary" & $ta_sca==2 {
    local format "%7.4f"
}
else {
    local format "%7.2f"
}
if $ta_rv==1 {tabdisp $ta_mod $ta_exp, cell(`contents') format(`format') cellwidth(20)}
else { tabdisp $ta_exp $ta_mod, cell(`contents') format(`format') cellwidth(20)}

end
