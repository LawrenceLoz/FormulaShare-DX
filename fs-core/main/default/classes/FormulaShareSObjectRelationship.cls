public inherited sharing class FormulaShareSObjectRelationship {

    @AuraEnabled public String thisObjectApiName;
    @AuraEnabled public String thisObjectLabel;
    @AuraEnabled public String lookupFromPrevObjectApiName;
    @AuraEnabled public String lookupToPrevObjectApiName;
    @AuraEnabled public String sharedToFieldApiName;
    public String thisObjectToken;
    public String lookupFromPrevObjectToken;
    public String lookupToPrevObjectToken;
    public String sharedToFieldToken;
    public String sharedToFieldLabel;
    @AuraEnabled public FormulaShareSObjectRelationship nextRelationship;


    // Map fields from nested relationship onto their flat metadata equivalents
    // This is used help convert an LWC component object to a metadata record which can be inserted / updated
    public FormulaShare_Rule__mdt mapRelationshipToMetadataRule(FormulaShare_Rule__mdt mdRule) {
        FormulaShareSObjectRelationship rel = nextRelationship;

        // If no nested relationships, set Shared_To__c field (on shared object) only
        if(rel == null) {
            mdRule.Shared_To__c = sharedToFieldApiName;
        }

        // Otherwise, set details for the first related object (treated specifically because API names don't follow other objects' pattern)
        else {
            mdRule.Child_Object_with_Shared_To_Field__c = rel.thisObjectApiName;
            mdRule.Related_Object_1_Lookup_from_Shared_Obj__c = rel.lookupFromPrevObjectApiName;
            mdRule.Child_Object_Lookup_Field__c = rel.lookupToPrevObjectApiName;

            // If shared field is on this object, populate details
            if(rel.sharedToFieldApiName != null) {
                mdRule.Child_Object_Shared_To_Field__c = rel.sharedToFieldApiName;
            }

            // If we have another nested relationship, process this
            else if(rel.nextRelationship != null) {
                mdRule = mapToRelationshipToMetadatRuleStructured(mdRule, rel.nextRelationship, 2);
            }
        }

        return mdRule;
    }

    // For objects lower than the shared and first related object, we can dynamically set fields on the metadata record
    private FormulaShare_Rule__mdt mapToRelationshipToMetadatRuleStructured(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, Integer depth) {
        System.debug('rel now: ' + rel);
        System.debug('rel lookupToPrevObjectApiName: ' + rel.lookupToPrevObjectApiName);
        System.debug('rel lookupFromPrevObjectApiName: ' + rel.lookupFromPrevObjectApiName);

        String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();
        String fieldPrefix = namespacePrefix + 'Related_Object_' + depth;
        Integer lastDepth = depth - 1;

        // Set object name and lookups between this and the last object
        mdRule.put(fieldPrefix + '__c', rel.thisObjectApiName);
        mdRule.put(fieldPrefix + '_Lookup_from_RO' + lastDepth + '__c', rel.lookupFromPrevObjectApiName);
        mdRule.put(fieldPrefix + '_Lookup_to_RO' + lastDepth + '__c', rel.lookupToPrevObjectApiName);

        // If shared field is on this object, populate details
        if(rel.sharedToFieldApiName != null) {
            mdRule.put(fieldPrefix + '_Shared_To_Field__c', rel.sharedToFieldApiName);
        }

        // If we have another nested relationship, process this
        else if(rel.nextRelationship != null) {
            mdRule = mapToRelationshipToMetadatRuleStructured(mdRule, rel.nextRelationship, depth + 1);
        }

        return mdRule;
    }


    public Boolean isValid() {
        if(thisObjectApiName == null) {
            System.debug('isValid() fail: Object API name not populated for relationship: ' + this);
            return false;
        }
        if(lookupToPrevObjectApiName == null && lookupFromPrevObjectApiName == null) {
            System.debug('isValid() fail: No relationship details for relationship: ' + this);
            return false;
        }
        if(lookupToPrevObjectApiName != null && lookupFromPrevObjectApiName != null) {
            System.debug('isValid() fail: Both relationship details are populated for relationship: ' + this);
            return false;
        }
        if(sharedToFieldToken == null && nextRelationship == null) {
            System.debug('isValid() fail: No shared to field or nested relationship for relationship: ' + this);
            return false;
        }
        if(sharedToFieldToken != null && nextRelationship != null) {
            System.debug('isValid() fail: Both shared to field and nested relationship populated for relationship: ' + this);
            return false;
        }
        if(nextRelationship != null) {
            System.debug(nextRelationship);
            if(!nextRelationship.isValid()) {
                System.debug('isValid() fail: Nested relationship not valid for relationship: ');
                return false;
            }
        }
        return true;
    }

}