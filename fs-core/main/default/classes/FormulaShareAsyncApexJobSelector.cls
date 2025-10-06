public inherited sharing class FormulaShareAsyncApexJobSelector extends fflib_SObjectSelector {

    private List<String> finishedReasons = new List<String> {
        'Aborted', 'Completed', 'Failed'
    };

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

    @TestVisible static Boolean isFullOrTargetedBatchScheduled;
    public static Boolean isFullOrTargetedBatchScheduled() {
        if(isFullOrTargetedBatchScheduled == null) {
            FormulaShareAsyncApexJobSelector jobSelector = new FormulaShareAsyncApexJobSelector();
            List<AsyncApexJob> jobs = jobSelector.getScheduledJobs(new List<String>{'FormulaShareProcessSchedulable','FormulaShareTargetedJobsSchedulable'});
            isFullOrTargetedBatchScheduled = !jobs.isEmpty();
        }
        return isFullOrTargetedBatchScheduled;
    }


    private List<AsyncApexJob> getScheduledJobs(List<String> classNames) {
        String query = newQueryFactory()
            .selectField(AsyncApexJob.Id)
            .selectField('CronTrigger.OwnerId')
            .setCondition('Status NOT IN :finishedReasons AND ApexClass.Name IN :classNames')
            .toSOQL();
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);

        return jobs;
    }

    public List<AsyncApexJob> getScheduledJobs(String className) {
        return getScheduledJobs(new List<String>{className});
    }

    public List<AsyncApexJob> getScheduledJobsWithCronTriggerFields(List<String> classNames) {
        String query = newQueryFactory()
            .selectField(AsyncApexJob.Id)
            .selectField('CronTriggerId')
            .selectField('CronTrigger.CronExpression')
            .selectField('CronTrigger.NextFireTime')
            .selectField('CronTrigger.OwnerId')
            .selectField('CronTrigger.CronJobDetail.Name')
            .selectField('CronTrigger.OwnerId')
            .setCondition('JobType = \'ScheduledApex\' AND Status NOT IN :finishedReasons AND ApexClass.Name IN :classNames')
            .toSOQL();
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

    public Id getParentIdForAsyncId(Id asyncJobId) {
        String query = newQueryFactory()
            .selectField('ParentJobId')
            .setCondition('Id = :asyncJobId')
            .toSOQL();

            AsyncApexJob job = (AsyncApexJob) Database.query(query)[0];
            system.debug('job.ParentJobId: '+job.ParentJobId);
            return job.ParentJobId;
    }

    /**
     * Returns a map of AsyncApexJob.Id -> ApexClassId for the provided job Ids.
     */
    public Map<Id, Id> getClassIdsByJobIds(Set<Id> jobIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (jobIds == null || jobIds.isEmpty()) {
            return result;
        }
        String query = newQueryFactory()
            .selectField(AsyncApexJob.Id)
            .selectField('ApexClassId')
            .setCondition('Id IN :jobIds')
            .toSOQL();
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);
        for (AsyncApexJob j : jobs) {
            if (j.ApexClassId != null) {
                result.put(j.Id, j.ApexClassId);
            }
        }
        return result;
    }

    /**
     * Returns a map of AsyncApexJob.Id -> ParentJobId for the provided job Ids.
     */
    public Map<Id, Id> getParentIdsByJobIds(Set<Id> jobIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (jobIds == null || jobIds.isEmpty()) {
            return result;
        }
        String query = newQueryFactory()
            .selectField(AsyncApexJob.Id)
            .selectField('ParentJobId')
            .setCondition('Id IN :jobIds')
            .toSOQL();
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);
        for (AsyncApexJob j : jobs) {
            result.put(j.Id, j.ParentJobId);
        }
        return result;
    }

}
