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

global inherited sharing class FormulaShareService {

	public class FormulaShareException extends Exception{}

	static FormulaShare_Settings__mdt settings;


	// Core method called from trigger and batch context - returns a wrapper with all details needed to make updates
	public static FormulaShareWrapper processFormulaShares(FormulaShareWrapper fsWrapper) {

		Boolean removeExistingShares = true;

		// Retrieve current record shares if type in scope is a custom object
		if(fsWrapper.type.getDescribe().isCustom()) {
			
			// Get all relevant row causes (aka apex sharing reasons) used in rules
			Set<String> rowCauseSet = new Set<String>();
			for(FSRule rule : fsWrapper.rules) {
				rowCauseSet.add(rule.sharingReason);
			}

			List<SObject> sharesQueryResultCustom = queryCustomObjectShares(fsWrapper, rowCauseSet);

			system.debug('Share query result: '+sharesQueryResultCustom);

			// Create map of shareQueryResults with record shares unique key
			for(SObject share : sharesQueryResultCustom) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);
				fsWrapper.mapToDelete.put(shareKey, share);
			}
		}

		// Retrieve current record shares if type in scope is a standard object
		else {
			List<SObject> sharesQueryResultStandard = queryStandardObjectShares(fsWrapper);

			system.debug('Share query result: '+sharesQueryResultStandard);

			// Create map of all record shares with unique key
			// Any required shares will be removed from this map and the remainder deleted (if settings allow this)
			for(SObject share : sharesQueryResultStandard) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(fsWrapper.type, share);
				fsWrapper.mapToDelete.put(shareKey, share);
			}

			// Ensure shares are not deleted if settings do not allow this
			FormulaShare_Settings__mdt settings = getFormulaShareSettings();
			if(!settings.Remove_Shares_for_Standard_Objects__c) {
				removeExistingShares = false;
			}
		}

		// Assess sharing to be created or kept (will update deletion and insertion maps)
		assessRequiredShares(fsWrapper);

		// Clear deletion map if removal of standard sharing is not permitted
		if(removeExistingShares) {
			fsWrapper.mapToDelete.clear();
		}

		return fsWrapper;
	}


	public static void assessRequiredShares(FormulaShareWrapper fsWrapper) {
		
		Set<Id> userQueryIdSet = new Set<Id>();
		Set<Id> roleQueryIdSet = new Set<Id>();

		Set<SObjectRule> userRecordRules = new Set<SObjectRule>();
		Set<SObjectRule> roleRecordRules = new Set<SObjectRule>();
		Set<SObjectRule> groupRecordRules = new Set<SObjectRule>();

		Set<String> sharedToNamesGroups = new Set<String>();
		Set<String> sharedToNamesRoles = new Set<String>();

		system.debug('Records to be assessed: '+fsWrapper.recordsMap);
		system.debug('Rules to be assessed: '+fsWrapper.rules);

		for(SObject record : fsWrapper.recordsMap.values()) {
			
			for(FSRule rule : fsWrapper.rules) {
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
								updateShareMaps(record.Id, (Id) sharedToString, rule, fsWrapper);
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
			assessUserSharingFromIds(userQueryIdSet, userRecordRules, fsWrapper);
		}
		
		// Process group sharing
		if(!sharedToNamesGroups.isEmpty()) {
			assessGroupSharingFromNames(sharedToNamesGroups, groupRecordRules, fsWrapper);
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
			assessRoleSharing(roleQueryIdSet, roleRecordRules
				, roleNamesToIdsMap, fsWrapper);
		}
	}


	public static void assessUserSharingFromIds(Set<Id> userQueryIdSet, Set<SObjectRule> userRecordRules, FormulaShareWrapper fsWrapper) {
		
		Set<Id> activeUsersIdSet = getActiveUsers(userQueryIdSet);

		for(SObjectRule recordRule : userRecordRules) {
			Id userId = (Id) recordRule.obj.get(recordRule.rule.sharedToAPIName);

			// If user is active and not already the record owner then create sharing record
			if(activeUsersIdSet.contains(userId) && userId != recordRule.obj.get('OwnerId')) {
				system.debug('adding to map for insert');
				updateShareMaps(recordRule.obj.Id, userId, recordRule.rule, fsWrapper);
			}
		}
	}


	public static Set<Id> getActiveUsers(Set<Id> userQueryIdSet) {
		Map<Id,User> activeUserMap = new Map<Id,User>([SELECT Id FROM User WHERE Id IN :userQueryIdSet AND IsActive = TRUE]);
		return activeUserMap.keySet();
	}


	public static void assessGroupSharingFromNames(Set<String> groupNames, Set<SObjectRule> groupRecordRules, FormulaShareWrapper fsWrapper) {

		Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

		for(SObjectRule recordRule : groupRecordRules) {
			String sharedToName = (String) recordRule.obj.get(recordRule.rule.sharedToAPIName);
			Id groupId = groupsMap.get(sharedToName);

			if(groupId != null) {
				updateShareMaps(recordRule.obj.Id, groupId, recordRule.rule, fsWrapper);
			}

			else {
				system.debug('Invalid group name ' + sharedToName + ' specified on record ' + recordRule.obj.Id);
			}
		}
	}


	public static Map<String,Id> getGroupsFromNames(Set<String> groupNames) {
		Map<String,Id> groups = new Map<String,Id>();

		for(Group grp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNames]) {
			groups.put(grp.DeveloperName,grp.Id);
		}
		return groups;
	}


	public static void assessRoleSharing(Set<Id> roleQueryIdSet, Set<SObjectRule> roleRecordRules
		, Map<String,Id> roleNamesToIdsMap, FormulaShareWrapper fsWrapper) {

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
				updateShareMaps(recordRule.obj.Id, roleGroupId, recordRule.rule, fsWrapper);
			}

			else {
				system.debug('Invalid role for sharing ' + recordRule.obj.get(recordRule.rule.sharedToAPIName) + ' specified on record ' + recordRule.obj.Id);
			}
		}
	}


	public static void updateShareMaps(Id recordId, Id sharedTo, FSRule rule, FormulaShareWrapper fsWrapper) {
		
		// For custom objects, check whether sharing record for this sharing reason exists at correct access level
		if(fsWrapper.type.getDescribe().isCustom()) {
			updateShareMapsCustom(recordId, sharedTo, rule, fsWrapper);
		}

		// For standard objects, check whether any sharing record exists at this access level or higher
		else {
			updateShareMapsStandard(recordId, sharedTo, rule, fsWrapper);
		}
	}


	public static void updateShareMapsCustom(Id recordId, Id sharedTo, FSRule rule, FormulaShareWrapper fsWrapper) {
		String shareKey = FormulaShareUtilities.get15CharacterId(recordId)
			 + FormulaShareUtilities.get15CharacterId(sharedTo)
			 + rule.accessLevel
			 + rule.sharingReason;
		
		// If share record exists already, remove from map to be deleted
		if(fsWrapper.mapToDelete.get(shareKey) != null) {
			fsWrapper.mapToDelete.remove(shareKey);
		}

		// Otherwise add to map to be inserted
		else {
			SObject newShare = getShareRecordCustom(fsWrapper.type, recordId, sharedTo, rule);
			fsWrapper.setToInsert.add(newShare);
		}
	}


	public static void updateShareMapsStandard(Id recordId, Id sharedTo, FSRule rule, FormulaShareWrapper fsWrapper) {

		FormulaShareUtilities fsUtil = FormulaShareUtilities.construct();

		// Check whether we have any shares for this record already
		String shareKeyBase = fsUtil.get15CharacterIdInstance(recordId) + fsUtil.get15CharacterIdInstance(sharedTo);
		String shareKeyAll = shareKeyBase + 'All';
		String shareKeyEdit = shareKeyBase + 'Edit';
		String shareKeyRead = shareKeyBase + 'Read';

		system.debug('*** searching with this Id: ' + shareKeyEdit);
		system.debug('*** full map keys: ' + fsWrapper.mapToDelete.keySet() );
		system.debug('result of EDIT search: ' + fsWrapper.mapToDelete.get(shareKeyEdit));

		// If we already have a record with All, keep this (All will always be more permissive as the rule)
		if(fsWrapper.mapToDelete.get(shareKeyAll) != null) {
			fsWrapper.mapToDelete.remove(shareKeyAll);
		}

		// If we already have a record with Edit, keep this (Edit will be at least as permissive as the rule)
 		else if(fsWrapper.mapToDelete.get(shareKeyEdit) != null) {
			fsWrapper.mapToDelete.remove(shareKeyEdit);
		}

		// If we have a record with Read...
		else if(fsWrapper.mapToDelete.get(shareKeyRead) != null) {

			// If rule's access level is Read, keep this record
			if(rule.accessLevel == 'Read') {
				fsWrapper.mapToDelete.remove(shareKeyRead);
			}

			// Otherwise add higher level share to be inserted
			else {
				SObject newShare = getShareRecordStandard(fsWrapper.type, recordId, sharedTo, rule);
				fsWrapper.setToInsert.add(newShare);
			}
		}

		// If no share found, add to be created
		else {
				SObject newShare = getShareRecordStandard(fsWrapper.type, recordId, sharedTo, rule);
				fsWrapper.setToInsert.add(newShare);
		}
	}


	public static List<SObject> queryStandardObjectShares(FormulaShareWrapper fsWrapper) {
//		String objectName = fsWrapper.type.getDescribe().getName();
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(fsWrapper.type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(fsWrapper.recordsMap.keySet());

		// Query for relevant share records via selector
		FormulaShareSObjectSharesStdSelector sharesSelector = new FormulaShareSObjectSharesStdSelector(true, shareObjectType, fsWrapper.type);
		return sharesSelector.selectByParentIds(parentIdsString);
	}


	public static List<SObject> queryCustomObjectShares(FormulaShareWrapper fsWrapper, Set<String> rowCauseSet) {
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(fsWrapper.type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(fsWrapper.recordsMap.keySet());
		String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(rowCauseSet);

		// Query for relevant share records via selector
		FormulaShareSObjectSharesCustomSelector sharesSelector = new FormulaShareSObjectSharesCustomSelector(true, shareObjectType);
		return sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
	}


	public static SObject getShareRecordCustom(Schema.SObjectType type, Id recordId, Id sharedTo, FSRule rule) {
		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);
		SObject newShare = shareType.newSObject();
		newShare.put('AccessLevel',rule.accessLevel);
		newShare.put('ParentId',recordId);
		newShare.put('RowCause',rule.sharingReason);
		newShare.put('UserOrGroupId',sharedTo);
		return newShare;
	}


	public static SObject getShareRecordStandard(Schema.SObjectType type, Id recordId, Id sharedTo, FSRule rule) {
		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);
		SObject newShare = shareType.newSObject();
		newShare.put(type + 'AccessLevel',rule.accessLevel);
		newShare.put(type + 'Id',recordId);
//		newShare.put('RowCause','Manual');		// Only reason supported for standard objects is manual (set by default)
		newShare.put('UserOrGroupId',sharedTo);
		return newShare;
	}


	// Used by batch job to retrieve query locator from selector
	public static Database.QueryLocator getFullObjectQueryLocator(Schema.sObjectType type, List<FSRule> rules) {

		Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
        Map<String, SObjectField> fieldMap = type.getDescribe().fields.getMap();

        for(FSRule rule : rules) {
            Schema.SObjectField field = fieldMap.get(rule.sharedToAPIName);
            fieldsSet.add(field);

			// Also add the OwnerId field if rule shares to users (required for later comparisons)
			if(rule.shareWith == 'Users') {
				Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
				fieldsSet.add(ownerIdField);
			}
        }

		Database.QueryLocator objectLocator = new FormulaShareSObjectsSelector(true,type,fieldsSet).selectAllLocator();
		return objectLocator;
	}

