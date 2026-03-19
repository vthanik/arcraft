/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_su
|
| Macro Version/Build:  6/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
| 
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process SUBUSE data according to mapping specs
|
|                       A general hint is to look at SUOCCUR in the mapping source
|                       We have to get separate rows for each SUOCCUR/VISIT combination.
|                       Clean up at the end to remove any null columns created by pre-processing
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
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_pre_defrag
| (@)tu_tidyup
| (@)tu_maclist
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_su
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers
| Date of Modification:         03Aug2010
| New Version/Build Number:     2/1
| Reference               :     bjc001
| Description for Modification: Add if/end to deal with SUBUSE data with no tobacco data collected 
| Reason for Modification:      To allow code to run for all possible scenarios.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         03Aug2010
| New Version/Build Number:     2/1
| Reference               :     bjc002
| Description for Modification: Add quoted separators to ensure clean log 
| Reason for Modification:      Add quoted separators to ensure clean log
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06Sep2010
| New Version/Build Number:     3/1
| Reference               :     bjc003
| Description for Modification: Simplify processing of tobacco questions to remove TB4 interim dataset
| Reason for Modification:      Get scenario that we expect to work for most studies.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06Sep2010
| New Version/Build Number:     3/1
| Reference               :     bjc004
| Description for Modification: Add PERIOD to list of header variables
| Reason for Modification:      Have PERIOD processed correctly.
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:         04Jan2011
| New Version/Build Number:     4/1
| Reference               :     DSS001
| Description for Modification: Add code not to report any SUBUSE variables which are not part of DM/SI 
| Reason for Modification:      To Report SUBUSE(DM/SI) variables only
|
| Modified By:                  Bruce Chambers
| Date of Modification:         18Jun2012
| New Version/Build Number:     5/1
| Reference               :     bjc005
| Description for Modification: To not drop date variables where all values are null in case a char 
|                               dup version is present as the pair is needed for date_driver macro later
| Reason for Modification:      Correctly converted date/times/char dups
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Feb2013
| New Version/Build Number:     6/1
| Reference               :     bjc006
| Description for Modification: To not process empty datasets 
| Reason for Modification:      Code will crash on empty dataset
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_su(
);

/* BJC006 : add if/end loop clause to skip empty dataset */
%if %eval(%tu_nobs(pre_sdtm.subuse))^=0 %then %do; 

/* Defragment the data - in this case get all data for one subject/visit/subtypcd on one row
/  the incoming source data often seems to be fragmented and we need all the values for one 
/  sutyp(cd) on one row per visit  */

%tu_sdtmconv_pre_defrag(
                        pre_sdtm.subuse, 
                        SUTYPCD
                        );

/* Subuse is a tricky one as we have to split it into one row for each type of substance 
/  and sometimes more than that e.g. one row for each SUOCCUR. for example - the various 
/  tobacco questions give 3 SUOCCUR values overall.*/

proc sql noprint;
  create table _pre_subuse_ds_items as 
  select name from dictionary.columns
  where libname='PRE_SDTM' and memname='SUBUSE'
  and name not in ('STUDYID','USUBJID','SUBJID','VISIT','VISITNUM','SUSEQ','SUACTDY');
quit;

/* The tobacco data is tricky as there are 3 main items and various studies can have any one or all 3.
/  they are 'SUTOBUS','SUSM','SUSMHS'(also 'SUSMHSCD' for DM SI). so check the data for presence of these 
/  variables and assign the first one as being the primary one that the smoking details will be associated 
/  with the other smoking items will simply appear on separate rows as their own tests */

/* If run on DM SI with SUSMHSCD, then SUBMHS wont (yet) be present ...... may need to add in pre-processing */

/*BJC003 : change order variables are supplied in - most common first */
%let tbvars=%tu_chkvarsexist(pre_sdtm.subuse,SUSMHS SUSM SUTOBUS , Y);

/* bjc001 - add if-end statement for when no tobacco data collected */
%if &tbvars ne %then %do;

 %tu_maclist(
 string = &tbvars,
 delim = %STR(' '),
 prefix = TB,
 cntname = TB_NO
 );
 
%end;

/* Potential TB1-3 macro vars created - initilise them all for later code processing */
%if not %symexist(tb1) %then %let tb1=" ";
%if not %symexist(tb2) %then %let tb2=" ";
%if not %symexist(tb3) %then %let tb3=" ";

