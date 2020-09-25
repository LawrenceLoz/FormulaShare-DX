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

    // Get metadata container and submit for processing
    public Id submitForDml(Map<String,FormulaShare_Rule__mdt> rulesMap, String type) {
        Metadata.DeployContainer container;
        if(type == 'create') {
            container = createRulesContainer(rulesMap);
        }
        else {
            container = updateRulesContainer(rulesMap);
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

            List<String> fieldNames = new List<String>{
                namespacePrefix + 'Object_Shared__c',
                namespacePrefix + 'Shared_To__c',
                namespacePrefix + 'Share_With__c',
                namespacePrefix + 'Access_Level__c',
                namespacePrefix + 'Active__c',
                namespacePrefix + 'Shared_To_Field_Type__c',
                namespacePrefix + 'Sharing_Reason__c',
                namespacePrefix + 'Contact_Access__c',
                namespacePrefix + 'Case_Access__c',
                namespacePrefix + 'Opportunity_Access__c',
                namespacePrefix + 'Child_Object_with_Shared_To_Field__c',
                namespacePrefix + 'Child_Object_Lookup_Field__c',
                namespacePrefix + 'Child_Object_Shared_To_Field__c',
                namespacePrefix + 'Child_Object_Shared_To_Field_Type__c',
                namespacePrefix + 'Description__c'
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

        return container;
    }


    private Metadata.CustomMetadataValue getMetadataValue(FormulaShare_Rule__mdt fr, String fieldName) {
        Metadata.CustomMetadataValue ruleFieldValue = new Metadata.CustomMetadataValue();
        ruleFieldValue.field = fieldName;
        ruleFieldValue.value = fr.get(fieldName);
        return ruleFieldValue;
    }


    public Metadata.DeployContainer updateRulesContainer(Map<String,FormulaShare_Rule__mdt> rulesMap) {
        
        // Build metadata API format full names and retrieve metadata
        List<String> ruleFullNames = new List<String>();
        for (String recordName : rulesMap.keySet()) {
//            ruleFullNames.add(FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Rule.' + recordName);
            ruleFullNames.add(namespacePrefix + mdNamePrefix + recordName);
        }
        
        List<Metadata.Metadata> records;
        if(!Test.isRunningTest()) {
            records = Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, ruleFullNames);
        }
        else {
            records = testRecords;
        }

        // Create a metadata container for deployment
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        // Loop through rules and assign values supplied
        for(Metadata.Metadata record : records) {
            Metadata.CustomMetadata rule = (Metadata.CustomMetadata) record;

            String ruleRecordName = rule.fullName.substringAfter('.');
            FormulaShare_Rule__mdt ruleToCopy = rulesMap.get(ruleRecordName);

            // If developer name and label are populated, set these in the metadata rule
            if(ruleToCopy.DeveloperName != null && ruleToCopy.MasterLabel != null) {
                rule.fullName = namespacePrefix + mdNamePrefix + ruleToCopy.DeveloperName;
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

            Boolean isAccountRule = ruleToCopy.Object_Shared__c == 'Account';

            // Map field values from records in map
            for (Metadata.CustomMetadataValue ruleFieldValue : rule.values) {

                if(fieldShouldBeCleared(ruleFieldValue, ruleType, isAccountRule)) {
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

        return container;
    }


    private Boolean fieldShouldBeCleared(Metadata.CustomMetadataValue ruleFieldValue, String ruleType, Boolean isAccountRule) {

        // Strip namespace (this is needed to support namespaced scratch orgs, which don't seem to recognise this in queried custom metadata)
        String fieldWithoutNamespace = ruleFieldValue.field.remove(namespacePrefix);

        switch on fieldWithoutNamespace {
            when 'Child_Object_Lookup_Field__c'         { return ruleType == 'standard'; }
            when 'Child_Object_Shared_To_Field__c'      { return ruleType == 'standard'; }
            when 'Child_Object_Shared_To_Field_Type__c' { return ruleType == 'standard'; }
            when 'Child_Object_with_Shared_To_Field__c' { return ruleType == 'standard'; }
            when 'Shared_To__c'                         { return ruleType == 'child';}
            when 'Shared_To_Field_Type__c'              { return ruleType == 'child';}
            when 'Contact_Access__c'                    { return !isAccountRule;}
            when 'Case_Access__c'                       { return !isAccountRule;}
            when 'Opportunity_Access__c'                { return !isAccountRule;}
            when else {return false;}
        }
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