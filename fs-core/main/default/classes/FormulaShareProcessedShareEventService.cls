/**
*Copyright 2020 Lawrence Newcombe
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

public inherited sharing class FormulaShareProcessedShareEventService {

    static String context;    // "Batch" and "Trigger" supported
    static FormulaShare_Log__c batchLog;
    static FormulaShare_Settings__mdt settings;
    static fflib_ISObjectUnitOfWork uow;

    // Metrics type names defined below.
    // Typically we would expect each rule to have at most one metrics record for the following:
    // 
    // 'Last Batch' - Set in the full batch finish method with all valid shares meeting the criteria of the rule (whether or not these were created in this batch)
    // 'Batch Operations Since Last Batch' - Incremented with number of shares created in a currently running full batch. Set to zero after full batch run
    // 'Targeted Job Operations Since Last Batch' - Incremented with number of shares created by targeted jobs since the last full batch run. Set to zero after full batch run
    // 'Trigger Operations Since Last Batch' - Incremented with number of shares created by targeted jobs since the last full batch run. Set to zero after full batch run
    //
    // Together these metrics allow us to represent the true number of shares immediately after the last batch run,
    // But show the total plus any created since a full run between full batch runs.
    // Logic for this is in FormulaShareRulesListViewController

    public static final String batchContext = 'Batch Operations Since Last Batch';
    public static final String targetedJobContext = 'Targeted Job Operations Since Last Batch';
    public static final String triggerContext = 'Trigger Operations Since Last Batch';
    public static final String batchFinishContext = 'Last Batch';

    private static Integer noRecordsSharingAppliedFirstTime;
    private static Integer noRecordsAllSharingRemoved;
    private static Integer noRecordsSharingUpdated;

    public static void processForEvents(List<FormulaShare_Processed_Share_Event__e> pseList, String eventContext) {
        System.debug('pseList: '+ pseList);
        context = eventContext;
        uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
        process(pseList);
        uow.commitWork();   // Commit all DML
    }


    public static IncrementsWithUow processForTargetedJobOrBatch(fflib_ISObjectUnitOfWork batchUow, List<FormulaShare_Processed_Share_Event__e> pseList, FormulaShare_Log__c relatedBatchLog, String executeContext) {
        context = executeContext;
        uow = batchUow;
        system.debug('Processing for batch. UOW1: '+uow);
        batchLog = relatedBatchLog;

        Map<String,FormulaShareMetrics.Increment> incMap;
        incMap = process(pseList);

        IncrementsWithUow incWithUow = new IncrementsWithUow();
        incWithUow.incrementsMap = incMap;
        incWithUow.uow = uow;

        // Pass back sharing changes from this batch
        incWithUow.noRecordsSharingAppliedFirstTime = noRecordsSharingAppliedFirstTime;
        incWithUow.noRecordsAllSharingRemoved = noRecordsAllSharingRemoved;
        incWithUow.noRecordsSharingUpdated = noRecordsSharingUpdated;

        system.debug('Processing for batch. UOW2: '+uow);

        return incWithUow;
    }

    public static fflib_ISObjectUnitOfWork processForBatchFail(fflib_ISObjectUnitOfWork batchUow, List<FormulaShareRule> rules) {
        context = batchContext;
        uow = batchUow;
        setMetricsForBatchFail(rules);
        return uow;
    }

    public static fflib_ISObjectUnitOfWork processForFullBatchFinish(fflib_ISObjectUnitOfWork batchUow, Map<String,Integer> totalValidSharesForRule, Map<String,Integer> totalErrorSharesForRule, FormulaShare_Log__c relatedBatchLog) {
        context = batchFinishContext;
        uow = batchUow;
        batchLog = relatedBatchLog;
        setMetricsForBatchFinish(totalValidSharesForRule, totalErrorSharesForRule);
        clearMetricsAfterBatchFinish(totalValidSharesForRule.keySet(), relatedBatchLog);
        return uow;
    }


    private static Map<String,FormulaShareMetrics.Increment> process(List<FormulaShare_Processed_Share_Event__e> pseList) {
        settings = FormulaShareSettingsSelector.construct().selectActiveSettings();

        Map<String,FormulaShare_Record_Log__c> processedRecords = new Map<String,FormulaShare_Record_Log__c>();
        Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType = new Map<String,List<FormulaShare_Processed_Share_Event__e>>();
    
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {

            // Contruct processed record logs
            FormulaShare_Record_Log__c pr;
            if(!processedRecords.containsKey(pse.Record_Id__c)) {
                pr = new FormulaShare_Record_Log__c();
                pr.Object__c = pse.Object__c;
                pr.Record_Id__c = pse.Record_Id__c;
                pr.Processed_Date_Time__c = pse.Processed_Date_Time__c;
                pr.Context_Detail__c = pse.Context_Detail__c;
                pr.Assessment_Type_Override__c = pse.Assessment_Type_Override__c;
            }
            else {
                pr = processedRecords.get(pse.Record_Id__c);
            }
            processedRecords.put(pr.Record_Id__c, pr);

            // Populate map with records split by object type
            List<FormulaShare_Processed_Share_Event__e> pseForObjectList;
            if(eventsByType.containsKey(pse.Object__c)) {
                pseForObjectList = eventsByType.get(pse.Object__c);
            }
            else {
                pseForObjectList = new List<FormulaShare_Processed_Share_Event__e>();
            }
            pseForObjectList.add(pse);
            eventsByType.put(pse.Object__c, pseForObjectList);
        }
    
        // Get processed record objects and register for insert if allowed
        List<FormulaShare_Record_Log__c> recordLogs = processedRecords.values();
        Boolean createRecordLogs = createRecordLogs();
        if(createRecordLogs) {
            uow.registerNew(recordLogs);

            // If processing batch, register a relationship with the batch log
            for(FormulaShare_Record_Log__c recordLog : recordLogs) {
                if(context == batchContext && batchLog != null) {
                    uow.registerRelationship(recordLog, FormulaShare_Record_Log__c.FormulaShare_Batch_Log__c, batchLog);
                }
            }
        }

        // Add in any additional changes - virtual class can be extended to add additional processing and DML
        FormulaShareProcessedRecordShare prs = new FormulaShareInjectionService().getProcessedRecordShare();
        uow = prs.prepare(uow, context, recordLogs, eventsByType, createRecordLogs);

        noRecordsSharingAppliedFirstTime = prs.getRecordsSharingAppliedFirstTime();
        noRecordsAllSharingRemoved = prs.getRecordsAllSharingRemoved();
        noRecordsSharingUpdated = prs.getNoRecordsSharingUpdated();

        // Query for and update, or create new metrics records
        Map<String,FormulaShareMetrics.Increment> increments = setMetricsProcessedRecords(prs.wrappedRecordShares);

        // Fire event to update rules list view
        List<String> objectLabels = new List<String>();
        for(String objectName : eventsByType.keySet()) {
            FormulaShareUtilities.describe(objectName).getLabel();
        }
        fireRulesListUpdateEvent(objectLabels);

        return increments;
    }


    // Will augment metrics to indicate a batch failure
    private static void setMetricsForBatchFail(List<FormulaShareRule> rules) {
        Map<String,FormulaShareMetrics.Increment> metricsIncrements = new Map<String,FormulaShareMetrics.Increment>();

        for(FormulaShareRule rule : rules) {
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = 0;
            inc.noFailedInserts = 0;
            inc.lastFailedBatch = DateTime.now();
            metricsIncrements.put(rule.developerName, inc);
        }
        
        // Insert or update metrics
        FormulaShareMetrics metrics = getNewAndExistingMetrics(metricsIncrements);
        uow = metrics.augmentMetrics(uow, metricsIncrements);
    }


    // Update batch metrics at end of run to overwrite total shares
    private static void setMetricsForBatchFinish(Map<String,Integer> totalValidSharesForRule, Map<String,Integer> totalErrorSharesForRule) {
        Map<String,FormulaShareMetrics.Increment> metricsIncrements = new Map<String,FormulaShareMetrics.Increment>();

        for(String ruleName : totalValidSharesForRule.keySet()) {
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = totalValidSharesForRule.get(ruleName);
            inc.noFailedInserts = totalErrorSharesForRule.get(ruleName);
            inc.lastSuccessfulBatch = DateTime.now();
            metricsIncrements.put(ruleName, inc);
        }
        
        // Insert or update metrics
        FormulaShareMetrics metrics = getNewAndExistingMetrics(metricsIncrements);
        uow = metrics.overwriteMetrics(uow, metricsIncrements, batchLog);
    }


    // Will update any metrics representing inserts/errors since the last batch (trigger ops, targeted jobs and inserts from the running batch)
    // These will be replaced by the batch finish metrics (Context = "Last Batch")
    private static void clearMetricsAfterBatchFinish(Set<String> ruleNamesSet, FormulaShare_Log__c batchLog) {

        // Get existing metrics for rules
        List<FormulaShare_Metrics__c> metricsObjectList = new FormulaShareMetricsSelector().getAllMetricsForRules(ruleNamesSet);

        // Consider only batch, trigger and targeted job metrics
        List<FormulaShare_Metrics__c> metricsOjectsToUpdate = new List<FormulaShare_Metrics__c>();
        for(FormulaShare_Metrics__c metricsObj : metricsObjectList) {
            if(metricsObj.Context__c == batchContext 
                || metricsObj.Context__c == triggerContext
                || metricsObj.Context__c == targetedJobContext) {
                metricsOjectsToUpdate.add(metricsObj);
            }
        }
        System.debug('metricsOjectsToUpdate '+ metricsOjectsToUpdate);
        FormulaShareMetrics metrics = new FormulaShareMetrics(metricsOjectsToUpdate);

        // Create a zero metric for each rule
        Map<String,FormulaShareMetrics.Increment> metricsIncrements = new Map<String,FormulaShareMetrics.Increment>();
        for(String ruleName : ruleNamesSet) {
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = 0;
            inc.noFailedInserts = 0;
            metricsIncrements.put(ruleName, inc);
        }
        
        // Update all batch and trigger metrics with last batch lookup and zero success/fail
        uow = metrics.overwriteMetrics(uow, metricsIncrements, batchLog);
    }

    private static Map<String,FormulaShareMetrics.Increment> setMetricsProcessedRecords(List<FormulaShareProcessedRecordShare.PRSWrapper> wrappedRecordShares) {
        Map<String,FormulaShareMetrics.Increment> metricsIncrements = new Map<String,FormulaShareMetrics.Increment>();

        for(FormulaShareProcessedRecordShare.PRSWrapper wrappedRecordShare : wrappedRecordShares) {
            FormulaShare_Processed_Record_Share__c prs = wrappedRecordShare.processedRecordShare;

            // Capture metrics only for insert operations related to a specific rule (deletes won't have rule name associated)
            if(prs.FormulaShare_Rule_Name__c != null && prs.Operation__c == 'Insert') {

                FormulaShareMetrics.Increment inc;
                if(metricsIncrements.containsKey(prs.FormulaShare_Rule_Name__c)) {
                    inc = metricsIncrements.get(prs.FormulaShare_Rule_Name__c);
                }
                else {
                    inc = new FormulaShareMetrics.Increment();
                    inc.noSuccessfulInserts = 0;
                    inc.noFailedInserts = 0;
                }
    
                // Increment and set date/times depending on status and context
                if(prs.Status__c == 'Success') {
                    inc.noSuccessfulInserts++;
                    inc.LastSuccessfulOperation = DateTime.now();
                }
                else if(prs.Status__c == 'Error') {
                    inc.noFailedInserts++;
                    inc.lastFailedOperation = DateTime.now();
                }
    
                metricsIncrements.put(prs.FormulaShare_Rule_Name__c, inc);
            }
        }

        FormulaShareMetrics metrics = getNewAndExistingMetrics(metricsIncrements);
        uow = metrics.augmentMetrics(uow, metricsIncrements);

        return metricsIncrements;
    }


    private static FormulaShareMetrics getNewAndExistingMetrics(Map<String,FormulaShareMetrics.Increment> metricsIncrements) {
        
        // Get existing metrics and match to wrapper records
        List<FormulaShare_Metrics__c> metricsObjectList = new FormulaShareMetricsSelector().getMetricsForRulesAndContext(metricsIncrements.keySet(), context);
        System.debug('metricsObjectList: '+ metricsObjectList);
        System.debug('metricsIncrements: '+ metricsIncrements);

        // Prepare set of rule names which are not in existing metrics records
        List<String> rulesInMetrics = new List<String>();
        for(FormulaShare_Metrics__c metricsObject : metricsObjectList) {
            rulesInMetrics.add(metricsObject.FormulaShare_Rule_Name__c);
        }
        Set<String> rulesNotInMetrics = metricsIncrements.keySet().clone();
        rulesNotInMetrics.removeAll(rulesInMetrics);

        // Instantiate domain with existing metrics, set new metrics, and augment all with increments
        FormulaShareMetrics metrics = new FormulaShareMetrics(metricsObjectList);
        metrics.setBlankMetrics(rulesNotInMetrics, context);
        return metrics;
    }


    // Publish event to update FormulaShare Rules list in real time
    public static void fireRulesListUpdateEvent(List<String> objectLabels) {
        List<FormulaShare_List_Update__e> eventsList = new List<FormulaShare_List_Update__e>();
        
        for(String objectLabel : objectLabels) {
            FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
            updateEvent.Type__c = 'recalculation';
            updateEvent.Object_Label__c = objectLabel;
            eventsList.add(updateEvent);
        }

        List<Database.SaveResult> results = EventBus.publish(eventsList);
    }


    // Create record logs only if setting allows
    // And only if job is scheduled (to prevent data volumes growing without cleanup job running)    
    private static Boolean createRecordLogs() {
        return settings.Log_Processing_Events__c == 'All' && FormulaShareAsyncApexJobSelector.isFullBatchScheduled();
    }


    public class IncrementsWithUow {
        public Map<String,FormulaShareMetrics.Increment> incrementsMap;
        public fflib_ISObjectUnitOfWork uow;
        public Integer noRecordsSharingAppliedFirstTime;
        public Integer noRecordsAllSharingRemoved;
        public Integer noRecordsSharingUpdated;
    }

}