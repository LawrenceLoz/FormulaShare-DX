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

// Note that fflib selector pattern isn't used because it fails for metadata relationship fields.
// FLS and sharing checks aren't needed since custom metadata does not support either.

public inherited sharing class FormulaShareRulesSelector {

    public static FormulaShareRulesSelector mock;
    public static FormulaShareRulesSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            system.debug('Mock requested: '+mock);
            return mock;
        }
        else {
            return new FormulaShareRulesSelector();
        }
    }
    @TestVisible Boolean isUnitTest = false;


    static String allFieldsForSelect;
    private static String getAllFieldsForSelect() {

        // If selected fields string hasn't been prepared already, set this now
        if(allFieldsForSelect == null) {
            List<String> fieldNames = new List<String>{
                'Id',
                'MasterLabel',
                'DeveloperName',

                'Active__c',
                'Description__c',

                'Access_Level__c',
                'Case_Access__c',
                'Contact_Access__c',
                'Opportunity_Access__c',
                'Share_With__c',
                'Sharing_Reason__c',
                'Child_Object_Shared_To_Field_Type__c',
                'Shared_To_Field_Type__c',

                'Object_Shared__c',
                'Object_Shared__r.QualifiedApiName',
                'Object_Shared__r.MasterLabel',
                'Shared_To__c',
                'Shared_To__r.QualifiedApiName',
                'Shared_To__r.MasterLabel',

                'Child_Object_with_Shared_To_Field__c',
                'Child_Object_with_Shared_To_Field__r.QualifiedApiName',
                'Child_Object_with_Shared_To_Field__r.MasterLabel',
                'Child_Object_Lookup_Field__c',
                'Child_Object_Lookup_Field__r.QualifiedApiName',
                'Related_Object_1_Lookup_from_Shared_Obj__c',
                'Related_Object_1_Lookup_from_Shared_Obj__r.QualifiedApiName',
                'Child_Object_Shared_To_Field__c',
                'Child_Object_Shared_To_Field__r.QualifiedApiName',
                'Child_Object_Shared_To_Field__r.MasterLabel',

                'Related_Object_2__c',
                'Related_Object_2__r.QualifiedApiName',
                'Related_Object_2__r.MasterLabel',
                'Related_Object_2_Lookup_from_RO1__c',
                'Related_Object_2_Lookup_from_RO1__r.QualifiedApiName',
                'Related_Object_2_Lookup_to_RO1__c',
                'Related_Object_2_Lookup_to_RO1__r.QualifiedApiName',
                'Related_Object_2_Shared_To_Field__c',
                'Related_Object_2_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_2_Shared_To_Field__r.MasterLabel',

                'Related_Object_3__c',
                'Related_Object_3__r.QualifiedApiName',
                'Related_Object_3__r.MasterLabel',
                'Related_Object_3_Lookup_from_RO2__c',
                'Related_Object_3_Lookup_from_RO2__r.QualifiedApiName',
                'Related_Object_3_Lookup_to_RO2__c',
                'Related_Object_3_Lookup_to_RO2__r.QualifiedApiName',
                'Related_Object_3_Shared_To_Field__c',
                'Related_Object_3_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_3_Shared_To_Field__r.MasterLabel',

                'Related_Object_4__c',
                'Related_Object_4__r.QualifiedApiName',
                'Related_Object_4__r.MasterLabel',
                'Related_Object_4_Lookup_from_RO3__c',
                'Related_Object_4_Lookup_from_RO3__r.QualifiedApiName',
                'Related_Object_4_Lookup_to_RO3__c',
                'Related_Object_4_Lookup_to_RO3__r.QualifiedApiName',
                'Related_Object_4_Shared_To_Field__c',
                'Related_Object_4_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_4_Shared_To_Field__r.MasterLabel',

                'Related_Object_5__c',
                'Related_Object_5__r.QualifiedApiName',
                'Related_Object_5__r.MasterLabel',
                'Related_Object_5_Lookup_from_RO4__c',
                'Related_Object_5_Lookup_from_RO4__r.QualifiedApiName',
                'Related_Object_5_Lookup_to_RO4__c',
                'Related_Object_5_Lookup_to_RO4__r.QualifiedApiName',
                'Related_Object_5_Shared_To_Field__c',
                'Related_Object_5_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_5_Shared_To_Field__r.MasterLabel',

                'Related_Object_6__c',
                'Related_Object_6__r.QualifiedApiName',
                'Related_Object_6__r.MasterLabel',
                'Related_Object_6_Lookup_from_RO5__c',
                'Related_Object_6_Lookup_from_RO5__r.QualifiedApiName',
                'Related_Object_6_Lookup_to_RO5__c',
                'Related_Object_6_Lookup_to_RO5__r.QualifiedApiName',
                'Related_Object_6_Shared_To_Field__c',
                'Related_Object_6_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_6_Shared_To_Field__r.MasterLabel',

                'Related_Object_7__c',
                'Related_Object_7__r.QualifiedApiName',
                'Related_Object_7__r.MasterLabel',
                'Related_Object_7_Lookup_from_RO6__c',
                'Related_Object_7_Lookup_from_RO6__r.QualifiedApiName',
                'Related_Object_7_Lookup_to_RO6__c',
                'Related_Object_7_Lookup_to_RO6__r.QualifiedApiName',
                'Related_Object_7_Shared_To_Field__c',
                'Related_Object_7_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_7_Shared_To_Field__r.MasterLabel',

                'Related_Object_8__c',
                'Related_Object_8__r.QualifiedApiName',
                'Related_Object_8__r.MasterLabel',
                'Related_Object_8_Lookup_from_RO7__c',
                'Related_Object_8_Lookup_from_RO7__r.QualifiedApiName',
                'Related_Object_8_Lookup_to_RO7__c',
                'Related_Object_8_Lookup_to_RO7__r.QualifiedApiName',
                'Related_Object_8_Shared_To_Field__c',
                'Related_Object_8_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_8_Shared_To_Field__r.MasterLabel',

                'Related_Object_9__c',
                'Related_Object_9__r.QualifiedApiName',
                'Related_Object_9__r.MasterLabel',
                'Related_Object_9_Lookup_from_RO8__c',
                'Related_Object_9_Lookup_from_RO8__r.QualifiedApiName',
                'Related_Object_9_Lookup_to_RO8__c',
                'Related_Object_9_Lookup_to_RO8__r.QualifiedApiName',
                'Related_Object_9_Shared_To_Field__c',
                'Related_Object_9_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_9_Shared_To_Field__r.MasterLabel',

                'Related_Object_10__c',
                'Related_Object_10__r.QualifiedApiName',
                'Related_Object_10__r.MasterLabel',
                'Related_Object_10_Lookup_from_RO9__c',
                'Related_Object_10_Lookup_from_RO9__r.QualifiedApiName',
                'Related_Object_10_Lookup_to_RO9__c',
                'Related_Object_10_Lookup_to_RO9__r.QualifiedApiName',
                'Related_Object_10_Shared_To_Field__c',
                'Related_Object_10_Shared_To_Field__r.QualifiedApiName',
                'Related_Object_10_Shared_To_Field__r.MasterLabel'
            };

            allFieldsForSelect = String.join(fieldNames, ',');
        }
        return allFieldsForSelect;
    }

    private static String getQueryWithCondition(String condition) {
        String query = 'SELECT ' + getAllFieldsForSelect() 
            + ' FROM FormulaShare_Rule__mdt WHERE ' 
            + condition;
        return query;
    }


    // Returns a list of wrapper objects rather than custom metadata objects, which is necessary   
    // to support unit tests since custom metadata relationships can't be mocked
    public List<FormulaShareRule> getRulesSharingObject(Schema.sObjectType type) {

		String objectName = type.getDescribe().getName();
        List<FormulaShare_Rule__mdt> rules = new List<FormulaShare_Rule__mdt>();

        // If test, populate list with a fake rule so we can test logic of method (can't otherwise guarantee rules exist)
        if(isUnitTest) {
            FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();
            rule.Sharing_Reason__c = 'Test reason';
            rules.add(rule);
        }

        else {
            String condition = 'Object_Shared__r.QualifiedApiName = \'' + objectName + '\''
                + ' WITH SECURITY_ENFORCED';
            String query = getQueryWithCondition(condition);
            rules = Database.query(query);
        }
        
		// Create list of all jobs with relevant details for assessing scope
		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }


    // Returns rules where the shared object and shared to field are the object in scope
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getStandardAndAncestorRulesSharingObject(String objectName) {
        String condition = 'Object_Shared__r.QualifiedApiName = \'' + objectName + '\''
            + ' AND Child_Object_Lookup_Field__c = NULL'
            + ' AND Related_Object_2_Lookup_to_RO1__c = NULL'
            + ' AND Related_Object_3_Lookup_to_RO2__c = NULL'
            + ' WITH SECURITY_ENFORCED';
        String query = getQueryWithCondition(condition);
        List<FormulaShare_Rule__mdt> rules = Database.query(query);

		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);
		return rulesToReturn;
    }


    // Returns rules where the supplied object name matches the bottom object of a inlaw or descendant rule
    // Since OR conditions aren't allowed for metadata queries, further filtering is done in apex
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getDescendantAndInlawRulesWithThisBottomObject(String objectName) {

        // Filter to just records with a related object which is below the shared object
        // Since OR conditions aren't allowed for metadata queries, further filtering is done in apex
        String condition = 'Child_Object_with_Shared_To_Field__c != NULL AND Child_Object_Lookup_Field__c != NULL'
            + ' WITH SECURITY_ENFORCED';
        String query = getQueryWithCondition(condition);
        List<FormulaShare_Rule__mdt> rules = Database.query(query);

        List<FormulaShareRule> rulesFromQuery = mapMetadataRulesToWrapper(rules);
        List<FormulaShareRule> rulesToReturn = new List<FormulaShareRule>();

        // Check for any rules where this object is the bottom object
        for(FormulaShareRule rule : rulesFromQuery) {
            switch on rule.type {
                when 'descendant' {
                    if(rule.controllingObjectApiName == objectName) {
                        rulesToReturn.add(rule);
                    }
                }
                when 'inlaw' {
                    FormulaShareRuleInlaw inlawRule = (FormulaShareRuleInlaw) rule;
                    if(inlawRule.bottomObjectApiName == objectName) {
                        rulesToReturn.add(rule);
                    }
                }
            }
        }

		return rulesToReturn;
    }    


    // Returns rules where type in scope is the child object in a child object rule
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getAllRules() {
        String condition = 'Object_Shared__c != null';
        String query = getQueryWithCondition(condition);
        List<FormulaShare_Rule__mdt> rules = Database.query(query);

        List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }


    // Returns details of a single rule matching a supplied id
    // Used by FormulaShareRuleDetail LWC
    @AuraEnabled(cacheable=false)
    public static FormulaShareRule getSpecificRule(Id ruleId) {
        String condition = 'Id = \'' + ruleId + '\' WITH SECURITY_ENFORCED LIMIT 1';
        String query = getQueryWithCondition(condition);
        System.debug('specific rule query: '+ query);
        FormulaShare_Rule__mdt rule = Database.query(query);
        FormulaShareRule ruleToReturn = FormulaShareRule.getRule(rule);
        System.debug('ruleToReturn: '+ ruleToReturn);

		return ruleToReturn;
    }


    private List<FormulaShareRule> mapMetadataRulesToWrapper(List<FormulaShare_Rule__mdt> mdRules) {
        List<FormulaShareRule> rulesToReturn = new List<FormulaShareRule>();

        for(FormulaShare_Rule__mdt mdRule : mdRules) {
            FormulaShareRule rule = FormulaShareRule.getRule(mdRule);
            rulesToReturn.add(rule);
        }

        return rulesToReturn;
    }


    public List<String> selectObjectsWithRules() {
        List<String> objNames = new List<String>();

        // If test, populate list with a fake object name so we can test logic of method (can't otherwise guarantee rules exist)
        if(isUnitTest) {
            objNames.add('Test object');
        }
        
        else {
            for(FormulaShare_Rule__mdt rule : [SELECT Object_Shared__r.QualifiedApiName FROM FormulaShare_Rule__mdt LIMIT 50000]) {
                objNames.add(rule.Object_Shared__r.QualifiedApiName);
            }
        }

        return objNames;
    }

}
