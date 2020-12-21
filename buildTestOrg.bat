@echo off
setlocal EnableDelayedExpansion

set orgName=TestData
echo Username for org: %orgName%

call sfdx force:org:create -f config/project-scratch-def.json -a %orgName% --durationdays 30
echo Created org with username %orgName%
call sfdx force:source:push -u %orgName%
echo Pushed source
call sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User -u %orgName%
call sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions -u %orgName%
echo Assigned permissions
call sfdx force:apex:execute -f config/setDebugModeForUser.apex -u %orgName%
echo Set up user for debug mode
call sfdx force:apex:execute -f config/runApexFullTestDataset.apex -u %orgName%
echo Created test data