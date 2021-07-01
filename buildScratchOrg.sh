# This script creates and configures a scratch org for genenral development. The steps below will be carried out:
# - A default scratch org valid for 7 days will be created with name "<Day><Mon>FS" (e.g. "21DecFS")
# - The core app and sample app will be pushed
# - Permission sets for the core and sample apps will be assigned to the default scratch org user
# - Lightning debug will be enabled for the default user
# - A few test records are created (donations, programmes, countries and themes)
# - The FormulaShare batch job will be scheduled


#!/bin/bash

#Before running this script, make it executable with the following command:
#chmod +x ./buildScratchOrg.sh

nameOfMonth=$(date +%b)
day=$(date +%d)

orgName="${day}${nameOfMonth}FS"
echo Username for default org: ${orgName}

sfdx force:org:create -f config/project-scratch-def.json -a ${orgName} --setdefaultusername
echo Created org with default username ${orgName}
node scripts/appendNamespaceToSampleMD.js
echo Checked for namespace and appended to custom metadata if required
sfdx force:source:push
echo Pushed source
sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User
sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions
echo Assigned permissions
sfdx force:apex:execute -f config/setDebugModeForUser.apex
echo Set up user for debug mode
sfdx force:apex:execute -f config/runApexOnInstallation.apex
echo Created test data