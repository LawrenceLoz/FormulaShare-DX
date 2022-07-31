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
public with sharing class FormulaShareServiceBulkTest {

    public static void setMocks() {

        // Always use standard rules mock (avoids issues around populating fake details object, which would
        // otherwise need appropriate controlling records set for each related rule)
//        FormulaShareInjectionService.useStandardRulesSelector = true;
        FormulaShareRulesSelector.mock = FormulaShareMockUtil.createMock(
            new FormulaShareInjectionService().getRulesSelectorType()
        );

        FormulaShareIdUtilities mockFSShareIdUtilities = (FormulaShareIdUtilities) FormulaShareMockUtil.createMock(FormulaShareIdUtilities.class);
        FormulaShareIdUtilities.mock = mockFSShareIdUtilities;

        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;
    }


    static Integer noSharesOfEachType = 40;   // Will create and submit 3x this many share records in total

    @testSetup
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


    // Test that a bulk insert transaction processes as expected
    // Method will insert records to trigger various combinations of rules
    @isTest
    public static void testInsertSharing() {
        setMocks();

        UserRole role = FormulaShareServiceTest.getOneRole();

        // Create records with all sharing fields populated
        List<FormulaShare_Log__c> fsLogs = new List<FormulaShare_Log__c>();
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Failed_Batches__c = role.DeveloperName;  // Share with role and subordinates (name)
            log.Context__c = role.Id;  // Share with role (id)
            log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
            log.Exception_Type__c = UserInfo.getUserId();  // Share with user (Id)
            log.Method_Name__c = 'allShares';     // To identify records later
            fsLogs.add(log);
        }

        // Create records to be shared through role and subordinates sharing only
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Failed_Batches__c = role.DeveloperName;  // Share with role and subordinates (name)
            log.Method_Name__c = 'oneShare';     // To identify records later
            fsLogs.add(log);
        }

        // Create records to be shared through two different rules
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Context__c = role.Id;  // Share with role (id)
            log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
            log.Method_Name__c = 'twoShares';     // To identify records later
            fsLogs.add(log);
        }

        // Insert all records
        insert fsLogs;

        // Call recalculate method to set sharing
        Test.startTest();
        FormulaShareService.recalculateAll();
        Test.stopTest();

        // Find a record which should be shared by all rules
        FormulaShare_Log__c log1 = [SELECT Id FROM FormulaShare_Log__c WHERE Method_Name__c = 'allShares'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log1.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND (Type = 'RoleAndSubordinates' OR Type = 'RoleAndSubordinatesInternal') ORDER BY Type Desc][0];
        Id userId = UserInfo.getUserId();
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundRoleShare1 = false;
        Boolean foundRoleSubordinatesShare1 = false;
        Boolean foundUserShare1 = false;
        Boolean foundGroupShare1 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundRoleShare1 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare1 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare1 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare1 = true;
        }
        System.assert(foundRoleShare1);
        System.assert(foundRoleSubordinatesShare1);
        System.assert(foundUserShare1);
        System.assert(foundGroupShare1);


        // Find a record which should be shared by just one rule
        FormulaShare_Log__c log2 = [SELECT Id FROM FormulaShare_Log__c WHERE Method_Name__c = 'oneShare'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares2 = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log2.Id];

        Boolean foundRoleShare2 = false;
        Boolean foundRoleSubordinatesShare2 = false;
        Boolean foundUserShare2 = false;
        Boolean foundGroupShare2 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares2) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundRoleShare2 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare2 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare2 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare2 = true;
        }
        System.assert(!foundRoleShare2);
        System.assert(foundRoleSubordinatesShare2);
        System.assert(!foundGroupShare2);


        // Find a record which should be shared by just one rule
        FormulaShare_Log__c log3 = [SELECT Id FROM FormulaShare_Log__c WHERE Method_Name__c = 'twoShares'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares3 = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log3.Id];

        Boolean foundRoleShare3 = false;
        Boolean foundRoleSubordinatesShare3 = false;
        Boolean foundUserShare3 = false;
        Boolean foundGroupShare3 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares3) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundRoleShare3 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare3 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare3 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare3 = true;
        }
        System.assert(foundRoleShare3);
        System.assert(!foundRoleSubordinatesShare3);
        System.assert(foundGroupShare3);

    }


    // Test that a bulk update transaction processes as expected
    // Method will insert records and apply all the sharing, then modify records such that
    // Sharing should be removed and new sharing applied in various combinations
    @isTest
    public static void testUpdateSharing() {
        setMocks();

        // Retrieve two roles
        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole 
            WHERE DeveloperName LIKE 'TestRoleFormulaShare%' 
            ORDER BY DeveloperName LIMIT 2];
        UserRole role = roles[0];
        UserRole role2 = roles[1];

        // Create records with all sharing fields populated
        List<FormulaShare_Log__c> fsLogs = new List<FormulaShare_Log__c>();
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Failed_Batches__c = role.DeveloperName;  // Share with role and subordinates (name)
            log.Context__c = role.Id;  // Share with role (id)
            log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
            log.Exception_Type__c = UserInfo.getUserId();  // Share with user (Id)
            log.Method_Name__c = 'allShares';     // To identify records later
            fsLogs.add(log);
        }

        // Create records to be shared through role and subordinates sharing only
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Failed_Batches__c = role.DeveloperName;  // Share with role and subordinates (name)
            log.Method_Name__c = 'oneShare';     // To identify records later
            fsLogs.add(log);
        }

        // Create records to be shared through two different rules
        for(Integer i=0; i<noSharesOfEachType; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Context__c = role.Id;  // Share with role (id)
            log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
            log.Method_Name__c = 'twoShares';     // To identify records later
            fsLogs.add(log);
        }

        // Insert all records
        insert fsLogs;

        // Carry out processing to share records (we won't use a batch as only one can be called per test)
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getRulesSharingObject(fsLogType);
        FormulaShareService fsService = FormulaShareService.construct(fsLogType, fsRules);
        
        // Inject details object set with records (assumes only standard rules, and no controlling objects set)
        List<FormulaShareRetrievedRecordDetails> recordDetails = new List<FormulaShareRetrievedRecordDetails>();
        for(FormulaShare_Log__c log : fsLogs) {
            FormulaShareRetrievedRecordDetails details = new FormulaShareRetrievedRecordDetails();
            details.sharedRecord = log;

            // For any non-standard rule, add a details object with empty list to controllingRecordsForRulesMap
            // This indicates no relevant related records to process
            for(FormulaShareRule rule : fsRules) {
                if(!(rule instanceof FormulaShareRuleStandard)) {
                    details.controllingRecordsForRulesMap.put(rule.developerName, new List<SObject>());
                }
            }

            recordDetails.add(details);
        }

        fsService.setSharedRecordDetails(recordDetails);
        
		fsService.processFormulaShares();

        // Update to remove sharing from records shared with all
        List<FormulaShare_Log__c> fsLogsToUpdate = new List<FormulaShare_Log__c>();

        List<FormulaShare_Log__c> fsLogsAll = [SELECT Id, Failed_Batches__c, Context__c, Type_In_Scope__c, Exception_Type__c
            FROM FormulaShare_Log__c WHERE Method_Name__c = 'allShares'];
        system.debug('alls size: '+fsLogsAll.size());

        for(FormulaShare_Log__c log : fsLogsAll) {
            log.Failed_Batches__c = '';
            log.Context__c = '';
            log.Type_In_Scope__c = '';
            log.Exception_Type__c = '';
            fsLogsToUpdate.add(log);
        }

        // Update to change sharing for records with two shares
        List<FormulaShare_Log__c> fsLogsTwo = [SELECT Id, Failed_Batches__c, Context__c, Type_In_Scope__c, Exception_Type__c
            FROM FormulaShare_Log__c WHERE Method_Name__c = 'twoShares'];
        for(FormulaShare_Log__c log : fsLogsTwo) {
            log.Context__c = role2.Id;  // Share with other role
            fsLogsToUpdate.add(log);
        }

        // Update to add sharing for records with one share
        List<FormulaShare_Log__c> fsLogsOne = [SELECT Id, Failed_Batches__c, Method_Name__c, Type_In_Scope__c, Exception_Type__c
            FROM FormulaShare_Log__c WHERE Method_Name__c = 'oneShare'];
        for(FormulaShare_Log__c log : fsLogsOne) {
            log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
            fsLogsToUpdate.add(log);
        }

        update fsLogsToUpdate;

        // Call recalculate method to set sharing
        Test.startTest();
        FormulaShareService.recalculateAll();
        Test.stopTest();


        // Find a record which should have had sharing removed
        FormulaShare_Log__c log1 = [SELECT Id FROM FormulaShare_Log__c WHERE Method_Name__c = 'allShares'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares1 = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log1.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND Type = 'Role'][0];
        Group roleGroup2 = [SELECT Id FROM Group WHERE RelatedId = :role2.Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :role.Id AND (Type = 'RoleAndSubordinates' OR Type = 'RoleAndSubordinatesInternal') ORDER BY Type Desc][0];
        Id userId = UserInfo.getUserId();
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundRoleShare1 = false;
        Boolean foundRoleSubordinatesShare1 = false;
        Boolean foundUserShare1 = false;
        Boolean foundGroupShare1 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares1) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundRoleShare1 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare1 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare1 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare1 = true;
        }
        System.assert(!foundRoleShare1);
        System.assert(!foundRoleSubordinatesShare1);
        System.assert(!foundGroupShare1);


        // Find a record which should have had sharing updated
        FormulaShare_Log__c log2 = [SELECT Id, Failed_Batches__c, Method_Name__c, Type_In_Scope__c, Exception_Type__c FROM FormulaShare_Log__c WHERE Method_Name__c = 'twoShares'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares2 = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log2.Id];

        Boolean foundRoleShare2 = false;
        Boolean foundRoleSubordinatesShare2 = false;
        Boolean foundUserShare2 = false;
        Boolean foundGroupShare2 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares2) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup2.Id) foundRoleShare2 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare2 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare2 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare2 = true;
        }
        System.assert(foundRoleShare2);
        System.assert(!foundRoleSubordinatesShare2);
        System.assert(foundGroupShare2);


        // Find a record which should have had sharing added
        FormulaShare_Log__c log3 = [SELECT Id FROM FormulaShare_Log__c WHERE Method_Name__c = 'oneShare'][0];

        // Retrieve share records for this log 
        List<FormulaShare_Log__Share> shares3 = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log3.Id];

        Boolean foundRoleShare3 = false;
        Boolean foundRoleSubordinatesShare3 = false;
        Boolean foundUserShare3 = false;
        Boolean foundGroupShare3 = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares3) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundRoleShare3 = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundRoleSubordinatesShare3 = true;
        else if  (share.UserOrGroupId == userId) foundUserShare3 = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundGroupShare3 = true;
        }
        System.assert(!foundRoleShare3);
        System.assert(foundRoleSubordinatesShare3);
        System.assert(foundGroupShare3);
    }

}