public virtual inherited sharing class FormulaShareRuleBottomObject extends FormulaShareRuleRelatedObject {

    // Allow direct construction from test context only
    @TestVisible
    protected FormulaShareRuleBottomObject() {}

    public FormulaShareRuleBottomObject(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        setVars();
        firstQueryStepApiName = lookupFromBottomObjTowardsSharedObj;
    }

    public String bottomObjectApiName;
    public String pathFromBottomObjToSharedObj;
    public String pathFromBottomObjToOwnerIdOnSharedObj; // Ends with the relationship of the
    public String lookupFromBottomObjTowardsSharedObj;
    protected FormulaShareSObjectRelationship bottomObjectRelationship;

    // Sequence of lookup fields needed to get from shared object to top object
    @TestVisible
    protected List<Schema.SObjectField> lookupFromBottomObjToSharedObjFieldList = new List<Schema.SObjectField>();

    @TestVisible
    private void setVars() {

        // Start from the first related object and field
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        pathFromBottomObjToSharedObj = rel.lookupToPrevObjectApiName;

        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
        Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
        String relationshipPathFromBottomObjToSharedObj = field.getDescribe().getRelationshipName();
        System.debug('relationshipPathFromBottomObjToSharedObj initially: '+relationshipPathFromBottomObjToSharedObj);

        // Iterate until we're on the bottom object and add the relationship name (__r) of each lookup
        List<Schema.SobjectField> lookupFieldListReverse = new List<Schema.SobjectField>();
        while(rel.nextRelationship != null) {
            lookupFieldListReverse.add(field);

            rel = rel.nextRelationship;
            type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
            field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
            String relationshipName = field.getDescribe().getRelationshipName();

            pathFromBottomObjToSharedObj             = relationshipName + '.' + pathFromBottomObjToSharedObj;
            relationshipPathFromBottomObjToSharedObj = relationshipName + '.' + relationshipPathFromBottomObjToSharedObj;
        }

        // Populate lookup field list in correct order
        for(Integer i=0; i<lookupFieldListReverse.size(); i++) {
            lookupFromBottomObjToSharedObjFieldList.add(lookupFieldListReverse[lookupFieldListReverse.size() - 1 - i]);
        }

        pathFromBottomObjToOwnerIdOnSharedObj = relationshipPathFromBottomObjToSharedObj + '.OwnerId';

        bottomObjectRelationship = rel;
        lookupFromBottomObjTowardsSharedObj = rel.lookupToPrevObjectApiName;
    }


    // Dynamically gets the value through in a set of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public Id getOwnerOfSharedObjectFromBottomObject(SObject record) {

        FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
        SObject sharedRecord = recordUtils.getTopRecordFromLookup(lookupFromBottomObjToSharedObjFieldList);

        // Return the shared to field from this object
        return (Id) sharedRecord?.get('OwnerId');
    }

}