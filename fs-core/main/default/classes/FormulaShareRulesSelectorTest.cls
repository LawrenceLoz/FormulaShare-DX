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
public with sharing class FormulaShareRulesSelectorTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }
    

    @IsTest
    public static void testGetRulesSharingObjectByType() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            selector.isUnitTest = true;
            Schema.SObjectType fsLogShareType = FormulaShare_Log__Share.SObjectType;

            List<FormulaShareRule> rules = selector.getRulesSharingObject(fsLogShareType);
            System.assertEquals('Test reason', rules[0].sharingReason);
        }
    }

    @IsTest
    public static void testGetRulesSharingObjectByString() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            List<FormulaShareRule> rules = selector.getStandardAndAncestorRulesSharingObject('FormulaShare_Log__c');

            // We won't know and can't guarantee rules exist or not, so verify for both cases
            List<FormulaShare_Rule__mdt> rulesByQuery = [
                SELECT Id FROM FormulaShare_Rule__mdt 
                WHERE Object_Shared__r.QualifiedApiName = 'FormulaShare_Log__c'];

            System.assertEquals(rulesByQuery.size(), rules.size(), 'Method should return the number of rules sharing log records');
        }
    }

    @IsTest
    public static void testGetAllRules() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            List<FormulaShareRule> rules = selector.getAllRules();

            // We won't know and can't guarantee rules exist or not, so verify for both cases
            List<FormulaShare_Rule__mdt> rulesByQuery = [
                SELECT Id FROM FormulaShare_Rule__mdt 
                WHERE Object_Shared__c != null];

            System.assertEquals(rulesByQuery.size(), rules.size(), 'Method should return the total number of rules in the org');
        }
    }


    @IsTest
    public static void testGetAllRulesWithSecurityEnforced() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            List<FormulaShareRule> rules = selector.getAllRulesWithSecurityEnforced();

            // We won't know and can't guarantee rules exist or not, so verify for both cases
            List<FormulaShare_Rule__mdt> rulesByQuery = [
                SELECT Id FROM FormulaShare_Rule__mdt 
                WHERE Object_Shared__c != null];

            System.assertEquals(rulesByQuery.size(), rules.size(), 'Method should return the total number of rules in the org');
        }
    }

    @IsTest
    public static void testGetSpecificRule() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // We can't guarantee any rules are set up in the org, so this is a negative test only
            Id wrongId = UserInfo.getUserId();

            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            FormulaShareRule rule = selector.getSpecificRule(wrongId);

            System.assertEquals(null, rule, 'Expected no rule for this id');
        }
    }

    @IsTest
    public static void testSelectObjectsWithRules() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            selector.isUnitTest = true;

            Set<String> objectsWithRules = selector.selectObjectsWithRules(true).keySet();
            System.assert(objectsWithRules.contains('Test object'));
        }
    }

}
