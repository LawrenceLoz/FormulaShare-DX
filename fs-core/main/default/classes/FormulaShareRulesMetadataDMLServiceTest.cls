@IsTest
public with sharing class FormulaShareRulesMetadataDMLServiceTest {

    private static FormulaShare_Rule__mdt getTestRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();
        rule.DeveloperName = 'Test_FS_Rule';
        rule.MasterLabel = 'Test FS Rule';
        rule.Object_Shared__c = prefix + 'FormulaShare_Log__c';
        rule.Shared_To__c = 'Failed_Batches__c';
        rule.Share_With__c = 'Roles and Internal Subordinates';
        rule.Access_Level__c = 'Read';
        rule.Active__c = true;
        rule.Shared_To_Field_Type__c = 'Name';
        rule.Sharing_Reason__c = prefix + 'FormulaShare_Log_Share__c';
        rule.Description__c = 'This is a description';
        return rule;
    }

    @IsTest
    public static void testCreateRule() {

        FormulaShare_Rule__mdt rule = getTestRule();
        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);

        Metadata.DeployContainer container = FormulaShareRulesMetadataDMLService.construct().createRulesContainer(ruleMap);

        List<Metadata.Metadata> contents = container.getMetadata();
        System.assertEquals(1, contents.size(), 'Expected one rule in deployment container');
    }

    @IsTest
    public static void testUpdateRule() {

        // Construct a metadata list to populate the testvisible variable
        // (means we can avoid relying an actual retrieve operation in the test)
        FormulaShare_Rule__mdt rule = getTestRule();
        Map<String,FormulaShare_Rule__mdt> ruleMap = new Map<String,FormulaShare_Rule__mdt>();
        ruleMap.put(rule.DeveloperName, rule);
        FormulaShareRulesMetadataDMLService service = FormulaShareRulesMetadataDMLService.construct();
        Metadata.DeployContainer containerForTest = service.createRulesContainer(ruleMap);
        service.testRecords = containerForTest.getMetadata();

        Metadata.DeployContainer container = service.updateRulesContainer(ruleMap, 'edit');

        List<Metadata.Metadata> contents = container.getMetadata();
        System.assertEquals(1, contents.size(), 'Expected one rule in deployment container');
    }

    @IsTest
    public static void testEditSuccessCallback() {

        // Instantiate the callback.
        FormulaShareRulesMetadataDMLService.RuleCallback rc = new FormulaShareRulesMetadataDMLService.RuleCallback('edit');

        // Create test result (with failure message) and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Handle mocked result and context
        rc.handleResult(result, context);

        // Check platform event fired
        System.assertEquals(1,rc.eventsDmlList.size(), 'Expected a single event to be published');
    }

    @IsTest
    public static void testActivateSuccessCallback() {

        // Instantiate the callback.
        FormulaShareRulesMetadataDMLService.RuleCallback rc = new FormulaShareRulesMetadataDMLService.RuleCallback('activate');

        // Create test result (with failure message) and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Handle mocked result and context
        rc.handleResult(result, context);

        // Check platform event fired
        System.assertEquals(1,rc.eventsViewList.size(), 'Expected a single event to be published');
    }
    

    @IsTest
    public static void testCreateFailureCallback() {

        // Instantiate the callback.
        FormulaShareRulesMetadataDMLService.RuleCallback rc = new FormulaShareRulesMetadataDMLService.RuleCallback('create');

        // Create test result (with failure message) and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        Metadata.DeployDetails details = new Metadata.DeployDetails();
        Metadata.DeployMessage message = new Metadata.DeployMessage();
        message.problem = 'This is a problem';
        List<Metadata.DeployMessage> messageList = new List<Metadata.DeployMessage>{message};
        details.componentFailures = messageList;
        result.details = details;
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Handle mocked result and context
        rc.handleResult(result, context);

        // Check platform event fired
        System.assertEquals(1,rc.eventsDmlList.size(), 'Expected a single event to be published');
    }
}