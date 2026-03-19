/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_add_dy_vars
|
| Macro Version/Build:  4 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu
|
| Date:                 08-Feb-2011 
|
| Macro Purpose:        Create --DY, --STDY & --ENDY variables in each domain, if --DTC or --STDTC or --ENDTC and RFSTDTC variables exist
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                  DESCRIPTION                                  DEFAULT           
|
|
|
|
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pst_add_dy_vars
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Deepak Sriramulu (DSS001)
| Date of Modification        : 26July2011
| New Version/Build Number    : 2 Build 1
| Description for Modification: Suppress creation of %DY variables for SE domain
| Reason for Modification     : These are not in the SE domain model, and since it is a Special Purpose domain  
|                               one can argue that the "add to any domains" rule doesn't apply.
|
| Modified By                 : Bruce Chambers (BJC001)
| Date of Modification        : 26May2012
| New Version/Build Number    : 3 Build 1
| Description for Modification: Dont drop RFSTDTC when DM domain processed
| Reason for Modification     : In-house converted data wont usually have DMDTC, but data from a CRO did
|                               and it was noted that RFSTDTC got dropped - dont drop DM.RFSTDTC.
|
| Modified By                 : Bruce Chambers (BJC002)
| Date of Modification        : 11Sep2013
| New Version/Build Number    : 4 Build 1
| Description for Modification: Allow for FAxx domains and expect the correct variable names.
| Reason for Modification     : So that DY vars are created in FA domains
|
*******************************************************************************/
%macro tu_sdtmconv_pst_add_dy_vars(
); 
  
/* BJC002 - define new DSR macro var to allow for FAxx domain variable names */  
%local domains dsn dsr dtc stdtc endtc rfstdtc dy stdy endy;
  
  proc contents data=PST_SDTM._all_ noprint nodetails 
                out=_contout(keep=memname name);
  run;
  
  /* BJC002 - allow for FAxx domain variable names */
  proc sql noprint;
   alter table _contout add domref char(21);
   update _contout a set domref=(select domref from domain_ref 
                                  where domain=a.memname);
  quit;								  
  
 /* Select domains having --DTC, --STDTC & --ENDTC variables */  

  proc sql noprint;
/* BJC002 - allow for FAxx domain variable names by adding domref var */	  
      select distinct memname, domref 
	    into
            :domains separated by ' ' , :domrefs separated by ' ' 
        from _contout 
       where substr(name,3) in ('DTC', 'STDTC', 'ENDTC') 
/* DSS001: Suppress creation of %DY variables for SE domain */		  
         and memname ne 'SE';      
  quit;

/* Check if DM domain is present before creating DY variables */

%if not %sysfunc(exist(pst_sdtm.dm)) %then %do;
%let _cmd = %str(%STR(RTN)OTE: No DM domain in this run, so no RFSTDTC therefore DY variables not created); %tu_sdtmconv_sys_message;
   %goto endmac;    
%end;

proc sort data = pst_sdtm.dm force;
  by studyid usubjid;
run;

/*  Check for each domain in a loop and populate DY variables
-----------------------------------------------------------------*/
%do x=1 %to &sqlobs;

/* Check if the date variables exists */

%let DSN = %scan(&domains,&x);
/* BJC002 - define new DSR macro var to allow for FAxx domain variable names */
%let DSR = %scan(&domrefs,&x);

/* BJC002 - replace DSN with DSR macro var for all variable (not dataset) references below here to allow for FAxx domain variable names */
%let DTC = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.DTC);
%let STDTC = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.STDTC);
%let ENDTC = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.ENDTC);
%let RFSTDTC = %tu_chkvarsexist(pst_sdtm.dm,RFSTDTC);

/* Check if DY variables already exist in the domains */ 
%let DY = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.DY);
%let STDY = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.STDY);
%let ENDY = %tu_chkvarsexist(pst_sdtm.&dsn.,&dsr.ENDY); 

/* Create dummy macro variables to check for partial dates */
%let partial_dtc_date = 0;
%let partial_stdtc_date = 0;
%let partial_endtc_date = 0;
%let partial_rfstdtc_date = 0;

     %if(&DTC eq or &STDTC eq or &ENDTC eq ) and &RFSTDTC eq %then 
     %do;

         proc sort data = pst_sdtm.&dsn force;
              by studyid usubjid;
         run;

         data pst_sdtm.&dsn;
             merge pst_sdtm.&dsn(in=a)
                  pst_sdtm.dm(keep=studyid usubjid rfstdtc);
         by studyid usubjid;
            if a;

