/*                                      
| Macro Name:         tu_chgccfg
|                    
| Macro Version:      3 build 1
|                    
| SAS Version:        9.1
|                    
| Created By:         Yongwei Wang
|                    
| Date:               31Aug2006
|                    
| Macro Purpose:      This unit shall take an input dataset and perform Clinical 
|                     Concern or Change From Baseline flagging for LAB, ECG or Vital 
|                     Signs, in order to create an output dataset. 
|
|                     NOTE: For LAB flagging, the tu_conv macro should be called before 
|                     this macro. The tu_conv macro converts the original results/units
|                     into standard results/units. This needs to be done before the 
|                     critical concern flagging can be done.
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
|                     Valid values: CC , CH or CHG                                   
|                                                                                    
| CPDSRNG             Specifies if the range is for Clinical       (None)            
|                     Pharmacology range                                             
|                     Valid values: Blank, Y or N                                    
|                                                                                    
| DEMODSET            Specifies a SI Demography dataset.           Dmdata.demo       
|                     Valid values: Blank or a valid dataset name                    
|                                                                                    
| DGCD                If given, the macro will try to get range    (None)            
|                     for given compound identifier first                            
|                     Valid Values: Blank or any string                              
|                                                                                    
| DOMAINCODE          Specifies which test flagging should be      LB                
|                     derived: Lab (LB), ECG (EG) or Vital Signs                     
|                     (VS)                                                           
|                     Valid Values:                                                  
|                     LB, EG or VS                                                   
|                                                                                    
| CRITDSET            Specifies the SI dataset which contains the  Dmdata.labcrit    
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
|    %tu_chgccfg()
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang (YW62951)
| Date of Modification:     11-May-2007
| New version number:       2/1
| Modification ID:          YW001
| Reason For Modification:  Added VSPOSCD to the condition in SQL merge, based on change 
|                           request HRT0161
|
| Modified By:              Shan Lee
| Date of Modification:     28-Sep-2007
| New version number:       2/2
| Modification ID:          SL001
| Reason For Modification:  1. Enable dataset options to be specified for input and output
|                              dataset names. HRT0184
|                           2. If BIRTHDT does not exist in &DEMODSET, use 
|                              xxAGEDY, xxAGEWK, xxAGEMO, xxAGE in &DSETIN to 
|                              get ranges
|
| Modified By:              Ian Barretto
| Date of Modification:     04-Jun-2009
| New version number:       2/3
| Modification ID:          IB001
| Reason For Modification:  1. If BIRTHDT exists but has missing values then use same algorithm 
|                              as if BIRTHDT was missing. HRT0224
|                           2. Correct variable names listed FGAGEHI and FGAGELO to FGHIAGE and FGLOAGE
|                              when checking for the existence of the variable in the CRIT dataset.       
|                           
| Modified By:             Anthony J Cooper
| Date of Modification:    17-May-2018
| New version number:      3 build 1
| Modification ID:         AJC001
| Reason For Modification: Add call to utility macro tu_chkboundvals which will flag
|                          observations where specified value variable (VALUEVAR) is 
|                          deemed to be close to a boundary value (COMPVARS) based on
|                          a level of accuracy (CRITERIA). The level of accuracy is 
|                          fixed at 10**-6 (CRIETRIA=6).
|                          An output SAS dataset with naming convention
|                          <domain>_<Change from Baseline (CH/CHG) or Clnical Concern (CC)>_chkboundvals
|                          e.g. VS_CH_chkboundvals will be created.
|
|----------------------------------------------------------------------------------------*/
                     
