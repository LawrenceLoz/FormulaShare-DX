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
	String batchStartError;
	String contextDetail;

	FormulaShareBatchService batchService;


	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public FormulaShareProcessBatch(List<Schema.SObjectType> types, String contextDetail, Integer batchSize) {
		this.types = types;
		this.contextDetail = contextDetail;
		this.batchSize = batchSize;
		this.typeInThisBatch = types[0];
	}

	public Database.QueryLocator start(Database.BatchableContext context) {
		system.debug('FormulaShare batch job started. Type in scope: '+this.typeInThisBatch);

		FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();
		List<FormulaShareRule> rulesForType = rulesSelector.getRulesSharingObject(this.typeInThisBatch);
		system.debug('Rules for this object: '+rulesForType);
		
		Database.QueryLocator ql;

		if(!rulesForType.isEmpty()) {
			
			this.batchService = new FormulaShareInjectionService().getBatchService(typeInThisBatch, contextDetail, rulesForType);
			
			// Continue only if object settings allow processing for full batch
			if(batchService.processingAllowed() || contextDetail == 'Manually Initiated Batch') {
				
				// Get query locator
				ql = FormulaShareService.getAllSharedObjectsLocator(typeInThisBatch);
				system.debug('query locator: ' + ql);
	
				// Save initial batch and RIB logs
				this.batchService.createBatchAndRibLogs(ql.getQuery(), this.batchSize);
			}

			// If processing isn't allowed, process the batch but log this as an error in FormulaShare batch logs
			// Avoids Salesforce "Start did not return a valid iterable object" batch fail message
			else {
				this.batchStartError = 
					'Sharing Calculation Schedule does not allow Full Recalculation on Batch, so no records '
					+ 'processed in this batch. Update configuration in Object Settings to allow this if required';
			}
		}

		else {
			this.batchStartError = 'No rules in place which share this object, so batch will be skipped';
		}

		// If an error was detected, return a query locator which will return no records
		// and log the batch start error as an exception (batch log will have status "Skipped")
		if(this.batchStartError != null) {
			FormulaShareSObjectsSelector selector = new FormulaShareInjectionService().getSObjectsSelector(true, typeInThisBatch);
			ql = selector.selectNoneLocator();

			this.batchService.createBatchAndRibLogs('n/a', this.batchSize);
			this.batchService.logBatchStartError(this.batchStartError);

			// Update list to clear "Processing..." label
			EventBus.publish(new FormulaShare_List_Update__e());
		}

		return ql;
	}


   	public void execute(Database.BatchableContext context, List<SObject> scope) {
		this.batchService.processSharingAndLogs(scope);
	}
	

	public void finish(Database.BatchableContext context) {

        this.batchService.finaliseLogs();

		// Update metrics only if there wasn't an error in the start method (retains shared totals if batch didn't run)
		if(batchStartError == null) {
			this.batchService.finaliseFullBatchMetrics();
		}
		this.batchService.additionalBatchFinishProcessing(this.batchStartError);
        this.batchService.commitFinalUow();

		// If there are more types to process, submit another batch
		if(types.size() > 1) {
			types.remove(0);
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, contextDetail, batchSize), batchSize);
			system.debug('Submitted next batch, Id = ' + batchJobId);
		}
	}

}