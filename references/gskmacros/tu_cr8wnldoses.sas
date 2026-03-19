/*******************************************************************************
|
| Macro Name:     tu_cr8wnldoses
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby/ James McGiffen
|
| Date:           21st July 2005
|
| Macro Purpose:  Create WNL doses files
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
|
| FILEOUTDIR      Specifies the name of the output directory     &G_PKDATA (Req)
|                 path
|
|                 Valid value: The directory shall exist
|
| FILEOUTPFX      Specifies an optional prefix for the           [blank] (Opt)
|                 names of all output files
|
| DOSEINT         Specifies the dosing interval when the         [blank] (Req)
|                 dosing regime is Steady-State.  This value 
|                 shall be placed into the output file(s) (hours)
|
|                 Valid value: A numeric value greater or  
|                 equal to zero, usually in units of hours
|
| DOSEUNIT        Specifies the name of the dose unit            doseunit (Req)
|                 variable
| 
| DSETINCONCS     Specifies the name of the A&R PKCNC            ardata.pkcnc (Req)
|                 dataset used for the calculation of the 
|                 total number of profiles
|
| DSETINDOSES     Specifies the name of the input A&R            ardata.exposure (Req)
|                 EXPOSURE dataset
|
| JOINMSG         Specifies whether unmatched PK concentration   %str(NOT)E (Opt)
|                 and PK exposure records should be treated as 
|                 warnings, errors or note
|
| LENGTHINFUSION  Length of infusion (hours).  Applicable when   [blank] (Opt)
|                 model is of type 202
|
|                 Valid values: Applicable when model is of 
|                 type 202, here a positive numeric value is 
|                 required, usually in units of hours
|
| MERGEVARS       Specify the variables by which to              &g_subjid visitnum (Req)
|                 join the PKCNC and EXPOSURE datasets                 
|
|                 Valid values: The merge variables must 
|                 exist on the DSETINCONCS and DSETINDOSES 
|                 datasets
|
| MODEL           Specifies the type of model                    [blank] (Req)
|                 associated with the doses files
|
|                 Valid values: 200, 201, 202
|
| SORTDOSES       Specify the sort order of records on the       pctyp pcspec pcan &g_subjid &g_trtgrp
|                 output dose file(s)                            pernum visitnum (Req)
|
|                 Valid values: The variables must exist 
|                 in the dataset defined by the DSETINCONCS 
|                 parameter
|
| SPLITVARS       Specifies a list of categorical variable(s)   pctyp pcspec pcan (Req)
|                 used to define classification levels that  
|                 are used to "split" the PKCNC dataset. One 
|                 output file is created for each level of 
|                 classification
|
|                 Valid values: Character or Numeric 
|                 variables that exist in DSETIN.  Specify
|                 a list of variables delimited by blanks
|
| STEADYSTATE     Specifies whether the dosing regime is         N (Req)
|                 steady state
|
|                 Valid values: Y, N
|
| SUBSETCONCS     An optional WHERE clause to subset the         [blank] (Opt)
|                 A&R PKCNC dataset
|
|                 Valid values: Shall be a valid WHERE 
|                 CLAUSE
|
| TIMELASTDOSE    Time of last dose (hours).                     [blank] (Req)
|
|                 Valid Values: A numeric value greater or
|                 equal to zero, usually in units of hours.
|                 When STEADYSTATE EQ Y a positive value is
|                 required, when STEADYSTATE EQ N then a 
|                 value of zero is required
|
| Output:         Doses files in the pkdata directory
|
| Global macro variables created: none
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_byid
|(@) tu_chkvartype
|(@) tu_maclist
|(@) tu_putglobals
|(@) tu_tidyup
|(@) tu_valparms
|(@) tu_words
|(@) tu_xcpput
|(@) tu_xcpsectioninit
|(@) tu_xcpsectionterm
|
| Example:  %tu_cr8wnldoses(fileoutdir=&g_pkdata
|                           fileoutpfx=wnl
|                           doseint=0
|                           doseunit=doseunit
|                           dsetinconcs=ardata.pkcnc
|                           dsetindoses=ardata.exposure
|                           joinmsg=NOTE
|                           lengthinfusion=0.5
|                           mergevars=&g_subjid visitnum
|                           model=202
|                           sortdoses=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum
|                           splitvars=pctyp pcspec pcan
|                           steadystate=N
|                           subsetconcs=1 le visitnum le 14
|                           timelastdose=2);
|
|*******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     23-Aug-05
| New version/draft number: 01.002
| Modification ID:          TQW9753.01.002
| Reason For Modification:  Update source code following review
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     14-Sep-05
| New version/draft number: 01.003
| Modification ID:          TQW9753.01.003
| Reason For Modification:  Update source code following UTC development
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     19-Sep-05
| New version/draft number: 01.004
| Modification ID:          TQW9753.01.004
| Reason For Modification:  Update validation for LENGTHINFUSION
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     23-Sep-05
| New version/draft number: 01.005
| Modification ID:          TQW9753.01.005
| Reason For Modification:  Update the header block of the doses.dat file
|                           so that the following rules are implemented
|                           with respect to spaces:
|                           e.g.
|                           Row 1: V32,MG,none (no spaces before or after commas)
|                           Row 2: 2 (no space before or after value)
|                           Row 3:  84 (include a space before the value)
|                           Row 4: 3, 1 (include a space after comma)
|                           Row 5: 4, 1 (include a space after comma)
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     27-Sep-05
| New version/draft number: 01.006
| Modification ID:          TQW9753.01.006
| Reason For Modification:  Remove code implemented in TQW9753.01.005
|                           and implement the following
|                           
|                           Convert the output text files from 
|                           UNIX to DOS Character sets (when executed
|                           on UNIX)
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     03-Nov-05
| New version/draft number: 01.007
| Modification ID:          TQW9753.01.007
| Reason For Modification:  Introduce a WHERE clause so that the correct number of
|                           profiles is calculated for the current value of 
|                           SPLITVARS

|*******************************************************************************
|
| Modified By:              Shivam Kumar	
| Date of Modification:     21-OCT-2013
| New version/draft number: 02.001
| Modification ID:
| Reason For Modification:  Replace local macro variable sysmsg with l_sysmsg
|
********************************************************************************/
%macro tu_cr8wnldoses(fileoutdir=&g_pkdata  /* Name of output directory path  */
                     ,fileoutpfx= /* Optional prefix for all output files  */
                     ,doseint=  /* Dosing interval for steady-state (hours) */
                     ,doseunit=doseunit /* Specifies the dose unit variable to be used in the Doses file */
                     ,dsetinconcs=ardata.pkcnc  /* type: ID Name of input A&R PK Concentrations dataset */
                     ,dsetindoses=ardata.exposure /* type:ID Name of input A&R EXPOSURE dataset */
                     ,joinmsg=%str(NOT)E /* Specifies how unmatched records are treated */
                     ,lengthinfusion= /* Length of infusion (hours) */
                     ,mergevars=&g_subjid visitnum  /* Variables for joining EXPOSURE and PKCNC datasets */
                     ,model=  /* Specifies the PK model used to build the Doses file */
                     ,sortdoses=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum  /* Sort order of output files */
                     ,splitvars=pctyp pcspec pcan /* List of classification variable(s) defining output file(s) contents */
                     ,steadystate=N /* Is dosing regime steady state? */
                     ,subsetconcs= /* Optionally specify a WHERE clause to subset the A&R PKCNC dataset */
                     ,timelastdose= /* Time of last dose (hours) */
                     );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=2;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid);

  %let fileoutdir=%nrbquote(&fileoutdir.);
  %let fileoutpfx=%nrbquote(&fileoutpfx.);
  %let doseint=%nrbquote(&doseint.);
  %let doseunit=%nrbquote(&doseunit.);
  %let dsetinconcs=%nrbquote(&dsetinconcs.);
  %let dsetindoses=%nrbquote(&dsetindoses.);
  %let joinmsg=%nrbquote(&joinmsg.);
  %let lengthinfusion=%nrbquote(&lengthinfusion.);
  %let mergevars=%nrbquote(&mergevars.);
  %let model=%nrbquote(&model.);
  %let sortdoses=%nrbquote(&sortdoses.);
  %let splitvars=%nrbquote(&splitvars.);
  %let steadystate=%nrbquote(%upcase(&steadystate.));
  %let subsetconcs=%nrbquote(&subsetconcs.);
  %let timelastdose=%nrbquote(&timelastdose.);

  %local prefix;
  %let prefix=&sysmacroname.;

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  %local pv_abort macroname;
  %let pv_abort=0;
  %let macroname=&sysmacroname;

  /* Verify that: 
  /
  / FILEOUTDIR DOSEINT DOSEUNIT DSETINCONCS DSETINDOSES MERGEVARS MODEL 
  / SORTDOSES SPLITVARS STEADYSTATE and TIMELASTDOSE are not blank 
  ------------------------------------------------------------------------------*/
  %tu_valparms(macroname=&macroname.,chktype=isNotBlank
              ,pv_varsin=fileoutdir doseint doseunit dsetinconcs dsetindoses mergevars model sortdoses splitvars steadystate timelastdose
              ,abortyn=Y);

  /* Verify DSETINCONCS exists */
  %tu_valparms(macroname=&macroname.,chktype=dsetExists,pv_dsetin=dsetinconcs);
  %if &pv_abort. eq 0 %then
  %do;/* DSETINCONCS exists */
    /* Verify that variables: PCRFDSDM, MERGEVARS, SORTDOSES and SPLITVARS exist on DSETINCONCS */
    %local pcrfdsdm;
    %let pcrfdsdm=pcrfdsdm;
    %tu_valparms(macroname=&macroname.,chktype=varExists,pv_dsetin=dsetinconcs,pv_varsin=pcrfdsdm mergevars sortdoses splitvars);
    /* Verify that SUBSETCONCS is a valid WHERE clause */
    %if %length(&subsetconcs.) ne 0 %then
    %do;  /* Is Not Blank */
      %local dsid rc;
      %let dsid=%sysfunc(open(&dsetinconcs.(where=(%unquote(&subsetconcs.)))));
      %if &dsid. eq 0 %then
      %do;  /* Open Failed */
        %local l_sysmsg;
        %let l_sysmsg=%sysfunc(sysmsg());
        %put RTE%str(RROR): &macroname.: &l_sysmsg.;
        %let pv_abort=1;
      %end;  /* Open Failed */
      %else
      %do;  /* Open Success */
        %local nobs;
        %let nobs=%sysfunc(attrn(&dsid.,nlobsf));
        %if &nobs. eq 0 %then
        %do;  /* No Observations */
          %put RTE%str(RROR): &macroname.: The WHERE clause identifed by the SUBSETCONCS(&subsetconcs.) parameter selects 0 observations;
          %let pv_abort=1;
        %end;  /* No Observations */
        %let rc=%sysfunc(close(&dsid));
        %if &rc. ne 0 %then
        %do;  /* Close failed */
          %let l_sysmsg=%sysfunc(sysmsg());
          %put RTE%str(RROR): &macroname.: &l_sysmsg.;
          %let pv_abort=1;
          %let rc=;
        %end;  /* Close failed */
      %end;  /* Open Success */
    %end;  /* Is Not Blank */
  %end;/* DSETINCONCS exists */

  /* 
  /  Create a flag that stores the value of pv_abort from the validation above 
  /  and reset the value of pv_abort to 0 for the next validation.  The value of
  /  pv_abort1 will be checked at the end of the parameter validation section
  /  and may terminate the macro 
  ------------------------------------------------------------------------------*/
  %local pv_abort1;
  %let   pv_abort1=0;
 
  %if &pv_abort. eq 1 %then
  %do;
    %let pv_abort =0;
    %let pv_abort1=1;
  %end;

  /* Verify DSETINDOSES exists */
  %tu_valparms(macroname=&macroname.,chktype=dsetExists,pv_dsetin=dsetindoses);
  %if &pv_abort. eq 0 %then
  %do;  /* DSETINDOSES exists */
    %if %length(&doseunit.) ne 0 %then
    %do; /* Verify that DOSEUNIT variable is on dsetindoses */ 
      %tu_valparms(macroname=&macroname.,chktype=varExists,pv_dsetin=dsetindoses,pv_varsin=doseunit);
      %if &pv_abort. eq 0 %then
      %do;  /* DOSEUNIT variable exists */
        %local doseunitvalue;
        proc sql noprint;
        select distinct &doseunit. into : doseunitvalue separated by ','
        from &dsetindoses.;
        quit;
        %if %index(%nrbquote(&doseunitvalue.),%nrbquote(,)) ne 0 %then
        %do;  /* Dose units inconsistent */
          %put RTE%str(RROR): &macroname: The DOSEUNIT variable (&doseunit.) has inconsistent units : &doseunitvalue.;
          %let pv_abort=1;
        %end;/* Dose units inconsistent */
      %end;  /* DOSEUNIT variable exists */
    %end;  /* Verify that DOSEUNIT variable is on dsetindoses */
    /* Verify that MERGEVARS exist on DSETINDOSES */
    %tu_valparms(macroname=&macroname.,chktype=varExists,pv_dsetin=dsetindoses,pv_varsin=mergevars);
  %end;  /* DSETINDOSES exists */

  /* Verify valid values of STEADYSTATE: Y or N */
  %tu_valparms(macroname=&macroname,chktype=isoneof,pv_varsin=steadystate,valuelist=Y N);

  /* Verify MODEL has values: 200 201 202 */
  %tu_valparms(macroname=&macroname.,chktype=isoneof,pv_varsin=model,valuelist=200 201 202);

  /* Verify TIMELASTDOSE is a numeric value GE zero */
  %if %datatyp(&timelastdose.) ne NUMERIC %then
  %do;
    %put RTE%str(RROR): &macroname.: TIMELASTDOSE (&timelastdose.) is not a numeric value;
    %let pv_abort=1;
  %end;
  %else %if (&timelastdose. lt 0) %then
  %do;
    %put RTE%str(RROR): &macroname: The TIMELASTDOSE variable (&timelastdose.) is not GE zero;
    %let pv_abort=1;
  %end;

  /* Verify DOSEINT is numeric value and positive when STEADYSTATE=Y and zero when STEADYSTATES=N */
  %if %datatyp(&doseint.) ne NUMERIC %then
  %do;
    %put RTE%str(RROR): &macroname.: DOSEINT (&doseint.) is not a numeric value;
    %let pv_abort=1;
  %end;
  %else %if (&steadystate. eq Y and &doseint. le 0) %then
  %do;
    %put RTE%str(RROR): &macroname: A positive value is required for a dose interval DOSEINT (&doseint.) when STEADYSTATE has a value of (&steadystate.);
    %let pv_abort=1;
  %end;
  %else %if (&steadystate. eq N and &doseint. ne 0) %then
    %do;
    %put RTE%str(RROR): &macroname: A value of zero is required for a dose interval DOSEINT (&doseint.) when STEADYSTATE has a value of (&steadystate.);
    %let pv_abort=1;
  %end;

  %if &model eq 202 %then
  %do;  /* Model 202 */
    %if %length(&lengthinfusion.) eq 0 %then
    %do;  /* Blank value */
      %put RTE%str(RROR): &macroname.: A value is required for LENGTHINFUSION when MODEL 202 is specified;
      %let pv_abort=1;
    %end;  /* Blank value */
    %else
    %do;  /* Non blank */
      %if %datatyp(&lengthinfusion.) ne NUMERIC %then
      %do;  /* Not numeric */
        %put RTE%str(RROR): &macroname.: LENGTHINFUSION (&lengthinfusion.) is not a numeric value;
        %let pv_abort=1;
      %end; /* Not numeric */
      %else
      %do;  /* Numeric */
        %if &lengthinfusion. le 0 %then
        %do;  /* Non-positive value */
          %put RTE%str(RROR): &macroname: A positive value is required for LENGTHINFUSION (&lengthinfusion.) when MODEL (&model.);
          %let pv_abort=1;
        %end;  /* Non-positive value */
      %end;  /* Numeric */
    %end; /* Non blank */
  %end;  /* Model 202 */
  %else %if %length(&lengthinfusion.) ne 0 %then
  %do;  /* LENGTHINFUSION incorrectly specified */
    %put RTE%str(RROR): &macroname: A value for LENGTHINFUSION (&lengthinfusion.) should not be specified for MODEL (&model.);
    %let pv_abort=1;
  %end; /* LENGTHINFUSION incorrectly specified */
 
  %if %eval(&g_abort.+&pv_abort.+&pv_abort1.) gt 0 %then
  %do;
    %put RTE%str(RROR): &macroname.: Macro has failed parameter validation check for reasons stated with RTE%str(RRORs) above;
    %tu_abort(option=force);
  %end;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/
  %local currentdataset;
  %let currentdataset=&dsetinconcs.;

  %local splitwords;
  %let splitwords=%tu_words(&splitvars.);
 
  %local z;

  %do z=1 %to &splitwords.;
    %local splitvar&z.;
  %end;

  %local not_used;

  %tu_maclist(string=&splitvars.
             ,delim=%str(' ')
             ,prefix=splitvar
             ,cntname=not_used
             ,scope=local
             );
  /*
  / Create a working copy of DSETINCONCS and derive KEY variable
  /------------------------------------------------------------------------------*/
  data &prefix._workcopy;
    attrib key length=$512;
    set &currentdataset. %if %length(&subsetconcs.) ne 0 %then
                         %do;
                          (where=(%unquote(&subsetconcs.)))
                         %end;;
    key=%if &z gt 1 %then
        %do;
          %do z=1 %to %eval(&splitwords.-1);
            %if %tu_chkvartype(&currentdataset.,&&splitvar&z.) eq C %then
            %do;
              trim(&&splitvar&z.)
            %end;
            %else
            %do;
              trim(left(put(&&splitvar&z.,best22.)))
            %end;
             ||'_'||
          %end;
        %end;

        %if %tu_chkvartype(&currentdataset.,&&splitvar&splitwords.) eq C %then
        %do;
          trim(&&splitvar&splitwords.);
        %end;
        %else
        %do;
          trim(left(put(&&splitvar&splitwords.,best22.)));
        %end;

  run;

  %let currentdataset=&prefix._workcopy;

  /*
  / Create a string of SPLITVALUES and assign number to NUMSPLITVALUES
  /------------------------------------------------------------------------------*/

  /* Number of SPLITVARS values */
  %local numsplitvalues;

  /* Create a string of distinct SPLITVALUES */
  %local splitvalues;

  proc sql noprint;
  select distinct key into: splitvalues separated by '#'
  from &currentdataset;
  %let numsplitvalues=&sqlobs;
  quit;

  %local splitvalue;
  %let   splitvalue=;

  %local masterdataset;
  %let masterdataset=&currentdataset;

  %local i;

  %do i=1 %to &numsplitvalues.;   /* Output file for each distinct value of splitvars */

   %let splitvalue=%scan(&splitvalues,&i,'#');  /* [TQW9753.01-008] */

   %local fileref;

    %let fileref=&fileoutdir./&fileoutpfx._&splitvalue._doses.dat;

    %if &i eq 1 %then
    %do;  /* Check the directory, execute this code once only */
      %local OutSearch Dirlen;
      %let OutSearch=%scan(&fileref.,-1,/\);
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG) : &macroname. : OutSearch: &OutSearch;
      %let Dirlen=%length(&fileref.)-1-%length(&OutSearch.);
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &macroname. : Dirlen: &Dirlen.;
      /* check that the directory exists */
      %local directory filelen;
      %let filelen=%length(%scan(&fileref.,-1,/\));
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &macroname. : Filelen: &filelen.;
      %let directory=%substr(&fileref.,1,%length(&fileref.)-&filelen.-1);
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &macroname. : Directory: &directory.;
      %local dref;
      %let dref=dref;
      %let rc=%sysfunc(filename(&dref.,&directory.));
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &macroname. : Assigned fileref RC: &rc.;
      %if &rc. ne 0 %then
      %do;  /* Directory syntax invalid */
        %local l_sysmsg;
        %let l_sysmsg=%sysfunc(sysmsg());
        %put RTE%str(RROR): &macroname.: &l_sysmsg.;
        %tu_abort(option=force);
      %end;  /* Directory syntax invalid */
      %else
      %do;  /* Directory syntax valid */
        %local dirid;
        %let dirid=%sysfunc(dopen(&dref.));
        %if &g_debug. ge 1 %then
          %put  RTD%str(EBUG) : &macroname. : DIRID: &dirid.;
        %if &dirid. eq 0 %then
        %do;  /* Directory does not exist */
          %put RTE%str(RROR): &macroname.: The directory specified by the fileref (&fileref.) parameter does not exist;
          %tu_abort(option=force);
        %end; /* Directory does not exist */
        %else
        %do;  /* Directory exists */
          /* tidy-up */
          %let rc=%sysfunc(dclose(&dirid.));
          %if &g_debug. ge 1 %then
            %put  RTD%str(EBUG) : &macroname. : Close directory RC: &rc.;
            %if &rc. ne 0 %then
            %do;  /* Close failed */
              %let l_sysmsg=%sysfunc(sysmsg());
              %put RTE%str(RROR): &macroname.: &l_sysmsg.;
              %tu_abort(option=force);
            %end;  /* Close failed */
            %let rc=%sysfunc(filename(&dref.));
            %if &rc. ne 0 %then
            %do;  /* De-assign failed */
              %let l_sysmsg=%sysfunc(sysmsg());
              %put RTE%str(RROR): &macroname.: &l_sysmsg.;
              %tu_abort(option=force);
            %end;  /* De-assign failed */
          %if &g_debug. ge 1 %then
            %put  RTD%str(EBUG) : &macroname. : Deassign fileref RC: &rc.;
        %end; /* Directory exists */
      %end;  /* Directory syntax valid */
    %end; /* Check the directory, execute this code once only */

    /* Execute this code for each file */
    %local dosefile;
    %let dosefile=dosefile;
    /* Assign fileref */
    %let rc=%sysfunc(filename(&dosefile.,&fileref.));
    %if &rc. ne 0 %then
    %do;  /* Verify that the filename valid */
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &macroname.: &l_sysmsg.;
      %tu_abort(option=force);
    %end;  /* Verify that the filename valid */

    /* Sort the CONCENTRATIONS dataset by MERGEVARS */
    proc sort data=&masterdataset. (where=(key="&splitvalue")) /* TQW9753.01.007 */
              out =&prefix._pkcnc 
              nodupkey
              ;
    by &mergevars. pcrfdsdm;
    run;

    /* Sort the EXPOSURE dataset by MERGEVARS */
    proc sort data=&dsetindoses.(keep=&mergevars. dose)
              out=&prefix._exposure nodupkey;
    by &mergevars.;
    run;

    data &prefix._MergeData;
      merge &prefix._pkcnc    (in=PKCNC)
            &prefix._exposure (in=EXPOSURE)
            end=DATAEND
      ;
      by &mergevars.;

      drop __msg;

        /*
	      / Initialise exception report section
	      /------------------------------------------------------------------------------*/
	      %tu_xcpsectioninit(header=Exception Message(s) for Merge of PKCNC and EXPOSURE data)

	      /*
	      /  Write the exception messages (if applicable)
	      /------------------------------------------------------------------------------*/
	      if (PKCNC and NOT EXPOSURE) then
	      do;  
	        %tu_byid(dsetin=&prefix._pkcnc 
	                ,invars=&mergevars.
	                ,outvar=__msg);
	        %tu_xcpput("No dose value (sortdoses=%upcase(&sortdoses.)) identified : "!!__msg,&joinmsg);
        end;	

        /* Left join */
	    if PKCNC then output;

        /*
        /  Terminate the section
        /------------------------------------------------------------------------------*/
        %tu_xcpsectionterm(end=DataEnd);

      run;

    %let currentdataset=&prefix._MergeData;
   
    /* Compute the total number of concentration profiles */
    %local num_of_profiles;
    proc sql noprint;
      select count(distinct &g_subjid.*pcrfdsdm) into: num_of_profiles
      from &currentdataset.;
    quit;
    
    %let num_of_profiles=%trim(&num_of_profiles.);

    /* Sort the prevailing dataset by the SORTDOSES parameter */
    proc sort data=&currentdataset. out=work.&prefix._final;
    by &sortdoses.;
    run;

    %let currentdataset=&prefix._final;

    data _null_;
      set &currentdataset.;
      file dosefile; 

      if _n_ eq 1 then
      do;  /* Header information */

        put "V32,%trim(&doseunitvalue.),none"              /* Row 1 */
          / "2"                                            /* Row 2 */
          / "&num_of_profiles."                            /* Row 3 */
        ;
        %if &model. eq 200 or &model. eq 201 %then
        %do;
          put "3,1";                                       /* Row 4 */
        %end;
        %else
        %if &model. eq 202 %then
        %do;
          put "4,1";                                       /* Row 4 */
        %end;

        put "4,N";                                         /* Row 5 */

      end;  /* Header information */

      %if &model. eq 200 or &model. eq 201 %then
      %do;  /* Models: 200, 201 */
        put dose /"&timelastdose." /
            "&doseint."
        ;
      %end;  /* Models: 200, 201 */
      %else
      %if &model. eq 202 %then
      %do;  /* Model 202 */
          put dose /
              "&lengthinfusion." /
              "&timelastdose." /
              "&doseint."
          ;
      %end;  /* Model 202 */

    run;

    %let rc=%sysfunc(filename(&dosefile.));
    %if &rc. ne 0 %then
    %do;  /* De-assign failed */
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &macroname.: &l_sysmsg.;
      %tu_abort(option=force);
    %end;  /* De-assign failed */

    /* Convert from UNIX to DOS Character set */
    %if %upcase(&sysscpl.) eq SUNOS %then
    %do;  /* Execute UNIX platform */
      %local rc;   
      %let rc=%sysfunc(system(unix2dos -437 "&fileref" "&fileref"));
      %if &rc ne 0 %then
      %do;
        %put RTE%str(RROR): &macroname.: Unix to DOS character set conversion failed;
        %tu_abort(option=force);
      %end;
    %end;  /* Execute UNIX platform */

  %end; /* Output file for each distinct value of splitvars */

  /*
  / Tidyup the session
  /------------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix.:
             ,glbmac=NONE
             );
  quit;

  %tu_abort();

%mend tu_cr8wnldoses;
