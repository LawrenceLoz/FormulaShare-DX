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

//  public static List<FormulaShare_Rule__mdt> rules = new List<FormulaShare_Rule__mdt>();
//	public static List<FormulaShareRule> fsRulePrims = new List<FormulaShareRule>();

    @TestSetup
    public static void setup() {
    
        // Insert 3 user roles
        List<UserRole> rolesForTest = new List<UserRole>();
        for(Integer i=0; i<3; i++) {
            UserRole role = new UserRole();
            role.DeveloperName = 'TestRoleFormulaShare'+i;
            role.Name = 'TestRoleFormulaShare'+i;
            rolesForTest.add(role);
        }
        insert rolesForTest;

        // Set and insert user
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName = orgId+dateString+RandomId; 

        User u = new User(
            firstname = 'FormulaShareTestUser', 
            lastName = 'OnlyForUnitTests', 
            email = 'FS' + uniqueName + '@test' + orgId + '.org', 
            Username = 'FS' + uniqueName + '@test' + orgId + '.org', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = 'FS' + uniqueName.substring(18, 21), 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = pf.Id, 
            UserRoleId = rolesForTest[0].Id);
        insert u;
    }

    //--------------------------------- Test utility methods ------------------------------------------------
    public static FormulaShareService callProcessForLogRecords(List<FormulaShare_Log__c> fsLogs) {
        Schema.SObjectType fsLogType = Schema.getGlobalDescribe().get('FormulaShare_Log__c');
        List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getRulesSharingObject(fsLogType);
		FormulaShareService fsService = FormulaShareService.construct(fsLogType, fsRules);
		for(FormulaShare_Log__c log : fsLogs) {
            fsService.recordsMap.put(log.Id, log);
        }
		fsService.processFormulaShares();
        return fsService;
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
        log.Class_Name__c = role.Id;  // Share with role (id)
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'Role'][0];

        // Check that fsService response is as expected
        System.assertEquals(fsService.recordsMap.get(log.Id), log, 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals('FormulaShare_Log_Share__c', sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testCreateRoleAndSubordinatesSharingNewRecord() {
        setMocks();
        UserRole role = getOneRole();

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = role.DeveloperName;  // Share with role and subordinates (name)
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'RoleAndSubordinates'][0];

        // Check that fsService response is as expected
        System.assertEquals(fsService.recordsMap.get(log.Id), log, 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role and subordinates group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role and subordinates group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleSubordinatesGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Read', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals('FormulaShare_Log_Share__c', sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
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
        System.assertEquals(fsService.recordsMap.get(log.Id), log, 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this public group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this public group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(publicGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals('FormulaShare_Log_Share__c', sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }

    @IsTest
    public static void testCreateUserSharingNewRecord() {
        setMocks();

        // Get the inserted user to share record to
        User u = [SELECT Id FROM User WHERE Firstname = 'FormulaShareTestUser' AND LastName = 'OnlyForUnitTests'][0];

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Method_Name__c = u.Id;  // Share with user (Id)
        log.OwnerId = UserInfo.getUserId();     // Make sure owner is a different user
        insert log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Check that fsService response is as expected
        System.assertEquals(fsService.recordsMap.get(log.Id), log, 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this user');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this user');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(u.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct user');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals('FormulaShare_Log_Share__c', sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
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
        log.Class_Name__c = roles[0].Id;
        insert log;

        test.startTest();

        // Apply sharing for first role
        FormulaShareService.recalculateAll();

        // Update log record to share with different role
        log.Class_Name__c = roles[1].Id;
        update log;

        FormulaShareService fsService = callProcessForLogRecord(log);

        // Get relevant id we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[1].Id AND Type = 'Role'][0];

        // Check that fsService response is as expected
        System.assertEquals(fsService.recordsMap.get(log.Id), log, 'New record not included in map');

        List<SObject> sharesToInsertList = fsService.getSharesToInsert();
        System.assert(!sharesToInsertList.isEmpty(), 'No share record for this role group');
        System.assertEquals(1, sharesToInsertList.size(), 'More than one share record for this role group');
        System.assertEquals(log.Id, sharesToInsertList[0].get('ParentId'), 'Share record not associated to correct parent');
        System.assertEquals(roleGroup.Id, sharesToInsertList[0].get('UserOrGroupId'), 'Share record not associated to correct group');
        System.assertEquals('Edit', sharesToInsertList[0].get('AccessLevel'), 'Access level not correct');
        System.assertEquals('FormulaShare_Log_Share__c', sharesToInsertList[0].get('RowCause'), 'Sharing reason different to expected');
    }


    // ----------------------------- Unit testing hard to test methods ----------------------------
    @IsTest
    public static void testUpdatingShareMapsStandard() {
        setMocks();

        Id anyValidId = UserInfo.getUserId();
        Schema.SObjectType fsLogType = Schema.getGlobalDescribe().get('Contact');

        // Check when no records were present in the map that a new record to insert is populated
        FormulaShareService fsService = FormulaShareService.construct(fsLogType);
        FormulaShareRule rule = new FormulaShareRule();

        // Find a FSRule object with access level of Read
        for(FormulaShareRule r : fsService.getRules()) {
            if(r.accessLevel == 'Read') {
                rule = r;
                break;
            }
        }

        // Add an element to the delete map. Any SObject is OK so long as the key matches the mock
        fsService.mapToDelete.put('123123Read', new FormulaShare_Log__c());

        fsService.updateShareMapsStandard(anyValidId, anyValidId, rule);
        system.assert(fsService.getSharesToInsert().isEmpty(), 'Record to insert which shouldnt be there');
        system.assert(fsService.getSharesToDelete().isEmpty(), 'Record to delete has not been removed');
    }


    @IsTest
    public static void testQueryingStandardObjectShares() {
        setMocks();

        FormulaShare_Log__c log = new FormulaShare_Log__c();
        insert log;
        
        Schema.SObjectType ContactType = Schema.getGlobalDescribe().get('Contact');
        FormulaShareService fsService = FormulaShareService.construct(ContactType);
        fsService.recordsMap.put(log.Id, log);

        fsService.processFormulaShares();

        // Check that no records included in the deletion map
        system.assert(fsService.getSharesToDelete().isEmpty());
    }


    // ------------------------- Integration test of batch job -------------------------------
    @IsTest
    public static void testInsertSharing() {

        // Given
//        fflib_ApexMocks mocks = new fflib_ApexMocks();
//        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) mocks.mock(FormulaShareSettingsSelector.class);
//        FormulaShare_Settings__mdt fsSettings = new FormulaShare_Settings__mdt();
//        fsSettings.DeveloperName = 'Mock Settings';
//        fsSettings.Recalculation_Batch_Size__c = 5;
//        fsSettings.Remove_Shares_for_Standard_Objects__c = true;
//        mocks.startStubbing();
//        mocks.when(mockFSSettingsSelector.selectActiveSettings()).thenReturn(fsSettings);
//        mocks.stopStubbing();
//        FormulaShareApplication.Selector.setMock(mockFSSettingsSelector);

        setMocks();

        UserRole role = getOneRole();

        // Create log object and set fields which have test rules created within apex class
        List<FormulaShare_Log__c> fsLogs = new List<FormulaShare_Log__c>();
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = role.DeveloperName;  // Share with role and subordinates (name)
        log.Class_Name__c = role.Id;  // Share with role (id)
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        log.Method_Name__c = UserInfo.getUserId();  // Share with user (Id)
        insert log;
        fsLogs.add(log);

        // Call recalculate method to set sharing
        test.startTest();
        FormulaShareService.recalculateAll();
        test.stopTest();

        // Retrieve share records for the inserted log
        List<FormulaShare_Log__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'RoleAndSubordinates'][0];
        Id userId = UserInfo.getUserId();
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundCorrectRoleShare = false;
        Boolean foundCorrectRoleSubordinatesShare = false;
        Boolean foundCorrectUserShare = false;
        Boolean foundCorrectGroupShare = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundCorrectRoleShare = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundCorrectRoleSubordinatesShare = true;
        else if  (share.UserOrGroupId == userId) foundCorrectUserShare = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundCorrectGroupShare = true;
        }
        System.assert(foundCorrectRoleShare);
        System.assert(foundCorrectRoleSubordinatesShare);
        System.assert(foundCorrectUserShare);
        System.assert(foundCorrectGroupShare);
    }

}