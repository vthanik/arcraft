/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_adjust_visit
|
| Macro Version/Build:  7/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        There are two possible sets of source data - for IDSL
|                       this is A+R (primary) or DMSI (alternate). For some
|                       (mainly efficacy) types of data, the A+R version will
|                       change for every study and it may be easier for these to
|                       use DM SI as the source. However, it often happens that
|                       the DM VISIT values are not the same as the A&R visit
|                       values, but we have to have one matching set in SDTM.
|                       Therefore to achieve this consistency across source 
|                       data we need to update the alternate VISIT values to
|                       equal their corresponding main source equivalent. This
|                       is done by getting unique values across all datasets (BY
|                       visitnum) and updating the alternate source.
|
|                       Note: this macro generates an (RTW)ARNING but does not
|                       terminate, if the user specifies a dataset in the SI_DSETS
|                       parameter (in TC_SDTMCONV) which is not also specified in
|                       the VISIT_ORIG parameter, assuming that there are other
|                       datasets in /ardata whose values of VISIT are not identical
|                       to those of the dataset specified in SI_DSETS. However,
|                       this macro is not designed to perform a complete validation
|                       of VISIT values, so, for example, the macro will also 
|                       terminate with a SAS (E)RROR in the following scenarios:
|
|                       1. There are mulitple values of VISIT for the same value of
|                          VISITNUM in any given dataset.
|                       2. None of the individual datasets in /ardata have multiple
|                          values of VISIT for any given VISITNUM, but for a given
|                          value of VISITNUM, different datasets have different values
|                          of VISIT.
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
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pre_adjust_visit
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers         
| Date of Modification:        14October2010
| New Version/Build Number:    2/1  
| Reference:                   bjc001
| Description for Modification:Uniquely identify Unscheduled VISIT identifiers
| Reason for Modification:     Make the data more SDTM compliant
|
| Modified By:                 Bruce Chambers         
| Date of Modification:        05November2010
| New Version/Build Number:    3/1  
| Reference:                   bjc002
| Description for Modification:Modify SQL to avoid null VISIT values being updated
|                              where there is no reference VISIT record
| Reason for Modification:     Make the data more SDTM compliant
|
| Modified By:                 Ashwin Venkat         
| Date of Modification:        05January2011
| New Version/Build Number:    4/1  
| Reference:                   VA001
| Description for Modification:If VISITNUM = 999 and <1 values in final SDTM data  be flagged  ,
|                              it is expected that 999 would be slotted, and <1 is aberrant. 
| Reason for Modification:     
|
| Modified By:                 Deepak Sriramulu
| Date of Modification:        03February2011
| New Version/Build Number:    4/1
| Reference:                   DSS001
| Description for Modification:Where present, Pre-pend to VISIT variable. VISIT=CYCLE|| VISIT                   
| Reason for Modification:     Accommodate CYCLE mapping to SDTM
|
| Modified By:                 Bruce Chambers
| Date of Modification:        03April2012
| New Version/Build Number:    5/1
| Reference:                   BJC003
| Description for Modification:Move UNS_NAMES definition to start of macro, out of IF/END loop
| Reason for Modification:     Ensure its available for use in later macros
|
| Modified By:                 Bruce Chambers
| Date of Modification:        03April2012
| New Version/Build Number:    5/1
| Reference:                   BJC004
| Description for Modification:Modify to work for DM SI start point that will become more common
| Reason for Modification:     Ensure correct data processing
|
| Modified By:                 Bruce Chambers
| Date of Modification:        20Jun2012
| New Version/Build Number:    5/1
| Reference:                   BJC005
| Description for Modification:Dont report different visit identifers for visitnum=0
| Reason for Modification:     These VISIT(NUM) values are nulled in SDTM anyway - no need to report here
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16Feb2013
| New Version/Build Number:    6/1
| Reference:                   BJC006
| Description for Modification:Allow for CYCLE scenario when updating unscheduled visit strings
| Reason for Modification:     Correct data product 
|
| Modified By:                 Bruce Chambers
| Date of Modification:        30Mar2013
| New Version/Build Number:    7/1
| Reference:                   BJC007
| Description for Modification:Fix bug introduced in previous version - use direct string compare and not index 
|                              to identify UNSCHEDULED type data rows, as each string may fit more than one known example
| Reason for Modification:     Correct data product 
|
*******************************************************************************/
%macro tu_sdtmconv_pre_adjust_visit(
);

