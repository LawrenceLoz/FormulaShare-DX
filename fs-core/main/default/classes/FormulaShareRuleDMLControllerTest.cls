@IsTest
public with sharing class FormulaShareRuleDMLControllerTest {

    static void setMocks() {
        FormulaShareRulesMetadataDMLService mockDmlService = (FormulaShareRulesMetadataDMLService) FormulaShareMockUtil.createMock(FormulaShareRulesMetadataDMLService.class);
        FormulaShareRulesMetadataDMLService.mock = mockDmlService;

        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;
    }

    static Id expectedId = FormulaShareMockProvider.expectedMockId;


    @IsTest
    public static void testRuleStringToRule() {
        FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
        String ruleString = JSON.serialize(rule);

        FormulaShare_Rule__mdt mdRule = FormulaShareRuleDMLController.ruleStringToRule(ruleString);

        System.assertEquals(rule.developerName, mdRule.DeveloperName, 'Developer name not set as expected');
        System.assertEquals(rule.objectSharedAPIName, mdRule.Object_Shared__c, 'Object shared not set as expected');
        System.assertEquals(rule.controllingObjectSharedToFieldType, mdRule.Shared_To_Field_Type__c, 'No child object so should have set shared to field for standard rule');
    }

    @IsTest
    public static void testCreateSubmission() {
        setMocks();
        FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
        String ruleString = JSON.serialize(rule);

        Id returnedId = FormulaShareRuleDMLController.submitForCreate(ruleString);
        System.assertEquals(expectedId, returnedId, 'Id not returned as expected');
    }

    @IsTest
    public static void testEditSubmission() {
        setMocks();
        FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
        String ruleString = JSON.serialize(rule);

        Id returnedId = FormulaShareRuleDMLController.submitForEdit(ruleString);
        System.assertEquals(expectedId, returnedId, 'Id not returned as expected');
    }

}