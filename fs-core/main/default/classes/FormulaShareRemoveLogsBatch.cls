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