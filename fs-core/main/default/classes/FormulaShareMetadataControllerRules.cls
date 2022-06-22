/**
*Copyright 2022 Lawrence Newcombe
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

public with sharing class FormulaShareMetadataControllerRules {

    @TestVisible
    private static FormulaShareMetadataDMLBase mockDmlService;

    // This is a little ugly beacuse @AuraEnabled must be static and we can't send objects as parameters
    @TestVisible
    private static FormulaShareMetadataDMLBase getRulesDml(FormulaShare_Rule__mdt rule) {
        if(Test.isRunningTest() && mockDmlService != null ) {
            return mockDmlService;
        }
        else {
            // Use the account implementation if the submitted (new) version of the rule shares accounts
            System.debug('Shared object: '+rule.Object_Shared__c);
            return rule.Object_Shared__c == 'Account' ? new FormulaShareMetadataDMLRulesAccount() : new FormulaShareMetadataDMLRules();
        }
    }

    // Called by relevant LWC components to trigger DML
    @AuraEnabled
    public static Id submitForCreate(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        rule.Active__c = true;      // Create all new rules as active
        Map<String,SObject> ruleMap = FormulaShareUtilities.cmdtToCmdtMap(rule);

        FormulaShareMetadataDMLBase dmlService = getRulesDml(rule);

        Id jobId = dmlService.submitCreate(ruleMap);
        return jobId;
    }

    @AuraEnabled
    public static Id submitForEdit(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        Map<String,SObject> ruleMap = FormulaShareUtilities.cmdtToCmdtMap(rule);

        FormulaShareMetadataDMLBase dmlService = getRulesDml(rule);
        
        Id jobId = dmlService.submitEdit(ruleMap);
        return jobId;
    }


    // We won't have full metadata information when activate is called from the list view, so just submit a
    // rule map with an otherwise blank rule with active set to the right value
    @AuraEnabled
    public static void activateDeactivate(String ruleName, String type) {
        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();
        rule.Active__c = type == 'activate' ? true : false;
        rule.DeveloperName = ruleName;
        Map<String,SObject> ruleMap = FormulaShareUtilities.cmdtToCmdtMap(rule);

        Map<String,FormulaShare_Rule__mdt> fsRulesMap = new Map<String,FormulaShare_Rule__mdt>();

        // Inject mock if we're running in test context and it's populated
        FormulaShareMetadataDMLBase dmlService = Test.isRunningTest() && mockDmlService != null ? mockDmlService : new FormulaShareMetadataDMLRulesActivate();

        Id jobId = dmlService.submitEdit(ruleMap);
    }


    // Deserialise JSON from create/edit and map to rule metadata object
    @TestVisible
    private static FormulaShare_Rule__mdt ruleStringToRule(String fsRuleString) {

        FormulaShareRule rule = (FormulaShareRule) JSON.deserialize(fsRuleString, FormulaShareRule.class);
        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt mdRule = ruleConverter.getMetadataRule(rule);

        return mdRule;
    }

}
