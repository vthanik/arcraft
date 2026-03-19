/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_chd
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:          Ashwin Venkat
|
| Date:                 05-Sep-2011
|
| Macro Purpose:        Pre-process CHDPOT data according to mapping specs
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
| %tu_sdtmconv_pre_si_bespoke_mh
|
|*******************************************************************************
| Change Log:
|
| Modified By                  : Bruce Chambers                  
| Date of Modification         : 15Oct2012        
| New Version/Build Number     : 2/1    
| Reference                    : BJC001
| Description for Modification : Update sys_register to also supply source dataset name
| Reason for Modification      : Ensure full traceability available.     
|
| Modified By                  : Bruce Chambers                  
| Date of Modification         : 11Jul2013        
| New Version/Build Number     : 3/1    
| Reference                    : BJC002
| Description for Modification : Correct char dups to be $9 to match IDSL standard
| Reason for Modification      : Ensure correct partial date processing   
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_chd(
);

 %if %sysfunc(exist(pre_sdtm.chdpot)) %then %do;
    %if %length(%tu_chkvarsexist(pre_sdtm.chdpot, chdmnfdt chdmnfd_ chdstdt chdstd_,Y )) gt 0  %then %do; 
        %let chdmnfdt = %tu_chkvarsexist(pre_sdtm.chdpot, chdmnfdt,Y);
        %let chdmnfd_ = %tu_chkvarsexist(pre_sdtm.chdpot, chdmnfd_,Y);
        %let chdstdt = %tu_chkvarsexist(pre_sdtm.chdpot,chdstdt,Y);
        %let chdstd_ = %tu_chkvarsexist(pre_sdtm.chdpot,chdstd_,Y);
         data pre_sdtm.chdpot(drop = x9term startdt startd_ &chdmnfdt &chdmnfd_ &chdstdt &chdstd_) 
              pre_sdtm.chdpotx9(drop = &chdmnfdt &chdmnfd_ &chdstdt &chdstd_); 
            length x9term  $200;
            format startdt date9.;
			/* BJC002: set $9 as char dup length */
            length startd_ $9.;
            set pre_sdtm.chdpot;
                output pre_sdtm.chdpot;
                %if %length(&chdmnfdt) ne 0 or %length(&chdmnfd_) ne 0 %then %do;
                    if not missing(chdmnfdt) or not missing (chdmnfd_) then do;
                        x9term = 'Final menses';
                        startdt = chdmnfdt;
                        startd_ = chdmnfd_;
                        output pre_sdtm.chdpotx9;
                    end;
                %end;
                %if %length(&chdstd_) ne 0 or %length(&chdstdt) ne 0 %then %do;
                    if not missing(chdstdt) or not missing (chdstd_) then do;
                        x9term = 'Became Sterile';
                        startdt = chdstdt  ;
                        startd_ = chdstd_;
                        output pre_sdtm.chdpotx9;
                    end;
                %end;
            
         run;
		 
        /* BJC001: update register statement to also provide source dataset name for define.xml traceability */
        %tu_sdtmconv_sys_register(CHDPOTX9,CHDPOT);

     %end;   
 %end;
%mend tu_sdtmconv_pre_si_bespoke_chd;
