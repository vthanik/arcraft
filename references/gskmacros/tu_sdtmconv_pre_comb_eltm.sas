/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_comb_eltm
|
| Macro Version/Build:  5/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        combine ELTMNUM and ELTMUNIT where present and provide
|                       in ISO8601 format
|
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
|
| Example:
|
| %tu_sdtmconv_pre_comb_eltm
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Deepak Sriramulu (DSS001) 
| Date of Modification:    		 30Apr2011
| New Version/Build Number:      2/1
| Description for Modification:  Amend the code to follow ISO 8601 standards: For example: "P3Y6M4DT12H30M5S" represents a duration of 
|								 "three years, six months, four days, twelve hours, thirty minutes, and five seconds". . 
| Reason for Modification:       There are values of PCELTM=�PTH�; these aren�t valid. 
| 								 The date time values in PCELTM are not as per ISO 8601 standards.
|
| Modified By:                   Ashwin Venkat (AV001) 
| Date of Modification:    		 5-Aug-2011
| New Version/Build Number:      3/1
| Description for Modification:  Added code to convert negative  elapsed time into ISO 8601 standards 
| Reason for Modification:        negative  elapsed time was not getting converted into ISO 8601 standards 
|
| Modified By:                   Ashwin Venkat (AV002) 
| Date of Modification:    		 15-Dec-2011
| New Version/Build Number:      4/1
| Description for Modification:  Added code to convert 0 elapsed time into ISO 8601 standards 
| Reason for Modification:       0  elapsed time was not getting converted into ISO 8601 standards 
|
| Modified By:                   Bruce Chambers (BJC001)
| Date of Modification:    		 31-Jul-2012
| New Version/Build Number:      5/1
| Reference                   :  BJC001
| Description for Modification:  Drop temporary hours variable
| Reason for Modification:       So it doesnt appear on user report as unmapped.
|
*******************************************************************************/
%macro tu_sdtmconv_pre_comb_eltm(
);

proc sql noprint;
 create table _pre_comb_eltm as
 select memname
 from  dictionary.columns 
 where libname='PRE_SDTM'
   and name ='ELTMUNIT'
   and memname in (select memname 
   		  from  dictionary.columns 
		  where libname='PRE_SDTM'
		  and name ='ELTMNUM')
   and memname in (select basetabname from view_tab_list);
quit; 

** Count the number of datasets (if any) to process **;
%if &sqlobs>=1 %then %do;
 data _pre_comb_eltm;
  set _pre_comb_eltm;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

  ** For each iteration - attempt to derive the ISO8601 value from the two data points  **;  
  data _null_ ;set _pre_comb_eltm (where=(num=&w));
   call symput('memname',trim(memname));
  run;

  /* DSS001 The date time values in PCELTM are not as per ISO 8601 standards. Amend the code to follow ISO 8601 standards */
  /*AV001: amended code to convert negative elapsed time into ISO 8601 standards */
  data pre_sdtm.&memname(drop=eltmnum rename=(new_eltmunit=ELTMUNIT));
   attrib NEW_ELTMUNIT length=$50;
     set pre_sdtm.&memname;
	 if missing(eltmnum) then eltmunit='';
     new_eltmunit=eltmunit; 
 
   select (upcase(NEW_ELTMUNIT));	
     when ('YRS') NEW_ELTMNUM = eltmnum*(365.25*24*60*60);  /* 1 YEAR = 31557600 seconds */   
     when ('MTH') NEW_ELTMNUM = eltmnum*(30.4375*24*60*60); /* 1 MONTH = 2629800 seconds */
     when ('WKS') NEW_ELTMNUM = eltmnum*(7*24*60*60);       /* 1 WEEK = 604800 seconds */
	 when ('DAY') NEW_ELTMNUM = eltmnum*(24*60*60);         /* 1 DAY = 86400 seconds */
     when ('HRS') NEW_ELTMNUM = eltmnum*(60*60);            /* 1 HOUR = 3600 seconds */ 
     when ('MIN') NEW_ELTMNUM = eltmnum*(60);               /* 1 MINUTE = 60 seconds */     
     when ('SEC') NEW_ELTMNUM = eltmnum;                            
     when ('')    /* Do nothing - blank is an acceptable value for ELTMUNIT */;
     otherwise 
     do;
       put / "RTW" "ARNING: &sysmacroname: the dataset pre_sdtm.&memname contains"
           / "a value of ELTMUNIT which is not recognised"
           / usubjid = eltmunit = eltmnum = 
           / ;
     end;	   /* End of otherwise do; */	   
   end;    /* select (upcase(new_eltmunit)) */
	  
	 if NEW_ELTMNUM ne 0 then do;
        secs = mod(NEW_ELTMNUM,60);
		mindur = (NEW_ELTMNUM - secs)/60;
		mins = mod(mindur,60);
		hrdur = (mindur - mins)/60;
		hours = mod(hrdur,24);
		daydur = (hrdur - hours)/24;
		days = mod(daydur,7);
		wkdur = (daydur - days)/7;
		weeks = mod(wkdur,52);
		mondur = (wkdur - weeks)/30.4375;
		months = mod(mondur,12);
		years = (mondur - months)/12;
		
    if new_eltmnum gt  0 and not missing(new_eltmnum) then
	 NEW_ELTMUNIT = 'P';
    else if NEW_ELTMNUM lt 0 and not missing(new_eltmnum) then
     NEW_ELTMUNIT = '-P';	 	
	 if (years ne 0) and not missing(years) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(years),2.)) || 'Y';
	 if (months ne 0)and not missing(months) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(months),2.)) || 'M';
	 if (weeks ne 0)and not missing(weeks) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(weeks),2.)) || 'W';
	 if (days  ne 0) and not missing(days) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(days),2.))  || 'D';
	 
	 if ((hours ne 0) or (mins  ne 0) or (secs  ne 0)) and not missing(NEW_ELTMNUM) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || 'T';
	 
	 if (hours ne 0)and not missing(hours) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(hours),2.)) || 'H';
	 if (mins  ne 0)and not missing(mins) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(mins),2.))  || 'M';
	 if (secs  ne 0)and not missing(secs) then NEW_ELTMUNIT = strip(NEW_ELTMUNIT) || strip(put(abs(secs),2.))  || 'S';
     end;
      
  /*AV002: amended code to convert 0 elapsed time into ISO 8601 standards */ 
  if new_eltmnum = 0  then do ;
    if eltmunit = "MIN" then NEW_ELTMUNIT = "PT0M";
    else if eltmunit = "SEC" then NEW_ELTMUNIT = "PT0S";
    else if eltmunit = "HRS" then NEW_ELTMUNIT = 'PT0H';
  end;
  /* BJC001: drop hours variable as well */
	 drop secs mins hours days weeks months years mindur hrdur daydur wkdur mondur new_eltmnum eltmunit;
 run; 
  /* End of DSS001 */ 

 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_comb_eltm:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_comb_eltm;
