@IsTest
public with sharing class FormulaShareTestDataFactory {

    static String batchContext = FormulaShareProcessedShareEventService.batchContext;
    static String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
    static String batchFinishContext = FormulaShareProcessedShareEventService.batchFinishContext;

    static String userRuleName = FormulaShareMockProvider.userRuleName;
    static String groupRuleName = FormulaShareMockProvider.groupRuleName;
    static String roleSubName = FormulaShareMockProvider.roleSubName;
    static String roleRuleName = FormulaShareMockProvider.roleRuleName;
    static String childUserRuleName = FormulaShareMockProvider.childUserRuleName;

    public static FormulaShare_Log__c getBatchLog() {
        return getBatchLogs(1)[0];
    }

    public static List<FormulaShare_Log__c> getBatchLogs(Integer size) {
        List<FormulaShare_Log__c> logs = new List<FormulaShare_Log__c>();

        for(Integer i = 0; i < size; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Class_Name__c = 'FormulaShareProcessBatch';
            log.Type_In_Scope__c = 'FormulaShare_Log__c';
            log.Query__c = 'SELECT Id FROM FormulaShare_Log__c ORDER BY Name ASC NULLS FIRST';
            log.Batches_Processed__c = 10;
            log.Processing_Started__c = DateTime.now() - 10;
            log.Processing_Finished__c = DateTime.now();
            logs.add(log);
        }

        return logs;
    }

    public static FormulaShare_Metrics__c getBatchFinishMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = batchFinishContext;
        metrics.Successful_Inserts__c = 101;
        metrics.Failed_Inserts__c = 1;
        metrics.Last_Successful_Batch__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }

    public static FormulaShare_Metrics__c getBatchFinishMetricsForRuleAndBatchFail(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = getBatchFinishMetricsForRuleAndBatch(ruleName, batchLogId);
        metrics.Last_Successful_Batch__c = null;
        metrics.Last_Failed_Batch__c = DateTime.now();
        return metrics;
    }

    public static FormulaShare_Metrics__c getTriggerMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = triggerContext;
        metrics.Successful_Inserts__c = 102;
        metrics.Failed_Inserts__c = 2;
        metrics.Last_Successful_Operation__c = DateTime.now();
        metrics.Last_Failed_Operation__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }

    public static FormulaShare_Metrics__c getBatchMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = batchContext;
        metrics.Successful_Inserts__c = 103;
        metrics.Failed_Inserts__c = 3;
        metrics.Last_Successful_Operation__c = DateTime.now();
        metrics.Last_Failed_Operation__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }
    

}