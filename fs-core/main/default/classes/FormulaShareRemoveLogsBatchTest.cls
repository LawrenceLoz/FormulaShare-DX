@IsTest
public with sharing class FormulaShareRemoveLogsBatchTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    
    static void setMocks() {
        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;
    }

    @IsTest
    public static void testRemoveOldLogs() {
        setMocks();

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Record_Log__c rl = new FormulaShare_Record_Log__c();
            insert rl;
            Test.setCreatedDate(rl.Id, DateTime.newInstance(2020,01,01));   // This is earlier than the settings mock deletion window

            FormulaShare_Log__c log = new FormulaShare_Log__c();
            insert log;
            Test.setCreatedDate(log.Id, DateTime.newInstance(2020,01,01));   // This is earlier than the settings mock deletion window
            
            Test.startTest();
            Id batchJobId = Database.executeBatch(new FormulaShareRemoveLogsBatch(), 200);
            Test.stopTest();

            List<FormulaShare_Record_Log__c> rlList = [SELECT Id FROM FormulaShare_Record_Log__c];
            System.assert(rlList.isEmpty(), 'Expected no record logs in system');
            List<FormulaShare_Log__c> logsList = [SELECT Id FROM FormulaShare_Log__c];
            System.assert(rlList.isEmpty(), 'Expected no batch logs in system');
        }
    }


    @IsTest
    public static void testKeepRecentLogs() {
        setMocks();

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Record_Log__c rl = new FormulaShare_Record_Log__c();
            insert rl;
            Test.setCreatedDate(rl.Id, DateTime.now()-0.5);   // This is earlier than the settings mock deletion window

            FormulaShare_Log__c log = new FormulaShare_Log__c();
            insert log;
            Test.setCreatedDate(log.Id, DateTime.now()-0.5);   // This is earlier than the settings mock deletion window
            
            Test.startTest();
            Id batchJobId = Database.executeBatch(new FormulaShareRemoveLogsBatch(), 200);
            Test.stopTest();

            List<FormulaShare_Record_Log__c> rlList = [SELECT Id FROM FormulaShare_Record_Log__c];
            System.assertEquals(1, rlList.size(), 'Expected record log to be kept');
            List<FormulaShare_Log__c> logsList = [SELECT Id FROM FormulaShare_Log__c];
            System.assertEquals(1, logsList.size(), 'Expected batch log to be kept');
        }
    }

}