public with sharing class FormulaShareAsyncApexJobSelector extends fflib_SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return AsyncApexJob.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            AsyncApexJob.Id         
        };
    }

    // Returns true if a job is scheduled for the future or false otherwise
    // Designed to be safe to call in a loop (done from list view controller)
    @TestVisible static Boolean isFullBatchScheduled;
    public static Boolean isFullBatchScheduled() {
        if(isFullBatchScheduled == null) {
            FormulaShareAsyncApexJobSelector jobSelector = new FormulaShareAsyncApexJobSelector();
            List<AsyncApexJob> jobs = jobSelector.getScheduledJobs('FormulaShareProcessSchedulable');
            isFullBatchScheduled = !jobs.isEmpty();
        }
        return isFullBatchScheduled;
    }


    public List<AsyncApexJob> getScheduledJobs(String className) {
        List<String> finishedReasons = new List<String> {
            'Aborted', 'Completed', 'Failed'
        };
        // Querying CronTrigger requires API version 52+, so can switch to code below after FFLibs upgrade
//        String query = newQueryFactory()
//            .selectField(AsyncApexJob.Id)
//            .selectField('CronTrigger.OwnerId')
//            .setCondition('Status NOT IN :finishedReasons AND ApexClass.Name = :className')
//            .toSOQL();
        String query = 'SELECT Id, CronTriggerId, CronTrigger.OwnerId FROM AsyncApexJob WHERE Status NOT IN :finishedReasons AND ApexClass.Name = :className WITH SECURITY_ENFORCED';
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);

        return jobs;
    }


    public Integer getNoJobsProcessingAndInQueue(String className) {
        List<String> processingAndInQueueReasons = new List<String> {
            'Queued', 'Preparing', 'Processing' // Processing
            , 'Holding'                         // Holding
        };
        String query = newQueryFactory()
            .setCondition('Status IN :processingAndInQueueReasons AND ApexClass.Name = :className')
            .toSOQL();
        
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);
        return jobs.size();
    }

}
