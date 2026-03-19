/*------------------------------------------------------------------------------
| Macro Name:         tu_cr8xml4vctr
|                     
| Macro Version:      2 build 1
|                     
| SAS Version:        9.3
|                     
| Created By:         Anthony J Cooper
|                     
| Date:               11-Feb-2016
|                     
| Macro Purpose:      To create XML files for a given data type for loading
|                     into VCTR from the input datasets supplied. Can also be
|                     called to delete existing XML files.
|                     
| Macro Design:       Procedure style.
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
|
| USAGE               Parameter which controls whether the macro   (Blank)
|                     creates the XML file or deletes the existing
|                     XML file.
|                     Valid values: CREATE or DELETE
|
| DATATYPE            Specifies the type of data being passed to   (Blank)
|                     the macro.
|                     Valid values: PARTFLOW, BASECHAR,
|                     FREQUENTAE or SERIOUSAE
|
| CR8USXMLYN          Specifies whether to create US format        Y
|                     results XML file.
|
| CR8EUXMLYN          Specifies whether to create EU format        Y
|                     results XML file.
|
| VCTRSTUDYID         Specifies the VCTR study identifier which    %upcase(&g_study_id)
|                     may be different to the HARP study
|                     identifier
|
| PFGROUPSDSET        Input dataset containing participant flow    (Blank)
|                     reporting groups data.
|                     Required when DATATYPE=PARTFLOW
|
| PFMSTONEDSET        Input dataset containing participant flow    (Blank)
|                     milestone data.
|                     Required when DATATYPE=PARTFLOW
|
| PFWITHDRAWDSET      Input dataset containing participant flow    (Blank)
|                     withdrawal reasons data.
|                     Required when DATATYPE=PARTFLOW
|
| BCGROUPSDSET        Input dataset containing baseline            (Blank)
|                     characteristics reporting groups data.
|                     Required when DATATYPE=BASECHAR
|
| BCDESCRDSET         Input dataset containing baseline            (Blank)
|                     characteristics description data.
|                     Required when DATATYPE=BASECHAR
|
| BCDATADSET          Input dataset containing baseline            (Blank)
|                     characteristics results data.
|                     Required when DATATYPE=BASECHAR
|
| AEFREQDSET          Input dataset containing adverse events      (Blank)
|                     frequency threshold data.
|                     Required when DATATYPE=FREQUENTAE
|
| AEGROUPSDSET        Input dataset containing adverse events      (Blank)
|                     reporting groups data.
|                     Required when DATATYPE=FREQUENTAE or 
|                     SERIOUSAE
|
| AEDATADSET          Input dataset containing adverse events      (Blank)
|                     results data.
|                     Required when DATATYPE=FREQUENTAE or 
|                     SERIOUSAE
|
|-------------------------------------------------------------------------------
| Output: XML results files. HTML messages file.
|-------------------------------------------------------------------------------
| Global macro variables created: NONE
|-------------------------------------------------------------------------------
| Macros called:
|(@) tu_putglobals
|(@) tu_chkvarsexist
|(@) tu_chkvartype
|(@) tu_nobs
|(@) tu_quotelst
|(@) tu_tidyup
|(@) tu_abort
|(@) tu_words
|-------------------------------------------------------------------------------
| Examples:
|   1. %tu_cr8xml4vctr(usage=DELETE,datatype=BASECHAR)
|   2. %tu_cr8xml4vctr(usage=CREATE,datatype=BASECHAR,bcgroupsdset=bc_groups,
|        bcdescrdset=bc_descr,bsdatadset=bc_data)
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By: Anthony J  Cooper
| Date of Modification: 02-Mar-2016
| New version number: 1 build 2
| Modification ID: AJC001
| Reason For Modification: bc_rep_group/bc_group_subjects field removed from
|                          EU results file XML schema
|
| Modified By: Anthony J  Cooper
| Date of Modification: 08-Apr-2016
| New version number: 1 build 3
| Modification ID: AJC002
| Reason For Modification: Updates resulting from VCTR System Integration Testing
|                          1. Add new macro parameter to allow VCTR study
|                             identifier to be passed in, which may be different
|                             to the HARP study identifier. Default is
|                             uppercase of HARP study identifier.
|                          2. Correct field names in SD_ARM_OTHER_MILESTONE table
|                          3. Populate ae_assessmentMethod for EU AE results
|                             files. As a result, ae_overview table is create
|                             for both serious and frequent AEs in EU results.
|                          4. Drop Total arm when creating EU Baseline
|                             Characteristics results when the baseline reporting
|                             model is arms (i.e. >1 arm).
|                          5. Drop periods/arms with 0 subjects started
|                             when creating EU Participant Flow results
|                          6. Delete HDR table via tu_tidyp for US results
|                             as well as EU results (xml_tables).
|                          7. Uppercase milestone title when using value in
|                             where clause processing.
|                          8. Correct total field names in EU AE results
|                          9. Correct field names in SD_POST_HEADER table
|                         10. Correct field name order in BC_AGE_CHARACTERISTIC
|                             and BC_GENDER_CATEGORICAL tables
|                         11. Drop withdrawal reasons with 0 subjects when
|                             creating EU Participant Flow results
|
| Modified By: Anthony J  Cooper
| Date of Modification: 02-Feb-2017
| New version number: 1 build 3
| Modification ID: AJC003
| Reason For Modification: Updates to US XML schema resulting from FDA final 
|                          ruling (HRT0318)
|                          1. Add all cause mortality fields to AE_ARMS table
|                             for serious Adverse Events
|                          2. Add "Product Issues" System Organ Class
|                          3. Change mapping of parameterType="NUMBER" from 
|                             "Number" to "CountOfParticipants" in BC_MEASURES
|                          4. For "CUSTOMIZED" measure titles create row titles
|                             otherwise create categories in BC_MEASURE_DATA
|                          5. Add various other new fields BC_ARMS,
|                             BC_ARMS_TOTAL, BC_MEASURES and BC_MEASURE_DATA
|-----------------------------------------------------------------------------*/

