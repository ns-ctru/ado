*! version 2.2, 3 Apr 2003, DGC
program define pseudocc 
  version 7.0
  syntax varlist(min=2) , SAVing(string) [  REPlace /*
          */ Ped(varname) Id(varname) MOther(varname) FAther(varname) /*
          */ SEX(varname) AFfect(varname) ACode(numlist) noWARN POrigin PHase/*
          */ EXch ONE THREE  FIrst MVar(string) FVar(string) /* 
          */ Keep(varlist) MGen FGen]
  preserve
  local nv : word count `varlist'
  if mod(`nv',2)!=0 {
    di in red "Number of variables is not even"
    exit
  }
  else {
    local nl = `nv'/2
  }
  /* Check options */
  if `nl'==1 & "`phase'"!="" {
    di "Option {bf:phase} has no effect for one locus"
  }
  if "`three'"!="" {
    if "`one'"!="" {
      di in red "Options {bf:one, three} cannot be specified together"
      exit
    }
  }
  if "`exch'"!="" & "`phase'"=="" {
    di "Option {bf:exch} implies {bf:porigin} option"
    local porigin "porigin"
  }

  /* Variables to be carried over from parents' records */

  if "`fvar'"!="" {
    tokenize "`fvar'", parse(" =")
    while "`1'"!="" {
      if "`2'"=="=" {
        cap confirm var `3'
        if  _rc!=0 {
          di in red "Non-existent paternal variable (`3')"
          exit
        }
        cap confirm new var `1'
        if  _rc!=0 {
          di in red "Illegal new name for paternal variable (`1')"
          exit
        }
        local fvars "`fvars' `1'"
        quietly gen `1'=`3'
        mac shift
        mac shift
        mac shift
      }
      else {
        cap confirm var `1'
        if  _rc!=0 {
          di in red "Non-existent paternal variable (`1')"
          exit
        }
        cap confirm new var F_`1'
        if  _rc!=0 {
          di in red "Illegal new name for maternal variable (F_`1')"
          exit
        }
        local fvars "`fvars' F_`1'"
        quietly gen F_`1'=`1'
        mac shift
      }
    }
  }

  if "`mvar'"!="" {
    tokenize "`mvar'", parse(" =")
    while "`1'"!="" {
      if "`2'"=="=" {
        cap confirm var `3'
        if  _rc!=0 {
          di in red "Non-existent maternal variable (`3')"
          exit
        }
        cap confirm new var `1'
        if  _rc!=0 {
          di in red "Illegal new name for maternal variable (`1')"
          exit
        }
        local mvars "`mvars' `1'"
        quietly gen `1'=`3'
        mac shift
        mac shift
        mac shift
      }
      else {
        cap confirm var `1'
        if  _rc!=0 {
          di in red "Non-existent maternal variable (`1')"
          exit
        }
        cap confirm new var M_`1'
        if  _rc!=0 {
          di in red "Illegal new name for maternal variable (M_`1')"
          exit
        }
        local mvars "`mvars' M_`1'"
        quietly gen M_`1'=`1'
        mac shift
      }
    }
  }

  /* Variables, codes etc. */
  
  unab vars : _all
  tokenize `vars'
  if "`ped'"=="" {
    local ped "`1'"
  }
  if "`ped'"=="" {
    local ped "`1'"
  }
  if "`id'"=="" {
    local id "`2'"
  }
  if "`mother'"=="" {
    local mother "`4'"
  }
  if "`father'"=="" {
    local father "`3'"
  }
  if "`sex'"=="" {
    local sex "`5'"
  }
  if "`affect'"=="" {
    local affect "`6'"
  }
  if "`acode'"=="" {
    local acode 2
  }

  /* New variable names */

  local cc "case"
  local set "set"
  local lstub "_lo_"
  local cstub "_ch_"
  local mstub "_ma_"
  local fstub "_fa_"
  local xstub "_ix_"
  local hstub "_hh_"


  tempvar work swap mid fid cid use

  /* Put genotypes into order --- smallest allele first --- and rename*/

  tokenize  `varlist'
  local i 0

  while "`1'"!="" {
    quietly {
      gen byte `swap' = `1'>`2'
      gen `work' = `1'
      replace `1' = `2' if `swap'
      replace `2' = `work' if `swap'
      drop `swap' `work'
      local i = `i' + 1
      rename `1' `lstub'_`i'_1
      rename `2' `lstub'_`i'_2
    }
    mac shift
    mac shift
  }
                   
  quietly recode `affect' `acode' = 2 * = 1 

  /* Make triads into 1 line */

  keep `ped' `id' `mother' `father' `affect' `lstub'_* `mvars' `fvars' `keep'

  tempfile idord
  sort `ped' `id'
  quietly save "`idord'"

  gen byte `use' = cond(`affect'==2, 1, 0)
  markout `use'  `mother' `father'  
  quietly keep if `use'
  quietly drop `affect' `use'
  di
  di "Total number of affected offspring = " _N
  rename `mother' `mid'
  rename `father' `fid'
  rename `id' `cid'
  renpfix `lstub' `cstub'

  rename `mid' `id'
  sort `ped' `id'
  foreach var of local mvars {
    quietly replace `var'=.
  }
  quietly merge `ped' `id' using "`idord'", update
  quietly drop if _merge==2
  quietly drop _merge `mother' `father'
  noi renpfix `lstub' `mstub'
  rename `id'  `mid'

  rename `fid' `id'
  sort `ped' `id'
  foreach var of local fvars {
    quietly replace `var'=.
  }
  quietly merge `ped' `id' using "`idord'", update
  quietly drop if _merge==2
  quietly drop _merge `mother' `father'
  renpfix `lstub' `fstub'
  rename `id'  `fid'

  rename `cid' `id'
  rename `mid' `mother'
  rename `fid' `father'
  quietly drop `affect'

  tempvar use gtmiss wa imiss 
  tempvar sw00 sw01 sw10 sw11 trmit
  gen byte `use' = 1
  markout `use' `mstub'* `fstub'*
  quietly keep if `use'
  di "Number with both parents fully genotyped = " _N

  /* Check for unknown genotypes and intercrosses */

  quietly {
    gen byte `gtmiss' = 0
    local i 0
    tokenize `varlist'
    while `i'<`nl' {
      local i = `i'+1
      local c1 `cstub'_`i'_1
      local c2 `cstub'_`i'_2
      local m1 `mstub'_`i'_1
      local m2 `mstub'_`i'_2
      local f1 `fstub'_`i'_1
      local f2 `fstub'_`i'_2
      local ix `xstub'_`i'
      local hh `hstub'_`i'

      /* Check for intercross mating, etc */
        
      gen byte `ix' = ((`m1'!=`m2') & (`m1'==`f1') & (`m2'==`f2'))
      gen byte `hh' = ((`m1'==`m2') & (`m1'==`f1') & (`m2'==`f2'))

      /* Check for missing offspring genotype but, if both parents homozygous,
         infer typing */

      gen byte `imiss' = (`c1'==. | `c2'==.) & (`m1'!=`m2' | `f1'!=`f2')
      replace `gtmiss' = 1 if `imiss'
      replace `c1' = `m1' if  `c1'==. | `c2'==.
      replace `c2' = `f1' if  `c1'==. | `c2'==.
      count if `imiss'
      local ndr=r(N)
      if `ndr'>0 & "`warn'"=="" {
        noi di " `ndr' missing genotypes for marker `i'" _continue
        noi di " (`1' `2')"
      }
      
      /* Evaluate possible inheritances */
        
      gen byte `sw00'= (`c1'==`m1' & `c2'==`f1')|(`c2'==`m1' & `c1'==`f1')
      gen byte `sw10'= (`c1'==`m2' & `c2'==`f1')|(`c2'==`m2' & `c1'==`f1')
      gen byte `sw01'= (`c1'==`m1' & `c2'==`f2')|(`c2'==`m1' & `c1'==`f2')
      gen byte `sw11'= (`c1'==`m2' & `c2'==`f2')|(`c2'==`m2' & `c1'==`f2')

      gen byte `trmit' = cond(`sw00',1, /*
                      */ cond(`sw10',2, /*
                       */ cond(`sw01',3, /*
                      */ cond(`sw11',4, 0))))
      replace `use' = 0 if `trmit'==0
      count if `trmit'==0
      local ndr=r(N)
      if `ndr'>0 & "`warn'"==""{
        noi di " `ndr' misinheritances for marker `i'" _continue
        noi di " (`1' `2'). " _continue
        noi di "Pedigree and member codes follow "
        noi li `ped' `id' if `trmit'==0, noobs nohead
      }
      
      /* In parents' genotypes, put transmitted allele first */

      gen `wa' = `m2'
      replace `m2' = `m1' if !mod(`trmit', 2)
      replace `m1' = `wa' if !mod(`trmit', 2)
      replace `wa' = `f2'
      replace `f2' = `f1' if `trmit'>2
      replace `f1' = `wa' if `trmit'>2
      
      drop `sw00' `sw10' `sw01' `sw11' `trmit'  `imiss' `wa' `c1' `c2'
      mac shift
      mac shift
    }

    /* Drop triads that cannot be analysed for one reason or another */
      
    count if `gtmiss'
    local ndr = r(N)
    if `ndr'>0 & "`warn'"=="" {
      noi di " `ndr' triads dropped - missing genotype(s)"
    }
    drop if `gtmiss'
    count if !`use'
    local ndr = r(N)
    if `ndr'>0 & "`warn'"=="" {
      noi di " `ndr' triads dropped - misinheritance"
    }
    keep if `use'
    if "`first'"!="" {
      tempvar if1
      sort `ped' `id'
      by `ped': gen byte `if1' = (_n==1)
      count if !`if1'
      local ndr = r(N)
      if `ndr'>0  & "`warn'"=="" {
        noi di " `ndr' triads dropped - first case restriction"
      }
      drop if !`if1'
      drop `if1'
    }

    drop `use' `gtmiss' 
  }

  /* Generate unique triad identifier */

  quietly gen long `set' = _n

  /* Exchangeable parent option; duplicate triad records and swap parents */

  tempvar pex
  if "`exch'"!="" {
    quietly {
      local oldN = _N
      expand 2
      tempvar work
      quietly {
        gen byte `pex' = (_n > `oldN')
      }
      sort `id' `pex'
      forvalues i = 1/`nl' {
        forvalues j = 1/2 {
          gen `work' = `mstub'_`i'_`j' 
          replace  `mstub'_`i'_`j' = `fstub'_`i'_`j' if `pex'
          replace  `fstub'_`i'_`j' = `work' if `pex'
          drop `work'
        }
      }
    }
  }
  else {
    gen byte `pex' = 0
  }

  /* Copy parental genotypes? */

  if "`mgen'`fgen'"!="" {
    quietly {
      tokenize `varlist'
      forvalues i =1/`nl' {
        if "`mgen'"!="" {
          gen M_`1' = `mstub'_`i'_1
          gen M_`2' = `mstub'_`i'_2
        }
        if "`fgen'"!="" {
          gen F_`1' = `fstub'_`i'_1
          gen F_`2' = `fstub'_`i'_2
        }
        mac shift
        mac shift
      }
    }
  }

  local nset = _N

  /* Expand each triad record to 4 records */

  tempvar mtu ftu
  quietly {
    local mloci
    local floci
    forvalues i = 1/`nl' {
      local mloci "`mloci' `mstub'_`i'_"
      local floci "`floci' `fstub'_`i'_"
    }
    reshape long `mloci', i(`set' `pex' ) j(`mtu')
    reshape long `floci', i(`set' `pex' `mtu') j(`ftu')
  }

  /* Determine whether parental origin and/or phase is known */

  tempvar pou ttuu phu ncontrol 

  quietly {
    gen int `pou' = 0
    gen int `ttuu' = 0
    tokenize `varlist'
    forvalues i = 1/`nl' {
      local ix `xstub'_`i'
      local hh `hstub'_`i'
      gen `1' = `mstub'_`i'_
      gen `2' = `fstub'_`i'_
      replace `pou' = `pou' + 1 if `ix' & (`1'!=`2')
      replace `ttuu' = `ttuu' + 1 if (`ix'|`hh') & (`1'==`2')
      drop `mstub'_`i'_ `fstub'_`i'_ `ix' `hh'
      mac shift
      mac shift
    }
    by `set': gen byte `cc' = (_n==1)
    gen `phu' = (`pou'>1 | (`pou'==1 & `ttuu'<(`nl'-1)))
    by `set': gen byte `ncontrol' = sum((!`phu') & (!`cc'))
    if "`phase'"!="" {
      drop if `phu'
    }
    else if "`porigin'"!="" {
      drop if `pou'>0
    }
    else {
      tempvar frub
      by `set': gen byte `frub' = `phu'[1] | (`ncontrol'[_N]==0)
      drop if (`frub') & (`mtu'!=`ftu')
      drop if (!`frub') & `phu'
      drop `frub'
    }
    if "`three'"!="" {
      if "`exch'"!="" {
        by `set': drop if _N!=8
      }
      else {
        by `set': drop if _N!=4
      }
    }
   
    if "`one'"!="" {
      drop if `mtu'!=`ftu'
    }

    /* List omissions */

    /* Drop sets with no case */
      
    by `set': gen byte `use' = `cc'[1]
    drop if !`use'
    tempvar first
    by `set': gen byte `first' = (_n==1)
    count if `first'
    local ndr = `nset' - r(N)
    if "`warn'"=="" & (`ndr'>0) {
      noi di " `ndr' triads dropped --- no useable case"
    }

    
    drop `use' `first'
    
    /* Drop sets with no controls */
      
    by `set': replace `ncontrol' = _N - 1
    by `set': gen byte `first' = (_n==1)
    by `set': gen byte `use' = (`ncontrol'>0)
    count if `first' & !`use'
    local ndr = r(N)
    if `ndr'>0 & "`warn'"=="" {
      noi di " `ndr' triads dropped --- no useable  pseudocontrols"
    }
    drop if !`use'

    /* Count sets */

    count if `cc'
    local nset = r(N)
    drop `pou' `phu'  `mtu' `ftu' `pex' `use' `first' `ttuu'
  }
  di
  di "Number of case/pseudo-control sets generated = `nset', as follows:"
  label variable `ncontrol' "Number of controls in set"
  table  `ncontrol' if `cc'

  drop `ncontrol'
    
  /* Write case/control file and restore original data */

  di

  save `saving', `replace'
  restore
  end
