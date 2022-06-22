@IsTest
public with sharing class FormulaShareMetadataControllerRulesTest {

    @IsTest
    static void testCreate() {
    
        FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
        String ruleString = JSON.serialize(rule);

        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt mdRule = ruleConverter.getMetadataRule(rule);

        Map<String,SObject> mdRuleMap = FormulaShareUtilities.cmdtToCmdtMap(mdRule);

        // Set mock
        Id createId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        FormulaShareMetadataDMLRules mockBroker = (FormulaShareMetadataDMLRules) mocks.mock(FormulaShareMetadataDMLRules.class);
        mocks.startStubbing();
        mocks.when(mockBroker.submitCreate(
                (Map<String,FormulaShare_Rule__mdt>) fflib_Match.anyObject()))
            .thenReturn(createId);
        mocks.stopStubbing();
        FormulaShareMetadataControllerRules.mockDmlService = mockbroker;    // Mock referecned from static class variable

        Test.startTest();
        Id jobId = FormulaShareMetadataControllerRules.submitForCreate(ruleString);
        Test.stopTest();

        mocks.verify(FormulaShareMetadataControllerRules.mockDmlService, 1);
        System.assertEquals(jobId, createId, 'Job id should match mock return for method called');
    }


    @IsTest
    static void testEdit() {
        FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
        String ruleString = JSON.serialize(rule);

        FormulaShareRuleConverterBase ruleConverter = new FormulaShareInjectionService().getRuleConverter();
        FormulaShare_Rule__mdt mdRule = ruleConverter.getMetadataRule(rule);

        Map<String,SObject> mdRuleMap = FormulaShareUtilities.cmdtToCmdtMap(mdRule);

        // Set mock
        Id editId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        FormulaShareMetadataDMLRules mockBroker = (FormulaShareMetadataDMLRules) mocks.mock(FormulaShareMetadataDMLRules.class);
        mocks.startStubbing();
        mocks.when(mockBroker.submitEdit(
                (Map<String,FormulaShare_Rule__mdt>) fflib_Match.anyObject()))
            .thenReturn(editId);
        mocks.stopStubbing();
        FormulaShareMetadataControllerRules.mockDmlService = mockbroker;    // Mock referecned from static class variable

        Test.startTest();
        Id jobId = FormulaShareMetadataControllerRules.submitForEdit(ruleString);
        Test.stopTest();

        mocks.verify(FormulaShareMetadataControllerRules.mockDmlService, 1);
        System.assertEquals(jobId, editId, 'Job id should match mock return for method called');
    }

}
