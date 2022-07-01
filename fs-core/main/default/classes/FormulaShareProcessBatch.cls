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

public class FormulaShareProcessBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents {
	
	List<Schema.SObjectType> types;
	Integer batchSize;
	Schema.SObjectType typeInThisBatch;
	List<FormulaShareRule> rulesForType;
	List<FormulaShare_Log__c> logsList = new List<FormulaShare_Log__c>();

//	Set<String> newMetricsForBatch;
	Map<String,Integer> totalValidSharesForRule = new Map<String,Integer>();
	Map<String,Integer> totalErrorSharesForRule = new Map<String,Integer>();


	public static final String batchContext = FormulaShareProcessedShareEventService.batchContext;
	Boolean atLeastOneBatchFailed = false;
	Boolean atLeastOneMetricsUpdateFailed = false;

	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public FormulaShareProcessBatch(List<Schema.SObjectType> types, Integer batchSize) {
		this.types = types;
		this.batchSize = batchSize;
		this.typeInThisBatch = types[0];
		FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();
		this.rulesForType = rulesSelector.getRulesSharingObject(typeInThisBatch);
	}
	

	public Database.QueryLocator start(Database.BatchableContext context) {
		system.debug('FormulaShare batch job started. Type in scope: '+typeInThisBatch);
		system.debug('Rules for this object: '+rulesForType);
		
		if(!rulesForType.isEmpty()) {

			Database.QueryLocator ql = FormulaShareService.getAllSharedObjectsLocator(typeInThisBatch);
			system.debug('query locator: ' + ql);

			// Establish unit of work for batch log and rules in batch
			fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());

			FormulaShare_Log__c log = new FormulaShare_Log__c();
			logsList = new List<FormulaShare_Log__c>();
			logsList.add(log);
			FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

			String typeInScope = typeInThisBatch.getDescribe().getName();
			String query = ql.getQuery();
			fsLogs.setContext('FormulaShareProcessBatch', batchSize, typeInScope, rulesForType, query);
			logsList = fsLogs.setFinalisedLogs();
			uow.registerNew(logsList);

			List<FormulaShare_Rule_in_Batch__c> ribList = new List<FormulaShare_Rule_in_Batch__c>();
			for(FormulaShareRule rule : rulesForType) {
				FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
				rib.FormulaShare_Rule_Name__c = rule.developerName;
				rib.Rule_Active_for_Batch_Run__c = rule.active;

				log = logsList[0];		// There will be only one log
				uow.registerNew(rib, FormulaShare_Rule_in_Batch__c.FormulaShare_Log__c, log);

				// Establish maps for finish metrics (set to zero here - will be updated if any records in batch execute)
				totalValidSharesForRule.put(rule.developerName, 0);
				totalErrorSharesForRule.put(rule.developerName, 0);
			}

			// Create metrics for any rules which don't have them already
			List<FormulaShare_Metrics__c> metrics = createMetricsForNewRules();
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
		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.incrementBatches();

		system.debug('*** batch scope : '+ scope);

		// Get set of records which we'll need for sharing assessment and populate into service class
		try {
			FormulaShareSObjectsRetrievalServiceBase rs = new FormulaShareInjectionService().getSObjectsRetrievalService();
			rs.setRequery();	// Batch selector only selects ids, so requery for relevant fields
			rs.setDetails(typeInThisBatch, rulesForType, scope);
			List<FormulaShareRetrievedRecordDetails> recordDetails = rs.getDetailsForSharing();

			// Populate records in batch scope into wrapper
			fsService.setSharedRecordDetails(recordDetails);
		}

		// Fail batch if exceptions identifying or populating records
		catch(Exception e) {
			e.setMessage('Issue populating batch scope. Message from Salesforce: ' + e.getMessage());
			fsLogs.logException(e);
			atLeastOneBatchFailed = true;
			return;
		}

		processSharingAssessmentAndLogs(fsService, fsLogs);
	}

