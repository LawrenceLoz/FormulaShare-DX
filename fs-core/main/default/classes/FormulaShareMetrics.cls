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

public with sharing class FormulaShareMetrics extends fflib_SObjectDomain {

    // Values to augment onto metrics
    public class Increment {
        public Integer noFailedInserts = 0;
        public DateTime lastFailedOperation;
        public DateTime LastSuccessfulOperation;
        public Integer noSuccessfulInserts = 0;
    }

    public FormulaShareMetrics(List<FormulaShare_Metrics__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
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

    // Updates metrics records with incremented values
    public fflib_ISObjectUnitOfWork augmentMetrics(fflib_ISObjectUnitOfWork uow, Map<String,Increment> incrementsMap) {
        for(FormulaShare_Metrics__c metrics : (List<FormulaShare_Metrics__c>) Records) {

            // Continue if there's an increment for the rule
            if(incrementsMap.containsKey(metrics.FormulaShare_Rule_Name__c)) {

                // Increment the metrics and set date/times
                Increment inc = incrementsMap.get(metrics.FormulaShare_Rule_Name__c);
                system.debug('rule name: '+ metrics.FormulaShare_Rule_Name__c);
                system.debug('inc.noFailedInserts: '+ inc.noFailedInserts);
                system.debug('metrics.Failed_Inserts__c '+ metrics.Failed_Inserts__c);
                
                metrics.Failed_Inserts__c += inc.noFailedInserts;
                metrics.Last_Failed_Operation__c = inc.lastFailedOperation;
                metrics.Last_Successful_Operation__c = inc.LastSuccessfulOperation;
                metrics.Successful_Inserts__c += inc.noSuccessfulInserts;
                if(metrics.Id == null) {
                    uow.registerNew(metrics);
                }
                else {
                    uow.registerDirty(metrics);
                }
            }
        }
        return uow;
    }

}