/*bjc002- add str to quoted separators to prevent various notes going to log */

%if &tb1=SUSMHS %then %let tb1=%quote(SUSMHS%str(",")SUSMHSCD);
%if &tb2=SUSMHS %then %let tb2=%quote(SUSMHS%str(",")SUSMHSCD);
%if &tb3=SUSMHS %then %let tb3=%quote(SUSMHS%str(",")SUSMHSCD);

/* Group the data into logical collections/groups of items. This is the crux of the 
/  pre-processing to break the IDSL data up into SUOCCUR rows in SDTM. The first item
/  in each list is the one that maps to SUOCCUR */

/* BJC003 - remove TB4 scenario from the next few steps */

data _pre_subuse_ds_items; 
 set _pre_subuse_ds_items;
  length sub_type $4;
  if name in ("&TB1",'SUCGSMDY','SUSMYR','SUPKYR','SUSMLSDT','SUFRSMDT','SUTOHS','SUTOHSCD',
              'SUFRSMTM','SUTOLSDT','SUTOLSD_','SUSMLSD_','SUFRSMD_','SUTOLS') then sub_type='TB1';  
  else if name in ("&TB2",'SUSMDY','SUSMDYCD','SUSMLV') then sub_type='TB2';  
  else if name in ("&TB3") then sub_type='TB3';
  
  else if name in ('SUNICTRT')   then sub_type='NR';  
  
  else if name in ('SUSLHS','SUSLHSCD','SUSLLSDT','SUSLLSD_') then sub_type='TBS1';    
  else if name in ('SUSMLSLV') then sub_type='TBS2';    
  
  else if name in ('SUBQHX','SUBQHXCD','SUBQLSDT','SUBQLSD_') then sub_type='BE1';
  else if name in ('SUBQLV') then sub_type='BE2';
  
  else if name in ('SUALUNWK','SUALUS','SUFRALDT','SUFRALTM','SUFRALD_') then sub_type='AL1';
  else if name in ('SUAL') then sub_type='AL2';
  
  else if name in ('SUCFSVDY','SUCFUS','SUFRCFDT','SUFRCFTM','SUFRCFD_') then sub_type='CF1';
  else if name in ('SUCF') then sub_type='CF2';

  /* the GENeral ones below in addition to the IDSL keys will apply to every row */
  /* BJC004: add PERIOD to list of general/header variables */
  else if name in ('PERIOD','SUDT','SUTYPCD','SUTYP','EVLINT','EVALINT','EVLINTCD') then sub_type='GEN';
  else sub_type='UNK';
run;

proc sort data=_pre_subuse_ds_items;
by name;

proc sort data=excluded(where=(type='ITEM'))
           out=_pre_subuse_excl_item;
by name; run;

/*DSS001*/
/* Add code not to report any SUBUSE variables which are not part of DM/SI */ 

proc sort data=dsm_meta out=dsm_meta1(rename=(var_nm=name));
by var_nm; 
run;

data _pre_subuse_ds_items;
 merge _pre_subuse_ds_items(in=a) 
       _pre_subuse_excl_item(in=b keep=name)
       dsm_meta1(in=c where=(dm_subset_flag='Y' and dataset_nm='SUBUSE')); /* So this will subset A&R only items */
 by name;
 if a and b and sub_type='UNK' then sub_type='KEY';
 if a and c then output;
run;

proc print data=_pre_subuse_ds_items(where=(sub_type='UNK')) noobs;
title3 "SDTM conversion: SUBUSE items not being pre-processed - notify developer";
var name sub_type;
run;

proc sort data=_pre_subuse_ds_items;
 by sub_type ; run;

