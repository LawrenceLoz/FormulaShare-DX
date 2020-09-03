/**
*Copyright 2019 Lawrence Newcombe
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

public with sharing class FormulaShareTriggerHelper implements FormulaShareIHelper {

	public class FormulaShareException extends Exception{}

	@TestVisible Map<String,FormulaShareService> populatedFsServiceMap = new Map<String, FormulaShareService>();
	@TestVisible private List<SObject> recordsInScopeOfStandardRules = new List<SObject>();
	@TestVisible private Map<String,List<Id>> parentTypesForQueryMap = new Map<String,List<Id>>();
	private static List<sObjectType> objectsRun = new List<sObjectType>();

	@TestVisible private enum OperationType {AFTER_INSERT_OR_UNDELETE, AFTER_UPDATE, AFTER_DELETE}

	// Constructor to assess sharing
	public FormulaShareTriggerHelper() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		sObjectType type;

		if(Trigger.isExecuting && Trigger.isAfter) {

			// Get SObject type in scope
			if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
				List<sObject> recordsChanged = Trigger.new;
				type = recordsChanged[0].getSObjectType();
			}
			else if(Trigger.isDelete) {
				List<sObject> recordsDeleted = Trigger.old;
				type = recordsDeleted[0].getSObjectType();
			}

			// Continue if we haven't already processed for this object (protects against calling in a loop)
			if(!objectsRun.contains(type)) {
				objectsRun.add(type);

				handleChanges(type, Trigger.oldMap, Trigger.newMap);
			}
		}
	}


	@TestVisible
	private void handleChanges(Schema.SObjectType type, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

		// Clear map in case populated from previous object in same transaction
		recordsInScopeOfStandardRules.clear();
		parentTypesForQueryMap.clear();

		// Determine trigger operation (we don't use trigger context variable so method can be unit tested)
		OperationType opType;
		if(oldRecords == null) {
			opType = OperationType.AFTER_INSERT_OR_UNDELETE;
		}
		else if(newRecords == null) {
			opType = OperationType.AFTER_DELETE;
		}
		else {
			opType = OperationType.AFTER_UPDATE;
		}

		// Get lists of standard and child rules which might be impacted by a change on this object
		String objectName = type.getDescribe().getName();
		FormulaShareRulesSelector fsRulesSelector = FormulaShareRulesSelector.construct();
		List<FormulaShareRule> standardRules = fsRulesSelector.getStandardRulesThisObjectControls(objectName);
		List<FormulaShareRule> childRules = fsRulesSelector.getChildRulesThisObjectControls(objectName);

		switch on opType {

			// If insert, submit records where one or more share to formula field is populated
			when AFTER_INSERT_OR_UNDELETE {
				for(SObject newRecord : newRecords.values()) {

					for(FormulaShareRule rule : standardRules) {

						// If sharing field specified on a standard rule is populated, we might need to assess sharing for this record
						if(newRecord.get(rule.sharedToAPIName) != null) {
							checkSharingImpactThisObject(newRecord, rule);
						}
					}

					for(FormulaShareRule rule : childRules) {

						// If sharing field on child rule is populated, we might need to assess sharing for the parent
						if(newRecord.get(rule.childObjectSharedToFieldAPIName) != null) {
							checkSharingImpactParentObjects(newRecord, rule);
						}
					}
				}
			}

			// If update, submit those where one or more share to formula field has changed
			when AFTER_UPDATE {
				for(SObject newRecord : newRecords.values()) {
					SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));

					for(FormulaShareRule rule : standardRules) {

						// If sharing field specified on a standard rule has changed, we might need to assess sharing for this record
						if(oldRecord.get(rule.sharedToAPIName) != newRecord.get(rule.sharedToAPIName)) {
							checkSharingImpactThisObject(newRecord, rule);
						}

						// If owner of shared standard object has changed we might need to check if this owner still requires sharing
						else if(oldRecord.get('OwnerId') != newRecord.get('OwnerId') && !rule.sharedObjectIsCustom) {
							checkSharingImpactThisObject(newRecord, rule);
						}
					}

					for(FormulaShareRule rule : childRules) {

						// If record has moved to a new parent, we might need to assess for the old parent and new parent
						if(oldRecord.get(rule.childObjectLookupFieldAPIName) != newRecord.get(rule.childObjectLookupFieldAPIName)) {
							checkSharingImpactParentObjects(newRecord, rule);
							checkSharingImpactParentObjects(oldRecord, rule);
						}

						// If sharing field on child rule has changed, we might need to assess sharing for the parent
						else if(oldRecord.get(rule.childObjectSharedToFieldAPIName) != newRecord.get(rule.childObjectSharedToFieldAPIName)) {
							checkSharingImpactParentObjects(newRecord, rule);
						}
					}
				}
			}

			when AFTER_DELETE {
				for(SObject oldRecord : oldRecords.values()) {

					for(FormulaShareRule rule : childRules) {

						// If sharing field on child rule is populated, we might need to assess sharing for the parent
						if(oldRecord.get(rule.childObjectSharedToFieldAPIName) != null) {
							checkSharingImpactParentObjects(oldRecord, rule);
						}
					}
				}
			}

		}

		// For all shared objects in the scope of the trigger which might need to be reassessed, submit these for sharing assessment
		if(!recordsInScopeOfStandardRules.isEmpty()) {
			List<FormulaShareRule> allRulesForObject = FormulaShareRulesSelector.construct().getRulesSharingObject(type);

			FormulaShareService fsService = FormulaShareService.construct(type, allRulesForObject);
			fsService.addToRecordsMap(recordsInScopeOfStandardRules);

			system.debug('Processing ' + fsService.getType());
			system.debug('records ' + recordsInScopeOfStandardRules);

			// Assess sharing and populate map
			fsService.processFormulaShares();
			String typeString = type.getDescribe().getName();
			populatedFsServiceMap.put('standardRule|' + typeString, fsService);
		}

		// For all parent objects (those which are the the shared object in child sharing rules)
		// Query for the records referenced in the lookups of records in the trigger scope
		if(!parentTypesForQueryMap.isEmpty()) {
			for(String parentAPIName : parentTypesForQueryMap.keySet()) {
				SObjectType parentType = FormulaShareUtilities.globalDescribe.get(parentAPIName);
				
				// Get all rules for the parent objects (to ensure we don't remove sharing which isn't covered by the child rules)
				List<FormulaShareRule> allRulesForParent = FormulaShareRulesSelector.construct().getRulesSharingObject(parentType);

				// Query for the parent records with all related children in subselect
				Set<Id> parentIdsToQuerySet = new Set<Id>();
				for(Id parentObjectId : parentTypesForQueryMap.get(parentAPIName)) {
					parentIdsToQuerySet.add(parentObjectId);
				}
				List<SObject> queriedParentObjects = FormulaShareService.getSObjectsWithFields(parentType, allRulesForParent, parentIdsToQuerySet);

				// Construct formulaShareService, populate records map and process sharing for the affected parent records
				FormulaShareService fsService = FormulaShareService.construct(parentType, allRulesForParent);
				fsService.addToRecordsMap(queriedParentObjects);

				system.debug('Processing ' + fsService.getType());
				system.debug('records ' + queriedParentObjects);

				fsService.processFormulaShares();

				populatedFsServiceMap.put('childRule|' + parentAPIName, fsService);
			}
		}
	}


	private void checkSharingImpactThisObject(SObject record, FormulaShareRule rule) {
		// Submit to recalculate only if rule is valid and active, and relevant field is populated
		if(rule.isValid
			&& rule.active
			&& rule.type == 'standard') {
			recordsInScopeOfStandardRules.add(record);
		}
	}

	private void checkSharingImpactParentObjects(SObject record, FormulaShareRule rule) {
		// Separate records which are children of records to have sharing assessed (will need to query for parents)
		if(rule.isValid
			&& rule.active
			&& rule.type == 'child'
			&& record.get(rule.childObjectLookupFieldAPIName) != null) {
			
			List<Id> parentsToQuery = new List<Id>();
			if(parentTypesForQueryMap.containsKey(rule.objectSharedAPIName)) {
				parentsToQuery = parentTypesForQueryMap.get(rule.objectSharedAPIName);
			}
			else {
				parentsToQuery = new List<Id>();
			}

			system.debug('this record: ' + record);
			system.debug('lookup: ' + record.get(rule.childObjectLookupFieldAPIName));

			parentsToQuery.add((Id) record.get(rule.childObjectLookupFieldAPIName));
			parentTypesForQueryMap.put(rule.objectSharedAPIName, parentsToQuery);
		}
	}

	public List<SObject> getSharesToDelete() {

		Map<String,FormulaShareService.ShareDetail> deleteDetails = new Map<String,FormulaShareService.ShareDetail>();
		List<SObject> sharesToDelete = new List<SObject>();

		if(!populatedFsServiceMap.isEmpty()) {
			for(FormulaShareService thisFsService : populatedFsServiceMap.values()) {
				Map<String,FormulaShareService.ShareDetail> thisDd = thisFsService.getDeleteDetails();
				if(thisDd != null) {
					deleteDetails.putAll(thisDd);
				}
			}

			for(FormulaShareService.ShareDetail sd : deleteDetails.values()) {
				sharesToDelete.add(sd.shareRecord);
			}

			/// Fire platform events to track the share deletions
			if(!deleteDetails.isEmpty()) {
				try {
					FormulaShareProcessEventPublisher publisher = new FormulaShareProcessEventPublisher();
					publisher.addDeleteEvents(deleteDetails, null, null);
					publisher.publish();
				}
				catch(Exception e) {
					System.debug('Exception constructing or publishing delete platform events. Details from Salesforce: '+e.getMessage());
				}
			}

			return sharesToDelete;
		}

		// Return an empty list if we hadn't initialised fsService (implies changes didn't require sharing updates)
		else {
			return new List<SObject>();
		}
	}


	public List<SObject> getSharesToInsert() {

		Map<String,FormulaShareService.ShareDetail> insertDetails = new Map<String,FormulaShareService.ShareDetail>();
		List<FormulaShareService.EntityNotFound> enfList = new List<FormulaShareService.EntityNotFound>();
		List<SObject> sharesToInsert = new List<SObject>();

		if(!populatedFsServiceMap.isEmpty()) {

			// Get details of inserted shares, and sharing which looked like it was needed but an entity couldn't be found
			for(FormulaShareService thisFsService : populatedFsServiceMap.values()) {
				Map<String,FormulaShareService.ShareDetail> thisInsertDetails = thisFsService.getInsertDetails();
				List<FormulaShareService.EntityNotFound> entitiesNotFound = thisFsService.getEntitiesNotFound();
				if(!thisInsertDetails.isEmpty()) {
					System.debug('insertDetails: '+thisInsertDetails.size()+' | '+ thisInsertDetails);
					insertDetails.putAll(thisInsertDetails);
				}
				if(!entitiesNotFound.isEmpty()) {
					System.debug('entitiesNotFound: '+entitiesNotFound.size()+' | '+ entitiesNotFound);
					enfList.addAll(entitiesNotFound);
				}
			}

			for(FormulaShareService.ShareDetail sd : insertDetails.values()) {
				sharesToInsert.add(sd.shareRecord);
			}

			/// Fire platform events to track the share insertions
			if(!insertDetails.isEmpty() || !enfList.isEmpty()) {
				try {
					FormulaShareProcessEventPublisher publisher = new FormulaShareProcessEventPublisher();
					publisher.addInsertEvents(insertDetails, null, null);
					publisher.addEventsForEntitiesNotFound(enfList);
					publisher.publish();
				}
				catch(Exception e) {
					System.debug('Exception constructing or publishing insert platform events. Details from Salesforce: '+e.getMessage());
				}
			}

			return sharesToInsert;
		}

		else {
			// Return an empty list if we hadn't initialised fsService (implies changes didn't require sharing updates)
			return new List<SObject>();
		}
	}

}
