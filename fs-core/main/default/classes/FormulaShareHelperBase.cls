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


// Implements methods acting on a list of FormulaShareService classes (populated within extending classes)
public abstract inherited sharing class FormulaShareHelperBase {

	// Used to prevent recursion
	@TestVisible private static Set<Id> processedIds = new Set<Id>();

    @TestVisible protected List<FormulaShareService> populatedFsServiceList = new List<FormulaShareService>();
	
    @TestVisible
    protected void handleChanges(Schema.SObjectType type, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

		// Check whether settings allow recursion
		FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
		Map<Id,SObject> oldRecordsToProcess;
		Map<Id,SObject> newRecordsToProcess;

		// Process all records if permitted
		if(settings.Allow_Recursive_Reassessment__c) {
			oldRecordsToProcess = oldRecords;
			newRecordsToProcess = newRecords;
		}

		// Otherwise remove any records processed this transaction
		else {
			oldRecordsToProcess = stripProcessed(oldRecords);
			newRecordsToProcess = stripProcessed(newRecords);
		}
		processedIds.addAll(newRecords.keySet());

		// Retrieve relevant info and establish FormulaShareService list
		setServiceObjectsWithRecords(type, oldRecordsToProcess, newRecordsToProcess);

		for(FormulaShareService fsService : populatedFsServiceList) {
			fsService.processFormulaShares();
		}
	}


	// Returns a map with records processed this transaction removed
	@TestVisible
	private Map<Id,SObject> stripProcessed(Map<Id,SObject> recordsMap) {
		if(recordsMap == null) {
			return null;
		}

		Map<Id,SObject> unprocessedMap;

		// First time only save a loop by returning map as is
		if(processedIds.isEmpty()) {
			unprocessedMap = recordsMap;
		}

		// Otherwise, create a new map with records not yet processed
		else {
			unprocessedMap = new Map<Id,SObject>();
			for(Id thisId : recordsMap.keySet()) {
				if(!processedIds.contains(thisId)) {
					unprocessedMap.put(thisId, recordsMap.get(thisId));
				}
			}
		}

		return unprocessedMap;
	}


	@TestVisible
	private void setServiceObjectsWithRecords(Schema.SObjectType type, Map<Id,SObject> oldRecords, Map<Id,SObject> newRecords) {

        // Check records for possible sharing impact, query for extra lookups if needed, and get rules and record details
		FormulaShareHelperService helperService = new FormulaShareHelperService(type, oldRecords, newRecords);
		List<FormulaShareServiceDetailsForType> detailsForTypes = helperService.getDetailsForTypes();

        // Iterate through objects which may need sharing changes and assess what these should be
		for(FormulaShareServiceDetailsForType details : detailsForTypes) {

			System.debug('Full details ' + details);
			for(FormulaShareRetrievedRecordDetails retDetails : details.retrieveRecordDetails.values()) {
				System.debug('Shared record: '+retDetails.sharedRecord+' | controlling records: '+retDetails.controllingRecordsForRulesMap);
			}

			// Instantiate processing service with record sharing details
			FormulaShareService fsService = FormulaShareService.construct(details.sharedType, details.rules);
			if(!details.removeExistingShares) {
				fsService.disableShareRemoval();
			}
			fsService.setSharedRecordDetails(details.retrieveRecordDetails.values());

			system.debug('Processing ' + fsService.getType());
			system.debug('records ' + details.retrieveRecordDetails);

			populatedFsServiceList.add(fsService);
        }
	}


	public List<SObject> getSharesToDelete() {

		Map<String,FormulaShareService.ShareDetail> deleteDetails = new Map<String,FormulaShareService.ShareDetail>();
		List<SObject> sharesToDelete = new List<SObject>();

		if(!populatedFsServiceList.isEmpty()) {
			for(FormulaShareService thisFsService : populatedFsServiceList) {
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

		if(!populatedFsServiceList.isEmpty()) {

			// Get details of inserted shares, and sharing which looked like it was needed but an entity couldn't be found
			for(FormulaShareService thisFsService : populatedFsServiceList) {
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
