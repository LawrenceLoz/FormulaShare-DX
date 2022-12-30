public inherited sharing class FormulaShareBatchService {

	String executeContext;
    Schema.SObjectType typeInThisBatch;
    String targetedJobInScope;
    List<FormulaShareRule> rulesForType;

	List<FormulaShare_Log__c> logsList;

	Map<String,Integer> totalValidSharesForRule = new Map<String,Integer>();
	Map<String,Integer> totalErrorSharesForRule = new Map<String,Integer>();
    Boolean atLeastOneBatchFailed = false;
	Boolean atLeastOneMetricsUpdateFailed = false;

	// Constructor for full batch processing
    public FormulaShareBatchService(Schema.SObjectType typeInThisBatch, List<FormulaShareRule> rulesForType) {
		this.executeContext = FormulaShareProcessedShareEventService.batchContext;
        this.typeInThisBatch = typeInThisBatch;
        this.rulesForType = rulesForType;
    }

	// Constructor for targeted job processing
    public FormulaShareBatchService(Schema.SObjectType typeInThisBatch, List<FormulaShareRule> rulesForType, String targetedJobInScope) {
		this.executeContext = FormulaShareProcessedShareEventService.targetedJobContext;
        this.typeInThisBatch = typeInThisBatch;
        this.rulesForType = rulesForType;
        this.targetedJobInScope = targetedJobInScope;
    }


    // Call from start()
    public void createBatchAndRibLogs(Database.QueryLocator ql, Integer batchSize) {

        // Establish maps for finish metrics (set to zero here - will be updated if any records in batch execute)
        for(FormulaShareRule rule : rulesForType) {
            this.totalValidSharesForRule.put(rule.developerName, 0);
            this.totalErrorSharesForRule.put(rule.developerName, 0);
        }

        // Establish unit of work for batch log and rules in batch
        fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());

        // Create FormulaShareLogs wrapper from placeholder log for batch
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        this.logsList = new List<FormulaShare_Log__c>();
        this.logsList.add(log);
        FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

        // Set context in batch log
        String query = ql.getQuery();
        String typeInScope = this.typeInThisBatch.getDescribe().getName();
        fsLogs.setContext('FormulaShareProcessBatch', batchSize, typeInScope, rulesForType, query);
        this.logsList = fsLogs.setFinalisedLogs();
        uow.registerNew(logsList);

        // Create a rules in batch record for each rule
        List<FormulaShare_Rule_in_Batch__c> ribList = new List<FormulaShare_Rule_in_Batch__c>();
        for(FormulaShareRule rule : rulesForType) {
            FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
            rib.FormulaShare_Rule_Name__c = rule.developerName;
            rib.Rule_Active_for_Batch_Run__c = rule.active;

            log = this.logsList[0];		// There will be only one log
            uow.registerNew(rib, FormulaShare_Rule_in_Batch__c.FormulaShare_Log__c, log);
        }

        // Create metrics for the execute context for any rules which don't have them already
        List<FormulaShare_Metrics__c> metrics = createMetricsForNewRules();
        uow.registerNew(metrics);

        uow.commitWork();
    }


    // Call from execute()
    public void processSharingAndLogs(List<SObject> scope) {
		FormulaShareService fsService = FormulaShareService.construct(this.typeInThisBatch, rulesForType);
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
			this.atLeastOneBatchFailed = true;
			return;
		}

		processPreparedService(fsService, fsLogs);        
    }


	private void processPreparedService(FormulaShareService fsService, FormulaShareLogs fsLogs) {
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
			System.debug('No delete events: '+deleteDetails.size());
			FormulaShare_Log__c log = logsList[0];
			FormulaShareProcessedShareEventService.IncrementsWithUow incWithUow = publisher.processForTargetedJobOrBatch(uow, log, executeContext);
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


    // Finalse methods called from finish()
	FormulaShareLogs fsLogs;
	fflib_ISObjectUnitOfWork finalUow;
    public void finaliseLogs() {

		fsLogs = new FormulaShareLogs(this.logsList);
		fsLogs.trimFailedBatches();
		fsLogs.setBatchProcessingComplete();

		// Update batch log records
		finalUow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
		finalUow.registerDirty(fsLogs.setFinalisedLogs());
	}

	public void finaliseFullBatchMetrics() {

		// Indicate batch failure in metrics if any failed batches
		if(atLeastOneBatchFailed) {
			finalUow = FormulaShareProcessedShareEventService.processForBatchFail(finalUow, rulesForType);
		}

		// Set metrics in batch finish based on all valid sharing
		if(!atLeastOneMetricsUpdateFailed) {
			FormulaShare_Log__c log = this.logsList[0];
			finalUow = FormulaShareProcessedShareEventService.processForFullBatchFinish(finalUow, totalValidSharesForRule, totalErrorSharesForRule, log);
		}		
	}

//	public void finaliseTargetedJobMetrics() {
//
//		// Indicate batch failure in metrics if any failed batches
//		if(atLeastOneBatchFailed) {
//			finalUow = FormulaShareProcessedShareEventService.processForBatchFail(finalUow, rulesForType);
//		}
//
//		// Set metrics in batch finish based on sharing inserted in this batch
//		if(!atLeastOneMetricsUpdateFailed) {
//			FormulaShare_Log__c log = this.logsList[0];
//			finalUow = FormulaShareProcessedShareEventService.processForTargetedJobFinish(finalUow, totalInsertedSharesForRule, totalErrorSharesForRule, log);
//		}
//	}

	public void commitFinalUow() {

		Exception metricsException;
		try {
			finalUow.commitWork();
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
	}


	private void listViewUpdate() {
		try {
			String objectLabel = this.typeInThisBatch.getDescribe().getLabel();
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
		List<FormulaShare_Metrics__c> existingMetrics = fsmSelector.getMetricsForRulesAndContext(ruleNames, executeContext);
		for(FormulaShare_Metrics__c m : existingMetrics) {
			ruleNames.remove(m.FormulaShare_Rule_Name__c);	// Take rules with metrics out of the set
		}

		// Get list of blank metrics records for all rules which don't yet have batch metrics
		List<FormulaShare_Metrics__c> allMetrics = FormulaShareMetrics.getBlankMetrics(ruleNames, executeContext);

		return allMetrics;
	}

}
