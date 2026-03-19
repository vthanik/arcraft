/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_drop_null_cols
|
| Macro Version/Build:  5/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Numerous columns are created earlier during transformation
|                       steps e.g. --ORRESU
|
|                       If a Perm(issible) column is present and all values are
|                       null then drop the column from the domain.
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
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pst_drop_null_cols
|
|*******************************************************************************
| Change Log:
|
| Modified By:                      Ashwin Venkat
| Date of Modification:             14September2010
| New Version/Build Number:         2/1
| Description for Modification:     VA001 :report number of blank entries for --ORRES ,--STRESC,
| Reason for Modification:          --ORRESU, --STRESC,--STRESN and --STRESU columns only after take 
|                                     into account if --STAT is populated
|  
| Modified By:                      Ashwin Venkat
| Date of Modification:             14September2010
| New Version/Build Number:         2/1
| Description for Modification:     VA002 :Suppress listing Exp variable --BLFL missing if --BLFL contains
| Reason for Modification:          some value atleast, and only report if --BLFL is               
|                                    all missing and is a EXP or REQ variable                                                         
|  
| Modified By:                      Bruce Chambers
| Date of Modification:             08October2010
| New Version/Build Number:         3/1
| Reference:                        BJC001
| Description for Modification:     correct item names for FA domains
| Reason for Modification:          the code was expecting FAMBSTAT and FAMBREASND columns/items, 
|                                   the correct item names are actually FASTAT and FAREASND                                                        
|
| Modified By:                      Bruce Chambers
| Date of Modification:             26November2010
| New Version/Build Number:         4/1
| Reference:                        BJC002
| Description for Modification:     To check All domains (including non CRF) for Exp/Req vars
| Reason for Modification:          Ensure SDTM compliance of all deliverables                                                      
|
| Modified By:                      Ashwin venkat
| Date of Modification:             9Feb2011
| New Version/Build Number:         5/1
| Reference:                        VA003
| Description for Modification:     Report if VISITNUM is EXP and is all missing
| Reason for Modification:                                               
|
*******************************************************************************/
%macro tu_sdtmconv_pst_drop_null_cols(
);

/* Get metadata details of datasets and column names. */
/* BJC001 : add dom_ref to SQL query to get domain model */
/* BJC002: expand driver query to also get non CRF domains and add libname  */

proc sql noprint;
 create table _pst_drop_all_cols as 
 (select distinct dc.libname, dc.memname, dc.name, ref.core, dr.dom_type, dr.domref
    from dictionary.columns dc, 
    reference ref,
    domain_ref dr
   where ( dc.libname='PST_SDTM' 
       and dc.name=ref.variable_name
       and dr.domain=ref.domain 
       and ( dc.memname in (select domain from sdtm_dom)
             or dc.memname in (select 'SUPP'||trim(domain) from sdtm_dom) )  
       and (dc.memname =dr.domain
            or substr(dc.memname,1,4)=dr.domain)) 
   %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;            
   UNION        
   (select distinct dc.libname, dc.memname, dc.name, ref.core, dr.dom_type, dr.domref
       from dictionary.columns dc, 
       reference ref,
       domain_ref dr
   where ( dc.libname = 'SDTMDATA'
      and dc.name=ref.variable_name
      and dr.domain=ref.domain 
      and dc.memname =dr.domain
      and dc.memname in ('TA','TE','TI','TS','TV','SE','RELREC')
      and dc.memname in (select domain from sdtm_dom) ))
   %end;   
      );
quit;

/* VISIT and VISITNUM in data with no matching defined SDTM columns will not be returned 
    by the above query, so get those as well */

/* BJC001 : add dom_ref to SQL query to get domain model */
proc sql noprint;
 create table _pst_drop_add_recs as 
 select dc.libname, dc.memname, dc.name, 'Perm' as core, dr.domref
   from dictionary.columns dc, domain_ref dr
  where dc.libname='PST_SDTM' 
    and dc.memname=dr.domain
    and dc.name in ('VISIT','VISITNUM')
    and dc.memname not in (select distinct domain 
                          from reference
                         where variable_name in ('VISIT','VISITNUM')); 
quit;

data _pst_drop_all_cols;
 set _pst_drop_all_cols 
     _pst_drop_add_recs;
run;

proc sort data=_pst_drop_all_cols;
by libname memname name;
run;

/* Get count of datasets to process */
proc sql noprint;
 select count(distinct memname)
   into :dsets_here
   from _pst_drop_all_cols;
quit;

/* Set local macro vars for datasets names and column counts */
%do i=1 %to &dsets_here;
 %local item_counts&i;
 %local memname&i;
%end;

/* Get macro vars in arrays defined with MEMNAME and column counts */

/* BJC001 : add dom_ref to SQL query to get domain model */
/* BJC002: add libname to query */

proc sql noprint;
 select count(distinct name), libname, memname, domref
   into :item_counts1 - :item_counts%left(&dsets_here),
        :dslib1 - :dslib%left(&dsets_here),
        :memname1 - :memname%left(&dsets_here),
        :domref1 - :domref%left(&dsets_here)
   from _pst_drop_all_cols 
   group by libname, memname, domref;
