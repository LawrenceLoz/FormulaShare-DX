/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public inherited sharing class FormulaShareHelperService {

	enum OperationType {AFTER_INSERT_OR_UNDELETE, AFTER_UPDATE, AFTER_DELETE}

    FormulaShareHelperServiceRulesSharingObj rulesSharingObjectService;
    FormulaShareHelperServiceInlaw inlawRulesService;
    FormulaShareHelperServiceDescendant descendantRulesService;

    Schema.SObjectType type;
	OperationType opType;
	String objectName;
	Boolean removeSharesForSharedObject = true;

	Set<Id> recordsToQuery = new Set<Id>();

	//	Map<String,List<FormulaShareRule>> rulesForTypeMap= new Map<String,List<FormulaShareRule>>();
	Map<String,FormulaShareServiceDetailsForType> detailsMap = new Map<String,FormulaShareServiceDetailsForType>();

	public FormulaShareHelperService(Schema.SObjectType type, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

        this.type = type;
		objectName = type.getDescribe().getName();

		// Clear map in case populated from previous object in same transaction
		recordsToQuery.clear();

		// Determine trigger operation (we don't use trigger context variable so method can be unit tested)
		if(oldRecords == null) {
			opType = OperationType.AFTER_INSERT_OR_UNDELETE;
		}
		else if(newRecords == null) {
            opType = OperationType.AFTER_DELETE;
            return;    // No processing for delete
		}
		else {
			opType = OperationType.AFTER_UPDATE;
		}
		System.debug('opType: '+opType);

        // Query for rules which may need to be reassessed for the records in scope, and initialise relevant service classes
		FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
		List<FormulaShareRule> rulesSharingObject = fsRulesSelector.getStandardAndAncestorRulesSharingObject(objectName);
        List<FormulaShareRule> rulesObjectControls = fsRulesSelector.getDescendantAndInlawRulesWithThisBottomObject(objectName);

		// Initialise service objects (variable setting only in constructors)
		rulesSharingObjectService = new FormulaShareHelperServiceRulesSharingObj(rulesSharingObject);
        descendantRulesService = new FormulaShareHelperServiceDescendant(rulesObjectControls);
        inlawRulesService = new FormulaShareHelperServiceInlaw(rulesObjectControls);
		
		// Add records to be re-queried if rules could be affected by changes to this object
		if(!rulesSharingObjectService.rules.isEmpty()) {
			populateRecordsToQuery(rulesSharingObjectService, oldRecords, newRecords);

			// Assess whether to remove rules
			setRemoveSharesForSharedObject();

			// Add all rules to map which splits by shared object
			if(removeSharesForSharedObject) {
				addToRulesForTypeMap(rulesSharingObjectService.relevantRules);
			}
			else {
				addToRulesForTypeMap(rulesSharingObjectService.fullRules);
			}
		}
		if(!descendantRulesService.rules.isEmpty()) {
			populateRecordsToQuery(descendantRulesService, oldRecords, newRecords);
			addToRulesForTypeMap(descendantRulesService.relevantRules);
		}
		if(!inlawRulesService.rules.isEmpty()) {
			populateRecordsToQuery(inlawRulesService, oldRecords, newRecords);
			addToRulesForTypeMap(inlawRulesService.relevantRules);
		}
	}

	
//	// Check whether any impact for rules sharing this object
//	private void processRulesSharingObject(Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {
//
//		switch on opType {
//
//			// If insert, submit records where one or more share to field is populated
//			when AFTER_INSERT_OR_UNDELETE {
//				for(SObject newRecord : newRecords.values()) {
//                    rulesSharingObjectService.processInsert(newRecord);
//				}
//			}
//
//			// If update, submit those where one or more share to field has changed
//			when AFTER_UPDATE {
//				for(SObject newRecord : newRecords.values()) {
//					SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));
//                    rulesSharingObjectService.processUpdate(newRecord, oldRecord);
//				}
//			}
//		}
//
//        // Add records which need to be queried
//		recordsToQuery.addAll(rulesSharingObjectService.recordsToQuery);
//	}
	

	// Check whether possible sharing impact based on rules and values from trigger
	private void populateRecordsToQuery(FormulaShareHelperServiceRuleType serviceRuleType, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

		switch on opType {

			// If insert, submit records where one or more share to field is populated
			when AFTER_INSERT_OR_UNDELETE {
				for(SObject newRecord : newRecords.values()) {
                    serviceRuleType.processInsert(newRecord);
				}
			}

			// If update, submit those where one or more share to field has changed
			when AFTER_UPDATE {
				for(SObject newRecord : newRecords.values()) {
					SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));
                    serviceRuleType.processUpdate(newRecord, oldRecord);
				}
			}
		}

        // Add all records which need to be queried
        recordsToQuery.addAll(serviceRuleType.recordsToQuery);
	}

