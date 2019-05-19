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

global with sharing class FormulaShareTriggerHelper {

	public class FormulaShareException extends Exception{}

	@TestVisible Map<sObjectType,FormulaShareService> populatedFsServiceMap = new Map<sObjectType, FormulaShareService>();
	@TestVisible private Map<Id,SObject> recordsWithSharingChanges = new Map<Id,SObject>();
	private static List<sObjectType> objectsRun = new List<sObjectType>();

	// Constructor to assess sharing
	global FormulaShareTriggerHelper() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		if(Trigger.isExecuting && (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))) {

			// Get SObject type
			List<sObject> recordsChanged = Trigger.new;
			sObjectType type = recordsChanged[0].getSObjectType();

			// Continue if we haven't processed for this object
			if(!objectsRun.contains(type)) {

				// Add object type to prevent future runs (protects against calling in a loop)
				objectsRun.add(type);

				handleChanges(type, Trigger.oldMap, Trigger.newMap);
			}
		}
	}


	@TestVisible
	private void handleChanges(Schema.SObjectType type, Map<Id,SObject> existingRecords, Map<Id,SObject> newRecords) {

		// Clear map in case populated from previous object in same transaction
		recordsWithSharingChanges.clear();

		FormulaShareService fsService = FormulaShareService.construct(type);
		List<FormulaShareRule> rules = fsService.getRules();

		Boolean isInsert = existingRecords != null ? false : true;

		// If insert, submit records where one or more share to formula field is populated
		if(isInsert) {
			for(SObject newRecord : newRecords.values()) {
				for(FormulaShareRule rule : rules) {
					
					// Submit to recalculate only if relevant field is populated and rule is active
					if(rule.sharedToAPIName != null && newRecord.get(rule.sharedToAPIName) != null && rule.active) {
						recordsWithSharingChanges.put((Id) newRecord.get('Id'), newRecord);
					}
				}
			}
		}

		// If update, submit those where one or more share to formula field has changed
		else {
			for(SObject newRecord : newRecords.values()) {
				SObject oldRecord = existingRecords.get((Id) newRecord.get('Id'));
				for(FormulaShareRule rule : rules) {
					if(rule.active) {

						// Submit to recalculate only if relevant field has changed
						if(oldRecord.get(rule.sharedToAPIName) != newRecord.get(rule.sharedToAPIName)
							|| (oldRecord.get('OwnerId') != newRecord.get('OwnerId') && !type.getDescribe().isCustom()) ) {
							recordsWithSharingChanges.put((Id) newRecord.get('Id'), newRecord);
						}
					}
				}
			}
		}

		// Submit relevant records if sharing changes might be needed
		if(!recordsWithSharingChanges.isEmpty()) {
			fsService.setRecordsMap(recordsWithSharingChanges);

			// Assess sharing and populate map
			fsService.processFormulaShares();
			populatedFsServiceMap.put(type, fsService);
		}
	}


	global List<SObject> getSharesToDelete() {

		if(populatedFsServiceMap.size() == 1 && populatedFsServiceMap.values()[0].getSharesToDelete() != null) {
			FormulaShareService thisFsService = populatedFsServiceMap.values()[0];
			List<SObject> sharesToDelete = thisFsService.getSharesToDelete();
			return sharesToDelete;
		}

		else if(populatedFsServiceMap.size() > 1) {
			throw new FormulaShareException('More than one object in scope - call getSharesToDelete with object name instead');
		}

		// Return an empty list if we hadn't initialised fsService (implies changes didn't require sharing updates)
		else {
			return new List<SObject>();
		}
	}


	global List<SObject> getSharesToInsert() {

		if(populatedFsServiceMap.size() == 1 && populatedFsServiceMap.values()[0].getSharesToInsert() != null) {
			FormulaShareService thisFsService = populatedFsServiceMap.values()[0];
			List<SObject> sharesToInsert = thisFsService.getSharesToInsert();
			return sharesToInsert;
		}

		else if(populatedFsServiceMap.size() > 1) {
			throw new FormulaShareException('More than one object in scope - call getSharesToInsert with object name instead');
		}

		else {
			// Return an empty list if we hadn't initialised fsService (implies changes didn't require sharing updates)
			return new List<SObject>();
		}
	}

}
