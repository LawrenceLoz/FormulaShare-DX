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

public class ProcessFormulaShareBatch implements Database.Batchable<sObject> {
	
	List<Schema.SObjectType> types;
	Integer batchSize;
	Schema.SObjectType typeInThisBatch;
	List<FormulaShareService.FSRule> rulesForType;

	// Accepts a list of types. Chained batches will be submitted if more than one type is provided
	public ProcessFormulaShareBatch(List<Schema.SObjectType> types, Integer batchSize) {
		this.types = types;
		this.batchSize = batchSize;
		this.typeInThisBatch = types[0];
		this.rulesForType = FormulaShareService.getRulesSharingObject(typeInThisBatch);
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		system.debug('FormulaShare batch job started. Type in scope: '+typeInThisBatch);
		system.debug('Rules for this object: '+rulesForType);
//		String query = FormulaShareService.getFullObjectQuery(typeInThisBatch, rulesForType);
//		return Database.getQueryLocator(query);

		return FormulaShareService.getFullObjectQueryLocator(typeInThisBatch, rulesForType);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		FormulaShareService.FormulaShareWrapper fsWrapper = new FormulaShareService.FormulaShareWrapper(typeInThisBatch, rulesForType);
		
		// Populate records in batch scope into wrapper
		for(SObject obj : scope) {
			fsWrapper.recordsMap.put(obj.Id, obj);
		}
		system.debug('scope: '+scope);

		FormulaShareService.processFormulaShares(fsWrapper);
	}
	
	public void finish(Database.BatchableContext BC) {
		
		// If there are more types to process, submit another batch
		if(types.size() > 1) {
			types.remove(0);
			Id batchJobId = Database.executeBatch(new ProcessFormulaShareBatch(types, batchSize), batchSize);
			system.debug('Submitted next batch, Id = ' + batchJobId);
		}

	}
	
}