/* As per CDISC SDTM Implementation Guide (Version 3.1.2)											 */
/* All Study Day values are integers. Thus, to calculate Study Day: 								 */
/* --DY = (date portion of --DTC) - (date portion of RFSTDTC) + 1 if --DTC is on or after RFSTDTC    */ 
/* --DY = (date portion of --DTC) - (date portion of RFSTDTC) if --DTC precedes RFSTDTC   	 		 */
/* This algorithm should be used across all domains. 												 */

            %if &DTC eq and &DY ne %then %do;
                length &dsr.DY 8;
                if length(strip(&dsr.DTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.DTC,yymmdd10.) ge input(rfstdtc,yymmdd10.)then 
                    &dsr.DY=input(&dsr.DTC,yymmdd10.) - input(rfstdtc,yymmdd10.) + 1;
			    else if length(strip(&dsr.DTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.DTC,yymmdd10.) lt input(rfstdtc,yymmdd10.) then 
                    &dsr.DY=input(&dsr.DTC,yymmdd10.) - input(rfstdtc,yymmdd10.);
                else if (10 > length(strip(&dsr.DTC)) >=4 ) then call symput('partial_dtc_date','1');                 
            %end;
            %if &STDTC eq and &STDY ne %then %do;
                length &dsr.STDY 8;
                if length(strip(&dsr.STDTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.STDTC,yymmdd10.) ge input(rfstdtc,yymmdd10.) then
                    &dsr.STDY=input(&dsr.STDTC,yymmdd10.) - input(rfstdtc,yymmdd10.) + 1;
                else if length(strip(&dsr.STDTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.STDTC,yymmdd10.) lt input(rfstdtc,yymmdd10.) then
                    &dsr.STDY=input(&dsr.STDTC,yymmdd10.) - input(rfstdtc,yymmdd10.);
                else if (10 > length(strip(&dsr.STDTC)) >=4 ) then call symput('partial_stdtc_date','1');				                
            %end;
            %if &ENDTC eq and &ENDY ne %then %do;
                length &dsr.ENDY 8;
                if length(strip(&dsr.ENDTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.ENDTC,yymmdd10.) ge input(rfstdtc,yymmdd10.) then
   	                &dsr.ENDY=input(&dsr.ENDTC,yymmdd10.) - input(rfstdtc,yymmdd10.) + 1; 
                else if length(strip(&dsr.ENDTC)) ge 10 and length(strip(rfstdtc)) ge 10 and input(&dsr.ENDTC,yymmdd10.) lt input(rfstdtc,yymmdd10.) then
                    &dsr.ENDY=input(&dsr.ENDTC,yymmdd10.) - input(rfstdtc,yymmdd10.);
                else if (10 > length(strip(&dsr.ENDTC)) >=4 ) then call symput('partial_endtc_date','1');
            %end;

            if (10 >length(strip(rfstdtc)) >=4 ) then call symput('partial_rfstdtc_date','1');
			/* BJC001: dont drop RFSTDTC for DM domain */
            %if &dsn ne DM %then %do;
			 drop rfstdtc; 
			%end;
         run; 

         %if &partial_dtc_date eq 1 %then %do; 		
             %let _cmd = %str(%STR(RTN)OTE: Partial dates present in &dsr.DTC so &dsr.DY not assigned for all rows); %tu_sdtmconv_sys_message;
         %end; 
         %if &partial_stdtc_date eq 1 %then %do;
             %let _cmd = %str(%STR(RTN)OTE: Partial dates present in &dsr.STDTC so &dsr.STDY not assigned for all rows); %tu_sdtmconv_sys_message;
         %end;
         %if &partial_endtc_date eq 1 %then %do;
             %let _cmd = %str(%STR(RTN)OTE: Partial dates present in &dsr.ENDTC so &dsr.ENDY not assigned for all rows); %tu_sdtmconv_sys_message;
         %end;
         %if &partial_rfstdtc_date eq 1 %then %do;
             %let _cmd = %str(%STR(RTN)OTE: Partial dates present in RFSTDTC so &dsr.DY, &dsr.STDY and &dsr.ENDY not assigned for all rows); %tu_sdtmconv_sys_message;
         %end;

     %end; /* End of %if(&DTC eq or &STDTC eq or &ENDTC eq ) and &RFSTDTC eq %then %do; */
%end; /* End of  %do x=1 %to 1; */

%endmac:

%mend tu_sdtmconv_pst_add_dy_vars;
