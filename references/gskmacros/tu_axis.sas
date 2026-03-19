/*----------------------------------------------------------------------------------------
| Macro Name        : tu_axis.sas
|
| Macro Version     : 1 build 2
|                     (YW Note: version 1 build 2 is the re-write of the macro. It is not 
|                      based on version 1 build 1)
|                     This is actually a re-write of the code that came in from an outsource
|                     but since Build 001 was never approved and archived in our archive folder,
|                     this version must be considered Build 001.         
|
| SAS version       : SAS v8
|
| Created By        : Yongwei Wang (YW62951)
|
| Date              : 29-Mar-06
|
| Macro Purpose     : This unit creates an Axis Property dataset which defines the 
|                     appearance of the axis as well as the number and location of tick
|                     marks. The unit analyzes an AXIS statement and returns a dataset 
|                     with a separate variable for each property defined by the AXIS 
|                     statement.
|
| Macro Design      : PROCEDURE STYLE
|
| Input Parameters  :
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| AXIS                Specifies the AXIS which will be used to define   (Blank)
|                     the location, values and appearance of the axis
|                     defined by &axisname.
|                     Valid Values: A definition of the AXIS which can
|                     be used in an AXIS1-99 statement
|
| AXISNAME            Specifies which axis is defined (AXIS1-99) by     AXIS1
|                     this instance of the macro.
|                     Valid Values: AXIS1-99
|
| AXISVAR             Specifies the SAS variable for which the axis is  (Blank)
|                     defined.
|                     Valid Values: A valid SAS variable name which
|                     exists in &DSETIN
|
| AXISVARDECODE       Specifies a SAS variable on &DSETIN which is the  (Blank)
|                     decoded values of &AXISVAR, and will be
|                     displayed under the major tick of the AXIS.
|                     Valid Values: Blank or a valid SAS variable name
|                     which exists in &DSETIN
|
| DSETIN              Specifies the input dataset name. This dataset    (Blank)
|                     shall contain the variable to be plotted on the
|                     axis (&AXISVAR), and may contain decoded values
|                     of this variable (&AXISECODEVAR).
|                     Valid Values: An existing SAS data set name
|
| DSETOUT             Specifies the name of the output dataset that     _axisdset_
|                     will contain the AXIS property data.
|                     Valid Values: A valid SAS data set name
|
| FORMATS             Specifies a definition of formats which can be    (Blank)
|                     used in SAS format statement.
|                     Valid Values: Blank or a definition of formats
|                     which can be used in SAS format statement
|
| LABELS              Specifies a definition of labels which can be     (Blank)
|                     used in a SAS label statement.
|                     Valid Values: Blank or a definition of labels
|                     which can be used in SAS label statement
|
| LOWLIMIT            Specifies the minimum value which will be         (Blank)
|                     displayed on the axis.
|                     Valid Values: Blank or a number
|
| UPLIMIT             Specifies the maximum value which will be         (Blank)
|                     displayed on the axis.
|                     Valid Values: Blank or a number
|
|---------------------------------------------------------------------------------------------------
| Output: This unit shall create an output dataset (&DSETOUT) which has the axis property data
|         (the Axis Property dataset).
|---------------------------------------------------------------------------------------------------
| Global macro variables created: NONE
|
| Macros called :
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_getproperty
| (@) tu_putglobals
| (@) tu_tidyup
|
| Example:
|  %tu_axis(AXIS                =c=black  order=( 0 to 70 by 10 ) width=15 label=(h=14pt),          
|           AXISNAME            =AXIS1,     
|           AXISVAR             =aestdt,          
|           DSETIN              =ardata.ae,          
|           DSETOUT             =_axisdset_
|           );                              
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|-------------------------------------------------------------------------------------------------*/

