/*******************************************************************************
|
| Macro Name:      tu_nrfg
|
| Macro Version:   6 build 1
|
| SAS Version:     9.4
|
| Created By:      Mark Luff
|
| Date:            21-May-2004
|
| Macro Purpose:   Normal range flagging
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETIN          Specifies the dataset for which      REQ      (Blank)
|                 Normal Range lab flagging needs 
|                 to be done.
|                 Valid values: valid dataset name     
|
| DSETOUT         Specifies the name of the output     REQ      (Blank)
|                 dataset to be created.
|                 Valid values: valid dataset name
|
| NRDSET          Specifies the SI dataset which       OPT      dmdata.nr
|                 contains the normal range information.
|
| DEMODSET        SI Demography dataset.               OPT      dmdata.demo
|                 
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &NRDSET            Opt      Parameter specified dataset
| &DEMODSET          Opt      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_chkvarsexist
|(@) tu_abort
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|(@) tu_chkboundvals
|
| Example:
|    %tu_nrfg(
|         dsetin  = _lab1,
|         dsetout = _lab2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     10-Jan-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  1. Modified two RTWARNING messages
|                           2. Merge &NRDSET by SEX only when SEX is in &NRDSET.
|------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     10-Dec-2005
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  Requested by change request HRT0079 
|                           1. Check that if given, &nrdset should exist and  
|                              &demodset should be given
|                           2. Check that if given, &demodset should exist.
|                           3. If both &NRDSET and &DEMODSET are blank, write an 
|                              RTNOTE to log to specify that Normal Range flags
|                              will be generated using the normal ranges 
|                              specified in the &dsetin dataset
|------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     12-Nov-2007
| New version/draft number: 3/1
| Modification ID:          YW003
| Reason For Modification:  1. Legalizing data set options for data set parameter  
|                              &dsetin, &dsetout, &nrdset, and &demodset - HRT0184  
|                           2. When merging normal range to input data set, taken  
|                              LBFAST as another by-variable, if LBFAST exists in  
|                              both &nrdset and &dsetin:
|                              a. If matched LBFAST is found, take normal range  
|                                 from &nrdset for matched records
|                              b. If matched LBFAST is not found, take normal  
|                                 range from &nrdset where LBFAST is missing, but  
|                                 other by-variables are matched
|                           3. If BIRTHDT does not exist in &DEMODSET, use AGE
|                              variables (AGEDY, AGEWK, AGEMO, AGEYR) in
|                              &DEMODSET to get normal range
|------------------------------------------------------------------------------
| Modified By:              Shan Lee
| Date of Modification:     24-Apr-2009
| New version/draft number: 4/1
| Modification ID:          SL001
| Reason For Modification:  HRT0219 - When deriving the _AGE variables, in 
|                           addition to checking that BIRTHDT does not exist,
|                           use the LBAGE variables in the situation where
|                           BIRTHDT does exist but all values are missing.
|------------------------------------------------------------------------------
| Modified By:              Shan Lee
| Date of Modification:     27-Apr-2009
| New version/draft number: 4/2
| Modification ID:          SL002
| Reason For Modification:  Additional changes requested in email from
|                           Tony Cooper: an (RTN)OTE should be generated when
|                           all values of LBFAST in the NR dataset are missing,
|                           but previously this message was generated regardless
|                           of whether or not LBFAST was missing.
|                           When the LAB and NR data is joined, a comma is 
|                           required in the ORDER BY clause when LBFAST is used.
|------------------------------------------------------------------------------
| Modified By:              Khilit Shah
| Date of Modification:     29-sep-2009
| New version/draft number: 5/1
| Modification ID:          KS001
| Reason For Modification:  HRT0235 - Round the values of lborresn, lbornrlo and 
|                           lbornrhi just prior to determining the normal range flag
|                           If the lab value is right on the edge of the normal range 
|                           then normal range flagging may not be done correctly due 
|                           to the way the underlying values were stored
|******************************************************************************
| Modified By:              Anthony J Cooper
| Date of Modification:     25-May-2018
| New version/draft number: 6 build 1
| Modification ID:          AJC001
| Reason For Modification:  Add call to utility macro tu_chkboundvals which will flag
|                           observations where specified value variable (VALUEVAR) is 
|                           deemed to be close to a boundary value (COMPVARS) based on
|                           a level of accuracy (CRITERIA). The level of accuracy is 
|                           fixed at 10**-6 (CRIETRIA=6). An output SAS dataset with 
|                           naming convention LB_NR_chkboundvals will be created.
*******************************************************************************/
%macro tu_nrfg (
     dsetin   = ,              /* Input dataset name */
     dsetout  = ,              /* Output dataset name */
     nrdset   = DMDATA.NR,     /* Normal range dataset name */
     demodset = DMDATA.DEMO    /* Demography dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 6 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin   = %nrbquote(&dsetin);
 %let dsetout  = %nrbquote(&dsetout);
 %let nrdset   = %nrbquote(&nrdset);
 %let demodset = %nrbquote(&demodset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_NRFG: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_NRFG: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if &dsetin ne and %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_NRFG: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;
 
 /*
 / YW002: If given, &nrdset should exist and &demodset should be given
 /----------------------------------------------------------------------------*/
 
 %if &nrdset ne %then
 %do;
    %if %sysfunc(exist(%qscan(&nrdset, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_NRFG: The dataset NRDSET(=&nrdset) does not exist.;
       %let g_abort=1;   
    %end;
    %if &demodset eq %then
    %do;
       %put %str(RTE)RROR: TU_NRFG: Normal range dataset NRDSET(=&nrdset) is given, but Demo data set DEMODSET is blank;
       %let g_abort=1;   
    %end; 
 %end; /* %if &nrdset ne */ 
 
 /*
 / YW002: If given, &demodset should exist. 
 / If &demodset is given and &nrdset is not, write a RTWARNING to log
 /----------------------------------------------------------------------------*/
   
 %if &demodset ne %then
 %do;
    %if %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_NRFG: The dataset DEMODSET(=&demodset) does not exist.;
       %let g_abort=1;   
    %end;
    %if &nrdset eq %then
    %do;
       %put %str(RTW)ARNING: TU_NRFG: The dataset DEMODSET(=&demodset) is given and it implies that a merge with a Normal Range dataset is required, but NRDSET is blank;        
    %end; 
 %end; /* %if &nrdset ne */
  

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: TU_NRFG: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;
 
 /* YW002: If both &NRDSET and &DEMODSET are blank, write an RTNOTE to log to 
 /  specify that  Normal Range flags will be generated using the normal ranges 
 /  specified in the &dsetin dataset
 /----------------------------------------------------------------------------*/
 
 %if ( &nrdset eq ) or ( &demodset eq ) %then
 %do;
    %put %str(RTN)OTE: TU_NRFG: NRDSET or DEMODSET is not given and normal range flags will be generated using the normal ranges specified in the &dsetin dataset.;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
 
 %local prefix lbfastvar age_is_used nrhiage_nonmissing nrloage_nonmissing 
        nrhiage_exist nrloage_exist lbfast_nonmissing is_birthdt l_idvars;
 
 %let prefix = _nrfg;   /* Root name for temporary work datasets */
 %let lbfastvar=__lbfast; /* If lbfast be used in merge. If it is blank, lbfast will not be used */
 %let nrhiage_nonmissing=0;
 %let nrloage_nonmissing=0;
 %let nrhiage_exist=0;
 %let nrloage_exist=0;
 %let age_is_used=1;  
 
 %if ( &nrdset ne ) and ( &demodset ne ) %then
 %do;
    /* NR and DEMO dataset parameters passed */
    
    /*
    / Categorise lab records into those without normal ranges and those
    / with normal ranges.
    /----------------------------------------------------------------------*/
   
    data &prefix._labwonr (drop = lbornrlo lbornrhi) &prefix._labwnr;
         set %unquote(&dsetin);
         if ( lbornrlo eq . ) and ( lbornrhi eq . ) then output &prefix._labwonr;
         else output &prefix._labwnr;
    run;
    
    data &prefix._demoexist;
       if 0 then set %unquote(&demodset);
    run;   
              
    data &prefix._nrexist;
       if 0 then set %unquote(&nrdset);
    run;  
        
    /*  
    /  Check if NRHIAGE and NRLOAGE exist and are populated
    /----------------------------------------------------------------------*/
    
    %if %tu_nobs(&prefix._labwonr) ge 1 %then
    %do;                   
       %if %tu_chkvarsexist(&prefix._nrexist, nrhiage) eq %then
       %do;
          %let nrhiage_exist=1;
 
          proc sql noprint;
             select count(*) into :nrhiage_nonmissing 
             from &prefix._nrexist
             where not missing(nrhiage);                   
          quit;             
       %end;
                 
       %if %tu_chkvarsexist(&prefix._nrexist, nrloage) eq %then
       %do;
          %let nrloage_exist=1;

          proc sql noprint;
             select count(*) into :nrloage_nonmissing 
             from &prefix._nrexist
             where not missing(nrloage);                   
          quit;             
       %end;  
       
       %let age_is_used=0;                 
       
       %if %tu_chkvarsexist(&prefix._demoexist, birthdt) ne %then
       %do;              
          %let age_is_used=0;
          %if %tu_chkvarsexist(&prefix._labwonr, LBAGE   ) eq %then  %let age_is_used=1;
          %if %tu_chkvarsexist(&prefix._labwonr, LBAGEMO ) eq %then  %let age_is_used=1;
          %if %tu_chkvarsexist(&prefix._labwonr, LBAGEWK ) eq %then  %let age_is_used=1;
          %if %tu_chkvarsexist(&prefix._labwonr, LBAGEDY ) eq %then  %let age_is_used=1;
          %if ( &nrhiage_nonmissing or &nrloage_nonmissing ) and ( not &age_is_used ) %then 
          %do;          
             %put %str(RTW)ARNING: TU_NRFG: NRLOAGE or NRHIAGE is populated in NRDSET (=&nrdset), but BIRTHDT does not exist in DEMODSET(=&demodset),;
             %put %str(RTW)ARNING: and LBAGE, LBAGEMO, LBAGEWK and LBAGEYR do not exist in DSETIN(=&DSETIN).; 
             %let age_is_used=0;
          %end;   
          %else %if not &age_is_used %then %let age_is_used=2;   
          %else %do;
             %put %str(RTN)OTE: TU_NRFG: NRLOAGE or NRHIAGE is populated in NRDSET (=&nrdset), but BIRTHDT does not exist in DEMODSET(=&demodset).;
             %put %str(RTN)OTE: TU_NRFG: LBAGE, LBAGEMO, LBAGEWK or LBAGEYR in DSETIN(=&DSETIN) will be used in deriving the normal ranges.; 
             %let age_is_used=1;      
          %end;
       %end;
         
       %else %if ( not &nrhiage_exist ) or ( not &nrloage_exist ) %then
       %do;          
          %put %str(RTW)ARNING: TU_NRFG: NRLOAGE or NRHIAGE does not exist in NRDSET (=&nrdset), but BIRTHDT exists in DEMODSET(=&demodset).; 
          %let age_is_used=0;
       %end; 
       %else %let age_is_used=1;  
        
       %if not &age_is_used %then
       %do;      
          data &prefix._labnr;
            set %unquote(&dsetin);
          run;

          %put %str(RTW)ARNING: TU_NRFG: &dsetout is set to &dsetin.;
       %end;
    %end; /* %if %tu_nobs(&prefix._labwonr) ge 1 */  
         
    /*
    / Perform NR lookup on lab records without normal ranges.
    /----------------------------------------------------------------------*/        

    %if %tu_nobs(&prefix._labwonr) ge 1 %then
    %do;
       /* Lab records without normal ranges exist */
          
       /*
       / SL001 - If BIRTHDT does not exist in DEMODSET, or if it exists but
       / is not populated in any observation, then use LBAGE, LBAGEMO,
       / LBAGEWK and LBAGEDY to populate _AGEYR, _AGEMO, _AGEWK and _AGEDY
       / respectively.
       /-------------------------------------------------------------------*/              
       
       %let is_birthdt = 0;

       %if %length(%tu_chkvarsexist(&prefix._demoexist, birthdt)) eq 0 %then
       %do;            
         data _null_;
           set %unquote(&demodset) end = eof;
           retain is_birthdt 0;
           if birthdt ne . then is_birthdt = 1;
           if eof and is_birthdt then call symput('is_birthdt', '1');
         run;
       %end;

       %if not &is_birthdt %then
       %do;
            
          proc sql noprint;
               create table &prefix._labwonr_bdt as
               select a.*, b.sex as _sex
               from &prefix._labwonr as a
                    left join %unquote(&demodset) as b
               on  a.studyid  eq  b.studyid and
                   a.subjid   eq  b.subjid ;
          quit;
            
          data &prefix._labwonr_age; 
             set &prefix._labwonr_bdt;
             _ageyr=.;
             _agemo=.; 
             _agewk=.; 
             _agedy=.;
             %if %tu_chkvarsexist(&prefix._labwonr, LBAGE )  eq %then _ageyr=LBAGE   ;;
             %if %tu_chkvarsexist(&prefix._labwonr, LBAGEMO) eq %then _agemo=LBAGEMO ;;
             %if %tu_chkvarsexist(&prefix._labwonr, LBAGEWK) eq %then _agewk=LBAGEWK ;;
             %if %tu_chkvarsexist(&prefix._labwonr, LBAGEDY) eq %then _agedy=LBAGEDY ;;               
             uniq_id = _n_;
          run;
                          
       %end; /* BIRTHDT does not exist in &DEMODSET, or it exists but is not populated in every observation. */
 
       /*
       / Retrieve birth date for calculation of sample age, and sex.
       /-------------------------------------------------------------------*/
  
       %else %do;
          
          proc sql noprint;
               create table &prefix._labwonr_bdt as
               select a.*, b.sex as _sex, b.birthdt as _birthdt
               from &prefix._labwonr as a
                    left join %unquote(&demodset) as b
               on  a.studyid  eq  b.studyid and
                   a.subjid   eq  b.subjid ;
          quit;
       
          /*
          / Sample age calculated in all possible age units.
          /-------------------------------------------------------------------*/
       
          data &prefix._labwonr_age (drop = _birthdt);
               set &prefix._labwonr_bdt;
       
               if _birthdt ne . and lbdt ne . then do;
       
                  _ageyr  = intck('year',_birthdt,lbdt) -
                            ( month(lbdt) lt month(_birthdt) or
                            (month(lbdt) eq month(_birthdt) and day(lbdt) lt day(_birthdt)) );
       
                  _agemo  = (year(lbdt) - year(_birthdt)) * 12
                           + (month(lbdt)-month(_birthdt)-1)
                           + (day(lbdt) ge day(_birthdt));
       
                  _agewk  = int((lbdt-_birthdt)/7);
       
                  _agedy  = lbdt-_birthdt;
       
               end;
       
               /*
               / Mark records with a unique identifier as merging with NR
               / panel can produce duplicated records with different NR
               / effective start dates. Record with latest effective start
               / date will be taken.
               /--------------------------------------------------------------*/
       
               uniq_id = _n_;
          run;
       %end; /* BIRTHDT exists in &DEMODSET, and is populated in at least one observation. */   
       
       %if %tu_chkvarsexist(&prefix._labwonr_age, lbfast) ne %then %let lbfastvar=;
       %if %tu_chkvarsexist(&prefix._nrexist, lbfast) ne %then %let lbfastvar=;              
       
       %if %nrbquote(&lbfastvar) ne %then
       %do;
          /*
          / SL002 - count the number of observations with non-missing LBFAST in the NR dataset.
          /-----------------------------------------------------------------------------------*/

          %let lbfast_nonmissing=0;
          proc sql noprint;
             select count(*) into:lbfast_nonmissing
             from %unquote(&nrdset) 
             where not missing(lbfast);
          quit;
          %if &lbfast_nonmissing eq 0 %then 
          %do;
             %let lbfastvar=;       
             %put %str(RTN)OTE: TU_NRFG: No non-missing LBFAST value is in NRDSET(=&nrdset). LBFAST will not be used to derive normal range.;
          %end;
       %end;
       
       %if %nrbquote(&lbfastvar) ne %then
       %do;
          %let lbfast_nonmissing=0;
          proc sql noprint;
             select count(*) into:lbfast_nonmissing
             from &prefix._labwonr_age
             where not missing(lbfast);
          quit;
          %if &lbfast_nonmissing eq 0 %then 
          %do;
             %let lbfastvar=;       
             %put %str(RTN)OTE: TU_NRFG: No non-missing LBFAST value is in DSETIN(=&dsetin). LBFAST will not be used to derive normal range.;
          %end;
       %end;             
  
       proc sql;
            create table &prefix._labwonr_nr (drop = _ageyr _agemo _agewk _agedy _sex) as
            select a.*,
                   %if %nrbquote(&lbfastvar) ne %then b.lbfast as &lbfastvar,;
                   b.lborunit as nr_unit,
                   b.lbornrhi,
                   b.lbornrlo,
                   b.nrstdt
            from &prefix._labwonr_age as a
                 left join %unquote(&nrdset) as b
            on  a.lbidcd  eq  b.lbidcd
            and a.lbtestcd  eq  b.lbtestcd
            and (a.lborunit  eq  b.lborunit or a.lborunit is null)
            
            /*
            / YW001: Sex is not required variable in NR data set.
            / Merge by SEX only when SEX is in NR data set.
            /-----------------------------------------------------*/   
            %if %tu_chkvarsexist(&prefix._nrexist, SEX) eq %then
            %do;
               and (b.sex  eq  ' ' or a._sex  eq  b.sex)
            %end;
            
            %if %nrbquote(&lbfastvar) ne %then
            %do;
               and ( missing(b.lbfast) or b.lbfast eq a.lbfast ) 
            %end;
            
            and b.nrstdt le a.lbdt
            and ( (b.nrloage  eq  . and b.nrhiage  eq  .)
               or ( b.nrageu eq '1'
                    and (b.nrloage  eq  . or a._ageyr ge b.nrloage)
                    and (b.nrhiage  eq  . or a._ageyr le b.nrhiage) )
               or ( b.nrageu eq '2'
                    and (b.nrloage  eq  . or a._agemo ge b.nrloage)
                    and (b.nrhiage  eq  . or a._agemo le b.nrhiage) )
               or ( b.nrageu eq '3'
                    and (b.nrloage  eq  . or a._agewk ge b.nrloage)
                    and (b.nrhiage  eq  . or a._agewk le b.nrhiage) )
               or ( b.nrageu eq '4'
                    and (b.nrloage  eq  . or a._agedy ge b.nrloage)
                    and (b.nrhiage  eq  . or a._agedy le b.nrhiage) )
                )

            /*
            / SL002 - ensure that correct syntax (i.e. comma) is
            / used in the ORDER BY clause when LBFASTVAR is not blank.
            /--------------------------------------------------------*/   
 
            order by a.uniq_id, b.nrstdt
                     %if %length(&lbfastvar) gt 0 %then %str(, &lbfastvar);
            ;
       quit;
  
       data &prefix._labwonr_uniq (drop = uniq_id nrstdt nr_unit &lbfastvar);
            set &prefix._labwonr_nr;
            by uniq_id nrstdt &lbfastvar;
  
            /* Record with latest effective start date of NR taken */
            if last.uniq_id;
  
            /* NR units copied to lab record */
            if lborunit  eq  ' ' then lborunit = nr_unit;
       run;
  
       data &prefix._labnr;
            set &prefix._labwnr &prefix._labwonr_uniq;
       run;
  
       %put %str(RTN)OTE: TU_NRFG: Normal Ranges have been added from NRDSET(=&nrdset) to lab records, which do not have normal range.;

    %end;
   
    %else
    %do;
       /* Lab records without normal ranges do not exist */
       
       data &prefix._labnr;
            set &prefix._labwnr;
       run;
       
       %put %str(RTN)OTE: TU_NRFG: Lab records without normal ranges do not exist.;
    %end;

 %end;  /* end-if on NR and DEMO dataset parameters passed */

 %else
 %do;
    /* NR or DEMO dataset parameter not passed */

    data &prefix._labnr;
         set %unquote(&dsetin);
    run;
    
 %end;

 /*
 / Assign normal range flag (based on unconverted lab values).
 /----------------------------------------------------------------------------*/

 data %unquote(&dsetout);
      set &prefix._labnr;
      length lbnrind $40;

     /* KS001: Round the values of lborresn, lbornrlo and lbornrhi just prior to 
     |         determining the normal range flag.
     /----------------------------------------------------------------------------*/
      if lbornrlo ne . then lbornrlo = round (lbornrlo, .00000001);
      if lbornrhi ne . then lbornrhi = round (lbornrhi, .00000001);
      if lborresn ne . then lborresn = round (lborresn, .00000001);

      if lbornrlo  eq  . and lbornrhi  eq  . then
      do;
         lbnrcd  = 'M';
         lbnrind = 'Missing both reference ranges';
      end;
      else if lborresn  eq  . then
      do;
         lbnrcd  = 'U';
         lbnrind = 'Missing unconverted lab value';
      end;
      else if lborresn lt lbornrlo and lbornrlo ne . then
      do;
         lbnrcd  = 'L';
         lbnrind = 'Low';
      end;
      else if lborresn gt lbornrhi and lbornrhi ne . then
      do;
         lbnrcd  = 'H';
         lbnrind = 'High';
      end;
      else
      do;
         lbnrcd  = 'I';
         lbnrind = 'Normal';
      end;
 run;

 /*
 / AJC001: Call macro chkboundvals for precision checking
 /----------------------------------------------------------------------------*/
 %let l_idvars=%tu_chkvarsexist(&dsetout, studyid subjid lbtestcd lbtest visitnum visit ptmnum ptm lbdt lbacttm ,Y);
   
 %tu_chkboundvals(dsetin=&dsetout,   
                  valuevar=lborresn,     
                  compvars=lbornrlo lbornrhi,     
                  obsidvars= &l_idvars,   
                  criteria=6,    
                  dsetout = rfmtdir.lb_nr_chkboundvals
                 );                

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_nrfg;
