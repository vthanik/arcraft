/******************************************************************************* 
|
| Program Name: tu_adsuppjoin.sas
|
| Macro Version: 2 Build 1
|
| Program Purpose: Joins SDTM.xx domain with with its SDTM.SUPPxx based on QNAM, USUBJID  and/or IDVAR/IDVARVAL values
|
| SAS Version: 9.1.3
|
| Created By:      Ashwin Venkat(va755193)/Lee S (ljs21463)
| 
| Date:            31-Dec-2012
|
| Macro Design:    Procedure Style
|
|******************************************************************************* 
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the SDTM dataset (eg:AE) for    REQ      (Blank)
|                   which the new variable is to be added  
|                   from its --SUPP dataset
|
|                   
| DSETINSUPP       Specifies the SDTM --SUPP dataset         REQ      (Blank)
|                  (Eg:SUPPAE) that contains supplementary 
|                  information  
|                   
|
| DSETOUT           Specifies the name of the output        REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name
|
|
| Output: 
|
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
|
| Nested Macros: 
| (@) tu_abort
| (@) tu_putglobals
| (@) tu_nobs
| (@) tu_tidyup
|
|
| Example :
|       %tu_adsuppjoin(dsetin=sdtm.ae,
|                     dsetinsupp=sdtm.suppae,
|                     dsetout=ardata.ae
|                     );
|******************************************************************************* 
| Change Log 
| Modified By:  Ashwin Venkat(va755193)
| Date of Modification: 4April2013
| Modification ID:  AV001
| Macro Version: 1 Build 2
| Reason For Modification: Modified the code so that SDTM.xx domain and its SDTM.SUPPxx dataset can be joined 
|			   even for multiple IDVAR value(s) (e.g.AEID,AESEQ,'') having same QNAM and also modified the logic by 
|			   transposing SDTM.SUPPxx dataset before joining with its SDTM.xx domain
|
| Modified By:             Anthony J Cooper
| Date of Modification:    04-Aug-2014
| Modification ID:         AJC001
| Macro Version:           2 Build 1
| Reason For Modification: Change request HRT0301
|			               1) proc sql join creates duplicate rows when more than
|			               one row from the SUPPxx dataset is joined to the same
|                          row in the SDTM.xx domain dataset. Update the code
|			               to loop round and join each IDVAR separately.
|                          2) Name all work datasets using &prefix.
|                          Uncomment out call to tu_tidyup
|                          Localise macro variables.
|
********************************************************************************/ 

%macro tu_adsuppjoin(dsetin=,
                     dsetinsupp=,
                     dsetout=
);
/*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 


 %local prefix; /*temp dataset prefix*/
 %local count a k tot maxlen;

 %let prefix =_join;
 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin  = %upcase(%nrbquote(&dsetin));
 %let dsetout = %upcase(%nrbquote(&dsetout));
 %let dsetinsupp = %upcase(%nrbquote(&dsetinsupp));

/* Validating DSETIN parameter */
  %if &dsetin. ne %str() %then
  %do;
    %if %sysfunc(exist(&dsetin.)) eq 0 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset %upcase("&dsetin.") which does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;
  %else
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
/* Validating DSETINSUPP  parameter */
 %if &dsetinsupp. ne %str() %then
  %do;
    %if %sysfunc(exist(&dsetinsupp.)) eq 0 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINSUPP refers to dataset %upcase("&DSETINSUPP.") which does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;
  %else
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINSUPP is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETOUT parameter not specified.  */

 
 /*
 / ------Check if DOMAIN and RDOMAIN variables are matching-------/
 / AJC001: Use &prefix._ to name datasets 
 */

 %IF &g_abort ne 1 %then 
 %do;
 	proc sort data=&dsetin(keep=domain) nodupkey out=&prefix._a;
 	by domain;
 	run;
 	
 	proc sort data=&dsetinsupp(keep=rdomain) nodupkey out=&prefix._b;
 	by rdomain;
 	run;
 	
 	proc sql noprint;
 			create table &prefix._chk as
 			select distinct a.domain , b.rdomain
 			from  &prefix._a a,  &prefix._b b
 			where a.domain = b.rdomain;
 	quit;
 	
 	%if &sqlobs =0 %then 
 	%do;
 		%put %str(RTE)RROR: DOMAIN and  --SUPP dataset are not related.;
 		%let g_abort=1;
 	%end;

 %end;	

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
    %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  Specified values for DSETIN and DSETOUT parameters are the same.  */


 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/


