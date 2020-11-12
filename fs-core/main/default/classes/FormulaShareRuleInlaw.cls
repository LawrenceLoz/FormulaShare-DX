public inherited sharing class FormulaShareRuleInlaw extends FormulaShareRuleBottomObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleInlaw() {}
        
    public FormulaShareRuleInlaw(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'inlaw';
        setVars();
    }

    // Set pathToSharedToField to path from bottom object to shared to field on top object for inlaw rule
    public String lookupFromBottomObjTowardsControllingObj;

    @TestVisible
    private List<Schema.SObjectField> lookupFromBottomObjToControllingObjFieldList = new List<Schema.SObjectField>();

    private void setVars() {

        // Navigate to the bottom object relationship and set the object type
        FormulaShareSObjectRelationship rel = bottomObjectRelationship;
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);

        // Traverse up from here, checking lookup fields
        rel = rel.nextRelationship;
        lookupFromBottomObjTowardsControllingObj = rel.lookupFromPrevObjectApiName;

        // Iterate up from bottom object until we're one away from controlling object
        pathToSharedToField = '';
        while(rel.nextRelationship != null) {
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
            lookupFromBottomObjToControllingObjFieldList.add(field);
            pathToSharedToField += field.getDescribe().getRelationshipName() + '.';
            type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
    
            rel = rel.nextRelationship;
        }
    }


    // Dynamically gets the value through in a set of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public String getSharedToValueFromRecord(SObject record) {

        FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
        SObject controllingRecord = recordUtils.getTopRecordFromLookup(lookupFromBottomObjToControllingObjFieldList);

        // Return the shared to field from this object
        return (String) controllingRecord?.get(controllingObjectSharedToFieldAPIName);
    }    

}