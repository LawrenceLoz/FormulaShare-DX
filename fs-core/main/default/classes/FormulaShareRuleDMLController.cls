/**
*Copyright 2020 Lawrence Newcombe
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

public with sharing class FormulaShareRuleDMLController {

    // Called by relevant LWC components to trigger DML
    @AuraEnabled
    public static Id submitForCreate(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        FormulaShareMetadataDMLRules dmlService = rule.Object_Shared__c == 'Account' ? new FormulaShareMetadataDMLRules() : new FormulaShareMetadataDMLRulesAccount();
        Id jobId = createRule(rule, dmlService);
        return jobId;
    }
    @AuraEnabled
    public static Id submitForEdit(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        FormulaShareMetadataDMLRules dmlService = rule.Object_Shared__c == 'Account' ? new FormulaShareMetadataDMLRules() : new FormulaShareMetadataDMLRulesAccount();
        Id jobId = editRule(rule, dmlService);
        return jobId;
    }

    // Separated to allow injecting a mock
    @TestVisible
    private static Id createRule(FormulaShare_Rule__mdt rule, FormulaShareMetadataDMLRules dmlService) {
        rule.Active__c = true;      // Create all new rules as active
        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);
        Id jobId = dmlService.submitCreate(ruleMap);
        return jobId;
    }

    @TestVisible
    private static Id editRule(FormulaShare_Rule__mdt rule, FormulaShareMetadataDMLRules dmlService) {
        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);
        Id jobId = dmlService.submitEdit(ruleMap);
        return jobId;
    }

    // Deserialise JSON from create/edit and map to rule metadata object
    @TestVisible
    private static FormulaShare_Rule__mdt ruleStringToRule(String fsRuleString) {

        FormulaShareRule rule = (FormulaShareRule) JSON.deserialize(fsRuleString, FormulaShareRule.class);

        FormulaShare_Rule__mdt mdRule = rule.transformRuleToMetadataRule();
        return mdRule;
    }

}
