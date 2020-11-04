public inherited sharing class FormulaShareRuleSibling extends FormulaShareRuleRelatedObject {

    public FormulaShareRuleSibling(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'sibling';
        pathToSharedToField = mdRule.Shared_To__r.QualifiedApiName;
        setVars();
    }

    public String pathFromSharedObjToTopObj;
    public String pathFromControllingObjToTopObj;
    
    private void setVars() {
        String prevObjApiName = objectSharedAPIName;
        System.debug('sibling rel: '+ relationship);

        // Start from the first related object
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        pathFromSharedObjToTopObj = '';
        pathFromControllingObjToTopObj = '';

        // Iterate until we're on the top object and add the relationship name (__r) of each lookup
        while(rel.nextRelationship.nextRelationship?.lookupFromPrevObjectApiName != null) {
            Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
            pathFromSharedObjToTopObj += field.getDescribe().getRelationshipName() + '.';

            prevObjApiName = rel.thisObjectApiName;
            rel = rel.nextRelationship;
        }

        // For the final relationship, add the api name
        pathFromSharedObjToTopObj += rel.lookupFromPrevObjectApiName;


        // Move on to object below the top
        rel = rel.nextRelationship;

        // Set path from controlling object to top to the first lookup down from the top object
        pathFromControllingObjToTopObj = rel.lookupToPrevObjectApiName;

        // Iterate from top object - get next object down, set the lookup field as the path
        // Then iterate down, adding to beginning of string
        while(rel.nextRelationship != null) {
            rel = rel.nextRelationship;
            Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
            pathFromControllingObjToTopObj = field.getDescribe().getRelationshipName() + '.' + pathFromControllingObjToTopObj;
        }

    }    

}