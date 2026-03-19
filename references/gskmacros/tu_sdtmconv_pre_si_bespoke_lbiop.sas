/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_lbiop
|
| Macro Version/Build:  1 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Ashwin V)
|
| Date:                 11-Feb-2011 
|
| Macro Purpose:        Pre-process LBIOPSY data according to mapping specs
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                  DESCRIPTION                                  DEFAULT           
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
| %tu_sdtmconv_pre_si_bespoke_lbiop
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : 
| Date of Modification        : 
| New Version/Build Number    : 
| Description for Modification: 
| Reason for Modification     : 
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_lbiop(
); 

%if %sysfunc(exist(pre_sdtm.lbiopsy)) %then %do;
   
   %if %tu_chkvarsexist(pre_sdtm.lbiopsy, BIOPSZ BIOPSZU) eq %then %do;
        
        data size (drop=LPORRSSP );
            set pre_sdtm.lbiopsy (where=(BIOPSZ>0));
        run;

        data size ;
           set size(drop=LPORRSCD 
            %if %tu_chkvarsexist(pre_sdtm.lbiopsy, LPSEQ ) eq %then %do;
              LPSEQ
            %end; 
                   );
             LPTESTCD ='BIOPSZ';
             LPTEST = left("%tu_varattr(pre_sdtm.lbiopsy,biopsz,varlabel)");
             LPORRES = left(input(biopsz,best.));           
        run;

        /* We only need one size per subject-visit, not one per test per subject-visit*/ 
        proc sort data=size nodupkey;
            by _all_;
        run;

        data pre_sdtm.lbiopsy ;
            set pre_sdtm.lbiopsy(drop=BIOPSZU) size;
        run;
   %end;                
%end;

%mend tu_sdtmconv_pre_si_bespoke_lbiop;