/* BJC003: Move this definition to the start. From TSU this is a list of the most common ways 
   that	unscheduled visits are named without being visit specific */

data uns_names (drop=string stringb);
length string $2000;
string="UNS~UNS SCR~UNSCH~UNSCHEDULED~UNSCHEDULED ASSESSMENTS~UNSCHEDULED CENTRAL LABS~UNSCHEDULED INVESTIGATIONAL PRODUCT";
stringb="UNSCHEDULED IP~UNSCHEDULED LABS~UNSCHEDULED SCREENING~UNSCHEDULED TIMEPOINT~UNSCHEDULED VISIT~UNSCHEDULED VISITS~UNSCHEDULED/REPEAT~UNSCHEDULEDIP";
/*Process first string - keep under 262 in length as Unix limit */
posn=index(string,'~');                      			
len_all=length(trim(string));						
len_tilde=length(trim(compress(string,'~')));			
num_tildes=len_all-len_tilde;						
tempstr=string;								
 do a=1 to num_tildes+1;							
 	 if a<=num_tildes then do;						
          uns_visit=substr(tempstr,1,index(tempstr,'~')-1);			
          tempstr=substr(tempstr,index(tempstr,'~')+1,length(trim(tempstr))-index(tempstr,'~')+1); 
 	  output;									
 	 end;										
 	 else if a=num_tildes+1 then do;					
 	  uns_visit=tempstr;								
          output;									
 	 end;										 											
  end;		

/*Process second string - keep under 262 in length as Unix limit */
posn=index(stringb,'~');                      			
len_all=length(trim(stringb));						
len_tilde=length(trim(compress(stringb,'~')));			
num_tildes=len_all-len_tilde;						
tempstr=stringb;								
 do a=1 to num_tildes+1;							
 	 if a<=num_tildes then do;						
          uns_visit=substr(tempstr,1,index(tempstr,'~')-1);			
          tempstr=substr(tempstr,index(tempstr,'~')+1,length(trim(tempstr))-index(tempstr,'~')+1); 
 	  output;									
 	 end;										
 	 else if a=num_tildes+1 then do;					
 	  uns_visit=tempstr;								
          output;									
 	 end;										 											
  end;		
run;

/* BJC006: move the section that defines the common/expected unscheduled definitions from further down up
   to the start of the code module */ 
 
proc sql noprint;
select count(*) into :num_uns from uns_names;
quit;

proc sql noprint;
  select distinct uns_visit
     into :uns1- :uns%left(&num_uns) 
     from uns_names;
quit;

/* Get a list of any datasets with VISIT populated with the alternative (e.g.DM SI) values*/
 
proc sql noprint;
  create table _pre_adjust_visit_alt as
  select dc.memname 
  from view_tab_list vtl,
       dictionary.columns dc
  where vtl.basetabname=dc.memname
    and vtl.libname=dc.libname
    and dc.name='VISIT'
    and memname in (&visit_orig);
quit;

/* Get a list of all datasets with VISIT column present and also check VIIST dataset is present and from default source */
%let vis_si_source =;
%let vis_ar_source =;

proc sql noprint;
 select memname into :vis_si_source 
  from dictionary.tables
  where libname='PRE_SDTM'
    and memname='VISIT'
    and memname in (&visit_orig);

 select memname into :vis_ar_source 
  from dictionary.tables
  where libname='PRE_SDTM'
    and memname='VISIT'
    and memname not in (&visit_orig);    

 create table _pre_adjust_visit_list as
 select dc.memname, vtl.libname
   from dictionary.columns dc, view_tab_list vtl
  where dc.libname='PRE_SDTM'
    and dc.name='VISIT'
    and dc.memname=vtl.basetabname;    
quit; 

/* BJC004: correct notes and warnings to bear in mind the new DM SI expected default */
%if %length(&vis_si_source)>=1 %then %do;
  %let _cmd = %str(%str(RTN)OTE: VISIT source dataset should be default A+R [where possible] not SI);%tu_sdtmconv_sys_message;
%end;