%macro tu_cr8xml4vctr(
  USAGE=,             /* Macro usage CREATE or DELETE */
  DATATYPE=,          /* Data type PARTFLOW, BASECHAR, FREQUENTAE or SERIOUSAE */
  CR8USXMLYN=Y,       /* Create US format results XML file? */
  CR8EUXMLYN=Y,       /* Create EU format results XML file? */
  VCTRSTUDYID=%upcase(&g_study_id), /* VCTR study identifier */
  PFGROUPSDSET=,      /* Particpant Flow Reporting Groups dataset */
  PFMSTONEDSET=,      /* Particpant Flow Milestones dataset */
  PFWITHDRAWDSET=,    /* Particpant Flow Withdrawals Reasons dataset */
  BCGROUPSDSET=,      /* Baseline Characteristics Reporting Groups dataset */
  BCDESCRDSET=,       /* Baseline Characteristics Measure Descriptions dataset */
  BCDATADSET=,        /* Baseline Characteristics Measure Results dataset */
  AEFREQDSET=,        /* Adverse Events Frequency Reporting Threshold dataset */
  AEGROUPSDSET=,      /* Adverse Events Reporting Groups dataset */
  AEDATADSET=         /* Adverse Events Results dataset */
  );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion MacroName;
  %let MacroVersion = 2 build 1;
  %let MacroName=&sysmacroname.;

  %put ************************************************************;
  %put * Macro name: &MacroName,  Macro Version: &macroVersion ;
  %put ************************************************************;

  %put * &MacroName has been called with the following parameters: ;
  %put * ;
  %put _local_;
  %put * ;
  %put ************************************************************;

  %tu_putglobals(varsin=g_study_id g_dddata) 

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/

  %let usage=%nrbquote(%upcase(&usage));
  %let datatype=%nrbquote(%upcase(&datatype));
  %let cr8usxmlyn=%nrbquote(%upcase(&cr8usxmlyn));
  %let cr8euxmlyn=%nrbquote(%upcase(&cr8euxmlyn));
  %let pfgroupsdset=%nrbquote(&pfgroupsdset);
  %let pfmstonedset=%nrbquote(&pfmstonedset);
  %let pfwithdrawdset=%nrbquote(&pfwithdrawdset);
  %let bcgroupsdset=%nrbquote(&bcgroupsdset);
  %let bcdescrdset=%nrbquote(&bcdescrdset);
  %let bcdatadset=%nrbquote(&bcdatadset);
  %let aefreqdset=%nrbquote(&aefreqdset);
  %let aegroupsdset=%nrbquote(&aegroupsdset);
  %let aedatadset=%nrbquote(&aedatadset);

  %if (&usage ne CREATE) and (&usage ne DELETE) %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: Value of USAGE (=&usage) is invalid. Valid value should be CREATE or DELETE;
     %let g_abort=1;
  %end;

  %if (&datatype ne PARTFLOW) and (&datatype ne BASECHAR) and (&datatype ne SERIOUSAE) and (&datatype ne FREQUENTAE) %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: Value of DATATYPE (=&datatype) is invalid. Valid value should be one of:;
     %put %str(RTE)RROR: &sysmacroname: PARTFLOW, BASECHAR, SERIOUSAE or FREQUENTAE;
     %let g_abort=1;
  %end;

  %if %length(&vctrstudyid) eq 0 %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter VCTRSTUDYID is required.;
     %let g_abort=1;
  %end; /* AJC002: Validation for VCTR study identifier parameter */

  %if &usage eq CREATE %then %do;
  
    %if (&cr8usxmlyn ne Y) and (&cr8usxmlyn ne N) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Value of CR8USXMLYN (=&cr8usxmlyn) is invalid. Valid value should be Y or N;
       %let g_abort=1;
    %end;

    %if (&cr8euxmlyn ne Y) and (&cr8euxmlyn ne N) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Value of CR8EUXMLYN (=&cr8euxmlyn) is invalid. Valid value should be Y or N;
       %let g_abort=1;
    %end;

    %if &datatype eq PARTFLOW %then %do;
    
      %if &pfgroupsdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter PFGROUPSDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&pfgroupsdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset PFGROUPSDSET(=&pfgroupsdset) does not exist.;
        %let g_abort=1;
      %end;
    
      %if &pfmstonedset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter PFMSTONEDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&pfmstonedset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset PFMSTONEDSET(=&pfmstonedset) does not exist.;
        %let g_abort=1;
      %end;

      %if &pfwithdrawdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter PFWITHDRAWDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;

      %else %if %tu_nobs(&pfwithdrawdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset PFWITHDRAWDSET(=&pfwithdrawdset) does not exist.;
        %let g_abort=1;
      %end;
   
    %end; /* %if &datatype eq PARTFLOW %then %do; */

    %else %if &datatype eq BASECHAR %then %do;
    
      %if &bcgroupsdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter BCGROUPSDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&bcgroupsdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset BCGROUPSDSET(=&bcgroupsdset) does not exist.;
        %let g_abort=1;
      %end;
    
      %if &bcdescrdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter BCDESCRDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&bcdescrdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset BCDESCRDSET(=&bcdescrdset) does not exist.;
        %let g_abort=1;
      %end;
    
      %if &bcdatadset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter BCDATADSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&bcdatadset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset BCDATADSET(=&bcdatadset) does not exist.;
        %let g_abort=1;
      %end;
    
    %end; /* %else %if &datatype eq BASECHAR %then %do; */

    %else %if &datatype eq FREQUENTAE %then %do;
    
      %if &aefreqdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter AEFREQDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&aefreqdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset AEFREQDSET(=&aefreqdset) does not exist.;
        %let g_abort=1;
      %end;
    
    %end; /* %else %if &datatype eq FREQUENTAE %then %do; */

    %if &datatype eq SERIOUSAE or &datatype eq FREQUENTAE %then %do;
    
      %if &aegroupsdset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter AEGROUPSDSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&aegroupsdset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset AEGROUPSDSET(=&aegroupsdset) does not exist.;
        %let g_abort=1;
      %end;
    
      %if &aedatadset eq %then %do;
        %put %str(RTE)RROR: &sysmacroname: The parameter AEDATADSET is required when DATATYPE is &datatype.;
        %let g_abort=1;
      %end;
      
      %else %if %tu_nobs(&aedatadset) lt 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname: The dataset AEDATADSET(=&aedatadset) does not exist.;
        %let g_abort=1;
      %end;
    
    %end; /* %if &datatype eq SERIOUSAE or &datatype eq FREQUENTAE %then %do; */

  %end; /* %if &usage eq CREATE %then %do; */
 
  %if &g_abort eq 1 %then %do;
    %tu_abort;
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  %local 
    prefix                         
    num_words
    xml_wrning
    xml_domain
    xml_tables
    xml_outputdir
    l_study_id
    xml_us_outfile
    xml_eu_outfile
    xml_msgfile
    pfNumPeriodID
    pfNumPeriodTitle
    pfGroupsVars
    pfMstoneVars                 
    pfWithdrawVars
    pfGroupsVarsMissing
    pfMstoneVarsMissing
    pfWithdrawVarsMissing 
    pfArmTypeList
    pfWithdrawReasonTypeList
    bcGroupsVars
    bcDescrVars
    bcDataVars
    bcGroupsVarsMissing
    bcDescrVarsMissing
    bcDataVarsMissing
    bcMeasureTitleList 
    bcParameterTypeList 
    bcDispersionTypeList
    bcArmTotal
    aeFreqVars
    aeGroupsVars
    aeDataVars
    aeFreqVarsMissing
    aeGroupsVarsMissing
    aeDataVarsMissing
    ;
  
  /* Root name for temporary work datasets */
  %let prefix = _cr8xml4vctr;

  /* Root name for temporary XML tables created - used in call to tu_tidyup */
  %if &datatype eq PARTFLOW and &cr8usxmlyn=Y %then %let xml_tables = PF_:;
  %else %if &datatype eq PARTFLOW  and &cr8euxmlyn=Y %then %let xml_tables = SD_:;
  %else %if &datatype eq BASECHAR %then %let xml_tables = BC_:;
  %else %let xml_tables = AE_:;
  %let xml_tables=HDR &xml_tables; /* AJC002: Always delete HDR table*/

  /* xml_domain is used in the file naming convention of the XML file */
  %if &datatype eq PARTFLOW %then %let xml_domain = PF;
  %else %if &datatype eq BASECHAR %then %let xml_domain = BC;
  %else %if &datatype eq SERIOUSAE %then %let xml_domain = SAE;   
  %else %if &datatype eq FREQUENTAE %then %let xml_domain = FAE;  

  /* xml_wrning is used to track any %str(war)ning messages created during dataset validation */
  %let xml_wrning=0;
  
  /*
  / Define list of expected variables for each dataset
  /----------------------------------------------------------------------------*/

  %let pfGroupsVars=studyID armID armTitle armDescription;
  %if &cr8euxmlyn=Y %then %let pfGroupsVars=&pfGroupsVars armType armTypeOther;

  %let pfMstoneVars=studyID periodID periodTitle armID armTitle armDescription 
    milestoneTitle milestoneData milestoneID;                
  
  %let pfWithdrawVars=studyID periodID periodTitle armID armTitle armDescription
    reasonType otherReasonName subjectsAffected reasonID;
  
  %let bcGroupsVars=studyID armID armTitle armDescription subjectsAnalyzed;

  %let bcDescrVars=studyID measureID measureTitle otherTitle measureDescription
    parameterType dispersionType unitOfMeasure; 

  %let bcDataVars=studyID measureID armID armTitle armDescription measureCategory categoryID
    parameterValue dispersionSpread dispersionLowerLimit dispersionUpperLimit; 
  %if &cr8usxmlyn=Y %then %let bcDataVars=&bcDataVars naComment;
     
  %let aeFreqVars=studyID frequencyReportingThreshold;

  %let aeGroupsVars=studyID armID armTitle armDescription;
  %if &datatype eq SERIOUSAE %then %do;
    /* AJC003: numDeathsAllCauses now required for US All Cause Mortality */
    %let aeGroupsVars=&aeGroupsVars numSubjectsSeriousEvents partAtRiskSeriousEvents numDeathsAllCauses;
    %if &cr8euxmlyn=Y %then %let aeGroupsVars=&aeGroupsVars numDeathsAdverseEvents;
  %end;
  %else
    %let aeGroupsVars=&aeGroupsVars numSubjectsFrequentEvents partAtRiskFrequentEvents;
      
  %let aeDataVars=studyID armID armTitle armDescription organSystemName aeTerm 
    numSubjectsAffected numSubjects numEvents eventID;
  %if &cr8euxmlyn=Y and &datatype eq SERIOUSAE %then 
    %let aeDataVars=&aeDataVars numEventsRelated numFatalities numFatalitiesRelated;

  /*
  / Define list of valid values for pick list variables
  /----------------------------------------------------------------------------*/

  %let pfArmTypeList="EXPERIMENTAL" "ACTIVECOMPARATOR" "PLACEBOCOMPARATOR" "NOINTERVENTION" "OTHER";

  %let pfWithdrawReasonTypeList="ADVERSE EVENT" "DEATH" "LACK OF EFFICACY" "LOST TO FOLLOW-UP"
    "PHYSICIAN DECISION" "PREGNANCY" "PROTOCOL VIOLATION" "WITHDRAWAL BY SUBJECT" "OTHER";

  %let bcMeasureTitleList="STUDY SPECIFIC CHARACTERISTIC" "AGE CONTINUOUS" "AGE CATEGORICAL"
    "AGE, CUSTOMIZED" "GENDER, MALE/FEMALE" "GENDER, CUSTOMIZED" "RACE (NIH/OMB)" "ETHNICITY (NIH/OMB)"
    "RACE/ETHNICITY, CUSTOMIZED" "REGION OF ENROLLMENT";
          
  %let bcAgeUnitList="YEARS" "MONTHS" "WEEKS" "DAYS" "HOURS" "MINUTES";          
          
  %let bcParameterTypeList="NUMBER" "MEAN" "MEDIAN" "LEAST SQUARES MEAN" "GEOMETRIC MEAN" "LOG MEAN";
  
  %let bcDispersionTypeList="NOT APPLICABLE" "STANDARD DEVIATION" "INTER-QUARTILE RANGE" "FULL RANGE";

  /*
  / Local macro to check if variables exist which are not required 
  /----------------------------------------------------------------------------*/

  %macro varsnotrequired(
    macroname=,
    dsetname=,
    dsetdescr=,
    varlist=
    );

    %local quotedvarlist;
    %let quotedvarlist=%tu_quotelst(%upcase(&varlist));

    proc contents data=&dsetname out=&prefix.contents noprint;
    run;
    
    data _null_;
      set &prefix.contents;
      if upcase(name) not in (&quotedvarlist) then
        put "RTNOTE: &macroname: Variable found in &dsetdescr dataset (&dsetname) which is not required for XML file."
          +1 "Variable name:" +1 name;
    run;

  %mend varsnotrequired;
  
  /*
  / Local macros to content of datasets passed to tu_cr8xml4vctr:
  /   checktype - Check variable type
  /   checklength - Check variable length against min/max values
  /   checkmissing - Check whether variable contains a missing value
  /   checklist - Check variable value against list of valid values
  /   checknumeric - Check variable contains numeric value
  /----------------------------------------------------------------------------*/

  %macro checktype(
    macroname=,
    dsetname=,
    dsetdescr=,
    variable=,
    type=
    );
  
    if "%sysfunc(compress(%tu_chkvartype(dsetin=&dsetname,varin=&variable)))" ne substr("&type",1,1) then do;
      err_flag=1;
      msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) must be type &type";
      put msg_text;
      output;
    end;
  
  %mend checktype;
  
  %macro checklength(
    macroname=,
    dsetname=,
    dsetdescr=,
    variable=,
    minlength=0,
    maxlength=
    );
  
    if &minlength gt 0 and length(&variable) lt &minlength and not(missing(&variable)) then do;
      err_flag=1;
      msg_text = "RTE"||"RROR: &macroname: Value of variable &variable in &dsetdescr dataset (&dsetname) "
      ||"is shorter than &minlength characters. &variable="||strip(&variable);
      put msg_text;
      output;
    end;
    else if length(&variable) gt &maxlength then do;
      wrn_flag=1;
      msg_text = "RTW"||"ARNING: &macroname: Value of variable &variable in &dsetdescr dataset (&dsetname) "
      ||"is greater than &maxlength characters. &variable="||strip(&variable)||". Variable will be truncated in XML file.";
      put msg_text;
      output;
    end;

  %mend checklength;

  %macro checkmissing(
    macroname=,
    dsetname=,
    dsetdescr=,
    variable=
    );
    
    * Special case: armDescription can be missing when armTitle is Total *;
    
    if missing(&variable) 
      %if &variable eq armDescription %then
        and not ("&variable" eq "armDescription" and upcase(armTitle) eq "TOTAL");
      then do;
      err_flag=1;
      msg_text = "RTE"||"RROR: &macroname: Value of required variable &variable in &dsetdescr dataset "
      ||"(&dsetname) is missing.";
      put msg_text;
      output;
    end;
    
  %mend checkmissing;
  
  %macro checklist(
    macroname=,
    dsetname=,
    dsetdescr=,
    variable=,
    valuelist=
    );
    
    if not missing(&variable) and upcase(&variable) not in (&valuelist) then do;
      err_flag=1;
      msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) "
      ||"contains an invalid value. &variable="||&variable;
      output;
      put msg_text;
    end;
        
  %mend checklist;
  
  %macro checknumeric(
    macroname=,
    dsetname=,
    dsetdescr=,
    variable=,
    maxvalue=,
    allowNA=N,
    naCommentVar=naComment
    );
    
    %if %tu_chkvartype(dsetin=&dsetname,varin=&variable) eq C %then %do;

      %if &allowNA eq N %then %do;
    
        if verify(compress(&variable),'0123456789.-') gt 0 then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) "
          ||"must contain a numeric value. &variable="||&variable;
          put msg_text;
          output;
        end;

      %end;

      %else %do;
    
        if &variable ne "NA" and verify(compress(&variable),'0123456789.-') gt 0 then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) "
          ||"must contain a numeric value or NA. &variable="||&variable;
          put msg_text;
          output;
        end;

        else if &variable eq "NA" then do;
          has_na=1;
          %if &cr8usxmlyn=Y %then %do;
            if missing(&naCommentVar) then do;
              err_flag=1;
              msg_text = "RTE"||"RROR: &macroname: Variable &naCommentVar in &dsetdescr dataset (&dsetname) "
              ||"must contain an explanation when the value of &variable is NA";
              put msg_text;
              output;
            end;
          %end;
        end;
      %end;
      
      %if %length(&maxvalue) gt 0 %then %do;
      
        else if input(&variable,best.) gt &maxvalue then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) "
          ||"is greater than &maxvalue. &variable="||&variable;
          put msg_text;
          output;
        end;
      
      %end;
    
    %end;
    
    %else %if %length(&maxvalue) gt 0 %then %do;
    
      if &variable gt &maxvalue then do;
        err_flag=1;
        msg_text = "RTE"||"RROR: &macroname: Variable &variable in &dsetdescr dataset (&dsetname) is "
        ||"greater than &maxvalue.. &variable="||strip(put(&variable,best.));
        put msg_text;
        output;
      end;
    
    %end;
  
  %mend checknumeric;
    
  /*
  / Determine path to documents directory which is used to construct the XML
  / output file name. 
  /----------------------------------------------------------------------------*/

  %let num_words = %tu_words(&g_dddata, delim = /\);

  %do n = 1 %to &num_words;
    %if &n eq 1 %then %do;
      %if "%substr(%left(&g_dddata),1,1)" eq "/" %then
        %let xml_outputdir = /%scan(&g_dddata, &n, /\);
      %else
        %let xml_outputdir = %scan(&g_dddata, &n, /\);
    %end;
    %else %if &n lt &num_words %then
      %let xml_outputdir = &xml_outputdir./%scan(&g_dddata, &n, /\);
    %else
      %let xml_outputdir = &xml_outputdir./documents;
    %if &g_debug gt 0 %then
      %put RTNOTE: n=&n xml_outputdir=&xml_outputdir;
  %end;

  /*
  / AJC002: Use VCTRSTUDYID parameter to create filename instead of G_STUDY_ID.
  / Change forward or backward slash to underscore if present. 
  /----------------------------------------------------------------------------*/

  %let l_study_id=%sysfunc(translate(&vctrstudyid,__,/\));

  %let xml_us_outfile = &xml_outputdir./&l_study_id._usresults_%lowcase(&xml_domain).xml;
  %let xml_eu_outfile = &xml_outputdir./&l_study_id._euresults_%lowcase(&xml_domain).xml;
  %let xml_msgfile = &xml_outputdir./&l_study_id._messages_%lowcase(&xml_domain).html;

  /*
  / When usage is CREATE, check that required variables exist on input datasets
  / and that the content is correct before creating the XML file.
  /----------------------------------------------------------------------------*/

  %if &usage eq CREATE %then %do;
  
    /*
    / Step 1: Check that all required variables exist. Conversely, check whether
    /         there are any variables which are not needed.
    /----------------------------------------------------------------------------*/
    
    options noQuoteLenMax;

    %if &datatype eq PARTFLOW %then %do;
    
      %let pfGroupsVarsMissing=%tu_chkvarsexist(dsetin=&pfgroupsdset,varsin=&pfGroupsVars);
        
      %if %nrbquote(&pfGroupsVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &pfGroupsVarsMissing - do not exist in Reporting Groups dataset (&pfgroupsdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&pfgroupsdset,
        dsetdescr=Reporting Groups,
        varlist=&pfGroupsVars
        );
        
      %let pfMstoneVarsMissing=%tu_chkvarsexist(dsetin=&pfmstonedset,varsin=&pfMstoneVars);
        
      %if %nrbquote(&pfMstoneVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &pfMstoneVarsMissing - do not exist in Milestones dataset (&pfmstonedset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&pfmstonedset,
        dsetdescr=Milestones,
        varlist=&pfMstoneVars
        );
              
      %let pfWithdrawVarsMissing=%tu_chkvarsexist(dsetin=&pfwithdrawdset,varsin=&pfWithdrawVars);
        
      %if %nrbquote(&pfWithdrawVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &pfWithdrawVarsMissing - do not exist in Withdrawal Reasons dataset (&pfwithdrawdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&pfwithdrawdset,
        dsetdescr=Withdrawal Reasons,
        varlist=&pfWithdrawVars
        );
              
    %end; /* %if &datatype eq PARTFLOW %then %do; */

    %else %if &datatype eq BASECHAR %then %do;

      %let bcGroupsVarsMissing=%tu_chkvarsexist(dsetin=&bcgroupsdset,varsin=&bcGroupsVars);
        
      %if %nrbquote(&bcGroupsVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &bcGroupsVarsMissing - do not exist in Reporting Groups dataset (&bcgroupsdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&bcgroupsdset,
        dsetdescr=Reporting Groups,
        varlist=&bcGroupsVars
        );
        
      %let bcDescrVarsMissing=%tu_chkvarsexist(dsetin=&bcdescrdset,varsin=&bcDescrVars);
        
      %if %nrbquote(&bcDescrVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &bcDescrVarsMissing - do not exist in Measure Descriptions dataset (&bcdescrdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&bcdescrdset,
        dsetdescr=Measure Descriptions,
        varlist=&bcDescrVars
        );
        
      %let bcDataVarsMissing=%tu_chkvarsexist(dsetin=&bcdatadset,varsin=&bcDataVars);
        
      %if %nrbquote(&bcDataVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &bcDataVarsMissing - do not exist in Measure Results dataset (&bcdatadset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&bcdatadset,
        dsetdescr=Measure Results,
        varlist=&bcDataVars
        );
        
    %end; /* %if &datatype eq BASECHAR %then %do; */

    %else %if &datatype eq FREQUENTAE %then %do;

      %let aeFreqVarsMissing=%tu_chkvarsexist(dsetin=&aefreqdset,varsin=&aeFreqVars);
        
      %if %nrbquote(&aeFreqVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &aeFreqVarsMissing - do not exist in Frequency Reporting Threshold dataset (&aefreqdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&aefreqdset,
        dsetdescr=Frequency Reporting Threshold,
        varlist=&aeFreqVars
        );
        
    %end; /* %if &datatype eq FREQUENTAE %then %do; */

    %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do;
    
      %let aeGroupsVarsMissing=%tu_chkvarsexist(dsetin=&aegroupsdset,varsin=&aeGroupsVars);
        
      %if %nrbquote(&aeGroupsVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &aeGroupsVarsMissing - do not exist in Reporting Groups dataset (&aegroupsdset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&aegroupsdset,
        dsetdescr=Reporting Groups,
        varlist=&aeGroupsVars
        );
        
      %let aeDataVarsMissing=%tu_chkvarsexist(dsetin=&aedatadset,varsin=&aeDataVars);
        
      %if %nrbquote(&aeDataVarsMissing) ne %then %do; 
        %put %str(RTE)RROR: &macroname: Required variables - &aeDataVarsMissing - do not exist in Adverse Event Results dataset (&aedatadset);
        %let g_abort=1;
      %end;
  
      %varsnotrequired(
        macroname=&macroname,
        dsetname=&aedatadset,
        dsetdescr=Adverse Event Results,
        varlist=&aeDataVars
        );
    
    %end; /* %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do; */

    options QuoteLenMax;

    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;

    /*
    / Step 2: Now we know we have required variables we can check the contents
    /----------------------------------------------------------------------------*/

    %if &datatype eq PARTFLOW %then %do;
    
      /*
      / Check the participant flow reporting groups dataset
      /----------------------------------------------------------------------------*/

      proc sort data=&pfgroupsdset out=&prefix.pfgroupssort;
        by armID;
      run;
    
      data &prefix.checks1 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 1 msg_sectionTitle "Reporting Groups" err_flag 0 wrn_flag 0;
        set &prefix.pfgroupssort end=last;
        by armID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armDescription,type=Character);
          %if &cr8euxmlyn=Y %then %do;
            %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armType,type=Character);
            %checktype(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armTypeOther,type=Character);
          %end;
        end;                
                
        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armID);
        %checkmissing(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armTitle);

        %if &cr8euxmlyn=Y %then %do;
          if upcase(armType) eq "OTHER" and missing(armTypeOther) then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Variable armTypeOther in Reporting Groups dataset (&pfgroupsdset) "
              ||"must be populated when armType is Other";
            put msg_text;
            output;
          end;        
        %end;

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armDescription,maxlength=999);
        %if &cr8euxmlyn=Y %then %do;
          %checklength(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armTypeOther,maxlength=50);
        %end;

        * Check valid values *;               
        %if &cr8euxmlyn=Y %then %do;
          %checklist(macroname=&macroname,dsetname=&pfgroupsdset,dsetdescr=Reporting Groups,variable=armType,valuelist=&pfArmTypeList);
        %end;

        * Check only one observation per armID *;

        if not (first.armID and last.armID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for armID="||compress(put(armID,8.))
          ||" in Reporting Groups dataset (&pfgroupsdset).";
          put msg_text;
          output;
        end;

        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;
      
      /*
      / Check the participant flow milestone dataset
      /----------------------------------------------------------------------------*/

      proc sql noprint;
        select count(distinct periodID), count(distinct periodTitle) into :pfNumPeriodID, :pfNumPeriodTitle
        from &pfmstonedset
        ;
      quit;
      
      proc sort data=&pfmstonedset out=&prefix.pfmstonesort;
        by periodID armID milestoneID;
      run;
    
      data &prefix.checks2 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 2 msg_sectionTitle "Milestones" err_flag 0 wrn_flag 0 has_started has_completed 0;
        set &prefix.pfmstonesort end=last;
        by periodID armID milestoneID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=periodID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=periodTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneData,type=Numeric);
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=periodID);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=periodTitle);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armID);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armTitle);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneTitle);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneID);
        %checkmissing(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneData);

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=periodTitle,minlength=2,maxlength=40);
        %checklength(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=armDescription,maxlength=999);
        %checklength(macroname=&macroname,dsetname=&pfmstonedset,dsetdescr=Milestones,variable=milestoneTitle,minlength=2,maxlength=40);

        * Check valid values *;               

        if &pfNumPeriodID eq 1 and &pfNumPeriodTitle eq 1 and upcase(periodTitle) ne "OVERALL STUDY" then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable periodTitle in Milestones dataset (&pfmstonedset) "
            ||"must equal 'Overall Study' when there is only 1 period.";
          put msg_text;
          output;
        end;
        
        else if &pfNumPeriodID gt 1 and &pfNumPeriodTitle gt 1 and upcase(periodTitle) eq "OVERALL STUDY" then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable periodTitle in Milestones dataset (&pfmstonedset) "
          ||"must not equal 'Overall Study' when there is >1 period.";
          put msg_text;
          output;
        end;
        
        * Check for required milestones *;
                
        if upcase(milestoneTitle) eq 'STARTED' then do;
          has_started=1;
          if not missing(milestoneID) and milestoneID ne 1 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Variable milestoneID in Milestones dataset (&pfmstonedset) "
              ||"must equal 1 when milestoneTitle is STARTED.";
            put msg_text;
            output;
          end;
        end;
        else if upcase(milestoneTitle) eq 'COMPLETED' then do;
          has_completed=1;
          if not missing(milestoneID) and milestoneID ne 2 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Variable milestoneID in Milestones dataset (&pfmstonedset) "
              ||"must equal 2 when milestoneTitle is COMPLETED.";
            put msg_text;
            output;
          end;
        end;
          
        * Check only one observation per periodID/armID/milestoneID *;

        if not (first.milestoneID and last.milestoneID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for periodID="||compress(put(periodID,8.))
          ||" armID="||compress(put(armID,8.))||" milestoneID="||compress(put(milestoneID,8.))
          ||" in Milestones dataset (&pfmstonedset).";
          put msg_text;
          output;
        end;

        if last then do;
          
          if has_started eq 0 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Milestones dataset (&pfmstonedset) must contain data for "
            ||"STARTED milestone.";
            put msg_text;
            output;
          end;
          if has_completed eq 0 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Milestones dataset (&pfmstonedset) must contain data for "
            ||"COMPLETED milestone.";
            put msg_text;
            output;
          end;

          if &pfNumPeriodID ne &pfNumPeriodTitle then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Milestones dataset (&pfmstonedset) has an inconsistent number of "
            ||"periodID values ("||strip(&pfNumPeriodID)||") and periodTitle values ("||strip(&pfNumPeriodTitle)||").";
            put msg_text;
            output;
          end;
          
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));

        end;
      
      run;
      
      /*
      / Check the participant flow withdrawals dataset
      /----------------------------------------------------------------------------*/

      proc sort data=&pfwithdrawdset out=&prefix.pfwithdrawsort;
        by periodID armID reasonID;
      run;
    
      data &prefix.checks3 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 3 msg_sectionTitle "Withdrawal Reasons" err_flag 0 wrn_flag 0;
        set &prefix.pfwithdrawsort end=last;
        by periodID armID reasonID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=periodID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=periodTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=reasonType,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=reasonID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=otherReasonName,type=Character);
          %checktype(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=subjectsAffected,type=Numeric);
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=periodID);
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=periodTitle);
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armID);                
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armTitle);
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=reasonType);
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=reasonID);

        if upcase(reasonType) eq "OTHER" and missing(otherReasonName) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable otherReasonName in Withdrawal Reasons dataset (&pfwithdrawdset) "
            ||"must be populated when reasonType is Other";
          put msg_text;
          output;
        end;
        
        %checkmissing(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=subjectsAffected);

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=periodTitle,minlength=2,maxlength=40);
        %checklength(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=armDescription,maxlength=999);
        %checklength(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=otherReasonName,minlength=2,maxlength=40);

        * Check valid values *;

        %checklist(macroname=&macroname,dsetname=&pfwithdrawdset,dsetdescr=Withdrawal Reasons,variable=reasonType,
          valuelist=&pfWithdrawReasonTypeList);

        * Check only one observation per periodID/armID/reasonID *;

        if not (first.reasonID and last.reasonID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for periodID="||compress(put(periodID,8.))
          ||" armID="||compress(put(armID,8.))||" reasonID="||compress(put(reasonID,8.))
          ||" in Withdrawal Reasons dataset (&pfwithdrawdset).";
          put msg_text;
          output;
        end;

        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;
      
      run;
      
      data &prefix.checks;
        set &prefix.checks1 &prefix.checks2 &prefix.checks3;
      run;
     
      /*
      / Check that the number "Not Completed" matches the total number of
      / withdrawals in each arm/period
      /----------------------------------------------------------------------------*/

      %if &g_abort eq 0 %then %do;
      
        proc sort data=&pfmstonedset out=&prefix.mstonesort;
          by periodID periodTitle armID;
        run;
      
        proc transpose data=&prefix.mstonesort out=&prefix.checks4a;
          by periodID periodTitle armID armTitle;
          var milestoneData;
          id  milestoneTitle;
        run;
      
        proc sort data=&pfwithdrawdset out=&prefix.withdrawsort;
          by periodID periodTitle armID armTitle;
        run;
      
        proc summary data=&prefix.withdrawsort;
          by periodID periodTitle armID armTitle;
          var subjectsAffected;
          output out=&prefix.checks4b sum=withdraw_tot;
        run;
      
        data &prefix.checks4 (keep=msg_:);
      
          length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
          retain msg_sectionID 4.1 msg_sectionTitle "Milestones vs Withdrawal Reasons" err_flag 0 wrn_flag 0;
          merge &prefix.checks4a (in=a) &prefix.checks4b (in=b) end=last;
          by periodID periodTitle armID;
        
          not_completed = started - completed;
        
          if a and b and not_completed ne withdraw_tot then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Number of subjects not completed ("
            ||compress(put(not_completed,8.))||") in Milestones dataset (&pfmstonedset) does not "
            ||"match the total number of withdrawals ("||compress(put(withdraw_tot,8.))
            ||") in Withdrawal Reasons dataset (&pfwithdrawdset) for periodTitle="||trim(periodTitle)
            ||" armTitle="||trim(armTitle);
            put msg_text;
            output;
          end;
          else if a and not b and not_completed > 0 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Milestones dataset (&pfmstonedset) indicates that a "
            ||"number of subjects ("||compress(put(not_completed,8.))||") did not complete but there "
            ||"are no observations in Withdrawal Reasons dataset (&pfwithdrawdset) for periodTitle="
            ||trim(periodTitle)||" armTitle="||trim(armTitle);
            put msg_text;
            output;
          end;
          else if b and not a then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Record found in Withdrawal Reasons dataset (&pfwithdrawdset) for "
            ||"periodTitle="||trim(periodTitle)||" armTitle="||trim(armTitle)
            ||" which was not found in Milestones dataset (&pfmstonedset)";
            put msg_text;
            output;
          end;
      
          if last then do;             
            call symputx('g_abort', max(&g_abort, err_flag));
            call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
          end;

        run;
      
        proc append base=&prefix.checks data=&prefix.checks4;
        run;

        /*
        / When there are multiple periods check that the number "Started" matches 
        / the number "Completed" in the previous period
        /--------------------------------------------------------------------------*/

        %if &pfNumPeriodTitle gt 1 %then %do;

          proc sort data=&prefix.checks4a;
            by armID armTitle periodID periodTitle;
          run;

          data &prefix.checks5 (keep=msg_:);
            length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
            retain msg_sectionID 2 msg_sectionTitle "Milestones" err_flag 0 wrn_flag 0;
            length msg_text $32767;
            set &prefix.checks4a end=last;
            by armID armTitle periodID periodTitle;

            _periodID=lag(periodID);
            _periodTitle=lag(periodTitle);
            _completed=lag(completed);

            if not first.armID and started ne _completed then do;
              wrn_flag=1;
              msg_text = "RTW"||"ARNING: &macroname: Number of subjects started ("||compress(put(started,8.))
                ||") for periodTitle="||trim(periodTitle)||" does not equal the number of subjects completed ("
                ||compress(put(_completed,8.))||") for periodTitle="||
                trim(_periodTitle)||". armTitle="||trim(armTitle);
              put msg_text;
              output;
            end;

            if last then do;             
              call symputx('g_abort', max(&g_abort, err_flag));
              call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
            end;

          run;
      
          proc append base=&prefix.checks data=&prefix.checks5;
          run;

        %end;
      
      %end; /* %if &g_abort eq 0 %then %do; */
      
    %end; /* %if &datatype eq PARTFLOW %then %do; */

    %else %if &datatype eq BASECHAR %then %do;

      /*
      / Check the baseline characteristics reporting groups dataset
      /----------------------------------------------------------------------------*/

      proc sort data=&bcgroupsdset out=&prefix.bcgroupssort;
        by armID;
      run;
    
      data &prefix.checks1 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 1 msg_sectionTitle "Reporting Groups" err_flag 0 wrn_flag 0;
        set &prefix.bcgroupssort end=last;
        by armID;
                
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=subjectsAnalyzed,type=Numeric);
        end;                
                
        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armID);
        %checkmissing(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armTitle);
        %checkmissing(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=subjectsAnalyzed);
                
        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&bcgroupsdset,dsetdescr=Reporting Groups,variable=armDescription,maxlength=999);
                
        * Check only one observation per armID *;

        if not (first.armID and last.armID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for armID="||compress(put(armID,8.))
          ||" in Reporting Groups dataset (&bcgroupsdset).";
          put msg_text;
          output;
        end;

        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;

      /*
      / Check the baseline characteristics description dataset
      /----------------------------------------------------------------------------*/

      proc sort data=&bcdescrdset out=&prefix.bcdescrsort;
        by measureID;
      run;
    
      data &prefix.checks2 (keep=msg_:);
      
        retain has_age has_gender 0;
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 2 msg_sectionTitle "Measure Descriptions" err_flag 0 wrn_flag 0;
        set &prefix.bcdescrsort end=last;
        by measureID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=otherTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=parameterType,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=dispersionType,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=unitOfMeasure,type=Character);
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureID);
        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureTitle);

        if upcase(measureTitle) eq "STUDY SPECIFIC CHARACTERISTIC" and missing(otherTitle) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Variable otherTitle in Measure Descriptions dataset (&bcdescrdset) must be "
          ||"populated when measureTitle is Study Specific Characteristic";
          put msg_text;
          output;
        end;

        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=parameterType);
        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=dispersionType);
        %checkmissing(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=unitOfMeasure);

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=otherTitle,minlength=2,maxlength=100);
        %checklength(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureDescription,maxlength=600);
        %checklength(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=unitOfMeasure,minlength=2,maxlength=40);

        * Check valid values *;               
        %checklist(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=measureTitle,
          valuelist=&bcMeasureTitleList);
        %checklist(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=parameterType,
          valuelist=&bcParameterTypeList);
        %checklist(macroname=&macroname,dsetname=&bcdescrdset,dsetdescr=Measure Descriptions,variable=dispersionType,
          valuelist=&bcDispersionTypeList);
        
        if upcase(parameterType) eq "NUMBER" and upcase(dispersionType) ne "NOT APPLICABLE" then do;
          wrn_flag=1;
          msg_text = "RTW"||"ARNING: &macroname: Variable dispersionType in Measure Descriptions dataset (&bcdescrdset) should "
          ||"be set to 'Not Applicable' when parameterType is 'Number'. dispersionType="||dispersionType;
          put msg_text;
          output;
        end;

        if upcase(measureTitle) eq "AGE CONTINUOUS" then do;
          if upcase(unitOfMeasure) not in (&bcAgeUnitList) then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Variable unitOfMeasure in Measure Descriptions dataset (&bcdescrdset) "
            ||"contains an invalid value when Baseline Measure is Age Continuous. unitOfMeasure="||unitOfMeasure;
            put msg_text;
            output;
          end;
        end;
        else if upcase(parameterType) eq "NUMBER" and upcase(unitOfMeasure) ne "PARTICIPANTS" then do;
            wrn_flag=1;
            msg_text = "RTW"||"ARNING: &macroname: Variable unitOfMeasure in Measure Descriptions dataset (&bcdescrdset) "
            ||"should be set to 'Participants' when Baseline Measure is Categorical. measureTitle="||strip(measureTitle)
            ||". parameterType="||strip(parameterType)||". unitOfMeasure="||strip(unitOfMeasure);
            put msg_text;
            output;
        end;

        * Check only one observation per measureID *;

        if not (first.measureID and last.measureID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for measureID="||compress(put(measureID,8.))
          ||" in Measure Descriptions dataset (&bcdescrdset).";
          put msg_text;
          output;
        end;
        
        * Check for required measures *;
        
        if upcase(scan(measureTitle,1)) eq "AGE" then
          has_age=1;
        if upcase(scan(measureTitle,1)) eq "GENDER" then
          has_gender=1;

        if last then do;
          
          if has_age eq 0 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Measure Descriptions dataset (&bcdescrdset) must contain AGE data.";
            put msg_text;
            output;
          end;

          if has_gender eq 0 then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Measure Descriptions dataset (&bcdescrdset) must contain GENDER data.";
            put msg_text;
            output;
          end;
          
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));

        end;

      run;
      
      /*
      / Check the baseline characteristics results dataset - initial checks
      / only for now
      /----------------------------------------------------------------------------*/

      proc sort data=&bcdatadset out=&prefix.bcdatasort;
        by measureID armID categoryID;
      run;
    
      data &prefix.checks3 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 3 msg_sectionTitle "Measure Results" err_flag 0 wrn_flag 0;
        set &prefix.bcdatasort end=last;
        by measureID armID categoryID;

        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=measureID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=categoryID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=measureCategory,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=parameterValue,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionSpread,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionLowerLimit,type=Character);
          %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionUpperLimit,type=Character);
          %if &cr8usxmlyn=Y %then
            %checktype(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=naComment,type=Character);
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=measureID);
        %checkmissing(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armID);

        * Check only one observation per measureID/armID/categoryID *;

        if not (first.categoryID and last.categoryID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for measureID="||compress(put(measureID,8.))
          ||" armID="||compress(put(armID,8.))||" categoryID="||compress(put(categoryID,8.))
          ||" in Measure Results dataset (&bcdatadset).";
          put msg_text;
          output;
        end;

        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;

      data &prefix.checks;
        set &prefix.checks1 &prefix.checks2 &prefix.checks3;
      run;

      /*
      / Check the rest of the baseline characteristics results dataset
      /----------------------------------------------------------------------------*/

      %if &g_abort eq 0 %then %do;

        data &prefix.checks4 (keep=msg_:);
      
          length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
          retain err_flag 0 wrn_flag 0;
          merge 
            &prefix.bcdatasort (in=data)
            &prefix.bcdescrsort(in=descr keep=measureID dispersionType)
            end=last
            ;
          by measureID;

          * Check consistency of measureID *;

          if descr and not data then do;
            msg_sectionID=4.1;
            msg_sectionTitle="Measure Descriptions vs Measure Results";
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Baseline measure in Measure Descriptions dataset "
            ||"(&bcdescrdset) which is not in Measure Results dataset (&bcdatadset). measureID="
            ||strip(put(measureID,8.));
            put msg_text;
            output;
          end;
        
          else if data and not descr and first.measureID then do;
            msg_sectionID=4.1;
            msg_sectionTitle="Measure Descriptions vs Measure Results";
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Baseline measure in Measure Results dataset (&bcdatadset) "
            ||"which is not in Measure Descriptions dataset (&bcdescrdset). measureID="
            ||strip(put(measureID,8.));
            put msg_text;
            output;
          end;

          if data then do;

            msg_sectionID=3;
            msg_sectionTitle="Measure Results";

            * Check for missing values *;
            %checkmissing(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=studyID);
            %checkmissing(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armTitle);
            %checkmissing(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=parameterValue);

            if not missing(measureCategory) and missing(categoryID) then do;
              err_flag=1;
              msg_text = "RTE"||"RROR: &macroname: Value of variable categoryID in Measure Results dataset "
              ||"(&bcdatadset) should not be missing when variable measureCategory is populated.";
              put msg_text;
              output;
            end;
            
            * Check variable lengths *;
            %checklength(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armTitle,minlength=4,maxlength=62);
            %checklength(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=armDescription,maxlength=999);
            %checklength(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=measureCategory,minlength=2,maxlength=50);
            %if &cr8usxmlyn=Y %then
              %checklength(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=naComment,maxlength=250);

            * Check valid values *;               
            has_na=0;        
            %checknumeric(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=parameterValue,allowNA=Y);
            %checknumeric(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionSpread,allowNA=Y);
            %checknumeric(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionLowerLimit,allowNA=Y);
            %checknumeric(macroname=&macroname,dsetname=&bcdatadset,dsetdescr=Measure Results,variable=dispersionUpperLimit,allowNA=Y);
            
            * Check dispersionSpread, dispersionLowerLimit and dispersionUpperLimit against dispersionType *;
    
            if upcase(dispersionType) eq "NOT APPLICABLE" then do;
    
              if not missing(dispersionSpread) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionSpread in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
      
              if not missing(dispersionLowerLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionLowerLimit in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
        
              if not missing(dispersionUpperLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionUpperLimit in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
    
            end;
    
            else if upcase(dispersionType) eq "STANDARD DEVIATION" then do; 
    
              if missing(dispersionSpread) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionSpread in Measure Results dataset "
                ||"(&bcdatadset) should not be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
        
              if not missing(dispersionLowerLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionLowerLimit in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
        
              if not missing(dispersionUpperLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionUpperLimit in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
    
            end;

            else if upcase(dispersionType) in ("INTER-QUARTILE RANGE" "FULL RANGE") then do;

              if not missing(dispersionSpread) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionSpread in Measure Results dataset "
                ||"(&bcdatadset) should be missing when dispersionType is="||strip(dispersionType);
                put msg_text;
                output;
              end;
    
              if missing(dispersionLowerLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionLowerLimit in Measure Results dataset "
                ||"(&bcdatadset) should not be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;
    
              if missing(dispersionUpperLimit) then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Value of variable dispersionUpperLimit in Measure Results dataset "
                ||"(&bcdatadset) should not be missing when dispersionType="||strip(dispersionType);
                put msg_text;
                output;
              end;

            end;

            * Check if naComment is unnecessarily populated. *;
            * The check for it being populated when variable has value NA is done in *;
            * the checknumeric macro which also populates has_na variable *;
            
            %if &cr8usxmlyn=Y %then %do;
              if not(missing(naComment)) and has_na=0 then do;
                err_flag=1;
                msg_text = "RTE"||"RROR: &macroname: Variable naComment in Measure Results dataset (&bcdatadset) should "
                ||"not be populated unless the value of one of parameterValue, dispersionSpread, dispersionLowerLimit "
                ||"or dispersionUpperLimit is NA";
                put msg_text;
                output;
              end;
            %end;

          end; /* if data then do */

          if last then do;
            call symputx('g_abort', max(&g_abort, err_flag));
            call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
          end;

        run;

        proc append base=&prefix.checks data=&prefix.checks4;
        run;

        /*
        / Check consistency of armID across groups and results datasets
        /--------------------------------------------------------------------------*/

        proc sort data=&prefix.bcdatasort out=&prefix.bcdatauniq nodupkey;
          by armID;
        run;

        data &prefix.checks5 (keep=msg_:);
      
          length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
          retain msg_sectionID 4.2 msg_sectionTitle "Reporting Groups vs Measure Results" err_flag 0 wrn_flag 0;
          merge &prefix.bcgroupssort (in=groups keep=armID) &prefix.bcdatauniq(in=data keep=armID) end=last;
          by armID;

          if groups and not data then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Arm identifer in Reporting Groups dataset "
            ||"(&bcgroupsdset) which is not in Measure Results dataset "||"(&bcdatadset). armID="
            ||strip(put(armID,8.));
            put msg_text;
            output;
          end;
        
          else if data and not groups then do;
            err_flag=1;
            msg_text = "RTE"||"RROR: &macroname: Arm identifer in Measure Results dataset "
            ||"(&bcdatadset) which is not in Reporting Groups dataset "
            ||"(&bcgroupsdset). armID="||strip(put(armID,8.));
            put msg_text;
            output;
          end;

          if last then do;
            call symputx('g_abort', max(&g_abort, err_flag));
            call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
          end;

        run;

        proc append base=&prefix.checks data=&prefix.checks5;
        run;

      %end; /* %if &g_abort eq 0 %then %do; */

    %end; /* %if &datatype eq BASECHAR %then %do; */

    %else %if &datatype eq FREQUENTAE %then %do;
    
      * Check the contents of the adverse events frequency reporting threshold dataset *;
      
      data &prefix.checks1 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 1 msg_sectionTitle "Frequency Reporting Threshold" err_flag 0 wrn_flag 0;
        length msg_text $32767;
        set &aefreqdset end=last;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&aefreqdset,dsetdescr=Frequency Reporting Threshold,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&aefreqdset,dsetdescr=Frequency Reporting Threshold,variable=frequencyReportingThreshold,type=Numeric);
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&aefreqdset,dsetdescr=Frequency Reporting Threshold,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&aefreqdset,dsetdescr=Frequency Reporting Threshold,variable=frequencyReportingThreshold);

        * Check valid values *;
        %checknumeric(macroname=&macroname,dsetname=&aefreqdset,dsetdescr=Frequency Reporting Threshold,variable=frequencyReportingThreshold,maxvalue=5);
        
        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;

    %end; /* %if &datatype eq FREQUENTAE %then %do; */

    %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do;
    
      * Check the contents of the adverse events intervention groups dataset *;
      
      proc sort data=&aegroupsdset out=&prefix.aegroupssort;
        by armID;
      run;
    
      data &prefix.checks2 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 2 msg_sectionTitle "Reporting Groups" err_flag 0 wrn_flag 0;
        set &prefix.aegroupssort end=last;
        by armID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armDescription,type=Character);
          %if &datatype eq SERIOUSAE %then %do;
            %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numSubjectsSeriousEvents,type=Numeric);
            %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=partAtRiskSeriousEvents,type=Numeric);
            /* AJC003: numDeathsAllCauses now required for US All Cause Mortality */
            %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numDeathsAllCauses,type=Numeric);
            %if &cr8euxmlyn=Y %then %do;
              %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numDeathsAdverseEvents,type=Numeric);
            %end;
          %end;
          %else %do;
            %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numSubjectsFrequentEvents,type=Numeric);
            %checktype(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=partAtRiskFrequentEvents,type=Numeric);
          %end;
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armID);
        %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armTitle);

        %if &datatype eq SERIOUSAE %then %do;
          %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numSubjectsSeriousEvents);
          %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=partAtRiskSeriousEvents);
        %end;
        %else %do;
          %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=numSubjectsFrequentEvents);
          %checkmissing(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=partAtRiskFrequentEvents);
        %end;

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&aegroupsdset,dsetdescr=Reporting Groups,variable=armDescription,maxlength=999);

        * Check only one observation per armID *;

        if not (first.armID and last.armID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for armID="||compress(put(armID,8.))
          ||" in Reporting Groups dataset (&aegroupsdset).";
          put msg_text;
          output;
        end;

        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;

      proc sort data=&aedatadset out=&prefix.aedatasort;
        by armID eventID;
      run;
    
      data &prefix.checks3 (keep=msg_:);
      
        length msg_sectionID 8 msg_sectionTitle $100 msg_text $32767;
        retain msg_sectionID 3 msg_sectionTitle "Adverse Event Results" err_flag 0 wrn_flag 0;
        set &prefix.aedatasort end=last;
        by armID eventID;
        
        * Check variable types *;
        if _n_ eq 1 then do;
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=studyID,type=Character);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armTitle,type=Character);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armDescription,type=Character);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=organSystemName,type=Character);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=aeTerm,type=Character);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=eventID,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numSubjectsAffected,type=Numeric);        
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numSubjects,type=Numeric);
          %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numEvents,type=Numeric);
          %if &cr8euxmlyn=Y and &datatype=SERIOUSAE %then %do;
            %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numEventsRelated,type=Numeric);
            %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numFatalities,type=Numeric);
            %checktype(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numFatalitiesRelated,type=Numeric);
          %end;
        end;

        * Check for missing values *;
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=studyID);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armID);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armTitle);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=organSystemName);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=aeTerm);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=eventID);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numSubjectsAffected);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numSubjects);
        %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numEvents);
        %if &cr8euxmlyn=Y and &datatype=SERIOUSAE %then %do;
          %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numEventsRelated);
          %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numFatalities);
          %checkmissing(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=numFatalitiesRelated);
        %end;

        * Check variable lengths *;
        %checklength(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armTitle,minlength=4,maxlength=62);
        %checklength(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=armDescription,maxlength=999);
        %checklength(macroname=&macroname,dsetname=&aedatadset,dsetdescr=Adverse Event Results,variable=aeTerm,maxlength=100);

        * Check only one observation per armID/eventID *;
        
        if not (first.eventID and last.eventID) then do;
          err_flag=1;
          msg_text = "RTE"||"RROR: &macroname: Multiple records for armID="||compress(put(armID,8.))
          ||" eventID="||compress(put(eventID,8.))||" in Adverse Event Results dataset (&aedatadset).";
          put msg_text;
          output;
        end;
        
        if last then do;
          call symputx('g_abort', max(&g_abort, err_flag));
          call symputx('xml_wrning', max(&xml_wrning, wrn_flag));
        end;

      run;

      data &prefix.checks;
        set 
          %if &datatype eq FREQUENTAE %then &prefix.checks1;
          &prefix.checks2 &prefix.checks3;
      run;
      
    %end; /* %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do; */
    
    /*
    / Create HTML output file containing validation messages
    /----------------------------------------------------------------------------*/

    data &prefix.checks;
      set &prefix.checks;
      * Strip off %str(RTE)RROR: and macroname info *;
      msg_text=scan(msg_text,-1,':');
    run;

    proc format;
      value $datatype
        'PARTFLOW'='Participant Flow'
        'BASECHAR'='Baseline Characteristics'
        'FREQUENTAE'='Frequent Non-serious Adverse Events'
        'SERIOUSAE'='Serious Adverse Events'
        ;
    run;

    ods listing close;
    ods html file="&xml_msgfile";
      
    title1 "XML creation macro for VCTR dataset validation messages";
    title2 "Study: &vctrstudyid. Data type: %sysfunc(putc(&datatype, $datatype.))";

    %if %tu_nobs(&prefix.checks) eq 0 %then %do;

      data _null_;
        file print ods=(variables=(msg(label=' '))) nofootnote;
        length msg $40;
        msg="No dataset validation messages to report";
        put _ods_;
      run;

    %end;
    %else %do;

      proc report data=&prefix.checks headline headskip nowindows split='~';
        columns msg_sectionID msg_sectionTitle msg_text;
        define msg_sectionID / order noprint;
        define msg_sectionTitle / flow 'Dataset';
        define msg_text / flow 'Message';
        break after msg_sectionID / page;
      run;

    %end;

    title;

    ods html close;
    ods listing;
          
    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;
  
    /*
    / Step 3: Create the XML file
    /----------------------------------------------------------------------------*/

    /*
    / Define code list mapping formats
    /----------------------------------------------------------------------------*/

    proc format;

      value $pfArmTypeFmtEU
        "EXPERIMENTAL" = "ARM_TYPE.experimental"
        "ACTIVECOMPARATOR" = "ARM_TYPE.activeComp"
        "PLACEBOCOMPARATOR" = "ARM_TYPE.placeboComp"
        "NOINTERVENTION" = "ARM_TYPE.noImp"
        "OTHER" = "ARM_TYPE.other"
        ;

      value $pfDropReasFmtUS
        "ADVERSE EVENT" = "Adverse"
        "DEATH" = "Death"
        "LACK OF EFFICACY" = "LackEfficacy"
        "LOST TO FOLLOW-UP" = "LoTF"
        "PHYSICIAN DECISION" = "PhysDecision"
        "PREGNANCY" = "Pregnancy"
        "PROTOCOL VIOLATION" = "Noncompliance"
        "WITHDRAWAL BY SUBJECT" = "SubjectWithdraw"
        "OTHER" = "Other"
        ;

      value $pfDropReasFmtEU
        "ADVERSE EVENT" = "NOT_COMPLETED_REASON.adverseNotSerious"
        "DEATH" = "NOT_COMPLETED_REASON.adverseSeriousFatal"
        "LACK OF EFFICACY" = "NOT_COMPLETED_REASON.lackEfficacy"
        "LOST TO FOLLOW-UP" = "NOT_COMPLETED_REASON.lostFollowup"
        "PHYSICIAN DECISION" = "NOT_COMPLETED_REASON.physicianDecision"
        "PREGNANCY" = "NOT_COMPLETED_REASON.pregnancy"
        "PROTOCOL VIOLATION" = "NOT_COMPLETED_REASON.protocolViolation"
        "WITHDRAWAL BY SUBJECT" = "NOT_COMPLETED_REASON.consentWithdrawn"
        "OTHER" = "NOT_COMPLETED_REASON.other"
        ;

      value $bcMeasFmtUS
        "AGE CONTINUOUS" = "AgeContinuous"
        "AGE CATEGORICAL" = "AgeCategoricalNLM"
        "AGE, CUSTOMIZED" = "AgeCategoricalOther"
        "GENDER, MALE/FEMALE" = "GenderNIH"
        "GENDER, CUSTOMIZED" = "GenderOther"
        "RACE (NIH/OMB)" = "RaceNIH"
        "ETHNICITY (NIH/OMB)" = "EthnicityNIH"
        "RACE/ETHNICITY, CUSTOMIZED" = "RaceEthnicityOther"
        "REGION OF ENROLLMENT" = "RegionEnroll"
        "STUDY SPECIFIC CHARACTERISTIC" = "Other"
        ;

      value $bcParamFmtUS
        "NUMBER" = "CountOfParticipants" /* AJC003: Update mapping */
        "MEAN" = "Mean"
        "MEDIAN" = "Median"
        "LEAST SQUARES MEAN" = "LeastSquareMean"
        "GEOMETRIC MEAN" = "GeometricMean"
        "LOG MEAN" = "LogMean"
        ;
    
      value $bcParamFmtEU
        "NUMBER" = " "
        "MEAN" = "CENTRAL_TENDENCY.arithmetic"
        "MEDIAN" = "CENTRAL_TENDENCY.median"
        "LEAST SQUARES MEAN" = "CENTRAL_TENDENCY.leastSquares"
        "GEOMETRIC MEAN" = "CENTRAL_TENDENCY.geometric"
        "LOG MEAN" = "CENTRAL_TENDENCY.log"
        ;
    
      value $bcDispFmtUS
        "NOT APPLICABLE" = "NA"
        "STANDARD DEVIATION" = "StandardDeviation"
        "INTER-QUARTILE RANGE" = "InterQuartileRange"
        "FULL RANGE" = "FullRange"
        ;

      value $bcDispFmtEU
        "NOT APPLICABLE" = " "
        "STANDARD DEVIATION" = "DISPERSION.standardDeviation"
        "INTER-QUARTILE RANGE" = "DISPERSION.interQuartile"
        "FULL RANGE" = "DISPERSION.fullRange"
        ;

      value $aeSocFmtUS
        "BLOOD AND LYMPHATIC SYSTEM DISORDERS" = "Blood"
        "CARDIAC DISORDERS" = "Heart"
        "CONGENITAL, FAMILIAL AND GENETIC DISORDERS" = "Genetic"
        "EAR AND LABYRINTH DISORDERS" = "Ear"
        "ENDOCRINE DISORDERS" = "Endocrine"
        "EYE DISORDERS" = "Eye"
        "GASTROINTESTINAL DISORDERS" = "Gastrointestine"
        "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS" = "General"
        "HEPATOBILIARY DISORDERS" = "Liver"
        "IMMUNE SYSTEM DISORDERS" = "Immune"
        "INFECTIONS AND INFESTATIONS" = "Infect"
        "INJURY, POISONING AND PROCEDURAL COMPLICATIONS" = "Injury"
        "INVESTIGATIONS" = "Investigation"
        "METABOLISM AND NUTRITION DISORDERS" = "Metabolism"
        "MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS" = "Bones"
        "NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)" = "Cancer"
        "NERVOUS SYSTEM DISORDERS" = "Nerve"
        "PREGNANCY, PUERPERIUM AND PERINATAL CONDITIONS" = "Pregnancy"
        "PRODUCT ISSUES" = "ProductIssues" /* AJC003: New System Organ Class */
        "PSYCHIATRIC DISORDERS" = "Psych"
        "RENAL AND URINARY DISORDERS" = "Kidney"
        "REPRODUCTIVE SYSTEM AND BREAST DISORDERS" = "Reproductive"
        "RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS" = "Respiration"
        "SKIN AND SUBCUTANEOUS TISSUE DISORDERS" = "Skin"
        "SOCIAL CIRCUMSTANCES" = "Social"
        "SURGICAL AND MEDICAL PROCEDURES" = "Procedure"
        "VASCULAR DISORDERS" = "Circulation"
        ;

      value $aeSocFmtEU
        "BLOOD AND LYMPHATIC SYSTEM DISORDERS" = "100000004851"
        "CARDIAC DISORDERS" = "100000004849"
        "CONGENITAL, FAMILIAL AND GENETIC DISORDERS" = "100000004850"
        "EAR AND LABYRINTH DISORDERS" = "100000004854"
        "ENDOCRINE DISORDERS" = "100000004860"
        "EYE DISORDERS" = "100000004853"
        "GASTROINTESTINAL DISORDERS" = "100000004856"
        "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS" = "100000004867"
        "HEPATOBILIARY DISORDERS" = "100000004871"
        "IMMUNE SYSTEM DISORDERS" = "100000004870"
        "INFECTIONS AND INFESTATIONS" = "100000004862"
        "INJURY, POISONING AND PROCEDURAL COMPLICATIONS" = "100000004863"
        "INVESTIGATIONS" = "100000004848"
        "METABOLISM AND NUTRITION DISORDERS" = "100000004861"
        "MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS" = "100000004859"
        "NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)" = "100000004864"
        "NERVOUS SYSTEM DISORDERS" = "100000004852"
        "PREGNANCY, PUERPERIUM AND PERINATAL CONDITIONS" = "100000004868"
        "PRODUCT ISSUES" = "100000167503" /* AJC003: New System Organ Class */
        "PSYCHIATRIC DISORDERS" = "100000004873"
        "RENAL AND URINARY DISORDERS" = "100000004857"
        "REPRODUCTIVE SYSTEM AND BREAST DISORDERS" = "100000004872"
        "RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS" = "100000004855"
        "SKIN AND SUBCUTANEOUS TISSUE DISORDERS" = "100000004858"
        "SOCIAL CIRCUMSTANCES" = "100000004869"
        "SURGICAL AND MEDICAL PROCEDURES" = "100000004865"
        "VASCULAR DISORDERS" = "100000004866"
        ;

      value $ynBoolFmt
        "YES" = "true"
        "NO" = "false"
        ;

    run;

    /*
    / Create tagset used to format XML files in a temporary STORE in the WORK
    / library. The parent tagset sasxmog was chosen as a basis and updated to:
    /   1. Lower case SAS table names (SASRow event)
    /   2. Not output tags when there are missing values and not pad values
    /      with leading/trailing blanks (SASColumn and MLEVDAT events)
    /----------------------------------------------------------------------------*/

    ods path work.&prefix._store (write) sasuser.templat sashelp.tmplmst;

    proc template;
      define tagset tagsets.vctr / store = work.&prefix._store;
        parent = tagsets.sasxmog;
        notes "Custom tagset for tu_cr8xml4vctr";
        define event SASRow;
          start:
            put "<";
            put lowcase(NAME);
            put ">" NL;
            break;
          finish:
            put "</";
            put lowcase(NAME);
            put ">" NL;
            break;
        end;
        define event SASColumn;
          start:
            break /if exists( MISSING);
            ndent;
            put "<";
            put NAME;
            break;
          finish:
            break /if exists( MISSING);
            put "</";
            put NAME;
            put ">" NL;
            xdent;
            break;
        end;
		define event MLEVDAT;
		  break /if exists( MISSING);
		  put " rawvalue=""" /if exists( RAWVALUE);
		  put RAWVALUE /if exists( RAWVALUE);
		  put """" /if exists( RAWVALUE);
		  put " value=""" /if cmp( XMLDATAFORM, "ATTRIBUTE");
		  put VALUE /if cmp( XMLDATAFORM, "ATTRIBUTE");
		  put """" /if cmp( XMLDATAFORM, "ATTRIBUTE");
		  break /if cmp( XMLDATAFORM, "ATTRIBUTE");
		  put ">";
		  put VALUE;
		  break;
  		end;
      end;
    run;

    /*
    / Create US format results XML file if requested
    / Create work datasets according to schema then copy to the output destination
    /----------------------------------------------------------------------------*/

    %if &cr8usxmlyn eq Y %then %do;

      libname vctr_us xml "&xml_us_outfile" tagset=tagsets.vctr ENCODING="UTF-8";
      
      /*
      / Create US format Participant Flow datasets
      /--------------------------------------------------------------------------*/

      %if &datatype eq PARTFLOW %then %do;

        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "US-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &pfgroupsdset
          ;

          create table pf_overview (sortedby=_null_) as
          select 
            distinct(studyID) as pf_study_id,
            " " as pf_recruitment_details,
            " " as pf_preassignment_details
          from &pfgroupsdset
          ;

          create table pf_arms (sortedby=_null_) as
          select 
            studyID as pf_study_id,
            "ParticipantFlow-ParticipantFlowGroup."||strip(put(armID,8.))||"-"||strip(studyID) as pf_arm_id,
            substrn(armTitle,1,62) as pf_arm_title,
            substrn(armDescription,1,999) as pf_arm_description
          from &pfgroupsdset
          ;

          create table pf_milestones as
          select 
            studyID as pf_study_id,
            "ParticipantFlow-ParticipantFlowGroup."||strip(put(armID,8.))||"-"||strip(studyID) as pf_arm_idref,
            substrn(periodTitle,1,40) as pf_period_title,
            "ParticipantFlow-Milestone."||strip(put(milestoneID,8.))||"-"||strip(studyid) as pf_milestone_idref,
            substrn(milestoneTitle,1,40) as pf_milestone_title,
            milestoneData as pf_milestone_data,
            " " as pf_milestone_data_comment
          from &pfmstonedset
          ;

          create table pf_milestones_started (sortedby=_null_) as
          select * 
          from pf_milestones
          where upcase(pf_milestone_title) = "STARTED"
          ; /* AJC002: Uppercase milestone title in where clause. */

          create table pf_milestones_other (sortedby=_null_) as
          select * 
          from pf_milestones
          where upcase(pf_milestone_title) not in ("STARTED" "COMPLETED")
          ; /* AJC002: Uppercase milestone title in where clause. */

          create table pf_milestones_completed (sortedby=_null_) as
          select * 
          from pf_milestones
          where upcase(pf_milestone_title) = "COMPLETED"
          ; /* AJC002: Uppercase milestone title in where clause. */

          create table pf_dropped_withdrawal (sortedby=_null_) as
          select 
            studyID as pf_study_id,
            "ParticipantFlow-ParticipantFlowGroup."||strip(put(armID,8.))||"-"||strip(studyID) as pf_arm_idref,
            substrn(periodTitle,1,40) as pf_period_title,
            "ParticipantFlow-Dropped."||strip(put(reasonID,8.))||"-"||strip(studyID) as pf_dropped_idref,
            put(upcase(reasonType),$pfDropReasFmtUS.) as pf_dropped_reason_type,
            substrn(otherReasonName,1,40) as pf_dropped_other_reason_name,
            subjectsAffected as pf_dropped_data
          from &pfwithdrawdset
          ;

        quit;

      %end; /* %if &datatype eq PARTFLOW %then %do; */

      /*
      / Create US format Baseline Characteristics datasets
      /--------------------------------------------------------------------------*/

      %else %if &datatype eq BASECHAR %then %do;

        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "US-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &bcgroupsdset
          ;

          /* AJC003: bc_analysis_population_desc field removed */
          create table bc_arms_total (sortedby=_null_) as
          select 
            studyID as bc_study_id,
            "Baseline-TotalBaselineRptGroup-"||strip(studyID) as bc_arm_id,
            substrn(armTitle,1,62) as bc_arm_title,
            substrn(armDescription,1,999) as bc_arm_description,
            subjectsAnalyzed as bc_arm_num_participants
          from &bcgroupsdset
          where upcase(armTitle) eq "TOTAL"
          ;

          /* AJC003: bc_arm_num_units_analyzed field added */
          create table bc_arms (sortedby=_null_) as
          select 
            studyID as bc_study_id,
            "Baseline-BaselineRptGroup."||strip(put(armID,8.))||"-"||strip(studyID) as bc_arm_id,
            substrn(armTitle,1,62) as bc_arm_title,
            substrn(armDescription,1,999) as bc_arm_description,
            subjectsAnalyzed as bc_arm_num_participants,
            . as bc_arm_num_units_analyzed
          from &bcgroupsdset
          where upcase(armTitle) ne "TOTAL"
          ;

          /* AJC003: bc_measure_analysis_pop_desc and bc_measure_select_unit_analysis fields added */
          create table bc_measures (sortedby=_null_) as
          select 
            studyID as bc_study_id,
            "Baseline-Measure."||strip(put(measureID,8.))||"-"||strip(studyID) as bc_measure_id,
            put(upcase(measureTitle),$bcMeasFmtUS.) as bc_measure_title,
            substrn(otherTitle,1,100) as bc_measure_title_study_specific,
            substrn(measureDescription,1,600) as bc_measure_description,
            " " as bc_measure_analysis_pop_desc,
            put(upcase(parameterType),$bcParamFmtUS.) as bc_measure_parameter_type,
            put(upcase(dispersionType),$bcDispFmtUS.) as bc_measure_dispersion_type,
            substrn(unitOfMeasure,1,40) as bc_measure_unit_of_measure,
            " " as bc_measure_time_frame,
            "Participants" as bc_measure_select_unit_analysis
          from &bcdescrdset
          ;

          /* AJC003: bc_number_units_analyzed and bc_number_subjects_analyzed fields added */
          create table bc_measure_data (sortedby=_null_) as
          select
            studyID as bc_study_id,
            "Baseline-Measure."||strip(put(measureID,8.))||"-"||strip(studyID) as bc_measure_id,
            /* AJC003: For "customized" measure types, measureCategory is now used to populate row title */
            case
              when indexw(upcase(measureTitle),"CUSTOMIZED") gt 0 then substrn(measureCategory,1,50)
              else " "
            end as bc_row_title,
            case
              when upcase(armTitle) eq "TOTAL" then "Baseline-TotalBaselineRptGroup-"||strip(studyID)
              else "Baseline-BaselineRptGroup."||strip(put(armID,8.))||"-"||strip(studyID)
            end as bc_arm_idref,
            /* AJC003: For "customized" measure types, bc_category_idref and bc_category_title are now blank */
            case
              when indexw(upcase(measureTitle),"CUSTOMIZED") gt 0 then " "
              else "Baseline-Category."||strip(put(categoryID,8.))||"-"||strip(studyID)
            end as bc_category_idref,
            case
              when indexw(upcase(measureTitle),"CUSTOMIZED") gt 0 then " "
              else substrn(measureCategory,1,50)
            end as bc_category_title,
            parameterValue as bc_parameter_value,
            dispersionSpread as bc_dispersion_spread,
            dispersionLowerLimit as bc_dispersion_lower,
            dispersionUpperLimit as bc_dispersion_upper,
            substrn(naComment,1,250) as bc_na_comment,
            " " as bc_number_units_analyzed,
            " " as bc_number_subjects_analyzed
          from
            &bcdatadset a left join
            &bcdescrdset (keep=measureID measureTitle rename=(measureID=descrID)) b
          on a.measureID=b.descrID
          ;

        quit; 

      %end; /* %if &datatype eq BASECHAR %then %do; */

      /*
      / Create US format Adverse Event datasets
      /--------------------------------------------------------------------------*/

      %else %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do;
      
        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "US-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &aegroupsdset
          ;

          create table ae_overview (sortedby=_null_) as
          select
            distinct(studyID) as ae_study_id,
            " " as ae_reporting_time_frame,
            " " as ae_additional_reporting_notes,
            " " as ae_default_source_vocabulary,
            "Scheduled" as ae_default_assessment_type,
          %if &datatype eq SERIOUSAE %then %do;
            . as ae_freq_reporting_threshold
            from &aegroupsdset
          %end;
          %else %do;
            frequencyReportingThreshold as ae_freq_reporting_threshold
            from &aefreqdset
          %end;
          ;

          create table ae_arms (sortedby=_null_) as
          select 
            studyID as ae_study_id,
            "ReportedEvents-InterventionGroup."||strip(put(armID,8.))||"-"||strip(studyID) as ae_arm_id,
            substrn(armTitle,1,62) as ae_arm_title,
            substrn(armDescription,1,999) as ae_arm_description,
            /* AJC003: Add all cause mortality fields */
            %if &datatype eq SERIOUSAE %then %do;
              numSubjectsSeriousEvents as ae_serious_total_affected,
              partAtRiskSeriousEvents as ae_serious_total_at_risk,
              numDeathsAllCauses as ae_mortality_total_affected,
              case
                when not missing(numDeathsAllCauses) then partAtRiskSeriousEvents
                else .
              end as ae_mortality_total_at_risk
            %end;
            %else %do;
              numSubjectsFrequentEvents as ae_frequent_total_affected,
              partAtRiskFrequentEvents as ae_frequent_total_at_risk
            %end;
          from &aegroupsdset
          ;

          create table ae_events (sortedby=_null_) as
          select 
            studyID as ae_study_id,
            "ReportedEvents-InterventionGroup."||strip(put(armID,8.))||"-"||strip(studyID) as ae_arm_idref,
            "ReportedEvents-Event."||strip(put(eventID,8.))||"-"||strip(studyID) as ae_event_idref,
            %if &datatype eq SERIOUSAE %then "Serious";
            %else "Frequent";
              as ae_serious_or_frequent,
            substrn(aeTerm,1,100) as ae_event_term,
            " " as ae_term_description,
            " " as ae_assessment_type,
            put(upcase(organSystemName),$aeSocFmtUS.) as ae_organ_system,
            " " as ae_source_vocabulary,
            numSubjectsAffected as ae_num_affected,
            numEvents as ae_num_events,
            numSubjects as ae_num_at_risk
          from &aedatadset         
          ;

        quit;

      %end; /* %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do; */
      
      proc copy in=work out=vctr_us mt=data;
        select
          hdr
          %if &datatype eq PARTFLOW %then pf_overview pf_arms pf_milestones_started pf_milestones_other
            pf_milestones_completed pf_dropped_withdrawal;
          %else %if &datatype eq BASECHAR %then bc_arms bc_arms_total bc_measures bc_measure_data;
          %else %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then ae_overview ae_arms ae_events;
          ;
      run;

      libname vctr_us;
    
    %end; /* %if &cr8usxmlyn eq Y %then %do; */
    
    /*
    / Create EU format results XML file if requested
    / Create work datasets according to schema then copy to the output destination
    /----------------------------------------------------------------------------*/

    %if &cr8euxmlyn eq Y %then %do;

      libname vctr_eu xml "&xml_eu_outfile" tagset=tagsets.vctr ENCODING="UTF-8";
      
      /*
      / Create EU format Participant Flow datasets
      /--------------------------------------------------------------------------*/

      %if &datatype eq PARTFLOW %then %do;

        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "EU-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &pfgroupsdset
          ;

          create table sd_post_header (sortedby=_null_) as
          select
            distinct(periodID) as sd_post_seq,
            substrn(periodTitle,1,40) as sd_post_title,
            " " as sd_post_blindingImplDetails, /* AJC002: correct field name */
            " " as sd_post_mutuallyExclusiveArms, /* AJC002: correct field name */
            sd_post_baselinePeriod,
            " " as sd_post_blinded,
            " " as sd_post_clinicalTrialRoles,
            " " as sd_post_blindingType,
            " " as sd_post_allocation
          from
            &pfmstonedset a left join 
            (select min(periodID) as minPeriodID, "true" as sd_post_baselinePeriod from &pfmstonedset) b
          on a.periodID=b.minPeriodID

          ;

          create table sd_arm (sortedby=_null_) as
          select
            substrn(a.armTitle,1,62) as sd_arm_title,
            substrn(a.periodTitle,1,40) as sd_post_title,
            substrn(a.armDescription,1,999) as sd_arm_description,
            sd_arm_started,
            sd_arm_completed,
            put(upcase(c.armType),$pfArmTypeFmtEU.) as sd_arm_type,
            substrn(c.armTypeOther,1,50) as sd_arm_otherType
          from
            &pfmstonedset(where=(upcase(milestoneTitle) = "STARTED") rename=(milestoneData=sd_arm_started)) a,
            &pfmstonedset(where=(upcase(milestoneTitle) = "COMPLETED") rename=(milestoneData=sd_arm_completed)) b,
            &pfgroupsdset c
          where 
            a.periodID=b.periodID and a.armID=b.armID and a.armID=c.armID
            and sd_arm_started>0
            ; /* AJC002: Keep periods/arms where number of subjects started is > 0. Uppercase milestone title in where clause. */

          create table sd_arm_other_milestone (sortedby=_null_) as
          select
            substrn(armTitle,1,62) as sd_arm_title,
            substrn(periodTitle,1,40) as sd_post_title,
            substrn(milestoneTitle,1,40) as sd_arm_other_milestone_title, /* AJC002: correct field name */
            milestoneData as sd_arm_other_milestone_subjects /* AJC002: correct field name */
          from 
            &pfmstonedset a,
            (select periodID, armID from &pfmstonedset where upcase(milestoneTitle)="STARTED" and milestoneData>0) b
          where upcase(milestoneTitle) not in ("STARTED" "COMPLETED") and a.periodID=b.periodID and a.armID=b.armID
          ; /* AJC002: Keep periods/arms where number of subjects started is > 0. Uppercase milestone title in where clause. */

          create table sd_arm_not_completed (sortedby=_null_) as
          select 
            armTitle as sd_arm_title,
            substrn(periodTitle,1,40) as sd_post_title,
            put(upcase(reasonType),$pfDropReasFmtEU.) as sd_arm_not_completed_rsn,
            substrn(otherReasonName,1,40) as sd_arm_not_completed_rsn_other,
            subjectsAffected as sd_arm_not_completed_subjects
          from
            &pfwithdrawdset a,
            (select periodID, armID from &pfmstonedset where upcase(milestoneTitle)="STARTED" and milestoneData>0) b
          where a.periodID=b.periodID and a.armID=b.armID and subjectsAffected>0
          ; /* AJC002: Keep periods/arms where number of subjects started is > 0. Uppercase milestone title in where clause. 
               Drop withdrawal reason records where there are no subjects affected. */

        quit;

      %end; /* %if &datatype eq PARTFLOW %then %do; */

      /*
      / Create EU format Baseline Characteristics datasets
      /--------------------------------------------------------------------------*/

      %else %if &datatype eq BASECHAR %then %do;

        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "EU-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &bcgroupsdset
          ;

          select count(armTitle) into: bcTotalGroup
          from &bcgroupsdset
          where upcase(armTitle) ? 'TOTAL'
          ;

          create table bc_overview(
            bc_reporting_model char(50)
          );

          %if %tu_nobs(&bcgroupsdset) eq 1 and &bcTotalGroup eq 1 %then %do;
            insert into bc_overview
            values("BASELINE_REPORTING_MODEL.period")
            ;
          %end;
          %else %do;
            insert into bc_overview
            values("BASELINE_REPORTING_MODEL.arms")
            ;
          %end;

          create table bc_measures as
          select
            measureID as bc_study_seq,
            case 
              when upcase(parameterType) eq "NUMBER" then "Categorical"
              else "Continuous"
            end as variableType,
            case 
              when upcase(scan(measureTitle,1)) eq "AGE" then "age"
              when upcase(scan(measureTitle,1)) eq "GENDER" then "gender"
              else "study"
            end as _studyType,
            compress(calculated _studyType||propcase(calculated variableType)) as studyType,
            case 
              when upcase(measureTitle) eq "STUDY SPECIFIC CHARACTERISTIC" then otherTitle
              when upcase(scan(measureTitle,1)) in ("AGE" "GENDER") then ""
              else measureTitle
            end as bc_study_title,
            substrn(measureDescription,1,600) as bc_study_description,
            "true" as bc_study_readyForValues,
            case 
              when calculated variableType eq "Continuous" then substrn(unitOfMeasure,1,40)
              else ""
            end as bc_study_unit,
            put(upcase(parameterType),$bcParamFmtEU.) as bc_tendency_type,
            put(upcase(dispersionType),$bcDispFmtEU.) as bc_dispersion_type
          from &bcdescrdset
          ;

          create table bc_study_categorical (sortedby=_null_) as
          select 
            bc_study_seq,
            bc_study_title,
            bc_study_description,
            bc_study_readyForValues,
            bc_study_unit
          from bc_measures
          where studyType='studyCategorical'
          ;

          create table bc_study_continuous (sortedby=_null_) as
          select 
            bc_study_seq,
            bc_study_title,
            bc_study_description,
            bc_study_readyForValues,
            bc_study_unit,
            bc_tendency_type,
            bc_dispersion_type
          from bc_measures
          where studyType='studyContinuous'
          ;

          create table bc_age_characteristic (sortedby=_null_) as
          select 
            case
              when studyType eq "ageCategorical" then "true"
              else "false"
            end as bc_measure_is_age_cat,
            bc_study_readyForValues,
            bc_study_description,
            lowcase(bc_study_unit) as bc_study_unit,
            bc_tendency_type,
            bc_dispersion_type
          from bc_measures
          where studyType in ('ageContinuous' 'ageCategorical')
          ; /* AJC002: correct field name order */

          create table bc_gender_categorical (sortedby=_null_) as
          select 
            bc_study_readyForValues,
            bc_study_description
          from bc_measures
          where studyType='genderCategorical'
          ; /* AJC002: correct field name order */

          create table bc_rep_group (sortedby=_null_) as
          select 
            substrn(armTitle,1,62) as bc_group_title,
            substrn(armDescription,1,999) as bc_group_description
          from &bcgroupsdset
          %if %tu_nobs(&bcgroupsdset) gt 1 %then
            where upcase(armTitle) ne "TOTAL"; /* AJC002: Drop total arm */
          ; /* AJC001: bc_group_subjects removed */

          create table bc_group_values (sortedby=_null_) as
          select
            bc_study_title,
            compress("BCSTUDYTYPE."||studyType) as bc_study_type,
            substrn(armTitle,1,62) as bc_group_title,
            "false" as bc_group_is_stat_analysis_set,
            substrn(measureCategory,1,50) as bc_group_category_name,
            case
              when studyType ? "Categorical" then parameterValue
              else ""
            end as bc_group_countable_value,
            case
              when studyType ? "Continuous" then parameterValue
              else ""
            end as bc_group_tendency_value,
            coalesce(dispersionSpread,dispersionLowerLimit) as bc_group_dispersion_value,
            dispersionUpperLimit as bc_group_high_range_value
          from &bcdatadset a, bc_measures b
          where a.measureID=b.bc_study_seq
          %if %tu_nobs(&bcgroupsdset) gt 1 %then
            and upcase(armTitle) ne "TOTAL"; /* AJC002: Drop total arm */
          ;
        quit; 

      %end; /* %if &datatype eq BASECHAR %then %do; */

      /*
      / Create EU format Adverse Event datasets
      /--------------------------------------------------------------------------*/

      %else %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do;

        proc sql noprint;

          create table hdr (sortedby=_null_) as
          select
            distinct(studyID) as hdr_protocol_id,
            "EU-RS" as hdr_rec_type,
            "Replace" as hdr_rec_action
          from &aegroupsdset
          ;

          /*
          / AJC002: create ae_overview table for both AE data types with
          / assessment method set to systematic.
          /----------------------------------------------------------------------*/

          create table ae_overview (sortedby=_null_ drop=studyID) as
          select
            distinct(studyID) as studyID,            
            " " as ae_description,
          %if &datatype eq SERIOUSAE %then %do;
            . as ae_nonSeriousFreqThreshold,
          %end;
          %else %do;
            frequencyReportingThreshold as ae_nonSeriousFreqThreshold,
          %end;
            " " as ae_timeFrame,
            "ADV_EVT_ASSESS_TYPE.systematic" as ae_assessmentMethod,
            " " as ae_dictionary_name,
            " " as ae_dictionary_version,
            " " as ae_dictionary_otherName
          %if &datatype eq SERIOUSAE %then %do;
            from &aegroupsdset
          %end;
          %else %do;
            from &aefreqdset
          %end;
          ;

          create table ae_group (sortedby=_null_) as
          select 
            armID as ae_group_seq,
            substrn(armTitle,1,62) as ae_group_title,
            substrn(armDescription,1,999) as ae_group_description,
            %if &datatype eq SERIOUSAE %then %do;
              numSubjectsSeriousEvents as ae_group_subAffectedSerious,
              partAtRiskSeriousEvents as ae_group_subjectsExposed,
              numDeathsAllCauses as ae_group_deathsAllCauses,
              numDeathsAdverseEvents as ae_group_deathsFromAdvEvents
            %end;
            %else %do;
              numSubjectsFrequentEvents as ae_group_subAffectedNonSerious,
              partAtRiskFrequentEvents as ae_group_subjectsExposed
            %end;
          from &aegroupsdset
          ; /* AJC002: Correct total subjects affected fields */

          create table ae_event (sortedby=_null_) as
          select 
            substrn(armTitle,1,62) as ae_group_title,
            %if &datatype eq SERIOUSAE %then "true";
            %else "false";
              as ae_event_is_serious,
            substrn(aeTerm,1,100) as ae_event_term,
            " " as ae_event_description,
            put(upcase(organSystemName),$aeSocFmtEU.) as ae_event_organSystem_eutctId,
            " " as ae_event_assessmentMethod,
            " " as ae_event_dictionaryOverridden,
            " " as ae_event_dictionary_otherName,
            " " as ae_event_dictionary_version,
            " " as ae_event_dictionary_name,
            numEvents as ae_event_occurrences,
            numSubjectsAffected as ae_event_subjectsAffected,
            numSubjects as ae_event_subjectsExposed
            %if &cr8euxmlyn=Y and &datatype eq SERIOUSAE %then %do;,
              numEventsRelated as ae_event_occurrencesRelTreatment,
              numFatalities as ae_event_deaths,
              numFatalitiesRelated as ae_event_deathsRelTreatment
            %end;
          from &aedatadset         
          ;

        quit;

      %end; /* %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then %do; */
      
      proc copy in=work out=vctr_eu mt=data;
        select
          hdr
          %if &datatype eq PARTFLOW %then sd_post_header sd_arm sd_arm_other_milestone sd_arm_not_completed;
          %else %if &datatype eq BASECHAR %then bc_overview bc_study_categorical bc_study_continuous 
            bc_age_characteristic bc_gender_categorical bc_rep_group bc_group_values;
          %else %if &datatype eq FREQUENTAE or &datatype eq SERIOUSAE %then
            ae_overview ae_group ae_event; /* AJC002: ae_overview table output for both AE data types */
          ;
      run;

      libname vctr_eu;
    
    %end; /* %if &cr8euxmlyn eq Y %then %do; */

    /*
    / Reset ODS PATH to default value
    /----------------------------------------------------------------------------*/

    ods path sasuser.templat sashelp.tmplmst;

    %if &xml_wrning gt 0 %then %do;
      %put %str(RTW)ARNING: &sysmacroname: There are %str(war)ning messages in the messages report but the XML file(s) have been generated.;
      %put %str(RTW)ARNING: &sysmacroname: Please review and notify your Clinical Disclosure contact.;
    %end;  
  
  %end; /* %if &usage eq CREATE %then %do; */
  
  /*
  / If &usage = "delete", then delete the XML file
  /----------------------------------------------------------------------------*/

  %else %do; /* i.e. &usage eq DELETE */
  
    filename _xmlus "&xml_us_outfile";
    filename _xmleu "&xml_eu_outfile";
    filename _htmlmsg "&xml_msgfile";
  
    data _null_;
      rc=fdelete('_xmlus');
      rc=fdelete('_xmleu');
      rc=fdelete('_htmlmsg');
    run;
  
    filename _xmlus clear;
    filename _xmleu clear;
    filename _htmlmsg clear;

  %end; /* %if &usage eq DELETE %then */
  
  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix: &xml_tables, glbmac=NONE);

%mend tu_cr8xml4vctr;

