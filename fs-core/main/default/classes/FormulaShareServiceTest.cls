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

@IsTest
public class FormulaShareServiceTest {

    static String reason = FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Log_Share__c';

    @TestSetup
    public static void setup() {
        List<UserRole> roles = FormulaShareTestDataFactory.getRoles(3);
        insert roles;
        List<User> usersList = FormulaShareTestDataFactory.getUsers(1, roles[0].Id);
        insert usersList;
    }

    //--------------------------------- Test utility methods ------------------------------------------------

    // Called directly when related rules being tested
    public static FormulaShareService callProcessForLogRecordWithRelated(List<FormulaShare_Log__c> fsLogs, Map<Id,Map<String,List<FormulaShare_Log__c>>> relatedRecordsMap) {
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getRulesSharingObject(fsLogType);
		FormulaShareService fsService = FormulaShareService.construct(fsLogType, fsRules);

        List<FormulaShareRetrievedRecordDetails> recordDetails = new List<FormulaShareRetrievedRecordDetails>();
        for(FormulaShare_Log__c log : fsLogs) {
            FormulaShareRetrievedRecordDetails details = new FormulaShareRetrievedRecordDetails();
            details.sharedRecord = log;
            if(relatedRecordsMap != null && relatedRecordsMap.containsKey(log.Id)) {
                details.controllingRecordsForRulesMap = relatedRecordsMap.get(log.Id);
            }
            recordDetails.add(details);
        }
        fsService.setSharedRecordDetails(recordDetails);

		fsService.processFormulaShares();
        return fsService;
    }

    public static FormulaShareService callProcessForLogRecords(List<FormulaShare_Log__c> fsLogs) {
        return callProcessForLogRecordWithRelated(fsLogs, null);
    }

    public static FormulaShareService callProcessForLogRecord(FormulaShare_Log__c log) {
        List<FormulaShare_Log__c> fsLogs = new List<FormulaShare_Log__c>();
        fsLogs.add(log);
        return callProcessForLogRecords(fsLogs);
    }

    public static void setMocks() {
        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;

        FormulaShareUtilities mockFSShareUtiities = (FormulaShareUtilities) FormulaShareMockUtil.createMock(FormulaShareUtilities.class);
        FormulaShareUtilities.mock = mockFSShareUtiities;

        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;
    }

    public static UserRole getOneRole() {
        UserRole role = [SELECT Id, DeveloperName FROM UserRole 
            WHERE DeveloperName LIKE 'TestRoleFormulaShare%' 
            ORDER BY DeveloperName LIMIT 1][0];
        return role;
    }


