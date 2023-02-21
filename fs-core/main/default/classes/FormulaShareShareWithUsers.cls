public with sharing class FormulaShareShareWithUsers extends FormulaShareShareWithBase {

    public FormulaShareShareWithUsers(FormulaShareService service) {
        this.service = service;
    }


    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Users') {
            if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.User.getSObjectType())) {
                queryIdSet.add((Id) sharedToString);
                recordRules.add(recRule);
            }
            else {
                String logMessage = 'Expected field to contain valid user id. Instead found: ' + sharedToString;
                service.captureEntityNotFound(recRule, logMessage);
            }
        }
    }

    public override void assess() {
        if(!recordRules.isEmpty()) {

            Set<Id> activeUsersIdSet = getActiveUsers(queryIdSet);

            for(FormulaShareService.RecordRule recRule : recordRules) {
    
                // If user is set on record
                if(recRule.sharedToString != null) {
        
                    Id userId = (Id) recRule.sharedToString;
        
                    // If user is active and not already the record owner then create sharing record
                    if(activeUsersIdSet.contains(userId) && userId != recRule.recordToShare.get('OwnerId')) {
                        system.debug('adding to map for insert');
                        service.updateShareMaps(recRule.recordToShare.Id, userId, recRule.rule.accessLevel, recRule.rule);
                    }
        
                    // If user not found log this as error
                    else if(!activeUsersIdSet.contains(userId)) {
                        String logMessage = 'No active user found with id \'' + userId 
                            + '\'. This could be because the user is inactive, or because their profile has a license'
                            + ' which doesn\'t support sharing (Customer Community or Customer Community Login)';
                        service.captureEntityNotFound(recRule, logMessage);
                    }
                }
            }            
        }
    }


	private static Set<Id> getActiveUsers(Set<Id> userQueryIdSet) {
		Map<Id,User> activeUserMap = new Map<Id,User>(
			[SELECT Id FROM User 
			WHERE Id IN :userQueryIdSet 
			AND IsActive = TRUE
			AND Profile.UserLicense.Name NOT IN ('Customer Community','Customer Community Login')]
		);
		return activeUserMap.keySet();
	}    

}