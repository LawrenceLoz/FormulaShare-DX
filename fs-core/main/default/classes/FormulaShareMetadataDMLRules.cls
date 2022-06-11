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

        this.fieldsToSet = new Set<String> {
            namespacePrefix + 'Active__c',
            namespacePrefix + 'Description__c',
            namespacePrefix + 'Object_Shared__c',
            namespacePrefix + 'Share_With__c',
            namespacePrefix + 'Access_Level__c',
            namespacePrefix + 'Sharing_Reason__c'
        };

        // Clear account related object sharing in case rule is modified from one sharing accounts
        this.fieldsToClear = new Set<String> {
            namespacePrefix + 'Contact_Access__c',
            namespacePrefix + 'Case_Access__c',
            namespacePrefix + 'Opportunity_Access__c'
        };

        this.fieldsToSetOrClear = new Set<String> {
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

    // Kept in class variable so we can test it populates
    @TestVisible
    private List<FormulaShare_Rule_DML__e> eventsDmlList = new List<FormulaShare_Rule_DML__e>();

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
