public inherited sharing class FormulaShareShareWithRoles extends FormulaShareShareWithBase {

    public FormulaShareShareWithRoles(FormulaShareService service) {
        this.service = service;
    }

    public override Schema.SObjectType getSharedToType() {
        return Schema.UserRole.getSObjectType();
    }

    Set<String> sharedToNamesRoles = new Set<String>();

    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Roles'
        || recRule.rule.shareWith == 'Roles and Internal Subordinates'
        || recRule.rule.shareWith == 'Roles, Internal and Portal Subordinates') {

            if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {
                addShareToFallbackIdsToCollection(queryIdSet, recRule);

                if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, sharedToType)) {
                    queryIdSet.add((Id) sharedToString);
                    recordRules.add(recRule);
                }
                else {
                    if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                        if(this.rulesWithShareToFallbackIdValidity.get(recRule.rule.developerName)) {
                            recordRules.add(recRule);
                        }
                        else {
                            String logMessage = 'Expected default provided in rule to contain valid role id. Instead found: ' + recRule.rule.fallbackShareToFieldMismatch;
                            service.captureEntityNotFound(recRule, logMessage);
                        }
                    }
                    else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                        String logMessage = 'Expected field to contain valid role id. Instead found: ' + sharedToString;
                        service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }
            else if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                sharedToNamesRoles.add(sharedToString);
                recordRules.add(recRule);
                addShareToFallbackNameToCollection(sharedToNamesRoles, recRule);
            }
        }
    }


    public override void assess() {

		// Query for role Ids if needed and create map
		Map<String,Id> roleNamesToIdsMap = new Map<String,Id>();
		if(!sharedToNamesRoles.isEmpty()) {
			List<UserRole> rolesList = [                    //NOPMD (false apexcrudviolation) - system object query for IDs
                    SELECT Id, DeveloperName 
                    FROM UserRole 
                WHERE DeveloperName IN :sharedToNamesRoles];

			for(UserRole role : rolesList) {
				roleNamesToIdsMap.put(role.DeveloperName, role.Id);
			}
		}

		// Process role and/or role and subordinate sharing
		if(!recordRules.isEmpty()) {

            // Build map of required group Ids for role groups
            Map<String,Id> roleGroupIds = new Map<String,Id>();

            // We need two queries here because it's not possible to traverse to Related.DeveloperName (only Related.Name works oddly)
            for(Group grp : [SELECT Id, RelatedId, Type 
                FROM Group 
                WHERE (RelatedId IN :queryIdSet OR RelatedId IN :roleNamesToIdsMap.values())
                AND (Type = 'Role' OR Type = 'RoleAndSubordinatesInternal' OR Type = 'RoleAndSubordinates')
                WITH SECURITY_ENFORCED]) {

                String shortRelatedToId = FormulaShareIdUtilities.get15CharacterId(grp.RelatedId);
                String key = shortRelatedToId + grp.Type;
                roleGroupIds.put(key, grp.Id);
            }


            // Update sharing maps to create or keep role shares
            for(FormulaShareService.RecordRule recRule : recordRules) {

                // If role field is not blank on record
                if(recRule.sharedToString != null) {
                    String sharedTo = (String) recRule.sharedToString;
                    Id sharedToId = null;
                    Id roleGroupId = null;
        
                    if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {

                        // If role exists with the name on the record, use this
                        if(roleNamesToIdsMap.containsKey(sharedTo)) {
                            sharedToId = roleNamesToIdsMap.get(sharedTo);
                        }

                        // If no role for this name, use a default if allowed
                        else if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                            Id fallbackRoleId = roleNamesToIdsMap.get(recRule.rule.fallbackShareToFieldMismatch);
                            if(fallbackRoleId != null) {
                                sharedToId = fallbackRoleId;
                            }
                            else {
                                String logMessage = 'Rule default \''+recRule.rule.fallbackShareToFieldMismatch+'\' should correspond to an active role, but no role was found with this name';
                                service.captureEntityNotFound(recRule, logMessage);
                                continue;	// No need to process remaining recRule logic
                            }
                        }
                        else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                            String logMessage = 'Field value \''+sharedTo+'\' should correspond to an active role, but no role was found with this name';
                            service.captureEntityNotFound(recRule, logMessage);
                            continue;	// No need to process remaining recRule logic
                        }
                        else if(recRule.rule.behaviourShareToFieldMismatch == 'Do Not Share') {
                            continue;	// No need to process remaining recRule logic
                        }
                    }
        
                    else if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {

                        // If id in field is a valid role, look for roles matching this
                        if(FormulaShareIdUtilities.construct().isValidIdType(sharedTo, sharedToType)) {
                            sharedToId = (Id) sharedTo;
                        }

                        // Otherwise look for roles matching fallback id
                        // NOTE: Only scenario we're processing a recordRule with invalid sharedTo is when default has been
                        //       specified and verified valid, so no need to check rule configuration again
                        else {
                            sharedToId = (Id) recRule.rule.fallbackShareToFieldMismatch;
                        }
                    }
        
                    String shortSharedToId = FormulaShareIdUtilities.get15CharacterId(sharedToId);

                    switch on recRule.rule.shareWith {

                        // Get group for Roles sharing
                        when 'Roles' {
                            roleGroupId = roleGroupIds.get(shortSharedToId + 'Role');
                        }

                        // When Digital Experiences not enabled, Role, RoleAndSubordinatesInternal exist
                        // When Digital Experiences are enabled, Role, RoleAndSubordinatesInternal and RoleAndSubordinates exist
                        when 'Roles and Internal Subordinates' {
                            // Logic below kept as legacy, but appears that RoleAndSubordinatesInternal should always exist
                            if(roleGroupIds.containsKey(shortSharedToId + 'RoleAndSubordinatesInternal')) {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinatesInternal');
                            }
                            else {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
                            }
                        }

                        when 'Roles, Internal and Portal Subordinates' {
                            // Previously failing when Digital Experiences not enabled (didn't fall back to checking for RoleAndSubordinatesInternal)
                            if(roleGroupIds.containsKey(shortSharedToId + 'RoleAndSubordinates')) {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
                            }
                            else {
                                roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinatesInternal');
                            }
                        }
                    }
                    
                    if(roleGroupId != null) {
                        this.service.updateShareMaps(recRule.recordToShare.Id, roleGroupId, recRule.rule.accessLevel, recRule.rule);
                    }
        
                    // Log error if no matching group for the id of the role on the record or the fallback
                    // The standard roles like CEO, CFO for example aren't valid for sharing in a scratch org
                    else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                        String logMessage = 'Role \''+recRule.sharedToString+'\' is not valid for sharing';
                        this.service.captureEntityNotFound(recRule, logMessage);
                    }
                    else if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                        String logMessage = 'Rule default role \''+recRule.sharedToString+'\' is not valid for sharing';
                        this.service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }
        }        
    }
}