public inherited sharing class FormulaShareRuleInlaw extends FormulaShareRuleBottomObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleInlaw() {}
        
    public FormulaShareRuleInlaw(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'inlaw';
        setVarsInlaw();
    }

    // Set pathToObjectWithSharedToField to path from bottom object to top object for inlaw rule
    public String lookupFromBottomObjTowardsControllingObj;

    @TestVisible
    private List<Schema.SObjectField> lookupFromBottomObjToControllingObjFieldList = new List<Schema.SObjectField>();

    private void setVarsInlaw() {

        // Navigate to the bottom object relationship and set the object type
        FormulaShareSObjectRelationship rel = bottomObjectRelationship;
        System.debug('inlaw bottomObjectRelationship: '+bottomObjectRelationship);
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);

        // Set first lookup towards the controlling object
        lookupFromBottomObjTowardsControllingObj = rel.nextRelationship.lookupFromPrevObjectApiName;

        // Iterate up from bottom object until we're on controlling object
        String pathToObjectWithSharedToField = '';
        while(rel.nextRelationship != null) {
            rel = rel.nextRelationship;

            Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
            lookupFromBottomObjToControllingObjFieldList.add(field);
            System.debug('Iterating inlaw rule for rel: '+field.getDescribe().getRelationshipName());
            pathToObjectWithSharedToField += field.getDescribe().getRelationshipName() + '.';
            type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
        }

        // Shared to field will be queried from bottom object, so add with relationship prefix
        pathToSharedToField = pathToObjectWithSharedToField + controllingObjectSharedToFieldAPIName;
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