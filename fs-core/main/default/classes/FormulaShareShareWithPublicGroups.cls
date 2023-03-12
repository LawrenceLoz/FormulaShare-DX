public with sharing class FormulaShareShareWithPublicGroups extends FormulaShareShareWithBase {

    public FormulaShareShareWithPublicGroups(FormulaShareService service) {
        this.service = service;
    }

    Set<String> groupNames = new Set<String>();


    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Public Groups') {

            if(recRule.rule.controllingObjectSharedToFieldType == 'Id') {
                if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.Group.getSObjectType())) {
                    service.updateShareMaps(recRule.recordToShare.Id, (Id) sharedToString, recRule.rule.accessLevel, recRule.rule);
                }
                else {
                    String logMessage = 'Expected field to contain valid group id. Instead found: ' + sharedToString;
                    service.captureEntityNotFound(recRule, logMessage);
                }
            }
            else if(recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                groupNames.add(sharedToString);
                recordRules.add(recRule);
            }
        }
    }


    public override void assess() {
		if(!recordRules.isEmpty()) {

            Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

            for(FormulaShareService.RecordRule recRule : recordRules) {
    
                // Update share maps or log only if group is set on record
                if(recRule.sharedToString != null) {
                    String sharedToName = (String) recRule.sharedToString;
                    Id groupId = groupsMap.get(sharedToName);
        
                    if(groupId != null) {
                        service.updateShareMaps(recRule.recordToShare.Id, groupId, recRule.rule.accessLevel, recRule.rule);
                    }
        
                    else {
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