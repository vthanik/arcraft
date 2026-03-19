/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_ds 
|
| Macro Version/Build:  4/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process DS data according to mapping specs
|                       The TYPE column can be kept in the work datset for debugging purposes.
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
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_ds 
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        10May2010
| New Version/Build Number:    2/1
| Reference:                   BJC001
| Description for Modification:output dataset name corrected and spelling mistakes in output text
| Reason for Modification:     ensure complete data conversion and coherent messages for user
|
| Modified By:                 Bruce Chambers
| Date of Modification:        18Jun2012
| New Version/Build Number:    3/1
| Reference:                   BJC002
| Description for Modification:check for subjects that are both SF and RIDO and flag
| Reason for Modification:     only one value can be inserted into DM domain ARM/ARMCD field
|
| Modified By:                 Bruce Chambers
| Date of Modification:        18Aug2012
| New Version/Build Number:    3/1
| Reference:                   BJC003
| Description for Modification:drop the IDSL variables as TERM/DECOD now contain data. Dont want dup maps.
| Reason for Modification:     only one value can be inserted into annotated eCRF metadata
|
| Modified By:                 Bruce Chambers
| Date of Modification:        11Jan2013
| New Version/Build Number:    4/1
| Reference:                   BJC004
| Description for Modification:remove code to swap specify field content 
| Reason for Modification:     this will be corrected in study source data, not generically here
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_ds(
);

/*
/* Check to see if secondary reasons are present in dataset 
/*  Set macro var to control later code execution based on absence/presence 
/**********************************************************************************/
   %local DSSBRSSP VISITNUM;
   %let DSSBRSCD = %tu_chkvarsexist(pre_sdtm.ds,DSSBRSCD,Y); 
   %let VISITNUM = %tu_chkvarsexist(pre_sdtm.ds,VISITNUM,Y);  

/*
/*  if DSSCATCD is missing from DS dataset then ABORT run
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.ds,DSSCATCD,Y) EQ %then %do;
      %put RTE%str(RROR): DS dataset missing required variable DSSCATCD, ABORTING Job...;
      %let syscc = 999;
      %goto FINI2;
    %end;

/*
/*  if DSRSCD is missing from DS dataset then ABORT run
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.ds,DSRSCD,Y) EQ %then %do;
      %put RTE%str(RROR): DS dataset missing required variable DSRSCD, ABORTING Job...;
      %let syscc = 999;
      %goto FINI1;
    %end;

/*
/*  if DSSBRSCD is missing from DS dataset then create missing values and continue
/**********************************************************************************/
   %if &DSSBRSCD EQ %then %do;
      %put %str(RTN)OTE: DS dataset variable DSSBRSCD is missing. Creating empty variable for DS processing;
      data pre_sdtm.ds;
         attrib DSSBRSCD format=$3.  length=$3  label='Subreason for disposition event code';
         attrib DSSBRS   format=$80. length=$80 label='Subreason for disposition event';
         set pre_sdtm.ds;
      run;
    %end;

/*
/*  if DSRSSP is missing from DS dataset then create missing values and continue
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.ds,DSRSSP,Y) EQ %then %do;
      %put %str(RTN)OTE: DS dataset variable DSRSSP is missing. Creating empty variable for DS processing;
      data pre_sdtm.ds;
         attrib DSRSSP   format=$200. length=$200 label='Reason for disposition event specify';
         set pre_sdtm.ds;
      run;
    %end;
   
/*
/*  if DSSBRSSP is missing from DS dataset then create missing values and continue
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.ds,DSSBRSSP,Y) EQ %then %do;
      %put %str(RTN)OTE: DS dataset variable DSSBRSSP is missing. Creating empty variable for DS processing;
      data pre_sdtm.ds;
         attrib DSSBRSSP   format=$200. length=$200 label='Subreason for disposition event specify';
         set pre_sdtm.ds;
      run;
    %end;

   proc sort data=pre_sdtm.ds;
      by subjid &visitnum dsfail dsrscd &DSSBRSCD; 
   run;

/* BJC004: remove code for : Correct SI datasets where specify text fields are not mapped correctly */