quit;
  
/* Create template datasets for later use */
data _pst_drop_flag_items;
   length name si_dset $32;
run;
data _pst_drop_drop_items;
   length name si_dset $32;
run;  
  
/* for each dataset loop through */
%do i=1 %to &dsets_here;

 /* Get a macro array of column names and the total obs in the dataset */
 proc sql noprint;
   select name, core, memname
   into :item_name1 - :item_name&&item_counts&i,
        :core1 - :core&&item_counts&i,
        :domname1 - :domname&&item_counts&i
   from _pst_drop_all_cols
   where memname="&&memname&i";
   
   select count(*) into :tot_recs from &&dslib&i...&&memname&i;
 quit;

/*VA001 :report number of blank entries for --ORRES ,--STRESC,       
  --ORRESU, --STRESC,--STRESN and --STRESU columns only after taking   
  into account if --STAT and/or --REASND is populated */                             
                                                                       
    /* for each column get a count of null values */
    %do j=1 %to &&item_counts&i;   
       
     proc sql noprint;
      create table _pst_drop_count_&j as 
      (select &tot_recs as total, "&&item_name&j" as name, count(*) as item_count 
       from &&dslib&i...&&memname&i
       where &&item_name&j is null
       
       %if %length(&&item_name&j)>=7 %then %do;
        %if %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,5) = SERRO or
         %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,6) = CSERTS or
         %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,6) = USERRO or
         %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,6) = CSERTS or 
         %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,6) = NSERTS or
         %substr(%sysfunc(reverse(%trim(&&item_name&j))),1,6) = USERTS  %then %do;
   
         /* BJC001 : use domain model to reference item names */
         %if %tu_chkvarsexist(&&dslib&i...&&memname&i,&&domref&i..REASND,Y) ne %then %do;
            and &&domref&i..REASND is null
         %end; 
         %if %tu_chkvarsexist(&&dslib&i...&&memname&i,&&domref&i..STAT,Y) ne %then %do;
            and &&domref&i..STAT is null
         %end;   
        %end; 
       %end;
       );
     quit;
/*VA003: Report if VISITNUM is EXP and is all missing */

       %let dropstr=%str(if total ^=. and (total=item_count) then do; type="&&core&j";output _pst_drop_drop_&&memname&i;end;);
       %let flagstr=%str(if total ^=. and (total^=item_count) then do; type="&&core&j";output _pst_drop_flag_&&memname&i;end;);
       %let flagvisstr=%str(if total ^=. and (total=item_count) and name = "VISITNUM" then do; type="&&core&j";output _pst_drop_flag_&&memname&i;end;);
       %let flagstrbl=%str(if total ^=. and (total=item_count) then do; type="&&core&j";output _pst_drop_flag_&&memname&i;end;);
       %let flagstr1=%str(data _pst_drop_flag_items; set _pst_drop_flag_items _pst_drop_flag_&&memname&i;);
       %let dropstr1=%str(data _pst_drop_drop_items; set _pst_drop_drop_items _pst_drop_drop_&&memname&i;);
        
       /* If the number of nulls equals the total then output to a drop or flag dataset based on Req/Perm */
       data  _pst_drop_drop_&&memname&i _pst_drop_flag_&&memname&i;
        attrib NAME length = $32 ;
        attrib si_dset length = $32 ;
        
        set _pst_drop_count_&j
       %if &j >1 %then %do;
        %if &&core&j=Perm %then %do; 
          _pst_drop_drop_&&memname&i 
        %end;      
        %if &&core&j=Req or &&core&j=Exp %then %do;
          _pst_drop_flag_&&memname&i
        %end;
       %end;
        ;
        si_dset="&&memname&i";
       
       /*IF its permitted and empty then drop it*/
       %if &&core&j=Perm %then %do;
                &dropstr
       %end;
          
/*VA002 :Suppress listing Exp variable --BLFL missing if --BLFL contains some value atleast, 
/       and only report if --BLFL values are all missing and is a EXP or REQ variable */                              
                                                                       
       /* If its a Required/Expected and empty column then flag this */
       
       %if &&core&j=Req or &&core&j=Exp %then %do;
        /* If its a BLFL variable then adding to flaging dataset*/
                &flagstr
                &flagvisstr;
                if length(name) >4 and substr(reverse(trim(left(name))),1,4) ="LFLB" then do;
                &flagstrbl
                end;
       %end;         
       run; 
        %if &&core&j=Req or &&core&j=Exp %then %do;
            &flagstr1;                                  
           if length(name) >4 and substr(reverse(trim(left(name))),1,4) ="LFLB" then do;
              if total^=item_count then delete;
           end;
       %end;        
       
       %if &&core&j=Perm %then %do;
         &dropstr1;
            if length(name) >4 and substr(reverse(trim(left(name))),1,4) ="LFLB" then do;
                 if total^=item_count then delete;
            end;
       %end;              
       
     %end;  /* end of item loop. still in dataset loop */
    
    /*Remove empty leading row from template files */
    data _pst_drop_flag_items; 
     set _pst_drop_flag_items(where=(name^=''));
    run;
    
    data _pst_drop_drop_items; 
     set _pst_drop_drop_items(where=(name^=''));
    run;
    
    %if %eval(%tu_nobs(_pst_drop_flag_items))>=1 %then %do;  
     proc sort data=_pst_drop_flag_items nodupkey;
     by si_dset name;run;  
    %end;
    
    %if %eval(%tu_nobs(_pst_drop_drop_items))>=1 %then %do;  
     proc sort data=_pst_drop_drop_items nodupkey;
     by si_dset name;run;
    %end; 
