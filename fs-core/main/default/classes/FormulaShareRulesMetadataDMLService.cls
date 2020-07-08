public inherited sharing class FormulaShareRulesMetadataDMLService {

    static String fullNamePrefix = 'FormulaShare_Rule.';

    public static Id createRules(Map<String,FormulaShare_Rule__mdt> rulesMap, String type) {

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Create metadata rules and add to container
        for(String recordName : rulesMap.keySet()) {
            FormulaShare_Rule__mdt fr = rulesMap.get(recordName); 
            Metadata.CustomMetadata rule = new Metadata.CustomMetadata();
            rule.fullName = FormulaShareTestUtils.getNamespacePrefix() + fullNamePrefix + recordName;
            rule.label = fr.MasterLabel;

            List<String> fieldNames = new List<String>{
                'Object_Shared__c',
                'Shared_To__c',
                'Share_With__c',
                'Access_Level__c',
                'Active__c',
                'Shared_To_Field_Type__c',
                'Sharing_Reason__c',
                'Child_Object_with_Shared_To_Field__c',
                'Child_Object_Lookup_Field__c',
                'Child_Object_Shared_To_Field__c',
                'Child_Object_Shared_To_Field_Type__c',
                'Description__c'
            };

            List<Metadata.CustomMetadataValue> valuesList = new List<Metadata.CustomMetadataValue>();
            for(String fieldName : fieldNames) {
                Metadata.CustomMetadataValue value = getMetadataValue(fr, fieldName);
                valuesList.add(value);
            }
            rule.values = valuesList;

            // Add record to the container
            container.addMetadata(rule);
        }

        RuleCallback callback = new RuleCallback('create');
        Id asyncResultId = Metadata.Operations.enqueueDeployment(container, callback);
        return asyncResultId;
    }

    private static Metadata.CustomMetadataValue getMetadataValue(FormulaShare_Rule__mdt fr, String fieldName) {
        Metadata.CustomMetadataValue ruleFieldValue = new Metadata.CustomMetadataValue();
        ruleFieldValue.field = fieldName;
        ruleFieldValue.value = fr.get(fieldName);
        return ruleFieldValue;
    }

    public static Id updateRules(Map<String,FormulaShare_Rule__mdt> rulesMap, String type) {
        
        // Build metadata API format full names and retrieve metadata
        List<String> ruleFullNames = new List<String>();
        for (String recordName : rulesMap.keySet()) {
//            ruleFullNames.add(FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Rule.' + recordName);
            ruleFullNames.add(fullNamePrefix + recordName);
        }
        List<Metadata.Metadata> records = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, ruleFullNames);

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Loop through rules and assign values supplied
        for(Metadata.Metadata record : records) {
            Metadata.CustomMetadata rule = (Metadata.CustomMetadata) record;

            String ruleRecordName = rule.fullName.substringAfter('.');
            FormulaShare_Rule__mdt ruleToCopy = rulesMap.get(ruleRecordName);

            // If both are populated, set name and label
            if(ruleToCopy.DeveloperName != null && ruleToCopy.MasterLabel != null) {
                rule.fullName = fullNamePrefix + ruleToCopy.DeveloperName;
                rule.label = ruleToCopy.MasterLabel;
                system.debug('MasterLabel: '+ruleToCopy.MasterLabel);
                system.debug('rule.fullName: '+rule.fullName);
            }

            String ruleType;
            if(ruleToCopy.Shared_To__c != null) {
                ruleType = 'standard';
            }
            else if(ruleToCopy.Child_Object_with_Shared_To_Field__c != null) {
                ruleType = 'child';
            }

            // Map field values from records in map
            for (Metadata.CustomMetadataValue ruleFieldValue : rule.values) {
                
                // If standard rule, set all child fields to blank
                if(ruleType == 'standard' && (
                    ruleFieldValue.field == 'Child_Object_Lookup_Field__c'
                    || ruleFieldValue.field == 'Child_Object_Shared_To_Field__c'
                    || ruleFieldValue.field == 'Child_Object_Shared_To_Field_Type__c'
                    || ruleFieldValue.field == 'Child_Object_with_Shared_To_Field__c')) {
                    ruleFieldValue.value = null;
                }

                // If child rule, set all standard fields to blank
                else if(ruleType == 'child' && (
                    ruleFieldValue.field == 'Shared_To__c'
                    || ruleFieldValue.field == 'Shared_To_Field_Type__c')) {
                    ruleFieldValue.value = null;
                }

                // Otherwise, check to see if a value for this field was supplied
                else if(ruleToCopy.get(ruleFieldValue.field) != null) {
                    system.debug('adding '+ruleFieldValue.field+' setting to : '+ruleToCopy.get(ruleFieldValue.field));
                    ruleFieldValue.value = ruleToCopy.get(ruleFieldValue.field);
                }
            }

            // Add record to the container
            container.addMetadata(rule);
        }

        RuleCallback callback = new RuleCallback(type);
        Id asyncResultId = Metadata.Operations.enqueueDeployment(container, callback);
        return asyncResultId;
    }


    // Manage post-callback logic to fire events for component updates
    public class RuleCallback implements Metadata.DeployCallback {
        String deployType;

        RuleCallback(String deployType) {
            this.deployType = deployType;
        }

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            if (result.status == Metadata.DeployStatus.Succeeded) {
                // Deployment was successful
                system.debug('Job complete, publishing');

                switch on deployType {
                    when 'activate', 'deactivate' {
                        List<FormulaShare_List_Update__e> eventsList = new List<FormulaShare_List_Update__e>();
                        FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
                        updateEvent.Type__c = deployType;
                        eventsList.add(updateEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsList);
                        system.debug('Published activate/deactivate');
                    }
                    when 'edit', 'create' {
                        List<FormulaShare_Rule_DML__e> eventsList = new List<FormulaShare_Rule_DML__e>();
                        FormulaShare_Rule_DML__e dmlEvent = new FormulaShare_Rule_DML__e();
                        dmlEvent.Type__c = deployType;
                        dmlEvent.Successful__c = true;
                        eventsList.add(dmlEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsList);
                        system.debug('Published edit/create');
                    }
                }
            }
            
            else {
                // Deployment was not successful
                system.debug('Issue processing metadata deployment job. Status:'+result.status);

                switch on deployType {
                    when 'activate', 'deactivate' {
                    }
                    when 'edit','create' {
                        List<FormulaShare_Rule_DML__e> eventsList = new List<FormulaShare_Rule_DML__e>();
                        FormulaShare_Rule_DML__e dmlEvent = new FormulaShare_Rule_DML__e();
                        dmlEvent.Type__c = deployType;
                        dmlEvent.Successful__c = false;
                        if(!result.details.componentFailures.isEmpty()) {
                            dmlEvent.Error__c = result.details.componentFailures[0].problem;
                        }
                        eventsList.add(dmlEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsList);
                    }
                }

                for(Metadata.DeployMessage message : result.details.componentFailures) {
                    system.debug('deployment message: '+message);
                }
            }
        }
    }

}
