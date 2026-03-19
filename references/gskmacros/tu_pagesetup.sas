/*--------------------------------------------------------------------------+
| Macro Name    : tu_pagesetup.sas
|
| Macro Version : 3
|
| SAS version   : SAS v8.2
|
| Created By    : Shan Lee
|
| Date          : 20-Jun-2003
|
| Macro Purpose : Define page attributes within the SAS environment.
|                 Creates an IDSL-compliant 9" x 6" display area.
|                 Define an appropriate qualifier for text output files.
|                 Save the qualifier in a global macro variable.
|
| Macro Design  : Procedure style.
|
| Input Parameters :
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| DEVICE              Specifies the device driver to which SAS/GRAPH    PDF
|                     sends. It is only useful when &g_dslytyp equals
|                     F.
|                     Valid Value:
|                     Blank or A valid SAS/GRAPH device. If &MODE 
|                     equals PRIMARY, it can only equals PDF or begin 
|                     with PS.
|
| FONT                Specify the font for all text on the graphics     Swiss
|                     output.Both FTEXT and FTITLE GOPTION will be
|                     set It is only useful when &g_dslytyp equals F.
|                     Valid Value:
|                     Blank or a valid SAS/GRAPH font
|
| GOPTIONS            Specify SAS graph options. It is only useful      (blank)
|                     when &g_dslytyp equals F.
|                     Valid Value:
|                     Blank or valid SAS/GRAPH options
|
| LSMVAR              Name of the global macro variable to hold the     G_LS
|                     line size value
|
| MODE                Specify if predefined GRAPH options will          PRIMARY
|                     overwrite the options given in parameter
|                     GOPTIONS. If equals PRIMARY, the predefined
|                     options will be overwritten. If equals
|                     SECONDARY, the value given in parameter GOPTIONS
|                     will overwrite the predefined options. The
|                     predefined options are options defined according
|                     to values of parameter DEVICE, FONT and PTSIZE.
|                     It is only useful when &g_dslytyp equals F.
|                     Valid Value:
|                     P, PRIMARY, S or SECONDARY
|
| PSMVAR              Name of the global macro variable to hold the     G_PS
|                     page size value
|
| PTSIZE              Species the height in point of the text in the    10
|                     graphics output. Both HTITLE and HTEXT GOPTION
|                     will be setIt is only useful when &g_dslytyp
|                     equals F.
|                     Valid Value:
|                     Blank or a numeric value
|
| RESET               Specify a value of SAS graph option RESET. It is  (blank)
|                     only useful when &g_dslytyp equals F.
|                     Valid Value:
|                     Blank or a valid value for GRAPH option RESET
|
| TFQMVAR             Name of the file qualifier global macro variable  G_TEXTFILESFX
| ----------------------------------------------------------------------------------------
| Output:
|
|  The unit shall set appropriate global macro variable values.
|
| Global macro variables created: none
|
|
| ----------------------------------------------------------------------------------------
| Macros called :
|  (@)tr_putlocals
|  (@)tu_putglobals
|  (@)tu_abort
|
|
| Example:
| %tu_pagesetup(lsmvar = g_ls, psmvar = g_ps, tfqmvar = g_textfilesfx)
|
|
| ----------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :             Shan Lee
| Date of Modification :    09-July-2003
| New Version Number :      1/2
| Modification ID :         SL001
| Reason For Modification : Amended after first round of unit testing.
| ----------------------------------------------------------------------------------------
| Modified By :             Shan Lee
| Date of Modification :    19-February-2004
| New Version Number :      2/1
| Modification ID :         SL002
| Reason For Modification : Modify range of fontsize, pagesize, and linesize
|                           options as specified in change control form
|                           HRT0003.
| ----------------------------------------------------------------------------------------
| Modified By :             Shan Lee
| Date of Modification :    26-March-2004
| New Version Number :      2/2
| Modification ID :         SL003
| Reason For Modification : Incorporate feedback from source code review.
| ----------------------------------------------------------------------------------------
| Modified By :             Shan Lee
| Date of Modification :    25-August-2004
| New Version Number :      2/3
| Modification ID :         SL004
| Reason For Modification : Modify so that the macro will issue an (RTN)OTE,
|                           rather than an (RTE)RROR, if the fontsize
|                           parameter does not imply ASCII output. This change
|                           is required because the HARP Application has been
|                           updated to allow processing of additional supported
|                           file formats, as detailed in change control form
|                           HRT0049.
| ----------------------------------------------------------------------------------------
| Modified By :             Yongwei Wang
| Date of Modification :    21-Oct-2004
| New Version Number :      3/1
| Modification ID :         YW001
| Reason For Modification : The modifications are required for the PK component of the HARP
|                           Reporting Tools in Release 1.2 (Change request HRT0050).
|                           Following changes have been made:
|                           1. Added six parameters: DEVICE, FONT, GOPTIONS, MODE, PTSIZE
|                              and RESET.
|                           2. Added parameter check for new parameters.
|                           3. Added processes to setup GOPTIONS.
+----------------------------------------------------------------------------------------*/
%macro tu_pagesetup(
   DEVICE    =PDF,           /* the device driver to which SAS/GRAPH sends */
   FONT      =Swiss,         /* font for all text on the graphics output */
   GOPTIONS  =,              /* SAS/GRAPH options */
   LSMVAR    =G_LS,          /* Name of macro var for line size */
   MODE      =PRIMARY,       /* Primary or secondary mode. Predefined GRAPH options will overwrite the options given in parameter GOPTIONS */
   PSMVAR    =G_PS,          /* Name of macro var for page size */
   PTSIZE    =10,            /* the height in point of the text in the graphics output */
   RESET     =,              /* Value of SAS graph option RESET */
   TFQMVAR   =G_TEXTFILESFX, /* Name of the file qualifier macro var */
   );
