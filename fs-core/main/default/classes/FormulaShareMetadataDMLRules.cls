public inherited sharing virtual class FormulaShareMetadataDMLRules extends FormulaShareMetadataDMLBase {

    public FormulaShareMetadataDMLRules() {
        super();
        configureBase();
    }
    @TestVisible
    protected FormulaShareMetadataDMLRules(FormulaShareMetadataBroker broker) {
        super(broker);
        configureBase();
    }

    private void configureBase() {

        // Oddly, field names from retrieved metadata come back lower case - transform everything so 
        // the set contains() method works as expected against this
        this.fieldsToSet = new Set<String> {
            namespacePrefix + 'Active__c'.toLowercase(),
            namespacePrefix + 'Description__c'.toLowercase(),
            namespacePrefix + 'Object_Shared__c'.toLowercase(),
            namespacePrefix + 'Share_With__c'.toLowercase(),
            namespacePrefix + 'Access_Level__c'.toLowercase(),
            namespacePrefix + 'Sharing_Reason__c'.toLowercase()
        };

        this.fieldsToSetOrClear = new Set<String> {
            namespacePrefix + 'Contact_Access__c'.toLowercase(),
            namespacePrefix + 'Case_Access__c'.toLowercase(),
            namespacePrefix + 'Opportunity_Access__c'.toLowercase(),

            namespacePrefix + 'Shared_To_Field_Type__c'.toLowercase(),
            namespacePrefix + 'Child_Object_Shared_To_Field_Type__c'.toLowercase(),
    
            namespacePrefix + 'Shared_To__c'.toLowercase(),
    
            namespacePrefix + 'Child_Object_with_Shared_To_Field__c'.toLowercase(),
            namespacePrefix + 'Child_Object_Lookup_Field__c'.toLowercase(),
            namespacePrefix + 'Related_Object_1_Lookup_from_Shared_Obj__c'.toLowercase(),
            namespacePrefix + 'Child_Object_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_2__c'.toLowercase(),
            namespacePrefix + 'Related_Object_2_Lookup_from_RO1__c'.toLowercase(),
            namespacePrefix + 'Related_Object_2_Lookup_to_RO1__c'.toLowercase(),
            namespacePrefix + 'Related_Object_2_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_3__c'.toLowercase(),
            namespacePrefix + 'Related_Object_3_Lookup_from_RO2__c'.toLowercase(),
            namespacePrefix + 'Related_Object_3_Lookup_to_RO2__c'.toLowercase(),
            namespacePrefix + 'Related_Object_3_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_4__c'.toLowercase(),
            namespacePrefix + 'Related_Object_4_Lookup_from_RO3__c'.toLowercase(),
            namespacePrefix + 'Related_Object_4_Lookup_to_RO3__c'.toLowercase(),
            namespacePrefix + 'Related_Object_4_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_5__c'.toLowercase(),
            namespacePrefix + 'Related_Object_5_Lookup_from_RO4__c'.toLowercase(),
            namespacePrefix + 'Related_Object_5_Lookup_to_RO4__c'.toLowercase(),
            namespacePrefix + 'Related_Object_5_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_6__c'.toLowercase(),
            namespacePrefix + 'Related_Object_6_Lookup_from_RO5__c'.toLowercase(),
            namespacePrefix + 'Related_Object_6_Lookup_to_RO5__c'.toLowercase(),
            namespacePrefix + 'Related_Object_6_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_7__c'.toLowercase(),
            namespacePrefix + 'Related_Object_7_Lookup_from_RO6__c'.toLowercase(),
            namespacePrefix + 'Related_Object_7_Lookup_to_RO6__c'.toLowercase(),
            namespacePrefix + 'Related_Object_7_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_8__c'.toLowercase(),
            namespacePrefix + 'Related_Object_8_Lookup_from_RO7__c'.toLowercase(),
            namespacePrefix + 'Related_Object_8_Lookup_to_RO7__c'.toLowercase(),
            namespacePrefix + 'Related_Object_8_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_9__c'.toLowercase(),
            namespacePrefix + 'Related_Object_9_Lookup_from_RO8__c'.toLowercase(),
            namespacePrefix + 'Related_Object_9_Lookup_to_RO8__c'.toLowercase(),
            namespacePrefix + 'Related_Object_9_Shared_To_Field__c'.toLowercase(),
    
            namespacePrefix + 'Related_Object_10__c'.toLowercase(),
            namespacePrefix + 'Related_Object_10_Lookup_from_RO9__c'.toLowercase(),
            namespacePrefix + 'Related_Object_10_Lookup_to_RO9__c'.toLowercase(),
            namespacePrefix + 'Related_Object_10_Shared_To_Field__c'.toLowercase()
        };

        this.mdNamePrefix = 'FormulaShare_Rule.';
    }

    public override void handleDeploySuccess(Metadata.DeployResult result) {
        publishRuleEvents(result, true);
        system.debug('Published edit/create');
    }

    public override void handleDeployError(Metadata.DeployResult result) {
        publishRuleEvents(result, false);
        System.debug('Error deploying rule DML');
    }

    private void publishRuleEvents(Metadata.DeployResult result, Boolean isSuccess) {
        FormulaShare_Rule_DML__e dmlEvent = new FormulaShare_Rule_DML__e();
        dmlEvent.Successful__c = isSuccess;
        if(!isSuccess && result.details != null && !result.details.componentFailures.isEmpty()) {
            dmlEvent.Error__c = result.details.componentFailures[0].problem;
        }
        eventsDmlList.add(dmlEvent);
        List<Database.SaveResult> results = EventBus.publish(eventsDmlList);
    }

}
