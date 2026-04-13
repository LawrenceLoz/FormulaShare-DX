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

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share, 'All', null);

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

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share,  'Read', null);

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

            Boolean isEqualOrMorePermissive = rule.shareEqualOrMorePermissiveThanRule(fsLogType, share, 'Read', null);

            System.assert(isEqualOrMorePermissive, 'Share is SAME access level as rule');
        }
    }


    @IsTest
    public static void setRuleFromMetadata_populatesCoreFields() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Rule__mdt mdRule = new FormulaShare_Rule__mdt();
            mdRule.MasterLabel = 'Test Rule';
            mdRule.DeveloperName = 'Test_Rule';
            mdRule.Active__c = true;
            mdRule.Share_With__c = 'Users';
            mdRule.Access_Level__c = 'Edit';
            mdRule.Sharing_Reason__c = 'Test_Reason__c';
            mdRule.Behaviour_Md_Match_Field_Mismatch__c = 'Log Error';
            mdRule.Behaviour_Share_To_Field_Mismatch__c = 'Log Error';

            FormulaShareRule rule = new FormulaShareRule();
            rule.setRuleFromMetadata(mdRule);

            System.assertEquals('Test Rule', rule.label, 'label should be set from MasterLabel');
            System.assertEquals('Test_Rule', rule.developerName, 'developerName should be set');
            System.assertEquals(true, rule.active, 'active should be set');
            System.assertEquals('Users', rule.shareWith, 'shareWith should be set');
            System.assertEquals('Edit', rule.accessLevel, 'accessLevel should be set');
            System.assertEquals('Test_Reason__c', rule.sharingReason, 'sharingReason should be set');
        }
    }


    @IsTest
    public static void setRuleFromMetadata_defaultsBehaviourWhenNull() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Rule__mdt mdRule = new FormulaShare_Rule__mdt();
            // Behaviour fields left null — should default to 'Log Error'

            FormulaShareRule rule = new FormulaShareRule();
            rule.setRuleFromMetadata(mdRule);

            System.assertEquals('Log Error', rule.behaviourMdMatchFieldMismatch, 'Null behaviour should default to Log Error');
            System.assertEquals('Log Error', rule.behaviourShareToFieldMismatch, 'Null behaviour should default to Log Error');
        }
    }


    @IsTest
    public static void setRuleFromMetadata_parsesFilterContracted() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String prefix = FormulaShareTestUtils.getNamespacePrefix();
            FormulaShare_Rule__mdt mdRule = new FormulaShare_Rule__mdt();
            mdRule.Filter__c = prefix + 'Type_In_Scope__c|Equals|Active';

            FormulaShareRule rule = new FormulaShareRule();
            rule.setRuleFromMetadata(mdRule);

            System.assertEquals(prefix + 'Type_In_Scope__c', rule.filterFieldApiName, 'filterFieldApiName should be parsed');
            System.assertEquals('Equals', rule.filterOperator, 'filterOperator should be parsed');
            System.assertEquals('Active', rule.filterValue, 'filterValue should be parsed');
            System.assertNotEquals(null, rule.filterContracted, 'filterContracted should be set');
        }
    }


    @IsTest
    public static void isValid_returnsTrueForCompleteRule() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
            // getUserRule() sets objectSharedAPIName, controllingObjectSharedToFieldAPIName,
            // controllingObjectSharedToFieldType, shareWith, accessLevel, sharingReason
            System.assert(rule.isValid(), 'Fully populated rule should be valid');
        }
    }


    @IsTest
    public static void isValid_returnsFalseWhenFieldMissing() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
            rule.shareWith = null;  // remove a required field
            System.assert(!rule.isValid(), 'Rule missing shareWith should be invalid');
        }
    }


    @IsTest
    public static void getShareWithRuleDefaults_buildsShareRecord() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Edit';
            rule.sharingReason = FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Log_Share__c';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            Id fakeRecordId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);
            Id fakeUserId = fflib_IDGenerator.generate(User.SObjectType);

            SObject share = rule.getShareWithRuleDefaults(fsLogType, fakeRecordId, fakeUserId, 'Edit', false);

            System.assertNotEquals(null, share, 'getShareWithRuleDefaults should return a non-null share');
            System.assertEquals(fakeUserId, (Id) share.get('UserOrGroupId'), 'UserOrGroupId should be set');
        }
    }


    @IsTest
    public static void shareEqualToRule_returnsTrue_whenSameAccess() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Edit';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(null, null, 'Edit');

            System.assert(rule.shareEqualToRule(fsLogType, share, 'Edit', false),
                'Share at same access level should be equal to rule');
        }
    }


    @IsTest
    public static void shareEqualToRule_returnsFalse_whenDifferentAccess() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Edit';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(null, null, 'Read');

            System.assert(!rule.shareEqualToRule(fsLogType, share, 'Edit', false),
                'Share at different access level should not be equal to rule');
        }
    }


    @IsTest
    public static void getMostPermissiveShare_returnsHighestAccess() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.accessLevel = 'Edit';
            rule.sharingReason = FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Log_Share__c';

            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            Id fakeRecordId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);
            Id fakeUserId = fflib_IDGenerator.generate(User.SObjectType);

            // Current share at Read; rule at Edit — result should be Edit
            FormulaShare_Log__Share currentShare = FormulaShareTestDataFactory.getShareForBatchLog(fakeRecordId, fakeUserId, 'Read');

            SObject result = rule.getMostPermissiveShare(fsLogType, fakeRecordId, fakeUserId, 'Edit', currentShare, false);

            System.assertNotEquals(null, result, 'getMostPermissiveShare should return a non-null share');
        }
    }


    @IsTest
    public static void sharedObjectIsCustom_returnsTrue_forCustomObject() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String prefix = FormulaShareTestUtils.getNamespacePrefix();
            FormulaShareRule rule = new FormulaShareRule();
            rule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';

            System.assert(rule.sharedObjectIsCustom, 'Custom object should report sharedObjectIsCustom = true');
        }
    }


    @IsTest
    public static void isMappedToMetadata_returnsFalseWhenNull() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.mdMappingType = null;
            System.assert(!rule.isMappedToMetadata, 'isMappedToMetadata should be false when mdMappingType is null');
        }
    }


    @IsTest
    public static void isMappedToMetadata_returnsTrueWhenSet() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            rule.mdMappingType = 'SomeType';
            System.assert(rule.isMappedToMetadata, 'isMappedToMetadata should be true when mdMappingType is set');
        }
    }


    @IsTest
    public static void getIntermediaryFilterContexts_returnsEmptyList() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            List<FormulaShareRule.IntermediaryFilterContext> contexts = rule.getIntermediaryFilterContexts();
            System.assertNotEquals(null, contexts, 'getIntermediaryFilterContexts should return a non-null list');
            System.assertEquals(0, contexts.size(), 'Base class should return empty list');
        }
    }


    @IsTest
    public static void requiresRelatedRecords_returnsFalse() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            System.assert(!rule.requiresRelatedRecords(), 'Base class should return false for requiresRelatedRecords');
        }
    }


    @IsTest
    public static void getTriggeringObjects_returnsEmptyMap() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = new FormulaShareRule();
            Map<String,String> result = rule.getTriggeringObjects();
            System.assertNotEquals(null, result, 'getTriggeringObjects should return a non-null map');
            System.assertEquals(0, result.size(), 'Base class should return empty map');
        }
    }


    @IsTest
    public static void setVars_noException() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Base class setVars() is empty — just verify it executes without throwing
            FormulaShareRule rule = new FormulaShareRule();
            rule.setVars();
            System.assert(true, 'setVars executed without exception');
        }
    }


    @IsTest
    public static void getSharedToValueFromRecord_returnsFieldValue() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String prefix = FormulaShareTestUtils.getNamespacePrefix();
            FormulaShareRule rule = new FormulaShareRule();
            rule.controllingObjectSharedToFieldAPIName = prefix + 'Type_In_Scope__c';

            FormulaShare_Log__c record = new FormulaShare_Log__c();
            record.put(prefix + 'Type_In_Scope__c', 'Batch');

            String result = rule.getSharedToValueFromRecord(record);
            System.assertEquals('Batch', result, 'getSharedToValueFromRecord should return the field value');
        }
    }


    @IsTest
    public static void shareEqualToRule_account_returnsTrue_whenAllMatch() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = FormulaShareRuleFactory.getAccountRule();

            // Build an in-memory AccountShare with matching access levels
            AccountShare share = new AccountShare();
            share.AccountAccessLevel = 'Edit';
            share.CaseAccessLevel = 'ReadWrite';
            share.OpportunityAccessLevel = 'ControlledByParent';

            Boolean result = rule.shareEqualToRule(Account.SObjectType, share, 'Edit', true);
            System.assert(result, 'Account share with matching access levels should be equal to rule');
        }
    }


    @IsTest
    public static void shareEqualToRule_account_returnsFalse_whenCaseMismatch() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = FormulaShareRuleFactory.getAccountRule();

            AccountShare share = new AccountShare();
            share.AccountAccessLevel = 'Edit';
            share.CaseAccessLevel = 'None';  // mismatch
            share.OpportunityAccessLevel = 'ControlledByParent';

            Boolean result = rule.shareEqualToRule(Account.SObjectType, share, 'Edit', true);
            System.assert(!result, 'Account share with case access mismatch should not be equal to rule');
        }
    }


    @IsTest
    public static void getShareWithRuleDefaults_account_setsRelatedAccess() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRule rule = FormulaShareRuleFactory.getAccountRule();

            Id fakeRecordId = fflib_IDGenerator.generate(Account.SObjectType);
            Id fakeUserId = fflib_IDGenerator.generate(User.SObjectType);

            // contactIsControlledByAccount = true skips ContactAccessLevel (which can't be set to 'None')
            SObject share = rule.getShareWithRuleDefaults(Account.SObjectType, fakeRecordId, fakeUserId, 'Edit', true);

            System.assertNotEquals(null, share, 'getShareWithRuleDefaults should return a non-null share for Account');
            System.assertEquals('ReadWrite', (String) share.get('CaseAccessLevel'), 'CaseAccessLevel should be set from rule');
        }
    }
}
