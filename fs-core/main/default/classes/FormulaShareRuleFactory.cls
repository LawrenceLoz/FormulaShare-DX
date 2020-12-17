@IsTest
public with sharing class FormulaShareRuleFactory {

    public static String userRuleName = 'User_rule';
    public static String groupRuleName = 'Group_rule';
    public static String roleSubName = 'Rule_sub_rule';
    public static String roleRuleName = 'Rule_rule';
    public static String childUserRuleName = 'Child_user_rule';
    public static String ancestorUserRuleName = 'Ancestor_user_rule';
    public static String siblingUserRuleName = 'Sibling_user_rule';
    public static String inlawGroupRuleName = 'Inlaw_group_rule';
    private static String prefix = FormulaShareTestUtils.getNamespacePrefix();

    public static List<FormulaShareRule> getRulesSharingBatchLogs() {
        List<FormulaShareRule> rules = getStandardRulesSharingBatchLogs();

        // Will add a sharing record for the user with the user id in Exception_Type__c field for all related log records
        FormulaShareRuleDescendant childUserRule = getChildUserRule();
        rules.add(childUserRule);

        // Shares FS Batch Log with the group name specified as FormulaShare_Rule_Name__c of the parent rule in batch record of related FS Record Logs
        FormulaShareRuleInlaw inlawGroupRule = getInlawGroupRule();
        rules.add(inlawGroupRule);

        return rules;
    }

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

        return rules;
    }

    public static List<FormulaShareRule> getRulesSharingRecordLogs() {
        List<FormulaShareRule> rules = new List<FormulaShareRule>();

        // Shares FS Record Log with owner of FormulaShare Rule in Batch related via the parent FS Batch Log
        FormulaShareRuleSibling siblingUserRule = getSiblingUserRule();
        rules.add(siblingUserRule);

        // Shares FS Record Log with owner of the parent FS Batch Log
        FormulaShareRuleAncestor ancestorUserRule = getAncestorUserRule();
        rules.add(ancestorUserRule);

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
        rule.relationship = getRelationshipStandardRule(rule);

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
        rule.relationship = getRelationshipStandardRule(rule);

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
        rule.relationship = getRelationshipStandardRule(rule);
        
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
        rule.relationship = getRelationshipStandardRule(rule);

        return rule;
    }

    // Returns a standard rule sharing the field name supplied
    public static FormulaShareRuleStandard getBasicRule(String sharedToFieldApiName) {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        FormulaShareRuleStandard rule = new FormulaShareRuleStandard();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
        rule.controllingObjectApiName = rule.objectSharedAPIName;
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
        rule.controllingObjectSharedToFieldAPIName = sharedToFieldApiName;
        rule.pathToSharedToField = sharedToFieldApiName;
        rule.firstQueryStepApiName = sharedToFieldApiName;
        rule.active = true;
        return rule;
    }

    public static FormulaShareSObjectRelationship getRelationshipStandardRule(FormulaShareRule rule) {
        FormulaShareSObjectRelationship rel = new FormulaShareSObjectRelationship();
        rel.thisObjectToken = 'objecttoken1234';
        rel.thisObjectApiName = rule.controllingObjectApiName;
        rel.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;
        return rel;
    }


    // Shares FS Record Log with owner of the parent FS Batch Log
    public static FormulaShareRuleAncestor getAncestorUserRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        FormulaShareRuleAncestor rule = new FormulaShareRuleAncestor();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Record_Log__c';
        rule.sharingReason = prefix + 'FormulaShare_Record_Log_Share__c';
        rule.active = true;

        rule.developerName = ancestorUserRuleName;

        rule.type = 'ancestor';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Users';
        rule.controllingObjectApiName = prefix + 'FormulaShare_Log__c';
        rule.controllingObjectSharedToFieldAPIName = 'OwnerId';
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldType = 'Id';

        rule.pathToSharedToField = prefix + 'FormulaShare_Batch_Log__r.' + prefix + 'OwnerId';
        rule.firstQueryStepApiName = prefix + 'FormulaShare_Batch_Log__c';

        // Populate lookup field lists
        Schema.SObjectType sharedType = FormulaShareUtilities.getSObjectTypeFromName(rule.objectSharedAPIName);
        Schema.SObjectField lookupToControlling = FormulaShareUtilities.getSObjectFieldFromName(rule.firstQueryStepApiName, sharedType);
        rule.lookupFromSharedObjToControllingObjFieldList.add(lookupToControlling);

        rule.relationship = getRelationshipAncestorRule(rule);

        return rule;
    }

    public static FormulaShareSObjectRelationship getRelationshipAncestorRule(FormulaShareRuleAncestor rule) {
        FormulaShareSObjectRelationship rel1 = new FormulaShareSObjectRelationship();
        rel1.thisObjectToken = 'objecttoken1234';
        rel1.thisObjectApiName = rule.objectSharedAPIName;

        FormulaShareSObjectRelationship rel2 = new FormulaShareSObjectRelationship();
        rel2.thisObjectToken = 'objecttoken1234';
        rel2.thisObjectApiName = rule.controllingObjectApiName;
        rel2.lookupFromPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel2.lookupFromPrevObjectApiName = rule.firstQueryStepApiName;
        rel2.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel2.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;

        rel1.nextRelationship = rel2;
        return rel1;
    }
    
    

    // Shares FS Record Log with the user specified in FormulaShare_Rule_Name__c on the FormulaShare Rule in Batch related via the parent FS Batch Log
    public static FormulaShareRuleSibling getSiblingUserRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        FormulaShareRuleSibling rule = new FormulaShareRuleSibling();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Record_Log__c';
        rule.sharingReason = prefix + 'FormulaShare_Record_Log_Share__c';
        rule.active = true;

        rule.developerName = siblingUserRuleName;

        rule.type = 'sibling';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Users';
        rule.controllingObjectApiName = prefix + 'FormulaShare_Rule_in_Batch__c';
        rule.controllingObjectSharedToFieldAPIName = prefix + 'FormulaShare_Rule_Name__c';
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldType = 'Id';

        rule.pathFromSharedObjToTopObj = prefix + 'FormulaShare_Batch_Log__c';
        rule.pathFromControllingObjToTopObj = prefix + 'FormulaShare_Log__c';
        rule.pathToSharedToField = prefix + 'FormulaShare_Rule_Name__c';

        rule.relationship = getRelationshipSiblingRule(rule);

        return rule;
    }

    public static FormulaShareSObjectRelationship getRelationshipSiblingRule(FormulaShareRuleSibling rule) {
        FormulaShareSObjectRelationship rel1 = new FormulaShareSObjectRelationship();
        rel1.thisObjectToken = 'objecttoken1234';
        rel1.thisObjectApiName = rule.objectSharedAPIName;

        FormulaShareSObjectRelationship rel2 = new FormulaShareSObjectRelationship();
        rel2.thisObjectToken = 'objecttoken1234';
        rel2.thisObjectApiName = prefix + 'FormulaShare_Log__c';    // Assumes that this is a sibling with Batch Log at top
        rel2.lookupFromPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel2.lookupFromPrevObjectApiName = rule.pathFromSharedObjToTopObj;   // Lookup field to parent batch log

        FormulaShareSObjectRelationship rel3 = new FormulaShareSObjectRelationship();
        rel3.thisObjectToken = 'objecttoken1234';
        rel3.thisObjectApiName = rule.controllingObjectApiName;
        rel3.lookupToPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel3.lookupToPrevObjectApiName = rule.pathFromControllingObjToTopObj;   // Lookup to parent batch log
        rel3.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel3.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;

        rel2.nextRelationship = rel3;
        rel1.nextRelationship = rel2;
        return rel1;
    }



    // Will add a sharing record for the user with the user id in Exception_Type__c field for all related log records
    public static FormulaShareRuleDescendant getChildUserRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        FormulaShareRuleDescendant rule = new FormulaShareRuleDescendant();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
        rule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
        rule.active = true;

        rule.developerName = childUserRuleName;

        rule.type = 'descendant';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Users';
        rule.controllingObjectApiName = prefix + 'FormulaShare_Log__c';    // Based on a self-lookup
        rule.controllingObjectSharedToFieldAPIName = prefix + 'Exception_Type__c';
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldType = 'Id';
        rule.relationship = getRelationshipChildRule(rule);

        rule.bottomObjectApiName = prefix + 'FormulaShare_Log__c';
        rule.pathFromBottomObjToSharedObj = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.pathFromBottomObjToOwnerIdOnSharedObj = prefix + 'Related_Log_Required_for_Test_Class__r.OwnerId';
        rule.lookupFromBottomObjTowardsSharedObj = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.pathToSharedToField = prefix + 'Exception_Type__c';
        rule.firstQueryStepApiName = rule.lookupFromBottomObjTowardsSharedObj;

        Schema.SObjectType boType = FormulaShareUtilities.getSObjectTypeFromName(rule.bottomObjectApiName);
        Schema.SObjectField lookupToShared = FormulaShareUtilities.getSObjectFieldFromName(rule.pathFromBottomObjToSharedObj, boType);
        rule.lookupFromBottomObjToSharedObjFieldList.add(lookupToShared);

        return rule;
    }

    public static FormulaShareSObjectRelationship getRelationshipChildRule(FormulaShareRule rule) {
        FormulaShareSObjectRelationship rel1 = new FormulaShareSObjectRelationship();
        rel1.thisObjectToken = 'objecttoken1234';
        rel1.thisObjectApiName = rule.objectSharedAPIName;

        FormulaShareSObjectRelationship rel2 = new FormulaShareSObjectRelationship();
        rel2.thisObjectToken = 'objecttoken1234';
        rel2.thisObjectApiName = rule.controllingObjectApiName;
        rel2.lookupToPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel2.lookupFromPrevObjectApiName = prefix + 'Related_Log_Required_for_Test_Class__c';   // Lookup field to parent log
        rel2.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel2.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;

        rel1.nextRelationship = rel2;
        return rel1;
    }


    // Shares FS Batch Log with the group name specified as FormulaShare_Rule_Name__c of the parent rule in batch record of related FS Record Logs
    public static FormulaShareRuleInlaw getInlawGroupRule() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        FormulaShareRuleInlaw rule = new FormulaShareRuleInlaw();
        rule.objectSharedAPIName = prefix + 'FormulaShare_Log__c';
        rule.sharingReason = prefix + 'FormulaShare_Log_Share__c';
        rule.active = true;

        rule.developerName = inlawGroupRuleName;

        rule.type = 'inlaw';
        rule.accessLevel = 'Edit';
        rule.shareWith = 'Public Groups';
        rule.controllingObjectApiName = prefix + 'FormulaShare_Rule_in_Batch__c';
        rule.controllingObjectSharedToFieldAPIName = prefix + 'FormulaShare_Rule_Name__c';
        rule.controllingObjectSharedToFieldToken = 'objecttoken1234.fieldtoken12345';
        rule.controllingObjectSharedToFieldType = 'Name';

        rule.lookupFromBottomObjTowardsControllingObj = prefix + 'FormulaShare_Rule_in_Batch__c';
        rule.bottomObjectApiName = prefix + 'FormulaShare_Record_Log__c';
        rule.pathFromBottomObjToSharedObj = prefix + 'FormulaShare_Batch_Log__c';
        rule.pathFromBottomObjToOwnerIdOnSharedObj = prefix + 'FormulaShare_Batch_Log__r.OwnerId';
        rule.lookupFromBottomObjTowardsSharedObj = prefix + 'FormulaShare_Batch_Log__c';
        rule.firstQueryStepApiName = rule.lookupFromBottomObjTowardsSharedObj;

        rule.pathToSharedToField = prefix + 'FormulaShare_Rule_in_Batch__r.' + prefix + 'FormulaShare_Rule_Name__c';

        // Populate lookup field lists
        Schema.SObjectType boType = FormulaShareUtilities.getSObjectTypeFromName(rule.bottomObjectApiName);
        Schema.SObjectField lookupToShared = FormulaShareUtilities.getSObjectFieldFromName(rule.pathFromBottomObjToSharedObj, boType);
        rule.lookupFromBottomObjToSharedObjFieldList.add(lookupToShared);

        Schema.SObjectField lookupToControlling = FormulaShareUtilities.getSObjectFieldFromName(rule.lookupFromBottomObjTowardsControllingObj, boType);
        rule.lookupFromBottomObjToControllingObjFieldList.add(lookupToControlling);
    
        rule.relationship = getRelationshipInlawRule(rule);

        return rule;
    }

    public static FormulaShareSObjectRelationship getRelationshipInlawRule(FormulaShareRuleInlaw rule) {
        FormulaShareSObjectRelationship rel1 = new FormulaShareSObjectRelationship();
        rel1.thisObjectToken = 'objecttoken1234';
        rel1.thisObjectApiName = rule.objectSharedAPIName;

        FormulaShareSObjectRelationship rel2 = new FormulaShareSObjectRelationship();
        rel2.thisObjectToken = 'objecttoken1234';
        rel2.thisObjectApiName = rule.bottomObjectApiName;
        rel2.lookupToPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel2.lookupToPrevObjectApiName = rule.pathFromBottomObjToSharedObj;   // Lookup field to parent batch log

        FormulaShareSObjectRelationship rel3 = new FormulaShareSObjectRelationship();
        rel3.thisObjectToken = 'objecttoken1234';
        rel3.thisObjectApiName = rule.controllingObjectApiName;
        rel3.lookupFromPrevObjectToken = 'objecttoken1234.lookuptoken1234';
        rel3.lookupFromPrevObjectApiName = rule.lookupFromBottomObjTowardsControllingObj;
        rel3.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel3.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;

        rel2.nextRelationship = rel3;
        rel1.nextRelationship = rel2;
        return rel1;
    }


    // Sibling rule with 10 levels
    public static FormulaShare_Rule__mdt getComplexSiblingMetadataRule() {
        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();

        rule.DeveloperName = 'Complex_Sibling_Rule';
        rule.MasterLabel = 'Complex_Sibling_Rule';
        rule.Description__c = 'Complex sibling rule desc';

        // Rule would share FormulaShare Log
        rule.Object_Shared__c = prefix + 'FormulaShare_Log__c';
        rule.Share_With__c = 'Users';
        rule.Access_Level__c = 'Edit';
        rule.Active__c = true;
        rule.Sharing_Reason__c = prefix + 'FormulaShare_Log_Share__c';
        
        rule.Child_Object_Shared_To_Field_Type__c = 'Id'; // Populate type for related objects

        // Traverse 5 levels up from shared object (using self-lookup)
        rule.Child_Object_with_Shared_To_Field__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_1_Lookup_from_Shared_Obj__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_2__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_2_Lookup_from_RO1__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_3__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_3_Lookup_from_RO2__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_4__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_4_Lookup_from_RO3__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_5__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_5_Lookup_from_RO4__c = prefix + 'Related_Log_Required_for_Test_Class__c';

        // Traverse 5 levels down (using same lookup)
        rule.Related_Object_6__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_6_Lookup_to_RO5__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_7__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_7_Lookup_to_RO6__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_8__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_8_Lookup_to_RO7__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_9__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_9_Lookup_to_RO8__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_10__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_10_Lookup_to_RO9__c = prefix + 'Related_Log_Required_for_Test_Class__c';

        // Share based on field on 10th object
        rule.Related_Object_10_Shared_To_Field__c = prefix + 'Exception_Type__c';

        return rule;
    }


    // Inlaw rule with 9 levels
    public static FormulaShare_Rule__mdt getComplexInlawMetadataRule() {
        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();

        rule.DeveloperName = 'Complex_Inlaw_Rule';
        rule.MasterLabel = 'Complex_Inlaw_Rule';
        rule.Description__c = 'Complex inlaw rule desc';

        // Rule would share FormulaShare Log
        rule.Object_Shared__c = prefix + 'FormulaShare_Log__c';
        rule.Share_With__c = 'Users';
        rule.Access_Level__c = 'Edit';
        rule.Active__c = true;
        rule.Sharing_Reason__c = prefix + 'FormulaShare_Log_Share__c';
        
        rule.Child_Object_Shared_To_Field_Type__c = 'Id'; // Populate type for related objects

        // Traverse 5 levels down from shared object (using self-lookup)
        rule.Child_Object_with_Shared_To_Field__c = prefix + 'FormulaShare_Log__c';
        rule.Child_Object_Lookup_Field__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_2__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_2_Lookup_to_RO1__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_3__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_3_Lookup_to_RO2__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_4__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_4_Lookup_to_RO3__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_5__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_5_Lookup_to_RO4__c = prefix + 'Related_Log_Required_for_Test_Class__c';

        // Traverse 4 levels up (using same lookup)
        rule.Related_Object_6__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_6_Lookup_from_RO5__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_7__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_7_Lookup_from_RO6__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_8__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_8_Lookup_from_RO7__c = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.Related_Object_9__c = prefix + 'FormulaShare_Log__c';
        rule.Related_Object_9_Lookup_from_RO8__c = prefix + 'Related_Log_Required_for_Test_Class__c';

        // Share based on field on 10th object
        rule.Related_Object_9_Shared_To_Field__c = prefix + 'Exception_Type__c';

        return rule;
    }    
}
