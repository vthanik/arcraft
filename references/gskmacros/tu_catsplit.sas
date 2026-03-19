/*******************************************************************************
|
| Macro Name        : tu_catsplit
| 
| Macro Version     : 2 build 1
|
| SAS Version       : 8.2
|
| Created By        : Venkata Sridhar B
|
| Date              : 24-Apr-2006
|
| Macro Purpose     : Unit creates a categorial variable from a continuous variables.
|
| Macro Design      : Procedure Style
|
| Input Parameters  :
|
| NAME               DESCRIPTION                                REQ/OPT  DEFAULT
| -----------------  -------------------------------------      -------  ----------
| DESCPREFIX         Specifies a prefix for &VAROUTDECODE       OPT      (Blank)
|                    and &FMTOUT.
|                    Valid values:Blank or a string. 
|
| DESCSUFFIX         Specifies a suffix for &VAROUTDECODE       OPT      (Blank)
|                    and &FMTOUT.
|                    Valid values:Blank or a string.						
| 	
| DSETIN             Specifies the Input dataset that           REQ      (Blank)
|                    contains the variable the variable to 
|                    be converted into a categorial variable.
|                    Valid values:An existing dataset 
|
| DSETOUT            Specifies name of the output dataset.      REQ      (Blank)
|                    Valid values: A Valid SAS dataset name.
|
| 
| FMTOUT             Specifies a name to be given to an         OPT      (Blank)
|                    out put format &VAROUT.The format  
|                    will be associated to &VAROUT and
|                    has format values from &VAROUTDECODE.
|                    Valid values:Blank or valid SAS
|                    format name.
|
| INTERVAL           Specifies a list of numerical values.      REQ      65
|                    Valid values:A list of numerical values.
|
| VAROUT             Specifies a name of the output             OPT      (Blank)
|                    (categorical) variable.if blank,the
|                    macro will replace &VARIN with the 
|                    categorial version created by the macro.
|                    Valid values:Blank or valid SAS
|                    variable name.
|                    
| VAROUTDECODE       Specifies a decode variable for &VAROUT.   OPT      _varoutdecode_
|                    The decode variable will describe the  
|                    interval-including &DESCPREFIX and 
|                    &DESCSUFFIX if they are provided.
|                    Valid values:A valid SAS 
|                    variable name. 
| VARIN              Specifies the continous variable in the    REQ      (Blank)
|                    input datset for which the macro will 
|                    create a categorical variable.
|                    Valid values : A variable that exist on 
|                    &DSETIN.
| 
| -----------------  -------------------------------------  -------  ----------
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter specified dataset.
| ------------------  -------  ------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset.
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: None.
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chknames
|(@) tu_tidyup
|
| Example:
|    %macro tu_catsplit(
|     descprefix        = weight,
|     descsuffix        = pound,	
|     dsetin            = test.age,           
|     dsetout           = test.conf_int,           
|     fmtout            = fmt,       
|     interval          = 65,           
|     varout            = varout,           
|     varoutdecode      = varoutdecode,
|     varin             = varin        
|     );
|
|******************************************************************************
| Change Log
|
| Modified By: Ian Barretto
| Date of Modification:	04Apr2006
| New version/draft number: Version 1 Build 6
| Modification ID: 001
| Reason For Modification: ensure that FMTOUT, VAROUT and VAROUTDECODE are
|			   handled conditionally
|------------------------------------------------------------------------------
| Modified By: Ian Barretto
| Date of Modification:	11Apr2006
| New version/draft number: Version 1 Build 7
| Modification ID: 002
| Reason For Modification: Remove conditional coding of VAROUT
|------------------------------------------------------------------------------
| Modified By: Ian Barretto
| Date of Modification:	24Apr2006
| New version/draft number: Version 2 Build 1
| Modification ID: 003 (not displayed)
| Reason For Modification: Removed dependent macro tu_labelvars from header block
*******************************************************************************/

