/**
*Copyright 2020 Lawrence Newcombe
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

public inherited sharing class FormulaShareMetrics extends fflib_SObjectDomain {

    // Values to augment onto metrics
    public inherited sharing class Increment {
        public Integer noSuccessfulInserts = 0;
        public Integer noFailedInserts = 0;
        public DateTime LastSuccessfulOperation;
        public DateTime lastFailedOperation;
        public DateTime LastSuccessfulBatch;
        public DateTime lastFailedBatch;
        public DateTime processingFinished;
    }

    public FormulaShareMetrics(List<FormulaShare_Metrics__c> sObjectList) {
        super(sObjectList);
    }

    public inherited sharing class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new FormulaShareMetrics(sObjectList);
        }
    }

    public void setBlankMetrics(Set<String> ruleNames, String context) {
        List<FormulaShare_Metrics__c> metricsList = getBlankMetrics(ruleNames, context);
        Records.addAll(metricsList);
    }

    // Create new metrics for a set of rules
    public static List<FormulaShare_Metrics__c> getBlankMetrics(Set<String> ruleNames, String context) {
        List<FormulaShare_Metrics__c> metricsList = new List<FormulaShare_Metrics__c>();
        for(String ruleName : ruleNames) {
            FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
            metrics.FormulaShare_Rule_Name__c = ruleName;
            metrics.Context__c = context;
            metrics.Failed_Inserts__c = 0;
            metrics.Successful_Inserts__c = 0;
            metricsList.add(metrics);
        }
        return metricsList;
    }

    // Adds incremented values to metrics
    public fflib_ISObjectUnitOfWork augmentMetrics(fflib_ISObjectUnitOfWork uow, Map<String,Increment> incrementsMap) {
        for(FormulaShare_Metrics__c metrics : (List<FormulaShare_Metrics__c>) Records) {

            // Continue if there's an increment for the rule
            if(incrementsMap.containsKey(metrics.FormulaShare_Rule_Name__c)) {

                // Increment the metrics and set date/times
                Increment inc = incrementsMap.get(metrics.FormulaShare_Rule_Name__c);
                metrics.Successful_Inserts__c += inc.noSuccessfulInserts;
                metrics.Failed_Inserts__c += inc.noFailedInserts;

                uow = updateDatesAndRegister(uow, metrics, inc);
            }
        }
        return uow;
    }

    // Updates metrics records with incremented values
    public fflib_ISObjectUnitOfWork overwriteMetrics(fflib_ISObjectUnitOfWork uow, Map<String,Increment> incrementsMap, FormulaShare_Log__c batchLog) {

        System.debug('Records: '+ Records);
        for(FormulaShare_Metrics__c metrics : (List<FormulaShare_Metrics__c>) Records) {

            // Continue if there's an increment for the rule
            if(incrementsMap.containsKey(metrics.FormulaShare_Rule_Name__c)) {

                // Increment the metrics and set date/times
                Increment inc = incrementsMap.get(metrics.FormulaShare_Rule_Name__c);
                system.debug('rule name: '+ metrics.FormulaShare_Rule_Name__c);
                system.debug('inc.noSuccessfulInserts: '+ inc.noSuccessfulInserts);
                
                metrics.Successful_Inserts__c = inc.noSuccessfulInserts;
                metrics.Failed_Inserts__c = inc.noFailedInserts;

                system.debug('batchLog: '+ batchLog);
                uow.registerRelationship(metrics, FormulaShare_Metrics__c.Last_Batch_Run__c, batchLog);
                
                uow = updateDatesAndRegister(uow, metrics, inc);
            }
        }
        return uow;
    }

    private fflib_ISObjectUnitOfWork updateDatesAndRegister(fflib_ISObjectUnitOfWork uow, FormulaShare_Metrics__c metrics, Increment inc) {
        metrics.Last_Successful_Operation__c = inc.LastSuccessfulOperation;
        metrics.Last_Failed_Operation__c = inc.lastFailedOperation;
        metrics.Last_Successful_Batch__c = inc.LastSuccessfulBatch;
        metrics.Last_Failed_Batch__c = inc.lastFailedBatch;

        // Override Processing Finished if explicitly provided
        if(inc.processingFinished != null) {
            metrics.Processing_Finished__c = inc.processingFinished;
        }

        if(metrics.Id == null) {
            uow.registerNew(metrics);
        }
        else {
            uow.registerDirty(metrics);
        }
        return uow;
    }


}