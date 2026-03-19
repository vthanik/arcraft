/*==================================================================================================
| Macro Name       : tu_split.sas
|                 
| Macro Version    : 2
|                 
| SAS version      : SAS v8
|                 
| Created By       : Yongwei Wang (YW62951)
|                 
| Date             : 02-Dec-03
|                 
| Macro Purpose    : Add split character to the specified variables in the specified data set, 
|                    according to the given widths. If an indent value is given for a variable, 
|                    the indent will be added to the beginning of the variable and after every 
|                    added split character. The format will be applied to the variable value before 
|                    adding the split character. If required, any leading apace, after the split 
|                    character, except the added indent, will be removed
|
| Macro Design     : PROCEDURE STYLE
|
|=================================================================================================== 
| Input Parameters :
|
| NAME              DESCRIPTION                                                    DEFAULT
|--------------------------------------------------------------------------------------------------- 
| DSETIN       Specifies the name of the input data set                            (Blank)
|              Valid values: A valid existing SAS data set name	                   
|                                                                                  
| DSETOUT      Specifies the name of the output data set. If blank, the &DSETIN    (The input data set)
|              will be used                                                        
|              Valid values: Blank or valid SAS data set name	                   
|                                                                                  
| FORMATS      Variables and their format for display. For use where format for    (Blank)
|              display differs to the format on the DSETIN.                        
|              Valid values: Blank or values of column names and formats such as               
|              form valid syntax for a SAS FORMAT statement	                       
|                                                                                  
| INDENTADJUST Specifies if a leading space needs to be added to the indent of     Y
| YN           the last line. The PROC REPORT removes one leading space of the     
|              last line from the variable values. To display the values           
|              correctly, one space needs to be added.                             
|              Valid values: Y or N                                                
|                                                                                  
| INDENTSOFVAR Specifies a list of numbers of indent spaces that will be added to  (Blank)
| S            the beginning and after each split character for the variable         
|              values. One variable in &INDENTVARS should have one value in the    
|              list                                                                
|              Valid values: Blank or a list of positive numbers	               
|                                                                                  
| INDENTVARS   Specifies a list of variables that need to be indented. If blank,   (Blank)
|              no indent will be added                                             
|              Valid Values: Blank or a list of variables that in &VARSIN	       
|                                                                                  
| LABELS       Variables and their label for display. For use where label for      (Blank)
|              display differs to the label on the DSETIN                          
|              Valid values: Blank or pairs of variable names and labels with      
|              equals signs between them	                                       
|                                                                                  
| NOLEFTALIGNV Specifies a list of variables that will not be left aligned before  (Blank)
| ARS          each &SPLITCHAR. By default, variables will be left aligned at      
|              each line.                                                          
|              Valid Values: Blank or a list of variables that in &VARSIN	          
|                                                                                  
| NUMOFLINEVAR Specifies a suffix for output number of lines variable. It will be  0
| SUFFIX       added to the end of each variable in &VARSIN to form new variables  
|              to save number of lines in the variable values. If blank, no number 
|              of lines variable will be created                                   
|              Valid Values: Blank or a valid suffix that can be used to form SAS  
|              variable names	                                                   
|                                                                                  
| OUTVARPREFIX Specifies a prefix for output variables. It will be added to the    _SP_
|              beginning of each variable in &VARSIN to form new variables to save 
|              the values with &SPLITCHAR. If blank, the &SPLITCHAR will be        
|              directly added to the variables.                                    
|              Valid Values: Blank or a valid SAS variable name prefix	           
|                                                                                  
| RESETVARLENG Specifies whether the lengths of the variables need to be           Y
| THYN         optimised. If yes, the macro will calculate maximum of the length   
|              of the variable values and make it as the new length.               
|              Valid values:  Y or N	                                           
|                                                                                  
| SPLITCHAR    Specifies the split character to be passed to %tu_display           ~      
|              Valid values: one single character	                               
|                                                                                  
| SPLITLABELYN Specifies whether the variable labels are also be split             Y       
|              Valid values:  Y or N	                                           
|                                                                                  
| VARSIN       Specifies variables that need to be split                           (Blank)
|              Valid values: A list of SAS variables in &DSETIN, separated by      
|              space                                                               
|                                                                                  
| WIDTHORWIDTH Specifies a variable of width values or width variables. Each       (Blank)
| VARS         variable in &VARSIN should have a value or variables in the list.   
|              The split will happen at the position that can be divided by the    
|              width.                                                              
|              Valid values: A list of positive values or/and variables in         
|              &DSETIN	                                                           
|
|---------------------------------------------------------------------------------------------------
| Output:   1. an output dataset
|
| Global macro variables created:  None
|
| Macros called :
| (@) tu_abort
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_nobs
| (@) tu_putglobals 
| (@) tu_tidyup
|
| Example:  
|    %tu_split(
|       );
|---------------------------------------------------------------------------------------------------
| Change Log :
| 
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|===================================================================================================
| CHANGE LOG:
|
|   -----------------------------------------------------------------------------------------------
|   MODIFIED BY: Yongwei Wang
|   DATE:        04-Jun-2007
|   NEW VERSION: 02
|   MODID:       YW001
|   DESCRIPTION: If the variable value has leading spaces, when wraping the variable, the leading
|                spaces will be kept in the wrapped lines. 
|   -----------------------------------------------------------------------------------------------
|   MODIFIED BY: 
|   DATE:        
|   NEW VERSION: 
|   MODID:       
|   DESCRIPTION: 
|   -----------------------------------------------------------------------------------------------
|=================================================================================================*/

