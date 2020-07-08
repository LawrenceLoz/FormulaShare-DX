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
    public static void submitForCreate(String fsRuleString){
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);
        rule.Active__c = true;      // Create all new rules as active

        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);

        FormulaShareRulesMetadataDMLService.createRules(ruleMap, 'edit');
    }

    @AuraEnabled
    public static void submitForEdit(String fsRuleString) {
        FormulaShare_Rule__mdt rule = ruleStringToRule(fsRuleString);

        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);

        FormulaShareRulesMetadataDMLService.updateRules(ruleMap, 'edit');
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

//        String ruleLabel":"Share Programmes to Donation Owner","ruleName":"Share_Programmes_to_Donation_Owner","ruleActive":false,"sharedObjectApiName":"Programme__c","sharedObject":{"detailUrl":"/{ID}","externalSharingModel":"Private","internalSharingModel":"Read","isCustom":true,"objectApiName":"Programme__c","objectId":"01I7E000000wZvu","objectLabel":"Programme","pluralLabel":"Programmes"},"ruleType":"child","relatedObjectSelected":"Donation__c&#124;Programme_to_Support__c","shareField":"OwnerId","shareWith":"Users","shareFieldType":"Id","accessLevel":"Edit","sharingReason":"Owner_of_Donations__c"}
    private class ComponentRule {
        String ruleLabel;
        String ruleName;
        String ruleDescription;
        Boolean ruleActive;
        String sharedObjectApiName;
        ComponentSharedObject sharedObject;
        String ruleType;
        String relatedObjectSelected;
        String shareField;
        String shareWith;
        String shareFieldType;
        String accessLevel;
        String sharingReason;
    }

    private class ComponentSharedObject {
        String detailUrl;
        String externalSharingModel;
        String internalSharingModel;
        Boolean isCustom;
        String objectApiName;
        String objectId;
        String objectLabel;
        String pluralLabel;
    }
}
