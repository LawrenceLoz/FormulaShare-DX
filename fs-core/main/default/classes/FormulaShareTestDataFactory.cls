@IsTest
public inherited sharing class FormulaShareTestDataFactory {

    static String batchContext = FormulaShareProcessedShareEventService.batchContext;
    static String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
    static String batchFinishContext = FormulaShareProcessedShareEventService.batchFinishContext;

    static String userRuleName = FormulaShareRuleFactory.userRuleName;
    static String groupRuleName = FormulaShareRuleFactory.groupRuleName;
    static String roleSubName = FormulaShareRuleFactory.roleSubName;
    static String roleRuleName = FormulaShareRuleFactory.roleRuleName;

    static String prefix = FormulaShareTestUtils.getNamespacePrefix();


    //--------------------------------- Log records factory ------------------------------------------------

    public static FormulaShare_Log__c getBatchLog() {
        return getBatchLogs(1)[0];
    }

    public static List<FormulaShare_Log__c> getBatchLogs(Integer size) {
        List<FormulaShare_Log__c> logs = new List<FormulaShare_Log__c>();

        for(Integer i = 0; i < size; i++) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Context__c = 'FormulaShareProcessBatch';
            log.Type_In_Scope__c = 'FormulaShare_Log__c';
            log.Query__c = 'SELECT Id FROM FormulaShare_Log__c ORDER BY Name ASC NULLS FIRST';
            log.Batches_Processed__c = 10;
            log.Processing_Started__c = DateTime.now() - 10;
            log.Processing_Finished__c = DateTime.now();
            logs.add(log);
        }

        return logs;
    }

    public static List<FormulaShare_Log__c> getBatchLogsNoSharingImpact(Integer size) {
        List<FormulaShare_Log__c> logs = getBatchLogs(size);

        // Clear all fields involved in any sharing
        for(FormulaShare_Log__c log : logs) {
            log.Context__c = null;
            log.Type_In_Scope__c = null;
            log.Exception_Type__c = null;
            log.Failed_Batches__c = null;
        }

        return logs;
    }

    public static List<FormulaShare_Log__c> getChildLogsSharingParent(Id parentId, List<User> users, Integer noLogs) {
        List<FormulaShare_Log__c> childLogs = getChildLogsNoSharingImpact(parentId, noLogs);
        Integer i = 0;
        for(FormulaShare_Log__c log : childLogs) {
            log.Exception_Type__c = users[Math.mod(i, users.size())].Id;
            i++;
        }
        return childLogs;
    }

    public static List<FormulaShare_Log__c> getChildLogsNoSharingImpact(Id parentId, Integer noLogs) {
        List<FormulaShare_Log__c> childLogs = getBatchLogsNoSharingImpact(noLogs);
        for(FormulaShare_Log__c log : childLogs) {
            log.Related_Log_Required_for_Test_Class__c = parentId;
        }
        return childLogs;
    }


    //--------------------------------- Record logs and ribs factory ------------------------------------------------

    public static List<FormulaShare_Record_Log__c> getRecordLogsForBatchLog(Id batchLogId, Integer noLogs) {
        List<FormulaShare_Record_Log__c> recordLogs = new List<FormulaShare_Record_Log__c>();

        for(Integer i=0; i < noLogs; i++) {
            FormulaShare_Record_Log__c log = new FormulaShare_Record_Log__c();
            log.FormulaShare_Batch_Log__c = batchLogId;
            recordLogs.add(log);
        }
        return recordLogs;
    }

    public static List<FormulaShare_Record_Log__c> getSharingRecordLogsForInlawRule(Id batchLogId, Id ruleInBatchId, Integer noLogs) {
        List<FormulaShare_Record_Log__c> recordLogs = getRecordLogsForBatchLog(batchLogId, noLogs);

        for(FormulaShare_Record_Log__c log : recordLogs) {
            log.FormulaShare_Rule_in_Batch__c = ruleInBatchId;
        }
        return recordLogs;
    }
    
    public static List<FormulaShare_Rule_in_Batch__c> getRuleInBatchRecords(Id batchLogId, Integer noRecords) {
        List<FormulaShare_Rule_in_Batch__c> ribs = new List<FormulaShare_Rule_in_Batch__c>();

        for(Integer i=0; i < noRecords; i++) {
            FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
            rib.FormulaShare_Log__c = batchLogId;
            rib.FormulaShare_Rule_Name__c = FormulaShareTestUtils.sharedGroupName;
            ribs.add(rib);
        }
        return ribs;
    }

    public static List<FormulaShare_Rule_in_Batch__c> getRuleInBatchRecordsForSiblingRule(Id batchLogId, List<User> users, Integer noRecords) {
        List<FormulaShare_Rule_in_Batch__c> ribs = getRuleInBatchRecords(batchLogId, noRecords);

        Integer i = 0;
        for(FormulaShare_Rule_in_Batch__c rib : ribs) {
            rib.FormulaShare_Rule_Name__c = users[Math.mod(i, users.size())].Id;
            i++;
        }
        return ribs;
    }


    //--------------------------------- Share records factory ------------------------------------------------

    public static FormulaShare_Log__Share getShareForBatchLog(Id batchLogId, Id userOrGroupId, String accessLevel) {
        return getSharesForBatchLog(batchLogId, new List<Id>{userOrGroupId}, accessLevel)[0];
    }

    public static List<FormulaShare_Log__Share> getSharesForBatchLog(Id batchLogId, List<Id> userOrGroupIdList, String accessLevel) {
        List<FormulaShare_Log__Share> sharesList = new List<FormulaShare_Log__Share>();

        for(Id userOrGroupId : userOrGroupIdList) {
            FormulaShare_Log__Share share = new FormulaShare_Log__Share();
            share.AccessLevel = accessLevel;
            share.ParentId = batchLogId;
            share.UserOrGroupId = userOrGroupId;
            share.RowCause = FormulaShareTestUtils.batchLogRowCause;
            sharesList.add(share);
        }
        return sharesList;
    }


    //--------------------------------- Metrics records factory ------------------------------------------------

    public static FormulaShare_Metrics__c getBatchFinishMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = batchFinishContext;
        metrics.Successful_Inserts__c = 101;
        metrics.Failed_Inserts__c = 1;
        metrics.Last_Successful_Batch__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }

    public static FormulaShare_Metrics__c getBatchFinishMetricsForRuleAndBatchFail(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = getBatchFinishMetricsForRuleAndBatch(ruleName, batchLogId);
        metrics.Last_Successful_Batch__c = null;
        metrics.Last_Failed_Batch__c = DateTime.now();
        return metrics;
    }

    public static FormulaShare_Metrics__c getTriggerMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = triggerContext;
        metrics.Successful_Inserts__c = 102;
        metrics.Failed_Inserts__c = 2;
        metrics.Last_Successful_Operation__c = DateTime.now();
        metrics.Last_Failed_Operation__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }

    public static FormulaShare_Metrics__c getBatchMetricsForRuleAndBatch(String ruleName, Id batchLogId) {
        FormulaShare_Metrics__c metrics = new FormulaShare_Metrics__c();
        metrics.FormulaShare_Rule_Name__c = ruleName;
        metrics.Context__c = batchContext;
        metrics.Successful_Inserts__c = 103;
        metrics.Failed_Inserts__c = 3;
        metrics.Last_Successful_Operation__c = DateTime.now();
        metrics.Last_Failed_Operation__c = DateTime.now();
        metrics.Last_Batch_Run__c = batchLogId;
        return metrics;
    }


    //--------------------------------- User and roles factory ------------------------------------------------

    public static List<UserRole> getRoles(Integer noRoles) {

        List<UserRole> rolesForTest = new List<UserRole>();
        for(Integer i=0; i< noRoles; i++) {
            UserRole role = new UserRole();
            role.DeveloperName = 'TestRoleFormulaShare'+i;
            role.Name = 'TestRoleFormulaShare'+i;
            rolesForTest.add(role);
        }
        return rolesForTest;
    }

    public static List<User> getUsers(Integer noUsers, Id roleId) {
        List<User> users = getUsers(noUsers);
        for(User u : users) {
            u.UserRoleId = roleId;
        }
        return users;
    }

    public static List<User> getUsers(Integer noUsers) {

        Profile pf= [Select Id from profile where Name='System Administrator']; 
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');

        List<User> users = new List<User>();
        for(Integer i=0; i< noUsers; i++) {

            Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
            String uniqueName = orgId+dateString+RandomId;
    
            User u = new User(
                firstname = 'FormulaShareTestUser' + i, 
                lastName = 'OnlyForUnitTests' + i, 
                email = 'FS' + uniqueName + '@test' + orgId + '.org', 
                Username = 'FS' + uniqueName + '@test' + orgId + '.org', 
                EmailEncodingKey = 'ISO-8859-1', 
                Alias = 'FS' + uniqueName.substring(18, 21), 
                TimeZoneSidKey = 'America/Los_Angeles', 
                LocaleSidKey = 'en_US', 
                LanguageLocaleKey = 'en_US', 
                ProfileId = pf.Id);
            users.add(u);
        }
        return users;
    }
    

}