%if %length(&vis_ar_source)=0 and %length(&vis_si_source)=0 and &tab_list= and &tab_exclude= %then %do;
  %let _cmd = %str(%str(RTW)ARNING: No VISIT source dataset present for a complete run);  %tu_sdtmconv_sys_message;
%end;

%if %length(&vis_si_source)=0 and %length(&vis_ar_source)=0 %then %goto endmac;

%if &sqlobs=0 %then %goto endmac;

data _pre_adjust_visit_alt; 
 set _pre_adjust_visit_alt;
 num=_n_;
run;

data _pre_adjust_visit_list; 
 set _pre_adjust_visit_list;
 num=_n_;
run;

/* Create an emtpy template dataset that we can append to to build a list of distinct 
/   combinations of VISIT and VISITNUM */
 
data _pre_adjust_visit_distinct;
  length memname $32;
  length VISIT $40;
  stop;
run;

%DO v=1 %TO &sqlobs;
 
 /* For each iteration - get distinct visit and visitnum values */
   data _null_ ;set _pre_adjust_visit_list (where=(num=&v));
    call symput('memname',trim(memname));
    call symput('libname',trim(libname));
  run;

/* DSS001: Check if Cycle variable exists in any of the domains */
%let cycle=%tu_chkvarsexist(pre_sdtm.&memname,CYCLE);
%let visitgt40=0;
%let cycle_not_missing=0;

  /* BJC001: upper case all VISIT strings as SDTM expects this */
  data pre_sdtm.&memname;
   set pre_sdtm.&memname;
    visit=upcase(visit);
    
 /* DSS001: If Cycle variable exists then pre-pend cycle values with VISIT */
	%if &CYCLE eq %then %do;	
		
        if cycle ne . and length('CYCLE ' || strip(put(cycle,3.)) || ':' || strip(upcase(visit))) le 40 then do;
             visit='CYCLE ' || strip(put(cycle,3.)) || ':' || strip(upcase(visit));
             if visitnum lt 100 then visitnum = visitnum + (cycle*100);
             else if visitnum lt 1000 then visitnum = visitnum + (cycle*1000);
             else if visitnum le 10000 then visitnum = visitnum + (cycle*10000); 
        end;
        else if cycle ne . then do;             
             call symput('visitgt40','1'); 
        end;

        if cycle ne . then call symput('cycle_not_missing','1'); 
    drop cycle; 
    %end; /* End of %if &CYCLE eq %then %do; */    

	/* BJC006 - move step from later up to here */
	
	%do b=1 %to &num_uns;
  
     /* BJC006: allow for cycle in unscheduled visit rows */
     /* BJC007: use direct string comparison instead of index */	 
     if visit="&&uns&b" then do;
      visit=trim(visit)||' - '||left(put(visitnum,7.2));    
     end;  
     visit=translate(visit,byte(32),byte(160));
    %end; 
	
  run;
  
/* DSS001: Stop conversion if VISIT values are greater than 40 characters */
 %if &visitgt40 eq 1 %then %do;
   %put %str(RTE)RROR: VISIT values > 40 characters in &memname;   
   %let syscc=999;
 %end;  

/* DSS001: Check if Cycle variable not in VISIT domain and present in other domains with values */
 %if %sysfunc(exist(pre_sdtm.visit)) %then %do;
  %if %tu_chkvarsexist(pre_sdtm.VISIT,CYCLE) ne and &cycle eq and &cycle_not_missing eq 1 %then %do;
    %let _cmd = %str(%str(RTW)ARNING: CYCLE variable missing from VISIT Domain); %tu_sdtmconv_sys_message;
  %end; 
 %end; 
   proc sql noprint;
    create table _pre_adjust_vis&v as 
    select distinct visit, visitnum , "&memname" as memname, "&libname" as libname
    from pre_sdtm.&memname;
   quit;
   
   data _pre_adjust_visit_distinct;
    set _pre_adjust_visit_distinct 
        _pre_adjust_vis&v;
   run; 
   
%end;

/*VA001: if VISITNUM = 999 or <1  in data then   ,
        it is expected that 999 would be slotted, and <1 is aberrant.*/    
