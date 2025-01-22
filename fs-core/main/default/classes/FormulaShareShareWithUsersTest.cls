@IsTest
public with sharing class FormulaShareShareWithUsersTest {

    private static fflib_ApexMocks mocks = new fflib_ApexMocks();

    private static FormulaShareService.RecordRule getRecordRule(String type) {
        FormulaShareService.RecordRule recRule = new FormulaShareService.RecordRule();
        recRule.recordToShare = new FormulaShare_Log__c();
        recRule.recordWithSharedToDetails = recRule.recordToShare;
        recRule.rule = new FormulaShareRule();
        recRule.rule.shareWith = 'Users';
        recRule.rule.controllingObjectSharedToFieldType = type;
        return recRule;
    }

    private static User getValidUser() {
        return [SELECT Id FROM User 
        WHERE IsActive = TRUE
        AND Profile.UserLicense.Name NOT IN ('Customer Community','Customer Community Login') LIMIT 1];
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


    // ------------------ Tests for rules sharing based on Id ------------------ //

    @IsTest
    public static void validShareToId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithUsers instance = new FormulaShareShareWithUsers(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        User validUser = getValidUser();

        recRule.sharedToString = validUser.Id;

        Test.startTest();
        instance.checkAndAdd(validUser.Id, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(validUser.Id, sharedTo, 'Should share to User provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithUsers instance = new FormulaShareShareWithUsers(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        User validUser = getValidUser();

        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validUser.Id;

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(recRule.rule.fallbackShareToFieldMismatch, sharedTo, 'Should fall back to default User id');
    }

    @IsTest
    public static void mismatchWithInvalidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithUsers instance = new FormulaShareShareWithUsers(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        
        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotAnId';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected default provided in rule to contain valid user id. Instead found: '+recRule.rule.fallbackShareToFieldMismatch, message, 'Error should be logged for invalid fallback id');
    }

    @IsTest
    public static void mismatchWithLogErrorId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithUsers instance = new FormulaShareShareWithUsers(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');

        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected field to contain valid user id. Instead found: NotAnId', message, 'Error should be logged for invalid id');
    }

}