# This script creates a long-lived (30 days) scratch org with a relatively large amount of data (~700 donations).
# This can be helpful when persistent data and large batches is useful for testing.


#!/bin/bash

#Before running this script, make it executable with the following command:
#chmod +x ./buildTestOrg.sh

orgName=TestData
echo Username for org: ${orgName}

call sf force org create --definitionfile config/project-scratch-def.json --setalias ${orgName} --durationdays 30
echo Created org with username ${orgName}
node scripts/appendNamespaceToSampleMD.js
echo Checked for namespace and appended to custom metadata if required
call sf project deploy start --target-org ${orgName}
echo Pushed source
call sf org assign permset --name FormulaShare_Admin_User --target-org ${orgName}
call sf org assign permset --name FormulaShare_Sample_App_Permissions --target-org ${orgName}
echo Assigned permissions
call sf apex run --file config/setDebugModeForUser.apex --target-org ${orgName}
echo Set up user for debug mode
call sf apex run --file config/runApexFullTestDataset.apex --target-org ${orgName}
echo Created test data