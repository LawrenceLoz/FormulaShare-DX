call sf org assign permset --perm-set-name FormulaShare_Admin_User
call sf org assign permset --perm-set-name FormulaShare_Sample_App_Permissions
echo Assigned permissions
call sf apex run --file config/setDebugModeForUser.apex
echo Set up user for debug mode
call sf apex run --file config/runApexOnInstallation.apex
echo Created test data