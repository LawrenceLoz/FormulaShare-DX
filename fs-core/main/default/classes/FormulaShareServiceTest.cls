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

@isTest
public class FormulaShareServiceTest {

//  public static List<FormulaShare_Rule__mdt> rules = new List<FormulaShare_Rule__mdt>();
//	public static List<FormulaShareService.FSRule> fsRulePrims = new List<FormulaShareService.FSRule>();

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
    }

    @isTest
    public static void testInsertSharing() {
//        FormulaShareService.executingFSTestClass = true;

/*
        // Given
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) mocks.mock(FormulaShareRulesSelector.class);
        mocks.startStubbing();
        mocks.when(mockFSRulesSelector.selectRules('FormulaShare_Log__c')).thenReturn(rules);
        mocks.stopStubbing();
        FormulaShareApplication.Selector.setMock(mockFSRulesSelector);
*/

        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;

        // When
        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole 
            WHERE DeveloperName LIKE 'TestRoleFormulaShare%' 
            ORDER BY DeveloperName LIMIT 3];

        // Create log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = roles[0].DeveloperName;  // Share with role and subordinates (name)
        log.Class_Name__c = roles[0].Id;  // Share with role (id)
//        log.Method_Name__c = ;        // Test with a user id?
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        //con.AssistantName = UserInfo.getUserId();  // Share with user (Id)
        insert log;

        Schema.SObjectType fsLogType = Schema.getGlobalDescribe().get('FormulaShare_Log__c');
        List<FormulaShareService.FSRule> fsRules = FormulaShareRulesSelector.construct().getRulesSharingObject(fsLogType);
        system.debug('**** rules from selector: '+fsRules);

		FormulaShareService.FormulaShareWrapper fsWrapper = new FormulaShareService.FormulaShareWrapper(fsLogType, fsRules);
		// Populate records in batch scope into wrapper
		fsWrapper.recordsMap.put(log.Id, log);
		FormulaShareService.processFormulaShares(fsWrapper);

        // Call recalculate method to set sharing
//        test.startTest();
//        FormulaShareService.recalculateAll();
//        test.stopTest();

        // Retrieve share records for the inserted log
        List<FormulaShare_Log__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[0].Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[0].Id AND Type = 'RoleAndSubordinates'][0];
//        Id userId = UserInfo.getUserId();
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundCorrectRoleShare = false;
        Boolean foundCorrectRoleSubordinatesShare = false;
//        Boolean foundCorrectUserShare = false;
        Boolean foundCorrectGroupShare = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares) {
            system.debug('this share: '+share);
        if    (share.UserOrGroupId == roleGroup.Id) foundCorrectRoleShare = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundCorrectRoleSubordinatesShare = true;
//        else if  (share.UserOrGroupId == userId) foundCorrectUserShare = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundCorrectGroupShare = true;
        }
        System.assert(foundCorrectRoleShare);
        System.assert(foundCorrectRoleSubordinatesShare);
//        System.assert(foundCorrectUserShare);
        System.assert(foundCorrectGroupShare);
    }


}