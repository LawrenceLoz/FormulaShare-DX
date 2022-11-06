@IsTest
public with sharing class FormulaShareRuleTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }
    

    // Tests use a custom SObject only - we can't guarantee share records for Account and related
    // objects exist so can't test with this
    @IsTest
    public static void checkShareMorePermissiveWithLowerAccessShare() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'All';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;

            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(null, null, 'Read');

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share, null);

            System.assert(!isEqualOrMorePermissive, 'Share is LOWER access level than rule');
        }
    }


    @IsTest
    public static void checkShareMorePermissiveWithHigherAccessShare() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Read';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;

            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(null, null, 'Edit');

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share, null);

            System.assert(isEqualOrMorePermissive, 'Share is HIGHER access level than rule');
        }
    }


    @IsTest
    public static void checkShareMorePermissiveWithSameAccessShare() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Read';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;

            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(null, null, 'Read');

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share, null);

            System.assert(isEqualOrMorePermissive, 'Share is SAME access level as rule');
        }
    }
}