%macro tu_chgccfg (
   chgorcc       = CC,               /* Change from Baseline (CH/CHG) or Clnical Concern (CC) */
   cpdsrng       = ,                 /* Clinical Pharmacolog Range identifier */
   critdset      = DMDATA.LABCRIT,   /* Flagging criteria dataset name */
   demodset      = DMDATA.DEMO,      /* Demography dataset name */
   dgcd          = ,                 /* Compound identifier */ 
   domaincode    = LB,               /* LB, EG or VS */
   dsetin        = ,                 /* Input dataset name */
   dsetout       = ,                 /* Output dataset name */
   studyid       =                   /* Study identifier */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   
   %local MacroVersion;
   %let MacroVersion = 3 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %let dsetin       = %qupcase(&dsetin);
   %let dsetout      = %qupcase(&dsetout);
   %let critdset     = %qupcase(&critdset);
   %let demodset     = %qupcase(&demodset);
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
   
   %if (&chgorcc ne CC) and (&chgorcc ne CH) and (&chgorcc ne CHG) %then
   %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of CHGORCC(=&chgorcc) is invalid. Valid values should be CC, CH or CHG.;       
      %let g_abort=1;    
   %end;
   
   %if (&domaincode eq LB) and (&chgorcc eq CH) %then %let chgorcc=CHG;
   %if (&domaincode ne LB) and (&chgorcc eq CHG) %then %let chgorcc=CH;
   
   /*
   / Check for existing datasets.
   / Allow for dataset options to be specified - SL001
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
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   / Ignore dataset options when comparing DSETIN and DSETOUT. SL001
   /----------------------------------------------------------------------------*/
   
   %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
   %do;
      %put %str(RTN)OTE: &SYSMACRONAME.: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
   %end;
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
   
   %local prefix l_rc l_standard l_crit l_dsetin l_vsposcd age_is_used 
          fghiage_nonmissing fgloage_nonmissing fghiage_exist fgloage_exist l_idvars;
   %let prefix = _chgccfg;   /* Root name for temporary work datasets */
   
   %if &chgorcc eq CC %then %let l_standard=ST;
   %else %let l_standard=;
   
   %if &chgorcc eq CC %then %let l_crit=F3;
   %else %let l_crit=F2;
   
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
   /----------------------------------------------------------------------------*/
   
   
   %if &chgorcc ne CC %then
   %do;
      data &prefix._base &prefix._postbase;
         set %unquote(&l_dsetin);
         if &domaincode.&chgorcc.CD in ('P', 'R') then output &prefix._base;
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
          
   %if (&critdset ne) and (&demodset ne) %then
   %do;
   
      /*
      / CRIT and DEMO dataset parameters passed.
      / Allow for dataset options to be specified. SL001
      /----------------------------------------------------------------------*/
   
      %if %sysfunc(exist(%qscan(&critdset, 1, %str(%()))) and %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) %then
      %do;

         /*
         / CRIT and DEMO datasets exist.
         /----------------------------------------------------------------------*/
                         
         data &prefix._crit;
            set %unquote(&critdset);

            /* 
            / Use IF statement instead of WHERE statement, to prevent an e rror
            / from occuring if a WHERE dataset option has been specified. SL001
            /-------------------------------------------------------------------*/

            if fgtyp eq "&l_crit";
               ;
            if (upcase(studyid) eq "&studyid") and (upcase(dgcd) eq "&dgcd") 
               %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then
            do;
               _order_=1;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and ( missing(cpdsrng) ); then
            do;
               _order_=2;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and ( missing(dgcd) ) 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then
            do;
               _order_=3;
               output;
            end;
            else if (upcase(studyid) eq "&studyid") and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then
            do;
               _order_=4;
               output;
            end;    
            else if (missing(studyid)) and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then
            do;
               _order_=5;
               output;
            end;
            else if (missing(studyid)) and (upcase(dgcd) eq "&dgcd") 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then
            do;
               _order_=6;
               output;
            end;
            else if (missing(studyid)) and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (upcase(cpdsrng) eq "&cpdsrng"); then
            do;
               _order_=7;
               output;
            end;                                                              
            else if (missing(studyid)) and (missing(dgcd)) 
                    %if %nrbquote(&cpdsrng) ne %then and (missing(cpdsrng)); then
            do;
               _order_=8;
               output;
            end;
         run;
         
         data &prefix._demoexist;
            if 0 then set %unquote(&demodset);
         run;
         
         data &prefix._dsetinexist;
            if 0 then set %unquote(&dsetin);
         run;   
         
         /*  
         /  Check if FGHIAGE and FGLOAGE exist and are populated
         /----------------------------------------------------------------------*/
        
         %if %tu_nobs(&prefix._crit) ge 1 %then
         %do;    
            data &prefix._demoexist;
               if 0 then set %unquote(&demodset);
            run;
            
            data &prefix._dsetinexist;
               if 0 then set %unquote(&dsetin);
            run;                    
            
            %if %tu_chkvarsexist(&prefix._crit, fghiage) eq %then
            %do;
               %let fghiage_exist=1;
        
               proc sql noprint;
                  select count(*) into :fghiage_nonmissing 
                  from &prefix._crit
                  where not missing(fghiage);                   
               quit;             
            %end;
                      
            %if %tu_chkvarsexist(&prefix._crit, fgloage) eq %then
            %do;
               %let fgloage_exist=1;
        
               proc sql noprint;
                  select count(*) into :fgloage_nonmissing 
                  from &prefix._crit
                  where not missing(fgloage);                   
               quit;             
            %end;  
            
            %let age_is_used=0;                 
            
            %if %tu_chkvarsexist(&prefix._demoexist, birthdt) ne %then
            %do;              
               %let age_is_used=0;
               %if %tu_chkvarsexist(&prefix._dsetinexist, &domaincode.AGE )   eq %then  %let age_is_used=1;
               %if %tu_chkvarsexist(&prefix._dsetinexist, &domaincode.AGEMO ) eq %then  %let age_is_used=1;
               %if %tu_chkvarsexist(&prefix._dsetinexist, &domaincode.AGEWK ) eq %then  %let age_is_used=1;
               %if %tu_chkvarsexist(&prefix._dsetinexist, &domaincode.AGEDY ) eq %then  %let age_is_used=1;
               %if ( &fghiage_nonmissing or &fgloage_nonmissing ) and ( not &age_is_used ) %then 
               %do;          
                  %put %str(RTW)ARNING: &SYSMACRONAME.: FGLOAGE or FGHIAGE is populated in CRITDSET (=&critdset), but BIRTHDT does not exist in DEMODSET(=&demodset),;
                  %put %str(RTW)ARNING: &SYSMACRONAME.: and &domaincode.AGE, &domaincode.AGEMO, &domaincode.AGEWK and &domaincode.AGE do not exist in DSETIN(=&dsetin).; 
                  %let age_is_used=0;
               %end;      
               %else %if not &age_is_used %then %let age_is_used=2;      
               %else %do;
                  %put %str(RTN)OTE: &SYSMACRONAME.: FGLOAGE or FGHIAGE is populated in CRITDSET (=&critdset), but BIRTHDT does not exist in DEMODSET(=&demodset).;
                  %put %str(RTN)OTE: &SYSMACRONAME.: LBAGE, LBAGEMO, LBAGEWK or LBAGEYR in DSETIN(=&DSETIN) will be used in deriving the ranges.; 
                  %let age_is_used=1;      
               %end;
            %end;
              
            %else %if ( not &fghiage_exist ) or ( not &fgloage_exist ) %then
            %do;          
               %put %str(RTW)ARNING: &SYSMACRONAME.: FGLOAGE or FGHIAGE does not exist in CRITDSET (=&critdset), but BIRTHDT exists in DEMODSET(=&demodset).; 
               %let age_is_used=0;
            %end; 
            %else %let age_is_used=1;  
             
            %if not &age_is_used %then
            %do;      
            
               data %unquote(&dsetout);
                  set &l_dsetin;
                  length &domaincode.&chgorcc.IND $40;
              
                  &domaincode.&chgorcc.CD  = ' ';
                  &domaincode.&chgorcc.IND = ' '; 
                            
                  if missing( &domaincode.&chgorcc.lo) then &domaincode.&chgorcc.LO=.;
                  if missing( &domaincode.&chgorcc.hi) then &domaincode.&chgorcc.HI=.;   
               run;
              
               %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank &DOMAINCODE.&CHGORCC.CD and &DOMAINCODE.&CHGORCC.IND variables added.;
               
            %end; /* %if not &age_is_used */            
         %end; /* %tu_nobs(&prefix._crit) ge 1 */  
              
         %if ( %tu_nobs(&prefix._crit) ge 1 ) and ( &age_is_used ) %then
         %do;
  
            /*
            / There is F2/F3 criteria.
            /----------------------------------------------------------------------*/
  
            /*
            / Retrieve birth date for calculation of sample age.
            /----------------------------------------------------------------------*/
                        
            %let l_rc=%tu_chkvarsexist(&prefix._demoexist, studyid subjid);
            
            %if %nrbquote(&l_rc) ne %then
            %do;
               %put %str(RTE)RROR: &SYSMACRONAME.: Following variables do not exist in DEMODSET(=&demodset): &l_rc.; 
               %let g_abort=1;                          
            %end;
            
            %let l_rc=%tu_chkvarsexist(&prefix._dsetinexist, studyid subjid &domaincode.dt sex &domaincode.testcd);
            
            %if %nrbquote(&l_rc) ne %then
            %do;
               %put %str(RTE)RROR: &SYSMACRONAME.: Following variables do not exist in DSETIN(=&dsetin): &l_rc.; 
               %let g_abort=1;                          
            %end;

            /* IB001 - Correct variable names listed FGAGEHI and FGAGELO to FGHIAGE and FGLOAGE */
            %if &age_is_used eq 1 %then
               %let l_rc=%tu_chkvarsexist(&prefix._crit, &domaincode.testcd fgstdt algtyp fglo fghi);
            %else 
               %let l_rc=%tu_chkvarsexist(&prefix._crit, &domaincode.testcd fgstdt algtyp fglo fghi fghiage fgloage);
            
            %if %nrbquote(&l_rc) ne %then
            %do;
               %put %str(RTE)RROR: &SYSMACRONAME.: Following variables do not exist in CRITDSET(=&critdset): &l_rc.; 
               %let g_abort=1;                          
            %end;
            
            %if &g_abort gt 0 %then
            %do;
               %tu_abort;
            %end;
               
            %if &domaincode eq VS %then
            %do;
               %let l_vsposcd=VSPOSCD;
               %if %tu_chkvarsexist(&prefix._crit, &l_vsposcd) ne %then %let l_vsposcd=;
               %else %if %tu_chkvarsexist(&l_dsetin, &l_vsposcd) ne %then %let l_vsposcd=;
            %end;
                    
            /*
            / If birthdt is not in &demodset, Use xxAGE, xxEMO, xxEWK 
            / and xxAGE in &DEMODSET.
            /-------------------------------------------------------------------*/  
                  
            %if %tu_chkvarsexist(&prefix._demoexist, birthdt) ne %then
            %do;                   
                    
               data &prefix._testbs2;
                  set &l_dsetin;
                  _ageyr=.;
                  _agemo=.; 
                  _agewk=.; 
                  _agedy=.;
                  %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGE)   eq %then _ageyr=&domaincode.AGE   ;;
                  %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEMO) eq %then _agemo=&domaincode.AGEMO ;;
                  %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEWK) eq %then _agewk=&domaincode.AGEWK ;;
                  %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEDY) eq %then _agedy=&domaincode.AGEDY ;;               
                  uniq_id = _n_;
               run;
                               
            %end; /* BIRTHDT does not exist in &DEMODSET */
           
            %else %do;

            /* If BIRTHDT exists in &demodset */

            /* Check if BIRTHDT is populated with missing values - IB001
            /----------------------------------------------------------------------------*/

               %let birthdt_miss = 0; 

               proc sql; 
                 create table &prefix._missvar as 
                 select
                 count(distinct birthdt) as no_birthdt
                 from &demodset;
               quit;

               data _null_;
                 set &prefix._missvar;
                 if no_birthdt eq 0 then 
                 do;
                   call symput ('birthdt_miss',1);
                 end;
               run;

               /* If BIRTHDT exists but has missing values then use same algorithm as if BIRTHDT was missing */
               %if &birthdt_miss %then 
               %do;

                  data &prefix._testbs2;
                    set &l_dsetin;
                    _ageyr=.;
                    _agemo=.; 
                    _agewk=.; 
                    _agedy=.;
                    %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGE)   eq %then _ageyr=&domaincode.AGE   ;;
                    %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEMO) eq %then _agemo=&domaincode.AGEMO ;;
                    %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEWK) eq %then _agewk=&domaincode.AGEWK ;;
                    %if %tu_chkvarsexist(&l_dsetin, &domaincode.AGEDY) eq %then _agedy=&domaincode.AGEDY ;;               
                    uniq_id = _n_;
                 run;

               %end; /* End of BIRTHDT exists but has missing values */

               %else %do;

               /*
               / Use BIRTHDT if populated with valid values
               /----------------------------------------------------------------------------*/
          
                  proc sql;
                     create table &prefix._testbs as
                     select a.*, b.birthdt
                     from &l_dsetin as a left join %unquote(&demodset) as b
                     on  a.studyid eq b.studyid
                     and a.subjid  eq b.subjid ;
                  quit;
                 
                  data &prefix._testbs2;
                     set &prefix._testbs;
                     drop birthdt;
              
                     /* Sample age calculated in all possible age units */
                 
                     if birthdt ne . and &domaincode.dt ne . then
                     do;
                        _ageyr  = intck('year', birthdt,&domaincode.dt) -
                                       ( month(&domaincode.dt) lt month(birthdt) or
                                       ( month(&domaincode.dt) eq month(birthdt) and 
                                         day(&domaincode.dt) lt day(birthdt)) );
                        _agemo  = (year(&domaincode.dt) - year(birthdt)) * 12
                                   + (month(&domaincode.dt) - month(birthdt)-1)
                                   + (day(&domaincode.dt) ge day(birthdt));
                        _agewk  = int((&domaincode.dt - birthdt)/7);
                        _agedy  = &domaincode.dt - birthdt;
                     end;
              
                     /*
                     / Mark records with a unique identifier as merging with CRIT
                     / panel can produce duplicated records with different CRIT
                     / effective start dates. Record with latest effective start
                     / date will be taken.
                     /--------------------------------------------------------------*/
              
                     uniq_id = _n_;
                  run;
               %end; /* BIRTHDT exists in &DEMODSET and contains values */

            %end; /* BIRTHDT exists in &DEMODSET */
            
            proc sort data=&prefix._crit nodupkey;
               by &domaincode.testcd &l_vsposcd fgtyp sex fgloage fghiage fgageu fgstdt _order_;
            run;
            
            data &prefix._crit;
               set &prefix._crit;
               by &domaincode.testcd &l_vsposcd fgtyp sex fgloage fghiage fgageu fgstdt _order_;
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
                   
                  %if %nrbquote(&l_vsposcd) ne %then
                  %do;
                     and b.&l_vsposcd eq a.&l_vsposcd
                  %end;                                      
                  
                  and (b.sex eq ' ' or a.sex eq b.sex)
                  and b.fgstdt le a.&domaincode.dt
                  %if &age_is_used ne 2 %then
                  %do;
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
            /----------------------------------------------------------------------*/
  
            data %unquote(&dsetout);            
               length &domaincode.&chgorcc.IND $40 ;
               set &prefix._testbs4;

               /*
               / Use DROP statement instead of DROP dataset option, so that there 
               / will not be a conflict if the DROP dataset option has been specified
               / as part of the DSETOUT parameter. SL001
               /-------------------------------------------------------------------*/

               drop algtyp fglo fghi &chgorcc._crit;

               /* Derive High & Low range variable */
               %if &chgorcc eq CC %then
               %do;
                  if algtyp eq 'A' then
                  do;
                     &domaincode.&l_standard.&chgorcc.LO = fglo;
                     &domaincode.&l_standard.&chgorcc.HI = fghi;           
                  end;
                  %if &domaincode eq LB %then
                  %do;                       
                     else if algtyp in('+NR', 'P') then 
                     do;
                        &domaincode.&l_standard.&chgorcc.LO = &domaincode.STNRLO * fglo;
                        &domaincode.&l_standard.&chgorcc.HI = &domaincode.STNRHI * fghi;
                     end;
                     else if algtyp eq 'NRA' then 
                     do;
                        &domaincode.&l_standard.&chgorcc.LO = &domaincode.STNRLO - fglo;
                        &domaincode.&l_standard.&chgorcc.HI = &domaincode.STNRHI + fghi;
                     end;
                  %end; /* %if &domaincode eq LB */
               %end; /* %if &chgorcc eq CC */
               %else %do;                   
                  if algtyp  eq  'A' then
                  do;
                     &domaincode.&l_standard.&chgorcc.LO = &domaincode.STDBL - fglo;
                     &domaincode.&l_standard.&chgorcc.HI = &domaincode.STDBL + fghi;
                  end;
                  else if algtyp  eq  'P' then 
                  do;
                     &domaincode.&l_standard.&chgorcc.LO = &domaincode.STDBL * fglo;
                     &domaincode.&l_standard.&chgorcc.HI = &domaincode.STDBL * fghi;
                  end;
                  %if &domaincode eq LB %then
                  %do;                  
                     else if algtyp  eq  'NR' then 
                     do;
                        &domaincode.&l_standard.&chgorcc.LO = 
                           &domaincode.STDBL - ((&domaincode.STNRHI - &domaincode.STNRLO) * fglo);
                        &domaincode.&l_standard.&chgorcc.HI = 
                           &domaincode.STDBL + ((&domaincode.STNRHI - &domaincode.STNRLO) * fghi);
                     end;
                  %end; /* %if &domaincode eq LB */
               %end; /* %if &chgorcc eq CC %else */
               else do;
                  algtyp='INV';               
               end;
               
               if algtyp ne 'INV' then
               do;         
                  &domaincode.&l_standard.&chgorcc.LO = 
                     round (&domaincode.&l_standard.&chgorcc.LO, .00000001);
                  &domaincode.&l_standard.&chgorcc.HI =                
                     round (&domaincode.&l_standard.&chgorcc.HI, .00000001);                                                                                
               end; /* if algtyp ne 'INV' */
                                                            
               /* Check missing values */             
               &domaincode.&chgorcc.IND = '';
               
               %if ( &domaincode eq LB ) and ( &chgorcc eq CC ) %then
               %do;   
                  if missing(&domaincode.stresn) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'U';               
                     &domaincode.&chgorcc.IND = "Missing converted lab value";
                  end;
                  else if (algtyp ne 'A') and ( missing(&domaincode.stnrlo) and   
                       missing(&domaincode.stnrhi) ) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'X';
                     &domaincode.&chgorcc.IND = 'Missing converted normal range value';
                  end;  
               %end; /* %if ( &domaincode eq LB ) and ( &chgorcc eq CC ) */               
               %else %if ( &domaincode ne LB ) and ( &chgorcc eq CC ) %then
               %do;   
                  if missing(&domaincode.stresn) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'U';               
                     &domaincode.&chgorcc.IND = "Missing test value";
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc eq CC ) */
               %else %if ( &domaincode eq LB ) and ( &chgorcc ne CC ) %then
               %do;
                  if missing(&domaincode.stresn) or missing(&domaincode.stdbl) then 
                  do;
                    &domaincode.&chgorcc.CD  = 'U';               
                    &domaincode.&chgorcc.IND = "Missing converted lab or baseline value";
                  end;
                  else if (algtyp eq 'NR') and (missing(&domaincode.stnrlo) or 
                          missing(&domaincode.stnrhi)) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'X';
                     &domaincode.&chgorcc.IND = 'Missing converted normal range value';
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) */
               %else %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) %then
               %do;
                  if missing(&domaincode.stresn) or missing(&domaincode.stdbl) then 
                  do;
                    &domaincode.&chgorcc.CD  = 'U';               
                    &domaincode.&chgorcc.IND = "Missing test or baseline test value";
                  end;
               %end; /* %if ( &domaincode ne LB ) and ( &chgorcc ne CC ) */
                                                  
               /* Derive flagging variables */                                                                
               if &chgorcc._crit eq 'N' then 
               do;
                  &domaincode.&chgorcc.CD  = 'N';
                  &domaincode.&chgorcc.IND = "No &l_crit criteria";
               end;
               else if algtyp eq 'INV' then 
               do;
                  &domaincode.&chgorcc.cd = 'M';
                  %if &domaincode eq LB %then
                     &domaincode.&chgorcc.IND = "Invalid algorithm type in LABCRIT";
                  %else                  
                     &domaincode.&chgorcc.IND = "Invalid algorithm type in &domaincode.CRIT";
                  ;
               end; /* if algtyp eq 'INV' */             
	           else if not missing(&domaincode.stresn) then
               do;      
	 	          if (&domaincode.stresn lt &domaincode.&l_standard.&chgorcc.lo) and 
                     (not missing(&domaincode.&l_standard.&chgorcc.lo) ) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'L';
                     &domaincode.&chgorcc.IND = 'Low';
                  end;
                  else if (&domaincode.stresn gt &domaincode.&l_standard.&chgorcc.hi) and 
                          (not missing(&domaincode.&l_standard.&chgorcc.hi) ) then 
                  do;
                     &domaincode.&chgorcc.CD  = 'H';
                     &domaincode.&chgorcc.IND = 'High';
                  end;
                  else if missing(&domaincode.&chgorcc.IND) then
                  do;
                     &domaincode.&chgorcc.CD  = 'I';
                     &domaincode.&chgorcc.IND = 'Normal';
                  end;
               end; /* end-else */
            run;
  
         %end;  /* end-if on there is F2/F3 criteria. */
         %else %do;
  
            /*
            / There is no F2/F3 criteria.
            /----------------------------------------------------------------------*/
  
            data %unquote(&dsetout);
                 set &l_dsetin;
                 length &domaincode.&chgorcc.IND $40;
  
                 &domaincode.&chgorcc.CD  = 'N';
                 &domaincode.&chgorcc.IND = "No &l_crit criteria";
            run;
            %put %str(RTW)ARNING: &SYSMACRONAME.: There are no &l_crit criteria.;
  
         %end; /* end-else on there is not F2/F3 criteria. */
  
      %end;  /* end-if on CRIT and DEMO datasets exist. */
      %else %do;
      
         /* CRIT or DEMO dataset does not exist */

         data %unquote(&dsetout);
             set &l_dsetin;
             length &domaincode.&chgorcc.IND $40;
  
             &domaincode.&chgorcc.CD  = ' ';
             &domaincode.&chgorcc.IND = ' ';
             
             if missing( &domaincode.&chgorcc.LO) then &domaincode.&chgorcc.LO=.;
             if missing( &domaincode.&chgorcc.HI) then &domaincode.&chgorcc.HI=.;           
          run;
  
         %if %sysfunc(exist(%qscan(&critdset, 1, %str(%()))) eq 0 %then
         %do;
            %put %str(RTW)ARNING: &SYSMACRONAME.: CRITDSET (=&critdset) dataset does not exist.; 
         %end;
  
         %if %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) eq 0 %then
         %do;
            %put %str(RTW)ARNING: &SYSMACRONAME.: DEMODSET (=&demodset) dataset does not exist.; 
         %end;
  
         %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank &DOMAINCODE.&CHGORCC.CD and &DOMAINCODE.&CHGORCC.IND variables added.;
  
      %end; /* end-else on CRIT or DEMO does not exist */
  
   %end;  /* end-if on CRIT and DEMO dataset parameters passed. */
  
   %else %do;
      /* CRIT or DEMO dataset parameter not passed */
  
      data %unquote(&dsetout);
         set &l_dsetin;
         length &domaincode.&chgorcc.IND $40;
  
         &domaincode.&chgorcc.CD  = ' ';
         &domaincode.&chgorcc.IND = ' '; 
                   
         if missing( &domaincode.&chgorcc.lo) then &domaincode.&chgorcc.LO=.;
         if missing( &domaincode.&chgorcc.hi) then &domaincode.&chgorcc.HI=.;   
      run;
  
      %if &critdset eq  %then
      %do;
         %put %str(RTW)ARNING: &SYSMACRONAME.: CRITDSET dataset parameter is blank.;
      %end;
      %if &demodset eq  %then
      %do;
         %put %str(RTW)ARNING: &SYSMACRONAME.: DEMODSET dataset parameter is blank.;
      %end;
      %put %str(RTW)ARNING: &SYSMACRONAME.: &dsetout is set to &dsetin with blank &DOMAINCODE.&CHGORCC.CD and &DOMAINCODE.&CHGORCC.IND variables added.;
      
   %end; /* end-else on CRIT or DEMO parameters not passed. */
   
   /*
   / For change from baseline, add baseline to output data set.
   /----------------------------------------------------------------------------*/
   
   %if &chgorcc ne CC %then
   %do;
      data %unquote(&dsetout);
         set %unquote(&dsetout) &prefix._base;
      run;
   %end;
  
   /*
   / AJC001: Call macro chkboundvals for precision checking
   /----------------------------------------------------------------------------*/

   %let l_idvars=%tu_chkvarsexist(&dsetout, studyid subjid &DOMAINCODE.testcd &DOMAINCODE.test vsposcd vspos visitnum visit ptmnum ptm &DOMAINCODE.dt &DOMAINCODE.acttm ,Y);
   
   %tu_chkboundvals(dsetin=&dsetout,   
                    valuevar=&domaincode.stresn,
                    compvars=&domaincode.&l_standard.&chgorcc.LO &domaincode.&l_standard.&chgorcc.HI,     
                    obsidvars= &l_idvars,   
                    criteria=6,    
                    dsetout = rfmtdir.&domaincode._&chgorcc._chkboundvals
                   );                

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
  
   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
    
%mend tu_chgccfg;

