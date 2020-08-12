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
	Set<String> newMetricsForBatch;
	public static final String batchContext = 'Batch';

	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public FormulaShareProcessBatch(List<Schema.SObjectType> types, Integer batchSize) {
		this.types = types;
		this.batchSize = batchSize;
		this.typeInThisBatch = types[0];
		this.rulesForType = FormulaShareRulesSelector.construct().getRulesSharingObject(typeInThisBatch);
	}
	

	public Database.QueryLocator start(Database.BatchableContext context) {
		system.debug('FormulaShare batch job started. Type in scope: '+typeInThisBatch);
		system.debug('Rules for this object: '+rulesForType);

		if(!rulesForType.isEmpty()) {
			Database.QueryLocator ql = FormulaShareService.getAllSharedObjectsLocator(typeInThisBatch);
			system.debug('query locator: ' + ql);

			// Establish unit of work for batch log and rules in batch
			fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance();

			FormulaShare_Log__c log = new FormulaShare_Log__c();
			logsList = new List<FormulaShare_Log__c>();
			logsList.add(log);
			FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

			fsLogs.setContext('FormulaShareProcessBatch', null, batchContext);
			String typeInScope = typeInThisBatch.getDescribe().getName();
			String query = ql.getQuery();
			fsLogs.setBatchDetails(batchSize, typeInScope, rulesForType, query);	// need to fix this
			logsList = fsLogs.getFinalisedLogs();
			uow.registerNew(logsList);

			List<FormulaShare_Rule_in_Batch__c> ribList = new List<FormulaShare_Rule_in_Batch__c>();
			for(FormulaShareRule rule : rulesForType) {
				FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
				rib.FormulaShare_Rule_Name__c = rule.developerName;
				rib.Rule_Active_for_Batch_Run__c = rule.active;

				log = logsList[0];		// There will be only one log
				uow.registerNew(rib, FormulaShare_Rule_in_Batch__c.FormulaShare_Log__c, log);
			}

			// Create metrics for any rules which don't have them already
			List<FormulaShare_Metrics__c> metrics = createMetricsForNewRules();
			newMetricsForBatch = new Set<String>();		// Track which rules had this added
			for(FormulaShare_Metrics__c m : metrics) {
				newMetricsForBatch.add(m.FormulaShare_Rule_Name__c);
			}
			uow.registerNew(metrics);

			uow.commitWork();

			return ql;
		}

		else {
			return null;
		}
	}


   	public void execute(Database.BatchableContext context, List<SObject> scope) {
		
		FormulaShareService fsService = FormulaShareService.construct(typeInThisBatch, rulesForType);
		String insertStatus;
		String insertStatusReason;
		String deleteStatus;
		String deleteStatusReason;

		system.debug('*** batch scope : '+ scope);

		// Build id set, and re-query batch scope for fields and child objects (avoids issues with sub-selects in query locator)
		Set<Id> sharedObjIdSet = new Set<Id>();
        for(SObject obj : scope) {
            sharedObjIdSet.add((Id) obj.get('Id'));
        }
		List<SObject> records = FormulaShareService.getSObjectsWithFields(typeInThisBatch, rulesForType, sharedObjIdSet);

		// Populate records in batch scope into wrapper
		fsService.addToRecordsMap(records);

		// Assess sharing for this object
		fsService.processFormulaShares();
		Schema.SObjectType type = fsService.getType();

		// Insert and remove sharing if required
		if(!fsService.getSharesToInsert().isEmpty()) {
			FormulaShareSObjectShares fsSharesToInsert = FormulaShareSObjectShares.construct(fsService.getSharesToInsert(), type);

			try {
				fsSharesToInsert.insertShares();
				insertStatus = 'Success';
			}
			catch(Exception e) {
				insertStatus = 'Failed';
				insertStatusReason = e.getMessage();
			}
		}

		Savepoint sp = Database.setSavepoint();

		if(!fsService.getSharesToDelete().isEmpty()) {
			FormulaShareSObjectShares fsSharesToDelete = FormulaShareSObjectShares.construct(fsService.getSharesToDelete(), type);
			try {
				fsSharesToDelete.deleteShares();
				deleteStatus = 'Success';
			}

			// Revert to prior state if exceptions after deletion
			catch(Exception e) {
				Database.rollback(sp);
				deleteStatus = 'Failed';
				deleteStatusReason = e.getMessage();
			}
		}

		// Unit of work to update batch logs, and insert/update logs and metircs
		fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance();

		// Set batch logs
		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.incrementBatches();
		uow.registerDirty(fsLogs.getFinalisedLogs());

		// Build map of number of valid shares for all new metrics (we'll increment metrics for these)
		Map<String,Integer> noValidSharesForRules = fsService.getNoValidSharesForRules();
		Map<String,Integer> noValidSharesNewMetrics = new Map<String,Integer>();
		for(String ruleName : newMetricsForBatch) {
			Integer validShares = noValidSharesForRules.get(ruleName);
			noValidSharesNewMetrics.put(ruleName, validShares);
		}

		// Set record logs
		Map<String,FormulaShareService.ShareDetail> insertDetails = fsService.getInsertDetails();
		Map<String,FormulaShareService.ShareDetail> deleteDetails = fsService.getDeleteDetails();
		FormulaShareProcessEventPublisher publisher = new FormulaShareProcessEventPublisher();
		publisher.addInsertEvents(insertDetails, insertStatus, insertStatusReason);
		publisher.addDeleteEvents(deleteDetails, deleteStatus, deleteStatusReason);
		System.debug('No insert events: '+insertDetails.size());
		System.debug('No delete events: '+insertDetails.size());
		FormulaShare_Log__c log = logsList[0];
		uow = publisher.processForBatch(uow, log, noValidSharesNewMetrics);
        system.debug('Processing for batch. UOW3: '+uow);

		uow.commitWork();

	}
	

	public void finish(Database.BatchableContext context) {

		// Update batch log records
		fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance();
		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.setBatchProcessingComplete();
		uow.registerDirty(fsLogs.getFinalisedLogs());
		uow.commitWork();

		// Publish event to update FormulaShare Rules list in real time
		List<FormulaShare_List_Update__e> eventsList = new List<FormulaShare_List_Update__e>();
		FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
		updateEvent.Type__c = 'recalculation';
		updateEvent.Object_Label__c = typeInThisBatch.getDescribe().getLabel();
		eventsList.add(updateEvent);
		List<Database.SaveResult> results = EventBus.publish(eventsList);

		// If there are more types to process, submit another batch
		if(types.size() > 1) {
			types.remove(0);
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, batchSize), batchSize);
			system.debug('Submitted next batch, Id = ' + batchJobId);
		}
	}


	private List<FormulaShare_Metrics__c> createMetricsForNewRules() {

		// Make a set of rules which haven't had metrics records created already
		Set<String> ruleNames = new Set<String>();
		for(FormulaShareRule rule : rulesForType) {
			ruleNames.add(rule.developerName);
		}
		FormulaShareMetricsSelector fsmSelector = new FormulaShareMetricsSelector();
		List<FormulaShare_Metrics__c> existingMetrics = fsmSelector.getMetricsForRulesAndContext(ruleNames, batchContext);
		for(FormulaShare_Metrics__c m : existingMetrics) {
			ruleNames.remove(m.FormulaShare_Rule_Name__c);	// Take rules with metrics out of the set
		}

		// Get list of blank metrics records for all rules which don't yet have batch metrics
		List<FormulaShare_Metrics__c> allMetrics = FormulaShareMetrics.getBlankMetrics(ruleNames, batchContext);

		return allMetrics;
	}
	
}