/**
*Copyright 2019 Lawrence Newcombe
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

@IsTest
public with sharing class FormulaShareTriggerHelperTest {

    @TestSetup
    static void setup() {
        List<UserRole> roles = FormulaShareTestDataFactory.getRoles(3);
        insert roles;
        List<User> usersList = FormulaShareTestDataFactory.getUsers(1, roles[0].Id);
        insert usersList;
    }

    static void setMocks() {
//        FormulaShareService mockFSService = (FormulaShareService) FormulaShareMockUtil.createMock(FormulaShareService.class);
//        FormulaShareService.mock = mockFSService;

        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;
    }


    @IsTest
    public static void testStandardRuleOnInsert() {
        setMocks();
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        // Create log which should be considered for sharing
        FormulaShare_Log__c log1 = FormulaShareTestDataFactory.getBatchLog();
        Group grp = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];
        log1.Type_In_Scope__c = grp.Id;      // Should trigger group sharing rule
        insert log1;

        // Create log which shouldn't be considered for sharing (all fields involved in sharing set to null)
        FormulaShare_Log__c log2 = FormulaShareTestDataFactory.getBatchLog();
        log2.Context__c = null;
        log2.Type_In_Scope__c = null;
        log2.Exception_Type__c = null;
        log2.Failed_Batches__c = null;
        insert log2;

        Map<Id,SObject> newRecords = new Map<Id,SObject>();
        newRecords.put(log1.Id, log1);
        newRecords.put(log2.Id, log2);

        helper.setServiceObjectsWithRecords(fsLogType, null, newRecords);

        // Check that class variables populated as expected
        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');
        System.assertEquals(1, helper.populatedFsServiceList.size(), 'Expected one object in scope');
        
        FormulaShareService service = helper.populatedFsServiceList[0];
        List<FormulaShareRetrievedRecordDetails> details = service.recordDetails;
        System.assertEquals(1, details.size(), 'Expected one record in processing map');

        FormulaShare_Log__c record = (FormulaShare_Log__c) details[0].sharedRecord;
        System.assertEquals(log1.Id, record.Id, 'Record included isn\'t the one we expected');
        System.assertEquals(grp.Id, record.Type_In_Scope__c, 'Field on record isn\'t populated with expected value');
    }


    @IsTest
    public static void testStandardRuleOnUpdate() {
        setMocks();
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        Group grp = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        FormulaShare_Log__c log1Old = FormulaShareTestDataFactory.getBatchLog();
        log1Old.Type_In_Scope__c = grp.Id;
        insert log1Old;

        FormulaShare_Log__c log2Old = FormulaShareTestDataFactory.getBatchLog();
        log2Old.Type_In_Scope__c = grp.Id;
        insert log2Old;

        // Simulate record being modifed in a way which would trigger sharing recalculation
        FormulaShare_Log__c log1New = log1Old.clone(true, true, false, false);
        log1New.Type_In_Scope__c = 'something different';       // This should ensure that sharing field recognised as modified

        // Simulate record being modifed in a way which should be excluded from sharing recalculation
        FormulaShare_Log__c log2New = log2Old.clone(true, true, false, false);
        log2New.Number_Of_Rules__c = 14;      // Should not trigger sharing rule

        Map<Id,SObject> existingRecords = new Map<Id,SObject>();
        Map<Id,SObject> newRecords = new Map<Id,SObject>();
        existingRecords.put(log1Old.Id, log1Old);
        existingRecords.put(log2Old.Id, log2Old);
        newRecords.put(log1New.Id, log1New);
        newRecords.put(log2New.Id, log2New);

        // Call helper method
        helper.setServiceObjectsWithRecords(fsLogType, existingRecords, newRecords);

        // Check that class variables populated as expected
        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');
        System.assertEquals(1, helper.populatedFsServiceList.size(), 'Expected one object in scope');
        
        List<FormulaShareRetrievedRecordDetails> details = helper.populatedFsServiceList[0].recordDetails;
        System.assertEquals(1, details.size(), 'Expected one record in processing map');

        FormulaShare_Log__c record = (FormulaShare_Log__c) details[0].sharedRecord;
        System.assertEquals(log1New.Id, record.Id, 'Record included isn\'t the one we expected');
        System.assertEquals('something different', record.Type_In_Scope__c, 'Modified field value not set to new version');
    }


    @IsTest
    public static void testDescendantRuleOnCreate() {
        setMocks();
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        List<User> users = [SELECT Id FROM User WHERE FirstName LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%' LIMIT 2];

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        List<FormulaShare_Log__c> parentLogs = FormulaShareTestDataFactory.getBatchLogs(2);
        insert parentLogs;
        Id sharedRecordId = parentLogs[0].Id;

        // Should create records to share with both supplied users
        List<FormulaShare_Log__c> childLogsWithSharing = FormulaShareTestDataFactory.getChildLogsSharingParent(sharedRecordId, users, 4);
        insert childLogsWithSharing;

        // Should create records which shouldn't impact sharing
        List<FormulaShare_Log__c> childLogsNoSharing = FormulaShareTestDataFactory.getChildLogsNoSharingImpact(sharedRecordId, 5);
        insert childLogsNoSharing;


        List<FormulaShare_Log__c> childLogs = new List<FormulaShare_Log__c>();
        childLogs.addAll(childLogsWithSharing);
        childLogs.addAll(childLogsNoSharing);

        Map<Id,SObject> newRecords = new Map<Id,SObject>();
        for(FormulaShare_Log__c log : childLogs) {
            newRecords.put(log.Id, log);
        }

        helper.setServiceObjectsWithRecords(fsLogType, null, newRecords);

        // Check that class variables populated as expected
        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');
        System.assertEquals(1, helper.populatedFsServiceList.size(), 'Expected one object in scope');
        
        FormulaShareService service = helper.populatedFsServiceList[0];
        List<FormulaShareRetrievedRecordDetails> details = service.recordDetails;
        
        FormulaShareRetrievedRecordDetails detail;
        for(FormulaShareRetrievedRecordDetails thisDetail : details) {
            if(thisDetail.sharedRecord.get('Id') == sharedRecordId) {
                detail = thisDetail;
            }
        }
        System.assert(detail != null, 'Expected the shared parent in processing map');

        FormulaShare_Log__c record = (FormulaShare_Log__c) details[0].sharedRecord;
        System.assertEquals(sharedRecordId, record.Id, 'Record included isn\'t the one we expected');
        System.assert(record.OwnerId != null, 'Expected owner id of shared record to have been retrieved');

        Map<String,List<SObject>> objectsForRulesMap = details[0].controllingRecordsForRulesMap;
        System.assertEquals(1, objectsForRulesMap.size(), 'Only the child rule should be included');
        List<SObject> controllingObjects = objectsForRulesMap.get(FormulaShareMockProvider.childUserRuleName);
        System.assertEquals(4, controllingObjects.size(), 'The 4 child records with sharing details should be included');
    }


    @IsTest
    public static void testDescendantRuleOnUpdate() {
        setMocks();
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        List<User> users = [SELECT Id FROM User WHERE FirstName LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%' LIMIT 2];

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        List<FormulaShare_Log__c> parentLogs = FormulaShareTestDataFactory.getBatchLogs(2);
        insert parentLogs;
        Id sharedRecordId = parentLogs[0].Id;

        // Should create records which shouldn't impact sharing
        List<FormulaShare_Log__c> childLogsNoSharing = FormulaShareTestDataFactory.getChildLogsNoSharingImpact(sharedRecordId, 2);
        insert childLogsNoSharing;

        FormulaShare_Log__c log1Old = childLogsNoSharing[0];
        FormulaShare_Log__c log2Old = childLogsNoSharing[1];

        // Simulate record being modifed in a way which would trigger sharing recalculation
        FormulaShare_Log__c log1New = log1Old.clone(true, true, false, false);
        log1New.Exception_Type__c = users[0].Id;       // This should ensure that sharing field recognised as modified

        // Simulate record being modifed in a way which should be excluded from sharing recalculation
        FormulaShare_Log__c log2New = log2Old.clone(true, true, false, false);
        log2New.Number_Of_Rules__c = 14;      // Should not trigger sharing rule

        Map<Id,SObject> existingRecords = new Map<Id,SObject>();
        Map<Id,SObject> newRecords = new Map<Id,SObject>();
        existingRecords.put(log1Old.Id, log1Old);
        existingRecords.put(log2Old.Id, log2Old);
        newRecords.put(log1New.Id, log1New);
        newRecords.put(log2New.Id, log2New);

        helper.setServiceObjectsWithRecords(fsLogType, existingRecords, newRecords);

        // Check that class variables populated as expected
        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');
        System.assertEquals(1, helper.populatedFsServiceList.size(), 'Expected one object in scope');
        
        FormulaShareService service = helper.populatedFsServiceList[0];
        List<FormulaShareRetrievedRecordDetails> details = service.recordDetails;

        // Note we iterate through - we'd expect more than one record, as the updated field is also used in a standard rule as well as the child rule
        FormulaShareRetrievedRecordDetails detail;
        for(FormulaShareRetrievedRecordDetails thisDetail : details) {
            if(thisDetail.sharedRecord.get('Id') == sharedRecordId) {
                detail = thisDetail;
            }
        }
        System.assert(detail != null, 'Expected the shared parent in processing map');

        Map<String,List<SObject>> objectsForRulesMap = details[0].controllingRecordsForRulesMap;
        System.assertEquals(1, objectsForRulesMap.size(), 'Only the child rule should be included');
        List<SObject> controllingObjects = objectsForRulesMap.get(FormulaShareMockProvider.childUserRuleName);
        System.assertEquals(1, controllingObjects.size(), 'The one child record which was updated should be included');
    }    



    @IsTest
    public static void testInlawRuleOnCreate() {
        setMocks();

        List<User> users = [SELECT Id FROM User WHERE FirstName LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%' LIMIT 2];

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        List<FormulaShare_Log__c> parentLogs = FormulaShareTestDataFactory.getBatchLogsNoSharingImpact(1);
        insert parentLogs;
        Id sharedRecordId = parentLogs[0].Id;

        List<FormulaShare_Rule_in_Batch__c> ribs = FormulaShareTestDataFactory.getRuleInBatchRecords(sharedRecordId, 1);
        insert ribs;
        Id controllingRecordId = ribs[0].Id;

        List<FormulaShare_Record_Log__c> bottomRecords = FormulaShareTestDataFactory.getSharingRecordLogsForInlawRule(sharedRecordId, controllingRecordId, 1);
        insert bottomRecords;

        Map<Id,SObject> newRecords = new Map<Id,SObject>();
        newRecords.put(bottomRecords[0].Id, bottomRecords[0]);

        Schema.SObjectType recordLogsType = FormulaShare_Record_Log__c.SObjectType;
        helper.setServiceObjectsWithRecords(recordLogsType, null, newRecords);

        // Check that class variables populated as expected
        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');

        FormulaShareService service;
        for(FormulaShareService serviceInList : helper.populatedFsServiceList) {
            if(serviceInList.type.getDescribe().getName().contains('FormulaShare_Log__c')) {
               service = serviceInList;
            }
        }

        System.assert(service != null, 'Service should have been set for the shared object (FormulaShare_Log)');

        FormulaShare_Log__c record = (FormulaShare_Log__c) service.recordDetails[0].sharedRecord;
        System.assertEquals(sharedRecordId, record.Id, 'Record included isn\'t the one we expected');

        Map<String,List<SObject>> objectsForRulesMap = service.recordDetails[0].controllingRecordsForRulesMap;
        System.assertEquals(1, objectsForRulesMap.size(), 'Only the inlaw rule should be included');
        List<SObject> controllingObjects = objectsForRulesMap.get(FormulaShareMockProvider.inlawGroupRuleName);
        System.assertEquals(1, controllingObjects.size(), 'Only the single bottom record with sharing details should be included');
    }



// Replace to check no effect for delete
//    @IsTest
//    public static void testChildRuleOnDelete() {
//        setMocks();
//        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
//
//        // Get the inserted user to share record to
//        User u = [SELECT Id FROM User WHERE Firstname LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%'][0];
//
//        // Create parent log object and set fields which have test rules created within apex class
//        FormulaShare_Log__c parentLog = FormulaShareTestDataFactory.getBatchLog();
//        parentLog.OwnerId = UserInfo.getUserId();     // Make sure owner is different to the user we want to share with
//        insert parentLog;
//
//        FormulaShare_Log__c childLog = FormulaShareTestDataFactory.getBatchLog();
//        childLog.Exception_Type__c = u.Id;  // Share with user (Id)
//        childLog.Related_Log_Required_for_Test_Class__c = parentLog.Id;
//        insert childLog;
//
//        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();
//
//        // Populate old records only (to simulate deletion)
//        Map<Id,SObject> existingRecords = new Map<Id,SObject>();
//        existingRecords.put(childLog.Id, childLog);
//
//        // Call helper method
//        helper.handleChanges(fsLogType, existingRecords, null);
//
//        // Check that class variables populated as expected
//        System.assert(!helper.populatedFsServiceList.isEmpty(), 'FormulaShareService not initialised by method call');
//        System.assertEquals(1, helper.populatedFsServiceList.size(), 'Expected one object in scope');
//        
//        List<FormulaShareRetrievedRecordDetails> details = helper.populatedFsServiceList[0].recordDetails;
//        System.assertEquals(1, details.size(), 'Expected one record in processing map');
//
//        FormulaShare_Log__c record = (FormulaShare_Log__c) details[0].sharedRecord;
//        System.assertEquals(parentLog.Id, record.Id, 'Record included isn\'t the one we expected');
//    }



    @IsTest
    public static void testGetSharesToInsert() {
        FormulaShareService mockFSService = (FormulaShareService) FormulaShareMockUtil.createMock(FormulaShareService.class);
//        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        helper.populatedFsServiceList.add(mockFSService);

        List<FormulaShare_Log__Share> sharesToInsert = (List<FormulaShare_Log__Share>) helper.getSharesToInsert();

        system.assert(!sharesToInsert.isEmpty(), 'No shares to insert returned');
        system.assertEquals(1, sharesToInsert.size());
    }


    @IsTest
    public static void testGetSharesToDelete() {
        FormulaShareService mockFSService = (FormulaShareService) FormulaShareMockUtil.createMock(FormulaShareService.class);
//        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        helper.populatedFsServiceList.add(mockFSService);

        List<FormulaShare_Log__Share> sharesToDelete = (List<FormulaShare_Log__Share>) helper.getSharesToDelete();

        system.assert(!sharesToDelete.isEmpty(), 'No shares to delete returned');
        system.assertEquals(1, sharesToDelete.size());
    }


//    @IsTest
//    public static void testGetDeleteFailsWhenMoreThanOneObject() {
//        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();
//
//        FormulaShareService mockFSService = (FormulaShareService) FormulaShareMockUtil.createMock(FormulaShareService.class);
//        //Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
//        helper.populatedFsServiceMap.put('standardRule|FormulaShare_Log__c', mockFSService);
//
//        // Add another entry to the FS Service map
//        Schema.SObjectType contactType = Contact.SObjectType;
//        helper.populatedFsServiceMap.put('standardRule|Contact', mockFSService);     // Add another pair to the map
//
//        try {
//            List<FormulaShare_Log__Share> sharesToDelete = (List<FormulaShare_Log__Share>) helper.getSharesToDelete();
//        }
//
//        catch(FormulaShareTriggerHelper.FormulaShareException e) {
//            system.assertEquals(e.getMessage(), 'More than one object in scope - call getSharesToDelete with object name instead');
//        }
//    }

}