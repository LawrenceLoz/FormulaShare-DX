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

    public static String userRuleName         = FormulaShareRuleFactory.userRuleName;
    public static String groupRuleName        = FormulaShareRuleFactory.groupRuleName;
    public static String roleSubName          = FormulaShareRuleFactory.roleSubName;
    public static String roleRuleName         = FormulaShareRuleFactory.roleRuleName;
    public static String childUserRuleName    = FormulaShareRuleFactory.childUserRuleName;
    public static String ancestorUserRuleName = FormulaShareRuleFactory.ancestorUserRuleName;
    public static String siblingUserRuleName  = FormulaShareRuleFactory.siblingUserRuleName;
    public static String inlawGroupRuleName   = FormulaShareRuleFactory.inlawGroupRuleName;
    private String prefix;

    // Example ID used in mock returns
    public static String expectedMockId = UserInfo.getUserId();

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
                return FormulaShareRuleFactory.getRulesSharingBatchLogs();
            }
            else if(sharedType == FormulaShare_Record_Log__c.SObjectType) {
                return FormulaShareRuleFactory.getRulesSharingRecordLogs();
            }
            else {
                return new List<FormulaShareRule>();
            }
        }

        else if(stubbedMethodName == 'getAllRules') {
            List<FormulaShareRule> rules = new List<FormulaShareRule>();
            rules.addAll(FormulaShareRuleFactory.getRulesSharingBatchLogs());
            rules.addAll(FormulaShareRuleFactory.getRulesSharingRecordLogs());
            return rules;
        }

        else if(stubbedMethodName == 'getStandardAndAncestorRulesSharingObject') {
            system.debug('getStandardAndAncestorRulesSharingObject stub');

            String sharedObjectName = (String) listOfArgs[0];
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            if(sharedObjectName.contains('FormulaShare_Log__c')) {
                rules = FormulaShareRuleFactory.getStandardRulesSharingBatchLogs();
            }
            else if(sharedObjectName.contains('FormulaShare_Record_Log__c')) {
                rules.add(FormulaShareRuleFactory.getAncestorUserRule());
            }

            return rules;
        }

        else if(stubbedMethodName == 'getDescendantAndInlawRulesWithThisBottomObject') {
            system.debug('getDescendantAndInlawRulesWithThisBottomObject stub');

            String sharedObjectName = (String) listOfArgs[0];
            List<FormulaShareRule> rules = new List<FormulaShareRule>();

            if(sharedObjectName.contains('FormulaShare_Log__c')) {
                rules.add(FormulaShareRuleFactory.getChildUserRule());
            }
            else if(sharedObjectName.contains('FormulaShare_Record_Log__c')) {
                rules.add(FormulaShareRuleFactory.getInlawGroupRule());
            }

            return rules;
        }

        else if(stubbedMethodName == 'selectObjectsWithRules') {
            Set<String> objNames = new Set<String>();
            objNames.add(prefix + 'FormulaShare_Log__c');
            objNames.add(prefix + 'FormulaShare_Record_Log__c');
            return objNames;
        }

        // -------------------------- FormulaShareIdUtilities Mocks ----------------------------- //

        else if(stubbedMethodName == 'get15CharacterIdInstance') {
            String argument18 = (String) listOfArgs[0];
            return argument18.left(15);
        }

        else if(stubbedMethodName == 'isValidIdType') {
            return true;
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
    
            FormulaShareRule userRule = FormulaShareRuleFactory.getUserRule();
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
            
            FormulaShareRule userRule = FormulaShareRuleFactory.getUserRule();
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
            return expectedMockId;
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
            return expectedMockId;
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

}