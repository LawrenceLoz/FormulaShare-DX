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

	static List<sObjectType> objectsRun = new List<sObjectType>();

	global static void run() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

			// Get SObject type
			List<sObject> recordsChanged = Trigger.new;
			sObjectType type = recordsChanged[0].getSObjectType();

			// Continue if we haven't processed for this object
			if(!objectsRun.contains(type)) {

				// Add object type to prevent future runs (protects against calling in a loop)
				objectsRun.add(type);

				// Check whether we're already at the maximum number of queueable jobs allowed for the transaction
				Boolean atMaxQueueableJobsSynch = !System.isBatch() && Limits.getQueueableJobs() == 50;
				Boolean atMaxQueueableJobsBatch = System.isBatch() && Limits.getQueueableJobs() == 1;

				if(!atMaxQueueableJobsSynch && !atMaxQueueableJobsBatch) {
					handleShareChanges(type, Trigger.oldMap, Trigger.newMap);
				}

				else {
					system.debug('At max allowed queueable jobs in transaction');
				}
			}
		}
	}


	public static void handleShareChanges(Schema.SObjectType type, Map<Id, SObject> existingRecords, Map<Id, SObject> newRecords) {

		ProcessFormulaShareQueueable job;
		FormulaShareService.FormulaShareWrapper fsWrapper = new FormulaShareService.FormulaShareWrapper(type);

		Boolean isInsert = existingRecords != null ? false : true;

		// If insert, submit all records
		if(isInsert) {
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
				
				for(FormulaShareService.FSRule rule : fsWrapper.rules) {

					// Submit to recalculate only if relevant field has changed and rule is active
					if(oldRecord.get(rule.sharedToAPIName) != newRecord.get(rule.sharedToAPIName) && rule.active) {
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


	// Inner class designated as without sharing to ensure that object share records can be 
	// created / updated when code is run in user context (necessary for triggers updates)
	public without sharing class DMLProcessing {

		public void makeChanges(FormulaShareService.FormulaShareWrapper fsWrapper) {
            
            Savepoint sp = Database.setSavepoint();

            // Remove sharing which is no longer needed
            if(!fsWrapper.mapToDelete.isEmpty()) {
                System.debug('Sharing to be removed: '+fsWrapper.mapToDelete.values());
                delete fsWrapper.mapToDelete.values();
            }

            // Insert new object share records
            System.debug('Sharing to be inserted: '+fsWrapper.setToInsert);
            List<SObject> sharesToInsertList = new List<SObject>(fsWrapper.setToInsert);
            try {
                insert sharesToInsertList;
            }

            // Revert to prior state if exceptions after deletion
            catch(Exception e) {
                Database.rollback(sp);
                throw e;
            }
        }
	}



	Map<sObjectType, FormulaShareService.FormulaShareWrapper> populatedFsWrapperMap = new Map<sObjectType, FormulaShareService.FormulaShareWrapper>();

	// Constructor to assess sharing
	global FormulaShareTriggerHelper() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

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


	private void handleChanges(Schema.SObjectType type, Map<Id, SObject> existingRecords, Map<Id, SObject> newRecords) {

		ProcessFormulaShareQueueable job;
		FormulaShareService.FormulaShareWrapper fsWrapper = new FormulaShareService.FormulaShareWrapper(type);

		Boolean isInsert = existingRecords != null ? false : true;

		// If insert, submit all records
		if(isInsert) {
			fsWrapper.recordsMap = newRecords;

			// Assess sharing and populate map
			FormulaShareService.FormulaShareWrapper populatedFsWrapper = FormulaShareService.processFormulaShares(fsWrapper);
			populatedFsWrapperMap.put(type, populatedFsWrapper);
		}

		// If update, submit those where one or more share to formula field has changed
		else {
			Map<Id,SObject> recordsWithSharingChanges = new Map<Id,SObject>();

			for(SObject newRecord : newRecords.values()) {
				SObject oldRecord = existingRecords.get((Id) newRecord.get('Id'));
				
				for(FormulaShareService.FSRule rule : fsWrapper.rules) {

					// Submit to recalculate only if relevant field has changed and rule is active
					if(oldRecord.get(rule.sharedToAPIName) != newRecord.get(rule.sharedToAPIName) && rule.active) {
						recordsWithSharingChanges.put((Id) newRecord.get('Id'), newRecord);
					}
				}
			}

			if(!recordsWithSharingChanges.isEmpty()) {
				fsWrapper.recordsMap = recordsWithSharingChanges;

				// Assess sharing and populate map
				FormulaShareService.FormulaShareWrapper populatedFsWrapper = FormulaShareService.processFormulaShares(fsWrapper);
				populatedFsWrapperMap.put(type, populatedFsWrapper);
			}
		}
	}


	global List<SObject> getSharesToDelete() {

		if(populatedFsWrapperMap.size() == 1 && populatedFsWrapperMap.values()[0].mapToDelete != null) {
			FormulaShareService.FormulaShareWrapper thisFSWrapper = populatedFsWrapperMap.values()[0];
			List<SObject> sharesToDelete = thisFSWrapper.mapToDelete.values();
			return sharesToDelete;
		}

		else if(populatedFsWrapperMap.size() > 1) {
			throw new FormulaShareException('More than one object in scope - call getSharesToDelete with object name instead');
		}

		else {
			throw new FormulaShareException('Map not popualted as expected');
		}
	}

	global List<SObject> getSharesToInsert() {

		if(populatedFsWrapperMap.size() == 1 && populatedFsWrapperMap.values()[0].setToInsert != null) {
			FormulaShareService.FormulaShareWrapper thisFSWrapper = populatedFsWrapperMap.values()[0];
			List<SObject> sharesToInsert = new List<SObject>(thisFSWrapper.setToInsert);
			return sharesToInsert;
		}

		else if(populatedFsWrapperMap.size() > 1) {
			throw new FormulaShareException('More than one object in scope - call getSharesToInsert with object name instead');
		}

		else {
			throw new FormulaShareException('Map not popualted as expected');
		}
	}

}