/*
/*  Set DSTERM and DSDECOD variables.  Also separate multiple DSTERMs/DEDECOD 
/*  in different datasets for transposing in next steps.
/**********************************************************************************/
   data pre_sdtm_ds1 mult_dsdecod (keep=subjid dssbrs &visitnum) mult_dsterm (keep=subjid dssbrs &visitnum); 
      set pre_sdtm.ds;
      length DSTERM DSDECOD DSTERMOT $200 ;
      by subjid &visitnum dsfail dsrscd &DSSBRSCD; 
      
      /* Define label here for transpose later - as if added by tu_decode no label will be present */
      attrib DSSBRS   label='Subreason for disposition event';

      if DSSCATCD = 5 then delete;

      if DSFAIL = 'N' then do;
         if DSSCATCD NE 1 then delete;
         if missing(DSRS) then 
            DSTERM = 'COMPLETED';
         else
            DSTERM = DSRS;
         DSDECOD = 'COMPLETED';
       end;  /* if DSFAIL = 'N' then do */
      
      if DSFAIL = 'Y' then do;
         if missing(DSSBRSCD) then do;
            if missing(DSRSSP) AND missing(DSSBRSSP)then
               DSTERM = DSRS;
            else if NOT(missing(DSRSSP)) then
               DSTERM = DSRSSP;
          end;  /* if missing(DSSBRSCD) then do */

          if NOT(missing(DSSBRSCD)) then do;
             if first.dsrscd + last.dsrscd = 2 then do;  /* Single subreason found */
                if missing(DSSBRSSP) then
                   DSTERM = put(DSSBRS,$NCOMPLT.);        
                else 
                   DSTERM = DSSBRSSP;
              end;
             else do;                                   /* MULTIPLE reasons for DSTERM */
                DSTERM = 'MULTIPLE';
                DSTERMOT = DSSBRSSP;
                output mult_dsterm;
              end;
           end;
         
         if DSSCATCD NE 2 then 
            DSDECOD = DSRS;
         else do;
            if first.dsrscd + last.dsrscd = 2 then   /* Single subreason found */
               if NOT(missing(DSSBRSCD)) then
                  DSDECOD = put(DSSBRS,$NCOMPLT.);
               else 
                  DSDECOD = DSRS;
            else do;                               /* MULTIPLE reasons for DSDECOD */
               DSDECOD = 'MULTIPLE';
               DSTERMOT = DSSBRSSP;
               /* BJC001 output dataset name corrected */
               output mult_dsdecod;
             end;
          end;
       end;  /* if DSFAIL = 'Y' then do */

      output pre_sdtm_ds1;
   run;

/* Transpose all the DSTERM variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm))>=1 %then %do;  

   proc transpose data=mult_dsterm out=transposed_dsterm (drop=_name_ _label_) prefix=DSTERM;
      var dssbrs;
      by subjid &visitnum;
   run;
  %end;
  
/* Transpose all the DSDECOD variables for each subjid */
  %if %eval(%tu_nobs(mult_dsdecod))>=1 %then %do;  
   proc transpose data=mult_dsdecod out=transposed_dsdecod(drop=_name_ _label_) prefix=DSDECOD;
      var dssbrs;
      by subjid &visitnum;
   run;
  %end;
  
   proc sort data=pre_sdtm_ds1;
       by subjid &visitnum;
   run;