    //------------------ Positive testing of record insertion for supported rule types ----------------------
    @IsTest
    public static void testCreateRoleSharingNewRecord() {
        setMocks();
        UserRole role = getOneRole();

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = role.Id;  // Share with role (id)
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'Role'][0];

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(log.Id), 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testCreateRoleAndSubordinatesSharingNewRecord() {
        setMocks();
        UserRole role = getOneRole();

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Failed_Batches__c = role.DeveloperName;  // Share with role and subordinates (name)
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND (Type = 'RoleAndSubordinates' OR Type = 'RoleAndSubordinatesInternal') ORDER BY Type Desc][0];

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(log.Id), 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role and subordinates group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role and subordinates group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleSubordinatesGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Read', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testCreatePublicGroupSharingNewRecord() {
        setMocks();

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(log.Id), 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this public group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this public group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(publicGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testRelatedCreateUserSharingNewRecord() {
        setMocks();

        // Get the inserted user to share record to
        User u = [SELECT Id FROM User WHERE Firstname LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%'][0];

        // Create parent log object and set fields which have test rules created within apex class
        FormulaShare_Log__c parentLog = new FormulaShare_Log__c();
        parentLog.OwnerId = UserInfo.getUserId();     // Make sure owner is different to the user we want to share with
        insert parentLog;

        FormulaShare_Log__c childLog = new FormulaShare_Log__c();
        childLog.Exception_Type__c = u.Id;  // Share with user (Id)
        childLog.Related_Log_Required_for_Test_Class__c = parentLog.Id;
        insert childLog;

        FormulaShare_Log__c childLog2 = new FormulaShare_Log__c();
        childLog2.Exception_Type__c = u.Id;  // Share with user (Id)
        childLog2.Related_Log_Required_for_Test_Class__c = parentLog.Id;
        insert childLog2;

        List<FormulaShare_Log__c> sharedList = new List<FormulaShare_Log__c>{
            parentLog};
        List<FormulaShare_Log__c> relatedList = new List<FormulaShare_Log__c>{
            childLog, childLog2};
        Map<String,List<FormulaShare_Log__c>> relatedRecordsForRules = new Map<String,List<FormulaShare_Log__c>>{
            FormulaShareMockProvider.childUserRuleName => relatedList};
        Map<Id,Map<String,List<FormulaShare_Log__c>>> relatedRecordsMap = new Map<Id,Map<String,List<FormulaShare_Log__c>>>{
            parentLog.Id => relatedRecordsForRules};

        FormulaShareService fsService = callProcessForLogRecordWithRelated(sharedList, relatedRecordsMap);

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(parentLog.Id), 'Record differs from one expected');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this user');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this user');
        System.assertEquals(parentLog.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(u.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct user');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testCreateUserSharingNewRecord() {
        setMocks();

        // Get the inserted user to share record to
        User u = [SELECT Id FROM User WHERE Firstname LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%'][0];

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Exception_Type__c = u.Id;  // Share with user (Id)
        log.OwnerId = UserInfo.getUserId();     // Make sure owner is a different user
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(log.Id), 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this user');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this user');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(u.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct user');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    // ------------------ Testing updates to sharing -------------------------
    @IsTest
    public static void testUpdateRoleSharingToNewRole() {

        setMocks();

        // Retrieve two roles
        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole 
            WHERE DeveloperName LIKE 'TestRoleFormulaShare%' 
            ORDER BY DeveloperName LIMIT 2];
        
        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = roles[0].Id;
        insert log;

        test.startTest();

        // Apply sharing for first role
        FormulaShareService.recalculateAll();

        // Update log record to share with different role
        log.Context__c = roles[1].Id;
        update log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[1].Id AND Type = 'Role'][0];

        // Check that fsService response is as expected
        System.assert(fsService.sharedRecordIdsSet.contains(log.Id), 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals(reason, sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }


    // ----------------------------- Unit testing hard to test methods ----------------------------
//    @IsTest
//    public static void testUpdatingShareMapsStandard() {
//        setMocks();
//
//        Id anyValidId = UserInfo.getUserId();
//        Schema.SObjectType fsLogType = Schema.getGlobalDescribe().get('Contact');
//
//        // Check when no records were present in the map that a new record to insert is populated
//        FormulaShareService fsService = FormulaShareService.construct(fsLogType);
//        FormulaShareRule rule = new FormulaShareRule();
//
//        // Find a FSRule object with access level of Read
//        for(FormulaShareRule r : fsService.rules) {
//            if(r.accessLevel == 'Read') {
//                rule = r;
//                break;
//            }
//        }
//
//        // Add an element to the delete map. Any SObject is OK so long as the key matches the mock
//        FormulaShareService.ShareDetail sd = new FormulaShareService.ShareDetail();
//        FormulaShare_Log__c log = new FormulaShare_Log__c();
//        sd.shareRecord = log;
//        fsService.mapToDelete.put('123123Read', sd);
//        fsService.existingShareKeys.add('123123Read');
//
//        fsService.updateShareMaps(anyValidId, anyValidId, rule);
//        system.assert(fsService.getSharesToInsert().isEmpty(), 'Record to insert which shouldnt be there');
//        system.assert(fsService.getSharesToDelete().isEmpty(), 'Record to delete has not been removed');
//    }


    @IsTest
    public static void testQueryingStandardObjectShares() {
        setMocks();

        FormulaShare_Log__c log = new FormulaShare_Log__c();
        insert log;
        
        Schema.SObjectType ContactType = Schema.getGlobalDescribe().get('Contact');
        FormulaShareService fsService = FormulaShareService.construct(ContactType);

        FormulaShareRetrievedRecordDetails details = new FormulaShareRetrievedRecordDetails();
        details.sharedRecord = log;
        List<FormulaShareRetrievedRecordDetails> detailsList = new List<FormulaShareRetrievedRecordDetails>{details};
        fsService.setSharedRecordDetails(detailsList);

        fsService.processFormulaShares();

        // Check that no records included in the deletion map
        system.assert(fsService.getSharesToDelete().isEmpty());
    }


}