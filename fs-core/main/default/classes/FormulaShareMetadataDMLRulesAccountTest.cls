// Note that most generic functionality from FormulaShareMetadataDMLBase is tested 
// in FormulaShareMetadataDMLRulesTest - this class looks at account specific things only

@IsTest
public with sharing class FormulaShareMetadataDMLRulesAccountTest {


    // Simulates making an an account rule to a rule sharing a different object and checks relevant fields cleared
    @IsTest
    static void testMakeCmdtContainerEditFields() {

        FormulaShare_Rule__mdt currentRule = FormulaShareRuleFactory.getAccountRule().transformRuleToMetadataRule();
        List<Metadata.Metadata> mdList = FormulaShareTestUtils.cmdtToMetadataList(currentRule);
        FormulaShareMetadataDMLRulesAccount dmlRules = new FormulaShareMetadataDMLRulesAccount(FormulaShareMetadataDMLRulesTest.getMockBroker(mdList));

        // Change the rule to accounts in RO and modify related object access
        FormulaShare_Rule__mdt ruleWithUpdate = FormulaShareRuleFactory.getAccountRuleUpdated().transformRuleToMetadataRule();
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
            if(customField.field == namespace + 'Opportunity_Access__c') {
                System.assertEquals(currentRule.get(customField.field), customField.value, 'Opps related access (not specified) should NOT be cleared and should be as per original rule');
                noChecks++;
            }
            else if(customField.field == namespace + 'Contact_Access__c') {
                System.assertEquals('ControlledByParent', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
            else if(customField.field == namespace + 'Case_Access__c') {
                System.assertEquals('ControlledByParent', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
            else if(customField.field == namespace + 'Access_Level__c') {
                System.assertEquals('Read', customField.value, 'Should have been updated to reflect change');
                noChecks++;
            }
        }
        System.assertEquals(4, noChecks, 'Expected 4 checks - suggests one or more fields not populated?');
    }

}
