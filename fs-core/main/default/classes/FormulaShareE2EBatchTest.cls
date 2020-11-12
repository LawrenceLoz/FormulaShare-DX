@IsTest
public with sharing class FormulaShareE2EBatchTest {

    @TestSetup
    public static void setup() {
        List<UserRole> roles = FormulaShareTestDataFactory.getRoles(2);
        insert roles;
        List<User> usersList = FormulaShareTestDataFactory.getUsers(2, roles[0].Id);
        insert usersList;
    }

    private static void setMocks() {
        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;

        FormulaShareUtilities mockFSShareUtiities = (FormulaShareUtilities) FormulaShareMockUtil.createMock(FormulaShareUtilities.class);
        FormulaShareUtilities.mock = mockFSShareUtiities;

        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;
    }

    @IsTest
    public static void testInsertSharing() {

        // Given
//        fflib_ApexMocks mocks = new fflib_ApexMocks();
//        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) mocks.mock(FormulaShareSettingsSelector.class);
//        FormulaShare_Settings__mdt fsSettings = new FormulaShare_Settings__mdt();
//        fsSettings.DeveloperName = 'Mock Settings';
//        fsSettings.Recalculation_Batch_Size__c = 5;
//        mocks.startStubbing();
//        mocks.when(mockFSSettingsSelector.selectActiveSettings()).thenReturn(fsSettings);
//        mocks.stopStubbing();
//        FormulaShareApplication.Selector.setMock(mockFSSettingsSelector);

        setMocks();

        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName LIKE 'TestRoleFormulaShare%'];
        UserRole role1 = roles[0];
        UserRole role2 = roles[1];

        List<User> usersList = [SELECT Id FROM User WHERE Firstname LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%'];
        System.debug('usersList: '+usersList);
        Id userId = usersList[0].Id;
        Id childUserId = usersList[1].Id;

        // Create log object and set fields which have test rules created within apex class
        List<FormulaShare_Log__c> fsLogs = new List<FormulaShare_Log__c>();
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = role1.Id;  // Share with role (id)
        log.Failed_Batches__c = role2.DeveloperName;  // Share with role and subordinates (name)
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        log.Exception_Type__c = userId;  // Share with user (Id)
        insert log;
        fsLogs.add(log);

        FormulaShare_Log__c childLog = new FormulaShare_Log__c();
        childLog.Exception_Type__c = usersList[1].Id;  // Share with user (Id)
        childLog.Related_Log_Required_for_Test_Class__c = log.Id;
        insert childLog;

        // Call recalculate method to set sharing
        Test.startTest();
        FormulaShareService.recalculateAll();
        Test.stopTest();

        // Retrieve share records for the inserted log
        List<FormulaShare_Log__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role1.Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role2.Id AND (Type = 'RoleAndSubordinates' OR Type = 'RoleAndSubordinatesInternal') ORDER BY Type Desc][0];
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundCorrectRoleShare = false;
        Boolean foundCorrectRoleSubordinatesShare = false;
        Boolean foundCorrectUserShare = false;
        Boolean foundCorrectGroupShare = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares) {
            system.debug('this share: '+share);
            if      (share.UserOrGroupId == roleGroup.Id) foundCorrectRoleShare = true;
            else if (share.UserOrGroupId == roleSubordinatesGroup.Id) foundCorrectRoleSubordinatesShare = true;
            else if (share.UserOrGroupId == userId) foundCorrectUserShare = true;
            else if (share.UserOrGroupId == publicGroup.Id) foundCorrectGroupShare = true;
        }
        System.assert(foundCorrectRoleShare);
        System.assert(foundCorrectRoleSubordinatesShare);
        System.assert(foundCorrectUserShare);
        System.assert(foundCorrectGroupShare);
    }


    @IsTest
    public static void testInsertSibling() {
        setMocks();

        List<User> usersList = [SELECT Id FROM User WHERE Firstname LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%' LIMIT 2];
        System.debug('usersList: '+usersList);

        // Create batch log
        FormulaShare_Log__c batchLog = FormulaShareTestDataFactory.getBatchLog();
        insert batchLog;

        // Create related record logs to be shared
        List<FormulaShare_Record_Log__c> recordLogs = FormulaShareTestDataFactory.getRecordLogsForBatchLog(batchLog.Id, 3);
        insert recordLogs;

        // Create related rule in batch logs controlling sharing
        List<FormulaShare_Rule_in_Batch__c> ribs = FormulaShareTestDataFactory.getRuleInBatchRecordsForSiblingRule(batchLog.Id, usersList, 2);
        insert ribs;

        // Call recalculate method to set sharing
        Test.startTest();
        FormulaShareService.recalculateAll();
        Test.stopTest();

        // Retrieve share records for the inserted record log
        List<FormulaShare_Record_Log__Share> shares = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Record_Log__Share WHERE Parent.FormulaShare_Batch_Log__c = :batchLog.Id];
        System.debug('|||Inserted '+shares.size()+' share records: '+shares);

        Integer relevantUserSharesForLog1 = 0;
        Integer relevantUserSharesForLog2 = 0;

        for(FormulaShare_Record_Log__Share share : shares) {
            if(share.ParentId == recordLogs[0].Id && (share.UserOrGroupId == usersList[0].Id || share.UserOrGroupId == usersList[1].Id)) {
                relevantUserSharesForLog1++;
            }
            if(share.ParentId == recordLogs[1].Id && (share.UserOrGroupId == usersList[0].Id || share.UserOrGroupId == usersList[1].Id)) {
                relevantUserSharesForLog2++;
            }
        }

        System.assertEquals(2, relevantUserSharesForLog1, 'Expected share records for both users in rule in batch records for first record log');
        System.assertEquals(2, relevantUserSharesForLog2, 'Expected share records for both users in rule in batch records for second record log');
    }

    
    @IsTest
    public static void testUpdateInlaw() {
        setMocks();

        FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();

        List<FormulaShare_Log__c> parentLogs = FormulaShareTestDataFactory.getBatchLogsNoSharingImpact(1);
        insert parentLogs;
        Id sharedRecordId = parentLogs[0].Id;

        List<FormulaShare_Rule_in_Batch__c> ribs = FormulaShareTestDataFactory.getRuleInBatchRecords(sharedRecordId, 1);
        insert ribs;
        Id controllingRecordId = ribs[0].Id;

        List<FormulaShare_Record_Log__c> bottomRecords = FormulaShareTestDataFactory.getSharingRecordLogsForInlawRule(sharedRecordId, controllingRecordId, 1);
        insert bottomRecords;

        // Insert one valid share (consistent with inlaw rule) and one share which should be removed for the batch log
        Id publicGroupId = FormulaShareTestUtils.getSharedGroupId();    // This should be the same as sharing provided by rule
        User u = [SELECT Id FROM User WHERE FirstName LIKE 'FormulaShareTestUser%' AND LastName LIKE 'OnlyForUnitTests%' LIMIT 1][0];
        List<Id> idsForShares = new List<Id>{publicGroupId, u.Id};
        List<FormulaShare_Log__Share> shares = FormulaShareTestDataFactory.getSharesForBatchLog(sharedRecordId, idsForShares, 'Edit');
        insert shares;

        // Call method to recalculate sharing
        Test.startTest();
        FormulaShareService.recalculateAll();
        Test.stopTest();

        // Retrieve share records for all batch logs
        List<FormulaShare_Log__Share> updatedShares = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause 
            FROM FormulaShare_Log__Share 
            WHERE ParentId = :sharedRecordId
            AND RowCause = :FormulaShareTestUtils.batchLogRowCause
            ];
        System.debug('updatedShares: '+updatedShares);
        System.assertEquals(1, updatedShares.size(), 'Only a single share is expected');
        System.assertEquals(publicGroupId, updatedShares[0].UserOrGroupId, 'Should share with public group set by rule');
    }
}