data _pre_subuse_ds_items; 
 set _pre_subuse_ds_items end=last;
  by sub_type ;
  ft=first.sub_type;
  lt=last.sub_type;
 
  length nrstring cf1string cf2string tbs1string tbs2string be1string be2string tb1string tb2string tb3string al1string al2string nrstring1 cf1string1 
         cf2string1 tbs1string1 tbs2string1 be1string1 be2string1 tb1string1 tb2string1 tb3string1  al1string1 al2string1 $300;
  retain nrstring cf1string cf2string tbs1string tbs2string be1string be2string tb1string tb2string tb3string  al1string al2string nrstring1 cf1string1 
         cf2string1 tbs1string1 tbs2string1 be1string1 be2string1 tb1string1 tb2string1 tb3string1 al1string1 al2string1;

  if sub_type ='NR' then do;
   nrstring=trim(nrstring)||' not missing('||trim(name)||')';
   
   if not last.sub_type then do;
    nrstring=trim(nrstring)||' or ';
   end;
   nrstring1=trim(nrstring1)||' '||trim(name);
   if last.sub_type then do;
    nrstring='if '||trim(nrstring)||' then output _pre_subuse_nr;';
   end;
  end;

  else if sub_type ='TB1' then do;   
   tb1string=trim(tb1string)||' not missing('||trim(name)||')';   
   
   if not last.sub_type then do;
    tb1string=trim(tb1string)||' or ';
   end;
   tb1string1=trim(tb1string1)||' '||trim(name);
   if last.sub_type then do;
    tb1string='if '||trim(tb1string)||' then output _pre_subuse_tb1;';
   end;
  end;
  
  else if sub_type ='TB2' then do;   
   tb2string=trim(tb2string)||' not missing('||trim(name)||')';   
   
   if not last.sub_type then do;
    tb2string=trim(tb2string)||' or ';
   end;
   tb2string1=trim(tb2string1)||' '||trim(name);
   if last.sub_type then do;
    tb2string='if '||trim(tb2string)||' then output _pre_subuse_tb2;';
   end;
  end;  
  
  else if sub_type ='TB3' then do;   
   tb3string=trim(tb3string)||' not missing('||trim(name)||')';   
   
   if not last.sub_type then do;
    tb3string=trim(tb3string)||' or ';
   end;
   tb3string1=trim(tb3string1)||' '||trim(name);
   if last.sub_type then do;
    tb3string='if '||trim(tb3string)||' then output _pre_subuse_tb3;';
   end;
  end;  
    
  else if sub_type ='TBS1' then do;
   tbs1string=trim(tbs1string)||' not missing('||trim(name)||')';  
   
   if not last.sub_type then do;
    tbs1string=trim(tbs1string)||' or ';
   end;
   tbs1string1=trim(tbs1string1)||' '||trim(name);
   if last.sub_type then do;
    tbs1string='if '||trim(tbs1string)||' then output _pre_subuse_tbs1;';
   end;
  end;
  
  else if sub_type ='TBS2' then do;
   tbs2string=trim(tbs2string)||' not missing('||trim(name)||')';  
   
   if not last.sub_type then do;
    tbs2string=trim(tbs2string)||' or ';
   end;
   tbs2string1=trim(tbs2string1)||' '||trim(name);
   if last.sub_type then do;
    tbs2string='if '||trim(tbs2string)||' then output _pre_subuse_tbs2;';
   end;
  end;  
  
  else if sub_type ='AL1' then do;
   al1string=trim(al1string)||' not missing('||trim(name)||')';  
   
   if not last.sub_type then do;
    al1string=trim(al1string)||' or ';
   end;
   al1string1=trim(al1string1)||' '||trim(name);
   if last.sub_type then do;
    al1string='if '||trim(al1string)||' then output _pre_subuse_al1;';
   end;
  end;
  
  else if sub_type ='AL2' then do;
   al2string=trim(al2string)||' not missing('||trim(name)||')';  
   
   if not last.sub_type then do;
    al2string=trim(al2string)||' or ';
   end;
   al2string1=trim(al2string1)||' '||trim(name);
   if last.sub_type then do;
    al2string='if '||trim(al2string)||' then output _pre_subuse_al2;';
   end;
  end;  
  
  else if sub_type ='BE1' then do;
    be1string=trim(be1string)||' not missing('||trim(name)||')';  
    
   if not last.sub_type then do;
    be1string=trim(be1string)||' or ';
   end;
   be1string1=trim(be1string1)||' '||trim(name);
   if last.sub_type then do;
    be1string='if '||trim(be1string)||' then output _pre_subuse_be1;';
   end;
  end;
  
  else if sub_type ='BE2' then do;
    be2string=trim(be2string)||' not missing('||trim(name)||')';  
    
   if not last.sub_type then do;
    be2string=trim(be2string)||' or ';
   end;
   be2string1=trim(be2string1)||' '||trim(name);
   if last.sub_type then do;
    be2string='if '||trim(be2string)||' then output _pre_subuse_be2;';
   end;
  end;  
 
  else if sub_type ='CF1' then do;    
    cf1string=trim(cf1string)||' not missing('||trim(name)||')';  
    
    if not last.sub_type then do;
     cf1string=trim(cf1string)||' or ';
    end;
    cf1string1=trim(cf1string1)||' '||trim(name);
    if last.sub_type then do;
     cf1string='if '||trim(cf1string)||' then output _pre_subuse_cf1;';
    end;
  end;
 
  else if sub_type ='CF2' then do;    
    cf2string=trim(cf2string)||' not missing('||trim(name)||')';  
    
    if not last.sub_type then do;
     cf2string=trim(cf2string)||' or ';
    end;
    cf2string1=trim(cf2string1)||' '||trim(name);
    if last.sub_type then do;
     cf2string='if '||trim(cf2string)||' then output _pre_subuse_cf2;';
    end;
  end;

 
  if last then do;
   call symput('nrstring',trim(nrstring));
   call symput('al1string',trim(al1string));
   call symput('al2string',trim(al2string));
   call symput('tb1string',trim(tb1string));
   call symput('tb2string',trim(tb2string));
   call symput('tb3string',trim(tb3string));
   call symput('tbs1string',trim(tbs1string));
   call symput('tbs2string',trim(tbs2string));
   call symput('be1string',trim(be1string));
   call symput('be2string',trim(be2string));
   call symput('cf1string',trim(cf1string));
   call symput('cf2string',trim(cf2string));
   call symput('tb1string1',trim(tb1string1));
   call symput('tb2string1',trim(tb2string1));
   call symput('tb3string1',trim(tb3string1));
   call symput('nrstring1',trim(nrstring1));
   call symput('be1string1',trim(be1string1));
   call symput('be2string1',trim(be2string1));
   call symput('al1string1',trim(al1string1));
   call symput('al2string1',trim(al2string1));
   call symput('tbs1string1',trim(tbs1string1));
   call symput('tbs2string1',trim(tbs2string1));
   call symput('cf1string1',trim(cf1string1));
   call symput('cf2string1',trim(cf2string1));
  end;    