	private void processSharingAssessmentAndLogs(FormulaShareService fsService, FormulaShareLogs fsLogs) {
		String insertStatus;
		String insertStatusReason;
		String deleteStatus;
		String deleteStatusReason;
		Map<String,Integer> failedInsertsMap = new Map<String,Integer>();

		// Assess sharing for this object
		try {
			fsService.processFormulaShares();
		}

		// Fail this batch if any exceptions assessing sharing
		catch(Exception e) {
			e.setMessage('FormulaShareService processing error. Message from Salesforce: ' + e.getMessage());
			fsLogs.logException(e);
			atLeastOneBatchFailed = true;
			return;
		}
		
		// Get insert details and extract list of shares
		Map<String,FormulaShareService.ShareDetail> insertDetails = fsService.getInsertDetails();
		List<SObject> sharesToInsert = new List<SObject>();
		for(FormulaShareService.ShareDetail sd : insertDetails.values()) {
			sharesToInsert.add(sd.shareRecord);
		}

		// Insert if required
		if(!sharesToInsert.isEmpty()) {
			FormulaShareSObjectShares fsSharesToInsert = FormulaShareSObjectShares.construct(sharesToInsert, typeInThisBatch);

			try {
				fsSharesToInsert.insertShares();
				insertStatus = 'Success';
			}
			catch(Exception e) {
				insertStatus = 'Error';
				insertStatusReason = e.getMessage();

				// Populate map of number of failed inserts by rule for finish metrics
				for(FormulaShareService.ShareDetail sd : insertDetails.values()) {
					Integer noFails = 0;
					if(failedInsertsMap.containsKey(sd.rule.developerName)) {
						noFails = failedInsertsMap.get(sd.rule.developerName);						
					}
					noFails++;
					failedInsertsMap.put(sd.rule.developerName, noFails);
				}
			}
		}

		Savepoint sp = Database.setSavepoint();

		// Get delete details and extract list of shares
		Map<String,FormulaShareService.ShareDetail> deleteDetails = fsService.getDeleteDetails();
		List<SObject> sharesToDelete = new List<SObject>();
		for(FormulaShareService.ShareDetail sd : deleteDetails.values()) {
			sharesToDelete.add(sd.shareRecord);
		}

		// Delete if required
		if(!sharesToDelete.isEmpty()) {
			FormulaShareSObjectShares fsSharesToDelete = FormulaShareSObjectShares.construct(sharesToDelete, typeInThisBatch);
			try {
				fsSharesToDelete.deleteShares();
				deleteStatus = 'Success';
			}

			// Revert to prior state if exceptions after deletion
			catch(Exception e) {
				Database.rollback(sp);
				deleteStatus = 'Error';
				deleteStatusReason = e.getMessage();
			}
		}

		try {
			// Unit of work to update batch logs, and insert/update logs and metrics
			fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());

			// Set batch logs
			uow.registerDirty(fsLogs.setFinalisedLogs());

			// Set record logs
			List<FormulaShareService.EntityNotFound> entitiesNotFound = fsService.getEntitiesNotFound();
			FormulaShareProcessEventPublisher publisher = new FormulaShareProcessEventPublisher();
			publisher.addInsertEvents(insertDetails, insertStatus, insertStatusReason);
			publisher.addDeleteEvents(deleteDetails, deleteStatus, deleteStatusReason);
			publisher.addEventsForEntitiesNotFound(entitiesNotFound);

			System.debug('No insert events: '+insertDetails.size());
			System.debug('No delete events: '+insertDetails.size());
			FormulaShare_Log__c log = logsList[0];
			FormulaShareProcessedShareEventService.IncrementsWithUow incWithUow = publisher.processForBatch(uow, log);
			uow = incWithUow.uow;
			system.debug('Processing for batch. UOW3: '+uow);

			// Get rule in batch records to be updated
			List<String> ruleNames = new List<String>();
			for(FormulaShareRule rule : rulesForType) {
				ruleNames.add(rule.developerName);
			}
			List<FormulaShare_Rule_in_Batch__c> ribList = new FormulaShareRuleInBatchSelector(true).getLogsForRules(ruleNames);
			Map<String,FormulaShare_Rule_in_Batch__c> ribMap = new Map<String,FormulaShare_Rule_in_Batch__c>();
			for(FormulaShare_Rule_in_Batch__c rib : ribList) {
				ribMap.put(rib.FormulaShare_Rule_Name__c, rib);
			}

			// Increment no. records shared (reduced by insert failures) and failures
			// This contributes to batch finish metrics
			Map<String,Integer> noValidSharesForRulesBatch = fsService.getNoValidSharesForRules();
			for(FormulaShareRule rule : rulesForType) {
				String ruleName = rule.developerName;
				Integer validShares = 0;
				Integer insertedShares = 0;
				Integer errorShares = 0;
				FormulaShare_Rule_in_Batch__c rib = ribMap.get(rule.developerName);

				if(rib != null) {
					if(rib.Total_Records_Shared_by_Rule__c != null) {
						validShares = (Integer) rib.Total_Records_Shared_by_Rule__c;
					}
					if(rib.Records_Shared_in_This_Batch__c != null) {
						insertedShares = (Integer) rib.Records_Shared_in_This_Batch__c;
					}
					if(rib.Record_Errors_in_This_Batch__c != null) {
						errorShares = (Integer) rib.Record_Errors_in_This_Batch__c;
					}
				}

				if(incWithUow.incrementsMap.containsKey(ruleName)) {
					FormulaShareMetrics.Increment metrics = incWithUow.incrementsMap.get(ruleName);
					errorShares += metrics.noFailedInserts;
					insertedShares += metrics.noSuccessfulInserts;
				}

				// Set inserted and error totals
				totalErrorSharesForRule.put(ruleName, errorShares);
				rib.Record_Errors_in_This_Batch__c = errorShares;
				rib.Records_Shared_in_This_Batch__c = insertedShares;

				// Add number of valid shares in batch, and subtract any inserts which failed
				// This should be the only type of failure not already excluded
				validShares += noValidSharesForRulesBatch.get(ruleName);
				if(insertStatus == 'Error' && failedInsertsMap.containsKey(ruleName)) {
					validShares -= failedInsertsMap.get(ruleName);
				}

				totalValidSharesForRule.put(ruleName, validShares);
				rib.Total_Records_Shared_by_Rule__c = validShares;

				uow.registerDirty(rib);

				System.debug('totalValidSharesForRule for execution: '+ totalValidSharesForRule);
			}

			uow.commitWork();
		}

