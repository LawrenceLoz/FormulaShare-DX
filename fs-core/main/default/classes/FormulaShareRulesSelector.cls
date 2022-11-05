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

public virtual inherited sharing class FormulaShareRulesSelector {

    public static Object mock;
    public static FormulaShareRulesSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            system.debug('Mock requested: '+mock);
            return (FormulaShareRulesSelector) mock;
        }
        else {
            return new FormulaShareRulesSelector();
        }
    }
    @TestVisible Boolean isUnitTest = false;

    String allFieldsForSelect;
    private String getAllFieldsForSelect() {

        // If selected fields string hasn't been prepared already, set this now
        if(allFieldsForSelect == null) {
            List<String> fieldNames = getFieldNames();      // overridden in extending classes
            allFieldsForSelect = String.join(fieldNames, ',');
        }
        return allFieldsForSelect;
    }

    protected virtual List<String> getFieldNames() {
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
            'Shared_To_Field_Type__c',

            'Object_Shared__c',
            'Object_Shared__r.QualifiedApiName',
            'Object_Shared__r.MasterLabel',
            'Shared_To__c',
            'Shared_To__r.QualifiedApiName',
            'Shared_To__r.MasterLabel'
        };
        return fieldNames;
    }

    protected String getQueryWithCondition(String condition) {
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
            String condition = 'Object_Shared__r.QualifiedApiName = \'' + objectName + '\'';
            String query = getQueryWithCondition(condition);
            rules = Database.query(query);
        }
        
		// Create list of all jobs with relevant details for assessing scope
		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);

		return rulesToReturn;
    }


    // Returns rules where the shared object and shared to field are the object in scope
    // Used by trigger helper to get rules which might be affected by object DML
    public List<FormulaShareRule> getRulesSharingObject(String objectName) {
        String condition = 'Object_Shared__r.QualifiedApiName = \'' + objectName + '\'';
        String query = getQueryWithCondition(condition);
        List<FormulaShare_Rule__mdt> rules = Database.query(query);

		List<FormulaShareRule> rulesToReturn = mapMetadataRulesToWrapper(rules);
		return rulesToReturn;
    }


    // Implementation is simple in the base class and overriden for related object sharing
    public virtual List<FormulaShareRule> getStandardAndAncestorRulesSharingObject(String objectName) {
        return getRulesSharingObject(objectName);
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


    public Map<String,String> selectObjectsWithRules() {
        Map<String,String> objMap = new Map<String,String>();

        // If test, populate Set with a fake object name so we can test logic of method (can't otherwise guarantee rules exist)
        if(isUnitTest) {
            objMap.put('Test object', 'Test label');
        }
        
        else {
            // Can't use FormulaShare_Rule__mdt.getAll() as this doesn't return entity relationship lookups
            String condition = 'Object_Shared__c != null';
            String query = getQueryWithCondition(condition);
            List<FormulaShare_Rule__mdt> rules = Database.query(query);

            for(FormulaShare_Rule__mdt rule : rules) {
                objMap.put(rule.Object_Shared__r.QualifiedApiName, rule.Object_Shared__r.MasterLabel);
            }
        }

        return objMap;
    }


    public FormulaShareRule getSpecificRule(Id ruleId) {
        String condition = 'Id = \'' + ruleId + '\' LIMIT 1';
        String query = getQueryWithCondition(condition);
        System.debug('specific rule query: '+ query);
        List<FormulaShare_Rule__mdt> ruleInList = Database.query(query);
        FormulaShareRule ruleToReturn;

        if(!ruleInList.isEmpty()) {
            FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
            ruleToReturn = ruleConverter.getRule(ruleInList[0]);
            System.debug('ruleToReturn: '+ ruleToReturn);
        }

		return ruleToReturn;
    }


    protected List<FormulaShareRule> mapMetadataRulesToWrapper(List<FormulaShare_Rule__mdt> mdRules) {
        List<FormulaShareRule> rulesToReturn = new List<FormulaShareRule>();

        for(FormulaShare_Rule__mdt mdRule : mdRules) {

            // Construct rule from metadata, and add only if no exceptions - could occur if structure corrupted or object not supported
            try {
                FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
                FormulaShareRule rule = ruleConverter.getRule(mdRule);
                rulesToReturn.add(rule);
            }
            catch(Exception e) {
                System.debug('Issue constructing rule: '+mdRule.developerName+'. Message from Salesforce: '+e.getMessage());
            }
        }

        return rulesToReturn;
    }

}
