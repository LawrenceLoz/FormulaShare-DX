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
public inherited sharing class FormulaShareMockProvider implements System.StubProvider {
    
    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        // You can use the method name and return type to determine which method was called.
        System.debug('Name of stubbed method: ' + stubbedMethodName);
        System.debug('Return type of stubbed method: ' + returnType.getName());
        
        for (integer i =0; i < listOfParamNames.size(); i++) {
            System.debug('parameter name: ' + listOfParamNames.get(i));
            System.debug('parameter type: ' + listOfParamTypes.get(i).getName());
        }
        
        // This shows the actual parameter values passed into the stubbed method at runtime.
        System.debug('number of parameters passed into the mocked call: ' + 
            listOfArgs.size());
        System.debug('parameter(s) sent into the mocked call: ' + listOfArgs);
        

        // -------------------------- FormulaShareSettingsSelector Mocks ----------------------------- //

        if(stubbedMethodName == 'selectActiveSettings' && returnType.getName() == prefix + 'FormulaShare_Settings__mdt') {
            FormulaShare_Settings__mdt settings = new FormulaShare_Settings__mdt();
            settings.DeveloperName = 'Mocked Settings';
            settings.Recalculation_Batch_Size__c = 200;
            return settings;
        }

        // -------------------------- FormulaShareRulesSelector Mocks ----------------------------- //

        else if(stubbedMethodName == 'getRulesSharingObject') {
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            // Will add a sharing record for the role and subordinates group for the role name in Context__c field
            FormulaShareRule roleSubRule = new FormulaShareRule();
            roleSubRule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
            roleSubRule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
            roleSubRule.active = true;
            roleSubRule.sharedToFieldType = 'Name';
            roleSubRule.accessLevel = 'Read';
            roleSubRule.sharedToAPIName = prefix + 'Context__c';
            roleSubRule.shareWith = 'Roles and Internal Subordinates';
            rules.add(roleSubRule);

            // Will add a sharing record for the role group for the role id in Class_Name__c field
            FormulaShareRule roleRule = new FormulaShareRule();
            roleRule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
            roleRule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
            roleRule.active = true;
            roleRule.sharedToFieldType = 'Id';
            roleRule.accessLevel = 'Edit';
            roleRule.sharedToAPIName = prefix + 'Class_Name__c';
            roleRule.shareWith = 'Roles';
            rules.add(roleRule);

            // Will add a sharing record for the public group with the group name in Type_In_Scope__c field
            FormulaShareRule groupRule = new FormulaShareRule();
            groupRule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
            groupRule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
            groupRule.active = true;
            groupRule.sharedToFieldType = 'Name';
            groupRule.accessLevel = 'Edit';
            groupRule.sharedToAPIName = prefix + 'Type_In_Scope__c';
            groupRule.shareWith = 'Public Groups';
            rules.add(groupRule);

            // Will add a sharing record for the user with the user id in Method_Name__c field
            FormulaShareRule userRule = new FormulaShareRule();
            userRule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
            userRule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
            userRule.active = true;
            userRule.sharedToFieldType = 'Id';
            userRule.accessLevel = 'Edit';
            userRule.sharedToAPIName = prefix + 'Method_Name__c';
            userRule.shareWith = 'Users';
            rules.add(userRule);

            return rules;
        }

        else if(stubbedMethodName == 'selectObjectsWithRules') {
            List<String> objNames = new List<String>();
            objNames.add(prefix + 'FormulaShare_Log__c');
            return objNames;
        }

        // -------------------------- FormulaShareUtilities Mocks ----------------------------- //

        else if(stubbedMethodName == 'get15CharacterIdInstance') {
            return '123';    // Return a string (only used as a string key by mocked method)
        }

        // -------------------------- FormulaShareService Mocks ----------------------------- //

        else if(stubbedMethodName == 'processFormulaShares') {
            return null;    // No return type, but carry out no processing
        }

        else if(stubbedMethodName == 'getRules') {
            system.debug('getRules stub');
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

           // Will add a sharing record for the public group with the group name in Type_In_Scope__c field
            FormulaShareRule groupRule = new FormulaShareRule();
            groupRule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
            groupRule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
            groupRule.active = true;
            groupRule.sharedToFieldType = 'Name';
            groupRule.accessLevel = 'Edit';
            groupRule.sharedToAPIName = prefix + 'Type_In_Scope__c';
            groupRule.shareWith = 'Public Groups';
            rules.add(groupRule);

            return rules;
        }

        else if(stubbedMethodName == 'getSharesToInsert') {
            List<FormulaShare_Log__Share> shares = new List<FormulaShare_Log__Share>();

            // Insert log object against which a share record could be inserted
//            FormulaShare_Log__c log = new FormulaShare_Log__c();
//            log.Exception_Type__c = 'log with share to insert';  // So we can identify in test class
//            insert log;

            // Create sharing table record
            FormulaShare_Log__Share share = new FormulaShare_Log__Share();
            share.AccessLevel = 'Edit';
//            share.ParentId = log.Id;
            share.ParentId = UserInfo.getUserId();      // Any valid id is fine
            share.UserOrGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0].Id;
            share.RowCause = prefix + 'FormulaShare_Log_Share__c';
            shares.add(share);

            return shares;
        }

        else if(stubbedMethodName == 'getSharesToDelete') {
            List<FormulaShare_Log__Share> shares = new List<FormulaShare_Log__Share>();

            // Insert log object which we'll create a share record for
//            FormulaShare_Log__c log = new FormulaShare_Log__c();
//            log.Exception_Type__c = 'log with share to delete';  // So we can identify in test class
//            insert log;

            // Create sharing table record linked to this log
            FormulaShare_Log__Share share = new FormulaShare_Log__Share();
            share.AccessLevel = 'Read';
//            share.ParentId = log.Id;
            share.ParentId = UserInfo.getUserId();      // Any valid id is fine
            share.UserOrGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0].Id;
            share.RowCause = prefix + 'FormulaShare_Log_Share__c';

            // Insert share so it can be deleted by calling methods
//            insert share;

            shares.add(share);
            return shares;
        }

        else if(stubbedMethodName == 'getFullObjectQueryLocator') {
            String query = 'SELECT '
                + prefix + 'Id, '
                + prefix + 'Context__c, '
                + prefix + 'Class_Name__c, '
                + prefix + 'Type_In_Scope, '
                + prefix + 'Method_Name__c '
                + 'FROM '
                + prefix + 'FormulaShare_Log__c';
            Database.QueryLocator locator = Database.getQueryLocator(query);
            return locator;
        }

        else if(stubbedMethodName == 'getType') {
            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            return fsLogType;
        }

        // -------------------------- FormulaShareService Mocks ----------------------------- //

        else if(stubbedMethodName == 'insertShares') {
            return null;
        }

        else if(stubbedMethodName == 'deleteShares') {
            return null;
        }


        else return null;
    }
}