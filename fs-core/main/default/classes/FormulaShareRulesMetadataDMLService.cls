public inherited sharing class FormulaShareRulesMetadataDMLService {


    public static Id updateRules(Map<String,FormulaShareRule> rulesMap, String type) {

        // Retrieve metadata
        List<String> ruleFullNames = new List<String>();
        for (String recordName : rulesMap.keySet()) {
            ruleFullNames.add('FormulaShare_Rule.' + recordName);
        }
        List<Metadata.Metadata> records = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, ruleFullNames);

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Loop through rules and assign values supplied
        for(Metadata.Metadata record : records) {
            Metadata.CustomMetadata rule = (Metadata.CustomMetadata) record;
            String ruleRecordName = rule.fullName.substringAfter('.');
            FormulaShareRule ruleToCopy = rulesMap.get(ruleRecordName);          

            // Map field values from records in map
            for (Metadata.CustomMetadataValue ruleFieldValue : rule.values) {
                switch on ruleFieldValue.field {
                    when 'Active__c' { ruleFieldValue.value = ruleToCopy.active; }
                }
            }

            // Add record to the container
            container.addMetadata(rule);
        }

        String deployType;
        if(type == 'activate' || type == 'deactivate') {
            deployType = type;
        }

        RuleCallback callback = new RuleCallback(deployType);
        Id asyncResultId = Metadata.Operations.enqueueDeployment(container, callback);
        return asyncResultId;
    }

    public class RuleCallback implements Metadata.DeployCallback {
        String deployType;

        RuleCallback(String deployType) {
            this.deployType = deployType;
        }

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            if (result.status == Metadata.DeployStatus.Succeeded) {
                // Deployment was successful
                system.debug('Job complete, publishing');
                List<FormulaShare_List_Update__e> eventsList = new List<FormulaShare_List_Update__e>();
                FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
                updateEvent.Type__c = deployType;
                eventsList.add(updateEvent);
                List<Database.SaveResult> results = EventBus.publish(eventsList);
            }
            
            else {
                // Deployment was not successful
            }
        }
    }

}