run;
 
/* split the types out and perform any type specific processing */
data _pre_subuse_al1  (drop=&al2string1 &nrstring1 &tb1string1 &tb2string1 &tb3string1 &be1string1 &be2string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_al2  (drop=&al1string1 &nrstring1 &tb1string1 &tb2string1 &tb3string1 &be1string1 &be2string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_tb1  (drop=&tb2string1 &tb3string1 &nrstring1 &al1string1 &al2string1 &tb3string1 &be1string1 &be2string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_tb2  (drop=&tb1string1 &tb3string1 &nrstring1 &al1string1 &al2string1 &tb3string1 &be1string1 &be2string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_tb3  (drop=&tb1string1 &tb2string1 &nrstring1 &al1string1 &al2string1 &be1string1 &be2string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_tbs1 (drop=&tbs2string1 &nrstring1 &al1string1 &al2string1 &be1string1 &be2string1 &tb1string1 &tb2string1 &tb3string1 &cf1string1 &cf2string1)
     _pre_subuse_tbs2 (drop=&tbs1string1 &nrstring1 &al1string1 &al2string1 &be1string1 &be2string1 &tb1string1 &tb2string1 &tb3string1 &cf1string1 &cf2string1)     
     _pre_subuse_be1  (drop=&be2string1 &nrstring1 &al1string1 &al2string1 &tb1string1 &tb2string1 &tb3string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)
     _pre_subuse_be2  (drop=&be1string1 &nrstring1 &al1string1 &al2string1 &tb1string1 &tb2string1 &tb3string1 &tbs1string1 &tbs2string1 &cf1string1 &cf2string1)     
     _pre_subuse_cf1  (drop=&cf2string1 &nrstring1 &al1string1 &al2string1 &tb1string1 &tb2string1 &tb3string1 &tbs1string1 &tbs2string1 &be1string1 &be2string1)
     _pre_subuse_cf2  (drop=&cf1string1 &nrstring1 &al1string1 &al2string1 &tb1string1 &tb2string1 &tb3string1 &tbs1string1 &tbs2string1 &be1string1 &be2string1)     
     _pre_subuse_nr  (drop=&al1string1 &al2string1 &tb1string1 &tb2string1 &tb3string1 &tbs1string1 &tbs2string1 &be1string1 &be2string1 &cf1string1 &cf2string1)
     ; 

  attrib SUTYP    length = $50 ; /* Increase current length for longer text*/
  attrib SUSTRF   length = $6 ;
  attrib SUENRF   length = $6 ;

 set pre_sdtm.subuse;  
  &al1string;
  &al2string;
  &tb1string;
  &tb2string;
  &tb3string;
  &cf1string;
  &cf2string;
  &tbs1string;
  &tbs2string;
  &be1string;
  &be2string;
  &nrstring;
run;

data _pre_subuse_nr; set _pre_subuse_nr;
 SUTYP='Nicotine replacement';
run;

data _pre_subuse_al1; set _pre_subuse_al1;
 if not missing(SUALUNWK) and SUALUS='' then SUAL='Y';
 if not missing(SUFRALDT) and SUALUS='' then SUAL='Y';
 if not missing(SUFRALD_) and SUALUS='' then SUAL='Y';
 if not missing(SUALUS) then SUTYP='Alcohol use in the defined period';
run;

data _pre_subuse_al2; set _pre_subuse_al2;
 if not missing(SUAL) then SUTYP='History of alcohol use';
run;

/* NB: The --STRF and --ENRF fields below are only populated where dates are not present 
/  This is as recommended by SDTM 312 IG (4.1.4.7) */

/* history of smoking use question */
%if %tu_chkvarsexist(_pre_subuse_tb1,SUSMHSCD) eq %then %do; 
 
  data _pre_subuse_tb1; set _pre_subuse_tb1;
   if SUSMHSCD=2 then do;
    if SUFRSMDT=. then SUSTRF='BEFORE';
    if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=. then SUENRF='AFTER';
   end;
   else if SUSMHSCD=3 then do;
      if SUFRSMDT=. then SUSTRF='BEFORE';
      if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=. then SUENRF='BEFORE';
   end;  
  run; 
%end;

/* history of smokeless tobacco use question */
%if %tu_chkvarsexist(_pre_subuse_tb1,SUSLHSCD) eq %then %do; 
 
  data _pre_subuse_tb1; set _pre_subuse_tb1;
   if SUSLHSCD=2 then do;
    if SUSMLSDT=. then SUSTRF='BEFORE';
    if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=. then SUENRF='AFTER';
   end;
   else if suslhscd=3 then do;
      if SUSMLSDT=. then SUSTRF='BEFORE';
      if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=. then SUENRF='BEFORE';
   end;  
  run; 
%end;

%if %tu_chkvarsexist(_pre_subuse_tb1,SUTOHSCD) eq %then %do; 
 
  data _pre_subuse_tb1; set _pre_subuse_tb1;
   if SUTOHSCD=2 then do;
    if SUSMLSDT=. then SUSTRF='BEFORE';
    if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=.  then SUENRF='AFTER';
   end;
   else if sutohscd=3 then do;
    if SUSMLSDT=. then SUSTRF='BEFORE';
    if SUSMLSDT=. or SUTOLSDT=. or SUSLLSDT=.  then SUENRF='BEFORE';
   end;  
  run; 
%end;

%if %tu_chkvarsexist(_pre_subuse_be1,SUBQHXCD) eq %then %do; 

  data _pre_subuse_be1; set _pre_subuse_be1;
   if SUBQHXCD=2 then do;
    if SUBQLSDT=. then SUSTRF='BEFORE';
    SUENRF='AFTER';
   end;
   else if SUBQHXCD=3 then do;
      if SUBQLSDT=. then SUSTRF='BEFORE';
      SUENRF='BEFORE';
   end;  
  run; 
%end;

%if %tu_chkvarsexist(_pre_subuse_tb1,SUSMYR) eq %then %do; 

 /* change SUSMYR from numeric to character and put in  ISO8601 format*/
 data _pre_subuse_tb1(drop=SUSMYR1);
   set _pre_subuse_tb1 (rename=(SUSMYR=SUSMYR1));
   length SUSMYR $10;
   if SUSMYR1>0 then SUSMYR = compress('P'||put(SUSMYR1,8.)||'Y');
 run;
 
%end;

/* If SUSMDYCD is present but no SUSMLV */
%if %tu_chkvarsexist(_pre_subuse_tb1,SUSMLV) eq %then %do; 
  
   data _pre_subuse_tb1; set _pre_subuse_tb1;
   attrib SUOCCUR length=$1 label='SU occurrence';
   if SUSMDYCD=1 then SUOCCUR='N';
   else if SUSMDYCD in (2,3) then do;
    SUOCCUR='Y'; /* SUSMDY Goes to Suppqual*/
   end;
  run; 
%end;

data _pre_subuse_be1; set _pre_subuse_be1;
  /*Split this smoking class into two distinct types - set apart from regular smoking
  / also one row in source can have more than one type, so delete any other*/
  if SUTYPCD=1 then SUTYP='History of betel quid/areca use';
  else if SUTYPCD=4 then SUTYP='Current betel quid/areca use'; 
  else delete;
run;

data _pre_subuse_tb2;
 set _pre_subuse_tb2 ;
   SUTYP='Tobacco use since last visit';
run;

/* combine the types back into one dataset */
data pre_sdtm.subuse; 
 set 
     %if %eval(%tu_nobs(_pre_subuse_nr))>=1 %then %do;
          _pre_subuse_nr 
     %end;
     %if %eval(%tu_nobs(_pre_subuse_al1))>=1 %then %do;
          _pre_subuse_al1
     %end;
     %if %eval(%tu_nobs(_pre_subuse_al2))>=1 %then %do;
          _pre_subuse_al2
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_tb1))>=1 %then %do;     
          _pre_subuse_tb1
     %end;          
     %if %eval(%tu_nobs(_pre_subuse_tb2))>=1 %then %do;     
          _pre_subuse_tb2     
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_tb3))>=1 %then %do;    
          _pre_subuse_tb3     
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_cf1))>=1 %then %do;
          _pre_subuse_cf1
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_cf2))>=1 %then %do;
          _pre_subuse_cf2
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_tbs1))>=1 %then %do;
          _pre_subuse_tbs1
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_tbs2))>=1 %then %do;
          _pre_subuse_tbs2
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_be1))>=1 %then %do;    
          _pre_subuse_be1
     %end; 
     %if %eval(%tu_nobs(_pre_subuse_be2))>=1 %then %do;
          _pre_subuse_be2
     %end; 
    
     ; 
