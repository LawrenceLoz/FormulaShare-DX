@IsTest
public with sharing class FormulaSharePSEventTriggerTest {

    @IsTest
    public static void testLogAfterSuccessfulInsert() {

        // Simulate a batch being scheduled
        FormulaShareAsyncApexJobSelector.isScheduled = true;

        // Simulate share being inserted by rule
        FormulaShare_Log__c log = FormulaShareTestDataFactory.getBatchLog();
        insert log;
        Id userId = UserInfo.getUserId();
        FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(log.Id, userId, 'Read');
        insert share;

        FormulaShare_Processed_Share_Event__e pse = new FormulaShare_Processed_Share_Event__e();

        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        DateTime insertedTime = System.now();
        String recordIdString = String.valueOf(log.Id);
        String sharedToUserString = String.valueOf(userId);

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(FormulaShare_Log__c.SObjectType);
        String shareKey = objectUtils.getShareKey(share);

        pse.Access_Level__c = 'Read';
        pse.FormulaShare_Rule_Name__c = 'Test_rule';
        pse.Object__c = prefix + 'FormulaShare_Log__c';
        pse.Operation__c = 'Insert';
        pse.Processed_Date_Time__c = insertedTime;
        pse.Record_Id__c = recordIdString;
        pse.Shared_to_Id__c = sharedToUserString;
        pse.Share_Id__c = String.valueOf(share.Id);
        pse.Share_Key__c = shareKey;
        pse.Share_With__c = 'Users';
        pse.Sharing_Reason__c = prefix + 'FormulaShare_Log_Share__c';

        Test.startTest();
        EventBus.publish(pse);
        Test.stopTest();

        // Query for record log and check created as expected
        List<FormulaShare_Record_Log__c> recordLog = [SELECT Id, Processed_Date_Time__c, Record_Id__c FROM FormulaShare_Record_Log__c];
        System.assertEquals(1, recordLog.size(), 'Expected a single record log to be inserted');
        System.assertEquals(insertedTime, recordLog[0].Processed_Date_Time__c, 'Time not populated as expected');
        System.assertEquals(recordIdString, recordLog[0].Record_Id__c, 'Record id not populated as expected');

        // Query for record share log and check created as expected
        List<FormulaShare_Processed_Record_Share__c> prsList = [SELECT Id, Processed_Record__c, Status__c, Share_With__c, Shared_to_User__c FROM FormulaShare_Processed_Record_Share__c];
        System.assertEquals(1, prsList.size(), 'Expected a single processing event to be inserted');
        System.assertEquals(recordLog[0].Id, prsList[0].Processed_Record__c, 'Not linked to parent record log');
        System.assertEquals('Users', prsList[0].Share_With__c, 'Share with not populated as expected');
        System.assertEquals(sharedToUserString, prsList[0].Shared_to_User__c, 'User Id not populated as expected');
        System.assertEquals('Success', prsList[0].Status__c, 'Expected success since there was a matching share record also inserted');

        // Query for trigger metrics
        String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
        List<FormulaShare_Metrics__c> metricsList = [SELECT Id, Successful_Inserts__c, Failed_Inserts__c FROM FormulaShare_Metrics__c 
            WHERE Context__c = :triggerContext AND FormulaShare_Rule_Name__c = :pse.FormulaShare_Rule_Name__c];
        System.assertEquals(1, metricsList.size(), 'Should only be one metrics for rule and trigger context');
        System.assertEquals(1, metricsList[0].Successful_Inserts__c, 'Share insert should be marked as failure not success');
        System.assertEquals(0, metricsList[0].Failed_Inserts__c, 'Single share insert fail expected');
    }

    @IsTest
    public static void testLogAfterFailedInsert() {
        String ruleName = 'Test_rule';

        // Simulate a batch being scheduled
        FormulaShareAsyncApexJobSelector.isScheduled = true;

        // Insert existing trigger log so we can check this is updated
        FormulaShare_Metrics__c triggerMetrics = FormulaShareTestDataFactory.getTriggerMetricsForRuleAndBatch(ruleName, null);
        insert triggerMetrics;

        FormulaShare_Processed_Share_Event__e pse = new FormulaShare_Processed_Share_Event__e();

        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        String idString = String.valueOf(UserInfo.getUserId());
        DateTime insertedTime = System.now();

        pse.Access_Level__c = 'Read';
        pse.FormulaShare_Rule_Name__c = ruleName;
        pse.Object__c = prefix + 'FormulaShare_Log__c';
        pse.Operation__c = 'Insert';
        pse.Processed_Date_Time__c = insertedTime;
        pse.Record_Id__c = idString;
        pse.Shared_to_Id__c = idString;
        pse.Share_Id__c = idString;
        pse.Share_Key__c = 'ExampleShareKey';
        pse.Share_With__c = 'Users';
        pse.Sharing_Reason__c = prefix + 'FormulaShare_Log_Share__c';

        Test.startTest();
        EventBus.publish(pse);
        Test.stopTest();

        // Query for record log and check created as expected
        List<FormulaShare_Record_Log__c> recordLog = [SELECT Id, Processed_Date_Time__c, Record_Id__c FROM FormulaShare_Record_Log__c];
        System.assertEquals(1, recordLog.size(), 'Expected a single record log to be inserted');
        System.assertEquals(insertedTime, recordLog[0].Processed_Date_Time__c, 'Time not populated as expected');
        System.assertEquals(idString, recordLog[0].Record_Id__c, 'Record id not populated as expected');

        // Query for record share log and check created as expected
        List<FormulaShare_Processed_Record_Share__c> prsList = [SELECT Id, Processed_Record__c, Status__c, Share_With__c, Shared_to_User__c FROM FormulaShare_Processed_Record_Share__c];
        System.assertEquals(1, prsList.size(), 'Expected a single processing event to be inserted');
        System.assertEquals(recordLog[0].Id, prsList[0].Processed_Record__c, 'Not linked to parent record log');
        System.assertEquals('Users', prsList[0].Share_With__c, 'Share with not populated as expected');
        System.assertEquals(Id.valueOf(idString), prsList[0].Shared_to_User__c, 'User Id not populated as expected');
        System.assertEquals('Error', prsList[0].Status__c, 'Expected error since there was no matching share record inserted');

        // Query for trigger metrics
        String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
        List<FormulaShare_Metrics__c> metricsList = [SELECT Id, Successful_Inserts__c, Failed_Inserts__c FROM FormulaShare_Metrics__c 
            WHERE Context__c = :triggerContext AND FormulaShare_Rule_Name__c = :pse.FormulaShare_Rule_Name__c];
        System.assertEquals(1, metricsList.size(), 'Should only be one metrics for rule and trigger context');
        System.assertEquals(102, metricsList[0].Successful_Inserts__c, 'Successful inserts should have been unchanged from 102');
        System.assertEquals(3, metricsList[0].Failed_Inserts__c, 'Trigger failure metrics should have been incremented from 2 to 3');
    }
    
}