/*
/ Echo values of parameters and global macro variables to the log.
/----------------------------------------------------------------------------*/
%local MacroVersion;
%let MacroVersion = 3;
%include "&g_refdata/tr_putlocals.sas";
%tu_putglobals(varsin = g_fontsize g_dsplytyp)
/*
/ PARAMETER VALIDATION
/----------------------------------------------------------------------------*/
/*
/ Check the parameters - none should be blank.
/----------------------------------------------------------------------------*/
%if &lsmvar eq %then
%do;
  %put %str(RTE)RROR: TU_PAGESETUP: The parameter LSMVAR is required;
  %let g_abort = 1;                                                 /* SL003 */
%end;
%if &psmvar eq %then
%do;
  %put %str(RTE)RROR: TU_PAGESETUP: The parameter PSMVAR is required;
  %let g_abort = 1;                                                 /* SL003 */
%end;
%if &tfqmvar eq %then
%do;
  %put %str(RTE)RROR: TU_PAGESETUP: The parameter TFQMVAR is required;
  %let g_abort = 1;                                                 /* SL003 */
%end;
%let mode=%qupcase(&mode);
/* YW001: parameter validation for &mode and &ptsize */
%if &mode eq PRIMARY %then %let mode=P;
%else %if &mode eq SECONDARY %then %let mode=S;
%if ( &mode ne P ) and (&mode ne S) %then
%do;
  %put %str(RTE)RROR: TU_PAGESETUP: Value of required parameter MODE (MODE=&MODE) is invalid. Valid value should be P, PRIMARY, S, or SECONDARY.;
  %let g_abort = 1;
%end;
%if ( %nrbquote(&ptsize) ne ) and ( %qupcase(&g_dsplytyp) eq F ) %then
%do;
   %if %datatyp(&ptsize) ne NUMERIC %then
   %do;
      %put %str(RTE)RROR: TU_PAGESETUP: Value of PTSIZE (PTSIZE=&ptsize) is invalid. Valid value should be a numeric.;
      %let g_abort = 1;
   %end;
