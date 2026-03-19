/******************************************************************************* 
|
| Program Name:    tc_sp
|
| Program Version: Placeholder
|
| MDP/Protocol ID: N/A
|
| Program Purpose: To prevent the introduction of non-standard tools with 
|                  standard tool names.
|
| SAS Version:     N/A
|
| Created By:      Paul Jarrett
| Date:            12-Jan-2005
| Input parameters:  NONE
|                    
| Output:            NONE
|
| Global macro variables created:  None
|
| Macros called :
|   (@) tu_abort
|                    
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 
%MACRO tc_sp(
            );
%put %str(RTE)RROR: TC_SP:  This macro is not currently released for production use.;
%LET g_abort=1;
%tu_abort;
%MEND tc_sp;
