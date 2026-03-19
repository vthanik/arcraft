/*******************************************************************************
*
*  Macro name:     td_lb5.sas
*
*  Macro version:  1
*
*  SAS version:    8.2
*
*
*  Created by:     Yongwei Wang (YW62951)
*
*  Date:           20Oct2003
*
*  Macro purpose:  display macro to generate IDSL lb5 listing
*
*  Macro design:   procedure style
*
********************************************************************************
*  Input parameters:
*
*   Name           Description                                         default
*------------------------------------------------------------------------------
*  dsetin          The lab data set to act as the subject of the 
*                  report. Valid values: name of a data set
*                  meeting the IDSL dataset specification for 
*                  lab data                                            ardata.lab
*  stackvar1       Specifies any variables that should be stacked 
*                  together.  See Unit Specification for HARP 
*                  Reporting Tools TU_STACKVAR[5] for more detail 
*                  regarding macro parameters that can be used in 
*                  the macro call.  Note that the DSETIN parameter 
*                  will be passed by %tu_list and should not be 
*                  provided here.                                      %str(varsin=&g_centid &g_subjid, varout=st_lb_cs5, sepc=/)
*  stackvar2       Additional stacked variables (ref: stackvar1)       %str(varsin=age sex race, varout=st_lb_asr5, sepc=/)
*  stackvar3       Additional stacked variables (ref: stackvar1)       %str(varsin=lbdt lbactdy, varout=st_lb_da5, sepc=/, splitc=)
*  stackvar4       Additional stacked variables (ref: stackvar1)
*  - stackvar15                                                        blank
*  varlabelstyle   Specifies the style of labels to be applied by 
*                  the %tu_labelvars macro Valid values: as 
*                  specified by %tu_labelvars, i.e. SHORT or STD       short
*
*  dddatasetlabel  Specifies the label to be applied to the 
*                  DD dataset Valid values: a non-blank text 
*                  string                                              DD dataset for LB5 listing
*  splitchar       Specifies the split character to be passed to 
*                  %tu_display Valid values: one single character      ~
*  computebefore-
*  pagelines       See Unit Specification for HARP Reporting Tools
*                  TU_LIST[4] for complete details.                    trtmnt $local. : &g_trtgrp
*  computebefore-
*  pagevars        See Unit Specification for HARP Reporting Tools 
*                  TU_LIST[4] for complete details.                    &g_trtcd  
*  columns         A PROC REPORT column statement specification.  
*                  Including spanning titles and variable names
*                  Valid values: one or more variable names from 
*                  DSETIN plus other elements of valid PROC REPORT 
*                  COLUMN statement syntax                             &g_trtcd &g_trtgrp &g_centid &g_subjid st_lb_cs5 st_lb_asr5 lbtest visitnum visit lbdt st_lb_da5 ('_Converted Data_' lbstresn normrng) ('Flag[1]' lbnrcd lbcccd)    
*  ABNORMALTYPE    Specifies type of abnormalities: Normal Range or 
*                  Clinical Corcern. NR for Normal Range. CC for 
*                  Clinical Concern and BL for change from baseline. 
*                  It decids whether subjects with at least one 
*                  abnormal clinical concern, abnormal vaule or 
*                  abnormal change from baseline should be included 
*                  in the list
*                  Valid values: NR, CC or BL                          CC
*  ABNORMALCDS	   Specifies A list of abnormal values of normal 
*                  range (clinical concern) indicator code. It will 
*                  be part of "where in  (&abnormalcds)" statement 
*                  to get the subjects with abnormalites. If blank, 
*                  all subjects will be selected
*                  Valid values: Blank or a list of valid value of 
*                  LBNRCD, while ABNORMALTYPE equles NR,  or LBCCCD, 
*                  while ABNORMALTYPE equles CC                        %str("H" "L")
*  RANGETYPE       Specifies type of of the range value that needs to 
*                  be displayed: Normal Range or Clinical Corcern. NR 
*                  for Normal Range. CC for Clinical Concern. BL for
*                  change from baseline range
*                  Valid values: NR, CC or BL                          NR 
*  ordervars       List of variables that will receive the PROC 
*                  REPORT define statement attribute ORDER Valid 
*                  values: one or more variable names from DSETIN 
*                  that are also defined with COLUMNS                  &g_trtcd &g_trtgrp &g_centid &g_subjid &g_trtcd st_lb_cs5 st_lb_asr5 lbtest visitnum visit lbdt     
*  sharecolvars    List of variables that will share print space. 
*                  The attributes of the last variable in the list 
*                  define the column width and flow options Valid 
*                  values: one or more variable names from DSETIN
*                  AE5 shows an example of this style of output
*                  The formatted values of the variables shall be 
*                  written above each other in one column.             blank
*  sharecolvars-
*  indent          Indentation factor for ShareColVars. Stacked 
*                  values shall be progressively indented by 
*                  multiples of ShareColVarsIndent Valid values: 
*                  positive integer                                    2
*  linevars        List of order variables that are printed with 
*                  LINE statements in PROC REPORT Valid values: one
*                  or more variable names from DSETIN that are also 
*                  defined with ORDERVARS These values shall be 
*                  written with a BREAK BEFORE when the value of
*                  one of the variables change. The variables will 
*                  automatically be defined as NOPRINT                 blank
*  descending      List of ORDERVARS that are given the PROC 
*                  REPORT define statement attribute DESCENDING
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with ORDERVARS         blank
*  orderformatted  Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement 
*                  attribute order=formatted.  Valid values: one 
*                  or more variable names from DSETIN that are 
*                  also defined with ORDERVARS Variables not 
*                  listed in ORDERFORMATTED, ORDERFREQ, or 
*                  ORDERDATA are given the define attribute 
*                  order=internal                                      blank
*  orderfreq       Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement
*                  attribute order=freq. Valid values: one or more 
*                  variable names from DSETIN that are also 
*                  defined with ORDERVARS Variables not listed in 
*                  ORDERFORMATTED, ORDERFREQ, or ORDERDATA are 
*                  given the define attribute order=internal           blank
*  orderdata       Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement 
*                  attribute order=data. Valid values: one or more 
*                  variable names from DSETIN that are also defined 
*                  with ORDERVARS Variables not listed in 
*                  ORDERFORMATTED, ORDERFREQ, or ORDERDATA are 
*                  given the define attribute order=internal           blank 
*  noprintvars     Variables listed in the COLUMN parameter that 
*                  are given the PROC REPORT define statement 
*                  attribute noprint. Valid values: one or more 
*                  variable names from DSETIN that are also 
*                  defined with COLUMNS These variables are 
*                  ORDERVARS used to control the order of the 
*                  rows in the display.                                &g_trtcd &g_trtgrp &g_centid &g_subjid visitnum lbdt    
*  byvars          By variables. The variables listed here are 
*                  processed as standard SAS by variables Valid 
*                  values: one or more variable names from DSETIN
*                  No formatting of the display for these variables
*                  is performed by %tu_display.  The user has the
*                  option of the standard SAS BY line, or using 
*                  OPTIONS NOBYLINE and #BYVAL #BYVAR directives 
*                  in title statements.                                blank
*  flowvars        Variables to be defined with the flow option
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS
*                  Flow variables should be given a width through 
*                  the WIDTHS.  If a flow variable does not have 
*                  a width specified the column width will be 
*                  determined by MIN(variable�s format width,
*                  width of  column header)                            st_lb_cs5 st_lb_asr5 lbtest visit st_lb_da5 normrng lbnrcd lbcccd
*  widths          Variables and width to display Valid values: 
*                  values of column names and numeric widths, a 
*                  list of variables followed by a positive 
*                  integer, e.g. widths = a b 10 c 12 d1-d4 6
*                  Numbered range lists are supported in this 
*                  parameter however name range lists, name prefix
*                  lists, and special SAS name lists are not.
*                  Display layout will be optimised by default, 
*                  however any specified widths will cause the 
*                  default to be overridden.                           blank
*  defaultwidths   Specifies column widths for all variables not 
*                  listed in the WIDTHS parameter Valid values: 
*                  values of column names and numeric widths such 
*                  as form valid syntax for a SAS LENGTH statement
*                  For variables that are not given widths through 
*                  either the WIDTHS or DEFAULTWIDTHS parameter will 
*                  be width optimised using: MAX (variable's format
*                  width, width of column header)                      &g_trtgrp 90 st_lb_cs5 7 st_lb_asr5 7 lbtest 16 visit 10 st_lb_da5 13 lbstresn 7 normrng 15 lbnrcd 4 lbcccd 2
*  skipvars        Variables whose change in value causes the display 
*                  to skip a line Valid values: one or more variable 
*                  names from DSETIN that are also defined with 
*                  COLUMNS                                             lbtest
*  pagevars        Variables whose change in value causes the 
*                  display to continue on a new page Valid 
*                  values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS           blank
*  idvars          Variables to appear on each page should the 
*                  report be wider than 1 page. If no value is 
*                  supplied to this parameter then all 
*                  displayable order variables will be defined 
*                  as idvars Valid values: one or more variable
*                  names from DSETIN that are also defined with 
*                  COLUMNS                                             blank
*  centrevars      Variables to be displayed as centre justified
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS 
*                  Variables not appearing in any of the 
*                  parameters CENTREVARS, LEFTVARS, or RIGHTVARS 
*                  will be displayed using the PROC REPORT default. 
*                  Character variables are left justified while 
*                  numeric variables are right justified.              blank
*  leftvars        Variables to be displayed as left justified
*                  Valid values: one or more variable names from
*                  DSETIN that are also defined with COLUMNS           blank
*  rightvars       Variables to be displayed as right justified
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS           blank
*  colspacing      The value of the between-column spacing 
*                  Valid values: positive integer                      2
*  varspacing      Spacing for individual columns Valid values: 
*                  variable name followed by a spacing value, 
*                  e.g. Varspacing=a 1 b 2 c 0
*                  This parameter does NOT allow SAS variable 
*                  lists. These values will override the overall 
*                  COLSPACING parameter. VARSPACING defines the 
*                  number of blank characters to leave between the 
*                  column being defined and the column immediately 
*                  to its left                                         blank
*  formats         Variables and their format for display. For 
*                  use where format for display differs to the 
*                  format on the DSETIN. Valid values: values of 
*                  column names and formats such as form valid 
*                  syntax for a SAS FORMAT statement                   blank
*  labels          Variables and their label for display. For use
*                  where label for display differs to the label 
*                  on the DSETIN Valid values: pairs of variable 
*                  names and labels                                    blank
*  break1          For input of user-specified break statements 
*  - break5        Valid values: valid PROC REPORT BREAK
*                  statements (without "break") The value of 
*                  these parameters are passed directly to PROC
*                  REPORT as: BREAK &break1;                           blank
*  proptions       PROC REPORT statement options to be used in 
*                  addition to MISSING. Valid values: proc 
*                  report options. The option 'Missing' can
*                  not be overridden                                   headline 
*  nowidowvar      Variable whose values must be kept together
*                  on a page Valid values: names of one or more
*                  variables specified in COLUMNS                      blank
*
********************************************************************************
*  Output:
********************************************************************************
*  Global macro variables created:
********************************************************************************
*  Macros called:
*  (@) tr_putlocals
*  (@) tu_chkvarsexist
*  (@) tu_list
*  (@) tu_nobs
*  (@) tu_putglobals
*  (@) tu_tidyup
********************************************************************************
* Change Log
*
* Modified by:             Paul Jarrett (pbj18878)
* Date of modification:    03DEC03
* New version number:      1/2
* Modification ID:         pbj01
* Reason for modification: Correct mis-spelling of "overallsummary".
********************************************************************************
*
* Modified by:
* Date of modification:
* New version number:
* Modification ID:
* Reason for modification:
********************************************************************************/