%end; /* end-if on ( %nrbquote(&ptsize) ne ) and ( %qupcase(&g_dsplytyp) eq F ) */ 
%if ( %qupcase(&g_dsplytyp) eq F ) and ( &mode eq P ) %then
%do;
   %if ( %qupcase(&device) ne PDF ) and ( %qsubstr(%qupcase(&device), 1, 2) ne PS ) %then
   %do;
      %put %str(RTE)RROR: TU_PAGESETUP: Value of DEVICE (DEVICE=&DEVICE) is invalid. Valid value shoud be PDF or begin with PS when MODE=PRIMARY;      
      %let g_abort = 1;      
   %end; 
%end;
/*
/ Tu_abort is not called until all the parameter validation checks have
/ been executed, so if parameter validation fails due to more than one check,
/ then all the appropriate messages will be displayed in the log before the
/ program terminates.                                                  SL003
/----------------------------------------------------------------------------*/
%if &g_abort %then
%do;
  %tu_abort()
%end;
/*
/ Declare local macro variables that will be used in this macro.      SL004
/----------------------------------------------------------------------------*/
%local ascii;
/*
/ Check upcase(G_FONTSIZE).
/ ASCII output is implied if upcase(G_FONTSIZE) is one of the
/ following values: P08, P09, P10, P11, P12, L08, L09, L10, L11, L12, 10, 12.
/ If non-ASCII output is implied, then:
/
/ 1. Issue an (RTN)OTE stating that no further action will be taken because
/    a non-ASCII file type has been chosen.
/ 2. Set the file qualifier macro variable (G_TEXTFILESFX) to the value of
/    fontsize.
/ 3. Set linesize and pagesize macro variables to nominal values (linesize 108,
/    pagesize 43).
/
/ After the above steps, execution will jump to the end of the macro.
/                                                        SL002 SL003 SL004
/----------------------------------------------------------------------------*/
%let ascii = 0;
data _null_;
  if upcase("&g_fontsize") in ("P08" "P09" "P10" "P11" "P12" "L08" "L09" "L10"
                               "L11" "L12" "10" "12") then
  do;
    call symput ("ascii", "1");
  end;
run;
/* YW001: Added the condition %qupcase(&g_dsplytyp) ne F */
%if not &ascii %then %do;
   %let &tfqmvar = &g_fontsize;
   %let &lsmvar = 108;
   %let &psmvar = 43;
   %if %qupcase(&g_dsplytyp) ne F %then
   %do;
      %put %str(RTN)OTE: TU_PAGESETUP: G_FONTSIZE implies non-ASCII output.;
      %put %str(RTN)OTE: TU_PAGESETUP: &tfqmvar will be set to &g_fontsize;
      %put %str(RTN)OTE: TU_PAGESETUP: The linesize and pagesize macro variables will be set to nominal values of 108 and 43 respectively.;
      %put %str(RTN)OTE: TU_PAGESETUP: No further action will be taken by tu_pagesetup.;
      %goto EXIT;
   %end;
%end; /* end-if on not &ascii */
/*
/ NORMAL PROCESSING.
/----------------------------------------------------------------------------*/
/*
/ If G_FONTSIZE is 10 or 12, then set the global macro variable specified
/ by TFQMVAR to L10 or L12 respectively, otherwise, set the global macro
/ variable specified by TFQMVAR to the same value as G_FONTSIZE. SL002 SL003
/----------------------------------------------------------------------------*/
%if (&g_fontsize eq 10) or (&g_fontsize eq 12) %then
%do;
  %let &tfqmvar = L&g_fontsize;
%end;
%else
%do;
  %let &tfqmvar = &g_fontsize;
