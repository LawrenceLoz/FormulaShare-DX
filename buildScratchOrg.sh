#!/bin/bash

#Before running this script, make it executable with the following command:
#chmod +x ./buildScratchOrg.sh

username=formulasharetestuser%orgName%@sfdx.org
nameOfMonth=$(date +%b)
day=$(date +%d)

orgName="${day}${nameOfMonth}FS"
echo Username for default org: ${orgName}

sfdx force:org:create -f config/project-scratch-def.json -a ${orgName} --setdefaultusername
echo Created org with default username ${orgName}
sfdx force:source:push
echo Pushed source
sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User
sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions
echo Assigned permissions
sfdx force:apex:execute -f config/setDebugModeForUser.apex
echo Set up user for debug mode
sfdx force:apex:execute -f config/runApexOnInstallation.apex
echo Created test data