/*
/ CHECK FOR MISSING IDVARVAL OR IDVAR 
/-----------------------------------------------------------------------------*/

 proc sql noprint;
 	create table &prefix.missub as 
 		select distinct sub.usubjid, sub.idvarval, sub.idvar 
 		from &dsetinsupp sub
 		where (missing(idvarval) + missing(idvar) = 1)
 		order by sub.usubjid;
 quit;

/* Count the number of issues if any to process */
 
 %let count = %tu_nobs(&prefix.missub);
 
 %if %eval(&count) >=1 %then %do;
 	
	proc sql noprint;
		select usubjid 
			into :subj1 - :subj&count
			from &prefix.missub;
	quit;

	 %do a=1 %to %eval(&count);
		%put %str(RTW)ARNING: USUBJID &&subj&a has missing IDVAR/IDVARVAL,--SUPP will not be merged for this SUBJID ;
	 %end;

 %end;
 
/*
/ AV001: Modified the code so that SDTM.xx domain and its SDTM.SUPPxx dataset can be joined 
/ even for multiple IDVAR value(s) (e.g.AEID,AESEQ,'') having same QNAM and also modified the logic by transposing  
/ SDTM.SUPPxx dataset before joining with its SDTM.xx domain
/ ----------------------------------------------------------------------------*/
/*Count distinct IDVAR value(s) from SDTM.SUPPxx dataset to use for looping */
 
 proc sort data = &dsetinsupp nodupkey out=&prefix._distinct;
  by idvar;
 run;
 
 proc sql noprint;
	select trim(left(put((count(idvar) + nmiss(idvar)),best.))) 
		into :tot
		from  &prefix._distinct;
 quit;
  
/* Put distinct IDVAR value(s) from SDTM.SUPPxx dataset into macro variables */

         
 proc sql noprint;
 	select idvar 
		into :id1-:id&tot
		from  &prefix._distinct;	
 quit;
 

/* Create macro variables for vartype of distinct IDVAR(s) */
/*(Code taken from the previous version)*/
	 
 %do k=1 %to &tot;	
	%if %length(&&id&k) ne 0 %then %do;
            	data _null_;
                 set &dsetin;
                 	call symput("vartyp&k",vtype(&&id&k));
                	stop;
                run;
        %end;                
 %end;
 
 /*
 / AJC001: Loop around each IDVAR separately and join SDTM.xx and
 / transposed SDTM.SUPPxx dataset
 /----------------------------------------------------------------------------*/

 data &prefix._dsetin;
   set &dsetin.;
 run;
    
 %do k=1 %to &tot;

    /* Transpose SDTM.SUPPxx datset for QVAL variable before joining with SDTM.xx dataset */

    proc sort data = &dsetinsupp out=&prefix._supp;
      where idvar="&&id&k";
      by studyid rdomain usubjid idvar idvarval;
    run;
    
    proc transpose data=&prefix._supp out = &prefix._supp1(drop=_name_ _label_);
      by studyid rdomain usubjid idvar idvarval ;
      var qval;
      id qnam;
      idlabel qlabel;
    run;

    /* Prepare SUPPxx dataset for join with SDTM.xx dataset */

    %if %length(&&id&k) ne 0 %then %do;
	   %if &&vartyp&k = C %then %do;
          proc sql noprint;
            select max(length(idvarval)) into: maxlen
            from &prefix._supp1
            ;
          quit;
       %end;
    %end;
  
    data &prefix._supp_subset;
      set &prefix._supp1 (rename=(rdomain=domain));
  	  %if %length(&&id&k) ne 0 %then %do;
  	     %if &&vartyp&k = N %then  %do;
    	    &&id&k=input(idvarval, best.);
  	     %end;
  	     %else %do;
            length &&id&k $&maxlen.; 
    	    &&id&k=idvarval;
         %end;
  	  %end;
      drop idvar:;
    run;

    proc sort data=&prefix._dsetin;
      by studyid domain usubjid &&id&k;
    run;
    
    proc sort data=&prefix._supp_subset;
      by studyid domain usubjid &&id&k;
    run;
    
    data &prefix._dsetin;
      merge &prefix._dsetin (in=a) &prefix._supp_subset;
      by studyid domain usubjid &&id&k;
      if a;
    run;

 %end;

/*----------------------------------------------------------------------------*/ 

 data &dsetout;
  set &prefix._dsetin;	
 run;
    
/*
 / Delete temporary datasets used in this macro.      
 / AJC001: Uncomment out call to tu_tidyup
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend;                     
