/*------------------------------------------------------------------------------
| Macro Name    : tu_align.sas
|
|
| Macro Version : 2.0
|
| SAS version   : SAS v8.2
|
| Created By    : Yongwei Wang (YW62951)
|
| Date          : 16-June-03
|
| Macro Purpose : This macro is for optimising column width. The data will be
|                 aligned so that decimal places or implied decimal places for
|                 the 'n' line up, and the percentage signs for frequency
|                 statistic line up. The width of each presentation column
|                 containing statistical data should be optimised to a minimum
|                 width.
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ALIGNMENT           Specifies the alignment to be used for the        Right             
|                     right-hand (non-numeric) part of the input                          
|                     values                                                              
|                     Valid values: "right", or "left"                                    
|                                                                                         
| COMPRESSCHRYN       Specifies whether to compress right-hand          Y                 
|                     (non-numeric) part of the input values or not                       
|                     Valid values: "Y", or "N"                                           
|                                                                                         
| DP                  Specifies the decimal point character to be       . (dot)           
|                     expected in the left-hand part of values                            
|                     Valid values: a single character                                    
|                                                                                         
| DSETIN              Specifies the dataset whose variables are to be   (Blank)           
|                     aligned                                                             
|                     Valid values: name of a dataset                                     
|                                                                                         
| DSETOUT             Specifies the name of the output dataset to be    &DSETIN           
|                     created                                                             
|                     Valid values: valid dataset name                                    
|                                                                                         
| NCSPACES            Specifies the minimum number of spaces to be      1                 
|                     inserted between the left-hand and right-hand                       
|                     part of values                                                      
|                     Valid values: zero or positive integer                              
|                                                                                         
| NDSPCHAR            Specifies a split character which is used to      /                 
|                     split the numerator and denominator                                 
|                     Valid values: (Blank) or one or more characters                     
|                                                                                         
| VARSIN              Specifies a list of variables whose values are    (Blank)           
|                     to be aligned                                                       
|                     Valid values: names of variables that exist in                      
|                     dsetin. Values of variables shall be numeric in                     
|                     content followed by optional                                        
|                     numerator/denominator splitter, optional numeric                    
|                     denominator and optional characters (i.e.                           
|                     bracketed, with a percentage sign)                                  
|                                                                                         
| VARSOUT             Specifies the names of the respective output      (Blank)            
|                     variables. If &VARSIN has more number of                            
|                     variable names, the name in &VARSIN will be used                    
|                     in the omitted position. There is no check if                       
|                     &VARSOUT has more names then &VARSIN                                
|                     Valid values: blank, or a list of valid variable                    
|                     names. If a &VARSOUT variable name is not the                       
|                     same as the &VARSIN variable name in the same                       
|                     position, the variable should not exist in                          
|                     &DSETIN  
|-------------------------------------------------------------------------------
|
| Output:    SAS data set with lined variables
|
| Global macro variables created:  None
|
| Macros called :
|   (@) tr_putlocals
|   (@) tu_abort
|   (@) tu_chknames
|   (@) tu_chkvarsexist
|   (@) tu_expvarlist
|   (@) tu_nobs
|   (@) tu_putglobals
|   (@) tu_tidyup
|   (@) tu_words
|
| Example:
|   data datain;
|      input @1 var1 $22. @23 var2 $10.;
|   datalines;
|   12.3 (47%)             1 (100%)
|   12.3  (   47   %   )  12
|   12.3                   6  (50%)
|   1,000   (<1%)          6  (50%)
|   10,000 (2%)            2
|   0.345 (99%)            1  (50%)
|   23,H                   1  (50%)
|   10.000,5              52
|   10.000.00,5           26  (50%)
|   ;
|   run;
|
|   %TU_ALIGN(
|             compresschryn =Y,
|             dsetin        =datain,
|             dsetout       =dataout,
|             ncspaces      =1,
|             varsin        =var1 var2,
|             varsout       =var1out var2out
|            );
|
|-------------------------------------------------------------------------------
|
| Change Log :
|
| Modified By :             Yongwei Wang
| Date of Modification :    03 Sep 2003
| New Version Number :      1/2
| Modification ID :
| Reason For Modification : Incorporate comments from first iteration of SCR.
|-------------------------------------------------------------------------------
| Modified By :             Yongwei Wang
| Date of Modification :    15 Oct 2004
| New Version Number :      2/1
| Modification ID :         Yongwei Wang
| Reason For Modification:  -Valid value of &VARSIN has been changed. Valid 
|                            value should be a list of variable names which can 
|                            be expanded via calling %tu_expvarlist
|                           -Valid value of &VARSIN has been changed. Numerical 
|                            variable can also be aligned
|                           -Simplified the codes so that the %tu_expvarlist can 
|                            be called
|                           -Added call of %tu_expvarlist to expand the &varsin
|                           -Added a new parameter NDSPCHAR to define split 
|                            character which splits the nominator and denominator
|                           -Changed the process of parameter validation so that 
|                            multiple errors can be found in one run.      
|                           -Removed call of tu_chkvartype and added call of 
|                            %tu_words
|                           -Changed the alignment process so that the variable 
|                            with result style NUMERDENOMPCT can also be aligned
|                           -Modified the header according to the change of unit 
|                            specification. 
|-------------------------------------------------------------------------------
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+-----------------------------------------------------------------------------*/
%MACRO tu_align(
     ALIGNMENT     =Right,   /* Alignment for right-hand part of input values */ 
     COMPRESSCHRYN =Y,       /* Whether to compress character part */
     DP            =.,       /* Decimal point character */
     DSETIN        =,        /* Input dataset */
     DSETOUT       =&DSETIN, /* Output dataset */
     NCSPACES      =1,       /* Minimum number of spaces between left-hand and right-hand part of values */
     NDSPCHAR      =/,       /* A character which splits numerator and denominator */
     VARSIN        =,        /* Variables to be aligned */
     VARSOUT       =         /* Names of output variables */
     );
   /*
   / Write details of macro call to log                               
   /------------------------------------------------------------------*/
   %LOCAL MacroVersion;
   %LET MacroVersion = 2;
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   %LOCAL l_prefix l_varprefix l_numof_vars l_varlist  l_varlabels  l_newvnames 
          l_newvnames l_curpos l_intilen l_tmp l_vartypes l_rc l_i l_dropvars
          l_chknewvars;
   %LET l_prefix=_align;
   /*
   / Check if any of the parameters is empty                           
   /-------------------------------------------------------------------*/
   %IF %nrquote(&ALIGNMENT) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter ALIGNMENT is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&DP) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter DP is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&DSETIN) EQ  %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter DSETIN is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&COMPRESSCHRYN) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter COMPRESSCHRYN is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&NCSPACES) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter NCSPACES is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&VARSIN) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter VARSIN is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrbquote(&DSETOUT) EQ %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter DSETOUT is blank.;
      %LET g_abort=1;
   %END;
   
   %IF &g_abort eq 1 %THEN %GOTO macerr;
   /*
   / Check if any of the parameters is invalid.                        
   /-------------------------------------------------------------------*/
   %LET alignment=%qsubstr(%upcase(&ALIGNMENT), 1, 1);
   %IF &alignment EQ R %THEN %LET alignment=Right;
   %ELSE %IF &alignment EQ L %THEN %LET alignment=Left;
   %ELSE %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: the value of parameter ALIGNMENT is invalid. Valid value should be R(ight) or L(eft);
      %LET g_abort=1;
   %END;
   %LET compresschryn=%qsubstr(%upcase(&compresschryn), 1, 1);
   %IF ( %nrquote(&compresschryn) NE Y ) AND ( %nrquote(&compresschryn) NE N ) %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: the value of parameter COMPRESSCHRYN is invalid. Valid value should be Y or N;
      %LET g_abort=1;
   %END;
   %IF %length(%str(&dp)) GT 1 %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: parameter DP can only be single character.;
      %LET g_abort=1;
   %END;
   %LET l_rc=%tu_nobs(%str(&DSETIN));      
   %IF &l_rc LT 0 %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: input data set %str(&dsetin) does not exist.;
      %LET g_abort=1;
   %END;
   %ELSE %IF &l_rc EQ 0 %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: there is no data in input data set %str(&dsetin).;
      %LET g_abort=1;
   %END;
   %LET l_rc=%tu_chknames(%str(&DSETOUT), data);
   %IF %nrbquote(&l_rc) EQ -1 %THEN %GOTO macerr;
   %IF %nrbquote(&l_rc) NE %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: dataset name %str(&l_rc) given by DSETOUT is invalid.;
      %LET g_abort=1;
   %END;
   
   /*
   / Check if &NCSPACES is a positive integer..                        
   /-------------------------------------------------------------------*/
   DATA _NULL_;
      IF verify("&NCSPACES", "1234567890") GT 0 THEN 
      DO;
         CALL SYMPUT('l_rc', '-1');
      END;
      ELSE IF length(compress("&NCSPACES")) GT 2 THEN 
      DO;
         CALL SYMPUT('l_rc', '-1');
      END;
   RUN;
   %IF %nrbquote(&l_rc) EQ -1 %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: the value of parameter NCSPACES is invalid. It should be an integer.;
      %LET g_abort=1;
   %END;
   %IF %nrquote(&VARSOUT) NE %THEN 
   %DO;
      %LET l_rc=%tu_chknames(%str(&VARSOUT), variable);
      %IF %nrbquote(&l_rc) EQ -1 %THEN %LET g_abort=1;
      %ELSE %IF %nrbquote(&l_rc) NE %THEN 
      %DO;
         %PUT %str(RTERR)OR: TU_ALIGN: variable name %str(&l_rc) in VARSOUT is invalid.;
         %LET g_abort=1;
      %END;
   %END; /* end-if on %nrquote(&VARSOUT) NE */
   
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
                                          
   /*
   / Call tu_expvarlist to expand VARSIN.                             
   /------------------------------------------------------------------*/
   
   %tu_expvarlist(
      DSETIN         =&dsetin,
      VARSIN         =&varsin,
      VAROUT         =l_varlist,
      SCOPE          =,
      SEPARATED_BY   =' '
      );
      
   %IF &G_ABORT NE 0 %THEN %GOTO ENDMAC;    
   /*
   / Call tu_chkvarsexist to check existance of variables.            
   /------------------------------------------------------------------*/
   %LET l_rc=%tu_chkvarsexist(&DSETIN, &l_varlist);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   %IF %nrquote(&l_rc) NE %THEN 
   %DO;
      %PUT %str(RTERR)OR: TU_ALIGN: variables &l_rc given in VARSIN are not in input data ;
      %PUT %str(RTERR)OR: TU_ALIGN: set "&dsetin". Please check the parameters.;
      %GOTO macerr;
   %END;
   
   /*
   / Call tu_words to get number of input variables to define local   
   / macros used by each input variable.                              
   /------------------------------------------------------------------*/
  
   %LET l_numof_vars=%tu_words(&l_varlist);
            
   %DO l_i=1 %TO &l_numof_vars;
      %LOCAL l_charlen&l_i l_int1len&l_i l_int2len&l_i l_dec1len&l_i l_dec2len&l_i l_dec3len&l_i l_varlen&l_i l_ndsplen&l_i;
   %END; /* end of do-to loop */
      
   /*
   / GET outpu variable names and list of variables used to split
   / input data set. Input data sets will be splited to two: one has
   / only variables that need to be aligned, the other does not have
   / such variables.
   /------------------------------------------------------------------*/
   
   DATA _NULL_;      
      LENGTH varsin varsout newvarsout dropvars chknewvars $32761 
             var1 var2 prefix initlen $100;
      
      /* Get output variable name */
      varsin=symget('l_varlist');
      varsout=symget('varsout');
      newvarsout='';
      dropvars=''; 
      chknewvars='';
      
      i=1;
      var1=scan(varsin, i, ' ');
      var2=scan(varsout, i, ' ');
      
      DO WHILE (var1 NE '');
         IF ( upcase(var1) EQ upcase(var2) ) OR ( VAR2 EQ '' ) THEN 
            dropvars=trim(left(dropvars))||' '||trim(left(var1));         
         IF ( upcase(var1) NE upcase(var2) ) AND ( VAR2 NE '' ) THEN
            chknewvars=trim(left(chknewvars))||' '||trim(left(VAR2));
            
         IF VAR2 NE '' THEN newvarsout=trim(left(newvarsout))||' '||trim(left(var2));
         ELSE newvarsout=trim(left(newvarsout))||' '||trim(left(var1));   
         
         initlen=trim(left(initlen))||' 0'; 
         i=i+1;
         var1=scan(varsin, i, ' ');
         var2=scan(varsout, i, ' ');        
      END; /* end of do-while loop */
      
      CALL SYMPUT('l_initlen', trim(left(initlen)));
      CALL SYMPUT('l_newvnames', trim(left(newvarsout)));     
      CALL SYMPUT('l_dropvars', trim(left(dropvars))); 
      CALL SYMPUT('l_chknewvars', trim(left(chknewvars)));
      
      /* Find a prefix for temporary variable */
      i=0;
      prefix='__ALIGN_PREFIX_0'; 
      varsin=trim(left(varsin))||' '||left(varsout);                                
      varsin=upcase(varsin);
      DO WHILE (index(varsin, prefix) GT 0);
         i=i+1;
         prefix=compress('__ALIGN_PREFIX_'||put(i, 6.0));
      END; 
      CALL SYMPUT('l_varprefix', compress(prefix));      
   RUN;  
   %LET l_varlist=%qupcase(&l_varlist);    
   %IF %nrbquote(&g_debug) GT 1 %THEN 
   %DO;
      %PUT l_newvnames=&l_newvnames;
      %PUT l_varlist  =&l_varlist;
   %END;
   
   /*
   / Split input data set into two data sets. Put data2 aside and     
   / save variables that need to be processed to data1                
   /------------------------------------------------------------------*/
   DATA &l_prefix.data1 ( KEEP = &l_varlist )
        &l_prefix.data2 
        %IF %nrbquote(&l_dropvars) NE %THEN 
        %DO;
           ( DROP = &l_dropvars )
        %END;
        ;
      SET &dsetin ;
      OUTPUT &l_prefix.data1;
      OUTPUT &l_prefix.data2;
   RUN;
   
   /*
   / output variables should not in data set DATA2.                   
   /------------------------------------------------------------------*/
   %LET l_i=1;
   %LET l_tmp=%scan(&l_chknewvars, &l_i, %str( ));
   %DO %WHILE (%nrbquote(&l_tmp) NE);
      %LET l_rc=%tu_chkvarsexist(&l_prefix.data2, &l_tmp);
      %IF %nrbquote(&l_rc) EQ -1 %THEN %GOTO macerr;
      %IF %nrbquote(&l_rc) EQ %THEN 
      %DO;
         %PUT %str(RTERR)OR: TU_ALIGN: variable name &l_tmp in VARSOUT is already in data set.;
         %GOTO macerr;
      %END;
      %LET l_i=%eval(&l_i + 1);
      %LET l_tmp=%scan(&l_chknewvars, &l_i, %str( ));
   %END; /* end of do-while loop */
   /*
   / Keep variable labels and get variable types.                     
   /------------------------------------------------------------------*/
   
   DATA _NULL_;
      LENGTH &l_varprefix.labels &l_varprefix.type $32761 &l_varprefix.quote $1 &l_varprefix.label $200;
      did=open("&l_prefix.data1", 'i');
      %DO l_i=1 %TO &l_numof_vars;
         vnum=varnum(did, "%scan(&l_varlist, &l_i, %str( ))");
         &l_varprefix.label=varlabel(did, vnum);
         IF &l_varprefix.label NE '' THEN 
         DO;
            IF index(&l_varprefix.label, "'") GT 0 THEN &l_varprefix.quote='"';
            ELSE &l_varprefix.quote="'";
            &l_varprefix.labels=trim(left(&l_varprefix.labels))||" %scan(&l_newvnames, &l_i, %str( ))="||&l_varprefix.quote||
                                trim(left(&l_varprefix.label))||&l_varprefix.quote; 
         END;
         &l_varprefix.type=trim(left(&l_varprefix.type))||' '||left(vartype(did, vnum)); 
      %END; /* end of do-to loop */
      rc=close(did);
      CALL SYMPUT('l_varlabels', trim(left(&l_varprefix.labels)));
      CALL SYMPUT('l_vartypes', trim(left(&l_varprefix.type)));
   RUN;
   
   /*
   / Apply format to variable values.                                 
   / Separate the variable value to numerator, denorminator and character.
   / Separate each of numerator and deominator to integer and deciaml
   /------------------------------------------------------------------------*/
  
   DATA &l_prefix.data3;
      SET &l_prefix.data1 end=&l_varprefix.eof1;  
      LENGTH &l_varprefix.int1v1-&l_varprefix.int1v&l_numof_vars
             &l_varprefix.int2v1-&l_varprefix.int2v&l_numof_vars 
             &l_varprefix.dec1v1-&l_varprefix.dec1v&l_numof_vars 
             &l_varprefix.dec2v1-&l_varprefix.dec2v&l_numof_vars 
             &l_varprefix.dec3v1-&l_varprefix.dec3v&l_numof_vars 
             &l_varprefix.ndspv1-&l_varprefix.ndspv&l_numof_vars
             &l_varprefix.vint1 &l_varprefix.vint2 &l_varprefix.vndsp
             &l_varprefix.vdec1 &l_varprefix.vdec2               $13
             &l_varprefix.charv1-&l_varprefix.charv&l_numof_vars   
             &l_varprefix.vt1 &l_varprefix.vt2 &l_varprefix.vt3            
             &l_varprefix.vchar                                  $200;
      DROP   &l_varprefix.v: &l_varlist ;               
      ARRAY  &l_varprefix.a_char {&l_numof_vars} _TEMPORARY_ (&l_initlen);
      ARRAY  &l_varprefix.a_int1 {&l_numof_vars} _TEMPORARY_ (&l_initlen);     
      ARRAY  &l_varprefix.a_dec1 {&l_numof_vars} _TEMPORARY_ (&l_initlen);
      ARRAY  &l_varprefix.a_int2 {&l_numof_vars} _TEMPORARY_ (&l_initlen);
      ARRAY  &l_varprefix.a_dec2 {&l_numof_vars} _TEMPORARY_ (&l_initlen);      
      ARRAY  &l_varprefix.a_ndsp {&l_numof_vars} _TEMPORARY_ (&l_initlen);     
      ARRAY  &l_varprefix.a_dec3 {&l_numof_vars} _TEMPORARY_ (&l_initlen);
      
      %DO l_i=1 %TO &l_numof_vars;     
         %IF %scan(&l_vartypes, &l_i, %str( )) EQ N %THEN 
         %DO;  
             &l_varprefix.vt3=left(putn(%scan(&l_varlist, &l_i, %str( )), 
                              vformat(%scan(&l_varlist, &l_i, %str( )))));
         %END;
         %ELSE %DO;
             &l_varprefix.vt3=left(putc(%scan(&l_varlist, &l_i, %str( )), 
                              vformat(%scan(&l_varlist, &l_i, %str( )))));        
         %END;
    
         LINK SEPCHAR;
         %IF &COMPRESSCHRYN EQ Y %THEN 
         %DO;
            &l_varprefix.vchar=compress(&l_varprefix.vchar);
         %END;      
         
         /* Calculate the length of each part */
         &l_varprefix.a_char{&l_i}=max(&l_varprefix.a_char{&l_i}, length('l'||trim(left(&l_varprefix.vchar))) -1);
         &l_varprefix.a_int1{&l_i}=max(&l_varprefix.a_int1{&l_i}, length('l'||trim(left(&l_varprefix.vint1))) -1);
         
         IF (&l_varprefix.vchar EQ "") AND (&l_varprefix.vndsp EQ "" ) THEN 
         DO;
            &l_varprefix.a_dec3{&l_i}=max(&l_varprefix.a_dec3{&l_i}, length('l'||trim(left(&l_varprefix.vdec1))) -1);         
            /* &l_varprefix.a_dec3{&l_i}=0; */
         END;
         ELSE DO;
            &l_varprefix.a_dec1{&l_i}=max(&l_varprefix.a_dec1{&l_i}, length('l'||trim(left(&l_varprefix.vdec1))) -1);         
            /* &l_varprefix.a_dec1{&l_i}=0; */
         END;
         
         &l_varprefix.a_int2{&l_i}=max(&l_varprefix.a_int2{&l_i}, length('l'||trim(left(&l_varprefix.vint2))) -1);
         &l_varprefix.a_dec2{&l_i}=max(&l_varprefix.a_dec2{&l_i}, length('l'||trim(left(&l_varprefix.vdec2))) -1);                  
         &l_varprefix.a_ndsp{&l_i}=max(&l_varprefix.a_ndsp{&l_i}, length('l'||trim(left(&l_varprefix.vndsp))) -1);         
                  
         &l_varprefix.charv&l_i=&l_varprefix.vchar;
         &l_varprefix.int1v&l_i=&l_varprefix.vint1;
         &l_varprefix.dec1v&l_i=&l_varprefix.vdec1;         
         &l_varprefix.int2v&l_i=&l_varprefix.vint2;
         &l_varprefix.dec2v&l_i=&l_varprefix.vdec2;   
         &l_varprefix.dec3v&l_i=&l_varprefix.vdec1;   
         &l_varprefix.ndspv&l_i=&l_varprefix.vndsp;       
      %END;  /* end of do-to loop */
            
      IF &l_varprefix.eof1 THEN 
      DO;
         %DO l_i=1 %TO &l_numof_vars;
            CALL SYMPUT("l_charlen&l_i.", compress(put(&l_varprefix.a_char{&l_i}, 6.0)));
            CALL SYMPUT("l_int1len&l_i.", compress(put(&l_varprefix.a_int1{&l_i}, 6.0)));
            CALL SYMPUT("l_dec1len&l_i.", compress(put(&l_varprefix.a_dec1{&l_i}, 6.0)));            
            CALL SYMPUT("l_int2len&l_i.", compress(put(&l_varprefix.a_int2{&l_i}, 6.0)));
            CALL SYMPUT("l_dec2len&l_i.", compress(put(&l_varprefix.a_dec2{&l_i}, 6.0)));                               
            CALL SYMPUT("l_dec3len&l_i.", compress(put(&l_varprefix.a_dec3{&l_i}, 6.0)));                               
            CALL SYMPUT("l_ndsplen&l_i.", compress(put(&l_varprefix.a_ndsp{&l_i}, 6.0)));  
                                  
            IF &l_varprefix.a_char{&l_i} GT 0 THEN &l_varprefix.a_char{&l_i}=&l_varprefix.a_char{&l_i} + &ncspaces;
            &l_varprefix.vlen1=&l_varprefix.a_char{&l_i} + &l_varprefix.a_int1{&l_i} + &l_varprefix.a_dec1{&l_i} + 
                               &l_varprefix.a_int2{&l_i} + &l_varprefix.a_dec2{&l_i} + &l_varprefix.a_ndsp{&l_i};
                              
            &l_varprefix.vlen2=&l_varprefix.a_int1{&l_i} + &l_varprefix.a_dec3{&l_i};     
            &l_varprefix.vlen1=max(1, &l_varprefix.vlen1, &l_varprefix.vlen2);     
            CALL SYMPUT("l_varlen&l_i.", compress(put(&l_varprefix.vlen1, 6.0)));
         %END;
         
         /* Remove the NOTE for variable is uninitialized */
         %IF %nrbquote(&ndspchar) EQ %THEN 
         %DO;      
            &l_varprefix.vint2='';
            &l_varprefix.vdec2='';
            &l_varprefix.vndsp='';
         %END;
      END; /* end-if on &l_varprefix.eof1 */
      RETURN;
      
   SEPCHAR: 
      /* Separate the value into five parts - int1 dec1 int2 dec2 and char */
      &l_varprefix.vchar='';
      &l_varprefix.vint1='';
      &l_varprefix.vdec1='';
      &l_varprefix.vint2='';
      &l_varprefix.vdec2='';
      &l_varprefix.vndsp='';
      &l_varprefix.vt3=left(&l_varprefix.vt3);
      
      IF &l_varprefix.vt3 EQ '' THEN return;
      
      %IF %nrbquote(&ndspchar) NE %THEN 
      %DO;      
         &l_varprefix.vindex=index(&l_varprefix.vt3, "&ndspchar");
         IF &l_varprefix.vindex GT 0 THEN 
         DO; 
            &l_varprefix.vndsp="&ndspchar.";              
            IF &l_varprefix.vindex GT 1 THEN 
            DO;            
               &l_varprefix.vt1=substr(&l_varprefix.vt3, 1, &l_varprefix.vindex - 1);   
               
               LINK SEPINT;
               
               &l_varprefix.vint1=&l_varprefix.vt1;
               &l_varprefix.vdec1=&l_varprefix.vt2;                          
            END; /* end-if on &l_varprefix.vindex GT 1 */
            
            &l_varprefix.vt3=left(substr(&l_varprefix.vt3, &l_varprefix.vindex + 1));
            &l_varprefix.vt1=scan(&l_varprefix.vt3, 1, ' ');
        
            LINK CHKINT;
                      
            IF scan(&l_varprefix.vt3, 1, ' ') NE &l_varprefix.vchar THEN 
            DO;                           
               &l_varprefix.vint2=&l_varprefix.vt1;
               &l_varprefix.vdec2=&l_varprefix.vt2;  
               &l_varprefix.vindex=index(&l_varprefix.vt3, ' ');
               &l_varprefix.vchar=left(substr(&l_varprefix.vt3, &l_varprefix.vindex + 1));
            END; 
            ELSE DO;
               &l_varprefix.vchar=&l_varprefix.vt3;
            END; /* end-if on &l_varprefix.vt3 NE &l_varprefix.vchar */
                   
         END;  
         ELSE DO; 
      %END; /* end-if on &ndspchar NE */
           
      &l_varprefix.vt1=scan(&l_varprefix.vt3, 1, ' ');
      LINK CHKINT;
      IF scan(&l_varprefix.vt3, 1, ' ') NE &l_varprefix.vchar THEN 
      DO; 
         &l_varprefix.vint1=&l_varprefix.vt1;
         &l_varprefix.vdec1=&l_varprefix.vt2;  
         &l_varprefix.vindex=index(&l_varprefix.vt3, ' ');
         &l_varprefix.vchar=left(substr(&l_varprefix.vt3, &l_varprefix.vindex + 1)); 
      END;  
      ELSE DO;
         &l_varprefix.vchar=&l_varprefix.vt3;
      END;
          
      %IF %nrbquote(&ndspchar) NE %THEN 
      %DO;           
         END;  /* end-if on &l_varprefix.vindex GT 0  */
      %END;
      
      RETURN;
      
   CHKINT:
      /* Check if the value is numeric varlue, if yes, separate it */
      &l_varprefix.vti1=verify(substr(&l_varprefix.vt1, 2), "0123456789,&dp ");
      &l_varprefix.vti2=verify(substr(&l_varprefix.vt1, 1, 1), "-0123456789,&dp ");  
      &l_varprefix.vchar='';
   
      IF (&l_varprefix.vti1 GT 0) OR (&l_varprefix.vti2 GT 0) OR (&l_varprefix.vt1 EQ '-') THEN
         &l_varprefix.vchar=&l_varprefix.vt1;
      ELSE DO;                            
         LINK SEPINT;      
      END;  
      RETURN;
                     
   SEPINT:
      /* Split a numeric value separated into two parts */
      &l_varprefix.vti1=index(&l_varprefix.vt1, "&dp.");
      &l_varprefix.vt2='';       
      IF &l_varprefix.vti1 GT 0 THEN 
      DO;    
         &l_varprefix.vt2=left(substr(&l_varprefix.vt1, &l_varprefix.vti1));
         IF &l_varprefix.vti1 GT 1 THEN
            &l_varprefix.vt1=left(substr(&l_varprefix.vt1, 1, &l_varprefix.vti1 - 1));
         ELSE 
            &l_varprefix.vt1='';
      END;  /* end-if on &l_varprefix.vti1 GT 0 */
   
      RETURN;           
   RUN;
   
   %IF %nrbquote(&g_debug) GT 1 %THEN %DO;
      %DO l_i=1 %TO &l_numof_vars;
         %PUT   l_charlen&l_i   l_int1len&l_i   l_int2len&l_i   l_dec1len&l_i   l_dec2len&l_i   l_dec3len&l_i   l_varlen&l_i;
         %PUT &&l_charlen&l_i &&l_int1len&l_i &&l_int2len&l_i &&l_dec1len&l_i &&l_dec2len&l_i &&l_dec3len&l_i &&l_varlen&l_i;
      %END;
   %END; /* end of do-to loop */
    
   /*
   / Put deominator integer and deciaml together and put numerator, 
   / denorminator and character together
   /------------------------------------------------------------------*/
    
   DATA &l_prefix.data4;
      LENGTH
      %DO l_i=1 %TO &l_numof_vars;
         %IF &&l_charlen&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.charv&l_i $&&l_charlen&l_i...
         %END;  
         %IF &&l_int1len&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.int1v&l_i $&&l_int1len&l_i...            
         %END;  
         %IF &&l_int2len&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.int2v&l_i $&&l_int2len&l_i...            
         %END;  
         %IF &&l_dec1len&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.dec1v&l_i $&&l_dec1len&l_i...            
         %END;  
         %IF &&l_dec2len&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.dec2v&l_i $&&l_dec2len&l_i...
         %END;
         %IF &&l_dec3len&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.dec3v&l_i $&&l_dec3len&l_i...
         %END;
         %IF &&l_ndsplen&l_i.. GT 0 %THEN 
         %DO;
            &l_varprefix.ndspv&l_i $&&l_ndsplen&l_i...
         %END;         
      %END;  /* end of do-to loop */
      ;
      SET &l_prefix.data3;
      LENGTH
      %DO l_i=1 %TO &l_numof_vars;
          &l_varprefix.v&l_i $&&l_varlen&l_i...
      %END; 
      ;
      
      RENAME
      %DO l_i=1 %TO &l_numof_vars;
         &l_varprefix.v&l_i =%scan(&l_newvnames, &l_i, %str( ))
      %END;
      ;  
      
      KEEP &l_varprefix.v1-&l_varprefix.v&l_numof_vars;     
                                                           
      %DO l_i=1 %TO &l_numof_vars;
         &l_varprefix.v&l_i='';
         %LET l_curpos=1;
         %IF &&l_int1len&l_i.. GT 0 %THEN 
         %DO;        
            substr(&l_varprefix.v&l_i, &l_curpos)=right(&l_varprefix.int1v&l_i);
            %LET l_curpos=%eval(&l_curpos + &&l_int1len&l_i);
         %END;  
         
         IF (&l_varprefix.ndspv&l_i EQ '') AND ( &l_varprefix.charv&l_i EQ '') THEN 
         DO;
             %IF &&l_dec3len&l_i.. GT 0 %THEN %DO;
               substr(&l_varprefix.v&l_i, &l_curpos)=left(&l_varprefix.dec3v&l_i);
            %END;  
         END;         
         ELSE DO;                
            %IF &&l_dec1len&l_i.. GT 0 %THEN 
            %DO;
               substr(&l_varprefix.v&l_i, &l_curpos)=left(&l_varprefix.dec1v&l_i);
               %LET l_curpos=%eval(&l_curpos + &&l_dec1len&l_i);         
            %END;          
            %IF &&l_ndsplen&l_i.. GT 0 %THEN 
            %DO;
               substr(&l_varprefix.v&l_i, &l_curpos)=right(&l_varprefix.ndspv&l_i);
               %LET l_curpos=%eval(&l_curpos + &&l_ndsplen&l_i);         
            %END;         
            %IF &&l_int2len&l_i.. GT 0 %THEN 
            %DO;
               substr(&l_varprefix.v&l_i, &l_curpos)=right(&l_varprefix.int2v&l_i);
               %LET l_curpos=%eval(&l_curpos + &&l_int2len&l_i);         
            %END;  
            %IF &&l_dec2len&l_i.. GT 0 %THEN 
            %DO;
               substr(&l_varprefix.v&l_i, &l_curpos)=left(&l_varprefix.dec2v&l_i);
               %LET l_curpos=%eval(&l_curpos + &&l_dec2len&l_i);          
            %END;   
            %IF &&l_charlen&l_i.. GT 0 %THEN 
            %DO;
               substr(&l_varprefix.v&l_i, &l_curpos + &ncspaces)=&ALIGNMENT.(&l_varprefix.charv&l_i);
            %END;                           
         END;
         
      %END;  /*** -end of do-to loop */
   RUN;
   
   %IF %nrbquote(&g_debug) GT 1 %THEN 
   %DO;
      PROC PRINT DATA=&l_prefix.data4;
      RUN;
   %END;
   /*
   / Add other variables back, recover the label of the variables and 
   / create output data set.                                          
   /------------------------------------------------------------------*/
   DATA &dsetout (label="Output data set from TU_ALIGN") ;
      MERGE &l_prefix.data2
            &l_prefix.data4;
      %IF %nrbquote(&l_varlabels) NE %THEN 
      %DO;
         LABEL &l_varlabels;
      %END;
   RUN;
  
   %goto endmac;
%MACERR:
   %LET g_abort=1;
   %PUT;
   %PUT %str(RTN)OTE: ------------------------------------------------------------;
   %PUT %str(RTN)OTE: &sysmacroname completed with error(s);
   %PUT %str(RTN)OTE: ------------------------------------------------------------;
   %PUT;
   %tu_abort();
%ENDMAC:
   /*
   / Clear temporary data set and fields.                              
   /-------------------------------------------------------------------*/
                                                                               
   %tu_tidyup(
      rmdset=&l_prefix.:,
      glbmac=none
      );
%MEND tu_align;
