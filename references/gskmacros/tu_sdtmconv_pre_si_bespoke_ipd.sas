/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_ipdisc 
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Ashwin Venkat (based on Bruce's code for pespoke_ds)
|
| Date:                 5-May-2011
|
| Macro Purpose:        Pre-process IPDISC data according to mapping specs
|                       The TYPE column can be kept in the work datset for debugging purposes.
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
| (@)tu_chkvarsexist
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_ipd 
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 
| Date of Modification:        
| New Version/Build Number:    
| Reference:                   
| Description for Modification:
| Reason for Modification:     
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_ipd(
);

/* Check to see if secondary reasons are present in dataset 
  Set macro var to control later code execution based on absence/presence */
/**********************************************************************************/
   %local VISITNUM;
   %let VISITNUM = %tu_chkvarsexist(pre_sdtm.ipdisc,VISITNUM,Y); 
   %let SDSUBRCD = %tu_chkvarsexist(pre_sdtm.ipdisc,SDSUBRCD,Y);

/*
/*  if SDSUBRCD is missing from IPDISC dataset then create missing values and continue
/**********************************************************************************/
   %if &SDSUBRCD EQ %then %do;
      %put %str(RTN)OTE: IPDISC dataset variable SDSUBRCD is missing. Creating empty variable for IPDISC processing;
      data pre_sdtm.ipdisc;
         attrib SDSUBRCD format=$3.  length=$3  label='Subreason IP stopped code';
         attrib SDSUBR   format=$80. length=$80 label='Subreason IP stopped';
         set pre_sdtm.ipdisc;
      run;
    %end;

/*
/*  if SDRSSP is missing from IPDISC dataset then create missing values and continue
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.IPDISC,SDRSSP,Y) EQ %then %do;
      %put %str(RTN)OTE: IPDISC dataset variable SDRSSP is missing. Creating empty variable for IPDISC processing;
      data pre_sdtm.IPDISC;
         attrib SDRSSP   format=$200. length=$200 label='Reason IP stopped specify' ;
         set pre_sdtm.IPDISC;
      run;
    %end;
   
/*
/*  if SDSUBRSP is missing from IPDISC dataset then create missing values and continue
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.IPDISC,SDSUBRSP,Y) EQ %then %do;
      %put %str(RTN)OTE: IPDISC dataset variable SDSUBRSP is missing. Creating empty variable for IPDISC processing;
      data pre_sdtm.IPDISC;
         attrib SDSUBRSP   format=$200. length=$200 label='Subreason IP stopped, specify';
         set pre_sdtm.IPDISC;
      run;
    %end;

/*  Set DSTERM and DSDECOD variables.  Also separate multiple DSTERMs/DEDECOD 
/   in different datasets for transposing in next steps.*/
/**********************************************************************************/
 
 proc sort data=pre_sdtm.IPDISC;
  by subjid &visitnum sdrscd &SDSUBRCD;
    where sdstopp ='Y'; 
 run;
 
 data pre_sdtm_ipdisc1(drop=DSTERMOT) mult_dsdecod (keep=subjid dsdecod dsterm dstermot sdrs &visitnum) 
                       mult_dsterm (keep=subjid dsdecod dsterm dstermot sdsubr sdsubrsp &visitnum); 
      set pre_sdtm.IPDISC;
      length DSTERM DSDECOD DSTERMOT $200 ;
      by subjid &visitnum sdrscd SDSUBRCD; 
         
            if first.sdrscd + last.sdrscd = 2 then do;  /* Single reason found */
            /*testing my code */
                if missing(sdrssp) and missing(sdsubrcd) then do;
                    DSDECOD=put(SDRS,$NCOMPLT.);
                    DSTERM=put(SDRS,$NCOMPLT.);
                end;
                else if not(missing(sdrssp)) and missing(sdsubrcd) then do;
                    DSDECOD=put(SDRS,$NCOMPLT.);
                    DSTERM=sdrssp;
                end;
                else if not(missing(sdsubrcd)) and missing(SDSUBRSP) then do;
                    DSDECOD=put(SDRS,$NCOMPLT.);
                    DSTERM=sdsubr;
                end;
                else if not(missing(sdsubrcd)) and not(missing(SDSUBRSP)) then do;
                    DSDECOD= put(SDRS,$NCOMPLT.);                     
                    DSTERM= sdsubrsp;
                end;
           end;
     

            
          else do;                               /* MULTIPLE reasons for DSDECOD */
               DSDECOD = put(SDRS,$NCOMPLT.);
               DSTERM  = 'MULTIPLE';
               DSTERMOT = sdsubrsp;
               output mult_dsdecod;
               output mult_dsterm;               
           end;
       
      output pre_sdtm_ipdisc1;
run;

/* Transpose all the DSTERM variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm))>=1 %then %do;  
    /* concatenate SDSUBR + SDSUBRSP if present */
    data mult_dsterm ;
        set mult_dsterm;
        if not(missing(sdsubrsp)) and not(missing(sdsubr)) then do;
            sdsubr= sdsubrsp;
        end;
    run;

   proc transpose data=mult_dsterm out=transposed_dsterm (drop=_name_ _label_) prefix=DSTERM;
      var sdsubr;
      by subjid &visitnum;
   run;
  %end;
  
/* Transpose all the DSDECOD variables for each subjid */
  %if %eval(%tu_nobs(mult_dsdecod))>=1 %then %do;  
   proc transpose data=mult_dsdecod out=transposed_dsdecod(drop=_name_ _label_) prefix=DSDECOD;
      var sdrs;
      by subjid &visitnum;
   run;
  %end;
  
   proc sort data=pre_sdtm_ipdisc1;
       by subjid &visitnum;
   run;

/* Create dataset for multiple DSTERMs and DEDECODs to be merged with in next step */
/***********************************************************************************/
   data upd_ipdisc_data noupd_ipdisc_data delete_ipdisc;
      set pre_sdtm_ipdisc1;
    %if &visitnum eq %then %do;
      by subjid;
      if DSTERM = 'MULTIPLE' OR DSDECOD = 'MULTIPLE' then do;
         if first.subjid then output upd_ipdisc_data;
         else output delete_ipdisc;
       end;
     %end;
    %else %do;
      by subjid visitnum;
      if DSTERM = 'MULTIPLE' OR DSDECOD = 'MULTIPLE' then do;
         if first.visitnum then output upd_ipdisc_data;
         else output delete_ipdisc;
       end;
     %end;
      else output noupd_ipdisc_data;
   run;

/* Merge the transposed datasets and the work dataset */
   data upd_ipdisc_data;
      merge upd_ipdisc_data(IN=A) 
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

/* Put the merged and non-merged datasets together for IPDISC processing to continue */
/**********************************************************************************/
   data pre_sdtm_ipdisc_merged;
      set upd_ipdisc_data noupd_ipdisc_data;
   run;

   proc sort data=pre_sdtm_ipdisc_merged out=pre_sdtm.ipdisc;
       by subjid &visitnum;
   run;

%mend tu_sdtmconv_pre_si_bespoke_ipd;
