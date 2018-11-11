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

public with sharing class FormulaShareService {

	public class FormulaShareException extends Exception{}

	public static void triggerHandler() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

			// Get SObject type
			List<sObject> recordsChanged = Trigger.new;
			sObjectType type = recordsChanged[0].getSObjectType();

			handleShareChanges(type, Trigger.oldMap, Trigger.newMap);
		}
	}


	public static void handleShareChanges(Schema.SObjectType type, Map<Id, SObject> existingRecords, Map<Id, SObject> newRecords) {

		ProcessFormulaShareQueueable job;
		FormulaShareWrapper fsWrapper = new FormulaShareWrapper(type);

		Boolean isUpdate = existingRecords != null ? true : false;

		// If insert, submit all records
		if(!isUpdate) {
			fsWrapper.recordsMap = newRecords;

			// Queue job for processing relevant records
			job = new ProcessFormulaShareQueueable(fsWrapper);
			ID formulaShareInsertJobID = System.enqueueJob(job);
		}

		// If update, submit those where one or more share to formula field has changed
		else {
			Map<Id,SObject> recordsWithSharingChanges = new Map<Id,SObject>();

			for(SObject newRecord : newRecords.values()) {
				SObject oldRecord = existingRecords.get((Id) newRecord.get('Id'));
				
				for(FormulaShare_Rule__mdt rule : fsWrapper.typeRules.rules) {
					String sharedTo = rule.Shared_To_Field__c;

					// Submit to recalculate only if relevant field has changed and rule is active
					if(oldRecord.get(sharedTo) != newRecord.get(sharedTo) && rule.Active__c) {
						recordsWithSharingChanges.put((Id) newRecord.get('Id'), newRecord);
					}
				}
			}

			if(!recordsWithSharingChanges.isEmpty()) {
				fsWrapper.recordsMap = recordsWithSharingChanges;

				// Queue job for processing relevant records
				job = new ProcessFormulaShareQueueable(fsWrapper);
				ID formulaShareUpdateJobID = System.enqueueJob(job);
			}
		}

	}


	// Core method called from trigger and batch context
	public static void processFormulaShares(FormulaShareWrapper fsWrapper) {

		Boolean removeExistingShares = true;

		// Retrieve current record shares if type in scope is a custom object
		if(fsWrapper.typeRules.type.getDescribe().isCustom()) {
			
			// Get all relevant row causes (aka apex sharing reasons) used in rules
			Set<String> rowCauseSet = new Set<String>();
			for(FormulaShare_Rule__mdt rule : fsWrapper.typeRules.rules) {
				rowCauseSet.add(rule.Sharing_Reason__c);
			}

			String sharesQueryStringCustom = buildShareQueryCustom(fsWrapper, rowCauseSet);
			List<SObject> sharesQueryResultCustom = Database.query(sharesQueryStringCustom);
			system.debug('Share query result: '+sharesQueryResultCustom);

			// Create map of shareQueryResults with record shares unique key
			for(SObject share : sharesQueryResultCustom) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);
				fsWrapper.mapToDelete.put(shareKey, share);
			}
		}

		// Retrieve current record shares if type in scope is a standard object
		else {
			String sharesQueryStringStandard = buildShareQueryStandard(fsWrapper);
			List<SObject> sharesQueryResultStandard = Database.query(sharesQueryStringStandard);
			system.debug('Share query result: '+sharesQueryResultStandard);

			// Create map of all record shares with unique key
			// Any required shares will be removed from this map and the remainder deleted (if settings allow this)
			for(SObject share : sharesQueryResultStandard) {
				String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(fsWrapper.typeRules.type, share);
				fsWrapper.mapToDelete.put(shareKey, share);
			}

			// Ensure shares are not deleted if settings do not allow this
			FormulaShare_Settings__mdt settings = FormulaShareSettings.getFormulaShareSettings();
			if(!settings.Remove_Shares_for_Standard_Objects__c) {
				removeExistingShares = false;
			}
		}

		// Assess sharing to be created or kept (will update deletion and insertion maps)
		assessRequiredShares(fsWrapper);

		Savepoint sp = Database.setSavepoint();

		// Remove sharing which is no longer needed
		if(removeExistingShares) {
			System.debug('Sharing to be removed: '+fsWrapper.mapToDelete.values());
			delete fsWrapper.mapToDelete.values();
		}

		// Insert new object share records
		System.debug('Sharing to be inserted: '+fsWrapper.setToInsert);
		try {
			List<SObject> sharesToInsertList = new List<SObject>(fsWrapper.setToInsert);
			insert sharesToInsertList;
		}

		// Revert to prior state if exceptions after deletion
		catch(Exception e) {
			Database.rollback(sp);
			throw e;
		}
	}


	public static void assessRequiredShares(FormulaShareWrapper fsWrapper) {
		
		Set<Id> roleQueryIdSet = new Set<Id>();

		Set<SObjectRule> roleRecordRules = new Set<SObjectRule>();
		Set<SObjectRule> groupRecordRules = new Set<SObjectRule>();

		Set<String> sharedToNamesGroups = new Set<String>();
		Set<String> sharedToNamesRoles = new Set<String>();

		for(SObject record : fsWrapper.recordsMap.values()) {
			
			for(FormulaShare_Rule__mdt rule : fsWrapper.typeRules.rules) {
			String sharedToString = (String) record.get(rule.Shared_To_Field__c);
				
				// Only need to check records where sharing field is populated and where rule is active
				if(!String.isBlank(sharedToString) && rule.Active__c) {
					try {

						// Add User Id to map
						if(rule.Share_With__c == 'Users') {
							if(FormulaShareUtilities.isValidIdType(sharedToString, Schema.User.getSObjectType())) {

								// Attempt to create a share record only if user isn't the record owner
								if((Id) sharedToString != record.get('OwnerId')) {
									updateShareMaps(record.Id, (Id) sharedToString, rule, fsWrapper);
								}

								else system.debug('Not necessary to share record with owner');
							}
							else {
								throw new FormulaShareException();
							}
						}

						// Add Group Id to map
						else if(rule.Share_With__c == 'Public Groups') {
							if(rule.Shared_To_Field_Type__c == 'Id' &&
								FormulaShareUtilities.isValidIdType(sharedToString, Schema.Group.getSObjectType())) {
								updateShareMaps(record.Id, (Id) sharedToString, rule, fsWrapper);
							}
							else if(rule.Shared_To_Field_Type__c == 'Name') {
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
						else if(rule.Share_With__c == 'Roles' || rule.Share_With__c == 'Roles and Internal Subordinates') {
							if(rule.Shared_To_Field_Type__c == 'Id' &&
								FormulaShareUtilities.isValidIdType(sharedToString, Schema.UserRole.getSObjectType())) {
								roleQueryIdSet.add((Id) sharedToString);
							}
							else if(rule.Shared_To_Field_Type__c == 'Name') {
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

						else system.debug('Share With value ' + rule.Share_With__c + ' does not match allowed options');

					}
					catch(FormulaShareException e) {
						system.debug('Expected Id entity relevant to type ' + rule.Share_With__c
						+ ' in field ' + rule.Shared_To_Field__c
						+ ' on object ' + rule.Shared_Object__c
						+ '. For record ' + record.Id
						+ ' instead found value ' + sharedToString);
					}
				}
			}
		}
		
		// Process group sharing from group names if needed
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

		// Process sharing for all role and/or role and subordinate records
		if(!roleQueryIdSet.isEmpty() || !roleNamesToIdsMap.isEmpty()) {
			assessRoleSharing(roleQueryIdSet, roleRecordRules
				, roleNamesToIdsMap, fsWrapper);
		}
	}


	public static void assessGroupSharingFromNames(Set<String> groupNames, Set<SObjectRule> groupRecordRules, FormulaShareWrapper fsWrapper) {

		Map<String,Id> groupsMap = getGroupsFromNames(groupNames);

		for(SObjectRule recordRule : groupRecordRules) {
			String sharedToName = (String) recordRule.obj.get(recordRule.rule.Shared_To_Field__c);
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

			String sharedTo = (String) recordRule.obj.get(recordRule.rule.Shared_To_Field__c);
			Id sharedToId = null;
			Id roleGroupId = null;

			if(recordRule.rule.Shared_To_Field_Type__c == 'Name') {
				sharedToId = roleNamesToIdsMap.get(sharedTo);
			}

			else if(recordRule.rule.Shared_To_Field_Type__c == 'Id') {
				sharedToId = (Id) sharedTo;
			}

			String shortSharedToId = FormulaShareUtilities.get15CharacterId(sharedToId);

			if(recordRule.rule.Share_With__c == 'Roles') {
				roleGroupId = roleGroupIds.get(shortSharedToId + 'Role');
			}

			else if(recordRule.rule.Share_With__c == 'Roles and Internal Subordinates') {
				roleGroupId = roleGroupIds.get(shortSharedToId + 'RoleAndSubordinates');
			}

			updateShareMaps(recordRule.obj.Id, roleGroupId, recordRule.rule, fsWrapper);
		}
	}


	public static void updateShareMaps(Id recordId, Id sharedTo, FormulaShare_Rule__mdt rule, FormulaShareWrapper fsWrapper) {
		
		// For custom objects, check whether sharing record for this sharing reason exists at correct access level
		if(fsWrapper.typeRules.type.getDescribe().isCustom()) {
			updateShareMapsCustom(recordId, sharedTo, rule, fsWrapper);
		}

		// For standard objects, check whether any sharing record exists at this access level or higher
		else {
			updateShareMapsStandard(recordId, sharedTo, rule, fsWrapper);
		}
	}


	public static void updateShareMapsCustom(Id recordId, Id sharedTo, FormulaShare_Rule__mdt rule, FormulaShareWrapper fsWrapper) {
		String shareKey = FormulaShareUtilities.get15CharacterId(recordId)
			 + FormulaShareUtilities.get15CharacterId(sharedTo) 
			 + rule.Access_Level__c
			 + rule.Sharing_Reason__c;
		
		// If share record exists already, remove from map to be deleted
		if(fsWrapper.mapToDelete.get(shareKey) != null) {
			fsWrapper.mapToDelete.remove(shareKey);
		}

		// Otherwise add to map to be inserted
		else {
			SObject newShare = getShareRecordCustom(fsWrapper.typeRules.type, recordId, sharedTo, rule);
			fsWrapper.setToInsert.add(newShare);
		}
	}


	public static void updateShareMapsStandard(Id recordId, Id sharedTo, FormulaShare_Rule__mdt rule, FormulaShareWrapper fsWrapper) {

		// Check whether we have any shares for this record already
		String shareKeyBase = FormulaShareUtilities.get15CharacterId(recordId) + FormulaShareUtilities.get15CharacterId(sharedTo);
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
			if(rule.Access_Level__c == 'Read') {
				fsWrapper.mapToDelete.remove(shareKeyRead);
			}

			// Otherwise add higher level share to be inserted
			else {
				SObject newShare = getShareRecordStandard(fsWrapper.typeRules.type, recordId, sharedTo, rule);
				fsWrapper.setToInsert.add(newShare);
			}
		}

		// If no share found, add to be created
		else {
				SObject newShare = getShareRecordStandard(fsWrapper.typeRules.type, recordId, sharedTo, rule);
				fsWrapper.setToInsert.add(newShare);
		}
	}


	public static String buildShareQueryCustom(FormulaShareWrapper fsWrapper, Set<String> rowCauseSet) {
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(fsWrapper.typeRules.type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(fsWrapper.recordsMap.keySet());
		String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(rowCauseSet);
		String queryString = 'SELECT Id, UserOrGroupId, ParentId, AccessLevel, RowCause'
			+' FROM '+shareObjectType
			+' WHERE ParentId IN (' + parentIdsString + ') AND RowCause IN (' + rowCausesString + ')';
		system.debug('Share query: ' + queryString);
		return queryString;
	}


	public static String buildShareQueryStandard(FormulaShareWrapper fsWrapper) {
		String objectName = fsWrapper.typeRules.type.getDescribe().getName();
		SObjectType shareObjectType = FormulaShareUtilities.getShareObject(fsWrapper.typeRules.type);
		String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(fsWrapper.recordsMap.keySet());
		String queryString = 'SELECT Id, UserOrGroupId, ' + objectName + 'Id, ' + objectName + 'AccessLevel'
			+' FROM ' + shareObjectType
			+' WHERE ' + objectName + 'Id IN (' + parentIdsString + ') AND RowCause = \'Manual\'';
		return queryString;
	}


	public static SObject getShareRecordCustom(Schema.SObjectType type, Id recordId, Id sharedTo, FormulaShare_Rule__mdt rule) {
		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);
		SObject newShare = shareType.newSObject();
		newShare.put('AccessLevel',rule.Access_Level__c);
		newShare.put('ParentId',recordId);
		newShare.put('RowCause',rule.Sharing_Reason__c);
		newShare.put('UserOrGroupId',sharedTo);
		return newShare;
	}


	public static SObject getShareRecordStandard(Schema.SObjectType type, Id recordId, Id sharedTo, FormulaShare_Rule__mdt rule) {
		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);
		SObject newShare = shareType.newSObject();
		newShare.put(type + 'AccessLevel',rule.Access_Level__c);
		newShare.put(type + 'Id',recordId);
//		newShare.put('RowCause','Manual');		// Only reason supported for standard objects is manual (set by default)
		newShare.put('UserOrGroupId',sharedTo);
		return newShare;
	}


	// Used by batch job
	public static String getFullObjectQuery(RulesForTypeWrapper typeRules) {
		String objectName = typeRules.type.getDescribe().getName();
		Set<String> sharedToFieldSet = new Set<String>();
		for(FormulaShare_Rule__mdt rule : typeRules.rules) {
			String sharedTo = rule.Shared_To_Field__c;
			sharedToFieldSet.add(sharedTo);
		}
		String query = 'SELECT Id, OwnerId, ' + FormulaShareUtilities.buildStringFromSetNoQuotes(sharedToFieldSet)
			+ ' FROM ' + objectName;
		System.debug('Full object query: ' + query);
		return query;
	}


	public class FormulaShareWrapper {
		public RulesForTypeWrapper typeRules;
		public Map<Id,SObject> recordsMap = new Map<Id,SObject>();
		public Map<String,SObject> mapToDelete = new Map<String,SObject>();
		public Set<SObject> setToInsert = new Set<SObject>();
		public Map<String,Id> sharingReasonsIdMap = new Map<String,Id>();

		// Set typeRules if provided
		public FormulaShareWrapper(RulesForTypeWrapper typeRules) {
			this.typeRules = typeRules;
		}

		// Or call RulesForTypeWrapper constructor if only type provided
		public FormulaShareWrapper(Schema.SObjectType type) {
			RulesForTypeWrapper newTypeRules = new RulesForTypeWrapper(type);
			this.typeRules = newTypeRules;
		}

	}


	public class RulesForTypeWrapper {
		public Schema.SObjectType type;
		public List<FormulaShare_Rule__mdt> rules;

		// Set type and find relevant rules on creation
		public RulesForTypeWrapper(Schema.SObjectType type) {
			this.type = type;
			this.rules = getRulesSharingObject(type);
			system.debug('fsWrapper rules populated: '+rules);
		}	
	}


	private class SObjectRule {
		SObject obj;
		FormulaShare_Rule__mdt rule;
	}


	public static List<FormulaShare_Rule__mdt> getRulesSharingObject(Schema.sObjectType type) {

		String objectName = type.getDescribe().getName();

		// Create list of all jobs with relevant details for assessing scope
		List<FormulaShare_Rule__mdt> rulesSharingObject =
			[SELECT Id, Access_Level__c, Shared_Object__c, Shared_To_Field__c, 
			Share_With__c, Sharing_Reason__c, Active__c, Shared_To_Field_Type__c
			FROM FormulaShare_Rule__mdt
			WHERE Shared_Object__c = :objectName];

		system.debug('All rules sharing object: '+rulesSharingObject);

		// If running test, return a dummy FormulaShare rule to support further processing
		if(Test.isRunningTest()) {
			List<FormulaShare_Rule__mdt> testRules = setTestRules();
			rulesSharingObject.clear();
			rulesSharingObject.addAll(testRules);
		}

		return rulesSharingObject;
	}


	public static List<SObjectType> getSharedObjectTypes() {

		List<SObjectType> typesList = new List<SObjectType>();
		Set<SObjectType> typesSet = new Set<SObjectType>();

		// Loop through all rules to check whether they are impacted by changes to this object
		for(FormulaShare_Rule__mdt rule : 
			[SELECT Shared_Object__c
			FROM FormulaShare_Rule__mdt
			]) {
			// Check whether rule shares this object
			String objName = rule.Shared_Object__c;
			SObjectType type = Schema.getGlobalDescribe().get(objName);
			typesSet.add(type);
			}

		if(!Test.isRunningTest()) {
			for(SObjectType type : typesSet) {
				typesList.add(type);
			}
		}

		// If running test return list with contact to enable execution of other code
		else {
			typesList.add(Contact.SobjectType);
		}

		return typesList;
	}


	// Submits batch recalculation of all sharing
	public static void recalculateAll() {
		FormulaShare_Settings__mdt settings = FormulaShareSettings.getFormulaShareSettings();
		Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();
		List<Schema.SObjectType> types = getSharedObjectTypes();
		Id batchJobId = Database.executeBatch(new ProcessFormulaShareBatch(types, batchSize), batchSize);
	}


	// Return a list of dummy rules to use in test methods
	private static List<FormulaShare_Rule__mdt> setTestRules() {
		List<FormulaShare_Rule__mdt> testRules = new List<FormulaShare_Rule__mdt>();

		FormulaShare_Rule__mdt testRule1 = new FormulaShare_Rule__mdt();
		testRule1.Access_Level__c = 'Edit';
		testRule1.Shared_Object__c = 'Contact';
		testRule1.Shared_To_Field__c = 'FirstName';		// Will add a sharing record for the user who created the Contact
		testRule1.Share_With__c = 'Roles';
		testRule1.Active__c = true;
		testRule1.Shared_To_Field_Type__c = 'Name';
		testRules.add(testRule1);
	
		FormulaShare_Rule__mdt testRule2 = new FormulaShare_Rule__mdt();
		testRule2.Access_Level__c = 'Edit';
		testRule2.Shared_Object__c = 'Contact';
		testRule2.Shared_To_Field__c = 'LastName';		// Will add a sharing record for the user who created the Contact
		testRule2.Share_With__c = 'Roles and Internal Subordinates';
		testRule2.Active__c = true;
		testRule2.Shared_To_Field_Type__c = 'Id';
		testRules.add(testRule2);
	
		FormulaShare_Rule__mdt testRule3 = new FormulaShare_Rule__mdt();
		testRule3.Access_Level__c = 'Edit';
		testRule3.Shared_Object__c = 'Contact';
		testRule3.Shared_To_Field__c = 'Description';		// Will add a sharing record for the user who created the Contact
		testRule3.Share_With__c = 'Public Groups';
		testRule3.Active__c = true;
		testRule3.Shared_To_Field_Type__c = 'Name';
		testRules.add(testRule3);

		FormulaShare_Rule__mdt testRule4 = new FormulaShare_Rule__mdt();
		testRule4.Access_Level__c = 'Edit';
		testRule4.Shared_Object__c = 'Contact';
		testRule4.Shared_To_Field__c = 'AssistantName';		// Will add a sharing record for the user who created the Contact
		testRule4.Share_With__c = 'Users';
		testRule4.Active__c = true;
		testRule4.Shared_To_Field_Type__c = 'Id';
		testRules.add(testRule4);

		return testRules;
	}

}