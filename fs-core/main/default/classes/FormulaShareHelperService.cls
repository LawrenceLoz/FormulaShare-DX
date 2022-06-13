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

	List<FormulaShareRuleTypeServiceBase> ruleTypeServices;

    Schema.SObjectType type;
	Schema.DescribeSObjectResult typeDescribe;
	OperationType opType;
	String objectName;
	Boolean removeSharesForSharedObject = true;
	Boolean assessAllRules = false;

	Set<Id> recordsToQuery = new Set<Id>();

	Map<String,FormulaShareServiceDetailsForType> detailsMap = new Map<String,FormulaShareServiceDetailsForType>();

	public FormulaShareHelperService() {
		this.ruleTypeServices = new FormulaShareInjectionService().getRuleTypeServices();
	}

	public void checkImpact(Schema.SObjectType type, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {
        this.type = type;
		this.typeDescribe = type.getDescribe();
		objectName = typeDescribe.getName();

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

        // Query for rules which may need to be reassessed for the records in scope, and initialise relevant service classes
		FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
		List<FormulaShareRule> rulesSharingObject = fsRulesSelector.getRulesSharingObject(objectName);
        List<FormulaShareRule> rulesObjectInfluences = fsRulesSelector.getInfluencedRulesOnOtherObjects(objectName);

		// Use services to identify which rules could need to be assessed for these records
		for(FormulaShareRuleTypeServiceBase service : ruleTypeServices) {
			service.setRules(objectName, rulesSharingObject, rulesObjectInfluences);

			if(!service.allRules.isEmpty()) {
				populateRecordsToQuery(service, oldRecords, newRecords);

				// If the service shares the updated records, we might need to consider all rules on these
				// This is because this is (currently) the only situation where sharing could be removed
				if(service.sharesProcessedObject()) {
					setRemoveSharesForSharedObject(service);
				}
			}
		}

		// Knowing whether full set of rules will need to be assessed, iterate again and add rules to map
		for(FormulaShareRuleTypeServiceBase service : ruleTypeServices) {
			if(!service.fullRules.isEmpty()) {
				if(service.sharesProcessedObject() && assessAllRules) {
					addToRulesForTypeMap(service.fullRules);
				}
				else {
					if(!service.relevantRules.isEmpty()) {
						addToRulesForTypeMap(service.relevantRules);
					}
				}
			}
		}
	}


	
	// Check whether possible sharing impact based on rules and values from trigger
	private void populateRecordsToQuery(FormulaShareRuleTypeServiceBase serviceRuleType, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

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


	// removeSharesForSharedObject is true by default. Check object settings to determine whether we should set to false
	// If we do need to check for removal, we need to query for all standard/ancestor fields and check all rules sharing object
	private void setRemoveSharesForSharedObject(FormulaShareRuleTypeServiceBase service) {

		// Proceed if there are any rules to check for this type 
		// and we haven't already identified a need to assess everything
		if(!service.relevantRules.isEmpty() && !assessAllRules) {
			FormulaShareSObjectUtilities objUtils = new FormulaShareSObjectUtilities(type);

			Boolean isCustom = typeDescribe.isCustom();
			Boolean removalAllowed = objUtils.removeSharesForObject();

			// For custom objects, remove sharing only if object settings allow this
			// No need to assess sharing for other rules, as sharing will be separated effectively by sharing rules 
			if(isCustom) {
				removeSharesForSharedObject = objUtils.removeSharesForObject();
				assessAllRules = false;
			}

			// For standard objects where removal is not allowed, do not remove sharing
			else if(!isCustom && !removalAllowed) {
				removeSharesForSharedObject = false;
				assessAllRules = false;
			}

			// For standard objects where removal is allowed...
			else if(!isCustom && removalAllowed) {
				FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
				List<FormulaShareRule> allRules = fsRulesSelector.getRulesSharingObject(type);

				// Check whether the number of rules sharing object is the same as the number of rules considered by service
				// If so we know all sharing on the object will be from rules we're assessing so no need to check others
				if(allRules.size() != service.allRules.size()) {
					removeSharesForSharedObject = false;
					assessAllRules = false;
				}

				// Otherwise, don't remove because there might be valid shares in place from other rules
				else {
					removeSharesForSharedObject = true;
					assessAllRules = true;
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


	private FormulaShareServiceDetailsForType getDetailsForType(String sharedObjectName) {
		String key = getDetailsMapKey(sharedObjectName);

		// If we've already started populating a DetailsForType object for this SObject, return this
		if(detailsMap.containsKey(key)) {
			return detailsMap.get(key);
		}

		// Otherwise determine if we should be removing shares, and construct and return a new DetailsForType
		else {
			Boolean removeForThisType = removeSharesForThisType(sharedObjectName);
			System.debug('Removal settings for: '+sharedObjectName+' = ' + removeForThisType);
			Schema.SObjectType sharedObjectType = FormulaShareUtilities.getSObjectTypeFromName(sharedObjectName);
			return new FormulaShareServiceDetailsForType(sharedObjectType, removeForThisType);
		}
	}

	private void setDetailsForType(String sharedObjectName, FormulaShareServiceDetailsForType details) {
		String key = getDetailsMapKey(sharedObjectName);
		detailsMap.put(key, details);
	}

	// If we're removing records for the shared object, key includes this format so it's processed in the
	// separately from any related object sharing which references the same object
	private String getDetailsMapKey(String sharedObjectName) {
		String key = sharedObjectName;
		Boolean removeForThisType = removeSharesForThisType(sharedObjectName);
		if(removeForThisType) {
			key =+ '|removeShares';
		}
		return key;
	}

	// Only remove sharing if object being assessed is the shared object (i.e. standard rule or specific record assessment e.g. for batch)
	private Boolean removeSharesForThisType(String sharedObjectName) {
		return sharedObjectName == objectName && removeSharesForSharedObject;
	}

	

    // Queries for records if necessary and returns map of objects and records with all sharing details required
    public List<FormulaShareServiceDetailsForType> getDetailsForTypeList() {

		// Query for records to populate lookups if required, and set retrieved record details for each
		Map<Id,SObject> fullQueriedRecords;

		// We may have extra information to requery from the records (values of relationship parents for example)
		if(!recordsToQuery.isEmpty()) {
			fullQueriedRecords = getFullQueriedRecords(type);
		}

		// ... but if not we can just use the versions from the trigger as the full queried records
		else {
			fullQueriedRecords = new Map<Id,SObject>();

			for(FormulaShareRuleTypeServiceBase service : ruleTypeServices) {
				for(SObject record : service.recordsShared) {
					Id recordId = (Id) record.get('Id');
					fullQueriedRecords.put(recordId, record);
				}
			}
		}

		// For each rule type service, add relevant records into the details service for the object
		// that the rules in the type service share. Logic definied in each implementation of type service
		for(FormulaShareRuleTypeServiceBase service : ruleTypeServices) {
			String processedObjectKey = getDetailsMapKey(objectName);
			detailsMap = service.makeUpdatedDetailsMap(detailsMap, fullQueriedRecords, processedObjectKey);
		}

		System.debug('Details service values map: '+detailsMap.values());

        return detailsMap.values();
    }


	// Queries for all records including lookups referenced in sharing and sets these in list
	private Map<Id,SObject> getFullQueriedRecords(Schema.SObjectType type) {

		// Create selector
		FormulaShareSObjectsSelector selector = new FormulaShareSObjectsSelector(true, type);

		// Add required field paths, including those to parent objects
		for(FormulaShareRuleTypeServiceBase service : ruleTypeServices) {

			Set<FormulaShareRule> rules;

			// We'll need paths from all rules if there's a chance we'll remove 
			// sharing for a standard object and service shares this object
			if(service.sharesProcessedObject() && assessAllRules) {
				rules = service.fullRules;
			}

			// Otherwise we can be confident to proceed without checking rules where sharing shouldn't change
			else {
				rules = service.relevantRules;
			}

			// Add paths to all fields we might need to reference to assess rules
			for(FormulaShareRule rule : rules) {
				selector.addFieldString(rule.pathToSharedToField);
				selector.addFieldString(rule.pathToSharedObject);

				if(rule.shareWith == 'Users') {
					selector.addFieldString(rule.pathToOwnerIdOnShared);
				}
			}
		}

		List<SObject> queriedList = selector.selectWithFields(recordsToQuery);
		Map<Id,SObject> fullQueriedRecords = new Map<Id,SObject>((List<SObject>) queriedList);
		
		return fullQueriedRecords;
	}

}