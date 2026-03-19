/*******************************************************************************
|
| Macro Name:      tu_bsfg
|
| Macro Version:   4 build 1
|
| SAS Version:     9.4
|
| Created By:      Eric Simms
|
| Date:            23-Jun-2004
|
| Macro Purpose:   Change from baseline flagging
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
| LABCRITDSET     Specifies the SI dataset which       OPT      dmdata.labcrit
|                 contains the lab flagging criteria 
|                 information. 
|
| DEMODSET        SI Demography dataset.               OPT      dmdata.demo
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &LABCRITDSET       Opt      Parameter specified lab flagging criteria dataset
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
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_tidyup
|(@) tu_chkboundvals
|
| Example:
|    %tu_bsfg(
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
| Reason For Modification:  Modified four RTWARNING messages
|
| Modified By:              Yongwei Wang                       
| Date of Modification:     04-Mar-2005                        
| New version/draft number: 1/3                              
| Modification ID:          YW002
| Reason For Modification:  Added variable LBCHGLO and LBCHGHI in, even though
|                           they can not be derived
|
| Modified By:              Shan Lee 
| Date of Modification:     17-Sep-2007
| New version/draft number: 2 build 1
| Modification ID:          SL001
| Reason For Modification:  1. Allow dataset options to be specified for input and
|                              output datasets - HRT0184
|                           2. If BIRTHDT does not exist in &DEMODSET, use 
|                              LBAGEDY, LBAGEWK, LBAGEMO, LBAGEYR in &DSETIN to 
|                              get baseline range
|
| Modified By:              Shan Lee 
| Date of Modification:     24-Apr-2009
| New version/draft number: 3 build 1
| Modification ID:          SL002
| Reason For Modification:  HRT0219 - When deriving the _AGE variables, in 
|                           addition to checking that BIRTHDT does not exist,
|                           use the LBAGE variables in the situation where
|                           BIRTHDT does exist but all values are missing.
|******************************************************************************
| Modified By:              Anthony J Cooper
| Date of Modification:     25-May-2018
| New version/draft number: 4 build 1
| Modification ID:          AJC001
| Reason For Modification:  Add call to utility macro tu_chkboundvals which will flag
|                           observations where specified value variable (VALUEVAR) is 
|                           deemed to be close to a boundary value (COMPVARS) based on
|                           a level of accuracy (CRITERIA). The level of accuracy is 
|                           fixed at 10**-6 (CRIETRIA=6). An output SAS dataset with 
|                           naming convention LB_CHG_chkboundvals will be created.
*******************************************************************************/

