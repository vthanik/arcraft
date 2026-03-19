/*******************************************************************************
|
| Macro Name:      tu_decode
|
| Macro Version:   3 build 3
|
| SAS Version:     8.2
|
| Created By:      Mark Luff
|
| Date:            27-Apr-2004
|
| Macro Purpose:   Decode 'CD' suffixed coded variables using SAS format catalog
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
|
| CODEPAIRS         Specifies code and decode variable pairs. OPT      (Blank)           
|                   The first variable in each pair will                         
|                   contain the code and the second variable
|                   in each pair will contain the decode
|                   variable. The code variables will be 
|                   derived from the decode variables by
|                   applying informats to them.
|                   Valid values:                                                       
|                   Blank                                                               
|                   a list of SAS variable names in pairs 
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
|(@) tu_varattr
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
| Modified By:               Anthony J Cooper
| Date of Modification:      21-Feb-2014
| New version/draft number:  3/1
| Modification ID:           AJC001
| Reason For Modification:   Add new parameter CODEPAIRS. The parameter will
|                            allow the user to specify code and decode variables
|                            where the code variable will be derived from the
|                            decode variable. 
|
| Modified By:               Anthony J Cooper
| Date of Modification:      16-Apr-2014
| New version/draft number:  3/2
| Modification ID:           AJC002
| Reason For Modification:   Check DSETIN exists if parameter is not missing
|
| Modified By:               Anthony J Cooper
| Date of Modification:      02-May-2014
| New version/draft number:  3/3
| Modification ID:           AJC003
| Reason For Modification:   Check for CD variables for IDSL studies (using
|                            &g_datatype). Divide l_cpairs by 2. 
|
*******************************************************************************/
%macro tu_decode (
     dsetin          = ,   /* Input dataset name */
     dsetout         = ,   /* Output dataset name */
     dsplan          = ,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     formatnamesdset = ,   /* Format names dataset name */
     decodepairs     = ,   /* a list of pairs of code and decode variables with nonstandard names */
     decoderename    = ,   /* List of renames for decoded variables */
     codepairs       =     /* Paired variables code and decode for which the code variable will be derived */
        );


 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 3 build 3;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals(varsin=g_datatype) 

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
 / AJC002: Updated to check DSETIN exists if &dsetin is not missing.
 /----------------------------------------------------------------------------*/

 %if &dsetin ne and %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
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

 %local prefix l_fmtnames l_decoderename l_i l_nrenames l_nparis l_decodes l_codes l_cpairs l_ccodes l_cdecodes
        l_start_length l_label_length l_fmtsearch l_i l_thisfmt l_fmtdsetlist l_fmtdsetcontlist l_setlength;
 %let prefix = _decode;   /* Root name for temporary work datasets */
 %let l_decoderename=;
 %let l_npairs=0;
 %let l_cpairs=0;
 %let l_nrenames=0;
 %let l_codes=;
 %let l_decodes=;
 
 /*
 / Parameter validation for DECODERENAME, DECODEPAIRS and CODEPAIRS
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

 %if %nrbquote(&codepairs) ne %then
 %do;
    %let l_cpairs=%tu_words(&codepairs);
    %if %sysfunc(mod(&l_cpairs, 2)) ne 0 %then
    %do;    
       %put %str(RTN)OTE: &sysmacroname: CODEPAIRS(=&codepairs) is not in format of a list of code_var decode_var.;
    %end;        
 %end;
 
 /*
 / Process DECODERENAME, DECODEPAIRS and CODEPAIRS 
 /----------------------------------------------------------------------------*/
 
 %do l_i=0 %to %eval(&l_nrenames./2 - 1);
    %let l_codes=%scan(&l_decoderename, %eval(2*&l_i + 1))cd &l_codes;
    %let l_decodes=%scan(&l_decoderename, %eval(2*&l_i + 2)) &l_decodes; 
 %end;
 
 %do l_i=0 %to %eval(&l_npairs/2 - 1);
    %let l_codes=%scan(&decodepairs, %eval(2*&l_i + 1)) &l_codes;
    %let l_decodes=%scan(&decodepairs, %eval(2*&l_i + 2)) &l_decodes; 
 %end;

 %do l_i=0 %to %eval(&l_cpairs/2 - 1);
    %let l_ccodes=%scan(&codepairs, %eval(2*&l_i + 1)) &l_ccodes;
    %let l_cdecodes=%scan(&codepairs, %eval(2*&l_i + 2)) &l_cdecodes; 
 %end;

 
 %let l_npairs=%eval((&l_npairs + &l_nrenames)/2);    
 %let l_cpairs=%eval(&l_cpairs/2);    
 
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
 / AJC001: add ftype variable to flag code variables which will be created
 / from decode variables via informat.
 / AJC003: only look for CD variables for IDSL studies (using &g_datatype).
 /----------------------------------------------------------------------------*/

 proc contents data=%unquote(&dsetin) noprint out=&prefix._vnames(keep=name);
 run;

 data &prefix._cdnames;
  set &prefix._vnames;
    length decode $32 ftype $5;
    decode='';
    ftype='';
    if length(name) ge 2;
    %do l_i=1 %to &l_npairs;
       if compress(upcase(name)) eq compress(upcase("%scan(&l_codes, &l_i)")) then
          decode=left("%scan(&l_decodes, &l_i)");    
       else
    %end;   

    %do l_i=1 %to &l_cpairs;
       if compress(upcase(name)) eq compress(upcase("%scan(&l_cdecodes, &l_i)")) then 
       do;
          decode=left("%scan(&l_ccodes, &l_i)");    
          ftype='infmt';
       end;
       else
    %end;  

    %if %qupcase(&g_datatype) eq IDSL %then
    %do;
       if substr(compress(reverse(upcase(name))),1,2) eq 'DC' then
          decode=substr(name,1,max(1,length(name)-2));
       else
    %end;

    delete;
 run;

 proc sql;
      create table &prefix._varFmtlist as
      select a.name, a.decode, a.ftype, b.format_nm
      from &prefix._cdnames as a,
           %unquote(&l_fmtnames) as b
      where upcase(a.name) = upcase(b.var_nm) or upcase(a.decode) = upcase(b.var_nm);
 quit;


 /*
 / Report to the log those variables that will be decoded.
 /----------------------------------------------------------------------------*/

 data _null_;
      set &prefix._varFmtlist;
      if ftype='' then
         put "RTN" "OTE: TU_DECODE: Variable " name "will be decoded in " decode "using format " format_nm;
      else if ftype='infmt' then
         put "RTN" "OTE: TU_DECODE: Variable " name "will be coded in " decode "using informat based on the format " format_nm;
 run;

 /*
 / AJC001: Search through all levels of formats to find the formats which will
 / be used to create code variables from the decodes.
 /----------------------------------------------------------------------------*/

 %let l_fmtsearch=%sysfunc(getoption(fmtsearch));
 %let l_fmtsearch=%sysfunc( translate( &l_fmtsearch, %str( ), %str(%(%) ) ) );
 %let l_fmtsearch=%sysfunc(compbl( %trim( %left(&l_fmtsearch) ) ) );
 %if %sysfunc(indexw(%qupcase(&l_fmtsearch), WORK)) eq 0 %then
    %let l_fmtsearch=WORK &l_fmtsearch;      
  
 %if &g_debug ge 1 %then
    %put %str(RTN)OTE: &sysmacroname: Searching for formats catalog in the following libraries &l_fmtsearch;
    
 %do l_i=1 %to %tu_words(&l_fmtsearch);
    
    %let l_thisfmt=%scan(&l_fmtsearch,&l_i);
        
    %if %sysfunc(exist(&l_thisfmt..formats, CATALOG)) %then 
    %do;

       %if &g_debug ge 1 %then 
          %put %str(RTN)OTE: &sysmacroname: &l_thisfmt..formats exists;
        
       proc format lib=&l_thisfmt. cntlout=&prefix._&l_thisfmt._fmts (keep=fmtname start label type);
       run;

       %let l_fmtdsetlist=&l_fmtdsetlist &prefix._&l_thisfmt._fmts;

       proc contents data=&prefix._&l_thisfmt._fmts out=&prefix._&l_thisfmt._conts (keep=name length) noprint;
       run;

       %let l_fmtdsetcontlist=&l_fmtdsetcontlist &prefix._&l_thisfmt._conts;

       data &prefix._&l_thisfmt._fmts;
            set &prefix._&l_thisfmt._fmts;
            retain level &l_i;
       run;
    
    %end; /* %if %sysfunc(exist(&l_thisfmt..formats, CATALOG)) %then %do; */
    
 %end; /* %do l_i=1 %to %tu_words(&l_fmtsearch); */

 /*
 / AJC001: Concatenate datasets created from the formats catalogs found.
 /----------------------------------------------------------------------------*/

 %if %length(&l_fmtdsetlist) gt 0 %then %do;

    /*
    / Determine maximum length of variables ready for setting together
    /-------------------------------------------------------------------------*/

    data &prefix._allconts;
         set &l_fmtdsetcontlist;
    run;

    proc sort data=&prefix._allconts;
         by name length;
    run;

    data &prefix._allconts;
         set &prefix._allconts;
         by name length;
         if last.name;
    run;

    data _null_;
         length str $32767;
         retain str 'length';
         set &prefix._allconts end = last;
         str = trim(str)||' '||trim(name)||' $'||compress(put(length,5.));
         if last then call symput("l_setlength",trim(str));
    run;

    data &prefix._allfmts0;
         &l_setlength;
         set &l_fmtdsetlist;
    run;

    /*
    / Find the first occurrence of each format within the format search path.
    /-------------------------------------------------------------------------*/

    proc sql noprint;
         create table &prefix._allfmts (drop=level) as
         select *
         from &prefix._allfmts0
         group by fmtname, type
         having level eq min(level)
         ;
    quit;

 %end; /* %if %length(&l_fmtdsetlist) gt 0 %then %do; */

 %else %do;

    /*
    / Create dataset with 0 observations if no formats were found
    /-------------------------------------------------------------------------*/

    data &prefix._allfmts;
         length fmtname $32 label $80 start $32 type $1;
         stop;
         fmtname = ' ';
         label   = ' ';
         start   = ' ';
         type    = ' ';
         label
            fmtname = 'Format name '
            label   = 'Format value label'
            start   = 'Starting value for format'
            type    = 'Type of format'
            ;
    run;

 %end;

 /*
 / AJC001: Retrieve the formats that will be used to derive informats for
 / creating code variables from decode variables.
 /----------------------------------------------------------------------------*/

 proc sql ;
      create table &prefix._fmtlist as select a.*, b.*
      from &prefix._varFmtlist as a,
           &prefix._allfmts as b
      where b.fmtname = compress(a.format_nm,'.') and a.ftype='infmt'
      ;
 quit;

 %if &g_debug ge 5 %then 
 %do;
    proc print data=&prefix._fmtlist;
    title1 "FORMAT CATALOG CONTENTS PRIOR TO INFORMAT DERIVATION";
    run;
 %end;

 %let l_start_length=%tu_varattr(dsetin=&prefix._fmtlist, varin=start, attrib=varlen);
 %let l_label_length=%tu_varattr(dsetin=&prefix._fmtlist, varin=label, attrib=varlen);

 data &prefix._informats (drop=old_:);
      set &prefix._fmtlist(rename=(start=old_start label=old_label));
      length start $&l_label_length label $&l_start_length;

      * Character decode to character code via format *;
      if type='C' then do;
          ftype='';
          format_nm=compress('$'||format_nm);
      end;

      * Character decode to numeric code via informat *;
      else
          type='I';

      * Swap the START and LABEL values to create the CODE from the DECODE *;
      start=old_label;
      label=old_start;

 run;

 %if &g_debug ge 5 %then 
 %do;
    proc print data=&prefix._informats ;
    title1 "FORMAT CATALOG CONTENTS WITH INFORMATS DERIVED";
    run;
 %end;

 proc format lib=work cntlin=&prefix._informats ;
 run;

 proc sort data=&prefix._informats out=&prefix._varFmtlist2(keep=name decode format_nm ftype) nodupkey;
      by name decode format_nm;
 run;

 /*
 / Create program statements to create decoded variables.
 / AJC001: Create code variables from decode via informat.
 /----------------------------------------------------------------------------*/

 filename tmp1 temp;
 data _null_;
      set &prefix._varFmtlist (where=(ftype='')) &prefix._varFmtlist2;
      file tmp1;
      if ftype='' then put decode '=put(' name ',' format_nm +(-1) ');';
      if ftype='infmt' then put decode '=input(' name ',' format_nm +(-1) ');';
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

%mend tu_decode;
