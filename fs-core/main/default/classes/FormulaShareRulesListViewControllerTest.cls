@IsTest
public with sharing class FormulaShareRulesListViewControllerTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin(true);
    }
    

    public static void setMocks() {
        FormulaShareRulesSelector.mock = FormulaShareMockUtil.createMock(
            new FormulaShareInjectionService().getRulesSelectorType()
        );

        FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
        FormulaShareSettingsSelector.mock = mockFSSettingsSelector;

        FormulaShareReportsService mockFSReportsService = (FormulaShareReportsService) FormulaShareMockUtil.createMock(FormulaShareReportsService.class);
        FormulaShareReportsService.mock = mockFSReportsService;
    }

    @IsTest
    public static void checkRulesPopulateNoLogs() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            setMocks();
            
            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            // Build map of objects in mock and number of rules
            Map<String,Integer> objectRules = new Map<String,Integer>();
            for(FormulaShareRule rule : fsRules) {
                if(objectRules.containsKey(rule.objectSharedAPIName)) {
                    Integer noRules = objectRules.get(rule.objectSharedAPIName);
                    noRules++;
                    objectRules.put(rule.objectSharedAPIName, noRules);
                }
                else {
                    objectRules.put(rule.objectSharedAPIName, 1);
                }
            }

            // Check right number of rules for each object
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                Integer expectedNoRules = objectRules.get(orw.objectApiName);
                System.assertEquals(expectedNoRules, orw.items.size(), 'Mismatch between expected and actual number of rules for '+orw.objectApiName);
            }

            // Check that wrapped data includes the right structure to cover the first rule
            // This requires a parent row and a child row for the rule
            Boolean foundObject = false;
            Boolean foundRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    foundObject = true;
                    System.assert(orw.isParentRow, 'Not marked as parent row');

                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {
                        if(rw.developerName == fsRules[0].developerName) {
                            foundRule = true;
                            System.assertEquals(fsRules[0].ruleId, rw.ruleId, 'Mis-match of rule ID in wrapper');
                            System.assert(rw.sharedToLink.contains('objecttoken1234'), 'Link missing object token');
                            System.assert(rw.sharedToLink.contains('fieldtoken12345'), 'Link missing field token');
                            System.assertEquals('Pending', rw.lastCalcStatus, 'Calc status not empty as expected');
                        }
                    }
                }
            }

            System.assert(foundObject, 'Did not find the object of the first rule');
            System.assert(foundRule, 'Did not find the rule for the first rule');
        }
    }


    @IsTest
    public static void checkRulesPopulateInProgressLogs() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            setMocks();

            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();
            
            // Insert a log and RIB record for the first rule indicating processing not yet complete
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            log.Processing_Started__c = DateTime.now();
            log.Processing_Started_Milliseconds__c = DateTime.now().getTime();
            insert log;

            FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
            rib.FormulaShare_Log__c = log.Id;
            rib.FormulaShare_Rule_Name__c = fsRules[0].developerName;
            rib.Rule_Active_for_Batch_Run__c = true;
            insert rib;

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            // Check that wrapped data includes the right structure to cover the first rule
            // This requires a parent row and a child row for the rule
            Boolean foundObject = false;
            Boolean foundRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    foundObject = true;
                    System.assert(orw.isParentRow, 'Not marked as parent row');

                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {
                        if(rw.developerName == fsRules[0].developerName) {
                            foundRule = true;
                            System.assertEquals(fsRules[0].ruleId, rw.ruleId, 'Mis-match of rule ID in wrapper');
                            System.debug('rw: '+ rw);
                            System.debug('rw.sharedToLink: '+ rw.sharedToLink );
                            System.assert(rw.sharedToLink.contains('objecttoken1234'), 'Link missing object token');
                            System.assert(rw.sharedToLink.contains('fieldtoken12345'), 'Link missing field token');
                            System.assertEquals('Processing...', rw.lastCalcStatus, 'Rule does not indicate processing is ongoing');
                        }
                    }
                }
            }

            System.assert(foundObject, 'Did not find the object of the first rule');
            System.assert(foundRule, 'Did not find the rule for the first rule');
        }
    }


    @IsTest
    public static void checkRulesPopulateMultipleCompleteLogs() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            setMocks();

            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();
            
            // Insert two logs and RIB records for the first rule indicating processing not yet complete
            DateTime now = DateTime.now();
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            FormulaShare_Log__c log2 = new FormulaShare_Log__c();
            log.Processing_Started__c = now - 1000;
            log.Processing_Finished__c = now - 900;
            log.Batch_Finish_Complete__c = true;
            log2.Processing_Started__c = now - 100;
            log2.Processing_Finished__c = now;
            log2.Batch_Finish_Complete__c = true;
            insert log;
            insert log2;

            FormulaShare_Rule_in_Batch__c rib = new FormulaShare_Rule_in_Batch__c();
            FormulaShare_Rule_in_Batch__c rib2 = new FormulaShare_Rule_in_Batch__c();
            rib.FormulaShare_Log__c = log.Id;
            rib.FormulaShare_Rule_Name__c = fsRules[0].developerName;
            rib.Rule_Active_for_Batch_Run__c = true;
            rib2.FormulaShare_Log__c = log2.Id;
            rib2.FormulaShare_Rule_Name__c = fsRules[0].developerName;
            rib2.Rule_Active_for_Batch_Run__c = true;
            insert rib;
            insert rib2;

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            // Check that wrapped data includes the right structure to cover the first rule
            // This requires a parent row and a child row for the rule
            Boolean foundObject = false;
            Boolean foundRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    foundObject = true;
                    System.assert(orw.isParentRow, 'Not marked as parent row');

                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {
                        if(rw.developerName == fsRules[0].developerName) {
                            foundRule = true;
                            System.assertEquals(fsRules[0].ruleId, rw.ruleId, 'Mis-match of rule ID in wrapper');
                            System.assert(rw.sharedToLink.contains('objecttoken1234'), 'Link missing object token');
                            System.assert(rw.sharedToLink.contains('fieldtoken12345'), 'Link missing field token');
                            System.assertEquals(now.format(), rw.lastCalcStatus, 'Calc complete time does not match logs');
                        }
                    }
                }
            }

            System.assert(foundObject, 'Did not find the object of the first rule');
            System.assert(foundRule, 'Did not find the rule for the first rule');
        }
    }


    @IsTest
    public static void testBatchFinishMetricsPopulate() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareAsyncApexJobSelector.isScheduled = true;
            setMocks();
    
            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();

            // Create batch log
            FormulaShare_Log__c batchLog = FormulaShareTestDataFactory.getBatchLog();
            insert batchLog;

            // Create sample metrics for user rule
            FormulaShare_Metrics__c batchFinishMetrics = FormulaShareTestDataFactory.getBatchFinishMetricsForRuleAndBatch(FormulaShareRuleFactory.userRuleName, batchLog.Id);
            insert batchFinishMetrics;

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            Boolean foundUserRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {

                        // Check user rule
                        if(rw.developerName == FormulaShareRuleFactory.userRuleName) {
                            System.assertEquals(101, rw.noSharesApplied);
                            System.assertEquals(batchLog.Id, rw.lastBatchId);
                            System.assertEquals(UserInfo.getUserId(), rw.recordLogsReportId, 'Expected the mocked ID as the report ID');
                            System.assertEquals('RecordErrorsSinceLastBatchReportUrl', rw.warningUrl, 'Expected record error report to be set as url, since some records failed');
                            foundUserRule = true;
                        }
                    }
                }
            }
            System.assert(foundUserRule, 'Couldn\'t find user rule in list');
        }
    }


    @IsTest
    public static void testBatchFinishFailPlusOtherMetrics() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareAsyncApexJobSelector.isScheduled = true;
            setMocks();

            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();

            // Create batch log
            FormulaShare_Log__c batchLog = FormulaShareTestDataFactory.getBatchLog();
            insert batchLog;

            // Create sample metrics for user rule
            FormulaShare_Metrics__c batchFinishMetricsFailed = FormulaShareTestDataFactory.getBatchFinishMetricsForRuleAndBatchFail(FormulaShareRuleFactory.userRuleName, batchLog.Id);
            FormulaShare_Metrics__c triggerMetrics = FormulaShareTestDataFactory.getTriggerMetricsForRuleAndBatch(FormulaShareRuleFactory.userRuleName, batchLog.Id);
            insert batchFinishMetricsFailed;
            insert triggerMetrics;

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            Boolean foundUserRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {

                        // Check user rule
                        if(rw.developerName == FormulaShareRuleFactory.userRuleName) {
                            foundUserRule = true;
                            System.assertEquals(203, rw.noSharesApplied);
                            System.assertEquals(batchLog.Id, rw.lastBatchId);
                            System.assertEquals(UserInfo.getUserId(), rw.recordLogsReportId, 'Expected the mocked ID to be set for records report');
                            System.assertEquals('BatchErrorReportUrl', rw.warningUrl, 'Expected record error report to be set as url, since batch failed');
                        }
                    }
                }
            }
            System.assert(foundUserRule, 'Couldn\'t find user rule in list');
        }
    }


    @IsTest
    public static void testBatchAndTriggerOnly() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareAsyncApexJobSelector.isScheduled = true;
            setMocks();
    
            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();

            // Create sample metrics for user rule
            FormulaShare_Metrics__c batchMetrics = FormulaShareTestDataFactory.getBatchMetricsForRuleAndBatch(FormulaShareRuleFactory.userRuleName, null);
            FormulaShare_Metrics__c triggerMetrics = FormulaShareTestDataFactory.getTriggerMetricsForRuleAndBatch(FormulaShareRuleFactory.userRuleName, null);
            insert batchMetrics;
            insert triggerMetrics;

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            Boolean foundUserRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {

                        // Check user rule
                        if(rw.developerName == FormulaShareRuleFactory.userRuleName) {
                            foundUserRule = true;
                            System.assertEquals(205, rw.noSharesApplied);
                            System.assertEquals(UserInfo.getUserId(), rw.recordLogsReportId, 'Expected the mocked ID to be set for records report');
                            System.assertEquals('RecordErrorsAllReportUrl', rw.warningUrl, 'Expected all record errors, since no complete batch run yet');
                        }
                    }
                }
            }
            System.assert(foundUserRule, 'Couldn\'t find user rule in list');
        }
    }


    @IsTest
    public static void testNoJobScheduled() {
        
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareAsyncApexJobSelector.isScheduled = false;   // Should trigger error message relating to scheduled job
            setMocks();

            List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();

            // Run core method
            List<FormulaShareRulesListViewController.ObjectRulesWrapper> orwList = FormulaShareRulesListViewController.getTreeGridData();

            Boolean foundUserRule = false;
            for(FormulaShareRulesListViewController.ObjectRulesWrapper orw : orwList) {
                if(orw.objectApiName == fsRules[0].objectSharedAPIName) {
                    for(FormulaShareRulesListViewController.RuleWrapper rw : orw.items) {

                        // Check user rule
                        if(rw.developerName == FormulaShareRuleFactory.userRuleName) {
                            foundUserRule = true;
                            System.assertEquals('Schedule batch job', rw.warningUrlLabel, 'Expected batch job scheduled warning');
                        }
                    }
                }
            }
            System.assert(foundUserRule, 'Couldn\'t find user rule in list');
        }
    }    

//    To fix - failing when no rules
//    
//    @IsTest
//    public static void checkRecalculation() {
//        setMocks();
//        List<FormulaShareRule> fsRules = FormulaShareRulesSelector.construct().getAllRules();
//        String objApiName = fsRules[0].objectSharedAPIName;
//
//        Test.startTest();
//        FormulaShareRulesListViewController.recalculateSharing(objApiName);
//        Test.stopTest();
//
//        List<FormulaShare_Log__c> fsLogs = [SELECT Id, Type_In_Scope__c FROM FormulaShare_Log__c 
//            WHERE Context__c = 'FormulaShareProcessBatch'];
//        
//        System.assertEquals(1, fsLogs.size(), 'Expected a single log record for the batch');
//        System.assertEquals(objApiName, fsLogs[0].Type_In_Scope__c, 'Mismatch with object type submitted'); 
//    }

}