/*
	public static List<FSRule> getRulesSharingObject(Schema.sObjectType type) {

		List<FSRule> rulesToReturn = new List<FSRule>();

		String objectName = type.getDescribe().getName();

		// Create list of all jobs with relevant details for assessing scope
		for(FormulaShare_Rule__mdt ruleInScope :
			FormulaShareRulesSelector.construct().selectRules(objectName)) {
				
				FSRule rule = new FSRule();
				rule.objectSharedAPIName = ruleInScope.Object_Shared__r.QualifiedApiName;
				rule.sharedToAPIName = ruleInScope.Shared_To__r.QualifiedApiName;
				rule.shareWith = ruleInScope.Share_With__c;
				rule.accessLevel = ruleInScope.Access_Level__c;
				rule.active = ruleInScope.Active__c;
				rule.sharedToFieldType = ruleInScope.Shared_To_Field_Type__c;
				rule.sharingReason = ruleInScope.Sharing_Reason__c;
				rulesToReturn.add(rule);
			}

		system.debug('All rules sharing object: '+rulesToReturn);

		// If running test, return dummy FormulaShare rules to support further processing
		if(Test.isRunningTest()) {
			List<FSRule> testRules = setTestRules();
			rulesToReturn.clear();
			rulesToReturn.addAll(testRules);
		}

		return rulesToReturn;
	}
*/

	public static List<SObjectType> getSharedObjectTypes() {

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

		// If running test return list with FSRule to enable execution of other code
		else {
			typesList.add(FormulaShare_Log__c.SobjectType);
		}

		return typesList;
	}


	// Submits batch recalculation of all sharing
	public static void recalculateAll() {
		FormulaShare_Settings__mdt settings = getFormulaShareSettings();
		Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();
		List<Schema.SObjectType> types = getSharedObjectTypes();
		Id batchJobId = Database.executeBatch(new ProcessFormulaShareBatch(types, batchSize), batchSize);
	}


	public static FormulaShare_Settings__mdt getFormulaShareSettings() {

		if(settings == null) {
			settings = new FormulaShareSettingsSelector().selectActiveSettings();
		}

		return settings;
	}


	// Core wrapper class passed to methods inside and outside the class
	global class FormulaShareWrapper {
		public Schema.SObjectType type;
		public List<FSRule> rules;
		public Map<Id,SObject> recordsMap = new Map<Id,SObject>();
		public Map<String,SObject> mapToDelete = new Map<String,SObject>();
		public Set<SObject> setToInsert = new Set<SObject>();
		public Map<String,Id> sharingReasonsIdMap = new Map<String,Id>();

		// Set type and rules if provided on creation
		public FormulaShareWrapper(Schema.SObjectType type, List<FSRule> rules) {
			this.type = type;
			this.rules = rules;
		}

		// Or get rules if only type provided
		global FormulaShareWrapper(Schema.SObjectType type) {
			this.type = type;
			this.rules = FormulaShareRulesSelector.construct().getRulesSharingObject(type);
		}
	}

	// Wrapper for FormulaShare rules - primitive types only so this can be populated by test classes
	global class FSRule {
		public String objectSharedAPIName;
		public String sharedToAPIName;
		public String shareWith;
		public String accessLevel;
		public Boolean active;
		public String sharedToFieldType;
		public String sharingReason;
	}

	// Wrapper for a record and a rule sharing this record
	private class SObjectRule {
		SObject obj;
		FSRule rule;
	}

}