/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_decode 
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Performs decodes as per SDTM mapping instructions
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
| Macros called :
| (@)tu_tidyup
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_util_pre_decode 
|
|*******************************************************************************
| Change Log :
|
| Modified By:                  Bruce Chambers   
| Date of Modification:         06Jan2011   
| New Version/Build Number:     2/1   
| Reference:                    bjc001
| Description for Modification: Efficiency change
| Reason for Modification:      Speed/performance - reduce datasets read/writes
|
|
| Modified By:                  Ashwin Venkat   
| Date of Modification:         20Mar2012   
| New Version/Build Number:     3/1   
| Reference:                    AV001
| Description for Modification: added  do loop to set attrib for all variables
| Reason for Modification:      Length was not set for all variables 
|*******************************************************************************/
%macro tu_sdtmconv_util_pre_decode(
);

proc sql noprint;
 create table _pre_util_decode as
 select distinct vm.si_dset, vm.si_var, vm.instructions
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(instructions,'pre_decode')>0
   and si_dset in (select basetabname from view_tab_list)
   order by si_dset, si_var;
quit; 

** This one needs a bit of additional processing to deal with the brackets etc correctly **;

/* bjc001: create first and last counters */
data _pre_util_decode; set _pre_util_decode;
 by si_dset si_var ;
 decode=tranwrd(instructions,"'-'","') # ='");
 /* bjc001: amend &si_var to &&si_var&w */
 decode=substr(decode,1,index(decode,'#')-1)||'&&si_var&w'||substr(decode,index(decode,'#')+1);
 decode=substr(decode,11,(length(decode)-12));
 fd=first.si_dset;ld=last.si_dset; 
 fv=first.si_var;lv=last.si_var; 
 num=_n_;
run;


** Count the number of datasets (if any) to process **;
%if %eval(%tu_nobs(_pre_util_decode))>=1 %then %do;

 %DO w=1 %TO %eval(%tu_nobs(_pre_util_decode));

  ** For each iteration - apply the decode **;  
  /* bjc001: amend macro var generation to array style and add counters */
  
  proc sql noprint;
  select si_dset, si_var, decode, fv, lv, fd, ld
   into :si_dset1- :si_dset%left(%eval(%tu_nobs(_pre_util_decode))),
        :si_var1- :si_var%left(%eval(%tu_nobs(_pre_util_decode))),
        :decode1- :decode%left(%eval(%tu_nobs(_pre_util_decode))),
        :fv1- :fv%left(%eval(%tu_nobs(_pre_util_decode))),
        :lv1- :lv%left(%eval(%tu_nobs(_pre_util_decode))),
        :fd1- :fd%left(%eval(%tu_nobs(_pre_util_decode))),
        :ld1- :ld%left(%eval(%tu_nobs(_pre_util_decode)))
    from _pre_util_decode
   order by si_dset, si_var, num;
  quit;

   /* bjc001: Only add the data step header and run statement for the first and last decode */

   /*AV001: added do loop to set attrib for all variables*/

  %DO w=1 %TO %eval(%tu_nobs(_pre_util_decode)); 
   
   %if &&fd&w=1 %then %do;
     data pre_sdtm.&&si_dset&w; 
       %do x=&w %to %eval(%tu_nobs(_pre_util_decode));
          %if &&si_dset&x = &&si_dset&w  %then %do;
                attrib &&si_var&x length = $200 format=$200.;
          %end;
       %end;
      set pre_sdtm.&&si_dset&w;    
   %end;      
   %if &&fv&w=1 %then %do;
          select (&&si_var&w);
   %end;  
    
    when &&decode&w;     

   %if &&lv&w=1 %then %do;
       otherwise;
      end;
   %end;   
   %if &&ld&w=1 %then %do;  
    run;
   %end;
   
  %end; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_util_decode:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_decode;
