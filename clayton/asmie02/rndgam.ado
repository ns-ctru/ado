*!version 1.0.0  1993 Joseph Hilbe, Walter Linde-Zwirble        (sg44: STB-28)
* gamma distribution random number generator: rejection method
* Example: rndgam 1000 4 2  [set obs 1000; 4 = shape; 2 = scale]

program define rndgam
  version 3.1
  cap drop xg
  qui  {
    local cases `1'
    set obs `cases'
    mac shift
    local ia `1'                 /* shape parameter */
    mac shift
    local theta `1'              /* scale parameter */
    noi di in gr "( Generating " _c
    if `ia'<1 { error }
    if (`ia'<6 & `ia'==int(`ia')) {   /* if shape 1-5 */
       tempvar x
       gen `x' = 1.0
       local i = 1
       while `i'<=`ia'  {
          replace `x'=`x'*uniform()
          local i = `i'+1
       noi di in gr "." _c
       }
       replace `x' = -log(`x')
    }
    else {   
       tempvar xr e ran1 ran2 ds ts sum1 y x
       local am = `ia'-1
       local s = sqrt(2.0*`am'+1.0)
       gen `x' = 1.0
       gen `xr' = -1.0
       gen `e'  = -1.0
       gen `ran1'= uniform()
       gen `ran2'= uniform()
       gen `ds'= 1
       gen `ts'= 1
       gen `y' = -1
       egen `sum1' = sum(`ds')
       while `sum1'>0   {
          replace `y'=sin(_pi*`ran1')/cos(-_pi*`ran1')
          replace `xr'=`s'*`y' + `am' if (`ds'==1)
          replace `ts'=0 if (`xr' <= 0 & `ds'==1)
          #delimit ;
          replace `e' = (1.0+`y'*`y')*
             (exp(`am'*log(`xr'/`am')-(`s'*`y'))) if (`ds'==1 & `ts'==1);
          #delimit cr
          replace `ds'=0 if (`e' >= `ran2' & `ds'==1 & `ts'==1)
          replace `ran1'= uniform()
          replace `ran2'= uniform()
          replace `e' = -1
          replace `ts' = 1
          drop `sum1'
          egen `sum1' = sum(`ds')
          noi di in gr "." _c
       }
       replace `x' = `xr'
  }
  noi di in gr " )"
  gen xg = `x' * `theta'
  noi di in bl "Variable " in ye "xg " in bl "created."
}
end

