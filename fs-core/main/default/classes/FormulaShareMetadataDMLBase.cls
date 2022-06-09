public abstract inherited sharing class FormulaShareMetadataDMLBase {

    protected String mdNamePrefix;              // Set to the name of the metadata type
    protected List<String> fieldsToSet;                             // Custom fields to be set if included, otherwise unchanged
    protected List<String> fieldsToSetOrClear = new List<String>(); // Custom fields to be set if included, otherwise cleared

    protected String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();

    private FormulaShareCMDTRetriever retriever;
    
    public FormulaShareMetadataDMLBase() {
        this.retriever = new FormulaShareCMDTRetriever();
    }
    @TestVisible
    private FormulaShareMetadataDMLBase(FormulaShareCMDTRetriever retriever) {
        this.retriever = retriever;
    }

    // Subclasses can handle deployment success and errors by implementing methods below
    public abstract void handleDeploySuccess(Metadata.DeployResult result);
    public abstract void handleDeployError(Metadata.DeployResult result);


    public Id submitCreate(Map<String,SObject> mdMap) {
        Metadata.DeployContainer container = makeCmdtContainerCreate(mdMap);
        return deployContainer(container);
    }

    public Id submitEdit(Map<String,SObject> mdMap) {
        Metadata.DeployContainer container = makeCmdtContainerUpdate(mdMap);
        return deployContainer(container);
    }

    private Id deployContainer(Metadata.DeployContainer container) {
        DeployCallback callback = new DeployCallback(this);
        Id asyncResultId = Metadata.Operations.enqueueDeployment(container, callback);
        return asyncResultId;
    }
    

    // Method is kept separate from update - otherwise we'd need to compoare and merge lists of cmdt value lists
    private Metadata.DeployContainer makeCmdtContainerCreate(Map<String,SObject> mdMapNew) {

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // For each supplied md record, create a cmdt and populate with values
        for(String recordName : mdMapNew.keySet()) {

            SObject mdNew = mdMapNew.get(recordName);
            Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();

            // Set name and label directly
            cmdt.fullName = namespacePrefix + mdNamePrefix + recordName;
            cmdt.label = (String) mdNew.get('MasterLabel');

            List<String> fieldNames = new List<String>();
            fieldNames.addAll(fieldsToSet);
            fieldNames.addAll(fieldsToSetOrClear);

            // Set metadata values for each field supplied
            List<Metadata.CustomMetadataValue> valuesList = new List<Metadata.CustomMetadataValue>();
            for(String fieldName : fieldNames) {
                Metadata.CustomMetadataValue value = getMetadataValue(mdNew, fieldName);
                valuesList.add(value);
            }
            cmdt.values = valuesList;

            container.addMetadata(cmdt);
        }

        return container;
    }


    private Metadata.DeployContainer makeCmdtContainerUpdate(Map<String,SObject> mdMapNew) {
        
        // Build metadata API format full names and retrieve metadata
        List<String> mdRecordNames = new List<String>();
        for (String recordName : mdMapNew.keySet()) {
            mdRecordNames.add(namespacePrefix + mdNamePrefix + recordName);
        }
        
        List<Metadata.Metadata> retrievedRecords;
        retrievedRecords = retriever.retrieve(mdRecordNames);
//        if(!Test.isRunningTest()) {
//            retrievedRecords = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, mdRecordNames);
//        }
//        else {
//            retrievedRecords = testRecords;
//        }

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Loop through md records and assign values supplied
        for(Metadata.Metadata record : retrievedRecords) {
            Metadata.CustomMetadata cmdt = (Metadata.CustomMetadata) record;

            String mdRecordName = record.fullName.substringAfter('.');
            SObject mdNew = mdMapNew.get(mdRecordName);

            // If developer name and label are populated, set these in the metadata
            if(mdNew.get('DeveloperName') != null && mdNew.get('MasterLabel') != null) {
                cmdt.fullName = namespacePrefix + mdNamePrefix + mdNew.get('DeveloperName');
                cmdt.label = (String) mdNew.get('MasterLabel');
            }

            setFieldsOnUpdate(cmdt, mdNew);

            container.addMetadata(cmdt);
        }

        return container;
    }


    // Sets all supplied fields, and clears fields which weren't supplied if they're in the fieldsToSetOrClear list
    private Metadata.CustomMetadata setFieldsOnUpdate(Metadata.CustomMetadata cmdt, SObject mdNew) {

        // Loop through field values
        for (Metadata.CustomMetadataValue cmdtFieldValue : cmdt.values) {

            String fieldName = getFieldWithNamespace(cmdtFieldValue);

            // If a value for this field was supplied, set this
            if(mdNew.get(fieldName) != null) {
                system.debug('adding '+fieldName+' setting to : '+mdNew.get(fieldName));
                cmdtFieldValue.value = mdNew.get(fieldName);
            }

            // Otherwise if field is one to be cleared and isn't supplied, set to null
            else if(fieldsToSetOrClear.contains(fieldName)) {
                system.debug('clearing '+fieldName);
                cmdtFieldValue.value = null;
            }
        }

        return cmdt;
    }


    // Namespaces included in package but not in namespaced scratch orgs. Strip out if present and append to be sure it's there
    private String getFieldWithNamespace(Metadata.CustomMetadataValue cmdtFieldValue) {
        String fieldWithoutNamespace = cmdtFieldValue.field.remove(namespacePrefix);
        return namespacePrefix + fieldWithoutNamespace;
    }

    private Metadata.CustomMetadataValue getMetadataValue(SObject md, String fieldName) {
        Metadata.CustomMetadataValue cmdtFieldValue = new Metadata.CustomMetadataValue();
        cmdtFieldValue.field = fieldName;
        cmdtFieldValue.value = md.get(fieldName);
        return cmdtFieldValue;
    }


    // Manage post-callback logic and call methods (overridable in subclasses) on success and failure
    private class DeployCallback implements Metadata.DeployCallback {

        private FormulaShareMetadataDMLBase instance;
        public DeployCallback(FormulaShareMetadataDMLBase instance) {
            this.instance = instance;
        }
        
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            if (result.status == Metadata.DeployStatus.Succeeded) {
                system.debug('Deploy job successful');
                instance.handleDeploySuccess(result);
            }
            
            else {
                system.debug('Issue processing metadata deployment job. Status:'+result.status);
                for(Metadata.DeployMessage message : result.details.componentFailures) {
                    system.debug('Deployment failure message: '+message);
                }
                instance.handleDeployError(result);
            }
        }
    }

}
