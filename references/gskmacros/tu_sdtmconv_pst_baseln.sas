/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pst_baseln
|
| Macro Version/Build: 4/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Ashwin Venkat(va755193)
|
| Date:            07May2012
|
| Macro Purpose:   Derive baseline flag for findings datasets
|                  
| Macro Design:  Procedure
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
|
| Output:
|
| Global macro variables created:
|
| Macros called:
| (@)tu_nobs          
| (@)tu_chkvarsexist
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13Feb2013
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: Add in exsubset param that should have been here all along !                              
| Reason for Modification:      v4 in Starteam claimed to have checked this in but it was the same as V3.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22May2013
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: Add in distinct to SQL queries so each domain only processed once (if >1 feeder SI)                             
| Reason for Modification:      Performance/efficiency.
|
|
| Modified By:                  Ashwin Venkat
| Date of Modification:         22July2013
| New Version/Build Number:     4/1
| Reference:                    VA001
| Description for Modification: Resolved issue with numeric --DTC variable with --DTC was missing. Also changed code to handle 
|                               baseline flagging when --DT is same as RFSTDT.                             
| Reason for Modification:      Performance/efficiency
|
| Modified By:                  Ashwin Venkat(va755193)
| Date of Modification:         22July2013
| New Version/Build Number:     4/1
| Reference:                    VA002
| Description for Modification: Added --LAT --DIR --PORTOT proc sort by statment, now baseline flagging take into these variables while 
|				flagging --BLFL                              
| Reason for Modification:      Performance/efficiency
|
| Modified By:                  Ashwin Venkat(va755193)
| Date of Modification:         30Aug2013
| New Version/Build Number:     4/1
| Reference:                    VA003
| Description for Modification: if --ORRES is missing then baseline flagging is not performed for such rows                             
| Reason for Modification:      Performance/efficiency
********************************************************************************/ 
%macro tu_sdtmconv_pst_baseln(
);


/* BJC002 : add distinct domain to this SQL */
proc sql noprint;
    select count(distinct domain) into :num_cmts 
    from sdtm_dom
    where dom_type contains 'Findings' and domain in 
   (select domain from reference where substr(reverse(trim(variable_name)),1,4)='LFLB');
quit;

%if &num_cmts>=1 %then %do;
    /* BJC002 : add distinct domain to this SQL */
    proc sql noprint;
        select distinct domain, dom_ref
            into 
                :dom1 - :dom%left(&num_cmts) ,
				:domref1 - :domref%left(&num_cmts) 
            from sdtm_dom
            where dom_type contains 'Findings' and domain in 
   (select domain from reference where substr(reverse(trim(variable_name)),1,4)='LFLB');
    quit;

    /* BJC001: add in EXSUBSET param where defined */
    data ex;
	    set pst_sdtm.ex %if %length(&exsubset) >=1 %then %do;
                        (&exsubset)
                         %end;	   
						 ;
       format exstdtm datetime20.;
       format exstdt date9.;
       if not missing(exstdtc) then do;
          if index(exstdtc,'T') gt 0  then do;
              if length(exstdtc) gt 16 then do;
                  exstdtm = input(exstdtc,is8601dt.);
                  exstdt = datepart(exstdtm);
              end;
              else do;
                  exstdtm = input(compress(exstdtc)||':00',is8601dt.);
                  exstdt = datepart(exstdtm);
              end;
          end;
          else exstdt = input(exstdtc,is8601da.);
       end;
    run;
        
    proc sort data = ex(keep = studyid usubjid exstdtc exstdtm exstdt);
        by studyid usubjid exstdt exstdtm ;
    run;
      
    proc sort data = ex nodupkey;
        by studyid usubjid;
    run; 
