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
	@TestVisible private Map<String,SObject> mapToDelete = new Map<String,SObject>();
	private Set<SObject> setToInsert = new Set<SObject>();
	private Schema.SObjectType type;
	private List<FormulaShareRule> rules = new List<FormulaShareRule>();

	// Wrapper for a record and a rule sharing this record
	private class SObjectRule {
		SObject obj;
		FormulaShareRule rule;
	}
	

	// Getter methods to access variables needed by calling classes. Methods are mocked for test classes
	public List<SObject> getSharesToInsert() {
		return new List<SObject>(setToInsert);
	}

	public List<SOBject> getSharesToDelete() {
		return mapToDelete.values();
	}

	public List<FormulaShareRule> getRules() {
		return rules;
	}

	public Schema.SObjectType getType() {
		return type;
	}

	public void setRecordsMap(Map<Id,SObject> recordsMap) {
		this.recordsMap = recordsMap;
	}

	// Used by batch job to retrieve query locator from selector
	public static Database.QueryLocator getFullObjectQueryLocator(Schema.sObjectType type, List<FormulaShareRule> rules) {

		Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
        Map<String, SObjectField> fieldMap = type.getDescribe().fields.getMap();

        for(FormulaShareRule rule : rules) {
            Schema.SObjectField field = fieldMap.get(rule.sharedToAPIName);
            fieldsSet.add(field);

			// Also add the OwnerId field if rule shares to users (required for later comparisons)
			if(rule.shareWith == 'Users') {
				Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
				fieldsSet.add(ownerIdField);
			}
        }

		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;

		Database.QueryLocator objectLocator = new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity,type,fieldsSet).selectAllLocator();
		return objectLocator;
	}


	// Submits batch recalculation of all sharing
	public static void recalculateAll() {
		FormulaShare_Settings__mdt settings = getFormulaShareSettings();
		Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();
		List<Schema.SObjectType> types = getSharedObjectTypes();
		Id batchJobId = Database.executeBatch(new ProcessFormulaShareBatch(types, batchSize), batchSize);
	}
	

	// Core method called from trigger and batch context - returns a wrapper with all details needed to make updates
	public void processFormulaShares() {

		Boolean removeExistingShares = true;

		// Retrieve current record shares if type in scope is a custom object
		if(type.getDescribe().isCustom()) {
			
			// Get all relevant row causes (aka apex sharing reasons) used in rules
			Set<String> rowCauseSet = new Set<String>();
			for(FormulaShareRule rule : rules) {
				rowCauseSet.add(rule.sharingReason);
			}

			List<SObject> sharesQueryResultCustom = queryCustomObjectShares(rowCauseSet);

			system.debug('Share query result: '+sharesQueryResultCustom);

			// Create map of shareQueryResults with record shares unique key
			for(SObject share : sharesQueryResultCustom) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);
				mapToDelete.put(shareKey, share);
			}
		}

		// Retrieve current record shares if type in scope is a standard object
		else {
			List<SObject> sharesQueryResultStandard = queryStandardObjectShares();

			system.debug('Share query result: '+sharesQueryResultStandard);

			// Create map of all record shares with unique key
			// Any required shares will be removed from this map and the remainder deleted (if settings allow this)
			for(SObject share : sharesQueryResultStandard) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(type, share);
				mapToDelete.put(shareKey, share);
			}

			List<FormulaShare_Std_Object_to_Remove_Shares__mdt> removalLines = FormulaShareRemoveSharesSelector.construct().getRemovalLinesForType(type);
			if(!removalLines.isEmpty()) {
				removeExistingShares = false;
			}
		}

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

		for(SObject record : recordsMap.values()) {
			
			for(FormulaShareRule rule : rules) {
			system.debug('this rule: '+rule);
			String sharedToString = (String) record.get(rule.sharedToAPIName);
				
				// Only need to check records where sharing field is populated and where rule is active
				if(!String.isBlank(sharedToString) && rule.active) {
					try {

						// Add User Id to map
						if(rule.shareWith == 'Users') {
							if(FormulaShareUtilities.isValidIdType(sharedToString, Schema.User.getSObjectType())) {
								userQueryIdSet.add((Id) sharedToString);
								SObjectRule recordRule = new SObjectRule();
								recordRule.obj = record;
								recordRule.rule = rule;
								userRecordRules.add(recordRule);
							}
							else {
								throw new FormulaShareException();
							}
						}

						// Add Group Id to map
						else if(rule.shareWith == 'Public Groups') {
							if(rule.sharedToFieldType == 'Id' &&
								FormulaShareUtilities.isValidIdType(sharedToString, Schema.Group.getSObjectType())) {
								updateShareMaps(record.Id, (Id) sharedToString, rule);
							}
							else if(rule.sharedToFieldType == 'Name') {
								sharedToNamesGroups.add(sharedToString);
								SObjectRule recordRule = new SObjectRule();
								recordRule.obj = record;
								recordRule.rule = rule;
								groupRecordRules.add(recordRule);
							}
							else {
								throw new FormulaShareException();
							}
						}

						// Add Role Id to role group query set
						else if(rule.shareWith == 'Roles' || rule.shareWith == 'Roles and Internal Subordinates') {
							if(rule.sharedToFieldType == 'Id' &&
								FormulaShareUtilities.isValidIdType(sharedToString, Schema.UserRole.getSObjectType())) {
								roleQueryIdSet.add((Id) sharedToString);
							}
							else if(rule.sharedToFieldType == 'Name') {
								sharedToNamesRoles.add(sharedToString);
							}
							else {
								throw new FormulaShareException();
							}
							SObjectRule recordRule = new SObjectRule();
							recordRule.obj = record;
							recordRule.rule = rule;
							roleRecordRules.add(recordRule);
						}

						else system.debug('Share With value ' + rule.shareWith + ' does not match allowed options');

					}
					catch(FormulaShareException e) {
						system.debug('Expected Id entity relevant to type ' + rule.shareWith
						+ ' in field ' + rule.sharedToAPIName
						+ ' on object ' + rule.objectSharedAPIName
						+ '. For record ' + record.Id
						+ ' instead found value ' + sharedToString);
					}
				}
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


	private void assessUserSharingFromIds(Set<Id> userQueryIdSet, Set<SObjectRule> userRecordRules) {
		
		Set<Id> activeUsersIdSet = getActiveUsers(userQueryIdSet);

		for(SObjectRule recordRule : userRecordRules) {
			Id userId = (Id) recordRule.obj.get(recordRule.rule.sharedToAPIName);

			// If user is active and not already the record owner then create sharing record
			if(activeUsersIdSet.contains(userId) && userId != recordRule.obj.get('OwnerId')) {
				system.debug('adding to map for insert');
				updateShareMaps(recordRule.obj.Id, userId, recordRule.rule);
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
			String sharedToName = (String) recordRule.obj.get(recordRule.rule.sharedToAPIName);
			Id groupId = groupsMap.get(sharedToName);

			if(groupId != null) {
				updateShareMaps(recordRule.obj.Id, groupId, recordRule.rule);
			}

			else {
				system.debug('Invalid group name ' + sharedToName + ' specified on record ' + recordRule.obj.Id);
			}
		}
	}


	private static Map<String,Id> getGroupsFromNames(Set<String> groupNames) {
		Map<String,Id> groups = new Map<String,Id>();

		for(Group grp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNames]) {
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
			AND (Type = 'Role' OR Type = 'RoleAndSubordinates')
			]) {

			String shortRelatedToId = FormulaShareUtilities.get15CharacterId(grp.RelatedId);
			String key = shortRelatedToId + grp.Type;
			system.debug('Added roleGroupEntry key: '+key+' for group: '+grp.Id);
			roleGroupIds.put(key, grp.Id);
		}


		// Update sharing maps to create or keep role shares
		for(SObjectRule recordRule : roleRecordRules) {

			String sharedTo = (String) recordRule.obj.get(recordRule.rule.sharedToAPIName);
			Id sharedToId = null;
			Id roleGroupId = null;

			if(recordRule.rule.sharedToFieldType == 'Name') {
				sharedToId = roleNamesToIdsMap.get(sharedTo);
			}

			else if(recordRule.rule.sharedToFieldType == 'Id') {
				sharedToId = (Id) sharedTo;
			}

			String shortSharedToId = FormulaShareUtilities.get15CharacterId(sharedToId);

			if(recordRule.rule.shareWith == 'Roles') {
				roleGroupId = roleGroupIds.get(shortSharedToId + 'Role');
			}

			else if(recordRule.rule.shareWith == 'Roles and Internal Subordinates') {
				roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
			}

			if(roleGroupId != null) {
				updateShareMaps(recordRule.obj.Id, roleGroupId, recordRule.rule);
			}

			else {
				system.debug('Invalid role for sharing ' + recordRule.obj.get(recordRule.rule.sharedToAPIName) + ' specified on record ' + recordRule.obj.Id);
			}
		}
	}


	private void updateShareMaps(Id recordId, Id sharedTo, FormulaShareRule rule) {
		
		// For custom objects, check whether sharing record for this sharing reason exists at correct access level
		if(type.getDescribe().isCustom()) {
			updateShareMapsCustom(recordId, sharedTo, rule);
		}

		// For standard objects, check whether any sharing record exists at this access level or higher
		else {
			updateShareMapsStandard(recordId, sharedTo, rule);
		}
	}


	@TestVisible
	private void updateShareMapsCustom(Id recordId, Id sharedTo, FormulaShareRule rule) {
		String shareKey = FormulaShareUtilities.get15CharacterId(recordId)
			 + FormulaShareUtilities.get15CharacterId(sharedTo)
			 + rule.accessLevel
			 + rule.sharingReason;
		
		// If share record exists already, remove from map to be deleted
		if(mapToDelete.get(shareKey) != null) {
			mapToDelete.remove(shareKey);
		}

		// Otherwise add to map to be inserted
		else {
			SObject newShare = rule.getShareRecord(type, recordId, sharedTo);
			setToInsert.add(newShare);
		}
	}


	@TestVisible
	private void updateShareMapsStandard(Id recordId, Id sharedTo, FormulaShareRule rule) {

		FormulaShareUtilities fsUtil = FormulaShareUtilities.construct();

		// Check whether we have any shares for this record already
		String shareKeyBase = fsUtil.get15CharacterIdInstance(recordId) + fsUtil.get15CharacterIdInstance(sharedTo);
		String shareKeyAll = shareKeyBase + 'All';
		String shareKeyEdit = shareKeyBase + 'Edit';
		String shareKeyRead = shareKeyBase + 'Read';

		system.debug('*** searching with this Id: ' + shareKeyEdit);
		system.debug('*** full map keys: ' + mapToDelete.keySet() );
		system.debug('result of EDIT search: ' + mapToDelete.get(shareKeyEdit));

		// If we already have a record with All, keep this (All will always be more permissive as the rule)
		if(mapToDelete.get(shareKeyAll) != null) {
			mapToDelete.remove(shareKeyAll);
		}

		// If we already have a record with Edit, keep this (Edit will be at least as permissive as the rule)
 		else if(mapToDelete.get(shareKeyEdit) != null) {
			mapToDelete.remove(shareKeyEdit);
		}

		// If we have a record with Read...
		else if(mapToDelete.get(shareKeyRead) != null) {

			// If rule's access level is Read, keep this record
			if(rule.accessLevel == 'Read') {
				mapToDelete.remove(shareKeyRead);
			}

			// Otherwise add higher level share to be inserted
			else {
				SObject newShare = rule.getShareRecord(type, recordId, sharedTo);
				setToInsert.add(newShare);
			}
		}

		// If no share found, add to be created
		else {
				SObject newShare = rule.getShareRecord(type, recordId, sharedTo);
				setToInsert.add(newShare);
		}
	}


	private List<SObject> queryStandardObjectShares() {
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordsMap.keySet());

		// Query for relevant share records via selector
		FormulaShareSObjectSharesStdSelector sharesSelector = new FormulaShareSObjectSharesStdSelector(true, shareObjectType, type);
		return sharesSelector.selectByParentIds(parentIdsString);
	}


	private List<SObject> queryCustomObjectShares(Set<String> rowCauseSet) {
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordsMap.keySet());
		String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(rowCauseSet);

		// Query for relevant share records via selector
		FormulaShareSObjectSharesCustomSelector sharesSelector = new FormulaShareSObjectSharesCustomSelector(true, shareObjectType);
		return sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
	}


	private static List<SObjectType> getSharedObjectTypes() {

		List<SObjectType> typesList = new List<SObjectType>();
		Set<SObjectType> typesSet = new Set<SObjectType>();

		// Loop through all rules and populate set of shared objects
		for(String objName : FormulaShareRulesSelector.construct().selectObjectsWithRules()) {
			SObjectType type = Schema.getGlobalDescribe().get(objName);
			typesSet.add(type);
		}

		if(!Test.isRunningTest()) {
			for(SObjectType type : typesSet) {
				typesList.add(type);
			}
		}

		// If running test return list with FormulaShareRule to enable execution of other code
		else {
			typesList.add(FormulaShare_Log__c.SobjectType);
		}

		return typesList;
	}


	private static FormulaShare_Settings__mdt getFormulaShareSettings() {

		if(settings == null) {
			settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
		}

		return settings;
	}


}