public inherited sharing class FormulaShareRuleSibling extends FormulaShareRuleRelatedObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleSibling() {}
    
    public FormulaShareRuleSibling(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'sibling';
        setVars();
    }

    public String pathFromSharedObjToTopObj;
    public String pathFromControllingObjToTopObj;

    @TestVisible private List<Schema.SObjectField> lookupFromSharedObjToTopObjFieldList = new List<Schema.SObjectField>();
    @TestVisible private List<Schema.SObjectField> lookupFromSiblingObjToTopObjFieldList = new List<Schema.SObjectField>();

    private void setVars() {
        String prevObjApiName = objectSharedAPIName;
        System.debug('sibling rel: '+ relationship);
        List<Schema.SObjectField> lookupFromSiblingObjToTopObjFieldListBackwards = new List<Schema.SObjectField>();

        // Start from the first related object
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        pathFromSharedObjToTopObj = '';
        pathFromControllingObjToTopObj = '';

        // Iterate until we're on the top object and add the relationship name (__r) of each lookup
        while(rel.nextRelationship.lookupFromPrevObjectApiName != null) {
            System.debug('Sibling rel on shared side, object: '+rel.thisObjectApiName+': rel: '+rel);
            Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
            pathFromSharedObjToTopObj += field.getDescribe().getRelationshipName() + '.';

            // Add the field to the sequence of lookups to top
            lookupFromSharedObjToTopObjFieldList.add(field);

            prevObjApiName = rel.thisObjectApiName;
            rel = rel.nextRelationship;
        }
        System.debug('Sibling rel top, object: '+rel.thisObjectApiName+': rel: '+rel);

        // For the final relationship, add the api name
        pathFromSharedObjToTopObj += rel.lookupFromPrevObjectApiName;

        // And the final field in lookup sequence
        Schema.SObjectType typeBeforeTopShared = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
        Schema.sObjectField fieldBeforeTopShared = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, typeBeforeTopShared);
        lookupFromSharedObjToTopObjFieldList.add(fieldBeforeTopShared);

        // Move on to object below the top
        rel = rel.nextRelationship;

        // Set path from controlling object to top to the first lookup down from the top object
        pathFromControllingObjToTopObj = rel.lookupToPrevObjectApiName;
        System.debug('Sibling rel below top, object: '+rel.thisObjectApiName+': rel: '+rel);

        // Add relationship and shared to field from final relationship
        Schema.SObjectType typeBeforeTopSibling = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
        Schema.sObjectField fieldBeforeTopSibling = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, typeBeforeTopSibling);
        lookupFromSiblingObjToTopObjFieldListBackwards.add(fieldBeforeTopSibling);

        // Iterate from top object - get next object down, set the lookup field as the path
        // Then iterate down, adding to beginning of string
        while(rel.nextRelationship != null) {
            rel = rel.nextRelationship;
            System.debug('Sibling rel on controlling side, object: '+rel.thisObjectApiName+': rel: '+rel);
            Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
            pathFromControllingObjToTopObj = field.getDescribe().getRelationshipName() + '.' + pathFromControllingObjToTopObj;
            lookupFromSiblingObjToTopObjFieldListBackwards.add(field);   // Add relationship field
        }

        // List of fields between sibling and top object are backwards, so reverse this
        for(Integer i = lookupFromSiblingObjToTopObjFieldListBackwards.size() - 1; i >= 0; i--){
            lookupFromSiblingObjToTopObjFieldList.add(lookupFromSiblingObjToTopObjFieldListBackwards[i]);
        }

        // Share field will be queried from controlling object, so add without relationship
        pathToSharedToField = controllingObjectSharedToFieldAPIName;
    }


    // Dynamically gets the value through in a sets of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public Id getTopObjectIdFromSharedRecord(SObject record) {
        return FormulaShareRecordUtilities.getTopRecordIdFromFieldList(lookupFromSharedObjToTopObjFieldList, record);
    }

    public Id getTopObjectIdFromSiblingRecord(SObject record) {
        return FormulaShareRecordUtilities.getTopRecordIdFromFieldList(lookupFromSiblingObjToTopObjFieldList, record);
    }

}