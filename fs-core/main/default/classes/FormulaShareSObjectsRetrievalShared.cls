public with sharing class FormulaShareSObjectsRetrievalShared {

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

                // If the rule references child objects, populate details of objects and fields for sub-selects
                when 'child' {
                    FormulaShareRuleChild childRule = (FormulaShareRuleChild) rule;
                    setChildRod(childRule);
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
            // && rule.type != 'child'
            if(rule.shareWith == 'Users') {
                Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
                sharedObjectSelector.addField(ownerIdField);
            }

        }

		List<SObject> sharedRecords = sharedObjectSelector.selectWithFields(sharedObjIdSet);
        return sharedRecords;
    }


    // Updates the related object detail map with relevant fields from this rule
    private void setChildRod(FormulaShareRuleChild rule) {
        FormulaShareSObjectsSelector.RelatedObjectDetails rod;

        // Child object will be the second nested relationship in the rule
        FormulaShareSObjectRelationship childObjRel = rule.relationship.nextRelationship;
        String key = rule.controllingObjectApiName + rule.pathFromBottomObjToSharedObj;

        // Check whether we have this object and relationship in map already, and get the details if so (we'll add the shared field)
        // Also get the field map populate when the object was assessed previously
        if(rodMap.containsKey(key)) {
            rod = rodMap.get(key);
        }

        // Otherwise create a new set of details
        else {
            rod = new FormulaShareSObjectsSelector.RelatedObjectDetails();
            rod.type = FormulaShareUtilities.globalDescribe.get(rule.controllingObjectApiName);
            rod.relationshipName = FormulaShareUtilities.getRelationshipName(rule.objectSharedAPIName, rule.controllingObjectApiName, childObjRel.lookupToPrevObjectApiName);
            rod.fields = new Set<Schema.SObjectField>();

            system.debug('child api name: ' + rule.controllingObjectApiName);
            system.debug('desc: ' + rod.type);
        }

        // Get the type for field and add this to the set field details
        Map<String, SObjectField> childObjectFieldMap = FormulaShareUtilities.getFieldMap(rule.controllingObjectApiName);
        Schema.SObjectField childField = childObjectFieldMap.get(rule.controllingObjectSharedToFieldAPIName);
        rod.fields.add(childField);

        system.debug('this rod '+rod);

        rodMap.put(key, rod);
    }

}