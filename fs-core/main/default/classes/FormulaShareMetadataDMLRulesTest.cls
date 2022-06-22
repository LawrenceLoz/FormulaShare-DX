@IsTest
public with sharing class FormulaShareMetadataDMLRulesTest {
    
    public static Id enqueueId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);

    public static FormulaShareMetadataBroker getMockBroker() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        FormulaShareMetadataBroker mockBroker = (FormulaShareMetadataBroker) mocks.mock(FormulaShareMetadataBroker.class);
    
        mocks.startStubbing();
        mocks.when(mockBroker.enqueueDeployment(
                (Metadata.DeployContainer) fflib_Match.anyObject()
                , (Metadata.DeployCallback) fflib_Match.anyObject()))
            .thenReturn(enqueueId);
        mocks.stopStubbing();
    
        return mockBroker;
    }

    public static FormulaShareMetadataBroker getMockBroker(List<Metadata.Metadata> mdList) {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        FormulaShareMetadataBroker mockBroker = (FormulaShareMetadataBroker) mocks.mock(FormulaShareMetadataBroker.class);

        mocks.startStubbing();
        mocks.when(mockBroker.enqueueDeployment(
                (Metadata.DeployContainer) fflib_Match.anyObject()
                , (Metadata.DeployCallback) fflib_Match.anyObject()))
            .thenReturn(enqueueId);
        mocks.when(mockBroker.retrieve(
                (List<String>) fflib_Match.anyList()))
            .thenReturn(mdList);
        mocks.stopStubbing();

        return mockBroker;
    }
    


    @IsTest
    static void testSubmitCreate() {

        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt rule = ruleConverter.getMetadataRule(FormulaShareRuleFactory.getUserRule());

        FormulaShareMetadataDMLRules dmlRules = new FormulaShareMetadataDMLRules(getMockBroker());
        Map<String,SObject> mdMap = FormulaShareUtilities.cmdtToCmdtMap(rule);

        Test.startTest();
        Id returnedId = dmlRules.submitCreate(mdMap);
        Test.stopTest();

        System.assertEquals(enqueueId, returnedId, 'Id not returned as expected');
    }

    @isTest
    static void testUpdate() {

        // Get mocked dmlRules
        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt rule = ruleConverter.getMetadataRule(FormulaShareRuleFactory.getUserRule());

        List<Metadata.Metadata> mdList = FormulaShareTestUtils.cmdtToMetadataList(rule);
        FormulaShareMetadataDMLRules dmlRules = new FormulaShareMetadataDMLRules(getMockBroker(mdList));

        // Make a map with updated rule
        FormulaShare_Rule__mdt ruleWithUpdate = rule.clone();
        ruleWithUpdate.Access_Level__c = 'Read';  // Update access from Edit to Read
        Map<String,SObject> mdMap = FormulaShareUtilities.cmdtToCmdtMap(ruleWithUpdate);

        Test.startTest();
        Id returnedId = dmlRules.submitEdit(mdMap);
        Test.stopTest();

        System.assertEquals(enqueueId, returnedId, 'Id not returned as expected');
    }

    @IsTest
    static void testMakeCmdtContainerCreate() {
        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt rule = ruleConverter.getMetadataRule(FormulaShareRuleFactory.getUserRule());

        Map<String,SObject> mdMapNew = FormulaShareUtilities.cmdtToCmdtMap(rule);
        
        FormulaShareMetadataDMLRules dmlRules = new FormulaShareMetadataDMLRules();

        Test.startTest();
        Metadata.DeployContainer container = dmlRules.makeCmdtContainerCreate(mdMapNew);
        Test.stopTest();

        List<Metadata.Metadata> mdList = container.getMetadata();
        Metadata.CustomMetadata md = (Metadata.CustomMetadata) mdList[0];
        List<Metadata.CustomMetadataValue> customFields = md.values;

        System.assertEquals(1, mdList.size(), 'Expected a single MD object');
        System.assertEquals(md.fullName, FormulaShareTestUtils.namespacePrefix + FormulaShareTestUtils.mdNamePrefix + rule.DeveloperName, 'Rule name should be consistent with namespace, object and rule');
        for(Metadata.CustomMetadataValue customField : customFields) {
            System.assertEquals(rule.get(customField.field), customField.value, 'Field value from md should match rule provided');
        }
    }

    // Simulates updating an account rule to a rule sharing a different object and checks relevant fields cleared
    @IsTest
    static void testMakeCmdtContainerEditFields() {

        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt currentRule = ruleConverter.getMetadataRule(FormulaShareRuleFactory.getAccountRule());

        List<Metadata.Metadata> mdList = FormulaShareTestUtils.cmdtToMetadataList(currentRule);
        FormulaShareMetadataDMLRules dmlRules = new FormulaShareMetadataDMLRules(getMockBroker(mdList));

        // Change the rule to share contacts in RO instead
        FormulaShare_Rule__mdt ruleWithUpdate = ruleConverter.getMetadataRule(FormulaShareRuleFactory.getAccountRuleModifiedToContactRule());

        Map<String,SObject> mdMapNew = FormulaShareUtilities.cmdtToCmdtMap(ruleWithUpdate);

        Test.startTest();
        Metadata.DeployContainer container = dmlRules.makeCmdtContainerEdit(mdMapNew);
        Test.stopTest();

        List<Metadata.Metadata> mdListForDeployment = container.getMetadata();
        Metadata.CustomMetadata md = (Metadata.CustomMetadata) mdListForDeployment[0];
        List<Metadata.CustomMetadataValue> customFields = md.values;

        String namespace = FormulaShareTestUtils.namespacePrefix;

        System.assertEquals(1, mdList.size(), 'Expected a single MD object');
        System.assertEquals(md.fullName, namespace + FormulaShareTestUtils.mdNamePrefix + currentRule.DeveloperName, 'Rule name should be consistent with namespace, object and rule');

        Integer noChecks = 0;

        for(Metadata.CustomMetadataValue customField : customFields) {
            if(customField.field == namespace + 'Contact_Access__c' 
                || customField.field == namespace + 'Case_Access__c' 
                || customField.field == namespace + 'Opportunity_Access__c') {
                System.assertEquals(null, customField.value, 'Account related access should be cleared as rule is converted to a Contact sharing rule');
                noChecks++;
            }
            else if(customField.field == namespace + 'Object_Shared__c') {
                System.assertEquals('Contact', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
            else if(customField.field == namespace + 'Shared_To__c') {
                System.assertEquals('FirstName', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
            else if(customField.field == namespace + 'Access_Level__c') {
                System.assertEquals('Read', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
            else if(customField.field == namespace + 'Share_With__c') {
                System.assertEquals(currentRule.get(customField.field), customField.value, 'Field wasnt changed so should match original rule');
                noChecks++;
            }
        }
        System.assertEquals(7, noChecks, 'Expected 7 checks - suggests one or more fields not populated?');
    }

    @IsTest
    public static void testEditSuccessCallback() {

        // Instantiate the callback.
        FormulaShareMetadataDMLRules instance = new FormulaShareMetadataDMLRules();
        FormulaShareMetadataDMLBase.DeployCallback dc = new FormulaShareMetadataDMLBase.DeployCallback(instance);

        // Create successful deploy result to be handled
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Handle mocked result and context
        Test.startTest();
        dc.handleResult(result, context);
        Test.stopTest();

        // Check platform event added to list
        System.assertEquals(1, instance.eventsDmlList.size(), 'Expected a single event to be published');
    }

    @IsTest
    public static void testCreateFailureCallback() {

        // Instantiate the callback.
        FormulaShareMetadataDMLRules instance = new FormulaShareMetadataDMLRules();
        FormulaShareMetadataDMLBase.DeployCallback dc = new FormulaShareMetadataDMLBase.DeployCallback(instance);

        // Create test result (with failure message) and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        Metadata.DeployDetails details = new Metadata.DeployDetails();
        Metadata.DeployMessage message = new Metadata.DeployMessage();
        result.status = Metadata.DeployStatus.Failed;
        message.problem = 'This is a problem';
        List<Metadata.DeployMessage> messageList = new List<Metadata.DeployMessage>{message};
        details.componentFailures = messageList;
        result.details = details;
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Handle mocked result and context
        Test.startTest();
        dc.handleResult(result, context);
        Test.stopTest();

        // Check platform event added to list
        System.assertEquals(1, instance.eventsDmlList.size(), 'Expected a single event to be published');
        FormulaShare_Rule_DML__e dmlEvent = instance.eventsDmlList[0];
        System.assertEquals(message.problem, dmlEvent.Error__c, 'Problem should be captured on the event as an error');

    }

}
