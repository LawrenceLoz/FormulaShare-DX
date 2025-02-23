@IsTest
public with sharing class FormulaShareShareWithRolesTest {

    private static fflib_ApexMocks mocks = new fflib_ApexMocks();

    private static FormulaShareService.RecordRule getRecordRule(String type) {
        FormulaShareService.RecordRule recRule = new FormulaShareService.RecordRule();
        recRule.recordToShare = new FormulaShare_Log__c();
        recRule.recordWithSharedToDetails = recRule.recordToShare;
        recRule.rule = new FormulaShareRule();
        recRule.rule.shareWith = 'Roles';
        recRule.rule.controllingObjectSharedToFieldType = type;
        return recRule;
    }

    @TestSetup
    static void createTestData() {
        UserRole testRole = new UserRole(
            Name = 'Test Role',
            DeveloperName = 'Test_Role'
        );
        insert testRole;
    }


    private static UserRole getValidRole() {
        UserRole existingRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Test_Role' LIMIT 1][0];
        return existingRole;
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

    private static Group getGroupFromRole(Id roleId) {
        return [SELECT Id, RelatedId, Type 
                FROM Group 
                WHERE RelatedId = :roleId AND Type = 'Role' LIMIT 1];
    }

    // ------------------ Tests for rules sharing based on Name ------------------ //

    @IsTest
    public static void validShareToName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');
        UserRole validRole = getValidRole();

        recRule.sharedToString = validRole.DeveloperName;
        
        Test.startTest();
        instance.checkAndAdd(validRole.DeveloperName, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(getGroupFromRole(validRole.Id).Id, sharedTo, 'Should share to role name provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        UserRole validRole = getValidRole();
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validRole.DeveloperName;
        recRule.sharedToString = 'NotARealRoleName';
        
        Test.startTest();
        instance.checkAndAdd('NotARealRoleName', recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(getGroupFromRole(validRole.Id).Id, sharedTo, 'Should share to fallback Role name');
    }


    @IsTest
    public static void mismatchWithInvalidFallbackName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotARealRoleName';
        recRule.sharedToString = 'NotARealRoleName';

        Test.startTest();
        instance.checkAndAdd('NotARealRoleName', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Rule default \''+recRule.rule.fallbackShareToFieldMismatch+'\' should correspond to an active role, but no role was found with this name', message, 'Error should be logged for invalid fallback name');
    }

    @IsTest
    public static void mismatchWithLogErrorName() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Name');

        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';
        recRule.sharedToString = 'NotARealRoleName';

        Test.startTest();
        instance.checkAndAdd('NotARealRoleName', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Field value \''+'NotARealRoleName'+'\' should correspond to an active role, but no role was found with this name', message, 'Error should be logged for invalid sharedTo name');
    }


    // ------------------ Tests for rules sharing based on Id ------------------ //

    @IsTest
    public static void validShareToId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        UserRole validRole = getValidRole();

        recRule.sharedToString = validRole.Id;

        Test.startTest();
        instance.checkAndAdd(validRole.Id, recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(getGroupFromRole(validRole.Id).Id, sharedTo, 'Should share to Role provided as shareTo');
    }

    @IsTest
    public static void mismatchWithValidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        UserRole validRole = getValidRole();

        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = validRole.Id;

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        Id sharedTo = getSharedToArgumentFromUpdateShareMaps(serviceMock);
        System.assertEquals(getGroupFromRole(recRule.rule.fallbackShareToFieldMismatch).Id, sharedTo, 'Should fall back to default Role id');
    }

    @IsTest
    public static void mismatchWithInvalidFallbackId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');
        
        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Share With Default';
        recRule.rule.fallbackShareToFieldMismatch = 'AlsoNotAnId';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected default provided in rule to contain valid role id. Instead found: '+recRule.rule.fallbackShareToFieldMismatch, message, 'Error should be logged for invalid fallback id');
    }

    @IsTest
    public static void mismatchWithLogErrorId() {
        FormulaShareService serviceMock = (FormulaShareService) (mocks).mock(FormulaShareService.class);
        FormulaShareShareWithRoles instance = new FormulaShareShareWithRoles(serviceMock);
        FormulaShareService.RecordRule recRule = getRecordRule('Id');

        recRule.sharedToString = 'NotAnId';
        recRule.rule.behaviourShareToFieldMismatch = 'Log Error';

        Test.startTest();
        instance.checkAndAdd('NotAnId', recRule);
        instance.assess();
        Test.stopTest();

        String message = getLogMessageArgumentFromCaptureEntityNotFound(serviceMock);
        System.assertEquals('Expected field to contain valid role id. Instead found: NotAnId', message, 'Error should be logged for invalid id');
    }

}