		catch(Exception e) {
			updateLogAfterMetricsFail(fsLogs, e);
			atLeastOneMetricsUpdateFailed = true;
		}

		listViewUpdate();
	}
	

	public void finish(Database.BatchableContext context) {
		System.debug('totalValidSharesForRule for finish: '+ totalValidSharesForRule);

		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);
		fsLogs.trimFailedBatches();
		fsLogs.setBatchProcessingComplete();

		Exception metricsException;
		try {
			// Update batch log records
			fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
			uow.registerDirty(fsLogs.setFinalisedLogs());

			// Indicate batch failure in metrics if any failed batches
			if(atLeastOneBatchFailed) {
				uow = FormulaShareProcessedShareEventService.processForBatchFail(uow, rulesForType);
			}

			// Update total shares in batch finish metrics provided no metric capture issues
			if(!atLeastOneMetricsUpdateFailed) {
				FormulaShare_Log__c log = logsList[0];
				uow = FormulaShareProcessedShareEventService.processForBatchFinish(uow, totalValidSharesForRule, totalErrorSharesForRule, log);
			}
			
			uow.commitWork();
			listViewUpdate();
		}

		// If any exceptions updating logs, ensure batch is closed
		catch(Exception e) {
			metricsException = e;

			try {
				fsLogs.setFinalisedLogs();
				updateLogAfterMetricsFail(fsLogs, metricsException);
			}
			catch(Exception exp) {
				System.debug('Error updating batch log after metrics error: '+exp.getMessage());
			}
		}

		finally {
			// If there are more types to process, submit another batch
			if(types.size() > 1) {
				types.remove(0);
				Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, batchSize), batchSize);
				system.debug('Submitted next batch, Id = ' + batchJobId);
			}
		}

	}


	private void listViewUpdate() {
		try {
			String objectLabel = typeInThisBatch.getDescribe().getLabel();
			List<String> objectLabelsList = new List<String>{objectLabel};
			FormulaShareProcessedShareEventService.fireRulesListUpdateEvent(objectLabelsList);
		}
		catch(Exception e) {
			System.debug('Error firing event to update list view. Message from Salesforce: '+e.getMessage());
		}
	}



	private void updateLogAfterMetricsFail(FormulaShareLogs fsLogs, Exception metricsException) {
		metricsException.setMessage('Issue capturing logs or metrics. Message from Salesforce: ' + metricsException.getMessage());
		fsLogs.logException(metricsException);
		
		fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
		uow.registerDirty(fsLogs.Records);
		uow.commitWork();
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