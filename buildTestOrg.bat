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

call sf org create scratch -f config/project-scratch-def.json -a %orgName% --duration-days 30
echo Created org with username %orgName%
call node scripts/appendNamespaceToSampleMD.js
echo Checked for namespace and appended to custom metadata if required
call sf project deploy start --target-org %orgName%
echo Pushed source
call sf org assign permset --name FormulaShare_Admin_User --target-org %orgName%
call sf org assign permset --name FormulaShare_Sample_App_Permissions --target-org %orgName%
echo Assigned permissions
call sf apex run --file config/setDebugModeForUser.apex --target-org %orgName%
echo Set up user for debug mode
call sf apex run --file config/runApexFullTestDataset.apex --target-org %orgName%
echo Created test data