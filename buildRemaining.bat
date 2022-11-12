call sfdx force:user:permset:assign --permsetname FormulaShare_Admin_User
call sfdx force:user:permset:assign --permsetname FormulaShare_Sample_App_Permissions
echo Assigned permissions
call sfdx force:apex:execute -f config/setDebugModeForUser.apex
echo Set up user for debug mode
call sfdx force:apex:execute -f config/runApexOnInstallation.apex
echo Created test data