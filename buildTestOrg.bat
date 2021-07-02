:: This script creates a long-lived (30 days) scratch org with a relatively large amount of data (~700 donations).
:: This can be helpful when persistent data and large batches is useful for testing.

@echo off
setlocal EnableDelayedExpansion

set orgName=TestData
echo Username for org: %orgName%

:: If namespace was provided as an argument, set this in the project-scratch-def.json
:: and update rules metadata to include the prefix in the sharing reason
set namespace=%1
if not "%namespace%" == "" (
    call node scripts/setNamespace.js %namespace%
    echo Set namespace in project-scratch-def.json
    call node scripts/appendNamespaceToSampleMD.js
    echo Appended namespace to custom metadata if required
)

call sfdx force:org:create -f config/project-scratch-def.json -a %orgName% --durationdays 30
echo Created org with username %orgName%
call node scripts/appendNamespaceToSampleMD.js
echo Checked for namespace and appended to custom metadata if required
call sfdx force:source:push -u %orgName%
echo Pushed source
call sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User -u %orgName%
call sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions -u %orgName%
echo Assigned permissions
call sfdx force:apex:execute -f config/setDebugModeForUser.apex -u %orgName%
echo Set up user for debug mode
call sfdx force:apex:execute -f config/runApexFullTestDataset.apex -u %orgName%
echo Created test data