public inherited sharing class FormulaShareHelperService {

	enum OperationType {AFTER_INSERT_OR_UNDELETE, AFTER_UPDATE, AFTER_DELETE}

    FormulaShareHelperServiceRulesSharingObj rulesSharingObjectService;
    FormulaShareHelperServiceInlaw inlawRulesService;
    FormulaShareHelperServiceDescendant descendantRulesService;

    Schema.SObjectType type;
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
		OperationType opType;
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
        setRuleServices();

		// Split descendant and inlaw rules, and remove invalid or inactive ones
		List<FormulaShareRuleDescendant> descendantRulesObjectControls = new List<FormulaShareRuleDescendant>();
		List<FormulaShareRuleInlaw> inlawRulesObjectControls = new List<FormulaShareRuleInlaw>();

		switch on opType {

			// If insert, submit records where one or more share to formula field is populated
			when AFTER_INSERT_OR_UNDELETE {
				for(SObject newRecord : newRecords.values()) {
                    rulesSharingObjectService.processInsert(newRecord);
                    descendantRulesService.processInsert(newRecord);
                    inlawRulesService.processInsert(newRecord);
				}
			}

			// If update, submit those where one or more share to formula field has changed
			when AFTER_UPDATE {
				for(SObject newRecord : newRecords.values()) {
					SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));
                    rulesSharingObjectService.processUpdate(newRecord, oldRecord);
                    descendantRulesService.processUpdate(newRecord, oldRecord);
                    inlawRulesService.processUpdate(newRecord, oldRecord);
				}
			}
		}

		setRemoveSharesForSharedObject();

		// Add all rules to map which splits by shared object
		if(removeSharesForSharedObject) {
			addToRulesForTypeMap(rulesSharingObjectService.relevantRules);
		}
		else {
			addToRulesForTypeMap(rulesSharingObjectService.fullRules);
		}
		addToRulesForTypeMap(inlawRulesService.relevantRules);
		addToRulesForTypeMap(descendantRulesService.relevantRules);

        // Add all records which need to be queried
        recordsToQuery.addAll(rulesSharingObjectService.recordsToQuery);
        recordsToQuery.addAll(inlawRulesService.recordsToQuery);
        recordsToQuery.addAll(descendantRulesService.recordsToQuery);
	}
	


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
				SObject bottomRecord = fullQueriedRecords.get(recordRule.bottomObjectRecordId);
				FormulaShareRuleDescendant descRule = (FormulaShareRuleDescendant) recordRule.rule;
				Id sharedRecordId = (Id) bottomRecord.get(descRule.pathFromBottomObjToSharedObj);
				setRetrievedRecordWithRelatedDetails(bottomRecord, sharedRecordId, recordRule.rule);
			}

			// And details for inlaw rules
			for(FormulaShareHelperServiceRuleType.BottomObjectRecordRule recordRule : inlawRulesService.recordRules) {
				SObject bottomRecord = fullQueriedRecords.get(recordRule.bottomObjectRecordId);
				FormulaShareRuleInlaw inlawRule = (FormulaShareRuleInlaw) recordRule.rule;
				Id sharedRecordId = (Id) bottomRecord.get(inlawRule.pathFromBottomObjToSharedObj);
				setRetrievedRecordwithRelatedDetails(bottomRecord, sharedRecordId, recordRule.rule);
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
		
		System.debug('no details objects: '+ detailsMap.values().size());
		System.debug('No rules to be processed: '+ detailsMap.values()[0].rules.size());
		System.debug('First rule to be processed: '+ detailsMap.values()[0].rules[0].developerName);
		System.debug('Rules service rules rulesSharingObjectService: ' + rulesSharingObjectService.relevantRules.size());
		System.debug('Rules service rules full standard: ' + rulesSharingObjectService.fullStandardRulesSet.size());
		System.debug('Rules service rules full ancestor: ' + rulesSharingObjectService.fullAncestorRulesSet.size());
		System.debug('Rules service rules inlawRulesService: ' + inlawRulesService.relevantRules.size());
		System.debug('Rules service rules descendantRulesService: ' + descendantRulesService.relevantRules.size());

        return detailsMap.values();
    }


    private void setRuleServices() {
        // Query for all rules which may need to be assessed
		FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
		List<FormulaShareRule> rulesSharingObject = fsRulesSelector.getStandardAndAncestorRulesSharingObject(objectName);
        List<FormulaShareRule> rulesObjectControls = fsRulesSelector.getDescendantAndInlawRulesWithThisBottomObject(objectName);
        
        // Establish service objects for these rules
        rulesSharingObjectService = new FormulaShareHelperServiceRulesSharingObj(rulesSharingObject);
        descendantRulesService = new FormulaShareHelperServiceDescendant(rulesObjectControls);
        inlawRulesService = new FormulaShareHelperServiceInlaw(rulesObjectControls);
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
				selector.addFieldString(descRule.pathFromBottomObjToSharedObj);
				selector.addFieldString(descRule.controllingObjectSharedToFieldAPIName);
			}
			for(FormulaShareRule rule : inlawRulesService.relevantRules) {
                FormulaShareRuleInlaw inlawRule = (FormulaShareRuleInlaw) rule;
				selector.addFieldString(inlawRule.pathFromBottomObjToSharedObj);
				selector.addFieldString(inlawRule.pathToSharedToField);
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
				selector.addFieldString(rule.controllingObjectSharedToFieldAPIName);
			}
			for(FormulaShareRuleAncestor rule : ancestorRules) {
				selector.addFieldString(rule.pathToSharedToField);
			}

			// Add ownerid - this will be used if rules share to users
			selector.addFieldString('OwnerId');

			List<SObject> queriedList = selector.selectWithFields(recordsToQuery);
            Map<Id,SObject> fullQueriedRecords = new Map<Id,SObject>((List<SObject>) queriedList);
            
            return fullQueriedRecords;
        }
        
        return new Map<Id,SObject>();
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

	private void setRetrievedRecordWithRelatedDetails(SObject bottomRecord, Id sharedRecordId, FormulaShareRule rule) {
		FormulaShareServiceDetailsForType details = getDetailsForType(rule.objectSharedAPIName);
		details.setRetrievedRecordWithRelatedDetails(bottomRecord, sharedRecordId, rule);
		setDetailsForType(rule.objectSharedAPIName, details);
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