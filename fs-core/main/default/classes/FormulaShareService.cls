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
		List<FormulaShareRule> rules = FormulaShareRulesSelector.construct().getRulesSharingObject(type);
		return construct(type, rules);
	}


	public class FormulaShareException extends Exception{}

	static FormulaShare_Settings__mdt settings;
	public Map<String,Id> sharingReasonsIdMap = new Map<String,Id>();
//	@TestVisible private Map<Id,SObject> recordsMap = new Map<Id,SObject>();

	@TestVisible private Set<Id> sharedRecordIdsSet = new Set<Id>();
	@TestVisible private List<FormulaShareRetrievedRecordDetails> recordDetails;
	
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


	// Used by batch job start to retrieve core query selector (ids only)
	public static Database.QueryLocator getAllSharedObjectsLocator(Schema.sObjectType type) {
		Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(type);

		Schema.SObjectField idField = fieldMap.get('Id');
		fieldsSet.add(idField);

		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;

		FormulaShareSObjectsSelector selector = FormulaShareSObjectsSelector.construct(enforceObjectAndFieldSecurity, type);
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
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, batchSize), batchSize);
		}
	}
	

	// Core method called from trigger and batch context - returns a wrapper with all details needed to make updates
	public void processFormulaShares() {

		// Set map tracking number of shares for rules with zeros
		for(FormulaShareRule rule : rules) {
			noValidSharesForRules.put(rule.developerName, 0);
		}

		// If no records populated (e.g. if lookups aren't populated), then no need to process
		if(sharedRecordIdsSet.isEmpty()) {
			return;
		}	

		// For account sharing, determine whether contact sharing is controlled by account
		if(type.getDescribe().getName() == 'Account') {
			contactIsControlledByAccount = FormulaShareUtilities.isContactSharingControlledByAccount();
		}

		// Query for existing shares
		List<SObject> sharesQueryResult = getExistingShares();

		// Create map of all record shares with unique key
		// Any required shares will be removed from this map and the remainder deleted (if settings allow this)
		for(SObject share : sharesQueryResult) {
			FormulaShareSObjectUtilities objectUtils = new FormulaShareSObjectUtilities(type);
			String shareKey = objectUtils.getShareKey(share);
			ShareDetail sd = new ShareDetail();
			sd.shareRecord = share;
			sd.type = type;
			mapToDelete.put(shareKey, sd);
		}

		// Clone so we can check existing sharing after removing shares from deletion map
		existingShareKeys = mapToDelete.keySet().clone();

		// Assess sharing to be created or kept (will update deletion and insertion maps)
		assessRequiredShares();

		// Clear deletion map if object is standard and removal of standard sharing is not permitted
		if(!isShareRemovalAllowed()) {
			mapToDelete.clear();
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

			// Query for relevant share records via selector
			sharesQueryResult = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
		}

		// If standard, select by parent Ids only
		else {
			sharesQueryResult = sharesSelector.selectByParentIds(parentIdsString);
		}

		system.debug('Share query result: '+sharesQueryResult);

		return sharesQueryResult;
	}


	private void assessRequiredShares() {
		
		Set<Id> userQueryIdSet = new Set<Id>();
		Set<Id> roleQueryIdSet = new Set<Id>();

		Set<FormulaShareServiceSObjectRule> userRecordRules = new Set<FormulaShareServiceSObjectRule>();
		Set<FormulaShareServiceSObjectRule> roleRecordRules = new Set<FormulaShareServiceSObjectRule>();
		Set<FormulaShareServiceSObjectRule> groupRecordRules = new Set<FormulaShareServiceSObjectRule>();

		Set<String> sharedToNamesGroups = new Set<String>();
		Set<String> sharedToNamesRoles = new Set<String>();

		system.debug('Records to be assessed: '+recordDetails);
		system.debug('Rules to be assessed: '+rules);

		List<FormulaShareServiceSObjectRule> allRecordRules = buildRecordRules();

		for(FormulaShareServiceSObjectRule recordRule : allRecordRules) {

			FormulaShareRule rule = recordRule.rule;
			String sharedToString = recordRule.sharedToString;

			system.debug('this rule: '+rule);
			system.debug('*** the record: '+recordRule.recordWithSharedToDetails);
			system.debug('*** sharedToAPIName: '+rule.pathToSharedToField);
			system.debug('shared to string: ' + sharedToString);
			
			if(rule.isValid() && rule.active) {
				System.debug('rule.controllingObjectSharedToFieldType: '+rule.controllingObjectSharedToFieldType);

				// Add User Id to map
				if(rule.shareWith == 'Users') {
					if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.User.getSObjectType())) {
						userQueryIdSet.add((Id) sharedToString);
						userRecordRules.add(recordRule);
					}
					else {
						String logMessage = 'Expected field to contain valid user id. Instead found: ' + sharedToString;
						captureEntityNotFound(recordRule, logMessage);
					}
				}

				// Add Group Id to map
				else if(rule.shareWith == 'Public Groups') {
					if(rule.controllingObjectSharedToFieldType == 'Id') {
						if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.Group.getSObjectType())) {
							updateShareMaps(recordRule.recordToShare.Id, (Id) sharedToString, rule);
						}
						else {
							String logMessage = 'Expected field to contain valid group id. Instead found: ' + sharedToString;
							captureEntityNotFound(recordRule, logMessage);
						}
					}
					else if(rule.controllingObjectSharedToFieldType == 'Name') {
						sharedToNamesGroups.add(sharedToString);
						groupRecordRules.add(recordRule);
					}
				}

				// Add Role Id to role group query set
				else if(rule.shareWith == 'Roles' || rule.shareWith == 'Roles and Internal Subordinates' || rule.shareWith == 'Roles, Internal and Portal Subordinates') {
					if(rule.controllingObjectSharedToFieldType == 'Id') {
						if(FormulaShareIdUtilities.construct().isValidIdType(sharedToString, Schema.UserRole.getSObjectType())) {
							roleQueryIdSet.add((Id) sharedToString);
							roleRecordRules.add(recordRule);
						}
						else {
							String logMessage = 'Expected field to contain valid role id. Instead found: ' + sharedToString;
							captureEntityNotFound(recordRule, logMessage);
						}
					}
					else if(rule.controllingObjectSharedToFieldType == 'Name') {
						System.debug('Adding share for role rule with name');
						sharedToNamesRoles.add(sharedToString);
						roleRecordRules.add(recordRule);
					}
				}

				else system.debug('Share With value ' + rule.shareWith + ' does not match allowed options');
			}

			else if(!rule.isValid()) {
				String logMessage = 'Invalid rule metadata, check configuration for rule: '+rule.developerName;
				captureEntityNotFound(recordRule, logMessage);
			}
		}

		// Process user sharing
		if(!userRecordRules.isEmpty()) {
			assessUserSharingFromIds(userQueryIdSet, userRecordRules);
		}

		// Process group sharing
		if(!groupRecordRules.isEmpty()) {
			assessGroupSharingFromNames(sharedToNamesGroups, groupRecordRules);
		}

		// Query for role Ids if needed and create map
		Map<String,Id> roleNamesToIdsMap = new Map<String,Id>();
		if(!sharedToNamesRoles.isEmpty()) {
			List<UserRole> rolesList = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :sharedToNamesRoles];

			for(UserRole role : rolesList) {
				roleNamesToIdsMap.put(role.DeveloperName, role.Id);
			}
		}

		// Process role and/or role and subordinate sharing
		if(!roleRecordRules.isEmpty()) {
			assessRoleSharing(roleQueryIdSet, roleRecordRules, roleNamesToIdsMap);
		}
	}


	private void captureEntityNotFound(FormulaShareServiceSObjectRule recordRule, String logMessage) {
		captureEntityNotFound(recordRule.recordToShare.Id, recordRule.rule, logMessage);
	}

	private void captureEntityNotFound(Id recordId, FormulaShareRule rule, String logMessage) {
		EntityNotFound enf = new EntityNotFound();
		enf.recordId = recordId;
		enf.rule = rule;
		enf.type = type;
		enf.failedStatusReason = logMessage.abbreviate(255);
		entitiesNotFound.add(enf);

		System.debug('Entity not found: '+enf);
	}


	private List<FormulaShareServiceSObjectRule> buildRecordRules() {
		List<FormulaShareServiceSObjectRule> allRecordRules = new List<FormulaShareServiceSObjectRule>();

		for(FormulaShareRule rule : rules) {
			for(FormulaShareRetrievedRecordDetails details : recordDetails) {
				SObject record = details.sharedRecord;
				
				// If shared to details are on the shared object, then this object in the record rule
				if(rule.type == 'standard' || rule.type == 'ancestor') {
					FormulaShareServiceSObjectRule recordRule = new FormulaShareServiceSObjectRule(details.sharedRecord, rule);
					allRecordRules.add(recordRule);
					system.debug('*** processing standard '+ details.sharedRecord);
				}

				// Otherwise, create record rules for the relevant records from the related object
				else {
					System.debug('rule: '+ rule);
					System.debug('details: '+details);
					System.debug('details.controllingRecordsForRulesMap: '+details.controllingRecordsForRulesMap);

					if(details.controllingRecordsForRulesMap.containsKey(rule.developerName)) {
						List<SObject> controllingObjectsForRule = details.controllingRecordsForRulesMap.get(rule.developerName);

						for(SOBject relatedObj : controllingObjectsForRule) {
							FormulaShareServiceSObjectRule recordRule = new FormulaShareServiceSObjectRule(details.sharedRecord, relatedObj, rule);
							allRecordRules.add(recordRule);
						}
					}
				}
			}
		}

		return allRecordRules;
	}


	private void assessUserSharingFromIds(Set<Id> userQueryIdSet, Set<FormulaShareServiceSObjectRule> userRecordRules) {
		
		Set<Id> activeUsersIdSet = getActiveUsers(userQueryIdSet);

		system.debug('user record rules: ' + userRecordRules);

		for(FormulaShareServiceSObjectRule recordRule : userRecordRules) {
			system.debug('Looking for this shared to: ' + recordRule.sharedToString);
			system.debug('in this object: ' + recordRule.recordWithSharedToDetails);

			system.debug('rec to share: ' + recordRule.recordToShare);
			system.debug('share to field: ' + recordRule.sharedToString);

			// If user is set on record
			if(recordRule.sharedToString != null) {
	
				Id userId = (Id) recordRule.sharedToString;
				system.debug('Found this id: ' + userId);
				system.debug('objects owner: ' + recordRule.recordToShare.get('OwnerId'));
				system.debug('activeUsersIdSet: ' + activeUsersIdSet);
	
				// If user is active and not already the record owner then create sharing record
				if(activeUsersIdSet.contains(userId) && userId != recordRule.recordToShare.get('OwnerId')) {
					system.debug('adding to map for insert');
					updateShareMaps(recordRule.recordToShare.Id, userId, recordRule.rule);
				}
	
				// If user not found log this as error
				else if(!activeUsersIdSet.contains(userId)) {
					String logMessage = 'No active user found with id ' + userId;
					captureEntityNotFound(recordRule, logMessage);
				}
			}
		}
	}


	private static Set<Id> getActiveUsers(Set<Id> userQueryIdSet) {
		Map<Id,User> activeUserMap = new Map<Id,User>([SELECT Id FROM User WHERE Id IN :userQueryIdSet AND IsActive = TRUE]);
		return activeUserMap.keySet();
	}


	private void assessGroupSharingFromNames(Set<String> groupNames, Set<FormulaShareServiceSObjectRule> groupRecordRules) {

		Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

		for(FormulaShareServiceSObjectRule recordRule : groupRecordRules) {

			// Update share maps or log only if group is set on record
			if(recordRule.sharedToString != null) {
				String sharedToName = (String) recordRule.sharedToString;
				Id groupId = groupsMap.get(sharedToName);
	
				if(groupId != null) {
					updateShareMaps(recordRule.recordToShare.Id, groupId, recordRule.rule);
				}
	
				else {
					String logMessage = 'Field value \''+sharedToName+'\' should correspond to an active public group, but no group was found with this name';
					captureEntityNotFound(recordRule, logMessage);
				}
			}
		}
	}


	private static Map<String,Id> getGroupsFromNames(Set<String> groupNames) {
		Map<String,Id> groups = new Map<String,Id>();

		// Query for matching public groups and queues
		for(Group grp : [SELECT Id, DeveloperName FROM Group 
			WHERE DeveloperName IN :groupNames
			AND (Type = 'Regular' OR Type = 'Queue' OR Type = 'Organization')]) {
			groups.put(grp.DeveloperName,grp.Id);
		}
		return groups;
	}


	private void assessRoleSharing(Set<Id> roleQueryIdSet, Set<FormulaShareServiceSObjectRule> roleRecordRules, Map<String,Id> roleNamesToIdsMap) {

		// Build map of required group Ids for role groups
		Map<String,Id> roleGroupIds = new Map<String,Id>();

		for(Group grp : [SELECT Id, RelatedId, Type 
			FROM Group 
			WHERE (RelatedId IN :roleQueryIdSet OR RelatedId IN :roleNamesToIdsMap.values())
			AND (Type = 'Role' OR Type = 'RoleAndSubordinatesInternal' OR Type = 'RoleAndSubordinates')
			]) {

			String shortRelatedToId = FormulaShareIdUtilities.get15CharacterId(grp.RelatedId);
			String key = shortRelatedToId + grp.Type;
			system.debug('Added roleGroupEntry key: '+key+' for group: '+grp.Id);
			roleGroupIds.put(key, grp.Id);
		}


		// Update sharing maps to create or keep role shares
		system.debug('*** Delete map before assessment: ' + mapToDelete.keySet() );
		for(FormulaShareServiceSObjectRule recordRule : roleRecordRules) {
			System.debug('recordRule.sharedToString: '+recordRule.sharedToString);
			System.debug('recordRule.sharedToString: '+recordRule.sharedToString);

			// If role field is not blank on record
			if(recordRule.sharedToString != null) {
				String sharedTo = (String) recordRule.sharedToString;
				Id sharedToId = null;
				Id roleGroupId = null;
	
				if(recordRule.rule.controllingObjectSharedToFieldType == 'Name') {
					if(roleNamesToIdsMap.containsKey(sharedTo)) {
						sharedToId = roleNamesToIdsMap.get(sharedTo);
					}
					else {
						String logMessage = 'Field value \''+sharedTo+'\' should correspond to an active role, but no role was found with this name';
						captureEntityNotFound(recordRule, logMessage);
						continue;	// No need to process remaining recordRule logic
					}
				}
	
				else if(recordRule.rule.controllingObjectSharedToFieldType == 'Id') {
					sharedToId = (Id) sharedTo;
				}
	
				String shortSharedToId = FormulaShareIdUtilities.get15CharacterId(sharedToId);
	
				// Get group for Roles sharing
				if(recordRule.rule.shareWith == 'Roles') {
					roleGroupId = roleGroupIds.get(shortSharedToId + 'Role');
				}
	
				// Get group for Roles and Internal Subordinates sharing
				else if(recordRule.rule.shareWith == 'Roles and Internal Subordinates') {
	
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
	
				// Get group for Roles, Internal and Portal Subordinates sharing
				else if(recordRule.rule.shareWith == 'Roles, Internal and Portal Subordinates') {
					roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
				}
	
				if(roleGroupId != null) {
					updateShareMaps(recordRule.recordToShare.Id, roleGroupId, recordRule.rule);
				}
	
				else {
					String logMessage = 'Role \''+recordRule.sharedToString+'\' specified on record is not valid for sharing';
					captureEntityNotFound(recordRule, logMessage);
				}
			}
		}
		system.debug('*** Delete map after assessment: ' + mapToDelete.keySet() );
	}


	private void updateShareMaps(Id recordId, Id sharedTo, FormulaShareRule rule) {

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
			}

			// If we're not permitted to remove sharing
			if(!isShareRemovalAllowed()) {

				// ...keep if all access levels for the share are the same or higher than the rule
				if(rule.shareEqualOrMorePermissiveThanRule(type, share, contactIsControlledByAccount)) {
					System.debug('/// Share exists which is the same or more permissive than rule, keep this: '+share);
				}

				// ...if access levels differ, create a new share with highest access levels
				else {
					System.debug('/// Existing share exists, create one with max levels of rule and this share: '+share);
					populateMapHighestAccess(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount, share);
				}
			}

			// ...otherwise, if no ownership and we're allowed to remove sharing, create a new share with access level of the rule
			else {
				
				// ...keep if all access levels for the share are identical
				if(rule.shareEqualToRule(type, share, contactIsControlledByAccount)) {
					System.debug('/// Share exists which is identical to the rule, keep this: '+share);
				}

				else {
					System.debug('/// Existing share exists with different level, create one with access levels of the rule instead. Existing share: '+share);
					populateMapNewShare(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount);
				}
			}

			// Remove from map to delete - share will be kept or updated
			mapToDelete.remove(shareKey);

			// Track this as a valid share record to populate metrics
			incrementShareMetrics(rule);
		}

		// Otherwise if we've already identified sharing is needed for this record...
		else if(mapToInsert.containsKey(shareKey)) {

			ShareDetail sd = mapToInsert.get(shareKey);
			SObject share = sd.shareRecord;

			// Create a new share which is maximally permissive, and replace this in the map
			System.debug('/// Updating a share already in insert map: '+share);
			populateMapHighestAccess(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount, share);
		}

		// Or, if sharing at this level doesn't exist now (and we haven't already identified sharing is needed), create sharing at this level
		else if(!existingShareKeys.contains(shareKey)) {
			System.debug('/// creating new share based on rule');
			populateMapNewShare(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount);

			// Track this as a valid share record to populate metrics
			incrementShareMetrics(rule);
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


	private void populateMapNewShare(Id recordId, Id sharedTo, String shareKey, FormulaShareRule rule, Boolean contactIsControlledByAccount) {
		
		// Check share can be constructed (might fail if OWD doesn't allow)
		SObject newShare;
		try {
			newShare = rule.getShareWithRuleDefaults(type, recordId, sharedTo, contactIsControlledByAccount);
		}
		catch(FormulaShareRule.FormulaShareException e) {
			captureEntityNotFound(recordId, rule, e.getMessage());
		}
		
		// Set up new share detail and add to insert map
		if(newShare != null) {
			addShareDetailToInsertMap(shareKey, rule, newShare);
		}
	}

	private void populateMapHighestAccess(Id recordId, Id sharedTo, String shareKey, FormulaShareRule rule, Boolean contactIsControlledByAccount, SObject currentShare) {
		
		// Check share can be constructed (might fail if OWD doesn't allow)
		SObject newShare;
		try {
			newShare = rule.getMostPermissiveShare(type, recordId, sharedTo, currentShare, contactIsControlledByAccount);
		}
		catch(FormulaShareRule.FormulaShareException e) {
			captureEntityNotFound(recordId, rule, e.getMessage());
		}
		
		// Set up new share detail and add to insert map
		if(newShare != null) {
			addShareDetailToInsertMap(shareKey, rule, newShare);
		}
	}


	// Create share detail object and add to insert map
	private void addShareDetailToInsertMap(String shareKey, FormulaShareRule rule, SObject newShare) {
		System.debug('shareKey: '+shareKey);
		ShareDetail sd = new ShareDetail();
		sd.rule = rule;
		sd.shareRecord = newShare;
		sd.type = type;
		System.debug('ShareDetail: '+sd);
		mapToInsert.put(shareKey, sd);
	}
	

	private static List<SObjectType> getSharedObjectTypes() {

		List<SObjectType> typesList = new List<SObjectType>();
		Set<SObjectType> typesSet = new Set<SObjectType>();

		// Loop through all rules and populate set of shared objects
		for(String objName : FormulaShareRulesSelector.construct().selectObjectsWithRules()) {
			SObjectType type = FormulaShareUtilities.globalDescribe.get(objName);
			typesSet.add(type);
		}

		for(SObjectType type : typesSet) {
			typesList.add(type);
		}



//		if(!Test.isRunningTest()) {
//			for(SObjectType type : typesSet) {
//				typesList.add(type);
//			}
//		}
//
//		// If running test return list with FormulaShareRule to enable execution of other code
//		else {
//			typesList.add(FormulaShare_Log__c.SObjectType);
//		}

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
	}

	public class EntityNotFound {
		public String recordId;
		public Schema.SObjectType type;
		public FormulaShareRule rule;
		public String failedStatusReason;
	}

}