/*******************************************************************************
|
| Macro Name:      tu_sdtm_decode (copied from v2 of tu_decode)
|
| Macro Version:   3
|
| SAS Version:     8.2
|
| Created By:      Bruce Chambers (original by Mark Luff)
|
| Date:            01May2013
|
| Macro Purpose:   Decode 'CD' suffixed coded variables using SAS format catalog
|                  Change for SDTM : Only process the entries in decoderename pairs string fed in 
|                  - so that SDTM pre-adjust processing can popualte decodes earlier if needed.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                              REQ/OPT  DEFAULT
| ----------------  ---------------------------------------  -------  ----------
| DSETIN            Specifies dataset for which decoded       REQ      (Blank)
|                   variables are to be added.
|                   Valid values: valid dataset name
|
| DSETOUT           Specifies name of the output dataset      REQ      (Blank)
|                   to be created.
|                   Valid values: valid dataset name
|
| DSPLAN            Path and file name of the HARP A&R        OPT      (Blank)
|                   dataset metadata.  This will define 
|                   the sort order desired. If this is
|                   specified, the HARP A&R dataset plan
|                   will be used to determine the formats   
|                   used in the decode. 
|                   NOTE: If DSPLAN is specified, then 
|                   FORMATNAMESDSET should be left blank. 
|
| FORMATNAMESDSET   Name of a dataset which contains          OPT      (Blank)
|                   VAR_NM (a name of a coded variable) 
|                   and FORMAT_NM (the name of a format to
|                   produce the decode). If this is specified,
|                   the FORMATNAMESDSET will be used to determine
|                   the formats to use in the decode.
|                   NOTE: If FORMATNAMESDSET is specified
|                   then DSPLAN	 should be left blank.
|
| DECODEPAIRS       Specifies code and decode variable pairs. OPT      (Blank)           
|                   The first variable in each pair will                         
|                   contain the code, which is used to derive                        
|                   decode variables, by applying format to it,  
|                   and the other will contain decode variable
|                   Valid values:                                                       
|                   Blank                                                               
|                   a list of SAS variable names in pairs 
|
| DECODERENAME      By default, a coded variable named        OPT      (Blank)
|                   ZZZcd will produce a decoded variable
|                   ZZZ.  This can be changed by using 
|                   this parameter, i.e. 
|                   decoderename=zzz=abc_text  will create
|                   the decode of ZZZcd in a variable 
|                   named ABC_TEXT.
| -----------------------------------------------------------------------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Input dataset specified by parameter
|
| &FORMATNAMESDSET   Opt      Optional dataset specified by parameter with
|                             variables:
|
|                              NAME       DESCRIPTION
|                              ---------  -------------------------------------
|                              VAR_NM     Variable name   (CD suffix)
|                              FORMAT_NM  SAS format name ($ prefix, e.g. $FMT)
| -----------------------------------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Output dataset specified by parameter.
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_words
|(@) tu_getformatnames
|(@) tu_tidyup
|
| Example:
|    %tu_decode(
|         dsetin          = _ae1,
|         dsetout         = _ae2,
|         dsplan          = &R_ARDATA/ae_spec.txt,
|         decoderename    = aeactr=aeacttrt aetxhv=aetoxhiv
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang (YW62951)
| Date of Modification:      07-Nov-2007
| New version/draft number:  2/1
| Modification ID:           YW001
| Reason For Modification:   1. Make data set options work for &DSETIN and &DSETOUT
|                               - HRT0184
|                            2. Added a new parameter DECODEPAIRS. The parameter
|                               will allow user to specify code and decode variables 
|                               for igregular code and decode variables - HRT0188
|
| Modified By:               Bruce Chambers
| Date of Modification:      22May2013
| New version/draft number:  3/1
| Modification ID:           BJC001
| Reason For Modification:   To not re-decode where the decode pair already exists
*******************************************************************************/
%macro tu_sdtm_decode (
     dsetin          = ,   /* Input dataset name */
     dsetout         = ,   /* Output dataset name */
     dsplan          = ,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     formatnamesdset = ,   /* Format names dataset name */
     decodepairs     = ,   /* a list of pairs of code and deocde variables with nonstandard names */
     decoderename    =     /* List of renames for decoded variables */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin          = %nrbquote(&dsetin);
 %let dsetout         = %nrbquote(&dsetout);
 %let dsplan          = %nrbquote(&dsplan);
 %let formatnamesdset = %nrbquote(&formatnamesdset);
 %let decoderename    = %nrbquote(&decoderename);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;                        /* end-if on &dsetin parameter not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;                       /* end-if on &dsetout parameter not specified. */

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;                          /* end-if on &dsetin dataset does not exist  */

 %if &formatnamesdset ne and %sysfunc(exist(%qscan(&formatnamesdset, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: The dataset FORMATNAMESDSET(=&formatnamesdset) does not exist.;
    %let g_abort=1;
 %end;                /* end-if on &formatnamesdset dataset does not exist.  */

 %if ( &formatnamesdset ne )  and ( &dsplan ne ) %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: Only one of FORMATNAMESDSET or DSPLAN should be specified.;
    %let g_abort=1;
 %end;            /* end-if on both parameters:  &formatnamesdset and &dsplan, */
                  /* passed as non-blanks.                                     */

 %if ( &formatnamesdset eq ) and ( &dsplan eq  ) %then
 %do;
    %put %str(RTE)RROR: TU_DECODE: One of FORMATNAMESDSET or DSPLAN should be specified.;
    %let g_abort=1;
 %end;            /* end-if on both parameters: &formatnamesdset and &dsplan, */
                  /* passed as blanks.                                        */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: TU_DECODE: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;             /* end-if on both parameters &dsetin and &dsetout */
                   /* passed with same values.  */

 /*
 / Define local macro variables
 /----------------------------------------------------------------------------*/

 %local prefix l_fmtnames l_decoderename l_i l_nrenames l_nparis l_decodes l_codes;
 %let prefix = _decode;   /* Root name for temporary work datasets */
 %let l_decoderename=;
 %let l_npairs=0;
 %let l_nrenames=0;
 %let l_codes=;
 %let l_decodes=;
 
 /*
 / Parameter validation for DECODERENAME and DECODEPAIRS 
 /----------------------------------------------------------------------------*/
 
 %if &decoderename ne %then
 %do;
    %let l_decoderename=%sysfunc(translate(&decoderename, %str( ), =));
    %let l_nrenames=%tu_words(&l_decoderename);
    %if %sysfunc(mod(&l_nrenames, 2)) ne 0 %then
    %do;    
       %put %str(RTN)OTE: &sysmacroname: DECODERENAME(=&decoderename) is not in format of a list of var1=var2.;
    %end; 
 %end;
 
 %if %nrbquote(&decodepairs) ne %then
 %do;
    %let l_npairs=%tu_words(&decodepairs);
    %if %sysfunc(mod(&l_npairs, 2)) ne 0 %then
    %do;    
       %put %str(RTN)OTE: &sysmacroname: DECODEPAIRS(=&decodepairs) is not in format of a list of code_var decode_var.;
    %end;        
 %end;
 
 /*
 / Parameter validation for DECODERENAME and DECODEPAIRS 
 /----------------------------------------------------------------------------*/
 
 %do l_i=0 %to %eval(&l_nrenames./2 - 1);
    %let l_codes=%scan(&l_decoderename, %eval(2*&l_i + 1))cd &l_codes;
    %let l_decodes=%scan(&l_decoderename, %eval(2*&l_i + 2)) &l_decodes; 
 %end;
 
 %do l_i=0 %to %eval(&l_npairs/2 - 1);
    %let l_codes=%scan(&decodepairs, %eval(2*&l_i + 1)) &l_codes;
    %let l_decodes=%scan(&decodepairs, %eval(2*&l_i + 2)) &l_decodes; 
 %end;
 
 %let l_npairs=%eval((&l_npairs + &l_nrenames)/2);    
 
 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / Get format names dataset.
 / Either the user specified a dataset which contains var_nm and format_nm, or
 / the user specified the HARP dataset plan for the A&R dataset which will be
 / used to build a dataset containing var_nm and format_nm.
 /----------------------------------------------------------------------------*/

 %if &formatnamesdset ne %then
 %do;
    %let l_fmtnames = &formatnamesdset;
 %end;       /* end-if on &formatnamesdset parameter specified as non-blank. */

 %else
 %do;
    %let l_fmtnames = &prefix._formatnames;

    %tu_getformatnames (
         dsplan          = &dsplan,
         formatnamesdset = &l_fmtnames
    );
 %end;       /* end-if on &formatnamesdset parameter specified as blank.  */

 /*
 / Match up the variable names of the codes and the decode formats.
 /----------------------------------------------------------------------------*/

 proc contents data=%unquote(&dsetin) noprint out=&prefix._vnames(keep=name);
 run;

 data &prefix._cdnames;
  set &prefix._vnames;
    length decode $32;
    if length(name) ge 2;
    %do l_i=1 %to &l_npairs;
       if compress(upcase(name)) eq compress(upcase("%scan(&l_codes, &l_i)")) then
          decode=left("%scan(&l_decodes, &l_i)");    
       else
    %end;    
	/* BJC001: SDTM change to remove  next lines so that the default decodes are not set, just the ones wanted */   
	if decode='' then delete;
 run;

 proc sql;
      create table &prefix._varFmtlist as
      select a.name, a.decode, b.format_nm
      from &prefix._cdnames as a,
           %unquote(&l_fmtnames) as b
      where upcase(a.name) = upcase(b.var_nm);
 quit;

 /*
 / Report to the log those variables that will be decoded.
 /----------------------------------------------------------------------------*/

 data _null_;
      set &prefix._varFmtlist;
      put "RTN" "OTE: TU_DECODE: Variable " name "will be decoded in " decode "using format " format_nm;
 run;

 /*
 / Create program statements to create decoded variables.
 /----------------------------------------------------------------------------*/

 filename tmp1 temp;
 data _null_;
      set &prefix._varFmtlist;
      file tmp1;
      put decode '=put(' name ',' format_nm +(-1) ');';
 run;

 /*
 / Execute statements within the files.
 /----------------------------------------------------------------------------*/

 data %unquote(&dsetout);
      set %unquote(&dsetin);
      %inc tmp1;
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_sdtm_decode;