//	// Check whether any impact for inlaw and descendant rules where this object is the controlling object
//	private void processRulesThisObjectControls(OperationType opType, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {
//
//		switch on opType {
//
//			// If insert, submit records where one or more share to field is populated
//			when AFTER_INSERT_OR_UNDELETE {
//				for(SObject newRecord : newRecords.values()) {
//                    descendantRulesService.processInsert(newRecord);
//                    inlawRulesService.processInsert(newRecord);
//				}
//			}
//
//			// If update, submit those where one or more share to field has changed
//			when AFTER_UPDATE {
//				for(SObject newRecord : newRecords.values()) {
//					SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));
//                    descendantRulesService.processUpdate(newRecord, oldRecord);
//                    inlawRulesService.processUpdate(newRecord, oldRecord);
//				}
//			}
//		}
//
//		addToRulesForTypeMap(inlawRulesService.relevantRules);
//		addToRulesForTypeMap(descendantRulesService.relevantRules);
//
//        // Add all records which need to be queried
//        recordsToQuery.addAll(inlawRulesService.recordsToQuery);
//        recordsToQuery.addAll(descendantRulesService.recordsToQuery);
//	}


    // Queries for records if necessary and returns map of objects and records with all sharing details required
    public List<FormulaShareServiceDetailsForType> getDetailsForTypes() {
        
		// Query for records to populate lookups if required, and set retrieved record details for each
		Map<Id,SObject> fullQueriedRecords;
		if(!recordsToQuery.isEmpty()) {

			fullQueriedRecords = getFullQueriedRecords(type);

			for(Id recordId : rulesSharingObjectService.recordIdsSharedByAncestorRules) {
				SObject record = fullQueriedRecords.get(recordId);
				System.debug('Setting record needed by ancestor rule: '+record);
				setSharedObjectRetrievedRecord(record);
			}

			// Add details for descendant records
			for(FormulaShareHelperServiceRuleType.BottomObjectRecordRule recordRule : descendantRulesService.recordRules) {
				getRelatedRecordDetailsAndSetInMap(fullQueriedRecords, recordRule);
			}

			// And details for inlaw rules
			for(FormulaShareHelperServiceRuleType.BottomObjectRecordRule recordRule : inlawRulesService.recordRules) {
				getRelatedRecordDetailsAndSetInMap(fullQueriedRecords, recordRule);
			}
		}

		// Add records shared by standard rules
		System.debug('rulesSharingObjectService: '+rulesSharingObjectService);
		System.debug('rulesSharingObjectService.recordsSharedByStandardRules: '+rulesSharingObjectService.recordsSharedByStandardRules);
		for(SObject record : rulesSharingObjectService.recordsSharedByStandardRules) {

			// If we'd queried this record for another type of rule, use the queried version with populated instead
			if(fullQueriedRecords != null && fullQueriedRecords.containsKey(record.Id)) {
				record = fullQueriedRecords.get(record.Id);
			}
			
			System.debug('Setting record needed by std rule: '+record);
			setSharedObjectRetrievedRecord(record);
		}

        return detailsMap.values();
    }


	// removeSharesForSharedObject is true by default. For standard objects check whether we should set to false
	// If we do need to check for removal, we need to query for all standard/ancestor fields and check all rules sharing object
	private void setRemoveSharesForSharedObject() {

		// Check whether removal of sharing is permitted at all
		if(!rulesSharingObjectService.relevantRules.isEmpty() && !type.getDescribe().isCustom()) {
			FormulaShareSObjectUtilities objUtils = new FormulaShareSObjectUtilities(type);
			removeSharesForSharedObject = objUtils.removeSharesForObject();

			// If standard object and we're permitted to remove sharing, check whether any rules other than standard and ancestor
			// If so, we shouldn't instruct to remove sharing because there might be legitimate shares in place from these rules
			if(removeSharesForSharedObject) {
				FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
				List<FormulaShareRule> allRules = fsRulesSelector.getRulesSharingObject(type);

				// Check whether the number of rules sharing object is the same as the number of standard & ancestor rules
				if(allRules.size() != rulesSharingObjectService.rules.size()) {
					removeSharesForSharedObject = false;
				}
			}
		}
	}



	// Queries for all records including lookups referenced in sharing and sets these in list
	private Map<Id,SObject> getFullQueriedRecords(Schema.SObjectType type) {

		if(!recordsToQuery.isEmpty()) {

			// Create selector
			FormulaShareSObjectsSelector selector = new FormulaShareSObjectsSelector(true, type);

			// Add field paths from all relevant rules
			for(FormulaShareRule rule : descendantRulesService.relevantRules) {
                FormulaShareRuleDescendant descRule = (FormulaShareRuleDescendant) rule;
				System.debug('Adding descRule.pathFromBottomObjToSharedObj: ' + descRule.pathFromBottomObjToSharedObj);
				System.debug('Adding descRule.controllingObjectSharedToFieldAPIName: ' + descRule.controllingObjectSharedToFieldAPIName);
				selector.addFieldString(descRule.pathFromBottomObjToSharedObj);
				selector.addFieldString(descRule.controllingObjectSharedToFieldAPIName);
				selectOwnerIdIfNeeded(selector, rule);
			}
			for(FormulaShareRule rule : inlawRulesService.relevantRules) {
				FormulaShareRuleInlaw inlawRule = (FormulaShareRuleInlaw) rule;
				System.debug('Adding inlawRule.pathFromBottomObjToSharedObj: ' + inlawRule.pathFromBottomObjToSharedObj);
				System.debug('Adding inlawRule.pathToSharedToField: ' + inlawRule.pathToSharedToField);
				selector.addFieldString(inlawRule.pathFromBottomObjToSharedObj);
				selector.addFieldString(inlawRule.pathToSharedToField);
				selectOwnerIdIfNeeded(selector, rule);
			}

			// For ancestor and standard, if we're planning to remove sharing then we need to query for anything relevant
			Set<FormulaShareRuleStandard> standardRules;
			Set<FormulaShareRuleAncestor> ancestorRules;
			if(removeSharesForSharedObject && !type.getDescribe().isCustom()) {
				standardRules = rulesSharingObjectService.fullStandardRulesSet;
				ancestorRules = rulesSharingObjectService.fullAncestorRulesSet;
			}
			else {
				standardRules = rulesSharingObjectService.relevantStandardRulesSet;
				ancestorRules = rulesSharingObjectService.relevantAncestorRulesSet;
			}

			for(FormulaShareRuleStandard rule : standardRules) {
				System.debug('Adding standard rule controllingObjectSharedToFieldAPIName: ' + rule.controllingObjectSharedToFieldAPIName);
				selector.addFieldString(rule.controllingObjectSharedToFieldAPIName);
				selectOwnerIdIfNeeded(selector, rule);
			}
			for(FormulaShareRuleAncestor rule : ancestorRules) {
				System.debug('Adding ancestor rule pathToSharedToField: ' + rule.pathToSharedToField);
				selector.addFieldString(rule.pathToSharedToField);
				selectOwnerIdIfNeeded(selector, rule);
			}

			List<SObject> queriedList = selector.selectWithFields(recordsToQuery);
            Map<Id,SObject> fullQueriedRecords = new Map<Id,SObject>((List<SObject>) queriedList);
            
            return fullQueriedRecords;
        }
        
        return new Map<Id,SObject>();
	}


	// If rule shares with users, adds the owner id from the shared object
	private void selectOwnerIdIfNeeded(FormulaShareSObjectsSelector selector, FormulaShareRule rule) {
		if(rule.shareWith == 'Users') {
			switch on rule.type {
				when 'standard', 'ancestor' {
					selector.addFieldString('OwnerId');
				}
				when 'descendant', 'inlaw' {
					FormulaShareRuleBottomObject boRule = (FormulaShareRuleBottomObject) rule;
					selector.addFieldString(boRule.pathFromBottomObjToOwnerIdOnSharedObj);
				}
			}
		}
	}


	// Establishes all types to be processed in map
	private void addToRulesForTypeMap(Set<FormulaShareRule> rulesSet) {
		for(FormulaShareRule rule : rulesSet) {
			FormulaShareServiceDetailsForType details = getDetailsForType(rule.objectSharedAPIName);
			details.rules.add(rule);
			setDetailsForType(rule.objectSharedAPIName, details);
		}
	}


	private void setSharedObjectRetrievedRecord(SObject record) {
		FormulaShareServiceDetailsForType details = getDetailsForType(objectName);
		details.setSharedObjectRetrievedRecord(objectName, record);
		setDetailsForType(objectName, details);
	}

	
	private void getRelatedRecordDetailsAndSetInMap(Map<Id,SObject> fullQueriedRecords, FormulaShareHelperServiceRuleType.BottomObjectRecordRule recordRule) {

		// Get shared record id
		SObject bottomRecord = fullQueriedRecords.get(recordRule.bottomObjectRecordId);
		FormulaShareRuleBottomObject boRule = (FormulaShareRuleBottomObject) recordRule.rule;
		Id sharedRecordId = boRule.getSharedObjectIdFromBottomRecord(bottomRecord);

		// If there's a shared record in scope (will be the case unless a lookup towards shared isn't populated)
		if(sharedRecordId != null) {

			// Get ownerId if rule shares with users (might not have been queried otherwise)
			Id ownerId;
			if(boRule.shareWith == 'Users') {
				ownerId = boRule.getOwnerOfSharedObjectFromBottomObject(bottomRecord);
			}
	
			// Establish the retrieved records with related details object for the shared object
			FormulaShareServiceDetailsForType details = getDetailsForType(boRule.objectSharedAPIName);
			details.setRetrievedRecordWithRelatedDetails(bottomRecord, sharedRecordId, ownerId, boRule);
			setDetailsForType(boRule.objectSharedAPIName, details);
		}
	}

	private FormulaShareServiceDetailsForType getDetailsForType(String sharedObjectName) {
		String key = getDetailsMapKey(sharedObjectName);

		FormulaShareServiceDetailsForType details;
		if(detailsMap.containsKey(key)) {
			details = detailsMap.get(key);
		}
		else {
			Boolean removeForThisType = removeSharesForThisType(sharedObjectName);
			System.debug('Removal settings for: '+sharedObjectName+' = ' + removeForThisType);
			Schema.SObjectType sharedObjectType = FormulaShareUtilities.getSObjectTypeFromName(sharedObjectName);
			details = new FormulaShareServiceDetailsForType(sharedObjectType, removeForThisType);
		}

		return details;
	}

	private void setDetailsForType(String sharedObjectName, FormulaShareServiceDetailsForType details) {
		String key = getDetailsMapKey(sharedObjectName);
		detailsMap.put(key, details);
	}

	private String getDetailsMapKey(String sharedObjectName) {
		String key = sharedObjectName;
		Boolean removeForThisType = removeSharesForThisType(sharedObjectName);
		if(removeForThisType) {
			key =+ '|removeShares';
		}
		return key;
	}

	private Boolean removeSharesForThisType(String sharedObjectName) {
		return sharedObjectName == objectName && removeSharesForSharedObject;
	}

}