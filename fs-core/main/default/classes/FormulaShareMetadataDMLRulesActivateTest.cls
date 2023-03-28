// Note that most generic functionality from FormulaShareMetadataDMLBase is tested 
// in FormulaShareMetadataDMLRulesTest - this class looks at activation specific things only

@IsTest
public with sharing class FormulaShareMetadataDMLRulesActivateTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    @IsTest
    static void testConstructor() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareMetadataDMLRulesActivate dmlService = new FormulaShareMetadataDMLRulesActivate();
            String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();
            System.assert(dmlService.fieldsToSetOrClear.contains(namespacePrefix + 'Active__c'), 'Active__c should be included in set');
        }
    }

    @IsTest
    public static void testEditSuccessCallback() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Instantiate the callback.
            FormulaShareMetadataDMLRulesActivate instance = new FormulaShareMetadataDMLRulesActivate();
            FormulaShareMetadataDMLBase.DeployCallback dc = new FormulaShareMetadataDMLBase.DeployCallback(instance);

            // Create successful deploy result to be handled
            Metadata.DeployResult result = new Metadata.DeployResult();
            result.status = Metadata.DeployStatus.Succeeded;
            Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

            // Handle mocked result and context
            Test.startTest();
            dc.handleResult(result, context);
            Test.stopTest();

            System.assertEquals(1, instance.eventsViewList.size(), 'Expected a single event to be published');
            System.assertEquals('activate', instance.eventsViewList[0].Type__c, 'Type should have been populated in event');
        }
    }
}
