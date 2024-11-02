:: This script creates and configures a scratch org for genenral development. The steps below will be carried out:
:: - A default scratch org valid for 7 days will be created with name "<Day><Mon>FS" (e.g. "21DecFS")
:: - The core app and sample app will be pushed
:: - Permission sets for the core and sample apps will be assigned to the default scratch org user
:: - Lightning debug will be enabled for the default user
:: - A few test records are created (donations, programmes, countries and themes)
:: - The FormulaShare batch job will be scheduled

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

:: If namespace was provided as an argument, set this in the project-scratch-def.json
:: and update rules metadata to include the prefix in the sharing reason
set namespace=%1
if not "%namespace%" == "" (
    call node scripts/setNamespace.js %namespace%
    echo Set namespace in project-scratch-def.json
    call node scripts/appendNamespaceToSampleMD.js
    echo Appended namespace to custom metadata if required
)

call sf force org create --definitionfile config/project-scratch-def.json --setalias %orgName% --setdefaultusername
echo Created org with default username %orgName%
call sf project deploy start
echo Pushed source
call sf org assign permset --name FormulaShare_Admin_User
call sf org assign permset --name FormulaShare_Sample_App_Permissions
echo Assigned permissions
call sf apex run --file config/setDebugModeForUser.apex
echo Set up user for debug mode
call sf apex run --file config/runApexOnInstallation.apex
echo Created test data