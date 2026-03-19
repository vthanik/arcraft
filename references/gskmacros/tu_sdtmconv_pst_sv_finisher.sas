/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pst_sv_finisher
|
| Macro Version/Build: 6/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:          07-Jan-2011
|
| Macro Purpose: This program assesses all of the SDTM datasets in the      
|                specified library. The variables VISIT(NUM) and --DTC are pulled
|                from datasets which have them. The first and last visit dates   
|                for a particular visit (per subject) are used to augment SV.  
|
|          NOTE: If a subject visit has Time associated with either   
|                the end or start date but not both and the dates are 
|                the same, Time is removed from the --DTC values      
|                because the algorithm doesn't know which record      
|                actually came first.                                 
|
|                The code in this module is based heavily on the original prototype
|                written by Randall Austin and Wendy Sense. Credit to them.
|
|    Various checks of the data are made and output reported in the driver .lst file
| 
|    CHECK1: Check to see if there is a start date before the 'official'(original) start date 
|    CHECK2: use start date polled from across Domains if start date is missing in SV
|    CHECK3: populate end date by using start date polled from across Domains if end date is still 
|            missing in SV even after polling other domains 
|    CHECK4: Check to see if visit ranges overlap 
|    CHECK5: Flag where one VISIT has multiple VISITNUMs so this can be rectified
|
| Macro Design:  Procedure
|
| Input Parameters: optional date_window driver parameter (ts_sdtmconv) - defaults to 0 if not specified
|
| Output: augmented SV domain and any output from checks that are performed
|
| Global macro variables created:
|
| Macros called:
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         10May2011
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: Exclude BRTHDTC from the checks 
| Reason for Modification:      Correct output
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05Apr2012
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: Reduce text to fit on output line for all scenarios
| Reason for Modification:      Correct/readable output
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Aug2012
| New Version/Build Number:     4/1
| Reference:                    BJC003
| Description for Modification: Amend substr for shorter subjid definitions (from CRO)
| Reason for Modification:      Make checking code generic to work with GSK or CRO data
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Feb2013
| New Version/Build Number:     5/1
| Reference:                    BJC004
| Description for Modification: Populate SV.SVUPDES with a default value for non-integer values
| Reason for Modification:      Make data conform to IG rules
|
| Modified By:                  Bruce Chambers
| Date of Modification:         19Feb2013
| New Version/Build Number:     6/1
| Reference:                    BJC006
| Description for Modification: Refine population for SVENDTC
| Reason for Modification:      Use all available data
|
|*******************************************************************************/
   
