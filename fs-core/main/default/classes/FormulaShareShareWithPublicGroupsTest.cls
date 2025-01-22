@IsTest
public with sharing class FormulaShareShareWithPublicGroupsTest {

    private static fflib_ApexMocks mocks = new fflib_ApexMocks();

    private static FormulaShareService.RecordRule getRecordRule(String type) {
        FormulaShareService.RecordRule recRule = new FormulaShareService.RecordRule();
        recRule.recordToShare = new FormulaShare_Log__c();
        recRule.recordWithSharedToDetails = recRule.recordToShare;
        recRule.rule = new FormulaShareRule();
        recRule.rule.shareWith = 'Public Groups';
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
    
    private static Id getSharedToArgumentFromUpdateShareMaps(FormulaShareService serviceMock) {
        fflib_ArgumentCaptor recordIdArg          = fflib_ArgumentCaptor.forClass(Id.class);
        fflib_ArgumentCaptor sharedToArg          = fflib_ArgumentCaptor.forClass(Id.class);
        fflib_ArgumentCaptor targetAccessLevelArg = fflib_ArgumentCaptor.forClass(String.class);
        fflib_ArgumentCaptor ruleArg              = fflib_ArgumentCaptor.forClass(FormulaShareRule.class);
        ((FormulaShareService) mocks.verify(serviceMock)).updateShareMaps(
            (Id) recordIdArg.capture(),
            (Id) sharedToArg.capture(),
            (String) targetAccessLevelArg.capture(),
            (FormulaShareRule) ruleArg.capture()
        );
        return (Id) sharedToArg.getValue();
    }

    private static String getLogMessageArgumentFromCaptureEntityNotFound(FormulaShareService serviceMock) {
        fflib_ArgumentCaptor recordRuleArg = fflib_ArgumentCaptor.forClass(FormulaShareService.RecordRule.class);
        fflib_ArgumentCaptor logMessageArg = fflib_ArgumentCaptor.forClass(String.class);
        ((FormulaShareService) mocks.verify(serviceMock)).captureEntityNotFound(
            (FormulaShareService.RecordRule) recordRuleArg.capture(),
            (String) logMessageArg.capture()
        );
        return (String) logMessageArg.getValue();
    }

    // ------------------ Tests for rules sharing based on Name ------------------ //

    @IsTest
    public static void validShareToName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');
        Group validGroup = getValidGroup();

        recRule.sharedToString = validGroup.DeveloperName;
        
        Test.startTest();
        instance.checkAndAdd(validGroup.DeveloperName, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 'Should share to group name provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        Group validGroup = getValidGroup();
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validGroup.DeveloperName;
        recRule.sharedToString = 'NotARealGroupName';
        
        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 'Should share to fallback group name');
    }


    @IsTest
    public static void mismatchWithInvalidFallbackName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotARealGroupName';
        recRule.sharedToString = 'NotARealGroupName';

        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Rule default \''+recRule.rule.fallbackShareToFieldMismatch+'\' should correspond to an active public group, but no group was found with this name', message, 'Error should be logged for invalid fallback name');
    }

    @IsTest
    public static void mismatchWithLogErrorName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';
        recRule.sharedToString = 'NotARealGroupName';

        Test.startTest();
        instance.checkAndAdd('NotARealGroupName', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Field value \''+'NotARealGroupName'+'\' should correspond to an active public group, but no group was found with this name', message, 'Error should be logged for invalid sharedTo name');
    }


    // ------------------ Tests for rules sharing based on Id ------------------ //

    @IsTest
    public static void validShareToId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        Group validGroup = getValidGroup();

        Test.startTest();
        instance.checkAndAdd(validGroup.Id, recRule);
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validGroup.Id, sharedTo, 'Should share to group provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        Group validGroup = getValidGroup();

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validGroup.Id;

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(recRule.rule.fallbackShareToFieldMismatch, sharedTo, 'Should fall back to default group id');
    }

    @IsTest
    public static void mismatchWithInvalidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotAnId';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected default provided in rule to contain valid group id. Instead found: '+recRule.rule.fallbackShareToFieldMismatch, message, 'Error should be logged for invalid fallback id');
    }

    @IsTest
    public static void mismatchWithLogErrorId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithPublicGroups instance = new FormulaShareShareWithPublicGroups(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');

        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected field to contain valid group id. Instead found: NotAnId', message, 'Error should be logged for invalid id');
    }


}