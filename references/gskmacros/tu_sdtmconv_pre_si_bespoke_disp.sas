/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_disp 
|
| Macro Version/Build:  4/1
|
| SAS Version:          9.1.3
|
| Created By:           Barry Ashby
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process DISPOSIT and SCRNFAIL data according to mapping specs
|
|                       NOTE: This code will not process more than 1 reason per subject,
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
|
| Output:
|
| Global macro variables created:
|
| Macros called:
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_disp 
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 06September2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     DSS001
| Description for Modification:  Remove libname statement which combined both DM and A&R into one
| Reason for Modification:       This libname statement is now added in tu_sdtmconv_sys_setup macro
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 18April2011
| New Version/Build Number: 	 V3 Build 1   
| Reference:                     DSS002
| Description for Modification:  
| Reason for Modification:       Code needs to populate SCREEN FAILURE subjects records from SCRNFAIL dataset as the 
|								 Disposit dataset will not have these records 
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 26July2011
| New Version/Build Number: 	 V4 Build 1   
| Reference:                     DSS003
| Description for Modification:  Create DSSCAT as a text variable by adding length statement.
| Reason for Modification:       Conversion gives an type error when we don�t have screenfail dataset to populate "DSSCAT'.
|                                Also check for SFTYP, SFDT & SFACTDY exist, as they are not SI variables.
|								 
*******************************************************************************/

%macro tu_sdtmconv_pre_si_bespoke_disp(
);

 /* DSS001 */
 /* Code removed from here and added to tu_sdtmconv_sys_setup */

/*
/* Check to see if visitnum is present in dataset 
/**********************************************************************************/
   %local VISITNUM;
   %let VISITNUM = %tu_chkvarsexist(pre_sdtm.disposit,VISITNUM,Y);  

/*
/*  if DSREASCD is missing from DISP dataset then ABORT run
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.disposit,DSREASCD,Y) EQ %then %do;
      %put RTE%str(RROR): DISPOSIT dataset missing required variable DSREASCD, ABORTING Job...;
      %goto FINI2;
    %end;

/*
/*  if DSWD is missing from DISP dataset then ABORT run
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.disposit,DSWD,Y) EQ %then %do;
      %put RTE%str(RROR): DISPOSIT dataset missing required variable DSWD, ABORTING Job...;
      %goto FINI2;
    %end;

/*
/*  if DSRSOTH is missing from DS dataset then create missing values and continue
/**********************************************************************************/
   %if %tu_chkvarsexist(pre_sdtm.disposit,DSRSOTH,Y) EQ %then %do;
      %put %str(RTN)OTE: DISPOSIT dataset variable DSRSOTH is missing. Creating empty variable for DISPOSIT processing;
      data pre_sdtm.disposit;
         attrib DSRSOTH format=$200. length=$200 label='Other specified reason for withdrawal';
         set pre_sdtm.disposit;
      run;
    %end;

   proc sort data=pre_sdtm.disposit out=disposit;
      by subjid &visitnum DSREASCD;
   run;

/* DSS002:
/*  Check if multiple reasons exists per subject in DISPSUB
/**********************************************************************************/
   %if %sysfunc(exist(combine.dispsub)) %then %do;
      
      proc sql noprint;
         select subjid, count(*) 
            from combine.dispsub
         group by subjid
         having count(*) gt 1;
      run;

      %if &sqlobs %then %do;
         %put Multiple sub-reasons exist per subject, CONTINUE further processing...;         
       %end;

/*  DSS002:  */
/*  Use DISPSUB with DISPOSIT to create the PRE DS domain dataset
/**********************************************************************************/
     proc sort data=combine.dispsub out=dispsub;
         by subjid &visitnum;
      run;

      data upd_disp;
         attrib DSREAS format=$200.;
         merge disposit dispsub;
         length DSTERM $200 ;
         by subjid &visitnum;
          
         if DSWD = 'N' then do;
            DSTERM = 'COMPLETED';
            DSREAS = 'COMPLETED';
         end;
         else if DSWD = 'Y' then do;
            DSREAS = put(DSREASCD,$DSREASS.);
            if missing(compress(DSSUBOTH)) then 
               if missing(compress(DSSUBRCD)) then 
                  DSTERM = put(DSREASCD,$DSREASS.);
               else
                  DSTERM = put(DSSUBRCD,$DSSUBRS.);
            else
               DSTERM = DSRSOTH;
          end;
      run;
	
/* Code added by Deepak Sriramulu (DSS002) to extract subjects with multiple reasons from DISPOSIT & DISPSUB dataset. */  
	
	proc sort data=upd_disp;
      by subjid &visitnum dsreascd;
    run;  
	
	data upd_disp mult_dsterm_decod;
        set upd_disp;	
		 by subjid &visitnum dsreascd;
			if first.dsreascd+last.dsreascd eq 1 then do;
				DSTERM = 'MULTIPLE';                      				
				DSREAS = 'MULTIPLE';				
			    output mult_dsterm_decod;
			end;
			output upd_disp;
    run;			

    %end;
