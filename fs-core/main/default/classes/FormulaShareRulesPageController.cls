public with sharing class FormulaShareRulesPageController {

    @AuraEnabled(cacheable=true)
    public static Boolean isFullOrTargetedBatchScheduled() {
        return FormulaShareAsyncApexJobSelector.isFullOrTargetedBatchScheduled();
    }
    
}