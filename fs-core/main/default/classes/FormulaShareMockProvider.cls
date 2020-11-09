/**
*Copyright 2018 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

@IsTest
public inherited sharing class FormulaShareMockProvider implements System.StubProvider {

    public static String userRuleName = 'User_rule';
    public static String groupRuleName = 'Group_rule';
    public static String roleSubName = 'Rule_sub_rule';
    public static String roleRuleName = 'Rule_rule';
    public static String childUserRuleName = 'Child_user_rule';
    public static String ancestorUserRuleName = 'Ancestor_user_rule';
    public static String siblingUserRuleName = 'Sibling_user_rule';
    public static String inlawGroupRuleName = 'Inlaw_group_rule';
    private String prefix;

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

        prefix = FormulaShareTestUtils.getNamespacePrefix();

        // You can use the method name and return type to determine which method was called.
        System.debug('Name of stubbed method: ' + stubbedMethodName);
        System.debug('Return type of stubbed method: ' + returnType.getName());
        
        for (integer i =0; i < listOfParamNames.size(); i++) {
            System.debug('parameter name: ' + listOfParamNames.get(i));
            System.debug('parameter type: ' + listOfParamTypes.get(i).getName());
        }
        
        // This shows the actual parameter values passed into the stubbed method at runtime.
        System.debug('number of parameters passed into the mocked call: ' + 
            listOfArgs.size());
        System.debug('parameter(s) sent into the mocked call: ' + listOfArgs);
        
        Id userId = UserInfo.getUserId();

        // -------------------------- FormulaShareSettingsSelector Mocks ----------------------------- //

        if(stubbedMethodName == 'selectActiveSettings' && returnType.getName() == prefix + 'FormulaShare_Settings__mdt') {
            FormulaShare_Settings__mdt settings = new FormulaShare_Settings__mdt();
            settings.DeveloperName = 'Mocked Settings';
            settings.Days_to_Retain_Batch_Logs__c = 2;
            settings.Days_to_Retain_Record_Logs__c = 1;
            settings.Log_Processing_Events__c = 'All Sharing Updates';
            settings.Logs_Removal_Batch_Size__c = 200;
            settings.Recalculation_Batch_Size__c = 200;
            settings.All_Record_Errors_Report_Name__c = 'FormulaShare_Record_Share_Failures_ilt';
            settings.All_Record_Logs_Report_Name__c = 'Processed_Record_Share_Details_acr';
            settings.Batch_Errors_Report_Name__c = 'FormulaShare_Batch_Errors_Gpn';
            settings.Rec_Errors_Since_Last_Batch_Report_Name__c = 'Record_Share_Errors_Since_Last_Batch_hB9';
            settings.Record_Logs_Since_Last_Batch_Report_Name__c = 'Record_Share_Logs_Since_Last_Batch_E3E';
            return settings;
        }

        // -------------------------- FormulaShareRulesSelector Mocks ----------------------------- //

        else if(stubbedMethodName == 'getRulesSharingObject') {
            Schema.SObjectType sharedType = (Schema.SObjectType) listOfArgs[0];

            if(sharedType == FormulaShare_Log__c.SObjectType) {
                return getRulesSharingBatchLogs();
            }
            else if(sharedType == FormulaShare_Record_Log__c.SObjectType) {
                return getRulesSharingRecordLogs();
            }
            else {
                return new List<FormulaShareRule>();
            }
        }

        else if(stubbedMethodName == 'getAllRules') {
            List<FormulaShareRule> rules = new List<FormulaShareRule>();
            rules.addAll(getRulesSharingBatchLogs());
            rules.addAll(getRulesSharingRecordLogs());
            return rules;
        }

        else if(stubbedMethodName == 'getStandardAndAncestorRulesSharingObject') {
            system.debug('getStandardAndAncestorRulesSharingObject stub');

            String sharedObjectName = (String) listOfArgs[0];
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            if(sharedObjectName.contains('FormulaShare_Log__c')) {
                rules = getStandardRulesSharingBatchLogs();
            }
            else if(sharedObjectName.contains('FormulaShare_Record_Log__c')) {
                rules.add(getAncestorUserRule());
            }

            return rules;
        }

        else if(stubbedMethodName == 'getDescendantAndInlawRulesWithThisBottomObject') {
            system.debug('getDescendantAndInlawRulesWithThisBottomObject stub');

            String sharedObjectName = (String) listOfArgs[0];
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            if(sharedObjectName.contains('FormulaShare_Log__c')) {
                rules.add(getChildUserRule());
            }
            else if(sharedObjectName.contains('FormulaShare_Record_Log__c')) {
                rules.add(getInlawGroupRule());
            }

            return rules;
        }

        else if(stubbedMethodName == 'selectObjectsWithRules') {
            List<String> objNames = new List<String>();
            objNames.add(prefix + 'FormulaShare_Log__c');
            objNames.add(prefix + 'FormulaShare_Record_Log__c');
            return objNames;
        }

        // -------------------------- FormulaShareUtilities Mocks ----------------------------- //

        else if(stubbedMethodName == 'get15CharacterIdInstance') {
            String argument18 = (String) listOfArgs[0];
            return argument18.left(15);
        }

        // -------------------------- FormulaShareService Mocks ----------------------------- //

        else if(stubbedMethodName == 'processFormulaShares') {
            return null;    // No return type, but carry out no processing
        }

        else if(stubbedMethodName == 'getSharesToInsert') {
            Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0].Id;
            List<FormulaShare_Log__Share> shares = FormulaShareTestDataFactory.getSharesForBatchLog(userId, new List<Id>{groupId}, 'Edit');
            return shares;
        }

        else if(stubbedMethodName == 'getSharesToDelete') {
            Id groupId = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0].Id;
            List<FormulaShare_Log__Share> shares = FormulaShareTestDataFactory.getSharesForBatchLog(userId, new List<Id>{groupId}, 'Read');
            return shares;
        }

        else if(stubbedMethodName == 'getInsertDetails' || stubbedMethodName == 'getDeleteDetails') {
            Map<String,FormulaShareService.ShareDetail> sharesMap = new Map<String,FormulaShareService.ShareDetail>();
            FormulaShareService.ShareDetail shareDetail = new FormulaShareService.ShareDetail();
    
            FormulaShare_Log__Share share = FormulaShareTestDataFactory.getShareForBatchLog(userId, userId, 'Read');
    
            FormulaShareRule userRule = getUserRule();
            shareDetail.rule = userRule;
    
            shareDetail.type = User.getSObjectType();
    
            String key = 'recordId0123456'
            + 'sharedToId12345'
            + share.AccessLevel
            + share.RowCause;
    
            sharesMap.put(key, shareDetail);
            return sharesMap;      
        }

        else if(stubbedMethodName == 'getEntitiesNotFound') {
            List<FormulaShareService.EntityNotFound> enfList = new List<FormulaShareService.EntityNotFound>();
            FormulaShareService.EntityNotFound enf = new FormulaShareService.EntityNotFound();
            enf.recordId = 'entitynotfoundi';
            enf.type = User.getSObjectType();
            enf.failedStatusReason = 'Some reason';
            
            FormulaShareRule userRule = getUserRule();
            enf.rule = userRule;

            enfList.add(enf);
            return enfList;
        }

        else if(stubbedMethodName == 'getSObjectsWithFields') {
            String queryString = 'SELECT '
                + prefix + 'Id, '
                + prefix + 'Failed_Batches__c, '
                + prefix + 'Context__c, '
                + prefix + 'Type_In_Scope, '
                + prefix + 'Exception_Type__c, '
                + '(SELECT '
                    + prefix + 'Id, '
                    + prefix + 'Failed_Batches__c, '
                    + prefix + 'Context__c, '
                    + prefix + 'Type_In_Scope, '
                    + prefix + 'Exception_Type__c '
                    + 'FROM '
                    + prefix + ' FormulaShare_Logs__r '
                + ') FROM '
                + prefix + 'FormulaShare_Log__c';
            List<SObject> records = Database.query(queryString);
            return records;
        }

        else if(stubbedMethodName == 'getType') {
            Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
            return fsLogType;
        }

        // -------------------------- FormulaShareService Mocks ----------------------------- //

        else if(stubbedMethodName == 'insertShares') {
            return null;
        }

        else if(stubbedMethodName == 'deleteShares') {
            return null;
        }

        // -------------------- FormulaShareRulesMetadataDMLService Mocks ------------------- //

        else if(stubbedMethodName == 'submitForDml') {
            return UserInfo.getUserId();
        }

        // -------------------- FormulaShareReportsService Mocks ------------------- //

        else if(stubbedMethodName == 'getRecordErrorsAllReportUrl') {
            return 'RecordErrorsAllReportUrl';
        }
        else if(stubbedMethodName == 'getRecordErrorsSinceLastBatchReportUrl') {
            return 'RecordErrorsSinceLastBatchReportUrl';
        }
        else if(stubbedMethodName == 'getBatchErrorReportUrl') {
            return 'BatchErrorReportUrl';
        }
        else if(stubbedMethodName == 'getReportIdForName') {
            return UserInfo.getUserId();
        }



        // -------------------- FormulaShareMetricsSelector Mocks ------------------- //

//        else if(stubbedMethodName == 'getAllMetricsForRules') {
//            Set<String> ruleNames = (Set<String>) listOfArgs[0];
//            
//            List<FormulaShare_Metrics__c> metricsList = new List<FormulaShare_Metrics__c>();
//
//            String batchContext = FormulaShareProcessedShareEventService.batchContext;
//            String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
//            String batchFinishContext = FormulaShareProcessedShareEventService.batchFinishContext;
////            Set<String> contextList = new List<String>{batchContext, triggerContext, batchFinishContext};
//
//            // For user rule, set batchFinish metrics
//            FormulaShare_Metrics__c metrics = getBasicMetrics();
//            metrics.FormulaShare_Rule_Name__c = userRuleName;
//            metrics.Failed_Batches__c = batchFinishContext;
//            metrics.Failed_Inserts__c = 3;
//            metrics.Successful_Inserts__c = 100;
//
//            metrics.Last_Failed_Operation__c = null;
//            metrics.Last_Successful_Operation__c = DateTime.now();
//            metrics.Last_Failed_Batch__c = null;
//            metrics.Last_Successful_Batch__c = DateTime.now();
//            metrics.Last_Batch_Run__c = DateTime.now();
//
//
//
//            for(String ruleName : ruleNames) {
//                for(String context : contextList) {
//                    FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
//                    metrics.FormulaShare_Rule_Name__c = ruleName;
//                    metrics.Failed_Batches__c = context;
//
//
//                    metricsList.add(metrics);
//                }
//            }
//        }

        else return null;
    }


    private List<FormulaShareRule> getRulesSharingBatchLogs() {
        List<FormulaShareRule> rules = getStandardRulesSharingBatchLogs();

        // Will add a sharing record for the user with the user id in Exception_Type__c field for all related log records
        FormulaShareRuleDescendant childUserRule = getChildUserRule();
        rules.add(childUserRule);

        // Shares FS Batch Log with the group name specified as the first name of the owner of related FS Record Logs
        FormulaShareRuleInlaw inlawGroupRule = getInlawGroupRule();
        rules.add(inlawGroupRule);

        return rules;
    }

    private List<FormulaShareRule> getStandardRulesSharingBatchLogs() {
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

    private List<FormulaShareRule> getRulesSharingRecordLogs() {
        List<FormulaShareRule> rules = new List<FormulaShareRule>();

        // Shares FS Record Log with owner of FormulaShare Rule in Batch related via the parent FS Batch Log
        FormulaShareRuleSibling siblingUserRule = getSiblingUserRule();
        rules.add(siblingUserRule);

        // Shares FS Record Log with owner of the parent FS Batch Log
        FormulaShareRuleAncestor ancestorUserRule = getAncestorUserRule();
        rules.add(ancestorUserRule);

        return rules;
    }    

    private FormulaShareRuleStandard getUserRule() {
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

    private FormulaShareRuleStandard getGroupRule() {
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

    private FormulaShareRuleStandard getRoleAndSubRule() {
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

    private FormulaShareRuleStandard getRoleRule() {
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
    private FormulaShareRuleStandard getBasicRule(String sharedToFieldApiName) {
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

    private FormulaShareSObjectRelationship getRelationshipStandardRule(FormulaShareRule rule) {
        FormulaShareSObjectRelationship rel = new FormulaShareSObjectRelationship();
        rel.thisObjectToken = 'objecttoken1234';
        rel.thisObjectApiName = rule.controllingObjectApiName;
        rel.sharedToFieldToken = rule.controllingObjectSharedToFieldToken;
        rel.sharedToFieldApiName = rule.controllingObjectSharedToFieldAPIName;
        return rel;
    }


    // Will add a sharing record for the user with the user id in Exception_Type__c field for all related log records
    private FormulaShareRuleDescendant getChildUserRule() {
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
        rule.lookupFromBottomObjTowardsSharedObj = prefix + 'Related_Log_Required_for_Test_Class__c';
        rule.pathToSharedToField = prefix + 'Exception_Type__c';
        rule.firstQueryStepApiName = rule.lookupFromBottomObjTowardsSharedObj;

        return rule;
    }

    private FormulaShareSObjectRelationship getRelationshipChildRule(FormulaShareRule rule) {
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


    // Shares FS Record Log with owner of FormulaShare Rule in Batch related via the parent FS Batch Log
    private FormulaShareRuleSibling getSiblingUserRule() {
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

    private FormulaShareSObjectRelationship getRelationshipSiblingRule(FormulaShareRuleSibling rule) {
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


    // Shares FS Record Log with owner of the parent FS Batch Log
    private FormulaShareRuleAncestor getAncestorUserRule() {
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

        rule.pathToSharedToField = prefix + 'FormulaShare_Batch_Log__r.' + prefix + 'FormulaShare_Rule_Name__c';
        rule.firstQueryStepApiName = prefix + 'FormulaShare_Batch_Log__c';

        rule.relationship = getRelationshipAncestorRule(rule);

        return rule;
    }

    private FormulaShareSObjectRelationship getRelationshipAncestorRule(FormulaShareRuleAncestor rule) {
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



    // Shares FS Batch Log with the group name specified as the first name of the owner of related FS Record Logs
    private FormulaShareRuleInlaw getInlawGroupRule() {
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
        rule.lookupFromBottomObjTowardsSharedObj = prefix + 'FormulaShare_Batch_Log__c';
        rule.firstQueryStepApiName = rule.lookupFromBottomObjTowardsSharedObj;

        rule.pathToSharedToField = prefix + 'FormulaShare_Rule_in_Batch__r.' + prefix + 'FormulaShare_Rule_Name__c';
    
        rule.relationship = getRelationshipInlawRule(rule);

        return rule;
    }

    private FormulaShareSObjectRelationship getRelationshipInlawRule(FormulaShareRuleInlaw rule) {
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

}