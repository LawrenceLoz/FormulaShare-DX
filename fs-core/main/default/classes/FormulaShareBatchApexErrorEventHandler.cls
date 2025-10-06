public inherited sharing class FormulaShareBatchApexErrorEventHandler {

    // In-code allowlist of relevant batch class name prefixes
    private static final Set<String> allowedClassNames = new Set<String>{
        'FormulaShareProcessBatch',
        'FormulaShareTargetedJobsBatch'
    };

    @TestVisible static Boolean wasCalled = false;

    public static void handle(List<BatchApexErrorEvent> events) {
        wasCalled = true;

        if(events == null || events.isEmpty()) {
            return;
        }

        // Collect AsyncApexJob Ids from events
        Set<Id> jobIds = new Set<Id>();
        for(BatchApexErrorEvent e : events) {
            if(e.AsyncApexJobId != null) {
                jobIds.add(e.AsyncApexJobId);
            }
        }

        // Map AsyncApexJobId -> ApexClassId using selector
        Map<Id, Id> jobIdToClassId = new Map<Id, Id>();
        Set<Id> classIdsOfEvents = new Set<Id>();
        if(!jobIds.isEmpty()) {
            FormulaShareAsyncApexJobSelector jobSel = new FormulaShareAsyncApexJobSelector();
            jobIdToClassId = jobSel.getClassIdsByJobIds(jobIds);
            classIdsOfEvents.addAll(jobIdToClassId.values());
        }

        // Resolve allowed class Ids in our namespace via selector
        Set<Id> allowedClassIds = new Set<Id>();
        if(!classIdsOfEvents.isEmpty()) {
            String namespace = String.valueOf(FormulaShareUtilities.getNamespaceNoUnderscores());
            FormulaShareApexClassSelector classSel = new FormulaShareApexClassSelector();
            allowedClassIds = classSel.getIdsByNamesAndNamespace(allowedClassNames, namespace);
        }

        // Filter relevant events by allowed class Ids
        List<BatchApexErrorEvent> relevantEvents = new List<BatchApexErrorEvent>();
        List<Id> relevantAsyncJobs = new List<Id>();
        for(BatchApexErrorEvent e : events) {
            Id eventClassId = jobIdToClassId.get(e.AsyncApexJobId);
            if(eventClassId != null && allowedClassIds.contains(eventClassId)) {
                relevantEvents.add(e);
                relevantAsyncJobs.add(e.AsyncApexJobId);
            }
        }

        if(relevantEvents.isEmpty()) {
            return;
        }

        // Build a map of async job ids -> parent job id using selector
        Map<Id, Id> jobIdToParentId = new Map<Id, Id>();
        if(!relevantAsyncJobs.isEmpty()) {
            FormulaShareAsyncApexJobSelector jobSel2 = new FormulaShareAsyncApexJobSelector();
            jobIdToParentId = jobSel2.getParentIdsByJobIds(new Set<Id>(relevantAsyncJobs));
        }

        // Map ParentJobId -> FormulaShare_Log__c via logs selector
        Map<String, FormulaShare_Log__c> logByJobId = new Map<String, FormulaShare_Log__c>();
        if(!jobIdToParentId.isEmpty()) {
            FormulaShareBatchLogsSelector logsSel = new FormulaShareBatchLogsSelector();
            logByJobId = logsSel.getByParentJobIds(new Set<Id>(jobIdToParentId.values()));
        }

        // Prepare error detail records
        List<FormulaShare_Batch_Error_Details__c> detailsForInsert = new List<FormulaShare_Batch_Error_Details__c>();
        for(BatchApexErrorEvent e : relevantEvents) {
            Id parentJobId = jobIdToParentId.get(e.AsyncApexJobId);

            if(parentJobId != null) {                
                FormulaShare_Log__c parent = logByJobId.get(String.valueOf(parentJobId));

                if(parent != null) {
                    FormulaShare_Batch_Error_Details__c rec = new FormulaShare_Batch_Error_Details__c();
                    rec.FormulaShare_Log__c = parent.Id;
                    rec.AsyncApexJobId__c = String.valueOf(e.AsyncApexJobId);
                    rec.DoesExceedJobScopeMaxLength__c = e.DoesExceedJobScopeMaxLength;
                    rec.ExceptionType__c = e.ExceptionType;
                    rec.JobScope__c = e.JobScope;
                    rec.Message__c = e.Message != null ? e.Message.left(131072) : null;
                    rec.Phase__c = e.Phase;
                    rec.RequestId__c = e.RequestId;
                    rec.StackTrace__c = e.StackTrace != null ? e.StackTrace.left(131072) : null;
                    rec.DedupKey__c = String.valueOf(e.EventUuid);  // Platform events could be received more than once

                    detailsForInsert.add(rec);
                }
            }
        }

        if(detailsForInsert.isEmpty()) {
            return;
        }

        // Upsert using external id to dedupe; run in user mode to respect FLS/CRUD, with safe logging
        try {
            Database.upsert(detailsForInsert, FormulaShare_Batch_Error_Details__c.DedupKey__c, true, AccessLevel.USER_MODE);
        } catch (DmlException dmlEx) {
            // Avoid exposing sensitive info in logs; log minimal diagnostic
            System.debug(LoggingLevel.WARN, 'Batch Error Event upsert failed. Size=' + detailsForInsert.size());
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unexpected failure upserting batch error events.');
        }
    }
}
