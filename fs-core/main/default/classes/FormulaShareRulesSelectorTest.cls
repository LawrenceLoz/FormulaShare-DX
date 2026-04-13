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


    @IsTest
    public static void testSelectObjectsWithRulesNoSecurity() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            // enforceSecurity = false branch — queries without SECURITY_ENFORCED
            Map<String,String> result = selector.selectObjectsWithRules(false);
            // Result may be empty if no rules configured; just verify no exception
            System.assertNotEquals(null, result, 'selectObjectsWithRules(false) should return a non-null map');
        }
    }


    @IsTest
    public static void testGetRulesSharingObjectByStringDirect() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // getRulesSharingObject(String) — direct query path
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            List<FormulaShareRule> rules = selector.getRulesSharingObject('FormulaShare_Log__c');

            List<FormulaShare_Rule__mdt> rulesByQuery = [
                SELECT Id FROM FormulaShare_Rule__mdt
                WHERE Object_Shared__r.QualifiedApiName = 'FormulaShare_Log__c'];

            System.assertEquals(rulesByQuery.size(), rules.size(),
                'getRulesSharingObject(String) should return the same count as direct SOQL');
        }
    }


    @IsTest
    public static void testGetSpecificRulesSharingObject() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // getSpecificRulesSharingObject — pass an empty ruleNames set so it returns empty
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            Map<String,Object> bindParams = new Map<String,Object>{
                'objectName' => 'FormulaShare_Log__c',
                'ruleNames' => new Set<String>()
            };
            List<FormulaShareRule> rules = selector.getSpecificRulesSharingObject(bindParams);
            System.assertNotEquals(null, rules, 'Result should be a non-null list');
            System.assertEquals(0, rules.size(), 'Empty ruleNames set should return empty list');
        }
    }


    @IsTest
    public static void testGetRulesExceptSpecificRulesSharingObject() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // getRulesExceptSpecificRulesSharingObject — exclude a non-existent name so all rules pass through
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            Map<String,Object> bindParams = new Map<String,Object>{
                'objectName' => 'FormulaShare_Log__c',
                'ruleNames' => new Set<String>{ 'NonExistentRule__x' }
            };
            List<FormulaShareRule> rules = selector.getRulesExceptSpecificRulesSharingObject(bindParams);
            System.assertNotEquals(null, rules, 'Result should be a non-null list');
        }
    }


    @IsTest
    public static void testGetRulesWithSharingReason() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
            Map<String,Object> bindParams = new Map<String,Object>{
                'reasonName' => 'NonExistentReason__c',
                'thisRuleName' => 'Self'
            };
            List<FormulaShare_Rule__mdt> result = selector.getRulesWithSharingReason(bindParams);
            System.assertNotEquals(null, result, 'Result should be a non-null list');
            System.assertEquals(0, result.size(), 'No rules expected for a non-existent sharing reason');
        }
    }


    @IsTest
    public static void testIsStandardAndCrossObjectActivationDisabled() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRulesSelector selector = new FormulaShareRulesSelector();
            System.assertEquals(false, selector.isStandardActivationDisabled(),
                'Base class should return false for isStandardActivationDisabled');
            System.assertEquals(false, selector.isCrossObjectActivationDisabled(),
                'Base class should return false for isCrossObjectActivationDisabled');
        }
    }

}
