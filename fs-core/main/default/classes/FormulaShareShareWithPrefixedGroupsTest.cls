/**
 * Tests for FormulaShareShareWithPrefixedGroups abstract base class.
 * Uses a concrete test implementation to validate the base class behavior.
 */
@IsTest
public with sharing class FormulaShareShareWithPrefixedGroupsTest {

    private static fflib_ApexMocks mocks = new fflib_ApexMocks();

    /**
     * Concrete test implementation of the abstract base class
     */
    private class TestPrefixedHandler extends FormulaShareShareWithPrefixedGroups {
        private String prefix;
        private String label;

        public TestPrefixedHandler(FormulaShareService service, String prefix, 
            String label) {
            this.service = service;
            this.prefix = prefix;
            this.label = label;
        }

        protected override String getPrefix() {
            return this.prefix;
        }

        protected override String getShareWithLabel() {
            return this.label;
        }
    }

    private static FormulaShareService.RecordRule getRecordRule(String type, 
        String shareWithLabel) {
        
        FormulaShareService.RecordRule recRule = 
            new FormulaShareService.RecordRule();
        recRule.recordToShare = new FormulaShare_Log__c();
        recRule.recordWithSharedToDetails = recRule.recordToShare;
        recRule.rule = new FormulaShareRule();
        recRule.rule.shareWith = shareWithLabel;
        recRule.rule.controllingObjectSharedToFieldType = type;
        return recRule;
    }

    private static Group getValidGroup() {
        return getValidGroups()[0];
    }

    private static List<Group> getValidGroups() {
        return [SELECT Id, DeveloperName FROM Group 
        WHERE Type = 'Regular' OR Type = 'Queue' OR Type = 'Organization' LIMIT 2];
    }
    
    private static Id getSharedToArgumentFromUpdateShareMaps(
        FormulaShareService serviceMock) {
        
        fflib_ArgumentCaptor recordIdArg = 
            fflib_ArgumentCaptor.forClass(Id.class);
        fflib_ArgumentCaptor sharedToArg = 
            fflib_ArgumentCaptor.forClass(Id.class);
        fflib_ArgumentCaptor targetAccessLevelArg = 
            fflib_ArgumentCaptor.forClass(String.class);
        fflib_ArgumentCaptor ruleArg = 
            fflib_ArgumentCaptor.forClass(FormulaShareRule.class);
        
        ((FormulaShareService) mocks.verify(serviceMock)).updateShareMaps(
            (Id) recordIdArg.capture(),
            (Id) sharedToArg.capture(),
            (String) targetAccessLevelArg.capture(),
            (FormulaShareRule) ruleArg.capture()
        );
        return (Id) sharedToArg.getValue();
    }

    private static String getLogMessageArgumentFromCaptureEntityNotFound(
        FormulaShareService serviceMock) {
        
        fflib_ArgumentCaptor recordRuleArg = 
            fflib_ArgumentCaptor.forClass(FormulaShareService.RecordRule.class);
        fflib_ArgumentCaptor logMessageArg = 
            fflib_ArgumentCaptor.forClass(String.class);
        
        ((FormulaShareService) mocks.verify(serviceMock)).captureEntityNotFound(
            (FormulaShareService.RecordRule) recordRuleArg.capture(),
            (String) logMessageArg.capture()
        );
        return (String) logMessageArg.getValue();
    }

    // ------------------ Tests for Name-based sharing ------------------ //

    @IsTest
    public static void validShareToNameWithPrefix() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        // Use empty prefix and existing group to test the logic
        String prefix = '';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Name', label);
        Group validGroup = getValidGroup();

        // With empty prefix, field value must match group name exactly
        recRule.sharedToString = validGroup.DeveloperName;
        
        Test.startTest();
        instance.checkAndAdd(validGroup.DeveloperName, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 
            'Should share to group when field value matches');
    }

    @IsTest
    public static void mismatchWithValidFallbackName() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        // Use empty prefix and existing group to test fallback logic
        String prefix = '';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Name', label);
        Group validGroup = getValidGroup();
        
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validGroup.DeveloperName;
        recRule.sharedToString = 'NotARealGroupName';
        
        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 
            'Should share to fallback group when field value mismatches');
    }

    @IsTest
    public static void mismatchWithInvalidFallbackName() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = '';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Name', label);

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotARealGroupName';
        recRule.sharedToString = 'NotARealGroupName';

        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        String message = 
            getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assert(message.contains('AlsoNotARealGroupName'), 
            'Error should reference invalid fallback name');
    }

    @IsTest
    public static void mismatchWithLogErrorName() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = '';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Name', label);

        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';
        recRule.sharedToString = 'NotARealGroupName';

        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        String message = 
            getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assert(message.contains('NotARealGroupName'), 
            'Error should reference invalid field value');
    }

    // ------------------ Tests for Id-based sharing ------------------ //

    @IsTest
    public static void validShareToId() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = 'TEST_';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Id', label);
        Group validGroup = getValidGroup();

        Test.startTest();
        instance.checkAndAdd(validGroup.Id, recRule);
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 
            'Should share to group provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackId() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = 'TEST_';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Id', label);
        Group validGroup = getValidGroup();

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validGroup.Id;

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(recRule.rule.fallbackShareToFieldMismatch, sharedTo, 
            'Should fall back to default group id');
    }

    @IsTest
    public static void mismatchWithInvalidFallbackId() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = 'TEST_';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Id', label);

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotAnId';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        String message = 
            getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected default provided in rule to contain ' + 
            'valid group id. Instead found: ' + 
            recRule.rule.fallbackShareToFieldMismatch, message, 
            'Error should be logged for invalid fallback id');
    }

    @IsTest
    public static void mismatchWithLogErrorId() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = 'TEST_';
        String label = 'Test Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Id', label);

        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        String message = 
            getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected field to contain valid group id. ' + 
            'Instead found: NotAnId', message, 
            'Error should be logged for invalid id');
    }

    // ------------------ Test empty prefix behavior ------------------ //

    @IsTest
    public static void noPrefixBehavesLikePublicGroups() {
        FormulaShareService serviceMock = 
            (FormulaShareService) (mocks).mock(FormulaShareService.class);
        
        String prefix = '';
        String label = 'No Prefix Handler';
        TestPrefixedHandler instance = 
            new TestPrefixedHandler(serviceMock, prefix, label);
        
        FormulaShareService.RecordRule recRule = getRecordRule('Name', label);
        Group validGroup = getValidGroup();

        recRule.sharedToString = validGroup.DeveloperName;
        
        Test.startTest();
        instance.checkAndAdd(validGroup.DeveloperName, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 
            'Should share to group with no prefix (exact name match)');
    }
}
