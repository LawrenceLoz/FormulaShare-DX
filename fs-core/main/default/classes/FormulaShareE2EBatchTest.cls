@IsTest
public with sharing class FormulaShareE2EBatchTest {

    
    @TestSetup
    public static void setup() {

        // Create admin user to run tests
        FormulaShareTestUtils.setupAdmin();

        List<UserRole> roles = FormulaShareTestDataFactory.getRoles(2);
        insert roles;
        List<User> usersList = FormulaShareTestDataFactory.getUsers(2, roles[0].Id);
        insert usersList;
    }

    private static void setMocks() {
        FormulaShareRulesSelector.mock = FormulaShareMockUtil.createMock(
            new FormulaShareInjectionService().getRulesSelectorType()
        );

        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;
    }

    @IsTest
    public static void testInsertSharing() {

        setMocks();

        System.runAs(FormulaShareTestUtils.getAdmin()) {

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

            // Mock SObjectShares - required as async job was running without sufficient permissions to insert sharing
            fflib_ApexMocks mocks = new fflib_ApexMocks();
            FormulaShareSObjectShares.mock = (FormulaShareSObjectShares) mocks.mock(FormulaShareSObjectShares.class);

            // Call recalculate method to set sharing
            Test.startTest();
            FormulaShareService.recalculateAll();
            Test.stopTest();

            // Retrieve the argument supplied to insertShares() for the mock
            fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass(FormulaShareSObjectShares.class);
            ((FormulaShareSObjectShares) mocks.verify(FormulaShareSObjectShares.mock)).insertShares((List<SObject>) argument.capture());
            List<FormulaShare_Log__Share> shares = (List<FormulaShare_Log__Share>) argument.getValue();

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
    }

}