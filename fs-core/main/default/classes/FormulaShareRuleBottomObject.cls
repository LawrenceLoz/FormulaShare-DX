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
    public String lookupFromBottomObjTowardsSharedObj;
    protected FormulaShareSObjectRelationship bottomObjectRelationship;


    @TestVisible
    private void setVars() {

        // Start from the first related object and field
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        pathFromBottomObjToSharedObj = rel.lookupToPrevObjectApiName;

        // Iterate until we're on the bottom object and add the relationship name (__r) of each lookup
        Schema.SObjectType type;
        while(rel.nextRelationship != null) {
            rel = rel.nextRelationship;
            type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
            pathFromBottomObjToSharedObj = field.getDescribe().getRelationshipName() + '.' + pathFromBottomObjToSharedObj;
        }

        bottomObjectRelationship = rel;
        lookupFromBottomObjTowardsSharedObj = rel.lookupToPrevObjectApiName;
    }


}