%let dvobs = %eval(%tu_nobs(_pre_adjust_visit_distinct));
proc sql noprint; 
    select memname, round(visitnum,.01)
    into :memname1 - :memname%left(%trim(&dvobs)),
         :visitnum1 - :visitnum%left(%trim(&dvobs))
    from _pre_adjust_visit_distinct;
quit;

%do a=1 %to &dvobs;
    %if &&visitnum&a eq 999 %then %do;
        %let _cmd = %str(%STR(RTW)ARNING: Dataset &&memname&a has VISITNUM = 999, this needs to be slotted);%tu_sdtmconv_sys_message;
    %end;

    /* VISITNUMs of 0 are removed by the conversion code - but check for any aberrant values between 0 and 1 */
    %if (1 > &&visitnum&a > 0) and &&visitnum&a ne 0 and &&visitnum&a ne  %then %do;
        %let _cmd = %str(%STR(RTW)ARNING: Dataset &&memname&a has VISITNUM values between 0 and 1 i.e &&visitnum&a, Investigate/Rectify.);%tu_sdtmconv_sys_message;
    %end;
%end;

/* Get distinct visit and visitnum values overall for the datasets other than the ones we
   already know we need to update */

proc sql noprint;
create table _pre_adjust_visit_dup_check
as select * from _pre_adjust_visit_distinct
where memname not in (&visit_orig) 
   or memname='VISIT';
quit;
 
proc sort data=_pre_adjust_visit_dup_check 
      out=_pre_adjust_visit_unq nodupkey;
 by visitnum visit ;
run;
 
*******************************************************************************************;
/* Check for any aberrant values where one VISITNUM has different VISIT values across
    all the datasets */
proc sql noprint;
     create table _pre_adjust_visit_dup as 
     select distinct  visit , count(distinct visit)
     from _pre_adjust_visit_unq
     group by visitnum
     having count(distinct visit)>1 ;
quit;

%if &sqlobs>=1 %then %do;

  /* BJC005: dont report visitnum=0 differences as the VISIT/VISITNUM values are nulled later for SDTM */
  proc sql noprint;
   create table _pre_adjust_visit_dup_report as
    select distinct libname, memname, visit, visitnum
     from _pre_adjust_visit_distinct
     where memname not in (&visit_orig)
       and upcase(visit) not like 'UNS%'
	   and visitnum <> 0
       and trim(visit)||compress(put(visitnum,8.)) in
     (select trim(visit)||compress(put(visitnum,8.))
        from  _pre_adjust_visit_dup)
     order by visitnum, visit, memname, libname  ;
  quit;

  %if &sqlobs>=1 %then %do;

   %let _cmd = %str(%str(RTW)ARNING: VISIT values different for same VISITNUMs [see.lst file] - correct and re-run);
   %tu_sdtmconv_sys_message;
   proc print data=_pre_adjust_visit_dup_report;
    title3 "&g_study_id SDTM conversion : differing VISIT values for same VISITNUM across datasets";
    title4 "Define datasets where VISIT values need harmonising in visit_orig parmeter   OR ";
    title5 "correct/harmonise the data in pre program if it is incorrect e.g. external data values differ";
   run;
  %end;  
%end;
*******************************************************************************************;

/* For each dataset that is specified in visit_orig update VISIT values to harmonise VISIT data values */

%DO w=1 %TO %eval(%tu_nobs(_pre_adjust_visit_alt));

  ** For each iteration - update the VISIT values **;  
  data _null_ ;set _pre_adjust_visit_alt (where=(num=&w));
   call symput('memname',trim(memname));
  run;
 
  /* BJC002: add where clause at bottom of update to prevent update of null values where there is no
     matching VISITNUM value in VISIT */
  proc sql;
   update pre_sdtm.&memname p set visit=
        (select visit 
           from _pre_adjust_visit_unq v
          where p.visitnum=v.visitnum         
            and p.visit^=v.visit)         
            where p.visit not in (select distinct visit 
                                    from _pre_adjust_visit_unq)
              and p.visitnum in (select distinct visitnum
                                    from _pre_adjust_visit_unq);  
  quit;
  
%end;

/* end of bjc001 changes */

%endmac:

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_adjust_vis:,
glbmac = none
);

%end;
%mend tu_sdtmconv_pre_adjust_visit;