%macro tu_sdtmconv_pst_sv_finisher(
);

  %local num;

  proc contents data=PST_SDTM._all_ noprint nodetails out=_sv_contout;
  run;
  
  /* For FINDINGS datsets, there may be a Visit End Date we can use to augment SV */
  data _sv_FINDINGS(keep=memname);
    set _sv_contout;
	
  if index(name,"TESTCD") then output;
  run;
  
  proc sort data=_sv_FINDINGS nodupkey; 
  by memname; run;

  /* Add length so can determine max length of --DTC variable across all input datasets 
  /-------------------------------------------------------------*/
  
  data _sv_DTC 
       _sv_VISIT (drop = length)
       _sv_VISITDESC (drop = length);  
    merge _sv_contout (keep=memname name length)
          _sv_FINDINGS (in=infind); /* identify FINDINGS datasets [ra001] */
	by memname;
        
    /* find assessment date variables, not start/end date variables */
	/* BJC001: also exclude BRTHDTC */
    if index(name,"DTC")  and not index(name,"RFTDTC") and not index(name,"STDTC") 
	   and not index(name,"BRTHDTC") and not index(name,"ENDTC") then output _sv_DTC;

    /* Only for FINDINGS datsets, create a record in DTC for Visit End Date */
    if infind and index(name,"ENDTC") then output _sv_DTC;
     
    /* Only for DS (event) dataset, create a record in DTC for Visit Start Date */
    if memname="DS" and index(name,"STDTC") then output _sv_DTC; 

    /* find visitnum */
    if index(name,"VISITNUM") then output _sv_VISIT;
    
    /* see whether dataset includes VISIT */
    if name="VISIT" then output _sv_VISITDESC;
  run;
  
  /* Find datasets with both VISITNUM and --DTC */
  data _sv_WANTED;
    length visitdesc $5;
    merge _sv_DTC(in=indtc 
              rename=(name=datevar)
              drop=length)
          _sv_VISIT(in=invisit) 
          _sv_VISITDESC(in=indesc) ;
    by memname;
    retain VISITDESC;
    if indtc and invisit;
    if first.memname then VISITDESC=" ";
    if indesc then VISITDESC="VISIT";
  run;
  
  /* Create macro variables representing each of the relevant dataset and variable names */
  
  data _null_;
  set _sv_wanted;
  call symput("DS"||left(_n_), memname);
  call symput("VAR"||left(_n_), datevar);
  call symput("NUM", _n_);
  call symput("VISIT"||left(_n_), visitdesc);
  run;  
  
  /* Get max length of --DTC across all domains in WANTED 
  /-------------------------------------------------------------*/
  
  proc sql noprint ;
    select max(length) into : dtcLength
    from _sv_dtc
    where memname in (select distinct memname 
                      from _sv_wanted) ;
  quit ;
  
  /* Sort each of the domain datasets by VISITNUM and visit date */
  /* Subset for records with both VISITNUM and visit date non-missing 
  /-------------------------------------------------------------*/
  
  %do x=1 %to &num;
  
    proc sort data=PST_SDTM.&&DS&x.(keep=STUDYID USUBJID VISITNUM &&VAR&x. &&VISIT&x.
                                rename = (&&VAR&x.=VISITDTC)
                                where = (not(missing(visitnum)) and not(missing(visitdtc))))
              out= _sv_S&x. nodupkeys; 
    by VISITNUM visitdtc STUDYID USUBJID ; 
    run;
   
    /* To aid debugging and data investigation add the source dataset name to the work data */
    data _sv_S&x.;
     set _sv_S&x.;
     length dset $4;
     dset="&&DS&x.";
    run; 
   
  %end;
  
  /* compile visitnums and visit dates from every domain into one dataset */
  data _sv_ALLVISITS;
    length visitdtc $&dtcLength ;    
    length VISIT $40; 
    set 
      %do x=1 %to &num; 
        _sv_S&x. 
      %end; 
      ;
    by VISITNUM VISITDTC STUDYID USUBJID ;
  run;
  
  /* get the VISIT description which goes with each VISITNUM (ignoring blanks) */
  proc sort data=_sv_allvisits(where=(VISIT ne "") keep=VISIT VISITNUM) out=_sv_visitlbl nodupkeys;
    by VISITNUM;
  run;
  
  /* add VISIT back into the data */
  /*------------------------------*/
  
  data _sv_allvisits; 
    merge _sv_allvisits (drop = visit )
          _sv_visitlbl ;
    by visitnum; 
  run;
  
  /* re-sort so we can find first and last visit date per subject */
  proc sort data=_sv_ALLVISITS nodupkey;
    by STUDYID USUBJID VISITNUM VISITDTC;
  run;
  
  /* get first and last visit date, by subject */
  data _sv_firstdate _sv_lastdate;
    set _sv_allvisits;
  by STUDYID USUBJID VISITNUM VISITDTC;
  if first.visitnum then do;
   f_vnum=visitnum;
   output _sv_firstdate;
  end; 
  if last.visitnum then do;
   l_vnum=visitnum;
   output _sv_lastdate;
  end; 
  run;
  
  /* Use existing SV domain as starting point. Bear in mind SV may have defaulted end dates
     already (from driver parameter), they may or may not get updated via this macro */
    
  proc sort data=PST_SDTM.sv out=_sv_sort;
  by usubjid visitnum;
  run;
  
  /* create SV by putting start and end on the same record */
  data _sv;
  merge _sv_firstdate(in=f rename=(visitdtc=_svstdtc dset=start_ds )) 
        _sv_lastdate (in=l rename=(visitdtc=_svendtc dset=end_ds )) 
        _sv_sort (in=sv);
  by usubjid visitnum;
  if (f or l) and not sv then added ='Y';
  run;
    
  data PST_SDTM.SV (drop=error _svstdtc _svendtc start_ds end_ds previous_end f_vnum l_vnum added diff)
       _sv_check1(drop=svendtc _svendtc end_ds previous_end f_vnum l_vnum) 
       _sv_check2(drop=error svendtc _svendtc end_ds previous_end f_vnum l_vnum )
       _sv_check3(drop=error svstdtc _svstdtc end_ds previous_end f_vnum l_vnum )
       _sv_check4(drop=error);
  /*  set length longer to allow for addition of times where needed */                 
  attrib SVSTDTC length = $20;
  attrib SVENDTC length = $20;
  set _SV;
  by usubjid visitnum;
  if added='Y' then domain='SV'; 
 
  /* CHECK1: Check to see if there is a start date before the 'official'(original) start date */
  
  if not missing(_svstdtc) and not missing(svstdtc) then do;
  
      /* If dates are complete but we find an earlier one elsewhere in the data then flag this 
         allow a window of a day as some assessments can be done the day before a visit */
      
      if substr(_svstdtc,1,10)^=substr(svstdtc,1,10) and length(_svstdtc)=10 
        and length(svstdtc)=10 and input(svstdtc,yymmdd10.) - input(_svstdtc,yymmdd10.) > &date_window then do;
        diff=input(svstdtc,yymmdd10.) - input(_svstdtc,yymmdd10.);
        
        /* If the difference in days is >28 then this could be an entry error in month or year.
           If below 28, then maybe the subject just came in early for a lab draw etc */
        if diff>28 then ERROR='Y';
        output _sv_check1;        
      end;
  end; 
    
  /* CHECK2: use start date polled from across Domains if start date is missing in SV.
     NB: This should never really happen for planned visits - but may happen for visits ADDED by this code */
  
  if missing(svstdtc) and not missing(_svstdtc) then do ;
     if added=' ' then output _sv_check2;
     if added='Y' then svstdtc = _svstdtc ;     
  end;  
  
  /* CHECK3: populate end date by using start date polled from across Domains if end date is still 
             missing in SV even after polling other domains.*/
  
  if missing(svendtc) and not missing(_svendtc) then do;
     if added=' ' then output _sv_check3;
	 /* BJC006 - refine SVENDTC population */
     if added='Y' and _svendtc^='' then svendtc = _svendtc ; /* NB: This was previously intentionally pulling from 
                                                                    start date but no note of why */	 
  end;
    
  /* if end has a time but start doesnt and they are on the same day then */ 
  /* remove time from end since we actually dont know whether the record  */
  /* with the time came first or last                                     */
  
  if (indexc("T", svendtc) and not indexc("T", svstdtc) )
    and (substr(svstdtc,1,10)=substr(svendtc,1,10))
    then svendtc = substr(svendtc,1,10);

  /* CHECK4: Check to see if visit ranges overlap  */
  
  retain previous_end;
  if first.usubjid then previous_end=svendtc;
  if (not indexc("T", previous_end) and not indexc("T", svstdtc) ) 
     and input(svstdtc,yymmdd10.) < input(previous_end,yymmdd10.) then do;
   output _sv_check4;
  end; 
  
  output PST_SDTM.sv;
 run;
    
 /* CHECK 5: Flag where one VISIT has multiple VISITNUMs so this can be rectified */   
 proc sql noprint;
    create table _sv_check5 as
    
    select distinct visit, visitnum from PST_SDTM.sv
    where trim(visit)||compress(put(visitnum,8.)) in 
    (select trim(visit)||compress(put(visitnum,8.)) from
     (select distinct visit, visitnum, count(distinct visitnum)
     from PST_SDTM.sv
     group by visit
      having count(distinct visitnum)>1 ));
 quit; 

 /* combine any issues reported into a dataset for the driver.lst file */
 
 data _report_sv_issues(keep=memname si_dset name problem_desc);
  set _sv_check1(in=a)
      _sv_check2(in=b)
      _sv_check3(in=c)
      _sv_check4(in=d)
      _sv_check5(in=e);
      
   length problem_desc $60;
   length name $8;
   length memname $8;
   length si_dset $8;

   memname='SV';
   si_dset='MULTIPLE';

   /* BJC002: remove a few chars from output to fit on line for all data scenarios */
   /* BJC003: remove a +1 from substr to make them generic */
   
   if a then do;
    name='SVSTDTC';
    problem_desc='USUBJID='||trim(put(substr(usubjid,index(usubjid,'.')+1,length(usubjid)-index(usubjid,'.')),8.))||',VISITNUM='||compress(put(visitnum,7.2))||' date '||compress(put(diff,8.))||' days prior in '||left(trim(start_ds));
    if error='Y' then problem_desc='*'||trim(problem_desc);
   end;
   
   if b then do;
    name='SVSTDTC';
    problem_desc='USUBJID='||trim(put(substr(usubjid,index(usubjid,'.')+1,length(usubjid)-index(usubjid,'.')),8.))||',VISITNUM='||compress(put(visitnum,7.2))||':missing SVSTDTC';
   end;
   
   if c then do;
    name='SVENDTC';
    problem_desc='USUBJID='||trim(put(substr(usubjid,index(usubjid,'.')+1,length(usubjid)-index(usubjid,'.')),8.))||',VISITNUM='||compress(put(visitnum,7.2))||':missing SVENDTC';
   end;
   
   if d then do;
    name='SVSTDTC';
    problem_desc='USUBJID='||trim(put(substr(usubjid,index(usubjid,'.')+1,length(usubjid)-index(usubjid,'.')),8.))||',VISITNUM='||compress(put(visitnum,7.2))||':date ranges overlap';
   end;
   
   if e then do;
    name='VISITNUM';
    problem_desc='VISIT='||trim(VISIT)||' has >1 VISITNUM='||compress(put(visitnum,7.2));
   end;
   
  run;
  
  
  /* BJC004: Populate SV.SVUPDES with a default value for non-integer values to make data conform to IG rules */
  
  data pst_sdtm.sv; set pst_sdtm.sv;
   length SVUPDES $17;
   if int(visitnum)^=visitnum then SVUPDES='UNSCHEDULED VISIT';
  run;

%if &sysenv=BACK %then %do;  

 %tu_tidyup(
  rmdset = _sv_:,
  glbmac = none
 );
%end;

/*Check datasets - produce RTWARNINGS when any these are populated */
      
%mend tu_sdtmconv_pst_sv_finisher;