run;

/* As we are turning one SI row into multiple rows - one for each 
   substance type - drop and recalculate the SEQ if present */
%if %tu_chkvarsexist(pre_sdtm.subuse,SUSEQ) eq %then %do; 
  data pre_sdtm.subuse; 
   set pre_sdtm.subuse(drop=suseq);
  run;
%end;

/* finally do a check for any blank columns added by the pre-processing - these should be
/  removed as they will make later traceability for define.xml very confused */

/* BJC005: Add 'and format not in ('DATE9.')' to the where clauses below. This is to ensure date 
   and char dup pairs are present for date driver macro later */

proc sql noprint;
 select nobs into :subuse_obs from dictionary.tables where libname='PRE_SDTM' and memname='SUBUSE';
  
 select count(*) into :numcols 
   from dictionary.columns
  where libname='PRE_SDTM' 
    and memname='SUBUSE' 
    and name not in ('STUDYID','SUBJID','VISIT','VISITNUM')
	and format not in ('DATE9.');
quit;

proc sql noprint;
  select distinct name into :name1- :name%left(&numcols) 
    from dictionary.columns
   where libname='PRE_SDTM' 
     and memname='SUBUSE' 
     and name not in ('STUDYID','SUBJID','VISIT','VISITNUM')
     and format not in ('DATE9.');
quit;   

proc sql noprint;
 %do a=1 %to &numcols; 
   select count(*) into :col&a from pre_sdtm.subuse where &&name&a is null; 
 %end; 
quit;

%do a=1 %to &numcols; 
 %if &&col&a = &subuse_obs %then %do;
  proc sql noprint;
   alter table pre_sdtm.subuse drop &&name&a;
  quit;
 %end;
%end; 

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_subuse_:,
 glbmac = none
);
%end;

/* BJC006 : add if/end loop clause to skip empty dataset */
%end;

%mend tu_sdtmconv_pre_si_bespoke_su;
