/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_sr
|
| Macro Version/Build:  1 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Ashwin Venkat
|
| Date:                 5 May 2011
|
| Macro Purpose:        subrace pre processing
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
| (@)tu_sdtmconv_sys_message
| (@)tu_sdtmconv_sys_error_check
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_sr
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 
| Date of Modification:          
| New Version/Build Number: 	   
| Reference:                     
| Description for Modification: 
| Reason for Modification:       
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_sr(
); 

* check if  is present before starting this code step **;
%if %sysfunc(exist(pre_sdtm.demo)) %then %do;
   /*copy subrace to pre_sdtm */
   data subrace; 
        set combine.subrace
        %if %length(&subset_clause) >= 1 %then %do;
             (&subset_clause);
        %end;;   
    run;

   /*if SUBRACE decode is not present then create  SUBRACE*/
    /* If SI is used then decode the coded items */
   %if %tu_chkvarsexist(subrace,subrace) ne %then %do;   
   %tu_decode(
        dsetin  = subrace,
        dsetout = subrace,
        dsplan  = ,
        formatnamesdset = FMTVARS
       );
    %end;

    proc sort data = subrace;
        by subjid subraccd;
    run;

	data subrace;
		set subrace;
        length idlab $20;
        length idval $10;
		by subjid subraccd;
		if first.subjid then do;
			subrcode = 1; 
            idval = compress("SUBRACE" || subrcode);
            idlab = "SUBRACE " || compress(subrcode);
        end;
		else do;
            subrcode+1;
            idval = compress("SUBRACE" || subrcode);
            idlab = "SUBRACE " || compress(subrcode);
        end;
	run;

    
	proc transpose data = subrace out = trans_subrace;
		by subjid ;
		var subrac;
        id idval;
        idlabel idlab;
	run;

/* merging with demo dataset */
    proc sort data = pre_sdtm.demo ;
        by subjid;
    run;

    data pre_sdtm.demo ;
        merge pre_sdtm.demo(in =indemo) trans_subrace;
        by subjid;
        if indemo;
    run;
	
   /* Delete pre_sdtm.subrace so it doesnt appear on outputs and confuse - vars appear as dropped in MSA*/   
   proc sql;
    delete from view_tab_list where basetabname='SUBRACE';
   quit;
   
   proc datasets memtype=data library=pre_sdtm nolist;
                delete subrace;
   run;
	
%end;

%mend tu_sdtmconv_pre_si_bespoke_sr;
