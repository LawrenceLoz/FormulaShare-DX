public inherited sharing class FormulaShareShareWithUsers extends FormulaShareShareWithBase {

    public FormulaShareShareWithUsers(FormulaShareService service) {
        this.service = service;
    }

    public override Schema.SObjectType getSharedToType() {
        return Schema.User.getSObjectType();
    }    


    public override void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule) {
        if(recRule.rule.shareWith == 'Users') {

            if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, sharedToType)) {
                queryIdSet.add((Id) sharedToString);
                recordRules.add(recRule);
            }
            else {
                if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                    if(FormulaShareIdUtilities.construct().isValidIdType(recRule.rule.fallbackShareToFieldMismatch, sharedToType)) {
                        recRule.sharedToString = recRule.rule.fallbackShareToFieldMismatch;
                        recordRules.add(recRule);
                    }
                    else {
                        String logMessage = 'Expected default provided in rule to contain valid user id. Instead found: ' + recRule.rule.fallbackShareToFieldMismatch;
                        service.captureEntityNotFound(recRule, logMessage);
                    }
                }
                else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                    String logMessage = 'Expected field to contain valid user id. Instead found: ' + sharedToString;
                    service.captureEntityNotFound(recRule, logMessage);
                }
            }
            addShareToFallbackIdsToCollection(queryIdSet, recRule);
        }
    }

    public override void assess() {
        if(!recordRules.isEmpty()) {

            Set<Id> activeUsersIdSet = getActiveUsers(queryIdSet);

            for(FormulaShareService.RecordRule recRule : recordRules) {
    
                // If user is set on record
                if(recRule.sharedToString != null) {
        
                    // Note at this point, we've checked validity of ids (sharedToString would have been updated to default if needed)
                    Id userId = (Id) recRule.sharedToString;

                    // Only share to user if shared object is custom, or standard record owner
                    if(userId != recRule.recordToShare.get('OwnerId') || recRule.rule.sharedObjectIsCustom) {

                        // If user is active and not already the record owner then create sharing record
                        if(activeUsersIdSet.contains(userId)) {
                            service.updateShareMaps(recRule.recordToShare.Id, userId, recRule.rule.accessLevel, recRule.rule);
                        }
            
                        // If user not found log this as error
                        else if(recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
                            String logMessage = 'No active user found with id \'' + userId 
                                + '\'. This could be because the user is inactive, or because their profile has a license'
                                + ' which doesn\'t support sharing (Customer Community or Customer Community Login)';
                            service.captureEntityNotFound(recRule, logMessage);
                        }

                        // Or share to default if this is configured (could be the case if target user is inactive)
                        else if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
                            if(FormulaShareIdUtilities.construct().isValidIdType(recRule.rule.fallbackShareToFieldMismatch, sharedToType)) {
                                if((Id) recRule.rule.fallbackShareToFieldMismatch != recRule.recordToShare.get('OwnerId') || recRule.rule.sharedObjectIsCustom) {
                                    service.updateShareMaps(recRule.recordToShare.Id, recRule.rule.fallbackShareToFieldMismatch, recRule.rule.accessLevel, recRule.rule);
                                }
                            }
                            else {
                                String logMessage = 'Expected default provided in rule to contain valid user id. Instead found: ' + recRule.rule.fallbackShareToFieldMismatch;
                                service.captureEntityNotFound(recRule, logMessage);
                            }
                        }
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