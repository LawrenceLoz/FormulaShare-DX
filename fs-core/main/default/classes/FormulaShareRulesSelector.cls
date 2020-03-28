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

public inherited sharing class FormulaShareRulesSelector {

    public static FormulaShareRulesSelector mock;
    public static FormulaShareRulesSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareRulesSelector();
        }
    }
    @TestVisible Boolean isUnitTest = false;

    // fflib selector pattern isn't used because it fails for metadata relationship fields.
    // The basic queries below are sufficient - FLS and sharing checks aren't needed 
    // since custom metadata does not support either.

    // Method returns list of wrapped rules with the 
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
        rules = [SELECT Id, Access_Level__c, 
			Object_Shared__r.QualifiedApiName, Shared_To__r.QualifiedApiName, 
			Share_With__c, Sharing_Reason__c, Active__c, Shared_To_Field_Type__c,
            Child_Object_with_Shared_To_Field__r.QualifiedApiName, Child_Object_Lookup_Field__r.QualifiedApiName,
            Child_Object_Shared_To_Field__r.QualifiedApiName, Child_Object_Shared_To_Field_Type__c
			FROM FormulaShare_Rule__mdt
			WHERE Object_Shared__r.QualifiedApiName = :objectName];
        }
        
		// Create list of all jobs with relevant details for assessing scope
		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }


    // Returns rules where the shared object and shared to field are the object in scope
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getStandardRulesThisObjectControls(String objectName) {

        List<FormulaShare_Rule__mdt> rules = [SELECT Id, Access_Level__c, 
			Object_Shared__r.QualifiedApiName, Shared_To__r.QualifiedApiName, 
			Share_With__c, Sharing_Reason__c, Active__c, Shared_To_Field_Type__c,
            Child_Object_with_Shared_To_Field__r.QualifiedApiName, Child_Object_Lookup_Field__r.QualifiedApiName,
            Child_Object_Shared_To_Field__r.QualifiedApiName, Child_Object_Shared_To_Field_Type__c
			FROM FormulaShare_Rule__mdt
			WHERE Child_Object_with_Shared_To_Field__c = null
            AND Object_Shared__r.QualifiedApiName = :objectName];

		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }


    // Returns rules where type in scope is the child object in a child object rule
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getChildRulesThisObjectControls(String objectName) {

        List<FormulaShare_Rule__mdt> rules = [SELECT Id, Access_Level__c, 
			Object_Shared__r.QualifiedApiName, Shared_To__r.QualifiedApiName, 
			Share_With__c, Sharing_Reason__c, Active__c, Shared_To_Field_Type__c,
            Child_Object_with_Shared_To_Field__r.QualifiedApiName, Child_Object_Lookup_Field__r.QualifiedApiName,
            Child_Object_Shared_To_Field__r.QualifiedApiName, Child_Object_Shared_To_Field_Type__c
			FROM FormulaShare_Rule__mdt
			WHERE Child_Object_with_Shared_To_Field__c != null 
            AND Child_Object_with_Shared_To_Field__r.QualifiedApiName = :objectName];

		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }



    private List<FormulaShareRule> mapMetadataRulesToWrapper(List<FormulaShare_Rule__mdt> rules) {
        List<FormulaShareRule> rulesToReturn = new List<FormulaShareRule>();

		for(FormulaShare_Rule__mdt ruleInScope : rules) {
			FormulaShareRule rule = new FormulaShareRule();
			rule.objectSharedAPIName = ruleInScope.Object_Shared__r.QualifiedApiName;
			rule.sharedToAPIName = ruleInScope.Shared_To__r.QualifiedApiName;
			rule.shareWith = ruleInScope.Share_With__c;
			rule.accessLevel = ruleInScope.Access_Level__c;
			rule.active = ruleInScope.Active__c;
			rule.sharedToFieldType = ruleInScope.Shared_To_Field_Type__c;
			rule.sharingReason = ruleInScope.Sharing_Reason__c;
            rule.childObjectWithSharedToFieldAPIName = ruleInScope.Child_Object_with_Shared_To_Field__r.QualifiedApiName;
            rule.childObjectLookupFieldAPIName = ruleInScope.Child_Object_Lookup_Field__r.QualifiedApiName;
            rule.childObjectSharedToFieldAPIName = ruleInScope.Child_Object_Shared_To_Field__r.QualifiedApiName;
            rule.childObjectSharedToFieldType = ruleInScope.Child_Object_Shared_To_Field_Type__c;

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