%MACRO tu_split( 
   dsetin             =,       /* Input data set */ 
   dsetout            =,       /* Output data set */                                  
   formats            =,       /* Format specification */                             
   indentadjustyn     =Y,      /* If Y then adjust the indent spaces for PROC REPORT */      
   indentvars         =,       /* A list of numbers of indent spaces */               
   indentsofvars      =,       /* A list of variables needed to be indented */        
   labels             =,       /* Label definitions */                                
   noleftalignvars    =,       /* A list of variables that will not be left aligned */
   numoflinevarsuffix =0,      /* A suffix for output number of lines variable */     
   outvarprefix       =_SP_,   /* A prefix for output variables */                    
   resetvarlengthyn   =Y,      /* If Y then optimise the length of the variable */           
   splitchar          =~,      /* Split character */                                  
   splitlabelyn       =Y,      /* If Y then split variable labels */                
   varsin             =,       /* A list of variables that need to be split */        
   widthorwidthvars   =        /* A list of width values or width variables */        
   );
            
   %***--------------------------------------------------------------------***;
   %***- Write details of macro call to log                               -***;
   %***--------------------------------------------------------------------***;
   
   %LOCAL MacroVersion;
   %LET MacroVersion = 2;

   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
   
   %***--------------------------------------------------------------------***;
   %***- Define local variables                                           -***;
   %***--------------------------------------------------------------------***;
   
   %LOCAL l_i 
          l_indentsofvars 
          l_j  
          l_lengthstatement
          l_lenvar 
          l_maxvarlength 
          l_minwidths 
          l_nobs
          l_nvars 
          l_prefix 
          l_rc 
          l_tmpprefix 
          l_varformats 
          l_widths 
          l_widthvars 
          l_workdata
          ;
   
   %LET l_prefix=_split;   %***- prefix of temporary data set -***;
   %LET l_nvars=0;
      
   %***--------------------------------------------------------------------***;
   %***- Check if any required parameter is blank                         -***;
   %***--------------------------------------------------------------------***;
   
   %IF %nrbquote(&DSETIN) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: parameter DSETIN is blank.;
      %LET g_abort=1;
   %END; 
   %IF %nrbquote(&VARSIN) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: parameter VARSIN is blank.;
      %LET g_abort=1;
   %END;
   %IF %nrbquote(&SPLITCHAR) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: parameter SPLITCHAR is blank.;
      %LET g_abort=1;
   %END;   
   %IF %nrbquote(&widthorwidthvars) EQ  %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: WIDTHORWIDTHVARS is blank.;
      %LET g_abort=1;
   %END; 
   
   %LET resetvarlengthyn=%upcase(&resetvarlengthyn);
   %LET splitlabelyn=%upcase(&splitlabelyn);
   %LET indentadjustyn=%upcase(&indentadjustyn);

   %IF ( %nrbquote(&resetvarlengthyn) NE Y ) AND ( %nrbquote(&resetvarlengthyn) NE N ) %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: value of parameter RESERVARLENGTHYN is invalid.;
      %PUT %str(RTERR)OR: &sysmacroname: the valid value should be Y or N.;
      %LET g_abort=1;
   %END;
   %IF ( %nrbquote(&splitlabelyn) NE Y ) AND ( %nrbquote(&splitlabelyn) NE N ) %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: value of parameter SPLITLABELYN is invalid.;
      %PUT %str(RTERR)OR: &sysmacroname: the valid value should be Y or N.;
      %LET g_abort=1;
   %END;
   %IF ( %nrbquote(&indentadjustyn) NE Y ) AND ( %nrbquote(&indentadjustyn) NE N ) %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: value of parameter INDENTADJUSTYN is invalid.;
      %PUT %str(RTERR)OR: &sysmacroname: the valid value should be Y or N.;
      %LET g_abort=1;
   %END;
   
   %IF &g_abort GT 0 %THEN %GOTO macerr;
         
   %***--------------------------------------------------------------------***;
   %***- Check and adjust parameters                                      -***;
   %***--------------------------------------------------------------------***;
   
   %***- DSETIN -***; 
   %LET l_nobs=%tu_nobs(&DSETIN);   
   %IF &l_nobs LT 0 %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: input data set DSETIN(=%str(&dsetin)) does not exist.;
      %GOTO macerr;
   %END;
   
   %***- DSETOUT -***;                     
   %IF %nrbquote(&DSETOUT) EQ %THEN %DO;
      %LET DSETOUT=&DSETIN;
   %END;
   %ELSE %DO;
      %LET l_rc=%tu_chknames(&DSETOUT, data);
      %IF %nrbquote(&l_rc) EQ -1 %THEN
      %DO;      
         %PUT %str(RTERR)OR: &sysmacroname: DSETOUT(=%str(&dsetout)) is not a valid data set name.;
         %GOTO macerr;
      %END;
   %END;
   
   %***- OUTVARPREFIX -***;                   
   %IF %nrbquote(&outvarprefix) NE %THEN %DO;
      %LET l_rc=%tu_chknames(&outvarprefix, variable);
      %IF %nrbquote(&l_rc) EQ -1 %THEN 
      %DO;         
         %PUT %str(RTERR)OR: &sysmacroname: Variable prefix OUTVARPREFIXDSETOUT(=%str(&outvarprefix)) is not valid.;
         %GOTO macerr;
      %END;
      
      %LET l_i=1;
      %LET l_j=%scan(&VARSIN, &l_i, %str( ));
      %DO %WHILE(%nrbquote(&l_j.) NE );
         %LET l_rc=%tu_chkvarsexist(&DSETIN, &outvarprefix.&l_j );
   
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         
         %IF %nrbquote(&l_rc) EQ %THEN %DO;
            %PUT %str(RTERR)OR: &sysmacroname: variable &l_j are already in input dataset ;
            %PUT %str(RTERR)OR: &sysmacroname: value of parameter OUTVARPREFIX is invalid. ;
            %GOTO macerr;
         %END; 
         
         %LET l_i=%eval(&l_i + 1);
         %LET l_j=%scan(&VARSIN, &l_i, %str( ));    
      %END;  
      
   %END;

   %***- VARSIN -***;                        
   %LET l_rc=%tu_chkvarsexist(&DSETIN, &VARSIN);   
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   %IF %nrbquote(&l_rc) NE %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: variable &l_rc given by VARSIN are not in input dataset;
      %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid. ;
      %GOTO macerr;
   %END;
    
   %***- NUMOFLINEVARSUFFIX -***;                     
   %IF %nrbquote(&numoflinevarsuffix) NE %THEN %DO; 
      %***- Check if NUMOFLINEVARSUFFIX is a valid suffix -***;                                               
      %LET l_rc=%tu_chknames(var&numoflinevarsuffix, variable);
      %IF %nrbquote(&l_rc) EQ -1 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: Variable suffix NUMOFLINEVARSUFFIX(=&NUMOFLINEVARSUFFIX) is not valid.;
         %GOTO macerr;
      %END;
      
      %***- Check if the name with the suffix is already in the data set -***;     
      %LET l_i=1;
      %LET l_j=%scan(&VARSIN, &l_i, %str( ));
      %DO %WHILE(%nrbquote(&l_j.) NE );
         %LET l_rc=%tu_chkvarsexist(&DSETIN, &outvarprefix.&l_j.&numoflinevarsuffix.);
   
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         
         %IF %nrbquote(&l_rc) EQ %THEN %DO;
            %PUT %str(RTERR)OR: &sysmacroname: variable &outvarprefix.&l_j.&numoflinevarsuffix is already in input dataset ;
            %PUT %str(RTERR)OR: &sysmacroname: value of parameter NUMOFLINEVARSUFFIX is invalid. ;
            %GOTO macerr;
         %END; 
         
         %LET l_i=%eval(&l_i + 1);
         %LET l_j=%scan(&VARSIN, &l_i, %str( ));    
      %END;  
    
      %***- Check if the NUMOFLINEVARSUFFIX conflict with VARSIN -***;
      %IF %nrbquote(&outvarprefix) NE %THEN %DO;
         %LET l_i=1;
         %DO %WHILE(%scan(&VARSIN, &l_i, %str( )) NE );
            %LET l_j=1;
            %DO %WHILE(%scan(&VARSIN, &l_j, %str( )) NE );
            
               %IF %upcase(%scan(&VARSIN, &l_i, %str( ))) EQ  %upcase(%scan(&VARSIN, &l_j, %str( ))&numoflinevarsuffix.) 
               %THEN %DO;
                  %PUT %str(RTERR)OR: &sysmacroname: value of parameter NUMOFLINEVARSUFFIX is invalid. It conflics with the output variable names;
                  %GOTO macerr;
               %END; /*End of If */ 
               %LET l_j=%eval(&l_j + 1);
            %END; /* End of Do-While on l_j */
            
            %LET l_i=%eval(&l_i + 1);      
         %END; /* End of Do-While on l_i */
      %END; /* End of If */
      
   %END; /* End of If on &numoflinevarsuffix */
   
   %***- SPLITCHAR -***;                              
   %IF %length(&SPLITCHAR) GT 1 %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: parameter SPLITCHAR has more than one characters.;
      %GOTO macerr;
   %END;   
   
   %LET l_workdata=&DSETIN;
      
   %***--------------------------------------------------------------------***;
   %***- Add the formats and labels to variables.                         -***;            
   %***--------------------------------------------------------------------***;
  
   %PUT %str(RTN)OTE: &sysmacroname: If SAS errors occured in the step below, it is caused by parameter FORMATS or LABELS; 
          
   %LET l_rc=0;
   %IF ( %nrbquote(&formats) NE ) OR ( %nrbquote(&labels) NE ) %THEN %DO;     
      DATA &l_prefix.split1;
         SET &l_workdata;
         %IF %nrbquote(&formats) NE %THEN %DO;
            FORMAT %unquote(&formats);
         %END;
         %IF %nrbquote(&labels) NE %THEN %DO;
            LABEL %unquote(&labels);          
         %END;
       RUN;
       %IF &SYSERR GT 0 %THEN
       %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter LABELS or FORMATS cause SAS error(s);
         %GOTO macerr;
       %END;       
       %LET l_workdata=&l_prefix.split1;
   %END;  /* End Of If on &formats and &labels */
   
   %***--------------------------------------------------------------------***;
   %***- Split the with and width variable given by withorwithvar         -***;                  
   %***--------------------------------------------------------------------***;
   
   %LET l_rc=0;
       
   DATA _NULL_;
      LENGTH strvars strvalues indentsofvars tmpstr varsin widthorwidthvars $32761 var1 var2 $200 rc $8;
      
   
      %***- Verify that indent variables are in parameter VARSIN -***;
      %***- put variable and indent in pairs and same in tmpstr  -***;
      strvalues=upcase(symget('indentsofvars'));
      strvars=upcase(symget('indentvars'));
      rc="0";        
      i=1;
      var1=scan(strvars, 1, " ");
      var2=scan(strvalues, 1, " ");
      tmpstr="";
      
      DO WHILE((var1 NE "") AND (var2 NE ""));
         IF indexw(upcase("&VARSIN"), trim(left(var1))) EQ 0 THEN DO;
            rc='1';
            PUT "RTE" "RROR: &sysmacroname: variable: " var2 "given by INDENTVARS is not in VARSIN." ;      
            CALL SYMPUT('l_rc', trim(left(rc)));
            STOP;
         END;
         
         IF verify(trim(var2), "0123456789") GT 0 THEN DO;
            rc='1';
            PUT "RTE" "RROR: &sysmacroname: non-numeric value is found in INDENTSOFVARS" ;      
            CALL SYMPUT('l_rc', trim(left(rc)));
            STOP;
         END;
   
         i=i+1;
         tmpstr=trim(left(tmpstr))||" "||trim(left(var1))||" "||trim(left(var2));
         var1=scan(strvars, i, " ");
         var2=scan(strvalues, i, " ");
      END;
      
      IF (var1 NE "") OR (var2 NE "") THEN DO;
         rc='1';
         PUT "RTE" "RROR: &sysmacroname: " "number of values given by INDENTVARS=(&indentvars) does not match with the one given by VARSIN(=&varsin)." ;      
         CALL SYMPUT('l_rc', trim(left(rc)));
         STOP;
      END;
    
      %***- Varialbes in NOLEFTALIGNVARS should be in VARSIN -***;   
      %IF %nrbquote(&NOLEFTALIGNVARS) NE %THEN %DO;         
         strvars=upcase(symget('noleftalignvars'));
         i=1;
         var1=scan(strvars, i, " ");
         DO WHILE(var1 NE "");
            IF indexw(upcase("&varsin"), var1) EQ 0 THEN DO;
               rc='1';
               PUT "RTE" "RROR: &sysmacroname: variable " var1 " in NOLEFTALIGNVARS is not in VARSIN." ;      
               CALL SYMPUT('l_rc', trim(left(rc)));
               STOP;           
            END; 
            i=i+1;
            var1=scan(strvars, i, " ");        
         END;
      %END;
 
      %***- Check if WIDTHORWIDTHVARS and VARSIN are in pairs -***;                                                                  
      i=1;
      strvars="";
      strvalues="";
      varsin=upcase(symget('varsin'));
      widthorwidthvars=upcase(symget('widthorwidthvars'));
      var1=scan(varsin, i, " ");
      var2=scan(widthorwidthvars, i, " ");
      indentofvars="";

      DO WHILE((var1 NE "") AND (var2 NE ""));
         IF verify(trim(var2), "0123456789") GT 0 THEN DO;
            strvars=trim(left(strvars))||" "||trim(left(var2));
            strvalues=trim(left(strvalues))||" -";
         END;
         ELSE DO;
            strvalues=trim(left(strvalues))||" "||trim(left(var2));
         END;
         
         indexw=indexw(tmpstr, var1);
         IF indexw GT 0 THEN DO;
            indentsofvars=trim(left(indentsofvars))||" "||scan(substr(tmpstr, indexw), 2);
         END;
         ELSE DO;
            indentsofvars=trim(left(indentsofvars))||" 0";
         END;
         
         i=i+1;
         var1=scan(varsin, i, " ");
         var2=scan(widthorwidthvars, i, " ");      
      END; /* End of Do-While */
      
      IF (var1 NE "") OR (var2 NE "") THEN DO;
         rc='1';
         PUT "RTE" "RROR: &sysmacroname: number of values given by VARSIN does not match with the one given by WIDTHORWIDTHVARS." ; 
         CALL SYMPUT('l_rc', trim(left(rc)));
         STOP;
      END;
      
      i=i-1;                                       
      CALL SYMPUT('l_rc', trim(left(rc)));
      CALL SYMPUT('l_widths', trim(left(strvalues)));
      CALL SYMPUT('l_widthvars', trim(left(strvars)));
      CALL SYMPUT('l_indentsofvars', trim(left(indentsofvars)));
      CALL SYMPUT('l_nvars', trim(left(i)));      
   RUN;   
   
   %IF &l_rc EQ 1 %THEN %GOTO macerr;
   
   %IF %nrbquote(&l_widthvars) NE %THEN %DO;
      %LET l_rc=%tu_chkvarsexist(&l_workdata, &L_WIDTHVARS);
      
      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      %IF %nrbquote(&l_rc) NE %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: variable: &l_rc given by WIDTHORWITHVARS are not in input dataset;
         %GOTO macerr;
      %END;
   %END;
  
   %***--------------------------------------------------------------------***;
   %***- Find a prefix that is not the prefix of variables in DSETIN      -***;                  
   %***--------------------------------------------------------------------***;
          
   DATA _NULL_;
      LENGTH vname prefix _p $200;
      did=open("&l_workdata", 'i');
      nvars=attrn(did, 'NVARS');
      _p="_P_";
      
      IF index(_p, compress(upcase(substr("&outvarprefix", 1, 3)))) EQ 1 THEN
         _p="P__";
          
      inc=1;
      prefix=compress(_p||inc);
      
      DO i=1 TO nvars;
         vname=upcase(varname(did, i));
         
         DO WHILE(index(vname, prefix) EQ 1);
            inc=inc+1;
            prefix=compress(_p||inc);
         END; /* End of do-while */
         
      END; /* End of do-to */
      
      rc=close(did);
      CALL SYMPUT("l_tmpprefix", trim(left(prefix)));
            
   RUN;   
      
   %***--------------------------------------------------------------------***;
   %***- Check if variables in l_widthvars are numeric variables.         -***;   
   %***- Get format of the variables given by VARSIN                      -***;
   %***--------------------------------------------------------------------***;
   
   %LET l_rc=0;
   
   DATA _NULL_;
      IF 0 THEN SET &l_workdata;
      
      LENGTH &l_tmpprefix.f $32761;
        
      %***- Check if variables in l_widthvars are numeric variables. ***;      

      %LET l_i=1;
      %LET l_j=%scan(&l_widthvars, &l_i, %str( ));
      
      &l_tmpprefix.R='0';
      
      %DO %WHILE (%nrbquote(&l_j) NE );
         IF vtype(&l_j) NE 'N' THEN DO;
            &l_tmpprefix.R='1';
            PUT "RTE" "RROR: &sysmacroname: variable: &l_j is not a numeric variable." ;            
         END;
         %LET l_i=%eval(&l_i + 1);
         %LET l_j=%scan(&l_widthvars, &l_i, %str( ));
      %END; /* End of DO-While */
      
      CALL SYMPUT('l_rc', trim(left(&l_tmpprefix.R)));
      
      IF &l_tmpprefix.R EQ '1' THEN STOP;
      
      %***- Get format and label of variables given by VARSIN. ***;      
      &l_tmpprefix.f="";
      
      %DO l_i=1 %TO &l_nvars;
         IF vformat(%scan(&varsin, &l_i, %str( ))) NE "" THEN
            &l_tmpprefix.f=trim(left(&l_tmpprefix.f))||" "||trim(left(vformat(%scan(&varsin, &l_i, %str( )))));
         ELSE
            &l_tmpprefix.f=trim(left(&l_tmpprefix.f))||" -"; 
             
      %END; /* End of Do-To */
      
      CALL SYMPUT('l_varformats', trim(left(&l_tmpprefix.f)));
      STOP;      
      
   RUN;         
   
   %IF &l_rc NE 0 %THEN %GOTO macerr;
   
   %***--------------------------------------------------------------------***;
   %***- Get the minimum value of the width variables.                    -***;            
   %***--------------------------------------------------------------------***;
   
   %IF %nrbquote(&l_widthvars) NE %THEN %DO;         
   
      %LET l_i=1;
      %LET l_j=;
      %DO %WHILE( %SCAN(&l_widthvars, &l_i, %str( )) NE );
         %LET l_j=min(%SCAN(&l_widthvars, &l_i, %str( ))) %str(=) %SCAN(&l_widthvars, &l_i, %str( ));
         %LET l_i=%eval(&l_i + 1);
      %END;
                                    
      PROC SUMMARY data=&l_workdata(KEEP=&l_widthvars);
         VAR &l_widthvars;
         OUTPUT out=&l_tmpprefix.minwidth(drop=_TYPE_ _FREQ_) &l_j;
      RUN;
      
      DATA _NULL_;
         SET &l_tmpprefix.minwidth;
         ARRAY &l_tmpprefix.a {*} _NUMERIC_;
         LENGTH &l_tmpprefix.l varsin $32761 var $200;
         
         varsin=upcase("%nrbquote(&varsin)");
         &l_tmpprefix.l="";
         
         DO &l_tmpprefix.i=1 TO &l_nvars;
            var=scan(varsin,  &l_tmpprefix.i, " ");
          
            IF indexw("&l_widthvars", var) GT 0 THEN DO;
               DO &l_tmpprefix.j=1 TO dim(&l_tmpprefix.a);
                  IF upcase(vname(&l_tmpprefix.a{&l_tmpprefix.j})) EQ var THEN DO;
                     &l_tmpprefix.l=trim(left(&l_tmpprefix.l))||" "||trim(left(&l_tmpprefix.a{&l_tmpprefix.j}));
                     LEAVE;
                  END;
               END; /* End of Do-To loop on &l_tmpprefix.j */
            END;
            ELSE DO;
               &l_tmpprefix.l=trim(left(&l_tmpprefix.l))||" "||trim(left("%scan(&l_widths, &l_i, %str( ))"));
            END;             
         END; /* End of Do-To loop on &l_tmpprefix.i */   
        
         CALL SYMPUT('l_minwidths', trim(left(&l_tmpprefix.l)));
      RUN;
   %END; /* End of If on &l_widthvars */
   %ELSE %DO;
      %LET l_minwidths=&l_widths.;
   %END;
   
   %***--------------------------------------------------------------------***;
   %***- Get the length of the formated value.                            -***;            
   %***--------------------------------------------------------------------***;
   
   %LET l_rc=0; 
   DATA _NULL_;
      IF 0 THEN SET &l_workdata(obs=1);
      LENGTH &l_tmpprefix.l $32761;
      &l_tmpprefix.l="";
      &l_tmpprefix.m =1;
     
      %DO l_i=1 %TO &l_nvars;
         %IF %SCAN(&l_varformats, &l_i, %str( )) NE %str(-) %THEN %DO;
            &l_tmpprefix.a&l_i=trim(put(%SCAN(&VARSIN, &l_i, %str( )), 
                                    %SCAN(&l_varformats, &l_i, %str( ))));
         %END;
         %ELSE %DO;
            &l_tmpprefix.a&l_i=trim(%SCAN(&VARSIN, &l_i, %str( )));
         %END;
         
         /* YW001: Increased the length */
         &l_tmpprefix.i=%scan(&l_indentsofvars, &l_i, %str( )) + 1;
         &l_tmpprefix.w=%scan(&l_minwidths, &l_i, %str( ));
         &l_tmpprefix.w=&l_tmpprefix.w - &l_tmpprefix.i;
         
         IF &l_tmpprefix.w LT 1 THEN DO;
            PUT "RTE" "RROR: &sysmacroname: given width of variable: %SCAN(&VARSIN, &l_i, %str( )) is too small" ;
            CALL SYMPUT('l_rc', '1');
            STOP;
         END;
         
         &l_tmpprefix.i=&l_tmpprefix.i + 10;
         &l_tmpprefix.v=vlength(&l_tmpprefix.a&l_i) ;  
         &l_tmpprefix.v=&l_tmpprefix.v + ceil(&l_tmpprefix.v / &l_tmpprefix.w ) * &l_tmpprefix.i;
         
         IF &l_tmpprefix.v GT 32761 THEN  &l_tmpprefix.v=32761;
         IF &l_tmpprefix.v LT 5 THEN  &l_tmpprefix.v=5;
  
         &l_tmpprefix.m=max(&l_tmpprefix.m, &l_tmpprefix.v);
         &l_tmpprefix.l=trim(left(&l_tmpprefix.l))||" "||trim(left(&l_tmpprefix.v));
         
      %END; /* End of Do-To loop */
      
      CALL SYMPUT('l_maxvarlength', trim(left(&l_tmpprefix.m)));
      CALL SYMPUT('l_varlengthes', trim(left(&l_tmpprefix.l)));
      STOP;
   RUN;   
   
   %IF &l_rc NE 0 %THEN %GOTO macerr;
   
   %***--------------------------------------------------------------------***;
   %***- Add split character to the variable values and labels. Calculate -***;            
   %***- the length of the variables.                                     -***;
   %***--------------------------------------------------------------------***;
   
   %IF &resetvarlengthyn = Y %THEN %DO;
      %DO l_i=1 %TO &l_nvars;
         %LOCAL l_label&l_i.;
      %END;
   %END;
  
   %LET l_rc=0;   
   DATA &l_prefix.split2;
      %IF &l_nobs EQ 0 %THEN %DO;
         IF 0 THEN
      %END;
      SET &l_workdata end=&l_tmpprefix.end;   
      
      %***- Add label to the variables that are used to save number of lines for a value -***;
      %IF %nrbquote(&numoflinevarsuffix) NE %THEN %DO;
         LABEL
         %DO l_i=1 %TO &l_nvars;
            &l_tmpprefix.n&l_i="Num of lines in variable &outvarprefix.%SCAN(&varsin, &l_i, %str( ))"
         %END; /* End of Do-To loop */
         ;
      %END; /* End of If */
         
      %***- Defined the length of new converted variables -***;    
      LENGTH
      %DO l_i=1 %TO &l_nvars;
         &l_tmpprefix.a&l_i $%SCAN(&l_varlengthes, &l_i, %str( ))
      %END;
      ;
      
      LENGTH  &l_tmpprefix.o &l_tmpprefix.v  &l_tmpprefix.s  $&l_maxvarlength.;   
      %***- v: current variable value.     s: temporary string. o: converted value            -***;
      %***- f: left align flag.            n: number of lines   e: defined width of the value.-***;
      %***- x: temporary numeric variable.                                                    -***;             
      DROP  &l_tmpprefix.v  &l_tmpprefix.o  &l_tmpprefix.s  
            &l_tmpprefix.f  &l_tmpprefix.n  &l_tmpprefix.e  
            &l_tmpprefix.d  &l_tmpprefix.x ;      
            
      %IF %nrbquote(&outvarprefix) EQ %THEN %DO;                
         DROP &VARSIN;
      %END;
      
      %***- Define variables to save the maximum length of new converted variables -***;
      %***- They will be used to redefine the length of those variables -***;
      %IF &resetvarlengthyn = Y %THEN %DO;      
         RETAIN 
         %DO l_i=1 %TO &l_nvars;
            &l_tmpprefix.i&l_i 
         %END; /* End of Do-To Loop */
         0;
         DROP &l_tmpprefix.i: ;     
      %END; /* End of If */
      
      %***- Define variables to save the maximum length of the width variables -***;  
      %***- They will be used to decide the width of the labels -***;
      %IF &splitlabelyn = Y %THEN %DO;
         RETAIN 
         %DO l_i=1 %TO &l_nvars;
            &l_tmpprefix.l&l_i
         %END; /* End of Do-To Loop */
         0;         
         DROP &l_tmpprefix.l:;   
      %END; /* End of If */

      %***- Loop over variables to add split characters to it -***;
      %LET l_j=0;    
      %DO l_i=1 %TO &l_nvars;
         %***- apply formats to the variables first -***;
         %IF %SCAN(&l_varformats, &l_i, %str( )) NE %str(-) %THEN %DO;
            &l_tmpprefix.a&l_i=put(%SCAN(&VARSIN, &l_i, %str( )), 
                                   %SCAN(&l_varformats, &l_i, %str( )));
         %END;
         %ELSE %DO;
            &l_tmpprefix.a&l_i=%SCAN(&VARSIN, &l_i, %str( ));
         %END; /* End of IF for %SCAN(&l_varformats, &l_i, %str( )) NE %str(-) */

         &l_tmpprefix.f='Y';     
         %IF %nrbquote(&noleftalignvars) NE %THEN %DO;
            IF indexw(upcase("&noleftalignvars"), upcase("%scan(&VARSIN, &l_i, %str( ))")) GT 0 THEN DO;
               &l_tmpprefix.f='N';
            END;
         %END;
                  
         &l_tmpprefix.d=%SCAN(&l_indentsofvars, &l_i, %str( ));                  
         &l_tmpprefix.v=&l_tmpprefix.a&l_i;
         &l_tmpprefix.a&l_i="";
         
         %LET l_lenvar=%SCAN(&l_widths, &l_i, %str( ));
         
         %IF %nrbquote(&l_lenvar) EQ %nrstr(-) %THEN %DO;
            %LET l_j=%eval(&l_j + 1);
            %LET l_lenvar=%SCAN(&l_widthvars, &l_j, %str( ));
            
            %IF &splitlabelyn = Y %THEN %DO;
               &l_tmpprefix.l&l_i=max(&l_tmpprefix.l&l_i, &l_lenvar);
            %END; /* End of IF for &splitlabelyn = Y */
         %END;
         %ELSE %IF &splitlabelyn = Y %THEN %DO;
            &l_tmpprefix.l&l_i=&l_lenvar;
         %END; /* End of IF for %nrbquote(&l_lenvar) EQ %nrstr(-) */
         
         &l_tmpprefix.e=&l_lenvar;
         
         LINK SPLITIT;
         
         %IF %nrbquote(&numoflinevarsuffix) NE %THEN %DO;
            &l_tmpprefix.n&l_i=&l_tmpprefix.n;
         %END;
         
         &l_tmpprefix.a&l_i=trim(&l_tmpprefix.o);
         
         %IF &resetvarlengthyn = Y %THEN %DO;
            &l_tmpprefix.i&l_i=max(&l_tmpprefix.i&l_i, length(&l_tmpprefix.a&l_i));
         %END;   
         
      %END; /* End of Do-To Loop */
      
      %IF &splitlabelyn = Y %THEN %DO;
         IF &l_tmpprefix.end THEN DO;
            %DO l_i=1 %TO &l_nvars;
               &l_tmpprefix.v=vlabel(%scan(&varsin, &l_i, %str( )));
               &l_tmpprefix.e=&l_tmpprefix.l&l_i;
               &l_tmpprefix.f='Y';
               &l_tmpprefix.d=%SCAN(&l_indentsofvars, &l_i, %str( ));  
               LINK SPLITIT;
               CALL  SYMPUT("l_label&l_i", trim(&l_tmpprefix.o));
            %END; /* End of Do-To Loop */        
         END;
      %END; /* End of If */
      
      %IF &resetvarlengthyn = Y %THEN %DO;
         LENGTH &l_tmpprefix.l $32761;
         DROP &l_tmpprefix.l;
         IF &l_tmpprefix.end THEN DO; 
            &l_tmpprefix.l="";
            %DO l_i=1 %TO &l_nvars;
               &l_tmpprefix.l=trim(left(&l_tmpprefix.l))||" "||trim(left("&l_tmpprefix.a&l_i"))||" $"||
                              trim(left(&l_tmpprefix.i&l_i));
            %END; /* End of Do-To Loop */
         
            CALL SYMPUT('l_lengthstatement', trim(left(&l_tmpprefix.l)));
         END;
      %END; /* End of If */
      
      RETURN;
      
      SPLITIT:
         %***- Add the split character to a variable -***;
         %***- input parameter:  &l_tmpprefix.v:variable name,   &l_tmpprefix.e: width            -***;
         %***-                   &l_tmpprefix.v:indent flag,     &l_tmpprefix.d: number of indent.-***;
         %***- output parameter: &l_tmpprefix.o:variable value.  &l_tmpprefix.n: number of lines  -***;
         
         &l_tmpprefix.o="-";
         &l_tmpprefix.n=1; 
         
         IF &l_tmpprefix.e - &l_tmpprefix.d LT 2 THEN DO;
             PUT "RTE" "RROR: &sysmacroname: at least one specified width is too small to add the split char in";
             CALL SYMPUT('l_rc', '1');
             STOP;
         END;
                                                       
         &l_tmpprefix.e=&l_tmpprefix.e - &l_tmpprefix.d;
         /* YW001: Calculate leading space &l_tmpprefix.y */
         &l_tmpprefix.y=0;
         IF &l_tmpprefix.f = "Y" THEN
            &l_tmpprefix.v=left(&l_tmpprefix.v);
         ELSE DO;
            &l_tmpprefix.y=length(&l_tmpprefix.v) - length(left(&l_tmpprefix.v));
            IF &l_tmpprefix.e - &l_tmpprefix.d - &l_tmpprefix.y LT 1 THEN
            DO;               
               PUT "RTN" "OTR: &sysmacroname: at least one specified width is too small to keep the leading spaces";
               &l_tmpprefix.y=0;
            END;
         END;
         
         DO WHILE (( length(&l_tmpprefix.v) GT &l_tmpprefix.e )
            /* Fix the bug for the last line */
            %IF &indentadjustyn EQ Y %THEN %DO;
               or (( &l_tmpprefix.n gt 1 ) and ( &l_tmpprefix.d GT 0 ) and 
               ( length(&l_tmpprefix.v) EQ &l_tmpprefix.e ))
            %END;
            );
   
            %***- Find the last space (or current split character) in the text string. -***;  
            &l_tmpprefix.s=substr(&l_tmpprefix.v, 1, &l_tmpprefix.e + 1);  
            substr(&l_tmpprefix.s, &l_tmpprefix.e + 2)='a'; 
            &l_tmpprefix.s=left(reverse(&l_tmpprefix.s));      
            &l_tmpprefix.s=substr(&l_tmpprefix.s, 2);           
            
            &l_tmpprefix.x=index(&l_tmpprefix.s, "&splitchar.");            
            IF &l_tmpprefix.x GT length(&l_tmpprefix.s) THEN &l_tmpprefix.x=0;
            IF &l_tmpprefix.x LE 0 THEN &l_tmpprefix.x=index(&l_tmpprefix.s, " ");                
            IF &l_tmpprefix.x GT length(&l_tmpprefix.s) THEN &l_tmpprefix.x=0;     
         
            %*** If no space found, use the whole block of text. -***;      
            IF &l_tmpprefix.x EQ 0 THEN DO;
         
               IF &l_tmpprefix.d EQ 0 THEN     
                  &l_tmpprefix.o=trim(&l_tmpprefix.o) || 
                                 substr(&l_tmpprefix.v, 1, &l_tmpprefix.e) ||
                                 "&splitchar.";
               ELSE
                   &l_tmpprefix.o=trim(&l_tmpprefix.o) ||
                                  repeat(' ', &l_tmpprefix.d -1)|| 
                                  substr(&l_tmpprefix.v, 1, &l_tmpprefix.e) ||
                                  "&splitchar.";              
                                    
               &l_tmpprefix.v=substr(&l_tmpprefix.v, &l_tmpprefix.e + 1 );
            END; 
              
            %***- If a space is found then use the text up to that space. -***;            
            ELSE DO;
               IF &l_tmpprefix.x LE &l_tmpprefix.e THEN DO;
                  IF &l_tmpprefix.d EQ 0 THEN
                     &l_tmpprefix.o=trim(&l_tmpprefix.o) || 
                                     substr(&l_tmpprefix.v, 1, &l_tmpprefix.e - &l_tmpprefix.x + 1) ||
                                     "&splitchar." ; 
                  ELSE
                      &l_tmpprefix.o=trim(&l_tmpprefix.o) || 
                                     repeat(' ', &l_tmpprefix.d -1)||
                                     substr(&l_tmpprefix.v, 1, &l_tmpprefix.e - &l_tmpprefix.x + 1) ||
                                     "&splitchar." ; 
                 
               END;
               ELSE DO;
                  IF &l_tmpprefix.d EQ 0 THEN
                     &l_tmpprefix.o=trim(&l_tmpprefix.o) || "&splitchar." ; 
                  ELSE
                     &l_tmpprefix.o=trim(&l_tmpprefix.o) || repeat(' ', &l_tmpprefix.d - 1) || "&splitchar." ;
               END; /* End of If for &l_tmpprefix.x LE &l_tmpprefix.e */  
               
               &l_tmpprefix.v=substr(&l_tmpprefix.v, &l_tmpprefix.e - &l_tmpprefix.x + 3 );     
            END; /* End of If for &l_tmpprefix.x EQ 0 */
            
            IF &l_tmpprefix.f = "Y" THEN
               &l_tmpprefix.v=left(&l_tmpprefix.v);             
                       
            &l_tmpprefix.n=&l_tmpprefix.n + 1;
            
            /* YW001: Add leading spaces */
            IF &l_tmpprefix.n eq 2 THEN DO; 
               &l_tmpprefix.d=&l_tmpprefix.d + &l_tmpprefix.y;
               &l_tmpprefix.e=&l_tmpprefix.e - &l_tmpprefix.y;
            END;     
         END;  /* End of Do-While Loop */ 
      
         %***- Add the remaining text to the new variable. -***;
         IF &l_tmpprefix.d EQ 0 THEN
            &l_tmpprefix.o=trim(&l_tmpprefix.o) || &l_tmpprefix.v ;
         ELSE DO;
            %IF &indentadjustyn EQ Y %THEN %DO;
               IF &l_tmpprefix.o EQ "-" THEN 
                  &l_tmpprefix.o=trim(&l_tmpprefix.o) ||repeat(' ', &l_tmpprefix.d - 1) || &l_tmpprefix.v ;
               ELSE 
                  &l_tmpprefix.o=trim(&l_tmpprefix.o) ||repeat(' ', &l_tmpprefix.d) || &l_tmpprefix.v ;
            %END;
            %ELSE %DO;
               &l_tmpprefix.o=trim(&l_tmpprefix.o) ||repeat(' ', &l_tmpprefix.d - 1) || &l_tmpprefix.v ;
            %END; /* End of If for &indentadjustyn EQ Y */
         END; /* End of If for &l_tmpprefix.d EQ 0 */
            
         &l_tmpprefix.o=substr(&l_tmpprefix.o, 2);
         
      RETURN;
     
   RUN;
 
   %IF &l_rc NE 0 %THEN %GOTO macerr;
   %LET l_workdata=&l_prefix.split2;
   
   %***--------------------------------------------------------------------***;
   %***- Rename the variable, redefine the length of the variablese and   -***;
   %***- create output data set.                                          -***;            
   %***--------------------------------------------------------------------***;   
   
   DATA &DSETOUT(LABEL="Output Data Set from TU_SPLIT");
      %***- Reset the length of the output variables -***;
      %IF &resetvarlengthyn = Y %THEN %DO;
         LENGTH &l_lengthstatement ;
      %END;
      SET &l_workdata;
      
      %***- Relabel the output variables -***;
      %IF &splitlabelyn = Y %THEN         
         %DO l_i=1 %TO &l_nvars;
             LABEL &l_tmpprefix.a&l_i="%superq(l_label&l_i)";
         %END;  /* End of Do-To Loop */                            
      
      %***- Rename the line variables -***;                                     
      %IF %nrbquote(&numoflinevarsuffix) NE %THEN %DO;
         RENAME
         %DO l_i=1 %TO &l_nvars;
              &l_tmpprefix.n&l_i=&outvarprefix.%SCAN(&VARSIN, &l_i, %str( ))&numoflinevarsuffix
         %END; /* End of Do-To Loop */           
         ;
      %END;  /* End of If */    
         
      %***- Rename the output variables -***;
      RENAME
      %DO l_i=1 %TO &l_nvars;
         &l_tmpprefix.a&l_i=&outvarprefix.%SCAN(&VARSIN, &l_i, %str( ))         
      %END;
      ;  
      
      %IF &l_nobs EQ 0 %THEN %DO;
         IF 0;
      %END;      
   RUN;    
         
   %GOTO endmac;

%MACERR:
   %LET g_abort=1;

   %PUT;
   %PUT %str(RTN)OTE: ------------------------------------------------------------;
   %PUT %str(RTN)OTE: &sysmacroname completed with error(s);
   %PUT %str(RTN)OTE: ------------------------------------------------------------;
   %PUT;
   
   %tu_abort();

%ENDMAC:

   %***---------------------------------------------------------------------***;
   %***- Clear temporary data set and fields.                              -***;
   %***---------------------------------------------------------------------***;

   %tu_tidyup(
      rmdset=&l_prefix.:,
      glbmac=none
      );
   
%MEND tu_split;