**********************************************************************************;
 /* check by item to see if there are any empty required values to flag - then flag them */
    %if %eval(%tu_nobs(_pst_drop_flag_items))=0 %then %goto end_flag; 

    data _pst_drop_thisds_flag; 
     set _pst_drop_flag_items(where=(si_dset="&&memname&i"));
    run;
          
    /* create empty template dataset */
    data _pst_drop_miss_req;
     length problem_desc $60;
    run;
                
    %if %eval(%tu_nobs(_pst_drop_thisds_flag)) >=1 %then %do;
     
     /* Turn the flag dataset into commands to drop the columns */
     
      proc sql noprint;
        select count(*) into :flag_cols from _pst_drop_flag_&&memname&i;
      quit; 
            
      %do k=1 %to %eval(%tu_nobs(_pst_drop_thisds_flag)) ;
       %global flag_cols&k;
      %end;
            
      proc sql noprint;
        select name
        into :flag_cols1 - :flag_cols&k
        from _pst_drop_flag_items
        where si_dset="&&memname&i";
      quit;      
            
      data _pst_drop_missing_req_values;
       attrib problem_desc length=$60;
       %do k=1 %to %eval(%tu_nobs(_pst_drop_thisds_flag));
             si_var="&&flag_cols&k";
             si_dset="&&memname&i";
             problem_desc='Columns specifed as REQuired/EXPected with 1> missing values';output;
       %end;
      run;
           
      data _pst_drop_miss_req; 
       set _pst_drop_missing_req_values 
           _pst_drop_miss_req ;
      run;
                     
      %if &flag_cols >=1 %then %do;
        %put &&memname&i has the following flagged as the EXPected/REQuired column contents are null for some rows;           
      %end;
                     
      %do k=1 %to &flag_cols;
        %put &&flag_cols&k;
        %symdel flag_cols&k;
      %end;     
           
    %end;
    %else %if %eval(%tu_nobs(_pst_drop_thisds_flag)) =0 %then %do;
      %put &&memname&i has had no null missing required values flagged.;
    %end;
 
    %end_flag:
             
    **********************************************************************************;  
    /* check by dataset to see if there are any null columns to drop - then drop them */
    %if %eval(%tu_nobs(_pst_drop_drop_items))=0 %then %goto end_drop; 

    data _pst_drop_thisds_drop; 
     set _pst_drop_drop_items(where=(si_dset="&&memname&i"));
    run;
    
    %if %eval(%tu_nobs(_pst_drop_thisds_drop))>=1 %then %do; 
     
     /* Turn the drop dataset into commands to drop the columns */
     proc sql noprint;
      select count(*) into :drop_cols from _pst_drop_thisds_drop;
     quit;
        
     %do k=1 %to %eval(%tu_nobs(_pst_drop_thisds_drop));
      %global drop_cols&k;
     %end;
    
     proc sql noprint;
       select name
       into :drop_cols1 - :drop_cols&k
       from _pst_drop_drop_items
       where si_dset="&&memname&i";
     quit;
   
    
     data &&dslib&i...&&memname&i;
      set &&dslib&i...&&memname&i;
      drop 
      %do k=1 %to &drop_cols;
            &&drop_cols&k
      %end;
      ;run;
   
      %if &drop_cols >=1 %then %do;
       %put &&memname&i has the following dropped as the permitted column contents are null for all rows;
      %end;
      
      %do k=1 %to &drop_cols;
            %put &&drop_cols&k;
            %symdel drop_cols&k;
      %end;      
      
    %end;
    %else %if %eval(%tu_nobs(_pst_drop_thisds_drop)) =0 %then %do;
      %put &&memname&i has had no null permitted columns dropped.;
    %end;
    
    %end_drop:
    
%end;/* end of dataset loop */

 proc sql noprint;
  select count(*) into :miss_req
    from _pst_drop_flag_items
   where type='Req';
 quit;
 
 %if &miss_req >=1 %then %do;
   %let _cmd=%str(%str(RTW)ARNING: One or more REQuired items present with missing values);%tu_sdtmconv_sys_message;
 %end;

 /* dont report removing of --REASND and --STAT fields each time */

 data _report_drop_items;
  set _pst_drop_drop_items;
  if length(name)>4 then do;
   if substr(reverse(trim(name)),1,4)='TATS' then delete;
  end; 
  if length(name)>6 then do;
   if substr(reverse(trim(name)),1,6)='DNSAER' then delete;
  end;
 run;
 
 data _report_flag_items;
  set _pst_drop_flag_items;
 run;

/* Clean up step */
%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pst_drop:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pst_drop_null_cols;
