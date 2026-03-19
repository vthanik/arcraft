/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_adjust_cmdecod
|
| Macro Version/Build:  2/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        The tu_dictdcod macro populates CMDECOD='Multiple
|                       Ingredient' for multi ingredient medications. This is not
|                       suitable for SDTM so for any source datasets that contain
|                       CMDECOD check all the values and if any CMDECOD='Multiple
|                       Ingredient' values are found update the details from the
|                       GSKDRUG dictionary data.
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                DESCRIPTION                                  DEFAULT           
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
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pre_adjust_cmdecod
|
|*******************************************************************************
| Change Log:
|
| Modified By:               Bruce Chambers
| Date of Modification:      22July2011
| New Version/Build Number:  2/1   
| Reference:                 BJC001 
| Description for Modification: Logic changes as follows: 
|                        1)�If ardata.CMANAL is present use CMANAL terms.
|                        2)�If a local Rfmtdir copy of GSKDRUG dictionary is present in reporting effort use that
|                           (NB: code wont look for sfmtdir and cfmtdir as well)  
|                        3) If 1 & 2 fail then refer to GSKDRUG current dictionary data (from ICDS) - previous default
| Reason for Modification: To ensure that dictionary updates dont introduce differences between IDSL and SDTM data
|
*******************************************************************************/
%macro tu_sdtmconv_pre_adjust_cmdecod(
);

/* Get list of any source datasets containing CMDECOD column */
proc sql noprint;
  create table _pre_cmdecod as 
  select distinct memname
  from dictionary.columns
  where libname='PRE_SDTM'
  and name='CMDECOD';
quit;

/* Count the number of datasets (if any) to process */

%if &sqlobs>=1 %then %do;  

 data _pre_cmdecod;
  set _pre_cmdecod;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

 /* For each iteration - create macro var with dataset name */  
 data _null_ ;set _pre_cmdecod (where=(num=&w));
   call symput('memname',trim(memname));
 run;

 /* BJC001 : Add steps below to use preferred methods to get multiple ingredients */

 /* Using GSKDRUG dictionary data, source the individual ingredients for each multiple term 
 / NB: This SQL code is taken from tu_dictdcod HARP RT macro */
 
 /* BJC001: Use ardata.cmanal as reference if present */
 %if %sysfunc(exist(ardata.cmanal)) %then %do;
   
   proc sql;         
    create table _pre_cmdecod_ingredients_&memname as
    select distinct cmdrgcol,  cmcomp
      from ardata.cmanal
     where cmcomp^='Multiple Ingredient'
	   and cmdrgcol in (select cmdrgcol
		          from pre_sdtm.&memname
		         where cmdecod='Multiple Ingredient')               
    order by cmdrgcol, cmcomp;
  quit;
 
  /* set the length of CMCOMP to 300 as thats what it is in ICDS and the later code expects it. 
     CMANAL sets it as 100 for soem reason */
	 
  data _pre_cmdecod_ingredients_&memname; 
  attrib cmcomp length=$300;
  set _pre_cmdecod_ingredients_&memname;
  run;
 
 %end;
 
 /* BJC001: If ardata.cmanal not present - look for rfmtdir.gskdrug (NB:wont look for sfmtdir and cfmtdir as well)*/
 %else %if %sysfunc(exist(rfmtdir.gskdrug)) %then %do;
 
   proc sql;         
   create table _pre_cmdecod_ingredients_&memname as
   select distinct cmdrgcol,  cmcomp
     from rfmtdir.gskdrug
    where cmnc eq 'C'
     and cmdrgcol in (select cmdrgcol
		       from pre_sdtm.&memname
		      where cmdecod='Multiple Ingredient')               
    order by cmdrgcol, cmcomp;
  quit; 
 
 %end;
 
 /* BJC001: If the first two lookup attempts fail use the current diction.gskdrug dictionary data from ICDS */
 %else %do; 
  
  proc sql;         
   create table _pre_cmdecod_ingredients_&memname as
   select distinct cmdrgcol,  cmcomp
     from diction.gskdrug
    where cmnc eq 'C'
     and cmdrgcol in (select cmdrgcol
		       from pre_sdtm.&memname
		      where cmdecod='Multiple Ingredient')               
    order by cmdrgcol, cmcomp;
  quit;        
 %end;
 
 %if &sqlobs=0 %then %goto skip;

 **********************************************************************************************;
 /* CMCOMP is defined in dictionary as $300, as at time of writing the longest value is ~80 chars, but check just in case */
 %let warn=N;            
 data _pre_cmdecod_too_long; set _pre_cmdecod_ingredients_&memname;
  if length(cmcomp)>200 then do;
   call symput('warn','Y');
   output;
  end; 
 run; 

 %if &warn=Y %then %do;
  %let _cmd = %str(%str(RTW)ARNING: At least one source GSKDRUG dictionary value for CMDECOD Multiple Ingredients has length >200);
  %tu_sdtmconv_sys_message;
  proc sort data=_pre_cmdecod_too_long nodupkey;
  by cmcomp;
  run;
  
  proc print data=_pre_cmdecod_too_long;
  title3 "Listing of multiple ingredient entry over $200 in length";
  run;
 %end;
 **********************************************************************************************;
  
 %let _cmd = %str(Updating CMDECOD='Multiple Ingredient' values for &memname);%tu_sdtmconv_sys_message;
  
 /* Process multiple ingreedient rows into one CMDECOD string with each term separated by a plus sign */
 data _pre_cmdecod_ingredients_&memname;
  set _pre_cmdecod_ingredients_&memname;
   attrib cmcomps length=$200;
   by cmdrgcol cmcomp;
   retain cmdecod;

   cmcomps=substr(cmcomp,1,200);
        
   if first.cmdrgcol then cmdecod=cmcomps;
   else do;
          if (not last.cmdrgcol and (length(cmdecod) + length(cmcomps) + 1 lt 200)) or 
             (last.cmdrgcol and (length(cmdecod) + length(cmcomps) + 1 le 200)) then
          do;
             cmdecod = trim(cmdecod) || '+' || cmcomps;
          end;
          else if length(cmdecod) lt 200 then 
          do;
             cmdecod = trim(cmdecod) || substr('+' || cmcomps,1,200-length(cmdecod));
             cmdecod = substr(cmdecod,1,200-7)||'/+OTHER';
          end;
   end;
        
  if last.cmdrgcol then output;
 run;

 /* A query of HARP shows that size attributes of CMDECOD vary from $1 to $300 !
 / To avoid an update warning, set the length of CMDECOD to 300 beforehand */
 data pre_sdtm.&memname;
  attrib CMDECOD length=$300; 
  set pre_sdtm.&memname;
 run; 

 /* Update the affected rows in the source dataset */
 
 proc sql;
  update pre_sdtm.&memname c set cmdecod=(select cmdecod
   from _pre_cmdecod_ingredients_&memname i
   where i.cmdrgcol=c.cmdrgcol)
   where c.cmdecod='Multiple Ingredient' ;
 quit;

 %skip:

 %end;
%end;

 
%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_cmdecod_:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_adjust_cmdecod;