/*
/*  Else Create the PRE DS domain dataset with DISPOSIT only
/**********************************************************************************/
   %else %do;

      data upd_disp mult_dsterm_decod;
         attrib DSREAS format=$200.;
         set disposit;
         length DSTERM $200 ;
         by subjid &visitnum DSREASCD;
          
         if DSWD = 'N' then do;
            DSTERM = 'COMPLETED';
            DSREAS = 'COMPLETED';
          end;
         else if DSWD = 'Y' then do;
            DSREAS = put(DSREASCD,$DSREASS.);
            if missing(compress(DSRSOTH)) then 
               DSTERM = put(DSREASCD,$DSREASS.);
            else
               DSTERM = DSRSOTH;
            if first.DSREASCD+last.DSREASCD eq 1 then do;
				DSTERM = 'MULTIPLE';                      
				DSREAS = 'MULTIPLE';				
			    output mult_dsterm_decod;
			end;			
          end;
		  output upd_disp;
      run;
    %end;

	/* Transpose all the DSTERM variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm_decod))>=1 %then %do;  
    proc transpose data=mult_dsterm_decod out=transposed_term (drop=_name_ _label_) prefix=DSTERM;
      var dssubr;
      by subjid &visitnum;
    run;
  %end;
  
  /* Transpose all the DSDECOD variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm_decod))>=1 %then %do;  
    proc transpose data=mult_dsterm_decod out=transposed_decod(drop=_name_ _label_) prefix=DSDECOD;
      var dssubr;
      by subjid &visitnum;
    run;
  %end;
  
/*
/* Create dataset for multiple DSTERMs and DEDECODs to be merged with in next step
/* Also save dataset where no merging will occur. 
/* Finally create an dataset to hold all the records which will be dropped.
/***********************************************************************************/
    data upd_disp_data delete_ds;
      set upd_disp;;
	%if &visitnum eq %then %do;
      by subjid;
      if DSTERM = 'MULTIPLE' then do;
         if first.subjid then output upd_disp_data;
         else output delete_ds;
       end;
    %end;
    %else %do;
      by subjid visitnum;
      if DSTERM = 'MULTIPLE' then do;
         if first.visitnum then output upd_disp_data;
         else output delete_ds;
       end;  
    %end;	   
      else output upd_disp_data;
    run;
   
   /* Merge the transposed datasets and the work dataset */
    data upd_disp_data;
      merge upd_disp_data(IN=A) 
       %if %eval(%tu_nobs(mult_dsterm_decod))>=1 %then %do;  
        transposed_term 
       %end; 
	   %if %eval(%tu_nobs(mult_dsterm_decod))>=1 %then %do;              
        transposed_decod
       %end;	   
       ;
      by subjid &visitnum;
      if A;
    run;
	
   data pre_sdtm.disposit;
      set upd_disp_data;
	  /* DSS003: Create DSSCAT as a text variable by adding length statement */
	  length DSSCAT $200;
   run;

%FINI1:

/* Create additional data to merge with DEMO data to populate ARM/ARMCD for untreated subjects.
/  The later module (bespoke_dm) will look for any ds_sub_demo work dataset to use as a feed for 
/  ARM/ARMCD values for untreated subjects. We dont use pre_sdtm library as this would then echo 
/  issues with this dataset to the driver.lst file */

   %if %sysfunc(exist(combine.scrnfail)) %then %do;
      data ds_sub_demo;
         set combine.scrnfail;
         length ARM $200 ARMCD $100;
         if sftypcd =2 then do;
            ARMCD = "SCRNFAIL" ;
            ARM   = "Screen Failure";
          end;
         if sftypcd in (1,3) then do;
            ARMCD = "NOTASSGN" ;
            ARM   = "Not Assigned";
          end;  
      run;
/* Code added by Deepak Sriramulu (DSS002) to extract Screen Failure subjects from SCRNFAIL dataset. */
/* DSS003: Check if STACTDY and SFTYP exists before using them in the code */
%let dsvars   = %str(DSFAIL DSDT DSSTDY DSREASCD DSREAS DSRSOTH);
%let sfvars   = %str(SFFAIL SFDT SFACTDY SFREASCD SFREAS SFRSOTH);
%let sfactdy  = %tu_chkvarsexist(combine.scrnfail,SFACTDY);
%let sftyp    = %tu_chkvarsexist(combine.scrnfail,SFTYP);
%let sffail   = %tu_chkvarsexist(combine.scrnfail,SFFAIL);
%let sfrfail  = %tu_chkvarsexist(combine.scrnfail,SFRFAIL);
%let sfdt     = %tu_chkvarsexist(combine.scrnfail,SFDT);
%let sfactdy  = %tu_chkvarsexist(combine.scrnfail,SFACTDY);
%let sfreascd = %tu_chkvarsexist(combine.scrnfail,SFREASCD);
%let sfreas   = %tu_chkvarsexist(combine.scrnfail,SFREAS);
%let sfrsoth  = %tu_chkvarsexist(combine.scrnfail,SFRSOTH);

    proc sort data = combine.scrnfail out = scrnfail;
          by subjid &visitnum             
          %if &sfreascd eq %then %do; sfreascd %end;
	  %if &sfreas eq %then %do; sfreas %end;; 
    run;	     
			 
    data scrnfail mult_dsterm_dsdecod;
