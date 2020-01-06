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

public class FormulaShareProcessBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	List<Schema.SObjectType> types;
	Integer batchSize;
	Schema.SObjectType typeInThisBatch;
	List<FormulaShareRule> rulesForType;
	List<FormulaShare_Log__c> logsList = new List<FormulaShare_Log__c>();


	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public FormulaShareProcessBatch(List<Schema.SObjectType> types, Integer batchSize) {
		this.types = types;
		this.batchSize = batchSize;
		this.typeInThisBatch = types[0];
		this.rulesForType = FormulaShareRulesSelector.construct().getRulesSharingObject(typeInThisBatch);
	}
	

	public Database.QueryLocator start(Database.BatchableContext BC) {
		system.debug('FormulaShare batch job started. Type in scope: '+typeInThisBatch);
		system.debug('Rules for this object: '+rulesForType);

		if(!rulesForType.isEmpty()) {
			Database.QueryLocator ql = FormulaShareService.getAllSharedObjectsLocator(typeInThisBatch);

			system.debug('query locator: ' + ql);

			FormulaShare_Log__c log = new FormulaShare_Log__c();
			logsList = new List<FormulaShare_Log__c>();
			logsList.add(log);
			FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

			fsLogs.setContext('FormulaShareProcessBatch', null, 'Batch');
			String typeInScope = typeInThisBatch.getDescribe().getName();
//			Integer noRules = rulesForType.size();
			String query = ql.getQuery();
			fsLogs.setBatchDetails(batchSize, typeInScope, 0, query);	// need to fix this
			logsList = fsLogs.upsertLogs();
			return ql;
		}

		else {
			return null;
		}
	}


   	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		FormulaShareService fsService = FormulaShareService.construct(typeInThisBatch, rulesForType);
		Map<Id,SObject> recordsMap = new Map<Id,SObject>();

		system.debug('*** batch scope : '+ scope);

		// Re-query batch scope for fields and child objects (avoids issues with sub-selects in query locator)
		List<SObject> records = FormulaShareService.getObjectsWithFields(typeInThisBatch, rulesForType, scope);

		// Populate records in batch scope into wrapper
		for(SObject record : records) {
			recordsMap.put(record.Id, record);
		}
		fsService.setRecordsMap(recordsMap);

		// Assess sharing for this object
		fsService.processFormulaShares();
		Schema.SObjectType type = fsService.getType();

		// Insert and remove sharing if required
		if(!fsService.getSharesToInsert().isEmpty()) {
			FormulaShareSObjectShares fsSharesToInsert = FormulaShareSObjectShares.construct(fsService.getSharesToInsert(), type);
			fsSharesToInsert.insertShares();
		}

		Savepoint sp = Database.setSavepoint();

		if(!fsService.getSharesToDelete().isEmpty()) {
			FormulaShareSObjectShares fsSharesToDelete = FormulaShareSObjectShares.construct(fsService.getSharesToDelete(), type);
			try {
				fsSharesToDelete.deleteShares();
			}

			// Revert to prior state if exceptions after deletion
			catch(Exception e) {
				Database.rollback(sp);
				throw e;
			}
		}

		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.incrementBatches();
		logsList = fsLogs.upsertLogs();
	}
	

	public void finish(Database.BatchableContext BC) {
		
		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.setBatchProcessingComplete();
		logsList = fsLogs.upsertLogs();

		// If there are more types to process, submit another batch
		if(types.size() > 1) {
			types.remove(0);
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, batchSize), batchSize);
			system.debug('Submitted next batch, Id = ' + batchJobId);
		}

	}
	
}