%macro tu_catsplit(
       descprefix        = ,                /* Prefix which will be added to &VAROUTDECODE */
       descsuffix        = ,                /* Suffix which will be added to &VAROUTDECODE */	
       dsetin            = ,                /* Input dataset name */
       dsetout           = ,                /* Output dataset name */
       fmtout            = ,                /* An Output format name for with format for &VAROUT */
       interval          = 65,              /* A numeric value list used to define the categorical variable to be output */
       varout            = ,                /* Name of the categorical variables to be output */
       varoutdecode      = ,                /* Name of the decode variable for &VAROUT */
       varin             =                  /* The name of an existing continuous variable */
       );


       /*-----------------------------------------------------------------------------*/
       /*  Echo parameter values and global macro variables to the log.               */
       /*-----------------------------------------------------------------------------*/

       %local MacroVersion;
       %let MacroVersion = 2 build 1;
       %put Macroname : &sysmacroname Macroversion : &MacroVersion ;
       %include "&g_refdata/tr_putlocals.sas";
       %tu_putglobals();			/* To echo the golbal macro variables to the log */

       /*-----------------------------------------------------------------------------*/
       /*      Local macro variables created in the macro.                            */
       /*-----------------------------------------------------------------------------*/

       %local   prefix          /* Holds the name for temp data sets */ 
                varlist         /* Holds the variables names of the datset */ 
                num             /* Holds the number of varibles in a datset */ 
                i ;             /* variable used to run the loop */       
       %let prefix=_catsplit;	 /* set the work data set name prefix to _catsplit */
       

       /*-----------------------------------------------------------------------------*/
       /*      PARAMETER VALIDATION                                                   */
       /*-----------------------------------------------------------------------------*/

       %let descprefix        = %nrbquote(&descprefix);	
       %let descsuffix        = %nrbquote(&descsuffix);
       %let dsetin            = %nrbquote(&dsetin);
       %let dsetout           = %nrbquote(&dsetout);
       %let fmtout            = %nrbquote(%scan(&fmtout,1,'.'));
       %let interval          = %nrbquote(&interval);
       %let varout            = %nrbquote(&varout);
       %let varoutdecode      = %nrbquote(&varoutdecode);
       %let varin             = %nrbquote(%lowcase(&varin));

       /*-----------------------------------------------------------------------------*/
       /*  1.Check that none of required parameters are blank.                        */
       /*-----------------------------------------------------------------------------*/

       %if &dsetin EQ %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
           %let g_abort=1;
       %end;

       %if &dsetout EQ %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
           %let g_abort=1;
       %end;

       %if &interval EQ %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The parameter INTERVAL is required.;
           %let g_abort=1;
       %end;

       %if &varin EQ %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The parameter VARIN is required.;
           %let g_abort=1;
       %end;	

       /*-----------------------------------------------------------------------------*/
       /*  2.Check that &DSETIN is an existing SAS dataset.                           */
       /*-----------------------------------------------------------------------------*/

       %if %sysfunc(EXIST(&dsetin)) EQ 0 %then  /*Check that &dsetin is an existing SAS dataset.*/
       %do;
           %put %str(RTE)RROR: &sysmacroname: The dataset identified by macro variable DSETIN (&dsetin) does not exist.;
           %let g_abort=1;
       %end;

       /*-----------------------------------------------------------------------------*/
       /*  3.Check that &VARIN exist on &DSETIN.                                      */
       /*-----------------------------------------------------------------------------*/

       %if %tu_chkvarsexist(&dsetin,&varin) ne  %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The required variable VARIN (&varin) does not exist in DSETIN (&dsetin).;
           %let g_abort=1;
       %end;
      
       /*-----------------------------------------------------------------------------*/
       /*  4.If given,Check that &DSEOUT is a valid SAS dataset name.                 */
       /*-----------------------------------------------------------------------------*/
       
       %if &dsetout NE %then
       %do;	
           %if %nrbquote(%tu_chknames(&dsetout,DATA)) NE %then	/* Check that &dsetout is a valid SAS dataset. */
           %do;
               %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable DSETOUT (&dsetout) is not a valid dataset name.;
               %let g_abort=1;
           %end;
       %end;

       /*-----------------------------------------------------------------------------*/
       /*  5.Check that &INTERVAL is a list of numbers.                               */
       /*-----------------------------------------------------------------------------*/

       %if &interval NE %then
       %do;
           %if %nrbquote(%verify(&interval,'.0123456789 ')) GT 0 %then 
           %do;
               %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable INTERVAL (&interval) is not a list of numbers.;
               %let g_abort=1;
          %end;
       %end;

       /*---------------------------------------------------------------------------------*/
       /*  6.If given,Check that &VAROUT and &VAROUTDECODE are valid SAS variable names.  */
       /*---------------------------------------------------------------------------------*/
       
       %if &varout NE %then
       %do;	
           %if %nrbquote(%tu_chknames(&varout,VARIABLE)) NE %then   /* Check for &varout */
           %do;                                                     /*    is a valid SAS variable name. */
               %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable VAROUT (&varout)is not a valid SAS variable name.;
               %let g_abort=1;
           %end;
       %end;
       %if &varoutdecode NE %then
       %do;	
           %if %nrbquote(%tu_chknames(&varoutdecode,VARIABLE)) NE %then   /* Check for &varoutdecode  */
           %do;                                                           /* is a valid SAS variable name.*/
               %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable VAROUTDECODE (&varoutdecode) is not a valid SAS variable name.;
               %let g_abort=1;
           %end;
       %end;

       /*-----------------------------------------------------------------------------*/
       /*  7.If SAS gives an error message then call the %tu_abort.                   */
       /*-----------------------------------------------------------------------------*/

       %if &g_abort GT 0 %then %tu_abort(option=force);
 
       /*-----------------------------------------------------------------------------*/
       /*     Normal Processing.                                                      */
       /*-----------------------------------------------------------------------------*/

       /*-----------------------------------------------------------------------------*/
       /*  5.If &VAROUT is blank set it to _VAROUT_                                   */
       /*-----------------------------------------------------------------------------*/

       %if &varout EQ  %then  %let varout=_varout_ ;
                
       /*-----------------------------------------------------------------------------*/
       /*  6.If &FMTOUT is blank set it to _tmpfmt                                    */
       /*-----------------------------------------------------------------------------*/

       %if &fmtout EQ  %then %let fmtout=_tmpfmt;
       
       /*-----------------------------------------------------------------------------*/
       /*  7.creates a dataset which has count and interval values                    */
       /*-----------------------------------------------------------------------------*/
       
       data &prefix.count(keep=interval_num interval_txt);
            retain interval "&interval";
            count + 1;
            interval_txt = scan(interval,count,' ');
            do while (interval_txt NE ' ');
               interval_num = input(interval_txt,best.);
               output;
               count + 1;
               interval_txt = scan(interval,count,' ');
            end;
            call symput('interval_count',left(put(count,8.)));
       run;

       proc sort data=&prefix.count out=&prefix.count;   /* Sorting interval_num data in numeric order  */
            by interval_num;
       run;

       /*----------------------------------------------------------------------------------------------------*/
       /*   7 a.Creating macro variables for the PROC FORMAT.                                                */
       /*     b.For the first value given,set n=1 and set the format label to :                              */
       /*       &DESCPREFIX||'<'||(interval value)||''||&DESCSUFFIX                                          */
       /*     c.If there is more then one value in the list,do the fallowing for every value except the first*/
       /*       increment n and se the format lable to:                                                      */
       /*       &DESCPREFIX||'>='||(Previous interval value)||'and <='||(interval value)||'||&DESCSUFFIX     */
       /*     d.For the last value,create one more format :set n=n+1 and set the format label to:            */
       /*       &DESCPREFIX||'>='||interval value||''||&DESCSUFFIX                                           */
       /*----------------------------------------------------------------------------------------------------*/
 
       data _null_;
            length interval_label $200
            interval_group $200;
            set &prefix.count end=last;
            interval_txt_prev = lag(interval_txt);
            if _n_ = 1 then
            do;
               interval_label="&descprefix. < "||trim(interval_txt)||" &descsuffix";  /*  Creating string variables one for the label and one for grouping the data */
               interval_group="LOW -< "||trim(interval_txt);
            end;
            else 
            do;	                        /*  Creating string variables one for the label and one for grouping the data */
               interval_label="&descprefix. >= "||trim(interval_txt_prev)||" and < "|| trim(interval_txt)||" &descsuffix";
               interval_group=trim(interval_txt_prev)||" -< "|| trim(interval_txt);
            end;
            call symput('interval_label'||left(put(_n_,8.)),interval_label);  /* Creating a macro variables for PROC FORMAT  */
            call symput('interval_group'||left(put(_n_,8.)),interval_group);  /* Creating a macro variables for PROC FORMAT  */
            if last then
            do;
               interval_label="&descprefix. >= "||trim(interval_txt)||" &descsuffix";   /*  Creating string variables one for the label and one for grouping the data */
               interval_group=trim(interval_txt)||' - HIGH ';        /* This is the n+1 interval */
               call symput('interval_label'||left(put(_n_+1,8.)),interval_label);      /* Creating a macro variables for PROC FORMAT  */
               call symput('interval_group'||left(put(_n_+1,8.)),interval_group);      /* Creating a macro variables for PROC FORMAT  */
           end;
       run;

       /*--------------------------------------------------------------------------------------------*/
       /*  8.Run Proc Format to create FORMAT to group the values and label the values.              */
       /*--------------------------------------------------------------------------------------------*/

       proc format;                        /* Creating FORMAT to label the values */
            value &fmtout                  
            %do i=1 %to &interval_count;
                %str(%trim(&i="%trim(&&interval_label&i)"))
            %end;
            ;
       run;

       proc format;                       /* Creating FORMAT to group the values */
             value _tmpgrp
             %do i=1 %to &interval_count;
                 %str(%trim(%trim(&&interval_group&i)="&i"))
             %end;
             ;
       run;

       /*--------------------------------------------------------------------------------------------------*/
       /*  9.a.Create &DSETOUT by Modifying &DSETIN.                                                       */
       /*  9 b.Create &VAROUTDECODE: Apply the format &FMTOUT.                                             */
       /*    c.Create &VAROUT: Apply the format _tmpgrp.                                                   */
       /*--------------------------------------------------------------------------------------------------*/

       data &dsetout(LABEL="Output dataset created by &sysmacroname");
            set &dsetin;
	    
             
            /* Modification 001 */
            /* Modification 002 */	    
            
            &varout=input(put(&varin,_tmpgrp.),8.);
	    LABEL &varout='Categorical variables';
	    
	    %if &varoutdecode ne %then %do;
              &varoutdecode=put(&varout,%unquote(&fmtout%str(.)));
	      LABEL &varoutdecode='Name of decode variable'; 
	    %end;  
            
	    
	    LABEL &varin='Existing continous variables';
       run;
 
       /*-----------------------------------------------------------------------------*/
       /*  10.Call tu_tidyup to delete temporary data sets                            */
       /*-----------------------------------------------------------------------------*/
        
       %tu_tidyup(rmdset=&prefix.:,glbmac=none);

%mend tu_catsplit;


	
      