%macro td_lb5(
   dsetin         =ardata.lab, /* Input lab dataset */
   stackvar1      =%str(varsin=&g_centid &g_subjid, varout=st_lb_cs5, sepc=/), /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))      */
   stackvar2      =%str(varsin=age sex race, varout=st_lb_asr5, sepc=/), /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar3      =%str(varsin=lbdt lbactdy, varout=st_lb_da5, sepc=/, splitc=), /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar4      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar5      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar6      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar7      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar8      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar9      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar10     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar11     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar12     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar13     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar14     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar15     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   varlabelstyle  =SHORT,     /* Specifies the label style for variables (SHORT or STD)  */
   dddatasetlabel =DD dataset for LB5 listing, /* Label to be applied to the DD dataset  */
   splitchar      =~,         /* Split character */
   computebeforepagelines=TRTMNT $local. : &g_trtgrp,   /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   computebeforepagevars=&g_trtcd, /* Names of variables that define the sort order for  Compute Before Page lines */
   columns        =&g_trtcd &g_trtgrp &g_centid &g_subjid st_lb_cs5 st_lb_asr5 lbtest visitnum visit lbdt st_lb_da5 ('_Converted Data_' lbstresn normrng) ('Flag[1]' lbnrcd lbcccd), /* Columns to be included in the listing (plus spanned headers)  */
   abnormaltype   =CC,        /* type of abnomalities - NR: normal range, CC: clinical concern or BL: change from baseline*/
   abnormalcds    =%str("H" "L"), /* A list of abnormal values of normal range (clinical concern) indicator code */
   rangetype      =NR,        /* Range values displayed - NR: normal range, CC: clinical concern or BL for change from baseline range */
   ordervars      =&g_trtcd &g_trtgrp &g_centid &g_subjid st_lb_cs5 st_lb_asr5 lbtest visitnum visit lbdt, /*  Order variables  */
   sharecolvars   =,          /* Order variables that share print space */
   sharecolvarsindent=2,      /* Indentation factor */
   linevars       =,          /* Order variables printed with LINE statement  */
   descending     =,          /* Descending ORDERVARS */
   orderformatted =,          /* ORDER=FORMATTED variables */
   orderfreq      =,          /* ORDER=FREQ variables */
   orderdata      =,          /* ORDER=DATA variables */
   noprintvars    =&g_trtcd &g_trtgrp &g_centid &g_subjid visitnum lbdt,  /* No print variables, used to order the display */
   byvars         =,          /* By variables */
   flowvars       =st_lb_cs5 st_lb_asr5 lbtest visit st_lb_da5 normrng lbnrcd lbcccd, /* Variables with flow option */
   widths         =,          /* Column widths */
   defaultwidths  =&g_trtgrp 90 st_lb_cs5 7 st_lb_asr5 7 lbtest 16 visit 10 st_lb_da5 13 lbstresn 7 normrng 15 lbnrcd 4 lbcccd 2, /* List of default column widths */
   skipvars       =lbtest,    /*  Variables whose change in value causes the display to skip a line */
   pagevars       =,          /* Variables whose change in value causes the display to continue on a new page */
   idvars         =,          /* Variables to appear on each page of the report */
   centrevars     =,          /* Centre justify variables */
   leftvars       =,          /* Left justify variables */ 
   rightvars      =,          /* Right justify variables */
   colspacing     =1,         /* Value for between-column spacing        */
   varspacing     =,          /* Column spacing for individual variables */
   formats        =,          /* Format specification (valid SAS syntax) */
   labels         =,          /* Label definitions (var="var label")     */
   break1         =,          /* Break statements */
   break2         =,          /* Break statements */
   break3         =,          /* Break statements */
   break4         =,          /* Break statements */
   break5         =,          /* Break statements */
   proptions      =headline,  /* PROC REPORT statement options                 */
   nowidowvar     =           /* List of variables whose values must be kept together on a page */
   );
   
   %*** echo macro parameters to log file below ***;
  
   %LOCAL MacroVersion;
   %LET MacroVersion = 1;
  
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
   
   %LOCAL l_high
          l_low
          l_workdata
          l_normrng
          l_cdvar
          l_label
		  l_hilen
		  l_lolen
		  l_rnglabel
          ;
 
   %LET l_prefix=l_tdlb5;
   %LET l_normrng=normrng;
   
   %***--------------------------------------------------------------------***;
   %***- Check parameters                                                 -***;   
   %***--------------------------------------------------------------------***;
   %IF %nrbquote(&G_ANALY_DISP) EQ D %THEN %GOTO DISPLAYIT;

   %LET abnormaltype=%qupcase(&abnormaltype);
   %LET rangetype=%qupcase(&rangetype);

   %IF ( %nrbquote(&abnormaltype) NE NR ) AND
       ( %nrbquote(&abnormaltype) NE CC ) AND 
       ( %nrbquote(&abnormaltype) NE BL ) %THEN %DO;       
       %PUT %str(RTERR)OR: &sysmacroname: value of parameter ABNORMALTYPE is invalid;                     
       %PUT %str(RTERR)OR: &sysmacroname: the valid value should be NR, CC or BL;
       %GOTO macerr;
   %END;

   %IF ( %nrbquote(&rangetype) NE NR ) AND
       ( %nrbquote(&rangetype) NE CC ) AND 
       ( %nrbquote(&rangetype) NE BL ) %THEN %DO;       
       %PUT %str(RTERR)OR: &sysmacroname: value of parameter RANGETYPE is invalid;                     
       %PUT %str(RTERR)OR: &sysmacroname: the valid value should be NR, CC or BL;
       %GOTO macerr;
   %END;
 
   %IF %nrbquote(&abnormaltype) EQ NR %THEN %DO;
      %LET l_cdvar=lbnrcd;
   %END;
   %ELSE %IF %nrbquote(&abnormaltype) EQ CC %THEN %DO;
      %LET l_cdvar=lbcccd;
   %END;
   %ELSE %DO;
      %LET l_cdvar=lbchgcd;
   %END;
 
   %IF %nrbquote(&rangetype) EQ NR %THEN %DO;
      %LET l_high=lbstnrhi;
      %LET l_low=lbstnrlo;
      %LET l_rnglabel=Normal Range;
   %END;
   %ELSE %IF %nrbquote(&rangetype) EQ CC %THEN %DO;
      %LET l_high=lbstcchi;
      %LET l_low=lbstcclo;
      %LET l_rnglabel=Clinical Concern Range;
   %END;   
   %ELSE %DO;
      %LET l_high=lbchghi;
      %LET l_low=lbchglo;
      %LET l_rnglabel=Change from Baseline Range;
   %END;
 
   %LET l_workdata=&dsetin;

   %IF %nrquote(%tu_chkvarsexist(&l_workdata, &l_high &l_low)) NE  %THEN %DO;   
       %PUT %str(RTERR)OR: &sysmacroname: Variable &l_high and/or &l_low are not in input dataset &l_workdata.; 
       %PUT %str(RTERR)OR: &sysmacroname: They are required while ABNORMALTYPE equals &abnormaltype;
       %GOTO macerr;      
   %END;

   %IF &G_DEBUG GT 0 %THEN %DO;
      DATA &l_prefix.debug;
         SET &L_WORKDATA ;
         if &g_subjid=7534;
      RUN;
      
      %LET l_workdata=&l_prefix.debug;   
   %END;

   %***---------------------------------------------------------------------***;
   %***- Processing input data set                                         -***; 
   %***---------------------------------------------------------------------***;  

   %IF %nrbquote(&l_workdata) NE %THEN %DO;            
      
      %IF %tu_nobs(&l_workdata) GT 0 %THEN %DO;

         %***---------------------------------------------------------------***; 
         %***- Subset input data set. Only subject with abnormal lab flag  -***;
		 %***- will be kept                                                -***; 
         %***---------------------------------------------------------------***; 
         %IF %nrquote(%upcase(&abnormalcds)) NE %THEN %DO;

            %IF %tu_chkvarsexist(&l_workdata, &l_cdvar) NE %THEN %DO;   
               %PUT %str(RTERR)OR: &sysmacroname: Variable &l_cdvar is not in input dataset &l_workdata.; 
               %PUT %str(RTERR)OR: &sysmacroname: It is required while ABNORMALTYPE equals &abnormaltype;
               %GOTO macerr;      
            %END;
             
            PROC SORT DATA=&l_workdata OUT=&l_prefix.sortdata;
               BY &g_centid &g_subjid;
            RUN;
            
            %LET l_workdata=&l_prefix.sortdata;
                                                                   
            PROC SORT DATA=&l_workdata.(WHERE=( &l_cdvar in (%unquote(&abnormalcds)) ))
                 OUT=&l_prefix.popdata(KEEP=&g_subjid &g_centid) NODUPKEY;
               BY &g_centid &g_subjid;
            RUN;

            %IF &SYSERR GT 0 %THEN %DO;
               %PUT %str(RTERR)OR: &sysmacroname: value of parameter NORMALCDVALUE cause SAS error(s);
               %GOTO macerr;
            %END;           

            DATA &l_prefix.subdata;
               MERGE &l_workdata
                     &l_prefix.popdata(IN=_IN_);
               BY &g_centid &g_subjid;     
               IF _IN_;
            RUN;   
            
            %LET l_workdata=&l_prefix.subdata;
            
            %IF %tu_nobs(&l_workdata.) LT 0 %THEN %GOTO displayit;
            %IF %tu_nobs(&l_workdata.) EQ 0 %THEN %DO;
                 
                DATA &l_prefix.lab1;
                   SET &l_workdata;
                   LENGTH &l_normrng $20;
                   IF _N_ LT 0;
                RUN;
                
                %LET l_workdata=&l_prefix.lab1;
                %GOTO displayit;
                
            %END;
                
         %END;

         %***---------------------------------------------------------------***;     
         %***- Combine lbtest and lbstunit together                        -***;
		 %***---------------------------------------------------------------***; 

         %IF %nrquote(%tu_chkvarsexist(&l_workdata, lbtest lbstunit)) EQ %THEN %DO;
         
            DATA _NULL_;   
               LENGTH tt_sthi 8 tt_stlo $200;            
               SET &l_workdata. (KEEP=lbtest lbstunit);
               tt_sthi=vlength(lbtest) + vlength(lbstunit) +3;
               tt_stho=trim(left(vlabel(lbtest))) ||"&splitchar.("|| trim(left(vlabel(lbstunit)))||")";
               
               CALL SYMPUT('l_vlen', tt_sthi);
               CALL SYMPUT('l_label', trim(left(tt_stho)));
            RUN;
            
            DATA &l_prefix.lab;
               LENGTH lbtest $&l_vlen ;
               SET &l_workdata;
               LABEL lbtest="&l_label";

			   IF lbstunit NE "" THEN
                  lbtest=trim(left(lbtest))||" ("||trim(left(lbstunit))||")";
            RUN;   
            
            %LET l_workdata=&l_prefix.lab;
               
         %END; 

		 %***---------------------------------------------------------------***; 
         %***- Combine lbstnrhi and lbstnrhi together                      -***;
		 %***---------------------------------------------------------------***;

         %***- Get the length of the combined field and the dash position -***;
         DATA _NULL_;
            SET &l_workdata. (KEEP=&l_high &l_low) end=_end_;
            RETAIN tt_lbstlo tt_lbsthi 0;
               
            IF ( VTYPE(&l_high) EQ 'N' ) AND ( vformat(&l_high) NE "" )  THEN
               tt_lbsthi=max(tt_lbsthi, length(trim(left(putn(&l_high, vformat(&l_high))))));
            ELSE 
               tt_lbsthi=max(tt_lbsthi, length(trim(left(&l_high))));
                  
            IF ( VTYPE(&l_low) EQ 'N' ) AND ( vformat(&l_low) NE "" )  THEN
               tt_lbstlo=max(tt_lbstlo, length(trim(left(putn(&l_low, vformat(&l_low))))));
            ELSE 
               tt_lbstlo=max(tt_lbstlo, length(trim(left(&l_low))));     
                
            IF _END_ THEN DO;
               CALL SYMPUT('l_hilen', tt_lbsthi);
			   CALL SYMPUT('l_lolen', tt_lbstlo);
            END; 
         RUN;                   
                            
         %***- Combine variable lbstnrlo and lbstnrhi -***;                  
         DATA &l_prefix.lab1;
            LENGTH &l_normrng $%eval(&l_hilen + &l_lolen + 3) ;
            SET &l_workdata;
            LABEL &l_normrng="&l_rnglabel";

            IF ( VTYPE(&l_low) EQ 'N' ) AND ( vformat(&l_low) NE "" )  THEN
               substr(&l_normrng, &l_lolen - length(trim(left(putn(&l_low, vformat(&l_low))))) + 1)
                  =trim(left(putn(&l_low, vformat(&l_low))));
            ELSE 
               substr(&l_normrng, &l_lolen - length(trim(left(&l_low))) + 1)
                  =trim(left(&l_low));           

			substr(&l_normrng, &l_lolen + 2, 1)="-";

            IF ( VTYPE(&l_high) EQ 'N' ) AND ( vformat(&l_high) NE "" )  THEN
               substr(&l_normrng, &l_lolen + 4)=trim(left(putn(&l_high, vformat(&l_high))));
            ELSE 
               substr(&l_normrng, &l_lolen + 4)=trim(left(&l_high));
                  
         RUN;
            
         %LET l_workdata=&l_prefix.lab1;
        
      %END;        
      %ELSE %DO;
          %IF %tu_nobs(&l_workdata.) LT 0 %THEN %GOTO displayit;
          
          DATA &l_prefix.lab1;
             SET &l_workdata;
             LENGTH &l_normrng $20;
             IF _N_ LT 0;
          RUN;
          
          %LET l_workdata=&l_prefix.lab1;
      %END;           
      
   %END;   
  
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %DISPLAYIT:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   
   %***--------------------------------------------------------------------***;
   %***- Pass everything to tu_list                                       -***;
   %***--------------------------------------------------------------------***;

   %tu_list(
      dsetin                 =&l_workdata,
      stackvar1              =&stackvar1,
      stackvar2              =&stackvar2,
      stackvar3              =&stackvar3,
      stackvar4              =&stackvar4,        
      stackvar5              =&stackvar5,         
      stackvar6              =&stackvar6,        
      stackvar7              =&stackvar7,        
      stackvar8              =&stackvar8,         
      stackvar9              =&stackvar9,         
      stackvar10             =&stackvar10,        
      stackvar11             =&stackvar11,        
      stackvar12             =&stackvar12,         
      stackvar13             =&stackvar13,         
      stackvar14             =&stackvar14,        
      stackvar15             =&stackvar15,        
      varlabelstyle          =&varlabelstyle,   
      dddatasetlabel         =&dddatasetlabel,
      splitchar              =&splitchar,         
      computebeforepagelines =&computebeforepagelines,
      computebeforepagevars  =&computebeforepagevars,
      columns                =&columns,
      ordervars              =&ordervars,
      sharecolvars           =&sharecolvars,
      sharecolvarsindent     =&sharecolvarsindent,
      linevars               =&linevars,         
      descending             =&descending,         
      orderformatted         =&orderformatted,          
      orderfreq              =&orderfreq,         
      orderdata              =&orderdata,         
      noprintvars            =&noprintvars,
      byvars                 =&byvars,          
      flowvars               =&flowvars,    
      widths                 =&widths,         
      pagevars               =&pagevars,          
      idvars                 =&idvars,          
      centrevars             =&centrevars,          
      leftvars               =&leftvars,         
      rightvars              =&rightvars,    
      colspacing             =&colspacing, 
      varspacing             =&varspacing,          
      formats                =&formats,          
      labels                 =&labels,          
      defaultwidths          =&defaultwidths,
      skipvars               =&skipvars,
      break1                 =&break1,          
      break2                 =&break2,          
      break3                 =&break3,          
      break4                 =&break4,         
      break5                 =&break5,          
      proptions              =&proptions ,                
      nowidowvar             =&nowidowvar,          
      display                =y,
      getdatayn              =y,
      labelvarsyn            =y,
      overallsummary         =n       
      )
      
   %GOTO endmac;
       
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %MACERR:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %LET g_abort=1;
      
   %PUT;
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT %str(RTNO)TE: &sysmacroname completed with error(s);
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT;      
      
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %ENDMAC:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;     
    
   %***---------------------------------------------------------------------***;
   %***- Call tu_tidyup to clear temporary data set and fields.            -***;
   %***---------------------------------------------------------------------***;
                                        
   %tu_tidyup(      
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      )
  
%mend td_lb5;


  
