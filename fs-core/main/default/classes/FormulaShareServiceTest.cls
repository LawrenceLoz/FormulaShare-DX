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

        List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole 
        WHERE DeveloperName LIKE 'TestRoleFormulaShare%' 
        ORDER BY DeveloperName LIMIT 3];

        // Create contact and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Context__c = 'testing';  // Share with role (name)
        log.Class_Name__c = roles[0].DeveloperName;  // Share with role (name)
        log.Method_Name__c = roles[0].Id;        // Share with role and subordinates (Id)
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        //con.AssistantName = UserInfo.getUserId();  // Share with user (Id)
        insert log;

        // Call recalculate method to set sharing
        test.startTest();
        FormulaShareService.recalculateAll();
        test.stopTest();

        // Retrieve share records for the inserted contact
        List<FormulaShare_Log__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM FormulaShare_Log__Share WHERE ParentId = :log.Id];

        // Get relevant ids we expect to be in share records
        Group roleGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[0].Id AND Type = 'Role'][0];
        Group roleSubordinatesGroup = [SELECT Id FROM Group WHERE RelatedId = :roles[0].Id AND Type = 'RoleAndSubordinates'][0];
//        Id userId = UserInfo.getUserId();
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];

        Boolean foundCorrectRoleShare = false;
        Boolean foundCorrectRoleSubordinatesShare = false;
        Boolean foundCorrectUserShare = false;
        Boolean foundCorrectGroupShare = false;

        // Check that all expected sharing was applied
        for(FormulaShare_Log__Share share : shares) {
        if    (share.UserOrGroupId == roleGroup.Id) foundCorrectRoleShare = true;
        else if  (share.UserOrGroupId == roleSubordinatesGroup.Id) foundCorrectRoleSubordinatesShare = true;
//        else if  (share.UserOrGroupId == userId) foundCorrectUserShare = true;
        else if  (share.UserOrGroupId == publicGroup.Id) foundCorrectGroupShare = true;
        }
        System.assert(foundCorrectRoleShare);
        System.assert(foundCorrectRoleSubordinatesShare);
        System.assert(foundCorrectUserShare);
        System.assert(foundCorrectGroupShare);
    }


}