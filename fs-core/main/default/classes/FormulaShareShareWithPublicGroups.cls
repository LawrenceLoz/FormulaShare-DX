public inherited sharing class FormulaShareShareWithPublicGroups extends FormulaShareShareWithBase {

    public FormulaShareShareWithPublicGroups(FormulaShareService service) {
        this.service = service;
    }

    public override Schema.SObjectType getSharedToType() {
        return Schema.Group.getSObjectType();
    }

    Set<String> groupNames = new Set<String>();


    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Public Groups') {

            if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {

                if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, sharedToType)) {
                    service.updateShareMaps(recRule.recordToShare.Id, (Id) sharedToString, recRule.rule.accessLevel, recRule.rule);
                }
                else {
                    if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                        
                        if(FormulaShareIdUtilities.construct().isValidIdType(recRule.rule.fallbackShareToFieldMismatch, sharedToType)) {
                            service.updateShareMaps(recRule.recordToShare.Id, (Id) recRule.rule.fallbackShareToFieldMismatch, recRule.rule.accessLevel, recRule.rule);
                        }
                        else {
                            String logMessage = 'Expected default provided in rule to contain valid group id. Instead found: ' + recRule.rule.fallbackShareToFieldMismatch;
                            service.captureEntityNotFound(recRule, logMessage);
                        }
                    }
                    else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                        String logMessage = 'Expected field to contain valid group id. Instead found: ' + sharedToString;
                        service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }

            // If not an ID we won't update share maps now - this is done later with assess()
            // For now just collect all the names we'll need to query
            else if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                groupNames.add(sharedToString);
                recordRules.add(recRule);
                addShareToFallbackNameToCollection(groupNames, recRule);
            }
        }
    }


    public override void assess() {
		if(!recordRules.isEmpty()) {

            Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

            for(FormulaShareService.RecordRule recRule : recordRules) {
    
                // Update share maps if a group is set on record
                String sharedToName = (String) recRule.sharedToString;
                Id groupId = groupsMap.get(sharedToName);
    
                if(groupId != null) {
                    service.updateShareMaps(recRule.recordToShare.Id, groupId, recRule.rule.accessLevel, recRule.rule);
                }
    
                // If no matching public group for this value. Log as exception (default), fallback or do nothing
                else {
                    if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                        Id fallbackGroupId = groupsMap.get(recRule.rule.fallbackShareToFieldMismatch);
                        if(fallbackGroupId != null) {
                            service.updateShareMaps(recRule.recordToShare.Id, fallbackGroupId, recRule.rule.accessLevel, recRule.rule);                        
                        }
                        else {
                            String logMessage = 'Rule default \''+recRule.rule.fallbackShareToFieldMismatch+'\' should correspond to an active public group, but no group was found with this name';
                            service.captureEntityNotFound(recRule, logMessage);
                        }
                    }
                    else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                        String logMessage = 'Field value \''+sharedToName+'\' should correspond to an active public group, but no group was found with this name';
                        service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }            
        }
    }


	private static Map<String,Id> getGroupsFromNames(Set<String> groupNames) {
		Map<String,Id> groups = new Map<String,Id>();

		// Query for matching public groups and queues
		for(Group grp : [
            SELECT Id, DeveloperName FROM Group 
			WHERE DeveloperName IN :groupNames
			AND (Type = 'Regular' OR Type = 'Queue' OR Type = 'Organization')
            WITH SECURITY_ENFORCED]) {
			groups.put(grp.DeveloperName,grp.Id);
		}
		return groups;
	}

}