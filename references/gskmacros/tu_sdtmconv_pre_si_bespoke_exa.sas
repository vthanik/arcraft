/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_exa
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Ashwin V
|
| Date:                 5-Aug-2011
|
| Macro Purpose:        Pre-process EXACERB data according to mapping specs,
|                       in EXACERB dataset some times subject has both EBWD and  HSPEXB 
|                       populated in such a case ,This needs pre processing.
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
|
|
|
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_exa
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  
| Date of Modification:         
| New Version/Build Number:     
| Description for Modification: 
| Reason for Modification:      
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_exa(
);
/*in EXACERB dataset some times subject has both EBWD and  HSPEXB 
populated in such a case ,This needs pre processing adding if we get a 
study */

 %IF %sysfunc(exist(pre_sdtm.EXACERB)) %then %do;
	%if %length(%tu_chkvarsexist(pre_sdtm.exacerb,EBWD HSPEXB)) eq 0 %then %do;
		data pre_sdtm.EXACERB ;
			length CEACNOT1 $200;
			length CEACNOT2 $200;
			length CEACNOTH $200;
			set pre_sdtm.EXACERB;
			label  CEACNOT1 = 'Subject withdrawn due to exacerbation?' 
				   CEACNOT2 = 'Subject hospitalized due to exacerbation';

			 if EBWD = 'Y' and  HSPEXB ='Y' then do;
				CEACNOT1 = 'Subject withdrawn';
				CEACNOT2 ='Subject hospitalised';
				EBWD =  '';
				HSPEXB = '';
				CEACNOTH = "MULTIPLE";
			 end;
		run; 
	%end;
%end;
%mend tu_sdtmconv_pre_si_bespoke_exa;
