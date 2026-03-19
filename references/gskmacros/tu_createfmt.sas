/*
/
/ Macro Name: tu_createfmt
/
/ Macro Version:  1
/
/ SAS Version: 8
/
/ Created By: John Henry King
/
/ Date: 27May2003
/
/ Macro Purpose: A macro to create a SAS value labeling fromat from a
/                code variable and its companion decode variable from
/                an A&R SAS data set.
/
/ Macro Design: Procedure style.
/
/ Input Parameters:
/
/ NAME     DESCRIPTION                                         DEFAULT
/ --------------------------------------------------------------------------
/ DSETIN   Names data set to use to derive the format.         no default
/
/ DSETOUT  Control in data set.  Names the "control in" data   work._cntlin_
/          set used by PROC FORMAT
/
/ CATOUT   Output format catalog. Names the catalog to         work.formats
/          receive the formats.
/
/ VARSIN   List of variable names SEX, RACE etc.  The name     no default
/          of the CODE variable will be derived from the name
/          listed by appending CD to the name.  If a variable
/          and its CODE companion do not have this naming
/          scheme then use the alternate form where the variable
/          is followed by an = sign and the name of the
/          CODE variable, e.g. varsin=sex age=agecode.
/
/
/
/ Output: Creates SAS value labeling formats from code and decode
/         variables in A&R data sets.
/
/ Global macro variables created: NONE
/
/ Macros called:
/(@) tr_putlocals
/(@) tu_putglobals
/(@) tu_chknames
/(@) tu_chkvarsexist
/(@) tu_varattr
/(@) tu_tidyup
/(@) tu_abort
/
/ Example:
/    %tu_createfmt
/       (
/          dsetin = work.tmt,
/          varsin = sex ethori=ethoricd age_cat=agecatcd tmtdg=tmtgr
/       )
/
/
/
/*******************************************************************************
/ Change Log
/
/ Modified By: John King
/ Date of Modification: 10-Jul-03
/ New version number: 1/2
/ Modification ID: jhk001
/ Reason For Modification: Failed source code review.
/
/*******************************************************************************
/ Change Log
/
/ Modified By: John King
/ Date of Modification: 17Jul2003
/ New version number: 1/3
/ Modification ID: jhk001
/ Reason For Modification: Added check for LIBREF exists for &dsetout
/                          and &catout.
/
/*******************************************************************************
/
/ Modified By: John King
/ Date of Modification: 22-Jul-03
/ New version number: 1/4
/ Modification ID: jhk001
/ Reason For Modification: Failed source code review.
/
/*******************************************************************************
/
/ Modified By:
/ Date of Modification:
/ New version number:
/ Modification ID:
/ Reason For Modification:
/
********************************************************************************/
%macro
   tu_createfmt
      (
         dsetin  = ,                /* Input data set                           */
         dsetout = work._cntlin_,   /* Control in data set                      */
         catout  = work.formats,    /* Output format catalog                    */
         varsin  =                  /* List of variables to derive formats from */
      )
   ;


   %local MacroVersion;
   %let MacroVersion = 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %if %nrbquote(&dsetin) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN must not be blank.;
      %goto macERROR;
   %end;

   %if %nrbquote(&dsetout) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETOUT must not be blank.;
   %end;

   %if %nrbquote(&varsin) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: VARSIN must not be blank.;
   %end;

   %if %nrbquote(&catout) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: CATOUT must not be blank.;
   %end;


   %if NOT %sysfunc(exist(&dsetin)) %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN=&dsetin does not exist.;
   %end;



   %if %bquote(%tu_chknames(&dsetout,DATA)) NE %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETOUT=&dsetout is not a valid SAS data set name.;
   %end;

   /*
   / Check that libref exists for &dsetout and &catout
   /----------------------------------------------------*/
   %if %index(&dsetout,.) %then
   %do;
      %if %sysfunc(libref(%scan(&dsetout,1,.))) %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: Library reference for DSETOUT=&dsetout is not assigned.;
      %end;
   %end;

   %if %index(&catout,.) %then
   %do;
      %if %sysfunc(libref(%scan(&catout,1,.))) %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: Library reference for CATOUT=&catout is not assigned;
      %end;
   %end;

   %if %bquote(&g_abort) EQ 1 %then %goto macERROR;


   /*
   / Note the macro will also create two arrays of LOCAL macro
   / variables below as &VARSIN is scanned.
   /-------------------------------------------------------------*/

   %local
      workroot    /* root name for temp data sets                */
      i           /* counter                                     */
      w           /* word holder variable                        */
      decode0     /* array dimension                             */
      allvars     /* list of variables that should be in &destin */
      donotexist  /* list of variable that do not exist          */
      rx          /* RXPARSE ID value                            */
      pattern     /* regular expression                          */
      times       /* changes for RXCHANGE                        */
      code_type   /* variable type returned from tu_varattr      */
      decode_type /* variable type returned from tu_varattr      */
      ;


   %let workroot = %substr(&sysmacroname,3);

   /*
   / "normalize" &varsin such that a simple SCAN will return
   / 1) word
   /     or
   / 2) word=word
   /----------------------------------------------------------*/
   %let rx = %sysfunc(rxparse(' '* '=' ' '* TO '='));
   %let times = 999;
   %syscall rxchange(rx,times,varsin));
   %syscall rxfree(rx);

   /*
   / Create &dsetout with 0 observations
   /---------------------------------------------------*/
   data &dsetout(label='Control in data for PROC FORMAT');
      length fmtname $32 type $1 start $32 label $256 ;
      stop;
      fmtname = ' ';
      type    = ' ';
      start   = ' ';
      label   = ' ';
      label
         fmtname = 'Format Name'
         type    = 'Format type'
         start   = 'Value to label'
         label   = 'Value label'
         ;
      run;

   %if &syserr GT 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETOUT=&dsetout could not be created.;
      %goto macERROR;
   %end;

   %let donotexist = ;
   %let allvars    = ;
   %let i          = 1;
   %let w          = %scan(&varsin,&i,%str( ));
   %do %while(%nrbquote(&w) NE);
      %local decode&i code&i;
      %if %index(&w,=) %then
         %do;
            %let decode&i = %scan(&w,1,=);
            %let code&i   = %scan(&w,2,=);
         %end;
      %else
         %do;
            %let decode&i = &w;
            %let code&i   = &w.CD;
         %end;
      %let allvars = &allvars &&decode&i &&code&i;
      %let i       = %eval(&i + 1);
      %let w       = %scan(&varsin,&i,%str( ));
   %end;

   %let decode0 = %eval(&i-1);

   %let donotexist = %tu_chkvarsexist(&dsetin,&allvars);
   %if %nrbquote(&donotexist) GT %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname VARSIN=&donotexist, not found in DSETIN=&dsetin;
      %goto macERROR;
   %end;

   /*
   / Create the control in data set for PROC FORMAT
   /-----------------------------------------------------*/
   %do i = 1 %to &decode0;
      proc summary nway missing data=&dsetin;
         class &&code&i &&decode&i;
         output out=work.&workroot._TEMP_(drop = _type_ _freq_);
         run;

      %let decode_type = %tu_varattr(work.&workroot._temp_,&&decode&i,vartype);
      %let code_type   = %tu_varattr(work.&workroot._temp_,&&code&i  ,vartype);

      data &dsetout(label='Control in data for PROC FORMAT');
         set
            &dsetout              (in=in1)
            work.&workroot._temp_ (in=in2)
            ;
         drop &&code&i &&decode&i;

         if in2 then
         do;
            fmtname = "&&decode&i";
            type    = "&code_type";

            %if &code_type EQ N %then
            %do;
               start = put(&&code&i,best.);
            %end;
            %else
            %do;
               start = &&code&i;
            %end;

            %if &decode_type EQ N %then
            %do;
               label = put(&&decode&i,best.);
            %end;
            %else
            %do;
               label = &&decode&i;
            %end;
         end;
      run;
   %end;

   proc format library=&catout cntlin=&dsetout;
      run;
   %if &syserr GT 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: PROC FORMAT produced an error.;
      %goto macERROR;
   %end;

   %tu_tidyup(rmdset=&workroot._temp_,glbmac=NONE)

   %goto exit;

 %macERROR:
   %let g_abort = 1;
   %put %str(RTER)ROR: &sysmacroname: Ending with errors, setting G_ABORT=&g_abort, and calling %nrstr(%tu_abort).;
   %tu_abort()

 %exit:
   %put RTNOTE: &sysmacroname: Ending execution.;

%mend tu_createfmt;