%macro tu_axis(
   AXIS                =,                  /* Definition of the AXIS */
   AXISNAME            =AXIS1,             /* Name of the axis */
   AXISVAR             =,                  /* AXIS variable */
   AXISVARDECODE       =,                  /* Decode of &AXISVAR */
   DSETIN              =,                  /* Input data set */
   DSETOUT             =_axisdset_,        /* Output AXIS property data set */
   FORMATS             =,                  /* Format definition */
   LABELS              =,                  /* Label definition */
   LOWLIMIT            =,                  /* Minimum display value of &AXISVAR */
   UPLIMIT             =                   /* Maximum display value of &AXISVAR */
   );

   /*
   / N1.Call %tr_putlocals to echo the macro name and version to the log.
   / N2.Call %tu_putglobals to echo the parameter values and values of global macro
   /    variables to the log
   /-----------------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;
   
   /* this is actually a re-write of the code that came in from an outsource but 
      since Build 001 was never approved and archived in our archive folder,
      this version will be considered Build 001.                                       */

   %include "&g_refdata./tr_putlocals.sas";
   %tu_putglobals(varsin=G_DDDATASETNAME  G_ANALY_DISP)

   /*
   / N3.Perform parameter validation. After all have been validated, if an error is
   /    found then call %tu_abort.
   /-----------------------------------------------------------------------------------*/
   %local l_charvars l_datetype l_flag l_i l_format l_length l_order1 l_order 
          l_prefix l_property l_tmp l_type l_vars l_word l_count l_lowlimit l_uplimit;
          
   /*
   /  C1.Check that none of required parameters are blank.
   /-----------------------------------------------------------------------------------*/
   
   %let l_tmp=AXIS AXISNAME AXISVAR DSETIN DSETOUT;
   %do l_i=1 %to 5;
      %let l_word=%scan(&l_tmp, &l_i);     
      %if %nrbquote(&&&l_word) eq %then 
      %do;
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Parameter &l_word is blank and it is required.;
      %end;
   %end; /* %do l_i=1 to 5 */
       
   /*
   / C5.Check that &DSETIN is an existing SAS dataset.
   /-----------------------------------------------------------------------------------*/
   
   %let l_flag=0;
   %if %nrbquote(&dsetin) ne %then
   %do;
      %if not %sysfunc(exist(&dsetin)) %then
      %do;      
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Dataset DSETIN (=&dsetin) does not exist.;
      %end;
      %else %let l_flag=1;
   %end; /* %if &dsetin ne */

   /*
   / C2.If &AXISVARDECODE is given; check that it is a variable that exists on &DSETIN
   /-----------------------------------------------------------------------------------*/
   
   %if ( %nrbquote(&AXISVARDECODE) ne ) and ( &l_flag ) %then
   %do;
      %if %tu_chkvarsexist(&dsetin, &AXISVARDECODE) ne %then
      %do;      
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Variable AXISVARDECODE(=&AXISVARDECODE) does not exist in DSETIN(=&dsetin);
      %end;
   %end; /* %if ( %nrbquote(&AXISVARDECODE) ne ) and ( &l_flag ) */

   /*
   / C3.Check that &AXISNAME is one of AXIS1 - AXIS99
   /-----------------------------------------------------------------------------------*/
   
   %let axisname=%qupcase(&axisname);
   %let l_tmp=0; 
   %do l_i=1 %to 99;
      %if &axisname eq AXIS&l_i %then
      %do;
         %let l_tmp=1;
         %let l_i=99;
      %end;
   %end; /* %do l_i=1 %to 99 */
   
   %if not &l_tmp %then
   %do;   
      %let g_abort=1;
      %put RTE%str(RROR): &sysmacroname: Value of AXISNAME(=&axisname) is invalid. Valid values should be between AXIS1 to AXIS99;
   %end;
      
   /*
   / C4.Check that &AXISVAR exists on &DSETIN.
   /-----------------------------------------------------------------------------------*/
   
   %let axisvar=%qupcase(&axisvar);
   %if ( &axisvar ne ) and ( &l_flag ) %then
   %do;   
      %if %tu_chkvarsexist(&dsetin, &AXISVAR) ne %then
      %do;      
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Variable AXISVAR(=&AXISVAR) does not exist in DSETIN(=&dsetin);
      %end;
   %end; /* %if ( &axisvar ne ) and ( &l_flag ) */

   /*
   / C6.If &LOWLIMIT is given; check that it is a number. Write a note to the log if the
   /    value does not appear in &AXISVAR, but do not abort
   /-----------------------------------------------------------------------------------*/
   
   %let LOWLIMIT=%nrbquote(&LOWLIMIT); 
   %let l_flag=1;              
   %if &LOWLIMIT ne %then
   %do;
      %if %verify(&lowlimit, %str(.0123456789 )) GT 0 %then 
      %do;      
         %let g_abort=1;
         %let l_flag=0;
         %put RTE%str(RROR): &sysmacroname: Value of LOWLIMIT(=&lowlimit) is invalid. It should be a number.;
      %end;      
   %end; /* %if &LOWLIMIT ne */
   
   /*
   / C7.If &UPLIMIT is given; check that it is a number. Write a note to the log if the
   /    value does not appear in &AXISVAR, but do not abort
   /-----------------------------------------------------------------------------------*/
   
   %let UPLIMIT=%nrbquote(&UPLIMIT); 
   %if &UPLIMIT ne %then
   %do;
      %if %verify(&uplimit, %str(.0123456789 )) GT 0 %then 
      %do;      
         %let g_abort=1;
         %let l_flag=0;
         %put RTE%str(RROR): &sysmacroname: Value of UPLIMIT(=&uplimit) is invalid. It should be a number.;
      %end;      
   %end; /* %if &UPLIMIT ne */

   /*
   / C8.If &LOWLIMIT and &UPLIMIT are given, check that &LOWLIMIT is less than &UPLIMIT.
   /-----------------------------------------------------------------------------------*/
   
   %if ( &lowlimit ne ) and ( &uplimit ne ) and ( &l_flag ) %then
   %do;
      %if &lowlimit ge &uplimit %then
      %do;      
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Value of UPLIMIT(=&uplimit) is less than LOWLIMIT(=&lowlimit).;
      %end;
   %end;

   /*
   / C9.If error is found, set g_abort and call %tu_abort.
   /-----------------------------------------------------------------------------------*/
   
   %if &g_abort gt 0 %then %goto macend;

   /* Normal Processes */

   /*
   / N4.Set the work dataset name prefix to _axis.
   /-----------------------------------------------------------------------------------*/
   
   %let l_prefix=_axis;

   /*
   / N5.If &FORMATS is not blank apply it to &DSETIN.
   /-----------------------------------------------------------------------------------*/
   
   %if %nrbquote(&formats.&labels) ne %then
   %do;
      data &l_prefix.dsetin;
         set &dsetin;
         %if %nrbquote(&formats) ne %then format &formats;;
         %if %nrbquote(&labels) ne %then label &labels;;
      run;  
      %let dsetin=&l_prefix.dsetin;
   %end;

   /*
   / N6.If &DSETOUT does not exist, create it. If it does exist already, append the new
   /    values to it.
   /-----------------------------------------------------------------------------------*/
   
   /*
   / N7.Populate &DESTOUT as follows:
   /-----------------------------------------------------------------------------------*/
   
   %let l_vars=COLOR LABEL LOGBASE LOGSTYLE MAJOR MINOR REFLABEL STYLE
               VALUE SPLIT ORDER LENGTH OFFSET WIDTH ORIGIN;
   %let l_charvars=COLOR LABEL LOGBASE LOGSTYLE MAJOR MINOR REFLABEL STYLE
               VALUE OFFSET SPLIT ORDER ORIGIN;
   
                    
   data &l_prefix.axis1;
      length name $32 MODIFIEDYN $1;
      %let l_property=%tu_getproperty(equalsignyn=N,keyword=NOBRACKETS,propertylist=&axis);
      %if %nrbquote(&l_property) eq %then
      %do;
         NOBRACKETS=0;
      %end;
      %else %do;
         NOBRACKETS=1;
      %end;      
      
      %let l_property=%tu_getproperty(equalsignyn=N,keyword=NOPLANE,propertylist=&axis);
      %if %nrbquote(&l_property) eq %then
      %do;
         NOPLANE=0;
      %end;
      %else %do;
         NOPLANE=1;
      %end;      
      NAME="&axisname";
      MODIFIEDYN='N';
   run;

   %do l_i=1 %to 15;    
      %let l_word=%scan(&l_vars, &l_i);
      %let l_property=%tu_getproperty(equalsignyn=Y,keyword=&l_word,propertylist=&axis);
      
      %if ( %qupcase(&l_word) eq COLOR ) and ( %nrbquote(&l_property) eq ) %then
      %do;
         %let l_property=%tu_getproperty(equalsignyn=Y,keyword=%substr(&l_word, 1, 1),propertylist=&axis);      
      %end;
      
      %if ( &l_word eq LABEL ) and ( %nrbquote(&l_property) eq ) %then 
      %do;
         data _null_;            
            if 0 then set &dsetin(keep=&axisvar);
            call symput('l_property', '"'||trim(left(vlabel(&axisvar)))||'"');
         run;   
      %end;
      
      %let l_length=%length(&l_property);      
      %if &l_length lt 1 %then %let l_length=1;                   
      data &l_prefix.axis1;
         %if %sysfunc(indexw(&l_charvars, &l_word)) %then
         %do;
            length &l_word $&l_length.;
         %end;         
         set &l_prefix.axis1;
         &l_word=symget('l_property');
      run;
   %end; /* %do l_i=1 %to 15 */      

   /*
   / N8.&TICKNUM and &TICKPROPERTY shall be built for each major tick mark on the axis.
   /    The following should be considered when determining the number of tick marks and
   /    the variable value to be plotted at each tick mark
   /  a.The number of major tick marks may be given (presented in decreasing order of
   /    precedence):
   /  i.As a property for MAJOR
   / ii.Through the use of an ORDER= specification in the AXIS statement
   /iii.Through the number of unique values of &AXISVAR in the dataset, if &AXISVAR is
   /    a character variable and ORDER is not used.
   / iv.If &AXISVAR is a numeric variable and ORDER is not used, take floor((maximum
   /    - minimum)/10 ) as step to create major ticks. If &UPLIMITS and/or &LOWLIMIT
   /    are given, taken them as maximum and minimum values.
   /  v.The limits of the axes may be given by (in decreasing order of precedence):
   /    &LOWLIMIT and &UPLIMIT
   / vi.Through the use of an ORDER= specification in the AXIS statement
   /vii.The unique values of &AXISVAR in the dataset.
   /-----------------------------------------------------------------------------------*/
   
    /* Get type and format of &axisvar */ 
    data _null_;
       if 0 then set &dsetin;
       call symput('l_type', compress(vtype(&axisvar)));
       call symput('l_format', compress(vformat(&axisvar)));       
    run;
    
    %let l_order=%tu_getproperty(equalsignyn=Y,keyword=ORDER,propertylist=&axis);
    %if %nrbquote(&l_order) eq %then
    %do;
       %let l_tmp=%substr(&l_word, 1, 1);
       %let l_order=%tu_getproperty(equalsignyn=Y,keyword=O,propertylist=&axis);
    %end;
    %let l_order1=&l_order;
    /* remove ( and ) from ORDER property */
    data _null_;
       length order $32761;
       order=trim(left(symget('l_order')));
       rx=rxparse("$(10)");
       call rxsubstr(rx, order, pos, len);       
       call rxfree(rx);
       if pos eq 1 then
       do;
          order=substr(order, 2, len - 2);
          call symput('l_order', trim(order));
       end;
    run;
     
    /* sort &dsetin */
    proc sort data=&dsetin out=&l_prefix.sort(keep=&axisvar &axisvardecode) nodupkey;
       by &axisvar &axisvardecode;
       where not missing(&axisvar);
    run;
    
    /* get upper limit and lower limit of &axisvar and compare with &lowlimt and &uplimit */                      
    %let l_lowlimit=&lowlimit;
    %let l_uplimit=&uplimit;
    data _null_;
       set &l_prefix.sort end=end;;
       by &axisvar;
       if _n_ eq 1 then
       do;       
          __flag__=0;
          %if &lowlimit ne %then
          %do;
             %if &l_type eq C %then
             %do;
                if &axisvar gt "&l_lowlimit" then 
                do;
                   __flag__=1;   
                   call symput('l_lowlimit', trim(left(&axisvar)));
                 end;
             %end; /* %if &l_type eq C */
             %else %do;
                if &axisvar gt &lowlimit then 
                do;
                   __flag__=1;
                   call symput('l_lowlimit', trim(put(&axisvar, best.)));
                end;
             %end; /* %else %do */
          %end; /* %if &lowlimit ne */
          %else %do;
             %if &l_type eq C %then
             %do;
                call symput('l_lowlimit', trim(left(&axisvar)));
             %end;         
             %else %do;
                call symput('l_lowlimit', trim(put(&axisvar, best.)));
             %end;
          %end;          
           if __flag__ then
           do;
              put "RTN%str(OTE): &sysmacroname: Value of LOWLIMIT(=&lowlimit) is greater than the minimum value of AXISVAR(=&axisvar)";
              put "RTN%str(OTE): &sysmacroname: It will be ignored";             
           end;
       end; /* if _n_ eq 1 */
       
       if end then
       do;       
          __flag__=0;
          %if &uplimit ne %then
          %do;
             %if &l_type eq C %then
             %do;
                if &axisvar lt "&uplimit" then 
                do;
                   __flag__=1;   
                   call symput('l_uplimit', trim(left(&axisvar)));
                end;
             %end; /* %if &l_type eq C */
             %else %do;
                if &axisvar lt &uplimit then 
                do;
                   __flag__=1;
                   call symput('l_uplimit', trim(put(&axisvar, best.)));
                end;
             %end; /* %else %do */
          %end; /* %if &uplimit ne */
          %else %do;
             %if &l_type eq C %then
             %do;
                call symput('l_uplimit', trim(left(&axisvar)));
             %end;         
             %else %do;
                call symput('l_uplimit', trim(put(&axisvar, best.)));
             %end;
          %end;/* %else %do */          
           if __flag__ then
           do;
              put "RTN%str(OTE): &sysmacroname: Value of UPLIMIT(=&uplimit) is less than the maximum value of AXISVAR(=&axisvar)";
              put "RTN%str(OTE): &sysmacroname: It will be ignored";             
           end;
           call symput('l_count', put(_n_, 6.0));
       end; /* if end */                           
    run;   
    
    %if %nrbquote(&l_order) ne %then
    %do;
       /* Check if values in ORDER property are date values */     
       %let l_word=;
       %if &l_type eq N %then
       %do;
          %let l_tmp=%index(%nrbquote(&l_order), %str(%'dt));
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%'dt));
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%"dt));
          %else %let l_datetype=DT;
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%'d));
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%"d));
          %else %let l_datetype=D;
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%'t));
          %if &l_tmp eq 0 %then %let l_tmp=%index(%nrbquote(&l_order), %str(%"t));
          %else %let l_datetype=T;          

          %let l_i=%index(%qupcase(&l_order), BY);          
          %if ( &l_tmp gt 1 ) and ( &l_i gt 0 ) %then
          %do;
             %let l_word=%qsubstr(&l_order, %eval(&l_i + 2));
             %let l_order=%qsubstr(&l_order, 1, %eval(&l_i - 1));
             %let l_type=D;
          %end; 
       %end; /* %if &l_type eq N */  
                                             
       /* Split ORDER to tick number and tick label */
       data &l_prefix.order;
          length chartick varvalue $100;
          keep ticknum chartick varvalue;
          ticknum=0;
          %if &l_type eq C %then
          %do;
             %let l_i=1;
             %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));
             %do %while (%nrbquote(&l_tmp) ne );
                chartick=&l_tmp;
                ticknum=ticknum +1;
                varvalue=chartick;
                output;       
                %let l_i=%eval(&l_i + 1);                   
                %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));
             %end;
          %end; /* %if &l_type eq C */
          %else %if ( &l_type eq D ) and ( %nrbquote(&l_word) ne ) %then
          %do;             
             maxtick=INTCK("&l_word",%scan(&l_order, 1, %str( )),%scan(&l_order, 1) );
             do ticknum=1 to maxtick;
                numtick=INTNX("&l_word",%scan(&l_order, 1, %str( )),ticknum);                 
                chartick=put(numtick, &l_format);
                varvalue=put(numtick, best.);
                output;
             end;              
          %end; /* %if ( &l_type eq D ) and ( %nrbquote(&l_word) ne ) */  
          %else %if ( &l_type eq D ) %then
          %do;
             %let l_i=1;
             %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));
             %do %while (%nrbquote(&l_tmp) ne );
                numtick=&l_tmp;
                chartick=put(numtick, &l_format);
                varvalue=put(numtick, best.);
                ticknum=ticknum +1;
                output;       
                %let l_i=%eval(&l_i + 1);  
                %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));               
             %end;           
          %end; /* %if ( &l_type eq D ) */
          %else %do;     
             %if %index(%qupcase(&l_order), TO) %then
             %do;
                do numtick=&l_order;
                   ticknum=ticknum +1;
                   chartick=put(numtick, &l_format);
                   varvalue=put(numtick, best.);
                   output;
                end;
             %end; /* %if %index(%qupcase(&l_order), TO) */
             %else %do;
                %let l_i=1;
                %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));
                %do %while (%nrbquote(&l_tmp) ne );
                   numtick=&l_tmp;
                   chartick=put(numtick, &l_format);
                   varvalue=put(numtick, best.);
                   ticknum=ticknum +1;
                   output;       
                   %let l_i=%eval(&l_i + 1);  
                   %let l_tmp=%qscan(%nrbquote(&l_order), &l_i, %str( ));               
                %end;                            
             %end; /* if %index(%qupcase(&l_order), TO) %else */
          %end; /* %else %do */
       run;     
       
      /* Check errors in DSETIN */
      %if &SYSERR GT 0 %then
      %do;
        %put %str(RTERR)OR: &sysmacroname: ORDER in AXIS(=&axis) cause SAS error(s);
        %goto macerr;
      %end;       
    %end; /* %if %nrbquote(&l_order) ne */
    %else %do;
       /* Get a list of user defined formats */
       %let l_flag=;
       %let l_tmp=%scan(%sysfunc(getoption(FMTSEARCH)), 1, %str(%(%)));
       %if %sysfunc(indexw(%qupcase(&l_tmp), LIBRARY)) EQ 0 %then
          %let l_tmp=LIBRARY &l_tmp;
       %if %sysfunc(indexw(%qupcase(&l_tmp), WORK)) EQ 0 %then
          %let l_tmp=WORK &l_tmp;
       
       %let l_i=1;
       %LET l_word=%scan(&l_tmp, &l_i, %str(, ));
       
       %do %while (%nrbquote(&l_word) NE );
          %if %index(&l_word, .) EQ 0 %then %let l_word=&l_word..formats;
          %if %sysfunc(exist(&l_word, CATALOG)) %then %do;
             proc format library=&l_word cntlout=&l_prefix.fmt&l_i(keep=FMTNAME);
             run;
             
             %if %nrbquote(&l_flag) eq %then %let l_flag=&l_prefix.fmt&l_i;
             %else %do;
                data &l_prefix.chkfmt;
                   set &l_flag &l_prefix.fmt&l_i;
                run;                             
                %let l_flag=&l_prefix.chkfmt;
             %end;
          %end; /* %if %sysfunc(exist(&l_word, CATALOG)) */       
          %let l_i=%eval(&l_i + 1);
          %let l_word=%scan(&l_tmp, &l_i, %str(, ));
       %end; /* %do %while (%nrbquote(&l_word) NE ) */
             
       /* Check if the format of &tmtvar is user defined format */
       %let l_i=1; 
       %if %nrbquote(&l_flag) ne %then
       %do;       
          data _null_;          
             length newfmt $50;
             set &l_flag;
             retain newfmt "" tmtfmt "&l_format";
             if _n_ eq 1 then
             do;
                do i=length(TMTFMT) to 1 by -1;
                   if not index(".0123456789", substr(tmtfmt, i, 1)) then
                   do;          
                      newfmt=substr(tmtfmt, 1, i);
                      i=1;
                   end;
                end; /* do i=length(TMTFMT) to 1 */        
             end; /* if _n_ eq 1 */
             if upcase(newfmt) eq upcase(fmtname) then
             do;
                call symput('l_i','0');
                stop;
             end;
          run;  
       %end; /* %if %nrbquote(&l_flag) ne */
       %if &l_i %then %let l_format=;  
       
       proc sort data=&dsetin out=&l_prefix.sort(keep=&axisvar &axisvardecode) nodupkey;
          by &axisvar &axisvardecode;
       run;
       
       data &l_prefix.order;       
          length chartick varvalue $100;
          set &l_prefix.sort;
          keep ticknum chartick varvalue;
          %if &l_type eq C %then
          %do;
             varvalue=&axisvar;
          %end;
          %else %do;
             varvalue=put(&axisvar, best.);
          %end;
          ticknum=_n_;            
          %if %nrbquote(&l_format) ne %then
          %do;
             chartick=put(&axisvar, &l_format);
          %end;
          %else %if %nrbquote(&axisvardecode) ne %then
          %do;
             chartick=&axisvardecode;                                             
          %end;
          %else %if &l_type eq C %then
          %do;
             chartick=putc(&axisvar, vformat(&axisvar));
          %end;
          %else %do;          
             if _n_ eq 1 then
             do;                             
                %if %nrbquote(&l_uplimit) ne %then
                   max_tick=&l_uplimit;
                %else
                   max_tick=0;
                ;
                
                %if %nrbquote(&l_lowlimit) ne %then
                   min_tick=&l_lowlimit;
                %else
                   min_tick=0;
                ;
                step=(max_tick - min_tick) / 10;
                if step eq 0 then step=1;
                dec=10 ** floor(log10(step));
                if step/dec gt 2 then step=dec * 10;
                else if step/dec gt 1 then step=dec * 2;
                else step=dec;
                
                if (dec le 1) and (dec ge 0.1) and (min_tick ge 0) then min_tick=0;
                min_tick=floor(min_tick/dec) * dec;
                if (max_tick - min_tick)/step gt floor((max_tick - min_tick)/step) then
                   max_tick=floor(max_tick/dec) * dec + step;
                else
                   max_tick=floor(max_tick/dec) * dec;
                do ticknum=min_tick to max_tick by step;
                   chartick=putn(ticknum, vformat(&axisvar));
                   varvalue=put(ticknum, best.);
                   output;
                end;
                stop;
             end;
          %end; /* %else %do */
       run;  
    %end; /* %if %nrbquote(&l_order) ne %else */
    
   /*
   / N9.Use this information from Step 7 to. Build the variables &TICKNUM and
   /    &TICKPROPERTY.
   /  a.If the number of major tick marks was determined from &AXISVAR, build &TICKNUM
   /    and a text string to be used as the axis label from the &AXISVAR and
   /    &AXISVARDECODE pair.
   /  b.Include other properties in &TICKPROPERTY if they are specified.
   /    For example, if the user specifies VALUE=(tick=3 justify=r color='Black' 'LINE1'
   /    justify=c color='Red' 'LINE2'), then the following must be added to
   /    &TICKPROPERTY: justify=r color='Black' 'LINE1' justify=c color='Red' 'LINE2'
   /-----------------------------------------------------------------------------------*/

   data &l_prefix.tick;        
      length tickproperty $500 tickvalue $100;
      set &l_prefix.axis1(keep=value);
      keep ticknum tickproperty tickvalue;
      tickproperty=left(value);
      value=upcase(value);
      rx=rxparse(" 'TICK' *'=' *$d ");
      rx1=rxparse("$q");
      rx2=rxparse("$(10)");
      pos=0;
      len=0;
      call rxsubstr(rx2, value, pos, len);
      if (pos eq 1) and (len eq length(value)) then
      do;
         value=substr(value, 2, length(value) - 2);
      end;

      call rxsubstr(rx, value, pos, len);
      if ( (pos gt 0) and (len gt 1) ) then
      do while( (pos gt 0) and (len gt 1) );
         tickvalue=substr(value, pos, len);
         ticknum=input(scan(tickvalue, 2, '='), best.);       
         if vlength(value) gt pos + len then
            value=substr(value, pos + len);
         else
            value='';
         call rxsubstr(rx, value, pos, len);
         if ( (pos gt 1) and (len gt 1) ) then
            tickvalue=substr(value, 1, pos - 1);
         else 
            tickvalue=value;    
         call rxsubstr(rx1, tickvalue, pos1, len1);
         if (pos1 gt 0) and (len1 gt 2) then            
            tickvalue=substr(tickvalue, pos1 + 1, len1 - 2);
         else if (pos1 gt 0) and (len1 gt 1) then
            tickvalue='';
         else
            tickvalue='DEFAULT-TICK-VALUE';                 
         output;
      end;      
      else do;         
         ticknum=0;
         value=left(value);
         call rxsubstr(rx1, value, pos, len);
         do while( (pos gt 0) and (len gt 1) );
            ticknum=ticknum + 1;     
            if len gt 2 then
               tickvalue=substr(value, pos + 1, len -2);
            else 
               tickvalue='';
            if vlength(value) gt pos + len then
               value=left(substr(value, pos + len));
            else
               value='';               
            call rxsubstr(rx, value, pos, len);            
            output;
         end;               
      end;
      call rxfree(rx1);
      call rxfree(rx2);
      call rxfree(rx);
   run;   

   /*
   / N10.Append &TICKNUM and &TICKPROPERTY to the axis property dataset.
   / N11.Populate VARVALUE with the variable value.
   /-----------------------------------------------------------------------------------*/
   
   proc sort data=&l_prefix.tick nodupkey;  
      by ticknum;
   run;
   
   proc sort data=&l_prefix.order;  
      by ticknum;
   run;
   
   data &l_prefix.merge;
      merge &l_prefix.tick (in=_in1_)
            &l_prefix.order ;
      by ticknum;
      keep ticknum tickproperty varvalue tickvalue; 
      if not _in1_ then
      do;
         tickproperty="tick="||left(put(ticknum, 6.0));
         tickproperty=trim(left(tickproperty))||' "'||trim(left(chartick))||'"';           
         tickvalue='DEFAULT-TICK-VALUE';
      end;
   run;
            
   proc sql noprint;
      create table &l_prefix.withtick as
      select a.*, b.* 
      from &l_prefix.merge as a, &l_prefix.axis1 as b;
   quit;

   /*
   / N12.Populate ORDER.
   /-----------------------------------------------------------------------------------*/
   
   data &l_prefix.final;   
      length offsetunit $10 temp $50;
      set &l_prefix.withtick;
      order=symget('l_order1');
      drop value temp temp2 offset;
      
      if index(offset,'()') then
      do;
         temp2=scan(offset, 2, '()');
         temp=scan(offsetunit, 1, ',');
         if not missing(temp) then
         do;
            offsetbegin=scan(temp, 1, ' ');   
            offsetunit=scan(temp, 2, ' ');
         end;
         temp=scan(offsetunit, 2, ',');
         if not missing(temp) then
         do;
            offsetend=scan(temp, 1, ' ');   
            if not missing(offsetunit) then
               offsetunit=scan(temp, 2, ' ');
         end;
         if not missing(offsetunit) then
            offsetunit=scan(offset, 3, '()');                            
      end; /* index(offset,'()') */
      
      %if &l_type eq N %then
      %do;
         %if %nrbquote(&uplimit) ne %then
         %do;
            if input(varvalue, best.) gt &uplimit then delete;
         %end;
         %if %nrbquote(&lowlimit) ne %then
         %do;      
            if input(varvalue, best.) lt &lowlimit then delete;      
         %end;
      %end; /* %if &l_type eq N */
      %else %do;
         %if %nrbquote(&uplimit) ne %then
         %do;
            if varvalue gt "&uplimit" then delete;
         %end;
         %if %nrbquote(&lowlimit) ne %then
         %do;              
            if varvalue lt "&lowlimit" then delete;                
         %end;
      %end; /* %else %do */
   run;   
   
   %if %sysfunc(exist(&dsetout)) %then
   %do;
      proc sql noprint;
         create table &dsetout as (
         select * from &dsetout 
         where name ne "&axisname"
         outer union corr
         select * from &l_prefix.final
         );
      quit;     
   %end;
   %else %do;   
      data &dsetout (label='Output Data set from %tu_axis');
         set &l_prefix.final;
      run;         
   %end;

   %goto macend;

%MACERR:
   %let g_abort=1;
   %tu_abort();

%MACEND:

   /*
   / N13.Call %tu_tidyup to delete the temporary data set.
   /-----------------------------------------------------------------------------------*/

   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      );

%mend tu_axis;



