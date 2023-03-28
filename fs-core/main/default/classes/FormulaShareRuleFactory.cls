@IsTest
public with sharing class FormulaShareRuleFactory {

    public static String userRuleName = 'User_rule';
    public static String groupRuleName = 'Group_rule';
    public static String roleSubName = 'Role_sub_rule';
    public static String roleRuleName = 'Role_rule';
    public static String mgrUpRuleName = 'Mgr_up_rule';
    public static String accountRuleName = 'Account_rule';
    private String prefix = FormulaShareTestUtils.getNamespacePrefix();

    public static List<FormulaShareRule> getStandardRulesSharingBatchLogs() {
        List<FormulaShareRule> rules = new List<FormulaShareRule>();

        // Will add a sharing record for the role and subordinates group for the role name in Failed_Batches__c field
        FormulaShareRuleStandard roleSubRule = getRoleAndSubRule();
        rules.add(roleSubRule);

        // Will add a sharing record for the role group for the role id in Context__c field
        FormulaShareRuleStandard roleRule = getRoleRule();
        rules.add(roleRule);

        // Will add a sharing record for the public group with the group name in Type_In_Scope__c field
        FormulaShareRuleStandard groupRule = getGroupRule();
        rules.add(groupRule);

        // Will add a sharing record for the user with the user id in Exception_Type__c field
        FormulaShareRuleStandard userRule = getUserRule();
        rules.add(userRule);

        FormulaShareRuleStandard mgrUpRule = getMgrUpRule();
        rules.add(mgrUpRule);

        return rules;
    }

    public static FormulaShareRuleStandard getUserRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = getBasicRule(prefix + 'Exception_Type__c');
        rule.developerName = userRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Users';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    public static FormulaShareRuleStandard getGroupRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = getBasicRule(prefix + 'Type_In_Scope__c');
        rule.developerName = groupRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Public Groups';
        rule.controllingObjectSharedToFieldType = 'Name';

        return rule;
    }

    public static FormulaShareRuleStandard getRoleAndSubRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = getBasicRule(prefix + 'Failed_Batches__c');
        rule.developerName = roleSubName;

        rule.type = 'standard';
        rule.accessLevel = 'Read';
        rule.shareWith = 'Roles and Internal Subordinates';
        rule.controllingObjectSharedToFieldType = 'Name';
        
        return rule;
    }

    public static FormulaShareRuleStandard getRoleRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = getBasicRule(prefix + 'Context__c');
        rule.developerName = roleRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Roles';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    public static FormulaShareRuleStandard getMgrUpRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = getBasicRule(prefix + 'Type_In_Scope__c');
        rule.developerName = mgrUpRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Managers of Users';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    public static FormulaShareRuleStandard getAccountRule() {

        FormulaShareRuleStandard rule = new FormulaShareRuleStandard();
        rule.objectSharedAPIName = 'Account';
        rule.controllingObjectApiName = rule.objectSharedAPIName;
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldAPIName = 'Name';
        rule.setVars();
        rule.active = true;

        rule.contactAccess = 'None';
        rule.caseAccess = 'ReadWrite';
        rule.opportunityAccess = 'ControlledByParent';

        rule.developerName = accountRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Roles';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    public static FormulaShareRuleStandard getAccountRuleUpdated() {

        FormulaShareRuleStandard rule = new FormulaShareRuleStandard();
        rule.objectSharedAPIName = 'Account';
        rule.controllingObjectApiName = rule.objectSharedAPIName;
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldAPIName = 'Name';
        rule.setVars();
        rule.active = true;

        rule.contactAccess = 'ControlledByParent';  // Updated
        rule.caseAccess = 'ControlledByParent';  // Updated
//        rule.opportunityAccess = 'ControlledByParent';    // Not specified

        rule.developerName = accountRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Read';  // Updated
        rule.shareWith = 'Roles';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    public static FormulaShareRuleStandard getAccountRuleModifiedToContactRule() {

        FormulaShareRuleStandard rule = new FormulaShareRuleStandard();
        rule.objectSharedAPIName = 'Contact';      // Updated
        rule.controllingObjectApiName = rule.objectSharedAPIName;
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldAPIName = 'FirstName';      // Updated
        rule.setVars();
        rule.active = true;

        // Omit the account access levels
//        rule.contactAccess = 'None';
//        rule.caseAccess = 'ReadWrite';
//        rule.opportunityAccess = 'ControlledByParent';

        rule.developerName = accountRuleName;

        rule.type = 'standard';
        rule.accessLevel = 'Read';      // Updated
        rule.shareWith = 'Roles';
        rule.controllingObjectSharedToFieldType = 'Id';

        return rule;
    }

    // Returns a standard rule sharing the field name supplied
    private static FormulaShareRuleStandard getBasicRule(String sharedToFieldApiName) {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = new FormulaShareRuleStandard();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
        rule.controllingObjectApiName = rule.objectSharedAPIName;
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
        rule.controllingObjectSharedToFieldAPIName = sharedToFieldApiName;
        rule.setVars();
//        rule.pathToSharedToField = sharedToFieldApiName;
//        rule.firstQueryStepApiName = sharedToFieldApiName;
        rule.active = true;
        return rule;
    }
    
}
