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

        // You can use the method name and return type to determine which method was called.
        System.debug('Name of stubbed method: ' + stubbedMethodName);
        System.debug('Return type of stubbed method: ' + returnType.getName());
        
        for (integer i =0; i < listOfParamNames.size(); i++) {
            System.debug('parameter name: ' + listOfParamNames.get(i));
            System.debug('  parameter type: ' + listOfParamTypes.get(i).getName());
        }
        
        // This shows the actual parameter values passed into the stubbed method at runtime.
        System.debug('number of parameters passed into the mocked call: ' + 
            listOfArgs.size());
        System.debug('parameter(s) sent into the mocked call: ' + listOfArgs);
        

        // FormulaShareSettingsSelector.selectActiveSettings() mock
        if (stubbedMethodName == 'selectActiveSettings' && returnType.getName() == 'FormulaShare_Settings__mdt') {
            FormulaShare_Settings__mdt settings = new FormulaShare_Settings__mdt();
            settings.DeveloperName = 'Mocked Settings';
            settings.Recalculation_Batch_Size__c = 100;
            settings.Remove_Shares_for_Standard_Objects__c = true;
            return settings;
        }

        if (stubbedMethodName == 'getRulesSharingObject') {
            List<FormulaShareService.FSRule> rules = new List<FormulaShareService.FSRule>();

            FormulaShareService.FSRule roleSubRule = new FormulaShareService.FSRule();
            roleSubRule.objectSharedAPIName = 'FormulaShare_Log__c';
            roleSubRule.sharingReason = 'FormulaShare_Log_Share__c';
            roleSubRule.active = true;
            roleSubRule.sharedToFieldType = 'Name';
            roleSubRule.accessLevel = 'Read';
            roleSubRule.sharedToAPIName = 'Context__c';
            roleSubRule.shareWith = 'Roles and Internal Subordinates';
            rules.add(roleSubRule);

            FormulaShareService.FSRule roleRule = new FormulaShareService.FSRule();
            roleRule.objectSharedAPIName = 'FormulaShare_Log__c';
            roleRule.sharingReason = 'FormulaShare_Log_Share__c';
//            roleRule.sharingReason = 'FormulaShare_Roles_Test__c';
            roleRule.active = true;
            roleRule.sharedToFieldType = 'Id';
            roleRule.accessLevel = 'Edit';
            roleRule.sharedToAPIName = 'Class_Name__c';
            roleRule.shareWith = 'Roles';
            rules.add(roleRule);

            FormulaShareService.FSRule groupRule = new FormulaShareService.FSRule();
            groupRule.objectSharedAPIName = 'FormulaShare_Log__c';
//            groupRule.sharingReason = 'FormulaShare_Groups_Test__c';
            groupRule.sharingReason = 'FormulaShare_Log_Share__c';
            groupRule.active = true;
            groupRule.sharedToFieldType = 'Name';
            groupRule.accessLevel = 'Edit';
            groupRule.sharedToAPIName = 'Type_In_Scope__c';
            groupRule.shareWith = 'Public Groups';
            rules.add(groupRule);

            return rules;
        }

        if (stubbedMethodName == 'selectObjectsWithRules') {
            List<String> objNames = new List<String>();
            objNames.add('FormulaShare_Log__c');
            return objNames;
        }

        else return null;
    }
}