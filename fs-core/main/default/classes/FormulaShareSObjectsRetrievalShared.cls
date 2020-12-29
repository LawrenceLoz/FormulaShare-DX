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

public inherited sharing class FormulaShareSObjectsRetrievalShared {

    Schema.SObjectType type;
    List<FormulaShareRule> rules;
    Set<Id> sharedObjIdSet;

    public FormulaShareSObjectsRetrievalShared(Schema.SObjectType type, List<FormulaShareRule> rules, Set<Id> sharedObjIdSet) {
        this.type = type;
        this.rules = rules;
        this.sharedObjIdSet = sharedObjIdSet;
    }

    Map<String,FormulaShareSObjectsSelector.RelatedObjectDetails> rodMap = new Map<String,FormulaShareSObjectsSelector.RelatedObjectDetails>();

    public List<SObject> retrieveSharedObjects() {
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(type);

        Set<String> parentFieldSet = new Set<String>();

		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;
        FormulaShareSObjectsSelector sharedObjectSelector = FormulaShareSObjectsSelector.construct(enforceObjectAndFieldSecurity,type);

        // Populate all details for query of shared object
        for(FormulaShareRule rule : rules) {

            switch on rule.type {

                // If rule references a field on the shared object, populate details
                when 'standard' {
                    Schema.SObjectField sharedToField = fieldMap.get(rule.controllingObjectSharedToFieldAPIName);
                    System.debug('Adding field: '+sharedToField.getDescribe().getName());
                    sharedObjectSelector.addField(sharedToField);
                }

                // For sharing based on parent values, populate top object lookups
                when 'ancestor'{
                    FormulaShareRuleAncestor ancestorRule = (FormulaShareRuleAncestor) rule;
                    String fieldPath = ancestorRule.pathToSharedToField;
                    System.debug('Adding ancestor field: '+fieldPath);
                    sharedObjectSelector.addFieldString(fieldPath);
                }
                when 'sibling' {
                    FormulaShareRuleSibling siblingRule = (FormulaShareRuleSibling) rule;
                    String fieldPath = siblingRule.pathFromSharedObjToTopObj;
                    System.debug('Adding sibling field: '+fieldPath);
                    sharedObjectSelector.addFieldString(fieldPath);
                }
            }
            
            // Also add the OwnerId field if rule shares to users (required for later comparisons)
            if(rule.shareWith == 'Users') {
                Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
                sharedObjectSelector.addField(ownerIdField);
            }

        }

        System.debug('sharedObjIdSet: '+sharedObjIdSet);

		List<SObject> sharedRecords = sharedObjectSelector.selectWithFields(sharedObjIdSet);
        return sharedRecords;
    }


}