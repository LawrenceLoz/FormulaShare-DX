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

    private static FormulaShare_Rule__mdt ruleStringToRule(String fsRuleString) {

        ComponentRule cr = (ComponentRule) JSON.deserialize(fsRuleString, ComponentRule.class);

        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();
        rule.DeveloperName = cr.ruleName;
        rule.MasterLabel = cr.ruleLabel;
        rule.Description__c = cr.ruleDescription;
        rule.Share_With__c = cr.shareWith;
        rule.Access_Level__c = cr.accessLevel;
        rule.Sharing_Reason__c = cr.sharingReason;
        rule.Object_Shared__c = cr.sharedObject.objectApiName;

        if(cr.ruleType == 'standard') {
            rule.Shared_To__c = cr.shareField;
            rule.Shared_To_Field_Type__c = cr.shareFieldType;
        }

        if(cr.ruleType == 'child') {
            system.debug('cr.relatedObjectSelected : '+cr.relatedObjectSelected);
            rule.Child_Object_with_Shared_To_Field__c = cr.relatedObjectSelected.substringBefore('|');
            rule.Child_Object_Lookup_Field__c = cr.relatedObjectSelected.substringAfter('|');
            rule.Child_Object_Shared_To_Field__c = cr.shareField;
            rule.Child_Object_Shared_To_Field_Type__c = cr.shareFieldType;
        }

        return rule;
    }

    @TestVisible
    private class ComponentRule {
        @TestVisible String ruleLabel;
        @TestVisible String ruleName;
        @TestVisible String ruleDescription;
        @TestVisible Boolean ruleActive;
        @TestVisible String sharedObjectApiName;
        @TestVisible ComponentSharedObject sharedObject;
        @TestVisible String ruleType;
        @TestVisible String relatedObjectSelected;
        @TestVisible String shareField;
        @TestVisible String shareWith;
        @TestVisible String shareFieldType;
        @TestVisible String accessLevel;
        @TestVisible String sharingReason;
    }

    @TestVisible
    private class ComponentSharedObject {
        @TestVisible String detailUrl;
        @TestVisible String externalSharingModel;
        @TestVisible String internalSharingModel;
        @TestVisible Boolean isCustom;
        @TestVisible String objectApiName;
        @TestVisible String objectId;
        @TestVisible String objectLabel;
        @TestVisible String pluralLabel;
    }
}
