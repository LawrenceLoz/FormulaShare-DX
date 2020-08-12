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
    static Map<String,Integer> validSharesNewMetrics;
    static FormulaShare_Settings__mdt settings;
    static fflib_ISObjectUnitOfWork uow;
    public static final String batchContext = FormulaShareProcessBatch.batchContext;
    public static final String triggerContext = 'Trigger';

    public static void processForEvents(List<FormulaShare_Processed_Share_Event__e> pseList, String eventContext) {
        context = eventContext;
        uow = FormulaShareApplication.unitOfWork.newInstance();
        process(pseList);
        uow.commitWork();   // Commit all DML
    }

    public static fflib_ISObjectUnitOfWork processForBatch(fflib_ISObjectUnitOfWork batchUow, List<FormulaShare_Processed_Share_Event__e> pseList, FormulaShare_Log__c relatedBatchLog, Map<String,Integer> noValidSharesNewMetrics) {
        context = batchContext;
        uow = batchUow;
        system.debug('Processing for batch. UOW1: '+uow);
        batchLog = relatedBatchLog;
        validSharesNewMetrics = noValidSharesNewMetrics;
        process(pseList);
        system.debug('Processing for batch. UOW2: '+uow);
        return uow;     // Pass uow back to ProcessBatch class
    }
    

    private static void process(List<FormulaShare_Processed_Share_Event__e> pseList) {
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
        if(settings.Log_Processing_Events__c == 'All') {
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
        setMetrics(processedRecordShares);
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

                // If status was set there's no need to query, so map to record and add to be inserted
                if(pse.Status__c != null) {
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
                if(!type.getDescribe().isCustom()) {
                    FormulaShareSObjectSharesStdSelector sharesSelector = new FormulaShareSObjectSharesStdSelector(true, shareObjectType, type);
                    List<SObject> sharesList = sharesSelector.selectByParentIds(parentIdsString);
                    for(SObject share : sharesList) {
                        String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(type, share);
                        shareKeySet.add(shareKey);
                        shareIdSet.add(share.Id);
                    }
                }

                // For custom objects, query for all shares and add to sets
                else {
                    String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(sharingReasonsSet);
                    FormulaShareSObjectSharesCustomSelector sharesSelector = new FormulaShareSObjectSharesCustomSelector(true, shareObjectType);
                    List<SObject> sharesList = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
                    for(SObject share : sharesList) {
                        String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);
                        shareKeySet.add(shareKey);
                        shareIdSet.add(share.Id);
                    }
                }

                // Set statuses based on information returned
                for(FormulaShare_Processed_Share_Event__e pse : pseWithoutStatus) {

                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, recordLogsMap, groupsMap);

                    // For insert, check whether share record was found in queried records and set to Success if so
                    if(prs.Operation__c == 'Insert') {
                        if(shareKeySet.contains(pse.Share_Key__c)) {
                            prs.Status__c = 'Success';
                        }
                        else {
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record to be inserted wasn\'t detected in query';
                        }
                    }

                    // For delete, check whether share record was found in queried records and set to Success if not
                    else if(prs.Operation__c == 'Delete') {
                        if(!shareIdSet.contains(pse.Share_Id__c)) {
                            prs.Status__c = 'Success';
                        }
                        else {
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record identified for removal not actually deleted';
                        }
                    }

                    processedRecordShares.add(prs);
                }
            }
        }

        return processedRecordShares;
    }


    // Returns a map of groups corresponding to Shared_to_Id__c values in events list
    private static Map<Id,Group> getGroupsMap(List<FormulaShare_Processed_Share_Event__e> pseList) {

        // Find groups we'll need to query based on Shared_to_Id__c type
        List<Id> groupIdList = new List<Id>();
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
            Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
            Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();
            if(userOrGroupType == Group.SOBjectType) {
                system.debug('group id: '+userOrGroupId);
                groupIdList.add(userOrGroupId);
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

        // Check whether user or group share
        Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
        system.debug('userOrGroupId: '+ userOrGroupId);
        Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();

        // Set status if provided
        prs.Status__c = pse.Status__c;
        prs.Status_Reason__c = pse.Failed_Status_Reason__c;

        // Populate share with type and relevant fields depending on user or group sharing
        if(userOrGroupType == User.SOBjectType) {
            prs.Shared_to_User__c = userOrGroupId;
            prs.Share_With__c = 'Users';
        }
        else if(userOrGroupType == Group.SOBjectType) {
            Group grp = groupsMap.get(userOrGroupId);
            prs.Shared_to_Role_or_Group__c = grp.DeveloperName;
            prs.Share_With__c = grp.Type;
        }

        // Register records for insert if settings allow
        if(settings.Log_Processing_Events__c == 'All') {
            // Set master detail relationship
            FormulaShare_Record_Log__c recordLog = recordLogsMap.get(pse.Record_Id__c);
            uow.registerNew(prs, FormulaShare_Processed_Record_Share__c.Processed_Record__c, recordLog);
        }

        return prs;
    }


    private static void setMetrics(List<FormulaShare_Processed_Record_Share__c> prsList) {
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

        // Add or update increments for first created metrics if running batch for first time
        if(context == batchContext) {
            for(String ruleName : validSharesNewMetrics.keySet()) {
                System.debug('Processing for inc: '+ruleNAme);
                
                FormulaShareMetrics.Increment inc;
                Integer noValidShares = validSharesNewMetrics.get(ruleName);

                if(metricsIncrements.containsKey(ruleName)) {
                    System.debug('Found metric increment');
                    inc = metricsIncrements.get(ruleName);

                    // Check whether we have more valid shares than the ones inserted now, and increase if so
                    if(noValidShares != null && inc.noSuccessfulInserts + inc.noFailedInserts < noValidShares) {
                        inc.noSuccessfulInserts = noValidShares - inc.noFailedInserts;
                    }
                    metricsIncrements.put(ruleName, inc);
                }

                // If we didn't have an increment for this rule, create one indicating all valid shares are inserted
                else if(noValidShares != null && noValidShares > 0) {
                    System.debug('Creating metric increment');
                    inc = new FormulaShareMetrics.Increment();
                    inc.noSuccessfulInserts = noValidShares;
                    inc.noFailedInserts = 0;
                    inc.LastSuccessfulOperation = DateTime.now();
                    metricsIncrements.put(ruleName, inc);
                }
            }
        }

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
        uow = metrics.augmentMetrics(uow, metricsIncrements);
    }

}