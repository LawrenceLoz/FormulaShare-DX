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
	@TestVisible private Map<Id,SObject> recordsMap = new Map<Id,SObject>();
	
	private Map<String,Integer> noValidSharesForRules = new Map<String,Integer>();
	@TestVisible private Map<String,ShareDetail> mapToDelete = new Map<String,ShareDetail>();
	private Map<String,ShareDetail> mapToInsert = new Map<String,ShareDetail>();
	@TestVisible Set<String> existingShareKeys = new Set<String>();
	private List<EntityNotFound> entitiesNotFound = new List<EntityNotFound>();

	private Boolean contactIsControlledByAccount;

	private Schema.SObjectType type;
	@TestVisible private List<FormulaShareRule> rules = new List<FormulaShareRule>();

	// Wrapper for a record and a rule sharing this record
	private class SObjectRule {
		SObject recordToShare;
		SObject recordWithSharedToDetails;
		FormulaShareRule rule;
	}
	

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

	public void addToRecordsMap(List<SObject> records) {
		if(records != null) {
			for(SOBject record : records) {
				this.recordsMap.put(record.Id, record);
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

		Database.QueryLocator ql = new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity,type,fieldsSet).selectAllSharedObjectsLocator();
		return ql;
	}


	// Used by batch job execute to re-query for details of objects in scope
	public static List<SObject> getSObjectsWithFields(Schema.sObjectType type, List<FormulaShareRule> rules, Set<Id> sharedObjIdSet) {

		Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(type);

		Map<String,FormulaShareSObjectsSelector.RelatedObjectDetails> rodMap = new Map<String,FormulaShareSObjectsSelector.RelatedObjectDetails>();
		Map<String,Map<String, SObjectField>> childObjectFieldMaps = new Map<String,Map<String, SObjectField>>();

        for(FormulaShareRule rule : rules) {

			// If rule references a field on the shared object, populate details
			if(rule.type == 'standard') {
				Schema.SObjectField field = fieldMap.get(rule.sharedToAPIName);
				fieldsSet.add(field);

				// Also add the OwnerId field if rule shares to users (required for later comparisons)
				if(rule.shareWith == 'Users') {
					Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
					fieldsSet.add(ownerIdField);
				}
			}

			// If the rule references child objects to determine sharing, populate details of objects and fields for sub-selects
			else if(rule.type == 'child') {
				system.debug('processing child rule: '+ rule);

				FormulaShareSObjectsSelector.RelatedObjectDetails rod;
				String key = rule.childObjectWithSharedToFieldAPIName + rule.childObjectLookupFieldAPIName;

				// Check whether we have this object and relationship in map already, and get the details if so (we'll add the shared field)
				// Also get the field map populate when the object was assessed previously
				if(rodMap.containsKey(key)) {
					rod = rodMap.get(key);
				}

				// Otherwise create a new set of details
				else {
					rod = new FormulaShareSObjectsSelector.RelatedObjectDetails();
					rod.type = FormulaShareUtilities.globalDescribe.get(rule.childObjectWithSharedToFieldAPIName);
					rod.relationshipName = FormulaShareUtilities.getRelationshipName(rule.objectSharedAPIName, rule.childObjectWithSharedToFieldAPIName, rule.childObjectLookupFieldAPIName);
					rod.fields = new Set<Schema.SObjectField>();

					system.debug('child api name: ' + rule.childObjectWithSharedToFieldAPIName);
					system.debug('desc: ' + rod.type);
				}

				// Get the type for field and add this to the set field details
				Map<String, SObjectField> childObjectFieldMap = FormulaShareUtilities.getFieldMap(rule.childObjectWithSharedToFieldAPIName);
				Schema.SObjectField childField = childObjectFieldMap.get(rule.childObjectSharedToFieldAPIName);
				rod.fields.add(childField);

				system.debug('this rod '+rod);

				rodMap.put(key, rod);
			}
        }
		
		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;
//		Boolean enforceObjectAndFieldSecurity = false;

		List<SObject> objectLocator = new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity,type,fieldsSet).selectWithFieldsForObjectList(rodMap.values(), sharedObjIdSet);
		return objectLocator;
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

		Boolean removeExistingShares = true;

		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordsMap.keySet());
		System.debug('parentIdsString: '+parentIdsString);
		System.debug('type: ' +shareObjectType.getDescribe().getName());

		// Retrieve current record shares if type in scope is a custom object
		List<SObject> sharesQueryResult;

		// Set map tracking number of shares for rules with zeros
		for(FormulaShareRule rule : rules) {
			noValidSharesForRules.put(rule.developerName, 0);
		}

		FormulaShareSObjectSharesSelector sharesSelector = new FormulaShareSObjectSharesSelector(true, shareObjectType, type);
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

		// Retrieve current record shares if type in scope is a standard object
		else {
			sharesQueryResult = sharesSelector.selectByParentIds(parentIdsString);

			// For account sharing, check whether contact sharing is controlled by account
			if(type.getDescribe().getName() == 'Account') {
				contactIsControlledByAccount = FormulaShareUtilities.isContactSharingControlledByAccount();
			}
		}

		system.debug('Share query result: '+sharesQueryResult);

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

		existingShareKeys = mapToDelete.keySet().clone();

		// Assess sharing to be created or kept (will update deletion and insertion maps)
		assessRequiredShares();

		// Clear deletion map if object is standard and removal of standard sharing is not permitted
		if(removeExistingShares && !type.getDescribe().isCustom()) {
			mapToDelete.clear();
		}
	}


	private void assessRequiredShares() {
		
		Set<Id> userQueryIdSet = new Set<Id>();
		Set<Id> roleQueryIdSet = new Set<Id>();

		Set<SObjectRule> userRecordRules = new Set<SObjectRule>();
		Set<SObjectRule> roleRecordRules = new Set<SObjectRule>();
		Set<SObjectRule> groupRecordRules = new Set<SObjectRule>();

		Set<String> sharedToNamesGroups = new Set<String>();
		Set<String> sharedToNamesRoles = new Set<String>();

		system.debug('Records to be assessed: '+recordsMap);
		system.debug('Rules to be assessed: '+rules);

		List<SObjectRule> allRecordRules = buildRecordRules();

		for(SObjectRule recordRule : allRecordRules) {

			FormulaShareRule rule = recordRule.rule;

			// Get the value of the entity this rule is trying to share to
			String sharedToString = (String) recordRule.recordWithSharedToDetails.get(rule.sharedToAPINameForType);

			system.debug('this rule: '+rule);
			system.debug('*** the record: '+recordRule.recordWithSharedToDetails);
			system.debug('*** sharedToAPINAme'+rule.sharedToAPINameForType);
			system.debug('shared to string: ' + sharedToString);
			
			if(rule.isValid && rule.active) {

				// Add User Id to map
				if(rule.shareWith == 'Users') {
					if(FormulaShareUtilities.isValidIdType(sharedToString, Schema.User.getSObjectType())) {
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
					if(rule.sharedToFieldTypeForRuleType == 'Id' &&
						FormulaShareUtilities.isValidIdType(sharedToString, Schema.Group.getSObjectType())) {
						updateShareMaps(recordRule.recordToShare.Id, (Id) sharedToString, rule);
					}
					else if(rule.sharedToFieldTypeForRuleType == 'Name') {
						sharedToNamesGroups.add(sharedToString);
						groupRecordRules.add(recordRule);
					}
					else {
						String logMessage = 'Expected field to contain valid group id. Instead found: ' + sharedToString;
						captureEntityNotFound(recordRule, logMessage);
					}
				}

				// Add Role Id to role group query set
				else if(rule.shareWith == 'Roles' || rule.shareWith == 'Roles and Internal Subordinates' || rule.shareWith == 'Roles, Internal and Portal Subordinates') {
					if(rule.sharedToFieldTypeForRuleType == 'Id' &&
						FormulaShareUtilities.isValidIdType(sharedToString, Schema.UserRole.getSObjectType())) {
						roleQueryIdSet.add((Id) sharedToString);
					}
					else if(rule.sharedToFieldTypeForRuleType == 'Name') {
						sharedToNamesRoles.add(sharedToString);
					}
					else {
						String logMessage = 'Expected field to contain valid role id. Instead found: ' + sharedToString;
						captureEntityNotFound(recordRule, logMessage);
					}
					roleRecordRules.add(recordRule);
				}

				else system.debug('Share With value ' + rule.shareWith + ' does not match allowed options');
			}
		}

		// Process user sharing
		if(!userRecordRules.isEmpty()) {
			assessUserSharingFromIds(userQueryIdSet, userRecordRules);
		}

		// Process group sharing
		if(!sharedToNamesGroups.isEmpty()) {
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
		if(!roleQueryIdSet.isEmpty() || !roleNamesToIdsMap.isEmpty()) {
			assessRoleSharing(roleQueryIdSet, roleRecordRules, roleNamesToIdsMap);
		}
	}


	private void captureEntityNotFound(SObjectRule recordRule, String logMessage) {
		captureEntityNotFound(recordRule.recordToShare.Id, recordRule.rule, logMessage);
	}

	private void captureEntityNotFound(Id recordId, FormulaShareRule rule, String logMessage) {
		EntityNotFound enf = new EntityNotFound();
		enf.recordId = recordId;
		enf.rule = rule;
		enf.type = type;
		enf.failedStatusReason = logMessage;
		entitiesNotFound.add(enf);

		System.debug('Entity not found: '+enf);
	}


	private List<SObjectRule> buildRecordRules() {
		List<SObjectRule> allRecordRules = new List<SObjectRule>();

		for(FormulaShareRule rule : rules) {
			for(SObject record : recordsMap.values()) {
				
				// If shared to details are on the shared object, then this object in the record rule
				if(rule.type == 'standard') {
					SObjectRule recordRule = new SObjectRule();
					recordRule.recordToShare = record;
					recordRule.recordWithSharedToDetails = record;
					recordRule.rule = rule;
					allRecordRules.add(recordRule);
					system.debug('*** processing standard '+ record);
				}

				// Otherwise, create record rules for the child objects with the shared to field
				else if(rule.type == 'child') {
					String relationshipName = FormulaShareUtilities.getRelationshipName(rule.objectSharedAPIName, rule.childObjectWithSharedToFieldAPIName, rule.childObjectLookupFieldAPIName);

					system.debug('rel name: ' + relationshipName);

					system.debug('record: ' + record);
					system.debug('related record: ' + record.getSObjects(relationshipName));

					if(record.getSObjects(relationshipName) != null) {
						for(SOBject relatedObj : (List<SObject>) record.getSObjects(relationshipName)) {
							SObjectRule recordRule = new SObjectRule();
							recordRule.recordToShare = record;
							recordRule.recordWithSharedToDetails = relatedObj;
							recordRule.rule = rule;
							allRecordRules.add(recordRule);
						}
					}
				}
			}
		}

		return allRecordRules;
	}


	private void assessUserSharingFromIds(Set<Id> userQueryIdSet, Set<SObjectRule> userRecordRules) {
		
		Set<Id> activeUsersIdSet = getActiveUsers(userQueryIdSet);

		system.debug('user record rules: ' + userRecordRules);

		for(SObjectRule recordRule : userRecordRules) {
			system.debug('Looking for this shared to: ' + recordRule.rule.sharedToAPINameForType);
			system.debug('in this object: ' + recordRule.recordWithSharedToDetails);

			system.debug('rec to share: ' + recordRule.recordToShare);
			system.debug('share to field: ' + recordRule.rule.sharedToAPINameForType);

			Id userId = (Id) recordRule.recordWithSharedToDetails.get(recordRule.rule.sharedToAPINameForType);
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


	private static Set<Id> getActiveUsers(Set<Id> userQueryIdSet) {
		Map<Id,User> activeUserMap = new Map<Id,User>([SELECT Id FROM User WHERE Id IN :userQueryIdSet AND IsActive = TRUE]);
		return activeUserMap.keySet();
	}


	private void assessGroupSharingFromNames(Set<String> groupNames, Set<SObjectRule> groupRecordRules) {

		Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

		for(SObjectRule recordRule : groupRecordRules) {
			String sharedToName = (String) recordRule.recordWithSharedToDetails.get(recordRule.rule.sharedToAPINameForType);
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


	private static Map<String,Id> getGroupsFromNames(Set<String> groupNames) {
		Map<String,Id> groups = new Map<String,Id>();

		// Query for matching public groups and queues
		for(Group grp : [SELECT Id, DeveloperName FROM Group 
			WHERE DeveloperName IN :groupNames
			AND (Type = 'Regular' OR Type = 'Queue')]) {
			groups.put(grp.DeveloperName,grp.Id);
		}
		return groups;
	}


	private void assessRoleSharing(Set<Id> roleQueryIdSet, Set<SObjectRule> roleRecordRules, Map<String,Id> roleNamesToIdsMap) {

		// Build map of required group Ids for role groups
		Map<String,Id> roleGroupIds = new Map<String,Id>();

		for(Group grp : [SELECT Id, RelatedId, Type 
			FROM Group 
			WHERE (RelatedId IN :roleQueryIdSet OR RelatedId IN :roleNamesToIdsMap.values())
			AND (Type = 'Role' OR Type = 'RoleAndSubordinatesInternal' OR Type = 'RoleAndSubordinates')
			]) {

			String shortRelatedToId = FormulaShareUtilities.get15CharacterId(grp.RelatedId);
			String key = shortRelatedToId + grp.Type;
			system.debug('Added roleGroupEntry key: '+key+' for group: '+grp.Id);
			roleGroupIds.put(key, grp.Id);
		}


		// Update sharing maps to create or keep role shares
		system.debug('*** Delete map before assessment: ' + mapToDelete.keySet() );
		for(SObjectRule recordRule : roleRecordRules) {

			String sharedTo = (String) recordRule.recordWithSharedToDetails.get(recordRule.rule.sharedToAPINameForType);
			Id sharedToId = null;
			Id roleGroupId = null;

			if(recordRule.rule.sharedToFieldTypeForRuleType == 'Name') {
				if(roleNamesToIdsMap.containsKey(sharedTo)) {
					sharedToId = roleNamesToIdsMap.get(sharedTo);
				}
				else {
					String logMessage = 'Field value \''+sharedTo+'\' should correspond to an active role, but no role was found with this name';
					captureEntityNotFound(recordRule, logMessage);
				}
			}

			else if(recordRule.rule.sharedToFieldTypeForRuleType == 'Id') {
				sharedToId = (Id) sharedTo;
			}

			String shortSharedToId = FormulaShareUtilities.get15CharacterId(sharedToId);

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
				String logMessage = 'Role \''+recordRule.recordWithSharedToDetails.get(recordRule.rule.sharedToAPINameForType)+'\' specified on record is not valid for sharing';
				captureEntityNotFound(recordRule, logMessage);
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

			// ...keep if it relates to record ownership
			if(objectAccess == 'All') {
				System.debug('||| Existing share with full access, keep this: '+share);
			}

			// ...keep if the access level is identical
			else if(rule.shareMatchesRulePermissions(type, share, contactIsControlledByAccount)) {
				System.debug('||| All access levels match, keep existing share: '+share);
			}

			// ...keep if share removal is not permitted and access is higher than the rule
			else if(!objectUtils.removeSharesForObject()
				&& !FormulaShareUtilities.accessLevelIsHigher(rule.accessLevel, objectAccess)) {
				System.debug('||| Share exists with object access at same or higher level, keep this: '+share);
			}

			// ...otherwise create a new share with highest access levels
			else {
				System.debug('||| Existing share exists, create one with max levels of rule and this share: '+share);
				populateMapHighestAccess(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount, share);
			}

			// Remove from map to delete - share will be kept or updated
			mapToDelete.remove(shareKey);
		}

		// Otherwise if we've already identified sharing is needed for this record...
		else if(mapToInsert.containsKey(shareKey)) {

			ShareDetail sd = mapToInsert.get(shareKey);
			SObject share = sd.shareRecord;

			// Create a new share which is maximally permissive, and replace this in the map
			System.debug('||| Updating a share already in insert map: '+share);
			populateMapHighestAccess(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount, share);
		}		

		// If no match, add to be created
		else {
			System.debug('||| creating new share based on rule');
			populateMapNewShare(recordId, sharedTo, shareKey, rule, contactIsControlledByAccount);
		}

		// Track this as a valid share record to populate metrics
		incrementShareMetrics(rule);
	}


	private void incrementShareMetrics(FormulaShareRule rule) {
		Integer noShares = noValidSharesForRules.get(rule.developerName);
		noShares++;
		noValidSharesForRules.put(rule.developerName, noShares);
	}


	private String getShareKey(Id recordId, Id sharedTo, FormulaShareRule rule) {
		FormulaShareUtilities fsUtil = FormulaShareUtilities.construct();

		// Instance method used to support mocking for standard objects
		String shareKey = fsUtil.get15CharacterIdInstance(recordId)
			+ fsUtil.get15CharacterIdInstance(sharedTo);
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

		if(!Test.isRunningTest()) {
			for(SObjectType type : typesSet) {
				typesList.add(type);
			}
		}

		// If running test return list with FormulaShareRule to enable execution of other code
		else {
			typesList.add(FormulaShare_Log__c.SObjectType);
		}

		return typesList;
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