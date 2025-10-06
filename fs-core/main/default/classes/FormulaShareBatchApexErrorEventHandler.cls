public inherited sharing class FormulaShareBatchApexErrorEventHandler {

    // In-code allowlist of relevant batch class name prefixes
    private static final Set<String> allowedClassNames = new Set<String>{
        'FormulaShareProcessBatch',
        'FormulaShareTargetedJobsBatch'
    };

    public static void handle(List<BatchApexErrorEvent> events) {
        if(events == null || events.isEmpty()) {
            return;
        }

        // Map ApexClassId -> ApexClass
        // BatchApexErrorEvent does not have ApexClassId, so we must get it via AsyncApexJob
        Set<Id> jobIds = new Set<Id>();
        for(BatchApexErrorEvent e : events) {
            if(e.AsyncApexJobId != null) {
                jobIds.add(e.AsyncApexJobId);
            }
        }

        // Map AsyncApexJobId to ApexClassId
        Map<Id, Id> jobIdToClassId = new Map<Id, Id>();
        Set<Id> classIdsOfEvents = new Set<Id>();
        if(!jobIds.isEmpty()) {
            for(AsyncApexJob job : [
                SELECT Id, ApexClassId FROM AsyncApexJob WHERE Id IN :jobIds
            ]) {
                if(job.ApexClassId != null) {
                    jobIdToClassId.put(job.Id, job.ApexClassId);
                    classIdsOfEvents.add(job.ApexClassId);
                }
            }
        }

        Map<Id, ApexClass> classById = new Map<Id, ApexClass>();
        Set<Id> allowedClassIds = new Set<Id>();
        if(!classIdsOfEvents.isEmpty()) {
            String namespace = FormulaShareUtilities.getNamespaceNoUnderscores();
            allowedClassIds = new Map<Id,ApexClass>([SELECT Id FROM ApexClass WHERE Name IN :allowedClassNames AND NamespacePrefix = :namespace]).keySet();
        }

        // Filter relevant events by allowed class prefixes and our namespace (or empty during unmanaged)
        List<BatchApexErrorEvent> relevantEvents = new List<BatchApexErrorEvent>();
        List<Id> relevantAsyncJobs = new List<Id>();
        for(BatchApexErrorEvent e : events) {
            Id eventClassId = jobIdToClassId.get(e.AsyncApexJobId);
            if(eventClassId != null && allowedClassIds.contains(eventClassId)) {
                relevantEvents.add(e);
                relevantAsyncJobs.add(e.AsyncApexJobId);
            }
        }

        // If no relevant events, suggests none of the classes of the are FormulaShare batches
        if(relevantEvents.isEmpty()) {
            return;
        }

        // Build a map of async job ids to their parent (start method) job id
        Map<Id, Id> jobIdToParentId = new Map<Id, Id>();
        for(AsyncApexJob job : [
            SELECT Id, ParentJobId FROM AsyncApexJob WHERE Id IN :relevantAsyncJobs
        ]) {
            jobIdToParentId.put(job.Id, job.ParentJobId);
        }

        Map<String, FormulaShare_Log__c> logByJobId = new Map<String, FormulaShare_Log__c>();
        if(!jobIdToParentId.isEmpty()) {
            for(FormulaShare_Log__c log : [
                SELECT Id, AsyncApexJobParentId__c FROM FormulaShare_Log__c WHERE AsyncApexJobParentId__c IN :jobIdToParentId.values()
            ]) {
                logByJobId.put(log.AsyncApexJobParentId__c, log);
            }
        }

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
                    rec.Message__c = e.Message;
                    rec.Phase__c = e.Phase;
                    rec.RequestId__c = e.RequestId;
                    rec.StackTrace__c = e.StackTrace;
                    rec.DedupKey__c = String.valueOf(e.EventUuid);  // Theoretically platform events could be received more than once

                    detailsForInsert.add(rec);
                }
            }
        }

        // Insert, letting unique ext id dedupe
        try {
            upsert detailsForInsert FormulaShare_Batch_Error_Details__c.DedupKey__c;
        } catch (Exception ex) {
            System.debug('Error upserting Batch Error Event records: ' + ex.getMessage());
        }

    }
}

