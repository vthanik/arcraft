/*--------------------------------------------------------------------------+
| Macro Name    : tu_stackvar.sas
|
| Macro Version : 1
|
| SAS version   : SAS v8.2
|
| Created By    : Anup R. Patel
|
| Date          : 18-Jun-2003
|
| Macro Purpose : To stack two or more variables together, separating each
|                 variable with the specified seporator and/or split 
|                 character
|
| Macro Design  : Statement
|
| Input Parameters :
|
| NAME           DESCRIPTION                              DEFAULT
|
| DSETIN         Name of dataset being read (Req)         None
|
| SEPC           Specifies the separator character (Req)  /
|
| SPLITC         Specifies the split character (Req)      ~
|
| VARSIN         Specifies a list of variables to be      None
                 stacked (Req)
|
| FORMATS        Specifies overriding formats to be use   None
|                when writing the variable to the 
|                stacked string (Opt)    
|                
| VAROUT         Specifies the name of the stacked        None
|                variable (Req)
|
| VAROUTLENGTH   Specifies the length of the stacked      200
|                variable (Opt)
|
| VARLABEL       Specifies the label of the stacked       None
|                variable (opt)
|
|
| Output: SAS code which can be used within a datastep to stack two or
|         more variables
|
| Global macro variables created: None
|
|
| Macros called :
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_maclist
|(@) tu_chkvartype
|
| Example:
| %tu_stackvar(dsetin       = demog,
|              sepc         = /,
|              splitc       = ~,
|              varsin       = age sex race,
|              formats      = sex=sexfmt trtcd=trtfmt,
|              varout       = agesexrac,
|              varoutlength = 60,
|              varlabel     = Age/#Sex/#Race
|              );
|
|
| **************************************************************************
| Change Log :
|
| Modified By : Anup R Patel
| Date of Modification : 25-Jun-2003
| New Version Number : 1/2
| Modification ID :
| Reason For Modification : Corrected prompted by SCR.
|                           Update made due to change in unit specification 
|
|
| Modified By : Anup R Patel
| Date of Modification : 15-Jul-2003
| New Version Number : 1/3
| Modification ID :
| Reason For Modification : Corrected prompted by UTC testing.
|
+----------------------------------------------------------------------------*/

%MACRO tu_stackvar(dsetin       = ,    /* Input dataset */
                   sepc         = /,   /* Separator character */
                   splitc       = ~,   /* Split character */
                   varsin       = ,    /* List of variables to be stacked */
                   formats      = ,    /* List of variables with formats */ 
                   varout       = ,    /* Name of stack variable */
                   varoutlength = 200, /* Length of stack variable */
                   varlabel     =      /* Label of stack variable */
                   );



  %LOCAL macroversion;
  %LET macroversion = 1;
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals;


  /* Paramater Validation */

  %LOCAL i j k l m n dummy addone;
  
    /* Check that input dataset has been specified */
  
  %IF %LENGTH(&dsetin) EQ 0 %THEN
  %DO;
      %PUT RT%STR(ERROR): &sysmacroname: No input dataset has been specified; 
      %LET g_abort = 1;
      %PUT RT%STR(ERROR): &sysmacroname: The value of g_abort is being set to &g_abort; 
  %END;

  /* Check that input dataset specified exists */
  
  %ELSE %IF %SYSFUNC(EXIST(&dsetin))=0 %THEN
  %DO;
      %PUT RT%STR(ERROR): &sysmacroname: Input dataset specified does not exist; 
      %LET g_abort = 1;
      %PUT RT%STR(ERROR): &sysmacroname: The value of g_abort is being set to &g_abort; 
  %END;

  /* Check that list of variables to be stacked has been specified */
  
  %IF %LENGTH(&varsin) EQ 0 %THEN
  %DO;
      %PUT RT%STR(ERROR): &sysmacroname: List of variables to be stacked has not been specified; 
      %LET g_abort = 1;
      %PUT RT%STR(ERROR): &sysmacroname: The value of g_abort is being set to &g_abort; 
  %END;
  
  /* Check that name stack variable has been specified */
  
  %IF %LENGTH(&varout) EQ 0 %THEN
  %DO;
      %PUT RT%STR(ERROR): &sysmacroname: Name of stack variable has not been specified; 
      %LET g_abort = 1;
      %PUT RT%STR(ERROR): &sysmacroname: The value of g_abort is being set to &g_abort; 
  %END;

  /* Check that length of stack variable specified is a valid numeric */                                                         
                                                         
  %DO i = 1 %to %EVAL(%LENGTH(&varoutlength));
     %LET string = %SUBSTR(&varoutlength,&i,1);
     %IF %SYSFUNC(INDEXC(&string,0123456789)) = 0 %THEN
        %LET dummy = 1;
  %END;
  
  %IF &dummy EQ 1 %THEN
  %DO;
      %PUT RT%STR(ERROR): &sysmacroname: Invalid length of stack variable has been specified : &varoutlength; 
      %LET g_abort = 1;
      %PUT RT%STR(ERROR): &sysmacroname: The value of g_abort is being set to &g_abort; 
  %END;
  
  /* Begining of normal processing */
  
  %IF &g_abort EQ 0 %THEN 
  %DO;  

      /* Create macro variables for each stack variable */


      %tu_maclist(string  = &varsin,
                  delim   = %STR(' '),
                  prefix  = stack,
                  cntname = stack_no
                  );

      /* Create macro variables for the formats associated to the stack variable */
      /* Overriding any formats that are specified in the formats parameter */

      %IF %LENGTH(&formats) NE 0 %THEN 
      %DO;
  
          %tu_maclist(string  = &formats,
                      delim   = %STR(' '),
                      prefix  = stackformat,
                      cntname = stackformat_no
                      );
    
      %END;
  
      %DO j=1 %TO %EVAL(&stack_no);
      
         %LOCAL stacktype&j stackfmt&j;
         %LET stacktype&j = %tu_chkvartype(&dsetin,&&stack&j);
         %LET stackfmt&j  = VFORMAT(&&stack&j);

         %IF %LENGTH(&formats) NE 0 %THEN 
         %DO;
     
             %DO k=1 %TO %EVAL(&stackformat_no) %BY 2;
        
                %IF &&stackformat&k EQ &&stack&j %THEN
                %DO;
                    %LET addone        = %EVAL(&k+1);
                    %LET stackfmt&j    = &&stackformat&addone; 
                    %LET stacktype&j   =  ; 
                %END;
          
             %END;

         %END;

      %END;

      /* Set length of stacked variable                                                */
      /* Construct stack variable using stack variables and split characters specified */
      /* Add variable label if specified                                               */

      LENGTH &varout $&varoutlength..;

      &varout=TRIM(LEFT(PUT&stacktype1(&stack1,&stackfmt1)))
              %DO l=2 %TO &stack_no;
                 ||"&sepc&splitc"||TRIM(LEFT(PUT&&stacktype&l(&&stack&l,&&stackfmt&l)))
              %END; 
              ;

      %IF %LENGTH(&varlabel) NE 0 %THEN
         LABEL &varout = "&varlabel";
      ;

      /* Delete all global macro variables created by macro */  
    
      %DO m=1 %TO %EVAL(&stack_no);
         %PUT Deleting stack&m (Global macro variable);
         %SYMDEL stack&m;
      %END;
    
      %IF %LENGTH(&formats) NE 0 %THEN 
      %DO;
          %DO n=1 %TO %EVAL(&stackformat_no);
             %PUT Deleting stackformat&n (Global macro variable);
             %SYMDEL stackformat&n;
          %END;
      %END;

  %END;
  
%MEND;