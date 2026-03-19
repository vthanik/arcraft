/*                                      
| Macro Name:         tu_adchgccfg
|                    
| Macro Version:      2 build 1
|                    
| SAS Version:        9.1
|                    
| Created By:         Spencer Renyard
|                    
| Date:               13Jun2014
|                    
| Macro Purpose:      This unit shall take an input dataset and perform Clinical 
|                     Concern or Change From Baseline flagging for LAB, ECG or Vital 
|                     Signs, in order to create an output dataset. 
|
|                     The unit shall respect (and shall not change the value of) the 
|                     prevailing values of any global macro variables. 
|                    
| Macro Design:       Procedure style.
|                   
| Input Parameters:
|
| Name                Description                                  Default           
| -----------------------------------------------------------------------------------
| DSETIN              Specifies the dataset for which Clinical     (None)            
|                     Concern lab flagging needs to be done.                         
|                     Valid values: valid dataset name                               
|                                                                                    
| DSETOUT             Specifies the name of the output dataset to  (None)            
|                     be created.                                                    
|                     Valid values: valid dataset name                               
|                                                                                    
| CHGORCC             Specifies if the flagging is for clinical    CC                
|                     concer (CC) or change from baseline(CHG)                       
|                     Valid values: CC or CHG                                   
|                                                                                    
| CPDSRNG             Specifies if the range is for Clinical       (None)
|                     Pharmacology range                                             
|                     Valid values: Blank, Y or N                                    
|                                                                                    
| DGCD                If given, the macro will try to get range    (None)           
|                     for given compound identifier first                            
|                     Valid Values: Blank or any string                              
|                                                                                    
| DOMAINCODE          Specifies which test flagging should be      &DOMAIN                
|                     derived: Lab (LB), ECG (EG) or Vital Signs                     
|                     (VS)                                                           
|                     Valid Values:                                                  
|                     LB, EG or VS                                                   
|                                                                                    
| CRITDSET            Specifies the SI dataset which contains the  (None)    
|                     lab flagging criteria information.                             
|                                                                                    
| STUYDYID            If given, the macro will try to get range    (None)
|                     for given study identifier first                               
|                     Valid Values: Blank or any string     
|----------------------------------------------------------------------------------------
| Output: A new output data set &DSETOUT should be created
|----------------------------------------------------------------------------------------
| Global macro variables created: NONE
|----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_chkboundvals
|----------------------------------------------------------------------------------------
| Example:
|      %tu_adchgccfg(dsetin=&lastdset.,
|                    dsetout=&prefix._chg,
|                    chgorcc=CHG,
|                    critdset=&critdset,
|                    dgcd=&dgcd,
|                    studyid=&studyid,
|                    cpdsrng=&cpdsrng
|                    );
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:             Anthony J Cooper 
| Date of Modification:    05-Nov-2014  
| New version number:      1 build 2
| Modification ID:         AJC001
| Reason For Modification: Updates from Source Code Review:
|                          1) Minor efficiency changes
|                          2) Update chkvarsexist variables on DSETIN to match what
|                             the proc sql step uses
|                          3) Update AGE processing so that age_is_used is set correctly
|                             when AGE exists on DSETIN and so that the code runs without
|                             error when AGE does not exist.
|                          4) Update values of A1IND/A2IND to match ADaM metadata.
|
| Modified By:             Spencer Renyard (sr550750) 
| Date of Modification:    14-Nov-2014  
| New version number:      1 build 3
| Modification ID:         SR001
| Reason For Modification: Methods for deriving change from baseline ranges (A2HI/LO)
|                          and flag (A2INDCD/A2IND) updated. 
|
| Modified By:             Spencer Renyard (sr550750) 
| Date of Modification:    25-Nov-2014  
| New version number:      1 build 4
| Modification ID:         SR002
| Reason For Modification: A1INDCD restricted to values H, I, L
|                          A2INDCD restricted to values H, I, L (plus P & R from
|                          tu_adbaseln macro) 
|                           
| Modified By:             Nicola Perry
| Date of Modification:    14-Mar-2018
| New version number:      2 build 1
| Modification ID:         NP001
| Reason For Modification: Include utility macro tu_chkboundvals which will flag
|                          observations where specified value variable (VALUEVAR) is 
|                          deemed to be close to a boundary value (COMPVARS) based on
|                          a level of accuracy (CRITERIA). The level of accuracy is fixed at 10**-6
|                          (CRIETRIA=6). An output SAS dataset with naming convention 
|                          <domain>_<Change from Baseline (CHG) or Clnical Concern (CC)>_chkboundvals
|                          e.g. LB_CHG_chkboundvals will be created.
|                          
|----------------------------------------------------------------------------------------*/
                     
