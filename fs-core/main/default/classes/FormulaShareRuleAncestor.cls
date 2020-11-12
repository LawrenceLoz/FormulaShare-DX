public virtual inherited sharing class FormulaShareRuleAncestor extends FormulaShareRuleRelatedObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleAncestor() {}
        
    public FormulaShareRuleAncestor(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'ancestor';
        setVars();
    }

    // Sequence of lookup fields needed to get from shared object to top object
    @TestVisible
    private List<Schema.SObjectField> lookupFromSharedObjToControllingObjFieldList = new List<Schema.SObjectField>();

    private void setVars() {

        // Field to check in queries (lookup from shared obj to next obj) is indicated in the second element of the relationship list
        firstQueryStepApiName = relationship.nextRelationship.lookupFromPrevObjectApiName;

        String prevObjApiName = objectSharedAPIName;
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        String fieldPath = '';

        // Iterate until we're at the top (no further relationships, or next relationship isn't a lookup from last)
        while(rel.nextRelationship != null) {
    
            // Concatenate field path
            if(rel.lookupFromPrevObjectApiName != null) {
                Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
                Schema.SObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
                lookupFromSharedObjToControllingObjFieldList.add(field);
                fieldPath += field.getDescribe().getRelationshipName() + '.';
            }
    
            prevObjApiName = rel.thisObjectApiName;
            rel = rel.nextRelationship;
        }

        // Add relationship and shared to field from final relationship
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
        Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
        lookupFromSharedObjToControllingObjFieldList.add(field);
        fieldPath += field.getDescribe().getRelationshipName() + '.';
        fieldPath += rel.sharedToFieldApiName;

        pathToSharedToField = fieldPath;
    }


    // Dynamically gets the value through in a set of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public String getSharedToValueFromRecord(SObject record) {

        FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
        SObject topRecord = recordUtils.getTopRecordFromLookup(lookupFromSharedObjToControllingObjFieldList);

        // Return the shared to field from this object
        return (String) topRecord?.get(controllingObjectSharedToFieldAPIName);
    }

}