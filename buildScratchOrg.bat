@echo off
setlocal EnableDelayedExpansion

set X=
for /f "skip=1 delims=" %%x in ('wmic os get localdatetime') do if not defined X set X=%%x
set month=%X:~4,2%
set day=%X:~6,2%

set monthList=JanFebMarAprMayJunJulAugSepOctNovDec
set /a monthPos=(%month%-1)*3
set monthName=!monthList:~%monthPos%,3!

set orgName=%day%%monthName%FS
echo Username for default org: %orgName%

call sfdx force:org:create -f config/project-scratch-def.json -a %orgName% --setdefaultusername
echo Created org with default username %orgName%
call sfdx force:source:push
echo Pushed source
call sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User
call sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions
echo Assigned permissions
call sfdx force:apex:execute -f config/setDebugModeForUser.apex
echo Set up user for debug mode
call sfdx force:apex:execute -f config/runApexOnInstallation.apex
echo Created test data
call sfdx force:user:create --setalias fstest --definitionfile config/user-def.json username=formulasharetestuser%orgName%@sfdx.org
echo Created test user fstest