@IsTest
public with sharing class FormulaSharePSEventTriggerTest {

    @IsTest
    public static void testLogAfterFailedInsert() {
        FormulaShare_Processed_Share_Event__e pse = new FormulaShare_Processed_Share_Event__e();

        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        String idString = String.valueOf(UserInfo.getUserId());
        DateTime insertedTime = System.now();

        pse.Access_Level__c = 'Read';
        pse.FormulaShare_Rule_Name__c = 'Test_rule';
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

        List<FormulaShare_Processed_Record_Share__c> prsList = [SELECT Id, Processed_Record__c, Status__c, Share_With__c, Shared_to_User__c FROM FormulaShare_Processed_Record_Share__c];
        System.assertEquals(1, prsList.size(), 'Expected a single processing event to be inserted');
        System.assertEquals(recordLog[0].Id, prsList[0].Processed_Record__c, 'Not linked to parent record log');
        System.assertEquals('Users', prsList[0].Share_With__c, 'Share with not populated as expected');
        System.assertEquals(Id.valueOf(idString), prsList[0].Shared_to_User__c, 'User Id not populated as expected');
        System.assertEquals('Error', prsList[0].Status__c, 'Expected error since there was no matching share record inserted');
    }
}
