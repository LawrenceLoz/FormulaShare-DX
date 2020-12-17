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
    public static Id submitForCreate(String fsRuleString){
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        rule.Active__c = true;      // Create all new rules as active

        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);

        Id jobId = FormulaShareRulesMetadataDMLService.construct().submitForDml(ruleMap, 'create');
        return jobId;
    }

    @AuraEnabled
    public static Id submitForEdit(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);

        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);

        Id jobId = FormulaShareRulesMetadataDMLService.construct().submitForDml(ruleMap, 'edit');
        return jobId;
    }


    // Deserialise JSON from create/edit and map to rule metadata object
    @TestVisible
    private static FormulaShare_Rule__mdt ruleStringToRule(String fsRuleString) {

        FormulaShareRule rule = (FormulaShareRule) JSON.deserialize(fsRuleString, FormulaShareRule.class);

        FormulaShare_Rule__mdt mdRule = rule.transformRuleToMetadataRule();
        return mdRule;
    }


//    // To deseriarlise rule object received from create/edit component
//    @TestVisible
//    private class ComponentRule {
//        @TestVisible String developerName;
//        @TestVisible String label;
//        @TestVisible String ruleDescription;
//
//        @TestVisible String objectSharedAPIName;
//        @TestVisible FormulaShareSObjectRelationship relationship;
//        @TestVisible String controllingObjectSharedToFieldType;
//
//        @TestVisible String shareWith;
//        @TestVisible String accessLevel;
//        @TestVisible String contactAccess;
//        @TestVisible String caseAccess;
//        @TestVisible String opportunityAccess;
//        @TestVisible String sharingReason;
//    }
    
}
