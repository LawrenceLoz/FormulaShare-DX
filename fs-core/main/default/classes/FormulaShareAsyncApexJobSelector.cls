public with sharing class FormulaShareAsyncApexJobSelector extends fflib_SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return AsyncApexJob.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> { AsyncApexJob.Id };
    }

    @TestVisible static Boolean isScheduled;
    private void setIsScheduled() {
        List<String> finishedReasons = new List<String> {
            'Aborted', 'Completed', 'Failed'
        };
        String query = newQueryFactory()
            .setCondition('Status NOT IN :finishedReasons AND ApexClass.Name = \'FormulaShareProcessSchedulable\'')
            .toSOQL();
        
        List<AsyncApexJob> jobs = (List<AsyncApexJob>) Database.query(query);
        isScheduled = !jobs.isEmpty();
    }

    // Returns true if a job is scheduled for the future or false otherwise
    public static Boolean isScheduled() {
        if(isScheduled == null) {
            FormulaShareAsyncApexJobSelector jobSelector = new FormulaShareAsyncApexJobSelector();
            jobSelector.setIsScheduled();
        }
        return isScheduled;
    }
}