%macro tu_bsfg (
     dsetin   = ,                    /* Input dataset name */
     dsetout  = ,                    /* Output dataset name */
     labcritdset = DMDATA.LABCRIT,   /* Lab flagging criteria dataset name */
     demodset    = DMDATA.DEMO       /* Demography dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 4 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin      = %nrbquote(&dsetin);
 %let dsetout     = %nrbquote(&dsetout);
 %let labcritdset = %nrbquote(&labcritdset);
 %let demodset    = %nrbquote(&demodset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_BSFG: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_BSFG: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for existing datasets.
 / Allow dataset options for DSETIN. SL001
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_BSFG: The dataset DSETIN (=&dsetin) does not exist.;  /* YW001:*/
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / Ignore dataset options when comparing DSETIN and DSETOUT - SL001
 /----------------------------------------------------------------------------*/

 %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
 %do;
    %put %str(RTN)OTE: TU_BSFG: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;


 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix age_is_used fghiage_nonmissing fgloage_nonmissing fghiage_exist fgloage_exist is_birthdt l_idvars;
 %let prefix = _bsfg;   /* Root name for temporary work datasets */
 %let fghiage_nonmissing=0;
 %let fgloage_nonmissing=0;
 %let fghiage_exist=0;
 %let fgloage_exist=0;
 %let age_is_used=1;           

 %if &labcritdset ne and &demodset ne %then
 %do;
 
    /*
    / LABCRIT and DEMO dataset parameters passed.
    /----------------------------------------------------------------------*/

    %if %sysfunc(exist(%qscan(&labcritdset, 1, %str(%()))) and %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) %then
    %do;

       /*
       / LABCRIT and DEMO datasets exist.
       /----------------------------------------------------------------------*/

       data &prefix._labcrit;
         set %unquote(&labcritdset);
         if fgtyp = 'F2';
       run;

       /*  
       /  Check if FGHIAGE and FGLOAGE exist and are populated
       /----------------------------------------------------------------------*/
      
       %if %tu_nobs(&prefix._labcrit) ge 1 %then
       %do;    
          data &prefix._demoexist;
             if 0 then set %unquote(&demodset);
          run;
          
          data &prefix._dsetinexist;
             if 0 then set %unquote(&dsetin);
          run;                    
          
          %if %tu_chkvarsexist(&prefix._labcrit, fghiage) eq %then
          %do;
             %let fghiage_exist=1;
 
             proc sql noprint;
                select count(*) into :fghiage_nonmissing 
                from &prefix._labcrit
                where not missing(fghiage);                   
             quit;             
          %end;
                    
          %if %tu_chkvarsexist(&prefix._labcrit, fgloage) eq %then
          %do;
             %let fgloage_exist=1;

             proc sql noprint;
                select count(*) into :fgloage_nonmissing 
                from &prefix._labcrit
                where not missing(fgloage);                   
             quit;             
          %end;  
          
          %let age_is_used=0;                 
          
          %if %tu_chkvarsexist(&prefix._demoexist, birthdt) ne %then
          %do;              
             %let age_is_used=0;
             %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGE   ) eq %then  %let age_is_used=1;
             %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEMO ) eq %then  %let age_is_used=1;
             %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEWK ) eq %then  %let age_is_used=1;
             %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEDY ) eq %then  %let age_is_used=1;
             %if ( &fghiage_nonmissing or &fgloage_nonmissing ) and ( not &age_is_used ) %then 
             %do;          
                %put %str(RTW)ARNING: TU_BSFG: FGLOAGE or FGHIAGE is populated in LABCRITDSET (=&labcritdset), but BIRTHDT does not exist in DEMODSET(=&demodset),;
                %put %str(RTW)ARNING: TU_BSFG: and LBAGE, LBAGEMO, LBAGEWK and LBAGEYR do not exist in DSETIN(=&DSETIN).; 
                %let age_is_used=0;
             %end;      
             %else %if not &age_is_used %then %let age_is_used=2;      
             %else %do;
                %put %str(RTN)OTE: TU_BSFG: FGLOAGE or FGHIAGE is populated in LABCRITDSET (=&labcritdset), but BIRTHDT does not exist in DEMODSET(=&demodset).;
                %put %str(RTN)OTE: TU_BSFG: LBAGE, LBAGEMO, LBAGEWK or LBAGEYR in DSETIN(=&DSETIN) will be used in deriving change from baseline ranges.; 
                %let age_is_used=1;      
             %end;
          %end;
            
          %else %if ( not &fghiage_exist ) or ( not &fgloage_exist ) %then
          %do;          
             %put %str(RTW)ARNING: TU_BSFG: FGLOAGE or FGHIAGE does not exist in LABCRITDSET (=&labcritdset), but BIRTHDT exists in DEMODSET(=&demodset).; 
             %let age_is_used=0;
          %end; 
          %else %let age_is_used=1;  
           
          %if not &age_is_used %then
          %do;      
             data %unquote(&dsetout);
                 set %unquote(&dsetin);
                 length lbchgind $40;
             
                 if lbchgcd not in ('P', 'R') then
                 do;
                    lbchgcd  = ' ';
                    lbchgind = ' ';
                 end;
                 if missing(lbchglo) then lbchglo=.;
                 if missing(lbchghi) then lbchghi=.;                      
             run;
                          
             %put %str(RTW)ARNING: TU_BSFG: &dsetout is set to &dsetin with blank LBCHGCD and LBCHGIND variables added.;              
          %end;
       %end; /* %if %tu_nobs(&prefix._labcrit) ge 1 */        

       %if ( %tu_nobs(&prefix._labcrit) ge 1 ) and ( &age_is_used ) %then
       %do;

          /*
          / There is F2 criteria.
          /----------------------------------------------------------------------*/
                      
	  /*
	  / SL002 - If BIRTHDT does not exist in DEMODSET, or if it exists but
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
                                                  
             data &prefix._labbs2;
                set %unquote(&dsetin);                
                _ageyr=.;
                _agemo=.; 
                _agewk=.; 
                _agedy=.;
                %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGE )  eq %then _ageyr=LBAGE   ;;
                %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEMO) eq %then _agemo=LBAGEMO ;;
                %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEWK) eq %then _agewk=LBAGEWK ;;
                %if %tu_chkvarsexist(&prefix._dsetinexist, LBAGEDY) eq %then _agedy=LBAGEDY ;;               
                uniq_id = _n_;
             run;
                            
          %end; /* BIRTHDT does not exist in &DEMODSET, or it exists but is not populated. */
         
          /*
          / Retrieve birth date for calculation of sample age.
          /----------------------------------------------------------------------*/
          
          %else %do;

             proc sql;
                  create table &prefix._labbs as
                  select a.*, b.birthdt
                  from %unquote(&dsetin) as a left join %unquote(&demodset) as b
                  on  a.studyid  eq  b.studyid
                  and a.subjid   eq  b.subjid ;
             quit;
            
             data &prefix._labbs2;
                  set &prefix._labbs;
                  drop birthdt;
            
                  /* Sample age calculated in all possible age units */
            
                  if birthdt ne . and lbdt ne . then
                  do;
                     _ageyr  = intck('year',birthdt,lbdt) -
                                    ( month(lbdt) lt month(birthdt) or
                                    (month(lbdt) eq month(birthdt) and day(lbdt) lt day(birthdt)) );
                     _agemo  = (year(lbdt) - year(birthdt)) * 12
                                + (month(lbdt)-month(birthdt)-1)
                                + (day(lbdt) ge day(birthdt));
                     _agewk  = int((lbdt-birthdt)/7);
                     _agedy  = lbdt-birthdt;
                  end;
            
                  /*
                  / Mark records with a unique identifier as merging with LABCRIT
                  / panel can produce duplicated records with different LABCRIT
                  / effective start dates. Record with latest effective start
                  / date will be taken.
                  /--------------------------------------------------------------*/
            
                  uniq_id = _n_;
             run;
          %end; /*  BIRTHDT exists in &DEMODSET, and is populated */

          proc sql;
               create table &prefix._labbs3 (drop = _ageyr _agemo _agewk _agedy) as
               select a.*,
                      b.algtyp,
                      b.fglo,
                      b.fghi,
                      b.fgstdt,
                      case when b.lbtestcd  eq  ' '
                           then 'N'
                           else 'Y'
                      end as bs_crit
               from &prefix._labbs2 as a left join &prefix._labcrit as b
               on  a.lbtestcd  eq  b.lbtestcd
               and (b.sex  eq  ' ' or a.sex  eq  b.sex)
               and b.fgstdt le a.lbdt
               %if &age_is_used ne 2 %then
               %do;
                  and ( (b.fgloage  eq  . and b.fghiage  eq  .)
                     or ( b.fgageu  eq  '1'
                          and (b.fgloage  eq  . or a._ageyr ge b.fgloage)
                          and (b.fghiage  eq  . or a._ageyr le b.fghiage) )
                     or ( b.fgageu  eq  '2'
                          and (b.fgloage  eq  . or a._agemo ge b.fgloage)
                          and (b.fghiage  eq  . or a._agemo le b.fghiage) )
                     or ( b.fgageu  eq  '3'
                          and (b.fgloage  eq  . or a._agewk ge b.fgloage)
                          and (b.fghiage  eq  . or a._agewk le b.fghiage) )
                     or ( b.fgageu  eq  '4'
                          and (b.fgloage  eq  . or a._agedy ge b.fgloage)
                          and (b.fghiage  eq  . or a._agedy le b.fghiage) )
                      )
               %end;
               order by a.uniq_id, b.fgstdt ;
          quit;

          data &prefix._labbs4 (drop = uniq_id fgstdt);
               set &prefix._labbs3;
               by uniq_id fgstdt;

               /* Record with latest effective start date of LABCRIT taken */
               if last.uniq_id;
          run;

          /*
          / Flag change from baseline.
          / Use drop statement, rather than dataset option, to allow dataset options
          / to be specified for DSETOUT.
          /   SL001
          /----------------------------------------------------------------------*/

          data %unquote(&dsetout);
               set &prefix._labbs4;
               length lbchgind $40;
      
               drop algtyp fglo fghi bs_crit;

               if lbchgcd not in ('P', 'R') then
               do;
                  if bs_crit  eq  'N' then 
                  do;
                     lbchgcd  = 'N';
                     lbchgind = 'No F2 criteria';
                  end;
                  else if algtyp not in ('A', 'P', 'NR') then 
                  do;
                     lbchgcd = 'M';
                     lbchgind = 'Invalid algorithm type in LABCRIT';
                  end;
                  else if lbstresn  eq  . or lbstdbl  eq  . then 
                  do;
                     lbchgcd  = 'U';
                     lbchgind = 'Missing converted lab or baseline value';
                  end;
                  else if algtyp  eq  'NR' and (lbstnrlo  eq  . or lbstnrhi  eq  .) then 
                  do;
                     lbchgcd  = 'X';
                     lbchgind = 'Missing converted normal range value';
                  end;
                  else 
                  do;
                     if algtyp  eq  'A' then
                     do;
                        lbchglo = lbstdbl - fglo;
                        lbchghi = lbstdbl + fghi;
                     end;
                     else if algtyp  eq  'P' then 
                     do;
                        lbchglo = lbstdbl * fglo;
                        lbchghi = lbstdbl * fghi;
                     end;
                     else if algtyp  eq  'NR' then 
                     do;
                        lbchglo = lbstdbl - ((lbstnrhi - lbstnrlo) * fglo);
                        lbchghi = lbstdbl + ((lbstnrhi - lbstnrlo) * fghi);
                     end;
      
                     lbchglo = round (lbchglo, .00000001);
                     lbchghi = round (lbchghi, .00000001);
      
                     if lbstresn lt lbchglo and lbchglo ne . then 
                     do;
                        lbchgcd  = 'L';
                        lbchgind = 'Low';
                     end;
                     else if lbstresn gt lbchghi and lbchghi ne . then 
                     do;
                        lbchgcd  = 'H';
                        lbchgind = 'High';
                     end;
                     else 
                     do;
                        lbchgcd  = 'I';
                        lbchgind = 'Normal';
                     end;
                  end; /* end-else: F2 flagging is possible, F2 criteria available, non-missing result, etc. */
               end;  /* end-if on lbchgcd not in ('P', 'R') */
          run;

       %end;  /* end-if on there is F2 criteria. */
       %else
       %do;

          /*
          / There is no F2 criteria.
          /----------------------------------------------------------------------*/

          data %unquote(&dsetout);
               set %unquote(&dsetin);
               length lbchgind $40;

               if lbchgcd not in ('P', 'R') then
               do;
                  lbchgcd  = 'N';
                  lbchgind = 'No F2 criteria';
               end;   
                /*YW002*/
               if missing(lbchglo) then lbchglo=.;
               if missing(lbchghi) then lbchghi=.;                             
          run;
          %put %str(RTW)ARNING: TU_BSFG: There are no F2 criteria.;

       %end; /* end-else on there is not F2 criteria. */

    %end;  /* end-if on LABCRIT and DEMO datasets exist. */
    %else
    %do;
       /* LABCRIT or DEMO dataset does not exist */

       data %unquote(&dsetout);
           set %unquote(&dsetin);
           length lbchgind $40;

           if lbchgcd not in ('P', 'R') then
           do;
              lbchgcd  = ' ';
              lbchgind = ' ';
           end;
           /*YW002*/
           if missing(lbchglo) then lbchglo=.;
           if missing(lbchghi) then lbchghi=.;                      
       run;

       %if %sysfunc(exist(%qscan(&labcritdset, 1, %str(%()))) eq 0 %then
       %do;
          %put %str(RTW)ARNING: TU_BSFG: LABCRITDSET (=&labcritdset) dataset does not exist.; /* YW001:*/
       %end;
       %if %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) eq 0 %then
       %do;
          %put %str(RTW)ARNING: TU_BSFG: DEMODSET (=&demodset) dataset does not exist.; /* YW001:*/
       %end;
              
       %put %str(RTW)ARNING: TU_BSFG: &dsetout is set to &dsetin with blank LBCHGCD and LBCHGIND variables added.; /* YW001:*/
       
    %end; /* end-else on LABCRIT or DEMO dataset does not exist. */

 %end;  /* end-if on LABCRIT and DEMO dataset parameters passed. */

 %else
 %do;
     /* LABCRIT or DEMO dataset parameter not passed */

     data %unquote(&dsetout);
         set %unquote(&dsetin);
         length lbchgind $40;

         if lbchgcd not in ('P', 'R') then
         do;
            lbchgcd  = ' ';
            lbchgind = ' ';
         end;
         /*YW002*/
         if missing(lbchglo) then lbchglo=.;
         if missing(lbchghi) then lbchghi=.;  
     run;

     %if &labcritdset eq  %then
     %do;
        %put %str(RTW)ARNING: TU_BSFG: LABCRITDSET dataset parameter is blank.;
     %end;
     %if &demodset eq  %then
     %do;
        %put %str(RTW)ARNING: TU_BSFG: DEMODSET dataset parameter is blank.;
     %end;
 %end; /* end-else on LABCRIT or DEMO dataset parameter not passed. */

 /*
 / AJC001: Call macro chkboundvals for precision checking
 /----------------------------------------------------------------------------*/
 %let l_idvars=%tu_chkvarsexist(&dsetout, studyid subjid lbtestcd lbtest visitnum visit ptmnum ptm lbdt lbacttm ,Y);
   
 %tu_chkboundvals(dsetin=&dsetout,   
                  valuevar=lbstresn,     
                  compvars=lbchglo lbchghi,     
                  obsidvars= &l_idvars,   
                  criteria=6,    
                  dsetout = rfmtdir.lb_chg_chkboundvals
                 );                

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_bsfg;

