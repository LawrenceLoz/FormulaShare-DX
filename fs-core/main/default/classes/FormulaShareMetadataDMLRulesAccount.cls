public with sharing class FormulaShareMetadataDMLRulesAccount extends FormulaShareMetadataDMLRules {

    public FormulaShareMetadataDMLRulesAccount() {

        this.fieldsToSet = new List<String> {
            namespacePrefix + 'Active__c',
            namespacePrefix + 'Description__c',
            namespacePrefix + 'Object_Shared__c',
            namespacePrefix + 'Share_With__c',
            namespacePrefix + 'Access_Level__c',
            namespacePrefix + 'Active__c',
            namespacePrefix + 'Sharing_Reason__c',

            // Only difference to FormulaShareMetadataDMLRules is that Contact, Case 
            // and Opp Access are set but not cleared if not provided
            namespacePrefix + 'Contact_Access__c',
            namespacePrefix + 'Case_Access__c',
            namespacePrefix + 'Opportunity_Access__c'
        };

        this.fieldsToSetOrClear = new List<String> {
            namespacePrefix + 'Shared_To_Field_Type__c',
            namespacePrefix + 'Child_Object_Shared_To_Field_Type__c',
    
            namespacePrefix + 'Shared_To__c',
    
            namespacePrefix + 'Child_Object_with_Shared_To_Field__c',
            namespacePrefix + 'Child_Object_Lookup_Field__c',
            namespacePrefix + 'Related_Object_1_Lookup_from_Shared_Obj__c',
            namespacePrefix + 'Child_Object_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_2__c',
            namespacePrefix + 'Related_Object_2_Lookup_from_RO1__c',
            namespacePrefix + 'Related_Object_2_Lookup_to_RO1__c',
            namespacePrefix + 'Related_Object_2_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_3__c',
            namespacePrefix + 'Related_Object_3_Lookup_from_RO2__c',
            namespacePrefix + 'Related_Object_3_Lookup_to_RO2__c',
            namespacePrefix + 'Related_Object_3_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_4__c',
            namespacePrefix + 'Related_Object_4_Lookup_from_RO3__c',
            namespacePrefix + 'Related_Object_4_Lookup_to_RO3__c',
            namespacePrefix + 'Related_Object_4_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_5__c',
            namespacePrefix + 'Related_Object_5_Lookup_from_RO4__c',
            namespacePrefix + 'Related_Object_5_Lookup_to_RO4__c',
            namespacePrefix + 'Related_Object_5_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_6__c',
            namespacePrefix + 'Related_Object_6_Lookup_from_RO5__c',
            namespacePrefix + 'Related_Object_6_Lookup_to_RO5__c',
            namespacePrefix + 'Related_Object_6_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_7__c',
            namespacePrefix + 'Related_Object_7_Lookup_from_RO6__c',
            namespacePrefix + 'Related_Object_7_Lookup_to_RO6__c',
            namespacePrefix + 'Related_Object_7_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_8__c',
            namespacePrefix + 'Related_Object_8_Lookup_from_RO7__c',
            namespacePrefix + 'Related_Object_8_Lookup_to_RO7__c',
            namespacePrefix + 'Related_Object_8_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_9__c',
            namespacePrefix + 'Related_Object_9_Lookup_from_RO8__c',
            namespacePrefix + 'Related_Object_9_Lookup_to_RO8__c',
            namespacePrefix + 'Related_Object_9_Shared_To_Field__c',
    
            namespacePrefix + 'Related_Object_10__c',
            namespacePrefix + 'Related_Object_10_Lookup_from_RO9__c',
            namespacePrefix + 'Related_Object_10_Lookup_to_RO9__c',
            namespacePrefix + 'Related_Object_10_Shared_To_Field__c'
        };

        this.mdNamePrefix = 'FormulaShare_Rule__mdt.';
    }
}
