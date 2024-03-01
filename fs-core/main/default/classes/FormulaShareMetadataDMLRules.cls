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

        // Set or clear any fields which are either set or cleared depending on level of the relationship 
        this.fieldsToSetOrClear = new Set<String> {
            namespacePrefix + 'Shared_To_Field_Type__c',
            namespacePrefix + 'Shared_To__c',
            namespacePrefix + 'Access_For_Team__c',
            namespacePrefix + 'Access_For_Owner_Of_Teams_User_Is_On__c',
            namespacePrefix + 'Access_For_Team_Comembers__c',
            namespacePrefix + 'Metadata_Mapping_Type__c',
            namespacePrefix + 'Metadata_Mapping_Match_Field__c',
            namespacePrefix + 'Metadata_Mapping_Shared_To_Field__c'
        };
        this.fieldsToSetOrClear.addAll(new FormulaShareInjectionService().getExtraRelationshipFields());

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