/*
/* Create dataset for multiple DSTERMs and DEDECODs to be merged with in next step
/* Also save dataset where no merging will occur. 
/* Finally create an dataset to hold all the records which will be dropped.
/***********************************************************************************/
   data upd_ds_data noupd_ds_data delete_ds;
      set pre_sdtm_ds1;
    %if &visitnum eq %then %do;
      by subjid;
      if DSTERM = 'MULTIPLE' OR DSDECOD = 'MULTIPLE' then do;
         if first.subjid then output upd_ds_data;
         else output delete_ds;
       end;
     %end;
    %else %do;
      by subjid visitnum;
      if DSTERM = 'MULTIPLE' OR DSDECOD = 'MULTIPLE' then do;
         if first.visitnum then output upd_ds_data;
         else output delete_ds;
       end;
     %end;
      else output noupd_ds_data;
   run;

/* Merge the transposed datasets and the work dataset */
   data upd_ds_data;
      merge upd_ds_data(IN=A) 
       %if %eval(%tu_nobs(mult_dsterm))>=1 %then %do;  
        transposed_dsterm 
       %end;
       %if %eval(%tu_nobs(mult_dsdecod))>=1 %then %do;              
        transposed_dsdecod
       %end;
       ;
      by subjid &visitnum;
      if A;
   run;

/*
/* Put the merged and non-merged datasets together for DS processing to continue
/**********************************************************************************/
/* BJC003: drop the 4 source vars that are processed to SDTM ones - so that dummy mappings can be 
           present in MSA for tracability purposes */
   data pre_sdtm_ds_merged (drop=dsrs dssbrs dsrssp dssbrssp);
      set upd_ds_data noupd_ds_data;
   run;

   proc sort data=pre_sdtm_ds_merged out=pre_sdtm.ds;
       by subjid &visitnum;
   run;

%FINI1:
/* Create additional data to merge with DEMO data to populate ARM/ARMCD for untreated subjects */
   data ds_sub_demo(where=(dsfail='Y' and ARM^=''));
      set pre_sdtm.ds;
      length ARM $200 ARMCD $100;
      if DSSCATCD = 2 then do;
         ARMCD = "SCRNFAIL";
         ARM   = "Screen Failure";
       end;

      /* If after all this ARM and ARMCD are still null - then populate with not assigned 
      /  This will be applied to run in drop outs DSSCATCD = 3, but also any subjects who were
      / not randomised but who somehow ended up being treated (unusual but happens) */
      if ARM='' then do;
        ARMCD = "NOTASSGN";
        ARM   = "Not Assigned";
      end;              
   run;
  
   /* BJC002: identify any subjects that are both screen failure and RIDO and flag as ERROR and remove
              from the ds_sub_demo dataset. Data will need fixing before it can be processed. */

   proc sql noprint;
     create table dup_ds as
     select distinct subjid, count(arm)
	 from ds_sub_demo
	 group by subjid
	 having count( distinct arm) >=2 ;
	 
	 select trim(put(subjid,8.)) into :dup_ds_subjid separated by ',' from dup_ds order by subjid;	 
   quit; 
   
   %if %eval(%tu_nobs(dup_ds))>=1 %then %do;   
   
    /* Remove offending rows and flag to users to remediate data */
    proc sort data= ds_sub_demo;
	by subjid visitnum dsstdt;
	run;
	
	data ds_sub_demo; set ds_sub_demo;
	by subjid visitnum dsstdt;
	if last.subjid;
	run;

    %put RTE%str(RROR): DS dataset : following subjects are both screen failure and RIDO,  ;
	%put NOTE: The row from the latest visit/dsstdt is kept - earlier ones are removed.;
	%put Investigate/query data. Final/clean data must be cleaned and can NOT have this scenario - only for in-stream data.;
	%put Affected Subjid(s): &dup_ds_subjid ;
	%put These values are updated into DM.ARM[CD] for non-treated subjects.;
	%put DM domain only has one row per subjid. As per SDTM/CDISC rules a subject can only;
	%put end their involvement in a study once and so cannot be both SF and RIDO.;		
   %end;
   /* End of BJC002 change */   

%FINI2:
%mend tu_sdtmconv_pre_si_bespoke_ds;
