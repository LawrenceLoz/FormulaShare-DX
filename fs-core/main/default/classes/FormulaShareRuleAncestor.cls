public virtual inherited sharing class FormulaShareRuleAncestor extends FormulaShareRuleRelatedObject {

    public FormulaShareRuleAncestor(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'ancestor';
        setVars();
    }

    // Sequence of lookup fields needed to get from shared object to top object
    private List<Schema.SObjectField> lookupFieldList = new List<Schema.SObjectField>();

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
                lookupFieldList.add(field);
                fieldPath += field.getDescribe().getRelationshipName() + '.';
            }
    
            prevObjApiName = rel.thisObjectApiName;
            rel = rel.nextRelationship;
        }

        // Add relationship and shared to field from final relationship
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
        Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
        lookupFieldList.add(field);
        fieldPath += field.getDescribe().getRelationshipName() + '.';
        fieldPath += rel.sharedToFieldApiName;

        pathToSharedToField = fieldPath;
    }


    // Required to dynamically get the 
    public String getSharedToValueFromRecord(SObject record) {
        // Iterate through fields until we're at the top object
        for(Schema.SObjectField field : lookupFieldList) {
            System.debug('Checking for field: '+field.getDescribe().getName()+' in record: '+record);
            record = record.getSObject(field);
            System.debug('record now: '+ record);

            // Return null if no record returned for this lookup. This could be the case if
            // relationship wasn't queried because lookup was cleared
            if(record == null) {
                return null;
            }
        }

        // Return the shared to field from this object
        return (String) record.get(controllingObjectSharedToFieldAPIName);
    }



}