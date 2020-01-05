@echo off
setlocal EnableDelayedExpansion
for /F "tokens=1 delims=/" %%m in ("%date%") do (
   set /A "m=(1%%m%%100-1)*3"
)
set month=JanFebMarAprMayJunJulAugSepOctNovDec
set monthName=!month:~%m%,3!

set day=%Date:~3,2%
set orgName=%day%%monthName%
echo Username for default org: %orgName%

call sfdx force:org:create -f config/project-scratch-def.json -a %orgName% --setdefaultusername
echo Created org with default username %orgName%
call sfdx force:source:push
echo Pushed source
call sfdx force:apex:execute -f config/runApexOnInstallation.apex
echo Created test data
call sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User
call sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions
echo Assigned permissions