%end;
/*
/ Assign values to the line size global macro variable and the page size
/ global macro variable, based on the value of the global macro variable
/ specified by TFQMVAR and a knowledge of which linesizes and pagesizes
/ need to be used for each of the possible file extensions.          SL002
/----------------------------------------------------------------------------*/
data _null_;
  /*
  / The arrays lsmvar and psmvar store the linesizes and pagesizes that
  / should be used with each of the corresponding file extensions specified
  / in the array tfqmvar.
  /--------------------------------------------------------------------------*/
  array tfqmvar[10] $ _temporary_ ("P08" "P09" "P10" "P11" "P12"
                                   "L08" "L09" "L10" "L11" "L12");
  array lsmvar[10] _temporary_  (90    80    72    65    64
                                 135   120   108   98    90);
  array psmvar[10] _temporary_  (83    74    67    61    56
                                 54    48    43    39    36);
  do n = 1 to dim(tfqmvar);
    if upcase("&&&tfqmvar") eq tfqmvar[n] then
    do;
      call symput("&lsmvar", trim(left(put(lsmvar[n], 6.0))));
      call symput("&psmvar", trim(left(put(psmvar[n], 6.0))));
    end;
  end; /* DO loop */
run;
/*
/ YW001: Setup GOPTIONS for &G_DSPLYTYP equals F
/----------------------------------------------------------------------------*/
%if %qupcase(&g_dsplytyp) eq F %then
%do;
   %if &mode eq P %then
   %do;
      %if %nrbquote(&reset.&goptions.&font.&ptsize.&device) ne %then
      %do;
   	     GOPTIONS
            %if %nrbquote(&reset) ne %then
            %do;
               reset=&reset
            %end;
            &goptions
            %if %nrbquote(&font) ne %then
            %do;
               ftitle=&font ftext=&font
            %end;
            %if %nrbquote(&ptsize) ne %then
            %do;
               htitle=&ptsize.pt htext=&ptsize.pt
            %end;
            %if %nrbquote(&device) ne %then
            %do;
               device=&device
            %end;
            ;
      %end; /* end-if on %nrbquote(&reset.&goptions.&font.&ptsize) ne */
      %if ( %qupcase(&device) eq PDF ) or ( %qsubstr(%qupcase(&device), 1, 2) eq PS ) %then
      %do;
         GOPTIONS vsize=6.0 in hsize=9.25 in horigin=0.88 in vorigin=1.25 in
                  rotate=landscape xmax=11 in ymax=8.5 in;
      %end;
   %end;
   %else %do;
      %if %nrbquote(&reset.&font.&ptsize.&device) ne %then
      %do;
     	 GOPTIONS
            %if %nrbquote(&reset) ne %then
            %do;
               reset=&reset
            %end;
            %if %nrbquote(&font) ne %then
            %do;
               ftitle=&font ftext=&font
            %end;
            %if %nrbquote(&ptsize) ne %then
            %do;
               htitle=&ptsize.pt htext=&ptsize.pt
            %end;
            %if %nrbquote(&device) ne %then
            %do;
               device=&device
            %end;
           ;
      %end; /* end-if on %nrbquote(&reset.&font.&ptsize) ne */
      %if ( %qupcase(&device) eq PDF ) or ( %qsubstr(%qupcase(&device), 1, 2) eq PS ) %then
      %do;
         GOPTIONS vsize=6.0 in hsize=9.25 in horigin=0.88 in vorigin=1.25 in
                  rotate=landscape xmax=11 in ymax=8.5 in;
      %end;
      %if %nrbquote(&goptions) ne %then
      %do;
         GOPTIONS &goptions;
      %end;
   %end; /* end-if on &mode eq P */
%end; /* end-if on %qupcase(&g_dsplytyp) eq F */
/*
/ If the check for G_FONTSIZE implies non-ASCII output, then macro execution
/ will jump to this point.                                   SL004
/----------------------------------------------------------------------------*/
%EXIT:
%mend tu_pagesetup;
