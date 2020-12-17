/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public inherited sharing class FormulaShareRulesMetadataDMLService {

    public static FormulaShareRulesMetadataDMLService mock;
    public static FormulaShareRulesMetadataDMLService construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareRulesMetadataDMLService();
        }
    }
    @TestVisible List<Metadata.Metadata> testRecords;

    String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();
    String mdNamePrefix = 'FormulaShare_Rule.';

    // Collections of all field names on custom metadata type
    List<String> generalFieldNames = new List<String>{
        namespacePrefix + 'Description__c',
        namespacePrefix + 'Object_Shared__c',
        namespacePrefix + 'Shared_To__c',
        namespacePrefix + 'Share_With__c',
        namespacePrefix + 'Access_Level__c',
        namespacePrefix + 'Active__c',
        namespacePrefix + 'Sharing_Reason__c'
    };

    // Account related sharing settings will be cleared if account rule changed to share another object
    Set<String> accountSharingFieldNamesSet = new Set<String>{
        namespacePrefix + 'Contact_Access__c',
        namespacePrefix + 'Case_Access__c',
        namespacePrefix + 'Opportunity_Access__c'
    };

    // Relationship-specific ones are in a separate set as we'll clear these explicitly if they're not set
    Set<String> relationshipSpecificFieldsSet = new Set<String> {
        namespacePrefix + 'Shared_To_Field_Type__c',
        namespacePrefix + 'Child_Object_Shared_To_Field_Type__c',

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

    // Get metadata container and submit for processing
    public Id submitForDml(Map<String,FormulaShare_Rule__mdt> rulesMap, String type) {
        Metadata.DeployContainer container;
        if(type == 'create') {
            container = createRulesContainer(rulesMap);
        }
        else {
            container = updateRulesContainer(rulesMap, type);
        }
        RuleCallback callback = new RuleCallback(type);
        Id asyncResultId = Metadata.Operations.enqueueDeployment(container, callback);
        return asyncResultId;
    }


    public Metadata.DeployContainer createRulesContainer(Map<String,FormulaShare_Rule__mdt> rulesMap) {

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Create metadata rules and add to container
        for(String recordName : rulesMap.keySet()) {
            FormulaShare_Rule__mdt fr = rulesMap.get(recordName); 
            Metadata.CustomMetadata rule = new Metadata.CustomMetadata();
            rule.fullName = namespacePrefix + mdNamePrefix + recordName;
            rule.label = fr.MasterLabel;

            List<String> fieldNames = new List<String>();
            fieldNames.addAll(generalFieldNames);
            fieldNames.addAll(accountSharingFieldNamesSet);
            fieldNames.addAll(relationshipSpecificFieldsSet);

            List<Metadata.CustomMetadataValue> valuesList = new List<Metadata.CustomMetadataValue>();
            for(String fieldName : fieldNames) {
                Metadata.CustomMetadataValue value = getMetadataValue(fr, fieldName);
                valuesList.add(value);
            }
            rule.values = valuesList;

            // Add record to the container
            container.addMetadata(rule);
        }

        return container;
    }


    private Metadata.CustomMetadataValue getMetadataValue(FormulaShare_Rule__mdt fr, String fieldName) {
        Metadata.CustomMetadataValue ruleFieldValue = new Metadata.CustomMetadataValue();
        ruleFieldValue.field = fieldName;
        ruleFieldValue.value = fr.get(fieldName);
        return ruleFieldValue;
    }


    public Metadata.DeployContainer updateRulesContainer(Map<String,FormulaShare_Rule__mdt> rulesMap, String type) {
        
        // Build metadata API format full names and retrieve metadata
        List<String> ruleFullNames = new List<String>();
        for (String recordName : rulesMap.keySet()) {
            ruleFullNames.add(namespacePrefix + mdNamePrefix + recordName);
        }
        
        List<Metadata.Metadata> retrievedRecords;
        if(!Test.isRunningTest()) {
            retrievedRecords = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, ruleFullNames);
        }
        else {
            retrievedRecords = testRecords;
        }

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Loop through rules and assign values supplied
        for(Metadata.Metadata record : retrievedRecords) {
            Metadata.CustomMetadata rule = (Metadata.CustomMetadata) record;

            String ruleRecordName = rule.fullName.substringAfter('.');
            FormulaShare_Rule__mdt ruleNewValues = rulesMap.get(ruleRecordName);

            // If developer name and label are populated, set these in the metadata rule
            if(ruleNewValues.DeveloperName != null && ruleNewValues.MasterLabel != null) {
                rule.fullName = namespacePrefix + mdNamePrefix + ruleNewValues.DeveloperName;
                rule.label = ruleNewValues.MasterLabel;
                system.debug('MasterLabel: '+ruleNewValues.MasterLabel);
                system.debug('rule.fullName: '+rule.fullName);
            }

            // Set and clear other fields as appropriate
            switch on type {

                // For activate and deavtive, map this field only
                when 'activate', 'deactivate' {
                    rule = mapActivate(rule, type);
                }
                when 'edit' {
                    rule = mapAllFields(rule, ruleNewValues);
//                    rule = clearInvalidFields(rule, ruleNewValues);
                }
            }

            // Add record to the container
            container.addMetadata(rule);
        }

        return container;
    }

    private Metadata.CustomMetadata mapActivate(Metadata.CustomMetadata rule, String type) {

        // Loop through field values and set Active based on change made
        for (Metadata.CustomMetadataValue ruleFieldValue : rule.values) {
            if(ruleFieldValue.field.remove(namespacePrefix) == 'Active__c') {
                ruleFieldValue.value = type == 'activate' ? true : false;
            }
        }
        return rule;
    }


    private Metadata.CustomMetadata mapAllFields(Metadata.CustomMetadata rule, FormulaShare_Rule__mdt ruleNewValues) {

        // Loop through field values
        for (Metadata.CustomMetadataValue ruleFieldValue : rule.values) {

            // Namespaces included in package but not in namespaced scratch orgs. Strip out if present and append to be sure it's there
            String fieldWithoutNamespace = ruleFieldValue.field.remove(namespacePrefix);
            String fieldWithNamespace = namespacePrefix + fieldWithoutNamespace;

            // If a value for this field was supplied, set this in the rule
            if(ruleNewValues.get(fieldWithNamespace) != null) {
                system.debug('adding '+fieldWithNamespace+' setting to : '+ruleNewValues.get(fieldWithNamespace));
                ruleFieldValue.value = ruleNewValues.get(fieldWithNamespace);
            }

//            System.debug('fieldWithNamespace: '+fieldWithNamespace);
//            System.debug('field set: '+relationshipSpecificFieldsSet);
//
            // Clear all relationship fields which aren't set explicitly
            else if(relationshipSpecificFieldsSet.contains(fieldWithNamespace)) {
                system.debug('clearing '+fieldWithNamespace);
                ruleFieldValue.value = null;
            }

            // Clear account share fields if they weren't set (in case account rule changed to share another object)
            else if(ruleNewValues.Object_Shared__c != 'Account' && accountSharingFieldNamesSet.contains(fieldWithNamespace)) {
                system.debug('clearing '+fieldWithNamespace);
                ruleFieldValue.value = null;
            }
        }
        return rule;
    }


    // Manage post-callback logic to fire events for component updates
    public class RuleCallback implements Metadata.DeployCallback {
        String deployType;
        @TestVisible List<FormulaShare_List_Update__e> eventsViewList;
        @TestVisible List<FormulaShare_Rule_DML__e> eventsDmlList;
        
        public RuleCallback(String deployType) {
            this.deployType = deployType;
        }

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            if (result.status == Metadata.DeployStatus.Succeeded) {
                // Deployment was successful
                system.debug('Job complete, publishing');

                switch on deployType {
                    when 'activate', 'deactivate' {
                        eventsViewList = new List<FormulaShare_List_Update__e>();
                        FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
                        updateEvent.Type__c = deployType;
                        eventsViewList.add(updateEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsViewList);
                        system.debug('Published activate/deactivate');
                    }
                    when 'edit', 'create' {
                        eventsDmlList = new List<FormulaShare_Rule_DML__e>();
                        FormulaShare_Rule_DML__e dmlEvent = new FormulaShare_Rule_DML__e();
                        dmlEvent.Type__c = deployType;
                        dmlEvent.Successful__c = true;
                        eventsDmlList.add(dmlEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsDmlList);
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
                        eventsDmlList = new List<FormulaShare_Rule_DML__e>();
                        FormulaShare_Rule_DML__e dmlEvent = new FormulaShare_Rule_DML__e();
                        dmlEvent.Type__c = deployType;
                        dmlEvent.Successful__c = false;
                        if(!result.details.componentFailures.isEmpty()) {
                            dmlEvent.Error__c = result.details.componentFailures[0].problem;
                        }
                        eventsDmlList.add(dmlEvent);
                        List<Database.SaveResult> results = EventBus.publish(eventsDmlList);
                    }
                }

                for(Metadata.DeployMessage message : result.details.componentFailures) {
                    system.debug('deployment message: '+message);
                }
            }
        }
    }

}