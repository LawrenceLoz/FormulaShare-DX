/**
*Copyright 2018 Lawrence Newcombe
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

public inherited sharing class FormulaShareService {

    public static FormulaShareService mock;

	// Set type and rules if provided on creation
    public static FormulaShareService construct(Schema.SObjectType type, List<FormulaShareRule> rules) {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
		else {
			FormulaShareService fsService = new FormulaShareService();
			fsService.type = type;
			fsService.rules = rules;
			return fsService;
		}
    }

	// Or get rules if only type provided
	public static FormulaShareService construct(Schema.SObjectType type) {
        FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();
		List<FormulaShareRule> rules = rulesSelector.getRulesSharingObject(type);
		return construct(type, rules);
	}


	public class FormulaShareException extends Exception{}

	static FormulaShare_Settings__mdt settings;
	public Map<String,Id> sharingReasonsIdMap = new Map<String,Id>();
//	@TestVisible private Map<Id,SObject> recordsMap = new Map<Id,SObject>();

	@TestVisible private Set<Id> sharedRecordIdsSet = new Set<Id>();
	private Set<Id> recordsSharingStillInPlace = new Set<Id>();	// All records where FS sharing will remain in place
	private Set<Id> existingSharesValidSet = new Set<Id>();		// All ids which were previously shared (regardless of whether sharing will be changed)
	private Set<Id> newSharesValidSet = new Set<Id>();		// All ids which were previously shared (regardless of whether sharing will be changed)
	@TestVisible private List<FormulaShareRetrievedRecordDetails> recordDetails;
	private String queryExceptionMessage;
	
	private Map<String,Integer> noValidSharesForRules = new Map<String,Integer>();
	@TestVisible private Map<String,ShareDetail> mapToDelete = new Map<String,ShareDetail>();
	private Map<String,ShareDetail> mapToInsert = new Map<String,ShareDetail>();

	@TestVisible Set<String> existingShareKeys = new Set<String>();
	private List<EntityNotFound> entitiesNotFound = new List<EntityNotFound>();

	private Boolean contactIsControlledByAccount;

	@TestVisible private Schema.SObjectType type;
	@TestVisible private List<FormulaShareRule> rules = new List<FormulaShareRule>();
	Boolean removeExistingShares = true;
	

	// Getter methods to access variables needed by calling classes. Methods are mocked for test classes

	// TODO - MAY NOT NEED THESE GOING FORWARD (delete also methods in mock provider)
	public List<SObject> getSharesToInsert() {
		List<SObject> sharesList = new List<SObject>();
		for(ShareDetail sd : mapToInsert.values()) {
			sharesList.add(sd.shareRecord);
		}
		return sharesList;
	}
	public List<SOBject> getSharesToDelete() {
		List<SObject> sharesList = new List<SObject>();
		for(ShareDetail sd : mapToDelete.values()) {
			sharesList.add(sd.shareRecord);
		}
		return sharesList;
	}

	Integer noRecordsSharingStillInPlace;
	Integer noRecordsNotShared;
	public Integer getNoRecordsSharingStillInPlace() {
		if(noRecordsSharingStillInPlace == null) {
			assessNoRecordsShared();
		}
		return noRecordsSharingStillInPlace;
	}
	public Integer getNoRecordsNotShared() {
		if(noRecordsNotShared == null) {
			assessNoRecordsShared();
		}
		return noRecordsNotShared;
	}
	
	private void assessNoRecordsShared() {

		// We'll want to count only records which aren't present in at least one of the maps to attempt to insert or delete
		Set<Id> recordsWithShareChanges = new Set<Id>();
		recordsWithShareChanges.addAll(newSharesValidSet);
		for(String shareKey : mapToDelete.keySet()) {
			ShareDetail sd = mapToDelete.get(shareKey);
			recordsWithShareChanges.add(sd.recordId);
		}

		// Records w/ sharing to remain in place will have 
		recordsSharingStillInPlace.removeAll(recordsWithShareChanges);
		this.noRecordsSharingStillInPlace = recordsSharingStillInPlace.size();

		// All other records considered by the batch are not shared by FormulaShare
		this.noRecordsNotShared = sharedRecordIdsSet.size() - recordsWithShareChanges.size() - noRecordsSharingStillInPlace;
	}


	// Return number of valid shares per rule (to create metrics on batch run if they don't exist)
	public Map<String,Integer> getNoValidSharesForRules() {
		return noValidSharesForRules;
	}

	// Return full details of share context for logging event
	public Map<String,ShareDetail> getInsertDetails() {
		return mapToInsert;
	}
	public Map<String,ShareDetail> getDeleteDetails() {
		return mapToDelete;
	}
	public List<EntityNotFound> getEntitiesNotFound() {
		return entitiesNotFound;
	}

	public Schema.SObjectType getType() {
		return type;
	}

	public void setSharedRecordDetails(List<FormulaShareRetrievedRecordDetails> recordDetails) {
		this.recordDetails = recordDetails;

		if(recordDetails != null) {
			for(FormulaShareRetrievedRecordDetails detail : recordDetails) {
				sharedRecordIdsSet.add(detail.sharedRecord.Id);
			}
		}
	}

	// Passing exception causes Internal Salesforce Error when moissues with mocking
	public void testSetQueryException(String queryExceptionMessage) {
		this.queryExceptionMessage = queryExceptionMessage;
	}


	// Used by batch job start to retrieve core query selector (ids only)
	public static Database.QueryLocator getAllSharedObjectsLocator(Schema.sObjectType type) {
		Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(type);

		Schema.SObjectField idField = fieldMap.get('Id');
		fieldsSet.add(idField);

		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;

		FormulaShareSObjectsSelector selector = new FormulaShareInjectionService().getSObjectsSelector(enforceObjectAndFieldSecurity, type);
		selector.setFields(fieldsSet);
		Database.QueryLocator ql = selector.selectAllLocator();
		
		return ql;
	}


	// Submits batch recalculation of all sharing
	public static void recalculateAll() {
		List<Schema.SObjectType> types = getSharedObjectTypes();
		if(!types.isEmpty()) {
			FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
			Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, 'Full Recalculation Batch', batchSize), batchSize);
		}
	}
	

	// Core method called from trigger and batch context - returns a wrapper with all details needed to make updates
	public void processFormulaShares() {

		// Set map tracking number of shares for rules with zeros
		for(FormulaShareRule rule : rules) {
			noValidSharesForRules.put(rule.developerName, 0);
		}

		// If no records populated (e.g. lookups towards shared object are blank), no need to process
		if(sharedRecordIdsSet.isEmpty()) {
			return;
		}

		// For account sharing, determine whether contact sharing is controlled by account
		if(type.getDescribe().getName() == 'Account') {
			contactIsControlledByAccount = FormulaShareUtilities.isContactSharingControlledByAccount();
		}

		// Query for existing shares
		List<SObject> sharesQueryResult;
		if(queryExceptionMessage != null) {
			logExceptionAllRecords('Running user permission error for '+type.getDescribe().getName()+' sharing: '+queryExceptionMessage);
		}
		else {
			try {
				sharesQueryResult = getExistingShares();
			}
			catch(fflib_SObjectDomain.DomainException e) {
				System.debug('Exception due to user access permissions: '+e.getMessage());
				logExceptionAllRecords('Running user permission error for '+type.getDescribe().getName()+' share object: '+e.getMessage());
			}
		}

		// Continue if no exceptions querying source object or shares
		if(sharesQueryResult != null) {

			// Create map of all record shares with unique key
			// Any required shares will be removed from this map and the remainder deleted (if settings allow this)
			for(SObject share : sharesQueryResult) {
				FormulaShareSObjectUtilities objectUtils = new FormulaShareSObjectUtilities(type);
				ShareDetail sd = new ShareDetail();
				sd.shareRecord = share;
				sd.type = type;
				sd.recordId = objectUtils.getParentIdFromShare(share);
				String shareKey = objectUtils.getShareKey(share, sd.recordId);
				mapToDelete.put(shareKey, sd);
			}

			// Clone so we can check existing sharing after removing shares from deletion map
			existingShareKeys = mapToDelete.keySet().clone();

			// Assess sharing to be created or kept (will update deletion and insertion maps)
			assessRequiredShares();

			// Get set of records w/ sharing which is no longer valid (based on mapToDelete)
			Set<Id> existingSharesInvalidSet = getInvalidIdSet();

			// Clear deletion map if removal of standard sharing is not permitted
			if(!isShareRemovalAllowed()) {
				mapToDelete.clear();
			}

			// Add indication whether each record w/ sharing to INSERT was shared already
			augmentWithExistingSharing(mapToInsert, existingSharesValidSet);
			augmentWithExistingSharing(mapToInsert, existingSharesInvalidSet);

			// Add indication whether each record w/ sharing to DELETE still has valid sharing which will be created or kept
			augmentWithExistingSharing(mapToDelete, newSharesValidSet);
			augmentWithExistingSharing(mapToDelete, existingSharesValidSet);
		}
	}


	private void logExceptionAllRecords(String logMessage) {
		for(FormulaShareRule rule : rules) {
			for(FormulaShareRetrievedRecordDetails details : recordDetails) {
				captureEntityNotFound(details.sharedRecord, rule, logMessage);
			}
		}
	}


	private Set<Id> getInvalidIdSet() {
		Set<Id> invalidIdsSet = new Set<Id>();
		for(ShareDetail sd : mapToDelete.values()) {
			invalidIdsSet.add(sd.recordId);
		}
		return invalidIdsSet;
	}

	private void augmentWithExistingSharing(Map<String,ShareDetail> inputMap, Set<Id> setToCheck) {
		for(String shareKey : inputMap.keySet()) {
			String recordIdString = shareKey.left(15);	// Left-most 15 characters of share key are the shared record id
			Id recordId = (Id) recordIdString;
			if(setToCheck.contains(recordId)) {
				ShareDetail sd = inputMap.get(shareKey);
				sd.existingSharingOnRecord = true;
				inputMap.put(shareKey, sd);
			}
		}
	}	



	// Retrieve shares for all shared objects identified as being in scope
	private List<SObject> getExistingShares() {
		List<SObject> sharesQueryResult = new List<SObject>();

		// Get object's share type, initialise selector and build string of parent Ids to query
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);
		FormulaShareSObjectSharesSelector sharesSelector = new FormulaShareSObjectSharesSelector(true, shareObjectType, type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(sharedRecordIdsSet);
		System.debug('parentIdsString: '+parentIdsString);

		// If custom, select by parent Ids and sharing reasons
		if(type.getDescribe().isCustom()) {
			
			// Get all relevant row causes (aka apex sharing reasons) used in rules
			Set<String> rowCauseSet = new Set<String>();
			for(FormulaShareRule rule : rules) {
				rowCauseSet.add(rule.sharingReason);
			}
			String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(rowCauseSet);
			System.debug('rowCausesString: '+rowCausesString);

			// Query for relevant share records via selector. Exception if user doesn't have access
			// (e.g. if related object user doesn't have permissions for). This is handled in calling method
			sharesQueryResult = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
		}

		// If standard, select by parent Ids only
		else {
			sharesQueryResult = sharesSelector.selectByParentIds(parentIdsString);	// Exception handled in calling method
		}

		system.debug('Share query result: '+sharesQueryResult);

		return sharesQueryResult;
	}

	List<FormulaShareShareWithBase> shareWithClasses = new FormulaShareInjectionService().getShareWithClasses(this);

	private void assessRequiredShares() {

		system.debug('*** Records to be assessed: '+recordDetails);
		system.debug('*** Rules to be assessed: '+rules);

		List<RecordRule> allRecordRules = buildRecordRules();

		for(RecordRule recRule : allRecordRules) {

			FormulaShareRule rule = recRule.rule;
			String sharedToString = recRule.sharedToString;

			system.debug('*** this rule: '+rule);
			system.debug('*** the record: '+recRule.recordWithSharedToDetails);
			system.debug('sharedToAPIName: '+rule.pathToSharedToField);
			system.debug('shared to string: ' + sharedToString);
			
			if(rule.isValid() && rule.active) {
				System.debug('rule.controllingObjectSharedToFieldType: '+rule.controllingObjectSharedToFieldType);

				for(FormulaShareShareWithBase shareWithClass: shareWithClasses) {
					shareWithClass.checkAndAdd(sharedToString, recRule);
				}
			}

			else if(!rule.isValid()) {
				String logMessage = 'Invalid rule metadata, check configuration for rule: '+rule.developerName;
				captureEntityNotFound(recRule, logMessage);
			}
		}

		for(FormulaShareShareWithBase shareWithClass: shareWithClasses) {
			shareWithClass.assess();
		}
	}

	public void captureEntityNotFound(RecordRule recRule, String logMessage) {
		captureEntityNotFound(recRule.recordToShare, recRule.rule, logMessage);
	}

	private void captureEntityNotFound(SObject recordToShare, FormulaShareRule rule, String logMessage) {
		String targetAccessLevel = 'Not yet assessed';

		// Unless rule is for a default team, target access level is defined in the rule
		if(rule.shareWith != 'Default Account Teams of Users' && rule.shareWith != 'Default Opportunity Teams of Users') {
			targetAccessLevel = rule.accessLevel;
		}
		captureEntityNotFound(recordToShare.Id, targetAccessLevel, rule, logMessage);
	}

	public void captureEntityNotFound(Id recordId, String targetAccessLevel, FormulaShareRule rule, String logMessage) {
		EntityNotFound enf = new EntityNotFound();
		enf.recordId = recordId;
		enf.targetAccessLevel = targetAccessLevel;
		enf.rule = rule;
		enf.type = type;
		enf.failedStatusReason = logMessage.abbreviate(255);
		entitiesNotFound.add(enf);

		System.debug('Entity not found: '+enf);
	}


	private List<RecordRule> buildRecordRules() {

		FormulaShareSharedValueMapper valueMapper = new FormulaShareInjectionService().getSharedValueMapper();
		valueMapper.setRules(rules, recordDetails);

		List<RecordRule> allRecordRules = new List<RecordRule>();

		for(FormulaShareRule rule : rules) {

			for(FormulaShareRetrievedRecordDetails details : recordDetails) {

				List<SObject> controllingObjectsForRule = details.getControllingObjectsForRule(rule);

				for(SObject controllingObj : controllingObjectsForRule) {
					System.debug('controllingObj: '+controllingObj);
					System.debug('Rule: '+rule.developerName);
					RecordRule recRule = new RecordRule();
					recRule.recordToShare 			  = details.sharedRecord;
					recRule.recordWithSharedToDetails = controllingObj;
					recRule.rule 					  = rule;

					try {
						recRule.sharedToString = valueMapper.getSharedToValue(rule, controllingObj);
					}
					// FormulaShareException suggests share value can't be found for this record
					catch(FormulaShareException e) {
						captureEntityNotFound(recRule.recordToShare, recRule.rule, e.getMessage());
					}
					// Other exceptions are likely to be query exceptions, so log and don't add this record rule
					catch(Exception e) {
						logExceptionAllRecords(e.getMessage());
						break;
					}
					
					allRecordRules.add(recRule);
				}
			}
		}

		return allRecordRules;
	}



	public void updateShareMaps(Id recordId, Id sharedTo, String targetAccessLevel, FormulaShareRule rule) {

		// Check whether we have any shares for this record already
		String shareKey = getShareKey(recordId, sharedTo, rule);

		system.debug('*** searching with this Id: ' + shareKey);
		system.debug('*** full map keys: ' + mapToDelete.keySet() );
		system.debug('*** full keyset: ' + existingShareKeys );
		system.debug('result of search: ' + mapToDelete.get(shareKey));

		// If we have a share already for this record, entity and reason...
		if(mapToDelete.containsKey(shareKey)) {

			ShareDetail sd = mapToDelete.get(shareKey);
			SObject share = sd.shareRecord;
			FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
			String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

			// ...keep if it relates to record ownership (these shares can't be created by apex sharing)
			if(objectAccess == 'All') {
				System.debug('/// Existing share with full access, keep this: '+share);
				incrementShareMetrics(rule);
			}

			// If we're not permitted to remove sharing
			if(!isShareRemovalAllowed()) {

				// ...keep if all access levels for the share are the same or higher than the rule
				if(rule.shareEqualOrMorePermissiveThanRule(type, share, targetAccessLevel, contactIsControlledByAccount)) {
					System.debug('/// Share exists which is the same or more permissive than rule, keep this: '+share);
					recordsSharingStillInPlace.add(recordId);
					incrementShareMetrics(rule);
				}

				// ...if access levels differ, create a new share with highest access levels
				else {
					System.debug('/// Existing share exists, create one with max levels of rule and this share: '+share);
					populateMapHighestAccess(recordId, sharedTo, shareKey, targetAccessLevel, rule, contactIsControlledByAccount, share);
				}
			}

			// ...otherwise, if no ownership and we're allowed to remove sharing, create a new share with access level of the rule
			else {
				
				// ...keep if all access levels for the share are identical
				if(rule.shareEqualToRule(type, share, targetAccessLevel, contactIsControlledByAccount)) {
					System.debug('/// Share exists which is identical to the rule, keep this: '+share);
					recordsSharingStillInPlace.add(recordId);
					incrementShareMetrics(rule);
				}

				else {
					System.debug('/// Existing share exists with different level, create one with access levels of the rule instead. Existing share: '+share);
					populateMapNewShare(recordId, sharedTo, shareKey, targetAccessLevel, rule, contactIsControlledByAccount);
				}
			}

			// Remove from map to delete - share will be kept or updated
			mapToDelete.remove(shareKey);

			// Add to set tracking which records were already shared by FormulaShare
			this.existingSharesValidSet.add(recordId);
		}

		// Otherwise if we've already identified sharing is needed for this record...
		else if(mapToInsert.containsKey(shareKey)) {

			ShareDetail sd = mapToInsert.get(shareKey);
			SObject share = sd.shareRecord;

			// Create a new share which is maximally permissive, and replace this in the map
			System.debug('/// Updating a share already in insert map: '+share);
			populateMapHighestAccess(recordId, sharedTo, shareKey, targetAccessLevel, rule, contactIsControlledByAccount, share);
		}

		// Or, if sharing at this level doesn't exist now (and we haven't already identified sharing is needed), create sharing at this level
		else if(!existingShareKeys.contains(shareKey)) {
			System.debug('/// creating new share based on rule');
			populateMapNewShare(recordId, sharedTo, shareKey, targetAccessLevel, rule, contactIsControlledByAccount);
		}
	}


	private void incrementShareMetrics(FormulaShareRule rule) {
		Integer noShares = noValidSharesForRules.get(rule.developerName);
		noShares++;
		noValidSharesForRules.put(rule.developerName, noShares);
	}


	private String getShareKey(Id recordId, Id sharedTo, FormulaShareRule rule) {
		FormulaShareIdUtilities idUtil = FormulaShareIdUtilities.construct();

		// Instance method used to support mocking for standard objects
		String shareKey = idUtil.get15CharacterIdInstance(recordId)
			+ idUtil.get15CharacterIdInstance(sharedTo);
		if(type.getDescribe().isCustom()) {
			shareKey += rule.sharingReason;
		}
		
		return shareKey;
	}


	private void populateMapNewShare(Id recordId, Id sharedTo, String shareKey, String targetAccessLevel, FormulaShareRule rule, Boolean contactIsControlledByAccount) {

		// Check share can be constructed (might fail if OWD doesn't allow)
		SObject newShare;
		try {
			newShare = rule.getShareWithRuleDefaults(type, recordId, sharedTo, targetAccessLevel, contactIsControlledByAccount);
		}
		catch(FormulaShareRule.FormulaShareException e) {
			captureEntityNotFound(recordId, targetAccessLevel, rule, e.getMessage());
		}
		
		// Set up new share detail and add to insert map
		if(newShare != null) {
			addShareDetailToInsertMap(shareKey, recordId, targetAccessLevel, rule, newShare);
		}
	}

	private void populateMapHighestAccess(Id recordId, Id sharedTo, String shareKey, String targetAccessLevel, FormulaShareRule rule, Boolean contactIsControlledByAccount, SObject currentShare) {
		
		// Check share can be constructed (might fail if OWD doesn't allow)
		SObject newShare;
		try {
			newShare = rule.getMostPermissiveShare(type, recordId, sharedTo, targetAccessLevel, currentShare, contactIsControlledByAccount);
		}
		catch(FormulaShareRule.FormulaShareException e) {
			captureEntityNotFound(recordId, targetAccessLevel, rule, e.getMessage());
		}
		
		// Set up new share detail and add to insert map
		if(newShare != null) {
			addShareDetailToInsertMap(shareKey, recordId, targetAccessLevel, rule, newShare);
		}
	}


	// Create share detail object and add to insert map
	FormulaShareIOrgControls controls = new FormulaShareInjectionService().getOrgControls();
	private void addShareDetailToInsertMap(String shareKey, Id recordId, String targetAccessLevel, FormulaShareRule rule, SObject newShare) {

		if(controls.preventSharingInserts()) {
			String logMessage = controls.getErrorForPreventedSharingInserts();
			captureEntityNotFound(recordId, targetAccessLevel, rule, logMessage);
		}

		else {
			ShareDetail sd = new ShareDetail();
			sd.rule = rule;
			sd.shareRecord = newShare;
			sd.type = type;
			sd.recordId = recordId;
			mapToInsert.put(shareKey, sd);
			newSharesValidSet.add(recordId);

			// Track this as a valid share record to populate metrics
			incrementShareMetrics(rule);			
		}

	}
	

	private static List<SObjectType> getSharedObjectTypes() {

		List<SObjectType> typesList = new List<SObjectType>();
		Set<SObjectType> typesSet = new Set<SObjectType>();

		// Loop through all rules and populate set of shared objects
        FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();

		for(String objName : rulesSelector.selectObjectsWithRules(false).keySet()) {
			SObjectType type = FormulaShareUtilities.globalDescribe.get(objName);
			typesSet.add(type);
		}

		for(SObjectType type : typesSet) {
			typesList.add(type);
		}

		return typesList;
	}

	// Called by trigger method when we can't guarantee all record sharing is in scope of processing
	public void disableShareRemoval() {
		removeExistingShares = false;
	}

	private Boolean isShareRemovalAllowed() {
		FormulaShareSObjectUtilities objUtils = new FormulaShareSObjectUtilities(type);
		System.debug('removeExistingShares: '+ removeExistingShares + 'utils settig: '+objUtils.removeSharesForObject());
		return removeExistingShares && objUtils.removeSharesForObject();
	}


	public class ShareDetail {
		public SObject shareRecord;
		public Schema.SObjectType type;
		public FormulaShareRule rule;
		public Id recordId;
		public Boolean existingSharingOnRecord = false;	// True if sharing identified matching rules which will be kept
	}

	// Holds details of a record and a rule sharing this record
	public class RecordRule {
		public SObject recordToShare;
		public SObject recordWithSharedToDetails;
		public String sharedToString;
		public FormulaShareRule rule;
	}

	public class EntityNotFound {
		public String recordId;
		public Schema.SObjectType type;
		public FormulaShareRule rule;
		public String targetAccessLevel;
		public String failedStatusReason;
	}

}