public virtual inherited sharing class FormulaShareBatchService {

	protected String executeContext;
    protected Schema.SObjectType typeInThisBatch;
    protected Schema.SObjectType shareTypeInThisBatch;
	protected String contextDetail;
    protected String targetedJobInScope;
    protected List<FormulaShareRule> rulesForType;

	List<FormulaShare_Log__c> logsList;

	Map<String,Integer> totalValidSharesForRule = new Map<String,Integer>();
	Map<String,Integer> totalErrorSharesForRule = new Map<String,Integer>();
    Boolean atLeastOneBatchFailed = false;
	Boolean atLeastOneMetricsUpdateFailed = false;

	// Track total record sharing processed by this job - incrememented with each batch
	@TestVisible protected Integer noRecordsSharingAppliedFirstTime = 0;
	@TestVisible protected Integer noRecordsAllSharingRemoved = 0;
	@TestVisible protected Integer noRecordsSharingUpdated = 0;
	@TestVisible protected Integer noRecordsSharingStillInPlace = 0;
	protected Integer noRecordsNotShared = 0;


	// Constructor for full batch processing
    public FormulaShareBatchService(Schema.SObjectType typeInThisBatch, String contextDetail, List<FormulaShareRule> rulesForType) {
		this.executeContext = FormulaShareProcessedShareEventService.batchContext;
		this.contextDetail = contextDetail;
        this.typeInThisBatch = typeInThisBatch;
		this.shareTypeInThisBatch = FormulaShareUtilities.getShareObject(typeInThisBatch);
        this.rulesForType = rulesForType;
    }

	// Zero arg constructor needed to allow inheritence - not actually used
	protected FormulaShareBatchService() {}

	// Full batch processing allowed by default, but can be overridden
	public virtual Boolean processingAllowed() {
		return true;
	}


    // Call from start()
    public void createBatchAndRibLogs(String query, Integer batchSize) {

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
		// Note that 'n/a' indicates a query wasn't run and a batch start error was encountered (logBatchStartError will be run)
		if(query != 'n/a') {
			setProcessingStartedAndCreateMetricsForNewRules(uow);
		}

        uow.commitWork();
    }

	public inherited sharing class FormulaShareBatchException extends Exception {}

    // If we detected an error during batch start, no records to process so just log and process this error
	public void logBatchStartError(String batchStartError) {
		FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

		// Throw an exception to be logged in FormulaShare batch log
		try {
			throw new FormulaShareBatchException(batchStartError);
		}
		catch(FormulaShareBatchException e) {
			fsLogs.logException(e);
		}

		this.atLeastOneBatchFailed = true;
	}


	// Called from execute
    public virtual void processSharingAndLogs(List<SObject> scope) {
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
			fsLogs.incrementFailedBatches();
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
			fsLogs.incrementFailedBatches();
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
			FormulaShareSObjectShares fsSharesToInsert = FormulaShareSObjectShares.construct(shareTypeInThisBatch);

			try {
				fsSharesToInsert.insertShares(sharesToInsert);
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
			FormulaShareSObjectShares fsSharesToDelete = FormulaShareSObjectShares.construct(shareTypeInThisBatch);
			try {
				fsSharesToDelete.deleteShares(sharesToDelete);
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
			FormulaShareProcessEventPublisher publisher = new FormulaShareProcessEventPublisher(contextDetail, 'Full Assessment');
			publisher.addInsertEvents(insertDetails, insertStatus, insertStatusReason);
			publisher.addDeleteEvents(deleteDetails, deleteStatus, deleteStatusReason);
			publisher.addEventsForEntitiesNotFound(entitiesNotFound);

			System.debug('No insert events: '+insertDetails.size());
			System.debug('No delete events: '+deleteDetails.size());
			FormulaShare_Log__c log = logsList[0];

			FormulaShareProcessedShareEventService.IncrementsWithUow incWithUow = publisher.processForTargetedJobOrBatch(uow, log, executeContext);
			uow = incWithUow.uow;
			
			// We pass number of processed records w/ sharing in place so this can be used in creating usage by object
			this.noRecordsSharingAppliedFirstTime += incWithUow.noRecordsSharingAppliedFirstTime;
			this.noRecordsAllSharingRemoved 	  += incWithUow.noRecordsAllSharingRemoved;
			this.noRecordsSharingUpdated 		  += incWithUow.noRecordsSharingUpdated;
			this.noRecordsSharingStillInPlace 	  += fsService.getNoRecordsSharingStillInPlace();
			this.noRecordsNotShared 			  += fsService.getNoRecordsNotShared();

			// Incremement batch records with numbers of records processed
			log.Records_w_Sharing_Applied_for_1st_Time__c = noRecordsSharingAppliedFirstTime;
			log.Records_w_All_Sharing_Removed__c 		  = noRecordsAllSharingRemoved;
			log.Records_w_Sharing_Updated__c 			  = noRecordsSharingUpdated;
			log.Records_w_Sharing_Still_In_Place__c 	  = noRecordsSharingStillInPlace;
			log.Records_Not_Shared_by_FormulaShare__c 	  = noRecordsNotShared;
			
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

	// Override to add additional processing in finish method
	public virtual void additionalBatchFinishProcessing(String batchStartErorr) {}


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
		fsLogs.incrementFailedBatches();
		
		fflib_ISObjectUnitOfWork uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
		uow.registerDirty(fsLogs.Records);
		uow.commitWork();
	}


	private void setProcessingStartedAndCreateMetricsForNewRules(fflib_ISObjectUnitOfWork uow) {
		Datetime timeNow = Datetime.now();

		// Make a set of rules which haven't had metrics records created already
		Set<String> ruleNames = new Set<String>();
		for(FormulaShareRule rule : rulesForType) {
			ruleNames.add(rule.developerName);
		}
		FormulaShareMetricsSelector fsmSelector = new FormulaShareMetricsSelector();
		List<FormulaShare_Metrics__c> existingMetrics = fsmSelector.getMetricsForRulesAndContext(ruleNames, executeContext);
		for(FormulaShare_Metrics__c m : existingMetrics) {
			m.Processing_Started__c = timeNow;
			m.Processing_Finished__c = null;	// Clear previous finish time
			ruleNames.remove(m.FormulaShare_Rule_Name__c);	// Take rules with metrics out of the set
		}
		uow.registerDirty(existingMetrics);

		// Get list of blank metrics records for all rules which don't yet have batch metrics
		List<FormulaShare_Metrics__c> newMetrics = FormulaShareMetrics.getBlankMetrics(ruleNames, executeContext);
		for(FormulaShare_Metrics__c metrics : newMetrics) {
			metrics.Processing_Started__c = timeNow;
		}
        uow.registerNew(newMetrics);
	}

}
