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
    public static final String batchContext = 'Batch Operations Since Last Batch';
    public static final String triggerContext = 'Trigger Operations Since Last Batch';
    public static final String batchFinishContext = 'Last Batch';

    public static void processForEvents(List<FormulaShare_Processed_Share_Event__e> pseList, String eventContext) {
        System.debug('pseList: '+ pseList);
        context = eventContext;
        uow = FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
        process(pseList);
        uow.commitWork();   // Commit all DML
    }

    public static IncrementsWithUow processForBatch(fflib_ISObjectUnitOfWork batchUow, List<FormulaShare_Processed_Share_Event__e> pseList, FormulaShare_Log__c relatedBatchLog) {
        context = batchContext;
        uow = batchUow;
        system.debug('Processing for batch. UOW1: '+uow);
        batchLog = relatedBatchLog;

        Map<String,FormulaShareMetrics.Increment> incMap;
        incMap = process(pseList);
        
        IncrementsWithUow incWithUow = new IncrementsWithUow();
        incWithUow.incrementsMap = incMap;
        incWithUow.uow = uow;
        system.debug('Processing for batch. UOW2: '+uow);

        return incWithUow;     // Pass uow back to ProcessBatch class
    }

    public static fflib_ISObjectUnitOfWork processForBatchFail(fflib_ISObjectUnitOfWork batchUow, List<FormulaShareRule> rules) {
        context = batchContext;
        uow = batchUow;
        setMetricsForBatchFail(rules);
        return uow;
    }

    public static fflib_ISObjectUnitOfWork processForBatchFinish(fflib_ISObjectUnitOfWork batchUow, Map<String,Integer> totalValidSharesForRule, Map<String,Integer> totalErrorSharesForRule, FormulaShare_Log__c relatedBatchLog) {
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
            if(!processedRecords.containsKey(pse.Record_Id__c)) {
                FormulaShare_Record_Log__c pr = new FormulaShare_Record_Log__c();
                pr.Object__c = pse.Object__c;
                pr.Record_Id__c = pse.Record_Id__c;
                pr.Processed_Date_Time__c = pse.Processed_Date_Time__c;
                processedRecords.put(pr.Record_Id__c, pr);
            }

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
        
        if(createRecordLogs()) {
            uow.registerNew(recordLogs);

            // If processing batch, register a relationship with the batch log
            for(FormulaShare_Record_Log__c recordLog : recordLogs) {
                if(context == batchContext && batchLog != null) {
                    uow.registerRelationship(recordLog, FormulaShare_Record_Log__c.FormulaShare_Batch_Log__c, batchLog);
                }
            }
        }

        // Get processed records share objects (method will internally register for insert)
        List<FormulaShare_Processed_Record_Share__c> processedRecordShares = getProcessedRecordShares(recordLogs, eventsByType);

        // Query for and update, or create new metrics records
        Map<String,FormulaShareMetrics.Increment> increments = setMetricsProcessedRecords(processedRecordShares);

        // Fire event to update rules list view
        List<String> objectLabels = new List<String>();
        for(String objectName : eventsByType.keySet()) {
            FormulaShareUtilities.describe(objectName).getLabel();
        }
        fireRulesListUpdateEvent(objectLabels);

        return increments;
    }


    private static List<FormulaShare_Processed_Record_Share__c> getProcessedRecordShares(List<FormulaShare_Record_Log__c> recordLogs, Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType) {
        List<FormulaShare_Processed_Record_Share__c> processedRecordShares = new List<FormulaShare_Processed_Record_Share__c>();

        Map<String,FormulaShare_Record_Log__c> recordLogsMap = new Map<String,FormulaShare_Record_Log__c>();
        for(FormulaShare_Record_Log__c recordLog : recordLogs) {
            recordLogsMap.put(recordLog.Record_Id__c, recordLog);
        }

        for(String objectName : eventsByType.keySet()) {

            // Build sets of record ids and sharing reasons for query
            Set<String> recordIdsSet = new Set<String>();
            Set<String> sharingReasonsSet = new Set<String>();
            List<FormulaShare_Processed_Share_Event__e> pseForObjectList = eventsByType.get(objectName);
            List<FormulaShare_Processed_Share_Event__e> pseWithoutStatus = new List<FormulaShare_Processed_Share_Event__e>();

            // Query for details of relevant groups
            Map<Id,Group> groupsMap = getGroupsMap(pseForObjectList);

            for(FormulaShare_Processed_Share_Event__e pse : pseForObjectList) {

                // If status was set (e.g. if entity not found) there's no need to query, so map to record and add to be inserted
                if(pse.Status__c != null) {
                    System.debug('Adding share with status set: '+pse);
                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, recordLogsMap, groupsMap);
                    processedRecordShares.add(prs);
                }

                // Otherwise track in list to be augmented with status
                if(pse.Status__c == null) {
                    pseWithoutStatus.add(pse);
                    recordIdsSet.add(pse.Record_Id__c);
                    sharingReasonsSet.add(pse.Sharing_Reason__c);    // Note this will be null for standard objects
                }
            }

            // If we found shares without status, query for these to check status and add details
            if(!recordIdsSet.isEmpty()) {

                String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordIdsSet);

                // Get SOBject types for queries
                SOBjectType type = FormulaShareUtilities.getSObjectTypeFromName(objectName);
                SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);

                // Build sets of share keys and record ids for existing sharing on the records in scope
                Set<String> shareKeySet = new Set<String>();
                Set<Id> shareIdSet = new Set<Id>();

                // For standard objects, query for all shares and add keys & ids to sets
                List<SObject> sharesList;
                FormulaShareSObjectSharesSelector sharesSelector = new FormulaShareSObjectSharesSelector(true, shareObjectType, type);
                if(!type.getDescribe().isCustom()) {
                    sharesList = sharesSelector.selectByParentIds(parentIdsString);
                }

                // For custom objects, query for all shares and add to sets
                else {
                    String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(sharingReasonsSet);
                    sharesList = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
                }

                for(SObject share : sharesList) {
                    FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
                    String shareKey = objectUtils.getShareKey(share);
                    shareKeySet.add(shareKey);
                    shareIdSet.add(share.Id);
                }

                // Set statuses based on information returned
                for(FormulaShare_Processed_Share_Event__e pse : pseWithoutStatus) {

                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, recordLogsMap, groupsMap);

                    // For insert, check whether share record was found in queried records and set to Success if so
                    if(prs.Operation__c == 'Insert') {
                        if(shareKeySet.contains(pse.Share_Key__c)) {
                            System.debug('Found the record for this share: '+pse.Share_Key__c);
                            prs.Status__c = 'Success';
                        }
                        else {
                            System.debug('No record found for this share : '+pse.Share_Key__c);
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record to be inserted wasn\'t detected in query';
                        }
                    }

                    // For delete, check whether share record was found in queried records and set to Success if not
                    else if(prs.Operation__c == 'Delete') {
                        if(!shareIdSet.contains(pse.Share_Id__c)) {
                            System.debug('Confirmed this share was deleted: '+pse.Share_Key__c);
                            prs.Status__c = 'Success';
                        }
                        else {
                            System.debug('Expected this share to be deleted (record still exists): '+pse.Share_Key__c);
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record identified for removal not actually deleted';
                        }
                    }

                    processedRecordShares.add(prs);
                }
            }
        }

        System.debug('Full processedRecordShare list: '+processedRecordShares);

        return processedRecordShares;
    }


    // Returns a map of groups corresponding to Shared_to_Id__c values in events list
    private static Map<Id,Group> getGroupsMap(List<FormulaShare_Processed_Share_Event__e> pseList) {

        // Find groups we'll need to query based on Shared_to_Id__c type
        List<Id> groupIdList = new List<Id>();
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
            if(pse.Shared_to_Id__c != null) {
                Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
                Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();

                if(userOrGroupType == Group.SOBjectType) {
                    system.debug('group id: '+userOrGroupId);
                    groupIdList.add(userOrGroupId);
                }
            }
        }
        
        // Build map of groups to populate details on processed records
        Map<Id,Group> groupsMap = new Map<Id,Group>();
        if(!groupIdList.isEmpty()) {
            groupsMap = new Map<Id,Group>([SELECT Id, DeveloperName, Type FROM Group WHERE Id IN :groupIdList]);
        }

        return groupsMap;
    }


    // Returns a record based on the event, which is populated with group details and success / failure info
    private static FormulaShare_Processed_Record_Share__c mapEventToProcessedRecordShare(FormulaShare_Processed_Share_Event__e pse, Map<String,FormulaShare_Record_Log__c> recordLogsMap, Map<Id,Group> groupsMap) {
        FormulaShare_Processed_Record_Share__c prs = new FormulaShare_Processed_Record_Share__c();

        // Set lookup to processed record and other common fields
        prs.Operation__c = pse.Operation__c;
        prs.Sharing_Reason__c = pse.Sharing_Reason__c;
        prs.FormulaShare_Rule_Name__c = pse.FormulaShare_Rule_Name__c;
        prs.Access_Level__c = pse.Access_Level__c;

        // Set status if provided
        prs.Status__c = pse.Status__c;
        prs.Status_Reason__c = pse.Failed_Status_Reason__c;

        // Populate share with type and relevant fields depending on user or group sharing
        // Check whether user or group share
        if(pse.Shared_to_Id__c != null) {
            Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
            system.debug('userOrGroupId: '+ userOrGroupId);
            Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();
            if(userOrGroupType == User.SOBjectType) {
                prs.Shared_to_User__c = userOrGroupId;
                prs.Share_With__c = 'Users';
            }
            else if(userOrGroupType == Group.SOBjectType) {
                Group grp = groupsMap.get(userOrGroupId);
                prs.Shared_to_Role_or_Group__c = grp.DeveloperName;
                prs.Share_With__c = grp.Type;
            }
        }

        // If share with wasn't populated based on id type (e.g. if entity not found), set this from attribute
        // (we don't do this for all logs because share with isn't known for deletes)
        else {
            prs.Share_With__c = pse.Share_With__c;
        }

        if(createRecordLogs()) {
            // Set master detail relationship
            FormulaShare_Record_Log__c recordLog = recordLogsMap.get(pse.Record_Id__c);
            uow.registerNew(prs, FormulaShare_Processed_Record_Share__c.Processed_Record__c, recordLog);
        }

        return prs;
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


    private static void clearMetricsAfterBatchFinish(Set<String> ruleNamesSet, FormulaShare_Log__c batchLog) {

        // Get existing metrics for rules
        List<FormulaShare_Metrics__c> metricsObjectList = new FormulaShareMetricsSelector().getAllMetricsForRules(ruleNamesSet);

        // Consider only batch and trigger metrics
        List<FormulaShare_Metrics__c> metricsOjectsToUpdate = new List<FormulaShare_Metrics__c>();
        for(FormulaShare_Metrics__c metricsObj : metricsObjectList) {
            if(metricsObj.Context__c == batchContext || metricsObj.Context__c == triggerContext) {
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

    private static Map<String,FormulaShareMetrics.Increment> setMetricsProcessedRecords(List<FormulaShare_Processed_Record_Share__c> prsList) {
        Map<String,FormulaShareMetrics.Increment> metricsIncrements = new Map<String,FormulaShareMetrics.Increment>();

        for(FormulaShare_Processed_Record_Share__c prs : prsList) {

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
        return settings.Log_Processing_Events__c == 'All' && FormulaShareAsyncApexJobSelector.isScheduled();
    }


    public class IncrementsWithUow {
        public Map<String,FormulaShareMetrics.Increment> incrementsMap;
        public fflib_ISObjectUnitOfWork uow;
    }

}