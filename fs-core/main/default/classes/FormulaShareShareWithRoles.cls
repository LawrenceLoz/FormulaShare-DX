public with sharing class FormulaShareShareWithRoles extends FormulaShareShareWithBase {

    public FormulaShareShareWithRoles(FormulaShareService service) {
        this.service = service;
    }

    Set<String> sharedToNamesRoles = new Set<String>();


    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Roles'
        || recRule.rule.shareWith == 'Roles and Internal Subordinates'
        || recRule.rule.shareWith == 'Roles, Internal and Portal Subordinates') {

            if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {
                if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.UserRole.getSObjectType())) {
                    queryIdSet.add((Id) sharedToString);
                    recordRules.add(recRule);
                }
                else {
                    String logMessage = 'Expected field to contain valid role id. Instead found: ' + sharedToString;
                    service.captureEntityNotFound(recRule, logMessage);
                }
            }
            else if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                System.debug('Adding share for role rule with name');
                sharedToNamesRoles.add(sharedToString);
                recordRules.add(recRule);
            }
        }
    }


    public override void assess() {

		// Query for role Ids if needed and create map
		Map<String,Id> roleNamesToIdsMap = new Map<String,Id>();
		if(!sharedToNamesRoles.isEmpty()) {
			List<UserRole> rolesList = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :sharedToNamesRoles];

			for(UserRole role : rolesList) {
				roleNamesToIdsMap.put(role.DeveloperName, role.Id);
			}
		}

		// Process role and/or role and subordinate sharing
		if(!recordRules.isEmpty()) {

            // Build map of required group Ids for role groups
            Map<String,Id> roleGroupIds = new Map<String,Id>();

            for(Group grp : [SELECT Id, RelatedId, Type 
                FROM Group 
                WHERE (RelatedId IN :queryIdSet OR RelatedId IN :roleNamesToIdsMap.values())
                AND (Type = 'Role' OR Type = 'RoleAndSubordinatesInternal' OR Type = 'RoleAndSubordinates')
                ]) {

                String shortRelatedToId = FormulaShareIdUtilities.get15CharacterId(grp.RelatedId);
                String key = shortRelatedToId + grp.Type;
                system.debug('Added roleGroupEntry key: '+key+' for group: '+grp.Id);
                roleGroupIds.put(key, grp.Id);
            }


            // Update sharing maps to create or keep role shares
            for(FormulaShareService.RecordRule recRule : recordRules) {
                System.debug('recRule.sharedToString: '+recRule.sharedToString);
                System.debug('recRule.sharedToString: '+recRule.sharedToString);

                // If role field is not blank on record
                if(recRule.sharedToString != null) {
                    String sharedTo = (String) recRule.sharedToString;
                    Id sharedToId = null;
                    Id roleGroupId = null;
        
                    if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                        if(roleNamesToIdsMap.containsKey(sharedTo)) {
                            sharedToId = roleNamesToIdsMap.get(sharedTo);
                        }
                        else {
                            String logMessage = 'Field value \''+sharedTo+'\' should correspond to an active role, but no role was found with this name';
                            service.captureEntityNotFound(recRule, logMessage);
                            continue;	// No need to process remaining recRule logic
                        }
                    }
        
                    else if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {
                        sharedToId = (Id) sharedTo;
                    }
        
                    String shortSharedToId = FormulaShareIdUtilities.get15CharacterId(sharedToId);

                    switch on recRule.rule.shareWith {

                        // Get group for Roles sharing
                        when 'Roles' {
                            roleGroupId = roleGroupIds.get(shortSharedToId + 'Role');
                        }

                        when 'Roles and Internal Subordinates' {
                            // If role and subordinates internal group exists, use this
                            if(roleGroupIds.containsKey(shortSharedToId + 'RoleAndSubordinatesInternal')) {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinatesInternal');
                            }
            
                            // If no role and subordinates internal group exists, use the role and subordinates group
                            // This will be the case when communities are not enabled
                            else {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
                            }
                        }

                        when 'Roles, Internal and Portal Subordinates' {
                            roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
                        }
                    }
                    
                    if(roleGroupId != null) {
                        this.service.updateShareMaps(recRule.recordToShare.Id, roleGroupId, recRule.rule.accessLevel, recRule.rule);
                    }
        
                    else {
                        String logMessage = 'Role \''+recRule.sharedToString+'\' specified on record is not valid for sharing';
                        this.service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }
        }        
    }
}