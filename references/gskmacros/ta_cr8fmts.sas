/******************************************************************************* 
|
| Program Name: ta_cr8fmts
|
| Program Version: 2
|
| MDP/Protocol ID: 
|
| Program Purpose: Extract controlled terms and create formats catalog
|
| SAS Version: 9.1.3
|
|
| (@) tu_putglobals
| (@) tu_nobs
| (@) tu_abort
| (@) tu_maclist
| (@) tu_quotelst
|
|
| Created By:      Lee Seymour
| Date:            07-Nov-2012
|
|******************************************************************************* 
| Change Log 
|
| Modified By:  Lee Seymour 
| Date of Modification: 12-Sep-2014
|
| Modification ID: LS001
| Reason For Modification: Changed '***' to ' ' for separator for hilowlist
|                          to ensure these are not passed to proc format
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 

%macro ta_cr8fmts(
);


 /* Set macro search path 
 /-------------------------*/

OPTIONS SASAUTOS=("&g_refdata");


 /*
 / Echo macro version number and values of parameters and global macro
 / variables to the log.
 /----------------------------------------------------------------------------*/
  
  %LOCAL MacroVersion;
  %LET MacroVersion=1;
  %INCLUDE "&g_refdata./tr_putlocals.sas";
  
  %tu_putglobals(varsin=g_rfmtdir user password path g_refdata log re_id);

  %LOCAL prefix k i err_fmtlist hilowlist fmtlist fmtcount;
  %LET prefix=%substr(&sysmacroname,3);
  %global g_abort g_debug;
  %let g_debug=0;
  %let g_abort=0;


/* Assign libname for reporting effort refdata folder
/-----------------------------------------------------*/
libname rfmtdir "&g_rfmtdir";


/* Remove existing reporting effort/refdata formats catalog
/------------------------------------------------------------*/
%if %sysfunc(fileexist(&g_rfmtdir/formats.sas7bcat)) %then
%do;
        proc datasets lib=rfmtdir memtype=catalog nowarn;
        delete formats / memtype=catalog;
        run; 
%end;
  

/* Extract control terms information. code, decode, name, type
/-----------------------------------------------------------------*/
PROC SQL NOERRORSTOP NOPRINT FEEDBACK NUMBER;
CONNECT TO ORACLE (USER=&user password=&password PATH="&path");
create table &prefix._cterms as select ct_type, ct_name, code, decode from connection to oracle
(select cti.code, cti.decode, ct.CONTROL_TERM_TYPE ct_type, ct.CONTROL_TERM_NAME ct_name
FROM harp_control_term ct,
     harp_control_term_item cti
WHERE ct.control_term_id = cti.control_term_id
      and ct.re_id=&re_id
order by ct.CONTROL_TERM_NAME);
quit;


/* Start redirecting log file 
/-----------------------------------------*/
proc printto log="&log" new;
run;


%if %tu_nobs(&prefix._cterms) = 0 %then
%do;
    %put %str(RTE)RROR :  &sysmacroname : Reporting effort contains no codelist entries. Code will abort;
    %let g_abort=1;
    %tu_abort;
%end;

/*Start Validation 
/ Validate format names to ensure proc format can work
/ Check if any formats contain "HIGH" or "LOW" as these
/ are keywords in proc format functionality
/----------------------------------------------------------*/

%else %if %tu_nobs(&prefix._cterms) gt 0 %then
%do;


    proc sort data=&prefix._cterms out=&prefix._hilows nodupkey;
    by ct_name code;
    where upcase(code) in ('HIGH','LOW');
    run;
    
    proc sql noprint;
        select distinct(ct_name) into : hilowlist
        separated by ' '  /*LS001*/
        from &prefix._hilows
        ;
        quit;
    
    
    %if %length(&hilowlist) gt 0 %then
    %do;
        %put %str(RTWA)RNING : &sysmacroname : Format(s) = &hilowlist contain(s) code values of Low and/or High these are functional values in proc format;
    %end;



    proc sql noprint;
    select distinct(ct_name) into : fmtlist
    separated by '***'
    from &prefix._cterms
    ;
    quit;
    proc sql noprint;
    select count(distinct(ct_name)) into : fmtcount
    from &prefix._cterms
    ;
    quit;


    %tu_maclist(string=&fmtlist,prefix=fmt,cntname=fmt_num,delim=%str('***'));


        %do k=1 %to &fmtcount;
        
            data &prefix._chk&k;
                  length currentChar $ 1 ct_name $32;
               
                  alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_";
                  numeric = "0123456789";
                  alphaNumeric = alpha || numeric;
                  ct_name="&&fmt&k";
               /* Strip off decimal point at the end of the format name if it exists */
                  if substr(trim(left(reverse(ct_name))),1,1)='.' then fmtname=reverse(substr(trim(left(reverse(ct_name))),2));
                  else fmtname=ct_name;
                  len = length(fmtname);
               /* Strip off the dollar symbol at the beginning of the format name if it exists */
                  if substr(fmtname,1,1)='$' then fmtname=substr(fmtname,2);
                  
                  isValid = 0;
        
               /* If last character is numeric then is an invalid format name */
                  if  not index(alpha,  substr(trim(left(reverse(fmtname))),1,1)) then isvalid=1  ;
                  len = length(fmtname);
               
                  do n = 1 to len;
               
                    currentChar = substr(fmtname, n, 1);
               
                    select;
                      when (n eq 1) if not index(alpha, currentChar) then isValid = 2;                          /* First character must be character   */
                      when (1 lt n lt (len - 1)) if not index(alphaNumeric, currentChar) then isValid = 3;      /* All characters must be alphanumeric */
                      when (n eq len) if not index(alpha, currentChar) then isValid = 4;                        /* Last character must be character    */
                      otherwise;
                    end; 
        
                 end;
               run;
        
         %end;    /* End of looping over each format*/


         data &prefix._all(keep=ct_name fmtname: isvalid n len);
         set 
           %do i=1 %to &fmtcount;
         &prefix._chk&i
         %end;
         ;
         run;

        
        proc sql noprint;
        select distinct(ct_name) into : err_fmtlist
        separated by ' '
        from &prefix._all
        where isvalid gt 0
        ;
        quit;

%end; /* End of code executed if data extracted from oracle contains data */

/* End Validation */

  
/* Print messages to the log for invalid formats */
%if %length(&err_fmtlist) gt 0 %then
%do;
    %put %str(RTWA)RNING : &sysmacroname : Invalid format names &err_fmtlist;

%end;


/* Remove decimal point from end of format names
/  Rename variables to SAS format dataset names
/  Remap format type to be SAS specific
/------------------------------------------------*/

%let err_fmtlist=&err_fmtlist &hilowlist;



data &prefix._formats ;
set &prefix._cterms
%if %length(&err_fmtlist) gt 0 %then
%do;
(where=(ct_name not in (%tu_quotelst(&err_fmtlist))))
%end;
;
fmtname=tranwrd(ct_name,'.','');
if upcase(substr(ct_type,1,1)) in ('F','I','N') then type='N';
else if upcase(substr(ct_type,1,1)) in ('C','T') then type='C';
start=code;   
label=decode;
run;


/* Create the SAS formats catalog
/-----------------------------------------*/

proc format cntlin=&prefix._formats lib=rfmtdir.formats;
run;

proc printto;
run;
 
%mend;
%ta_cr8fmts;
