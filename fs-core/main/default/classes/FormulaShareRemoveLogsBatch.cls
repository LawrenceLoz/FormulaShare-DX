public inherited sharing class FormulaShareRemoveLogsBatch implements Database.Batchable<sObject>, Database.Stateful {

    // Start queries for all record logs earlier than the number of days retained
	public Database.QueryLocator start(Database.BatchableContext context) {
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        Integer retentionDays = settings.Days_to_Retain_Record_Logs__c.intValue();
        DateTime newestLogTime = DateTime.now() - retentionDays;
        Database.QueryLocator ql = new FormulaShareRecordLogsSelector().selectLogsOlderThanDate(newestLogTime);
        return ql;
    }

    // Execute method deletes all record logs in scope
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<FormulaShare_Record_Log__c> logs = (List<FormulaShare_Record_Log__c>) scope;
        Schema.SObjectType logsType = FormulaShare_Record_Log__c.sObjectType;
        if(logsType.getDescribe().isAccessible() && logsType.getDescribe().isDeletable()) {
            delete logs;
        }
    }

    // On completion, run job to delete batch logs
    public void finish(Database.BatchableContext context) {
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        Integer batchSize = settings.Logs_Removal_Batch_Size__c.intValue();
        Id batchJobId = Database.executeBatch(new FormulaShareRemoveBatchLogsBatch(), batchSize);
    }

}