/*VA002 : Added --LAT --DIR --PORTOT proc sort by statment, now baseline flagging take into these variables while 
flagging --BLFL */

     %do a=1 %to &num_cmts;
	    
        %let dom = &&dom&a;
		%let domref = &&domref&a;
        %let CAT = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.cat,Y); 
        %let method = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.method,Y);
        %let spec = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.spec,Y);
        %let loc = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.loc,Y);
        %let dir = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.dir,Y);
        %let lat = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.lat,Y);
        %let portot = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.portot,Y);
        %let pos = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.pos,Y);
        %let tptnum =%tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.tptnum,Y);
        %let dtm = %tu_chkvarsexist(pst_sdtm.&dom,&DOMREF.dtm,Y);


        /* BJC002 : add user screen feedback */
        %let _cmd = %str( Assigning generic baseline flags to &DOM );%tu_sdtmconv_sys_message;  
        /* VA001 : checking if &domref.dtc exist or not */
             
        %let dtc = %length(%tu_chkvarsexist(pst_sdtm.&dom,&domref.dtc));
        data &dom;
        	set pst_sdtm.&dom;
        	format &domref.dt date9.;
            format &domref.dtm datetime20.;
            %if  &dtc = 0 %then %do;
            	if not missing(&domref.dtc) then do;
                	if index(&domref.dtc,'T') gt 0 then do; 
                    		if length(&domref.dtc) gt 16 then do;
                        		&domref.dtm = input(&domref.dtc,is8601dt.);
                        		&domref.dt = datepart(&domref.dtm);
                    		end;
                    		else do;
                        		&domref.dtm = input(compress(&domref.dtc)||':00',is8601dt.);
                        		&domref.dt = datepart(&domref.dtm);
                    		end;
                	end;
               		else &domref.dt = input(&domref.dtc,is8601da.);
            	end;
            %end;
        run;
        
        proc sort data = &dom;
            by studyid usubjid;
        run; ;
        
        data &dom.2 ;
            merge &dom(in=a) ex;
                by studyid usubjid;
                if a;
        run;
        /* VA001 : if --DT is same as RFSTDT and missing --DTM then take the last entry that matches RFSTDT date as baseline.
        /* A note from Randall's response mail(19/7/2013) for the above condition :
         1.	If all we have is date (e.g. no Time or one record doesn't have Time), always set the first 'same date'
         assessment=baseline. This assumes that if we are interested in collecting data around the time of dosing, 
         we would likely do so before dosing and probably again afterwards. Or that for something like QS, 
         the first dosing day is 'close enough' as baseline regardless of the precise timing.*/


        proc sort data = &dom.2;
            by studyid usubjid &cat &pos &method &spec &loc &lat &dir &portot &domref.testcd  descending &domref.dt descending &domref.dtm descending visitnum 
            %if %length(&tptnum) gt 0 %then %do;
                descending &tptnum
            %end;;
        run;
     /*VA003-  if --ORRES is missing then baseline flagging is not done for such rows*/
        data pst_sdtm.&dom(drop = exstdt exstdtm exstdtc &domref.dt &domref.dtm basefl);
            set &dom.2;
                by studyid usubjid &cat &pos &method &spec &loc &lat &dir &portot &domref.testcd;
                &domref.blfl = '';
                retain basefl;
                if first.&domref.testcd then do;
                    basefl = 'N';
                end;
        
                if missing(&domref.dtm) or missing(exstdtm) then do;
                    if first.&domref.testcd and last.&domref.testcd  and not missing(exstdt) and not missing(&domref.dt) 
					and &domref.dt le exstdt and not missing(&domref.orres) then &domref.blfl = 'Y';
                    else if not missing(&domref.dt) and basefl ne 'Y' then do;
                        if &domref.dt le exstdt and not missing(&domref.orres) then do ;
                            &domref.blfl = 'Y';
                            basefl = 'Y';
                        end;
                    end;
                                    
                     
                end; 

		        else if not missing(&domref.dtm) and not missing(exstdtm) then do;
                    	if first.&domref.testcd and last.&domref.testcd  and not missing(exstdtm) and not missing(&domref.dtm)
                    	and &domref.dtm le exstdtm and not missing(&domref.orres) then &domref.blfl = 'Y';
                    	else if not missing(&domref.dtm) and basefl ne 'Y' then do;
                        	if &domref.dtm le exstdtm and not missing(&domref.orres) then do ;
                            		&domref.blfl = 'Y';
                            		basefl = 'Y';
                       		end;
                    	end;
                     
                    	 
                 end;       
        run;
		
		/* BJC002 : add user feedback */
		proc sql noprint;
		 select count(*) into :num_bl from pst_sdtm.&dom
		 where &domref.blfl = 'Y';
		quit;
        %if &num_bl=0 %then %do;
         %let _cmd = %str(%STR(RTN)OTE : Attempt to assign generic baseline flags to &DOM did not flag any rows);%tu_sdtmconv_sys_message;  
        %end;		
		
    %end;
%end;   
 
 	
%mend;


