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

	FormulaShareBatchService batchService;


	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public FormulaShareProcessBatch(List<Schema.SObjectType> types, Integer batchSize) {
		this.types = types;
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

			// Get query locator
			ql = FormulaShareService.getAllSharedObjectsLocator(typeInThisBatch);
			system.debug('query locator: ' + ql);

			// Save initial batch and RIB logs
			this.batchService = new FormulaShareBatchService(typeInThisBatch, rulesForType);
			this.batchService.createBatchAndRibLogs(ql, this.batchSize);
		}

		return ql;
	}


   	public void execute(Database.BatchableContext context, List<SObject> scope) {
		this.batchService.processSharingAndLogs(scope);
	}
	

	public void finish(Database.BatchableContext context) {

		this.batchService.finaliseLogsAndMetrics();

		// If there are more types to process, submit another batch
		if(types.size() > 1) {
			types.remove(0);
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, batchSize), batchSize);
			system.debug('Submitted next batch, Id = ' + batchJobId);
		}
	}

}