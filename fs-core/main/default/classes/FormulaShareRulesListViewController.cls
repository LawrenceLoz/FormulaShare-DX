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

public with sharing class FormulaShareRulesListViewController {

    static Map<String,FormulaShareRule> rulesMap = new Map<String,FormulaShareRule>();
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectRulesWrapper> getTreeGridData() {

        FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();
        List<FormulaShareRule> rules = rulesSelector.getAllRulesWithSecurityEnforced();

        Map<String, List<RuleWrapper>> objectsWithRulesMap = new Map<String, List<RuleWrapper>>();
        Map<String, String> objectNameToLabelMap = new Map<String,String>();
        List<String> ruleNames = new List<String>();

        for(FormulaShareRule rule : rules){
            ruleNames.add(rule.developerName);
        }

        // Assess when last sharing calculation happened
        FormulaShareRuleInBatchSelector ribSelector = new FormulaShareRuleInBatchSelector(true);
        List<FormulaShareRuleInBatchSelector.RuleRunDetail> runDetails = ribSelector.getRuleRuns(ruleNames);
        Map<String,FormulaShareRuleInBatchSelector.RuleRunDetail> ruleRunDetailMap = new Map<String,FormulaShareRuleInBatchSelector.RuleRunDetail>();

        // Iterate through logs and build map of latest calculations
        for(FormulaShareRuleInBatchSelector.RuleRunDetail runDetail : runDetails) {

            // Consider only if rule was active when batch ran
            if(runDetail.ruleActive) {

                if(ruleRunDetailMap.containsKey(runDetail.developerName)) {
                    FormulaShareRuleInBatchSelector.RuleRunDetail thisDetail = ruleRunDetailMap.get(runDetail.developerName);
                    
                    // If log is later than current latest, replace this (otherwise we'll keep the later log in the map)
                    if(thisDetail.processingStarted < runDetail.processingStarted) {
                        ruleRunDetailMap.put(runDetail.developerName, runDetail);
                    }
                }
                
                // If there wasn't already times in the map, record the details from this log
                else {
                    ruleRunDetailMap.put(runDetail.developerName, runDetail);
                }
            }
        }

        // Build map of all metrics for rules
        List<FormulaShare_Metrics__c> metricsList = FormulaShareMetricsSelector.construct().getAllMetricsForRules(new Set<String>(ruleNames));
        Map<String,FormulaShare_Metrics__c> metricsMap = new Map<String,FormulaShare_Metrics__c>();
        for(FormulaShare_Metrics__c metrics : metricsList) {
            metricsMap.put(metrics.FormulaShare_Rule_Name__c + metrics.Context__c, metrics);
        }

        // Determine whether activation should be disabled for any rule types
		FormulaShareRulesSelector fsRulesSelector = new FormulaShareInjectionService().getRulesSelector();
        Boolean stdActivationDisabled = fsRulesSelector.isStandardActivationDisabled();
        Boolean crossObjActivationDisabled = fsRulesSelector.isCrossObjectActivationDisabled();

        for(FormulaShareRule rule : rules) {
            rulesMap.put(rule.developerName, rule);
            
            List<RuleWrapper> rwList;

            String objectName = rule.objectSharedAPIName;

            if(objectsWithRulesMap.containsKey(objectName)) {
                rwList = objectsWithRulesMap.get(objectName);
            }
            else {
                rwList = new List<RuleWrapper>();
            }

            RuleWrapper rw = new RuleWrapper();
            rw.ruleId = rule.ruleId;
            rw.developerName = rule.developerName;
            rw.key = 'rule|' + rule.developerName;
            rw.tableLabel = rule.label;
            rw.label = rule.label;
            rw.objectLabel = rule.objectSharedLabel;
            rw.controllingObject = rule.controllingObjectLabel;
            rw.shareWith = rule.shareWith;
            rw.sharingReason = rule.sharingReason;
            rw.accessLevel = rule.accessLevel;
            rw.type = rule.type;
            rw.active = rule.active;
            rw.sharedObjectClass = 'slds-tree__item';

            if(rule.type == 'standard') {
                rw.enableActivate = stdActivationDisabled;
            }
            else {
                rw.enableActivate = crossObjActivationDisabled;
            }

            rw.setMetricsDetails(objectName, metricsMap);
            
            // Show warning if rule isn't valid

            if(!rule.isValid()) {
                System.debug('Invalid rule: '+rule.developerName);
                rw.warningUrlLabel = 'Rule not valid';
                rw.warningTooltip = 'One or more fields on this rule are not set correctly. Edit this rule and complete all required fields';
                rw.warningIcon = 'utility:warning';
            }

            // Set URL for shared to field if populated
//            System.debug('this field detail. Label: '+rule.controllingObjectSharedToFieldLabel+' | token: '+rule.controllingObjectSharedToFieldToken);
            if(!String.isBlank(rule.controllingObjectSharedToFieldToken) && rule.controllingObjectSharedToFieldToken.contains('.')) {
                
                // Build URL to field from token (includes object and field id, separated by full stop)
                Integer sharedToPoint = rule.controllingObjectSharedToFieldToken.indexOf('.');
                String objectId = rule.controllingObjectSharedToFieldToken.left(sharedToPoint);
                String fieldId = rule.controllingObjectSharedToFieldToken.mid(sharedToPoint + 1, 15);
                rw.sharedToLink = FormulaShareLWCUtilities.getLightningDomain() 
                    + '/lightning/setup/ObjectManager/' 
                    + objectId
                    + '/FieldsAndRelationships/' 
                    + fieldId 
                    + '/view';
                rw.sharedToLinkLabel = rule.controllingObjectSharedToFieldLabel;
            }

            // Set calculation status depending on most recent logs
            if(!ruleRunDetailMap.containsKey(rw.developerName)) {
                rw.lastCalcStatus = 'Pending';
                rw.iconName = 'standard:today';
                rw.iconAlt = 'Pending';
        }

            else {
                FormulaShareRuleInBatchSelector.RuleRunDetail runDetail = ruleRunDetailMap.get(rw.developerName);
                if(runDetail.batchFinishComplete) {
                    rw.lastCalcStatus = runDetail.processingFinished.format();
                }

                // If currently processing, indicate this against the field
                else {
                    rw.lastCalcStatus = 'Processing...';
                    rw.iconName = 'standard:product_transfer';
                    rw.iconAlt = 'Currently Processing';
                }
            }

            rwList.add(rw);
            objectsWithRulesMap.put(objectName, rwList);
    
            if(!objectNameToLabelMap.containsKey(objectName)) {
                objectNameToLabelMap.put(objectName, rule.objectSharedLabel);
            }
        }

        // Construct list of object wrappers with rules to return
        List<ObjectRulesWrapper> orwList = new List<ObjectRulesWrapper>();
        for(String objectName : objectsWithRulesMap.keySet()) {
            ObjectRulesWrapper orw = new ObjectRulesWrapper();
            List<RuleWrapper> rwList = objectsWithRulesMap.get(objectName);
            rwList.sort();
            for(RuleWrapper rw : rwList) {
                if(rw.lastCalcStatus == 'In Progress') {
                    orw.batchIsProcessing = true;
                    break;
                }
            }

            String objectLabel = objectNameToLabelMap.get(objectName);
            orw.tableLabel = objectLabel + ' (' + rwList.size() + ')';
            orw.key = 'object|'+objectName;
            orw.items = rwList;
            system.debug('rwList'+ rwList);
            orw.objectApiName = objectName;
            orw.sharedObjectClass = 'slds-tree__item slds-text-title_caps';
            orwList.add(orw);
        }

        orwList.sort();
        return orwList;
    }


    @AuraEnabled
    public static void recalculateSharing(String objectApiName) {
        system.debug(objectApiName);

        // Set batch size according to settings
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();

        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(objectApiName);
        List<Schema.SObjectType> typesList = new List<Schema.SObjectType>();
        typesList.add(type);

        // Submit batch
        Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(typesList, batchSize), batchSize);
    }

    
    public class ObjectRulesWrapper implements Comparable {
        @AuraEnabled
        public String key {get;set;}
        @AuraEnabled
        public String tableLabel {get;set;}
        @AuraEnabled
        public Boolean isParentRow = true;
        @AuraEnabled
        public String objectApiName {get;set;}
        @AuraEnabled
        public Boolean batchIsProcessing {get;set;}
        @AuraEnabled
        public List<RuleWrapper> items {get;set;}
        @AuraEnabled
        public String sharedObjectClass {get;set;}

		// Comparable interface allows us to call sort
        public Integer compareTo(Object compareTo) {
			ObjectRulesWrapper compareToWrapper = (ObjectRulesWrapper) compareTo;
			
			// Sort on table labels (object labels)
            if (tableLabel < compareToWrapper.tableLabel) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }

    public class RuleWrapper implements Comparable {
        @AuraEnabled
        public String key {get;set;}
        @AuraEnabled
        public String tableLabel {get;set;}
        @AuraEnabled
        public Id ruleId {get;set;}
        @AuraEnabled
        public String developerName {get;set;}
        @AuraEnabled
        public Boolean isParentRow = false;
        @AuraEnabled
        public String controllingObject {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String objectLabel {get;set;}
        @AuraEnabled
        public String shareWith {get;set;}
        @AuraEnabled
        public String sharedToLink {get;set;}
        @AuraEnabled
        public String sharedToLinkLabel {get;set;}
        @AuraEnabled
        public String sharingReason {get;set;}
        @AuraEnabled
        public String accessLevel {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public Boolean enableActivate {get;set;}
        @AuraEnabled
        public Boolean active {get;set;}
        @AuraEnabled
        public String lastCalcStatus {get;set;}
        @AuraEnabled
        public String sharedObjectClass {get;set;}
        @AuraEnabled
        public String iconName {get;set;}
        @AuraEnabled
        public String iconAlt {get;set;}
        @AuraEnabled
        public Decimal noSharesApplied {get;set;}
        @AuraEnabled
        public String warningIcon {get;set;}
        @AuraEnabled
        public String warningUrl {get;set;}
        @AuraEnabled
        public String warningUrlLabel {get;set;}
        @AuraEnabled
        public String warningTooltip {get;set;}

        // Ids and parameters for filtered record report URL (built in navigation mixin)
        @AuraEnabled
        public Id recordLogsReportId {get;set;}
        @AuraEnabled
        public Id lastBatchId {get;set;}
        @AuraEnabled
        public Long batchFinishEpoch {get;set;}

        private final String warningTriangle = 'utility:warning';
        
		// Comparable interface allows us to call sort
        public Integer compareTo(Object compareTo) {
			RuleWrapper compareToWrapper = (RuleWrapper) compareTo;
			
			// Sort on table labels (rule labels)
            if (tableLabel < compareToWrapper.tableLabel) {
                return -1;
            }
            else {
                return 1;
            }
        }


        // Assess what to show in this line's records shared numbers and any warnings based on latest metrics
        private void setMetricsDetails(String objectApiName, Map<String,FormulaShare_Metrics__c> metricsMap) {
            FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();

            // Separate metrics for contexts
            String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
            String targetedJobContext = FormulaShareProcessedShareEventService.targetedJobContext;
            String batchContext = FormulaShareProcessedShareEventService.batchContext;
            String batchFinishContext = FormulaShareProcessedShareEventService.batchFinishContext;
            FormulaShare_Metrics__c triggerMetrics = metricsMap.get(developerName + triggerContext);
            FormulaShare_Metrics__c targetedJobMetrics = metricsMap.get(developerName + targetedJobContext);
            FormulaShare_Metrics__c batchMetrics = metricsMap.get(developerName + batchContext);
            FormulaShare_Metrics__c batchFinishMetrics = metricsMap.get(developerName + batchFinishContext);

            Integer noSharesFailed = 0;
            Boolean recordFailure = false;
            Boolean batchFailure = false;

            // Set report url to report returning all records (overwritten if batch has run)
            FormulaShareReportsService reportsService = FormulaShareReportsService.construct();
            recordLogsReportId = reportsService.getReportIdForName(settings.All_Record_Logs_Report_Name__c);

            // If complete batch metrics are available, use these together with more recent trigger and targeted job metrics
            if(batchFinishMetrics != null) {

                noSharesApplied = batchFinishMetrics.Successful_Inserts__c;
                noSharesFailed = (Integer) batchFinishMetrics.Failed_Inserts__c;
                lastBatchId = batchFinishMetrics.Last_Batch_Run__c;

                // Add contributions from trigger metrics if captured after last batch
                if(triggerMetrics != null && triggerMetrics.Last_Batch_Run__c == lastBatchId) {
                    noSharesApplied += triggerMetrics.Successful_Inserts__c;
                    noSharesFailed += (Integer) triggerMetrics.Failed_Inserts__c;
                }

                // ... and from targeted job metrics if captured after last batch
                if(targetedJobMetrics != null && targetedJobMetrics.Last_Batch_Run__c == lastBatchId) {
                    noSharesApplied += targetedJobMetrics.Successful_Inserts__c;
                    noSharesFailed += (Integer) targetedJobMetrics.Failed_Inserts__c;
                }

                // Indicate batch failure if last finshed batches failed...
                if(batchFinishMetrics.Last_Failed_Batch__c != null) {
                    batchFailure = true;
                }

                // ... Or if currently running batch failed
                else if(batchMetrics != null && batchMetrics.Last_Batch_Run__c != lastBatchId
                    && batchMetrics.Last_Failed_Batch__c != null) {
                    batchFailure = true;
                }

                // Set record log report urls and parameters for action
                recordLogsReportId = reportsService.getReportIdForName(settings.Record_Logs_Since_Last_Batch_Report_Name__c);

                // Convert batch finish datetime to epoch for use in report url parameters
                if(batchFinishMetrics.Last_Successful_Batch__c != null) {
                    DateTime batchFinishDateTime = batchFinishMetrics.Last_Successful_Batch__c;
                    Long millisecs = batchFinishDateTime.getTime();
                    batchFinishEpoch = millisecs / 1000;
                }
            }

            else if(triggerMetrics != null || targetedJobMetrics != null || batchMetrics != null) {
                noSharesApplied = 0;

                // Set number of shares from trigger metrics
                if(triggerMetrics != null) {
                    noSharesApplied += triggerMetrics.Successful_Inserts__c;
                    noSharesFailed += (Integer) triggerMetrics.Failed_Inserts__c;
                }

                // Set number of shares from trigger metrics
                if(targetedJobMetrics != null) {
                    noSharesApplied += targetedJobMetrics.Successful_Inserts__c;
                    noSharesFailed += (Integer) targetedJobMetrics.Failed_Inserts__c;
                }

                // Add details from batch metrics
                if(batchMetrics != null) {
                    noSharesApplied += batchMetrics.Successful_Inserts__c;
                    noSharesFailed += (Integer) batchMetrics.Failed_Inserts__c;
                    if(batchMetrics.Last_Failed_Batch__c != null) {
                        batchFailure = true;
                    }
                }
            }

            if(noSharesFailed > 0) {
                recordFailure = true;
            }

            // If job isn't scheduled, set icon and link
            warningUrlLabel = '';
            if(!FormulaShareAsyncApexJobSelector.isFullBatchScheduled()) {
                warningIcon = warningTriangle;
                warningUrlLabel = 'Schedule batch job';
                warningTooltip = 'The batch job must be scheduled for rules to apply correctly. Click for more details';
                String domainName = FormulaShareLWCUtilities.getLightningDomain();
                String apexClassesSetup = domainName + '/lightning/setup/ApexClasses/home';
                warningUrl = apexClassesSetup;
            }

            // If either trigger or batch failure, provide link to filtered report
            else if(recordFailure || batchFailure) {

                // Set text depending on what's failed

                // ..Batch error report if any batch failures
                if(batchFailure) {
                    warningUrlLabel = 'Batch errors';
                    warningTooltip = 'View batch error logs';
                    warningUrl = reportsService.getBatchErrorReportUrl(objectApiName);
                }
                else if(recordFailure) {
                    warningUrlLabel = noSharesFailed + ' record errors';
                    warningTooltip = 'View record error logs';
                    String ruleName = this.developerName;
                    
                    // ..Record errors since last batch if batch run completed before
                    if(lastBatchId != null && batchFinishEpoch != null) {
                        warningTooltip += ' since last batch';
                        warningUrl = reportsService.getRecordErrorsSinceLastBatchReportUrl(ruleName, lastBatchId, batchFinishEpoch);
                    }
                    // ..All record errors if no completed batch
                    else {
                        warningUrl = reportsService.getRecordErrorsAllReportUrl(ruleName);
                    }
                }

                // Set warning icon, messages and url
                warningIcon = warningTriangle;
            }
        }
    
    }
}