/* DSS003: Check if SFTYP SFDT & SFACTDY exist, as they are not SI required variables */
	set scrnfail(keep=STUDYID -- VISIT SFTYPCD
							%if &SFTYP eq %then %do; SFTYP %end;	                          
							%if &SFDT eq %then %do; SFDT %end;
							%if &SFACTDY eq %then %do; SFACTDY %end;
	                        %if &sfreascd eq %then %do; SFREASCD %end;
	                        %if &sfreas eq %then %do; SFREAS %end;
	                        %if &sfrsoth eq %then %do; SFRSOTH %end;       							
                            %if &sfrfail eq %then %do; SFRFAIL %end;
				            %if &sffail eq %then %do; SFFAIL where=(sffail eq 'Y' %end; 
				            %if &sfrfail eq %then %do; or SFRFAIL eq 'Y' %end;));									
    by subjid &visitnum           
    %if &sfreascd eq %then %do; SFREASCD %end;
	%if &sfreas eq %then %do; SFREAS %end;;       	
	length dsterm dsscat $200;			 
        visit = upcase(visit); 		        	 		
		    DSSCAT = strip(upcase(SFTYP));
			DSCAT = 'SCREEN FAILURE';
        %if (&sffail eq or &sfrfail eq ) and &sfreascd eq %then %do; 
		        SFREAS = put(SFREASCD,$SFREASS.); 				        	
            if missing(sfrsoth) then do;
			    DSTERM = put(SFREASCD,$SFREASS.); 	    		       			    		
			end;
			else if not missing(sfrsoth) then do;
				DSTERM = SFRSOTH;				
			end;
			if first.sfreascd + last.sfreascd eq 1 then do;
				DSTERM = 'MULTIPLE';                      
				DSDECOD = 'MULTIPLE';				
			    output mult_dsterm_dsdecod;
			end;
        %end;  

        %if &sffail eq %then %do;
		    if sffail eq 'N' then do;
			    DSTERM = 'COMPLETED'; 
			    DSDECOD = 'COMPLETED';				
			end;
        %end; 			
		
		%if &sfrfail eq %then %do;
		    if sfrfail eq 'N' then do;
			    DSTERM = 'COMPLETED'; 
			    DSDECOD = 'COMPLETED';				
			end;
		%end;		
                              
		rename 
            %do i=1 %to 6;	
			  %let vars = %scan(&sfvars,&i); 
			  %if &&&vars eq %then %do;
       	        %scan(&sfvars,&i) = %scan(&dsvars,&i)
			  %end;
            %end;;
            
            output scrnfail;
    run;   
	
	/* Transpose all the DSTERM variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm_dsdecod))>=1 %then %do;  
    proc transpose data=mult_dsterm_dsdecod out=transposed_dsterm (drop=_name_ _label_) prefix=DSTERM;
      var dsreas;
      by subjid &visitnum;
    run;
  %end;
  
  /* Transpose all the DSDECOD variables for each subjid */
  %if %eval(%tu_nobs(mult_dsterm_dsdecod))>=1 %then %do;  
    proc transpose data=mult_dsterm_dsdecod out=transposed_dsdecod(drop=_name_ _label_) prefix=DSDECOD;
      var dsreas;
      by subjid &visitnum;
    run;
  %end;
  
    proc sort data=scrnfail;
       by subjid &visitnum;
    run;

/*
/* Create dataset for multiple DSTERMs and DEDECODs to be merged with in next step
/* Also save dataset where no merging will occur. 
/* Finally create an dataset to hold all the records which will be dropped.
/***********************************************************************************/
    data upd_ds_data delete_ds;
      set scrnfail;
	%if &visitnum eq %then %do;
      by subjid;
      if DSTERM = 'MULTIPLE' then do;
         if first.subjid then output upd_ds_data;
         else output delete_ds;
       end;
    %end;
    %else %do;
      by subjid visitnum;
      if DSTERM = 'MULTIPLE' then do;
         if first.visitnum then output upd_ds_data;
         else output delete_ds;
       end;  
    %end;	   
      else output upd_ds_data;
    run;
   
   /* Merge the transposed datasets and the work dataset */
    data upd_ds_data;
      merge upd_ds_data(IN=A) 
       %if %eval(%tu_nobs(mult_dsterm_dsdecod))>=1 %then %do;  
        transposed_dsterm 
       %end; 
	   %if %eval(%tu_nobs(mult_dsterm_dsdecod))>=1 %then %do;              
        transposed_dsdecod
       %end;	   
       ;
      by subjid &visitnum;
      if A;
    run;
    
    /*
/* Put the merged and non-merged datasets together for DS processing to continue
/**********************************************************************************/   
    data pre_sdtm.disposit;
        set pre_sdtm.disposit upd_ds_data;
    run;
	
/* Code added by Deepak Sriramulu to extract Screen Failure subjects from SCRNFAIL dataset ends here */
 %end;
%FINI2:

%mend tu_sdtmconv_pre_si_bespoke_disp;
