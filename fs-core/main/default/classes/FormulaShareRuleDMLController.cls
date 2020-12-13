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
        rule.DeveloperName = cr.developerName;
        rule.MasterLabel = cr.label;
        rule.Description__c = cr.ruleDescription;

        rule.Object_Shared__c = cr.objectSharedAPIName;

        rule.Share_With__c = cr.shareWith;
        rule.Access_Level__c = cr.accessLevel;
        rule.Contact_Access__c = cr.contactAccess;
        rule.Case_Access__c = cr.caseAccess;
        rule.Opportunity_Access__c = cr.opportunityAccess;
        rule.Sharing_Reason__c = cr.sharingReason;

        rule = cr.relationship.mapRelationshipToMetadataRule(rule);

        // Populate appropriate shared to type field depending on whether field is on shared object or related object
        if(rule.Child_Object_with_Shared_To_Field__c == null) {
            rule.Shared_To_Field_Type__c = cr.controllingObjectSharedToFieldType;
        }
        else {
            rule.Child_Object_Shared_To_Field_Type__c = cr.controllingObjectSharedToFieldType;
        }

        return rule;
    }

    @TestVisible
    private class ComponentRule {
        @TestVisible Boolean active;

        @TestVisible String developerName;
        @TestVisible String label;
        @TestVisible String ruleDescription;

        @TestVisible String objectSharedAPIName;
        @TestVisible FormulaShareSObjectRelationship relationship;
        @TestVisible String controllingObjectSharedToFieldType;
//        @TestVisible ComponentSharedObject sharedObject;
//        @TestVisible String ruleType;
//        @TestVisible String controllingObjectSharedToFieldAPIName;

        @TestVisible String shareWith;
        @TestVisible String accessLevel;
        @TestVisible String contactAccess;
        @TestVisible String caseAccess;
        @TestVisible String opportunityAccess;
        @TestVisible String sharingReason;

    }




//        controllingObjectApiName : "sdfs__Programme_Support_Officer__c"
//        controllingObjectLabel : "Programme Support Officer"
//        controllingObjectSharedToFieldAPIName : "sdfs__User__c"
//        controllingObjectSharedToFieldLabel : "User"
//        controllingObjectSharedToFieldToken : "01I7E000001TzGu.00N7E00000DpnCc"
//        controllingObjectSharedToFieldType


//accessLevel : "Read"
//active : true
//caseAccess : "None"
//contactAccess : "None"
//controllingObjectApiName : "sdfs__Programme_Support_Officer__c"
//controllingObjectLabel : "Programme Support Officer"
//controllingObjectSharedToFieldAPIName : "sdfs__User__c"
//controllingObjectSharedToFieldLabel : "User"
//controllingObjectSharedToFieldToken : "01I7E000001TzGu.00N7E00000DpnCc"
//developerName : "Share_Donations_with_External_Role"
//label : "Share Donations with External Role"
//objectSharedAPIName : "sdfs__Donation__c"
//objectSharedLabel : "Donation"
//opportunityAccess : "None"
//relationship
//nextRelationship
//thisObjectApiName : "sdfs__Donation__c"
//thisObjectLabel : "Donation"
//ruleId : "m007E0000002whiQAA"
//shareWith : "Roles, Internal and Portal Subordinates"
//sharingReason : "sdfs__External_roles__c"
//type : "sibling"

//    @TestVisible
//    private class ComponentSharedObject {
//        @TestVisible String detailUrl;
//        @TestVisible String externalSharingModel;
//        @TestVisible String internalSharingModel;
//        @TestVisible Boolean isCustom;
//        @TestVisible String objectApiName;
//        @TestVisible String objectId;
//        @TestVisible String objectLabel;
//        @TestVisible String pluralLabel;
//    }
}