%macro tu_adchgccfg (
   chgorcc       = CC,      /* Change from Baseline (CHG) or Clnical Concern (CC) */
   cpdsrng       = ,        /* Clinical Pharmacolog Range identifier */
   critdset      = ,        /* Flagging criteria dataset name */
   dgcd          = ,        /* Compound identifier */ 
   domaincode    = &domain, /* LB, EG or VS */
   dsetin        = ,        /* Input dataset name */
   dsetout       = ,        /* Output dataset name */
   studyid       =          /* Study identifier */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   
   %local MacroVersion;
   %let MacroVersion = 2 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %let dsetin       = %qupcase(&dsetin);
   %let dsetout      = %qupcase(&dsetout);
   %let critdset     = %qupcase(&critdset);
   %let domaincode   = %qupcase(&domaincode);
   %let chgorcc      = %qupcase(&chgorcc);
   %let studyid      = %qupcase(&studyid);
   %let dgcd         = %qupcase(&dgcd);
   %let cpdsrng      = %qupcase(&cpdsrng);   
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
   
   %if &dsetin eq %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: The parameter DSETIN is required.;
      %let g_abort=1;
   %end;
   
   %if &dsetout eq %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: The parameter DSETOUT is required.;
      %let g_abort=1;
   %end;
   
   %if (&domaincode ne LB) and (&domaincode ne VS) and (&domaincode ne EG) %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of DOMAINCODE(=&domaincode) is invalid. Valid values should be EG, LB or VS.;       
      %let g_abort=1;    
   %end;
   
   %if (&chgorcc ne CC) and (&chgorcc ne CHG) %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of CHGORCC(=&chgorcc) is invalid. Valid values should be CC or CHG.;       
      %let g_abort=1;    
   %end;
   
   /*
   / Check for existing datasets.
   / Allow for dataset options to be specified
   /----------------------------------------------------------------------------*/

   %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: The dataset DSETIN (=&dsetin) does not exist.; 
      %let g_abort=1;
   %end;
      
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;
   
   /*
   / Validating that DSETOUT is not same as DSETIN.
   / Ignore dataset options when comparing DSETIN and DSETOUT.
   /----------------------------------------------------------------------------*/
   
   %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
   %do;
      %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
   %end;

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
   
   %local prefix l_rc l_crit l_dsetin l_vsposcd l_lbspec l_lbmethod age_is_used 
          fghiage_nonmissing fgloage_nonmissing fghiage_exist fgloage_exist l_a1ora2 
          _valuevar l_idvars;
   %let prefix = _chgccfg;   /* Root name for temporary work datasets */
   
   %if &chgorcc eq CC %then %let l_crit=F3;
   %else %let l_crit=F2;

   %IF &chgorcc = CC %THEN %LET l_a1ora2 = A1;
   %ELSE %LET l_a1ora2 = A2;
   
   %let l_dsetin=%unquote(&dsetin);
   %let chgorcc=%unquote(&chgorcc);
   %let domaincode=%unquote(&domaincode);
   %let l_vsposcd=;
   
   %let fghiage_nonmissing=0;
   %let fgloage_nonmissing=0;
   %let fghiage_exist=0;
   %let fgloage_exist=0;
   %let age_is_used=1; 
    
   /*
   / For change from baseline, split &dsetin into two: baseline and post-baseline.
   / AJC001: Use &l_a1ora2.indcd rather than a2indcd
   /----------------------------------------------------------------------------*/
   
   
   %if &chgorcc ne CC %then %do;
      data &prefix._base &prefix._postbase;
         set %unquote(&l_dsetin);
         if &l_a1ora2.indcd in ('P', 'R') then output &prefix._base;
         else output &prefix._postbase;
      run;
      
      %let l_dsetin=&prefix._postbase;      
   %end;
   %else %do;
      data &prefix._dsetin;
         set %unquote(&dsetin);
      run;
      
      %let l_dsetin=&prefix._dsetin;      
   %end;
          
   %if (&critdset ne) %then %do;
   
      /*
      / CRIT dataset parameter passed.
      / Allow for dataset options to be specified. SL001
      /----------------------------------------------------------------------*/
   
      %if %sysfunc(exist(%qscan(&critdset, 1, %str(%()))) %then %do;

         /*
         / CRIT dataset exists.
         /----------------------------------------------------------------------*/

         data &prefix._crit;
            set %unquote(&critdset);

            /* 
            / Use IF statement instead of WHERE statement, to prevent an e rror
            / from occuring if a WHERE dataset option has been specified.
            /-------------------------------------------------------------------*/

            if fgtyp eq "&l_crit";

            if (upcase(studyid) eq "&studyid") and (upcase(dgcd) eq "&dgcd") 
               %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then do;
               _order_=1;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and ( missing(cpdsrng) ); then do;
               _order_=2;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and ( missing(dgcd) ) 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then do;
               _order_=3;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then do;
               _order_=4;
               output;
            end;    
            else if (missing(studyid)) and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then do;
               _order_=5;
               output;
            end;
            else if (missing(studyid)) and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then do;
               _order_=6;
               output;
            end;
            else if (missing(studyid)) and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then do;
               _order_=7;
               output;
            end;                                                              
            else if (missing(studyid)) and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then do;
               _order_=8;
               output;
            end;
         run;

         data &prefix._dsetinexist;
            if 0 then set %unquote(&dsetin);
         run;   
         
         /*  
         /  Check if FGHIAGE and FGLOAGE exist and are populated
         /----------------------------------------------------------------------*/
        
         %if %tu_nobs(&prefix._crit) ge 1 %then %do;    
            data &prefix._dsetinexist;
               if 0 then set %unquote(&dsetin);
            run;                    
            
            %if %tu_chkvarsexist(&prefix._crit, fghiage) eq %then %do;
               %let fghiage_exist=1;
        
               proc sql noprint;
                  select count(*) into :fghiage_nonmissing 
                  from &prefix._crit
                  where not missing(fghiage);                   
               quit;             
            %end;
                      
            %if %tu_chkvarsexist(&prefix._crit, fgloage) eq %then %do;
               %let fgloage_exist=1;
        
               proc sql noprint;
                  select count(*) into :fgloage_nonmissing 
                  from &prefix._crit
                  where not missing(fgloage);                   
               quit;             
            %end;  

            %let age_is_used=0;
            %* AJC001: Check for AGE rather &domaincode.AGE and change equality from ne to eq *;
            %if %tu_chkvarsexist(&prefix._dsetinexist, AGE ) eq %then %let age_is_used=1;
            %if ( &fghiage_nonmissing or &fgloage_nonmissing ) and ( not &age_is_used ) %then %do;          
               %put %str(RTW)ARNING: &SYSMACRONAME.: FGLOAGE or FGHIAGE is populated in CRITDSET (=&critdset), but AGE does not exist in DSETIN(=&dsetin).; 
               %let age_is_used=0;
            %end;      
            %else %if not &age_is_used %then %let age_is_used=2;      
              
            %else %if ( not &fghiage_exist ) or ( not &fgloage_exist ) %then %do;          
               %put %str(RTW)ARNING: &SYSMACRONAME.: FGLOAGE or FGHIAGE does not exist in CRITDSET (=&critdset), but AGE exists in DSETIN(=&dsetin).; 
               %let age_is_used=0;
            %end; 
            %else %let age_is_used=1;  
             
            %if not &age_is_used %then %do;      
            
               data %unquote(&dsetout);
                  length &l_a1ora2.IND $40;
                  set &l_dsetin;
              
                  &l_a1ora2.INDCD  = ' ';
                  &l_a1ora2.IND = ' '; 
                            
                  if missing( &l_a1ora2.lo) then &l_a1ora2.LO=.;
                  if missing( &l_a1ora2.hi) then &l_a1ora2.HI=.;   
               run;
              
               %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank &l_a1ora2.INDCD and &l_a1ora2.IND variables added.;
               
            %end; /* %if not &age_is_used */            
         %end; /* %tu_nobs(&prefix._crit) ge 1 */  
              
         %if ( %tu_nobs(&prefix._crit) ge 1 ) and ( &age_is_used ) %then %do;
  
            /*
            / There is F2/F3 criteria.
            /----------------------------------------------------------------------*/
  
            %* AJC001: Check for ADT rather &domaincode.DT and remove AGE *;
            %let l_rc=%tu_chkvarsexist(&prefix._dsetinexist, studyid &g_subjid adt sex &domaincode.testcd);
            
            %if %nrbquote(&l_rc) ne %then %do;
               %put %str(RTE)RROR: &SYSMACRONAME.: Following variables do not exist in DSETIN(=&dsetin): &l_rc.; 
               %let g_abort=1;                          
            %end;

            %if &age_is_used eq 1 %then %let l_rc=%tu_chkvarsexist(&prefix._crit, &domaincode.testcd fgstdt algtyp fglo fghi);
            %else %let l_rc=%tu_chkvarsexist(&prefix._crit, &domaincode.testcd fgstdt algtyp fglo fghi fghiage fgloage);
            
            %if %nrbquote(&l_rc) ne %then %do;
               %put %str(RTE)RROR: &SYSMACRONAME.: Following variables do not exist in CRITDSET(=&critdset): &l_rc.; 
               %let g_abort=1;                          
            %end;
            
            %if &g_abort gt 0 %then %do;
               %tu_abort;
            %end;

            %if &domaincode eq LB %then %do;
               %let l_lbspec=LBSPEC;
               %if %tu_chkvarsexist(&prefix._crit, &l_lbspec) ne %then %let l_lbspec=;
               %else %if %tu_chkvarsexist(&l_dsetin, &l_lbspec) ne %then %let l_lbspec=;
               %let l_lbmethod=LBMETHOD;
               %if %tu_chkvarsexist(&prefix._crit, &l_lbmethod) ne %then %let l_lbmethod=;
               %else %if %tu_chkvarsexist(&l_dsetin, &l_lbmethod) ne %then %let l_lbmethod=;
            %end;
               
            %* AJC001: Added %else *;
            %else %if &domaincode eq VS %then %do;
               %let l_vsposcd=VSPOS;
               %if %tu_chkvarsexist(&prefix._crit, &l_vsposcd) ne %then %let l_vsposcd=;
               %else %if %tu_chkvarsexist(&l_dsetin, &l_vsposcd) ne %then %let l_vsposcd=;
            %end;
                    
            /*
            / Create temporary variables based in AGE containing age in years,
            / months, weeks and days.
            / AJC001: Create dataset when AGE does *not* exist with temporary
            / variables set to missing ready for PROC SQL
            /-------------------------------------------------------------------*/  
                  
            %if %tu_chkvarsexist(&prefix._dsetinexist, age) eq %then %do;                   
              data &prefix._testbs2;
                set &l_dsetin;
                  IF age NE . THEN DO;
                    _ageyr = age;
                    _agemo = age * 12; 
                    _agewk = (age * 365.25) / 7; 
                    _agedy = age * 365.25;
                  END;
                  uniq_id = _n_;
              run;
            %END;
            %else %do;
               data &prefix._testbs2;
                  set &l_dsetin;
                  _ageyr=.;
                  _agemo=.;
                  _agewk=.;
                  _agedy=.;
                  uniq_id = _n_;
               run;
            %end;

            proc sort data=&prefix._crit nodupkey;
               by &domaincode.testcd &l_lbspec &l_lbmethod &l_vsposcd fgtyp sex fgloage fghiage fgageu fgstdt _order_;
            run;
            
            data &prefix._crit;
               set &prefix._crit;
               by &domaincode.testcd &l_lbspec &l_lbmethod &l_vsposcd fgtyp sex fgloage fghiage fgageu fgstdt _order_;
               if first.fgstdt;
            run;
            
            proc sql;
               create table &prefix._testbs3 (drop = _ageyr _agemo _agewk _agedy) as
               select a.*,
                      b.algtyp,
                      b.fglo,
                      b.fghi,
                      b.fgstdt,
                      b._order_,
                      b.sex as _sex_,
                      case when b.&domaincode.testcd eq ' '
                           then 'N'
                           else 'Y'
                      end 
                   as &chgorcc._crit
                 from &prefix._testbs2 as a left join &prefix._crit as b
                   on a.&domaincode.testcd eq b.&domaincode.testcd
                   
                  %if %nrbquote(&l_lbspec) ne %then %do;
                     and b.&l_lbspec eq a.&l_lbspec
                  %end;                                      
                  %if %nrbquote(&l_lbmethod) ne %then %do;
                     and b.&l_lbmethod eq a.&l_lbmethod
                  %end;                                      
                  %if %nrbquote(&l_vsposcd) ne %then %do;
                     and b.&l_vsposcd eq a.&l_vsposcd
                  %end;                                      
                  
                  and (b.sex eq ' ' or a.sex eq b.sex)
                  and b.fgstdt le adt
                  %if &age_is_used ne 2 %then %do;
                      and ( (b.fgloage eq . and b.fghiage eq .)
                            or  ( b.fgageu eq '1'
                                  and (b.fgloage eq . or a._ageyr ge b.fgloage)
                                  and (b.fghiage eq . or a._ageyr le b.fghiage) 
                                )
                            or  ( b.fgageu eq '2'
                                  and (b.fgloage eq . or a._agemo ge b.fgloage)
                                  and (b.fghiage eq . or a._agemo le b.fghiage) 
                                )
                            or  ( b.fgageu eq '3'
                                  and (b.fgloage eq . or a._agewk ge b.fgloage)
                                  and (b.fghiage eq . or a._agewk le b.fghiage) 
                                )
                            or  ( b.fgageu eq '4'
                                  and (b.fgloage eq . or a._agedy ge b.fgloage)
                                  and (b.fghiage eq . or a._agedy le b.fghiage) 
                                )
                          )
                  %end;
             order by a.uniq_id, b._order_ DESC, b.fgstdt, b.sex ;
            quit;
  
            data &prefix._testbs4 (drop = uniq_id fgstdt _order_ _sex_);
               set &prefix._testbs3;
               by uniq_id descending _order_ fgstdt _sex_;
  
               /* Record with latest effective start date of CRIT taken */
               if last.uniq_id;
            run;

            /*
            / Flag clinical concern.
            / AJC001: Update values of A1IND/A2IND to match ADaM metadata
            /----------------------------------------------------------------------*/
  
            data %unquote(&dsetout);            
               length &l_a1ora2.IND $40 ;
               set &prefix._testbs4;

               /*
               / Use DROP statement instead of DROP dataset option, so that there 
               / will not be a conflict if the DROP dataset option has been specified
               / as part of the DSETOUT parameter.
               /-------------------------------------------------------------------*/

               drop algtyp fglo fghi &chgorcc._crit;

               /* Derive High & Low range variable */
               %if &chgorcc eq CC %then %do;
                  if algtyp eq 'A' then do;
                     &l_a1ora2.LO = fglo;
                     &l_a1ora2.HI = fghi;           
                  end;
                  %if &domaincode eq LB %then %do;                       
                     else if algtyp in('+NR', 'P') then do;
                        &l_a1ora2.LO = anrLO * fglo;
                        &l_a1ora2.HI = anrHI * fghi;
                     end;
                     else if algtyp eq 'NRA' then do;
                        &l_a1ora2.LO = anrLO - fglo;
                        &l_a1ora2.HI = anrHI + fghi;
                     end;
                  %end; /* %if &domaincode eq LB */
               %end; /* %if &chgorcc eq CC */

               %* SR001 - Updated derivation of ranges for change from baseline ;
               %else %do;                   
                  if algtyp  eq  'A' then do;
                     &l_a1ora2.LO = fglo;
                     %* Check whether A2LO is positive and convert to negative ;
                     IF &l_a1ora2.LO GT 0 THEN &l_a1ora2.LO = &l_a1ora2.LO * -1;
                     &l_a1ora2.HI = fghi;
                  end;
                  else if algtyp  eq  'P' then do;
                     &l_a1ora2.LO = (base * fglo) - base;
                     &l_a1ora2.HI = (base * fghi) - base;
                  end;
                  %if &domaincode eq LB %then %do;                  
                     else if algtyp  eq  'NR' then do;
                        &l_a1ora2.LO = (anrHI - anrLO) * fglo;
                        %* Check whether A2LO is positive and convert to negative ;
                        IF &l_a1ora2.LO GT 0 THEN &l_a1ora2.LO = &l_a1ora2.LO * -1;
                        &l_a1ora2.HI = (anrHI - anrLO) * fghi;
                     end;
                  %end; /* %if &domaincode eq LB */
               %end; /* %if &chgorcc eq CC %else */

               else do;
                  algtyp='INV';               
               end;
               
               if algtyp ne 'INV' then do;         
                  &l_a1ora2.LO = round (&l_a1ora2.LO, .00000001);
                  &l_a1ora2.HI = round (&l_a1ora2.HI, .00000001);                                                                                
               end; /* if algtyp ne 'INV' */
                      
               /* Check missing values */             
               &l_a1ora2.IND = '';
               
               %if ( &domaincode eq LB ) and ( &chgorcc eq CC ) %then %do;   
                  if missing(aval) then do;
                     &l_a1ora2.INDCD  = '';               
                     &l_a1ora2.IND = "";
                  end;
                  else if (algtyp ne 'A') and ( missing(anrlo) and missing(anrhi) ) then do;
                     &l_a1ora2.INDCD  = '';
                     &l_a1ora2.IND = '';
                  end;  
               %end; /* %if ( &domaincode eq LB ) and ( &chgorcc eq CC ) */               
               %else %if ( &domaincode ne LB ) and ( &chgorcc eq CC ) %then %do;   
                  if missing(aval) then do;
                     &l_a1ora2.INDCD  = '';               
                     &l_a1ora2.IND = "";
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc eq CC ) */
               %else %if ( &domaincode eq LB ) and ( &chgorcc ne CC ) %then %do;
                  if missing(aval) or missing(base) then do;
                    &l_a1ora2.INDCD  = '';               
                    &l_a1ora2.IND = "";
                  end;
                  else if (algtyp eq 'NR') and (missing(anrlo) or missing(anrhi)) then do;
                     &l_a1ora2.INDCD  = '';
                     &l_a1ora2.IND = '';
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) */
               %else %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) %then %do;
                  if missing(aval) or missing(base) then do;
                    &l_a1ora2.INDCD  = '';               
                    &l_a1ora2.IND = "";
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) */
                                   
                                      
               /* Derive flagging variables */                                                                
               %* SR001 - Separate CC and CHG as now using AVAL and CHG respectively ;
               %IF &chgorcc eq CC %THEN %DO;
	             else if not missing(aval) then do;      
	 	           if (aval lt &l_a1ora2.lo) and (not missing(&l_a1ora2.lo) ) then do;
                     &l_a1ora2.INDCD  = 'L';
                     &l_a1ora2.IND = 'Low';
                   end;
                   else if (aval gt &l_a1ora2.hi) and (not missing(&l_a1ora2.hi) ) then do;
                     &l_a1ora2.INDCD  = 'H';
                     &l_a1ora2.IND = 'High';
                   end;
                   else if missing(&l_a1ora2.IND) AND NMISS(&l_a1ora2.lo,&l_a1ora2.hi) LT 2 then do;
                     &l_a1ora2.INDCD  = 'I';
                     &l_a1ora2.IND = 'Normal';
                   end;
                 end; /* end-else */
               %END; /* End %IF &chgorcc eq CC */
               %ELSE %IF &chgorcc ne CC %THEN %DO;
	             else if not missing(chg) then do;      
	 	           if (chg lt &l_a1ora2.lo) and (not missing(&l_a1ora2.lo) ) then do;
                     &l_a1ora2.INDCD  = 'L';
                     &l_a1ora2.IND = 'Low';
                   end;
                   else if (chg gt &l_a1ora2.hi) and (not missing(&l_a1ora2.hi) ) then do;
                     &l_a1ora2.INDCD  = 'H';
                     &l_a1ora2.IND = 'High';
                   end;
                   else if missing(&l_a1ora2.IND) AND NMISS(&l_a1ora2.lo,&l_a1ora2.hi) LT 2 then do;
                     &l_a1ora2.INDCD  = 'I';
                     &l_a1ora2.IND = 'Normal';
                   end;
                 end; /* end-else */
              %END; /* End %IF &chgorcc ne CC */
            run;
  
         %end;  /* end-if on there is F2/F3 criteria. */
         %else %do;
  
            /*
            / There is no F2/F3 criteria.
            /----------------------------------------------------------------------*/
  
            data %unquote(&dsetout);
                 length &l_a1ora2.IND $40;
                 set &l_dsetin;
  
                 &l_a1ora2.INDCD  = ' '; /*SR002 */
                 &l_a1ora2.IND = " "; /* SR002 */
            run;
            %put %str(RTW)ARNING: &SYSMACRONAME.: There are no &chgorcc criteria.;
  
         %end; /* end-else on there is not F2/F3 criteria. */
  
      %end;  /* end-if on CRIT dataset exist. */
      %else %do;
      
         /* CRIT dataset does not exist */

         data %unquote(&dsetout);
             length &l_a1ora2.IND $40;
             set &l_dsetin;
  
             &l_a1ora2.INDCD  = ' ';
             &l_a1ora2.IND = ' ';
             
             if missing( &l_a1ora2.LO) then &l_a1ora2.LO=.;
             if missing( &l_a1ora2.HI) then &l_a1ora2.HI=.;           
          run;
  
         %if %sysfunc(exist(%qscan(&critdset, 1, %str(%()))) eq 0 %then %do;
            %put %str(RTW)ARNING: &SYSMACRONAME.: CRITDSET (=&critdset) dataset does not exist.; 
         %end;
  
         %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank %UPCASE(&l_a1ora2.INDCD) and %UPCASE(&l_a1ora2.)IND variables added.;
  
      %end; /* end-else on CRIT does not exist */
  
   %end;  /* end-if on CRIT dataset parameter passed. */
  
   %else %do;
      /* CRIT dataset parameter not passed */
  
      data %unquote(&dsetout);
         length &l_a1ora2.IND $40;
         set &l_dsetin;
  
         &l_a1ora2.INDCD  = ' ';
         &l_a1ora2.IND = ' '; 
                   
         if missing( &l_a1ora2.lo) then &l_a1ora2.LO=.;
         if missing( &l_a1ora2.hi) then &l_a1ora2.HI=.;   
      run;
  
      %if &critdset eq  %then %do;
         %put %str(RTW)ARNING: &SYSMACRONAME.: CRITDSET dataset parameter is blank.;
      %end;
      %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank %UPCASE(&l_a1ora2.INDCD) and %UPCASE(&l_a1ora2.)IND variables added.;
      
   %end; /* end-else on CRIT parameter not passed. */

  
   /*
   / For change from baseline, add baseline to output data set.
   /----------------------------------------------------------------------------*/
   
   %if &chgorcc ne CC %then %do;
      data %unquote(&dsetout);
         set %unquote(&dsetout) &prefix._base;
      run;
   %end;
  
   /*
   / Call macro chkboundvals for precision checking
   /----------------------------------------------------------------------------*/
   ** NP001 Determine if VALUEVAR should be AVAL or CHG **;
   %if &chgorcc eq CC %then %let _valuevar=AVAL;
   %if &chgorcc eq CHG %then %let _valuevar=CHG;
   
   ** NP001 Add list of variables for OBSIDVARS and check which exist - create macro parameter of those that do **;
   %let l_idvars=%tu_chkvarsexist(&dsetout, &g_subjid aseq &DOMAINCODE.seq &_valuevar. &DOMAINCODE.testcd paramcd param visitnum &DOMAINCODE.visit avisitn avisit &DOMAINCODE.dtc adt atm &l_a1ora2.LO &l_a1ora2.HI,Y);
   
   %tu_chkboundvals(dsetin=&dsetout,   
                    valuevar=&_valuevar.,     
                    compvars=&l_a1ora2.LO &l_a1ora2.HI,     
                    obsidvars= &l_idvars,   
                    criteria=6,    
                    dsetout = rfmtdir.&domaincode._&chgorcc._chkboundvals
                   );                
   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
  
   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
    
%mend tu_adchgccfg;
