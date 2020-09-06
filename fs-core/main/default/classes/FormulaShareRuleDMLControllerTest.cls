@IsTest
public with sharing class FormulaShareRuleDMLControllerTest {

    static void setMocks() {
        FormulaShareRulesMetadataDMLService mockDmlService = (FormulaShareRulesMetadataDMLService) FormulaShareMockUtil.createMock(FormulaShareRulesMetadataDMLService.class);
        FormulaShareRulesMetadataDMLService.mock = mockDmlService;

        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;
    }

    static Id expectedId = UserInfo.getUserId();

    private static FormulaShareRuleDMLController.ComponentRule getComponentRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleDMLController.ComponentRule cr = new FormulaShareRuleDMLController.ComponentRule();
        cr.ruleName = 'Test_FS_Rule';
        cr.ruleLabel = 'Test FS Rule';
        FormulaShareRuleDMLController.ComponentSharedObject cso = new FormulaShareRuleDMLController.ComponentSharedObject();
        cso.objectApiName = prefix + 'FormulaShare_Log__c';
        cr.sharedObject = cso;
        cr.shareField = 'Failed_Batches__c';
        cr.shareWith = 'Roles and Internal Subordinates';
        cr.accessLevel = 'Read';
        cr.ruleActive = true;
        cr.shareFieldType = 'Name';
        cr.sharingReason = prefix + 'FormulaShare_Log_Share__c';
        cr.ruleDescription = 'This is a description';
        cr.ruleType = 'standard';
        return cr;
    }

    private static String getStringifiedComponentRule() {
        return JSON.serialize(getComponentRule());
    }

    @IsTest
    public static void testCreateSubmission() {
        setMocks();
        String crString = getStringifiedComponentRule();
        Id returnedId = FormulaShareRuleDMLController.submitForCreate(crString);
        System.assertEquals(expectedId, returnedId, 'Id not returned as expected');
    }

    @IsTest
    public static void testEditSubmission() {
        setMocks();
        String crString = getStringifiedComponentRule();
        Id returnedId = FormulaShareRuleDMLController.submitForEdit(crString);
        System.assertEquals(expectedId, returnedId, 'Id not returned as expected');
    }    

}