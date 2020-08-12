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

        List<FormulaShareRule> rules = FormulaShareRulesSelector.construct().getAllRules();

        Map<String, List<RuleWrapper>> objectsWithRulesMap = new Map<String, List<RuleWrapper>>();
        Map<String, String> objectNameToLabelMap = new Map<String,String>();
        List<String> ruleNames = new List<String>();

        for(FormulaShareRule rule : rules){
            ruleNames.add(rule.developerName);
        }

        // Assess when last sharing calculation happened
        FormulaShareRuleInBatchSelector ribSelector = new FormulaShareRuleInBatchSelector(true);
        List<FormulaShareRuleInBatchSelector.RuleRunDetail> runDetails = ribSelector.getLogsForRule(ruleNames);
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

        for(FormulaShareRule rule : rules) {
            rulesMap.put(rule.developerName, rule);
            
            List<RuleWrapper> rwList;
            system.debug('Shared_To__c: '+rule.sharedToFieldToken);

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
            rw.key = rule.developerName;
            rw.tableLabel = rule.label;
            rw.label = rule.label;
            rw.objectLabel = rule.objectSharedLabel;
            rw.controllingObject = rule.controllingObjectLabelForRuleType;
            rw.shareWith = rule.shareWith;
            rw.sharingReason = rule.sharingReason;
            rw.accessLevel = rule.accessLevel;
            rw.active = rule.active;
            rw.sharedObjectClass = 'slds-tree__item';

            rw.setSharingAttributes(metricsMap);

            // Set URL for shared to field if populated
            if(!String.isBlank(rule.sharedToTokenForRuleType) && rule.sharedToTokenForRuleType.contains('.')) {
                
                // Build URL to field from token (includes object and field id, separated by full stop)
                Integer sharedToPoint = rule.sharedToTokenForRuleType.indexOf('.');
                String objectId = rule.sharedToTokenForRuleType.left(sharedToPoint);
                String fieldId = rule.sharedToTokenForRuleType.mid(sharedToPoint + 1, 15);
                rw.sharedToLink = FormulaShareUtilities.getLightningDomain() 
                    + '/lightning/setup/ObjectManager/' 
                    + objectId
                    + '/FieldsAndRelationships/' 
                    + fieldId 
                    + '/view';
                rw.sharedToLinkLabel = rule.sharedToLabelRuleType;
            }

            // Set calculation status depending on most recent logs
            if(!ruleRunDetailMap.containsKey(rw.developerName)) {
                rw.lastCalcStatus = 'None';
            }

            else {
                FormulaShareRuleInBatchSelector.RuleRunDetail runDetail = ruleRunDetailMap.get(rw.developerName);
                if(runDetail.batchFinishComplete) {
                    rw.lastCalcStatus = runDetail.processingFinished.format();
                }

                // If currently processing, indicate this against the field
                else {
                    rw.lastCalcStatus = 'Processing...';
                    rw.iconName = 'standard:today';
                    rw.iconAlt = 'Currently Processing';
                }
            }

            rwList.add(rw);
            objectsWithRulesMap.put(objectName, rwList);
    
            if(!objectNameToLabelMap.containsKey(objectName)) {
                objectNameToLabelMap.put(objectName, rule.objectSharedLabel);
            }
        }

        List<ObjectRulesWrapper> orwList = new List<ObjectRulesWrapper>();
        for(String objectName : objectsWithRulesMap.keySet()) {
            ObjectRulesWrapper orw = new ObjectRulesWrapper();
            List<RuleWrapper> rwList = objectsWithRulesMap.get(objectName);
            for(RuleWrapper rw : rwList) {
                if(rw.lastCalcStatus == 'In Progress') {
                    orw.batchIsProcessing = true;
                    break;
                }
            }
            String objectLabel = objectNameToLabelMap.get(objectName);
            orw.tableLabel = objectLabel + ' (' + rwList.size() + ')';
            orw.key = objectLabel;
            orw.items = rwList;
            system.debug('rwList'+ rwList);
            orw.objectApiName = objectName;
//            orw.isParentRow = true;
            orw.sharedObjectClass = 'slds-tree__item slds-text-title_caps';
            orwList.add(orw);
        }

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


    @AuraEnabled
    public static void activateDeactivate(String ruleName, String type) {

        Map<String,FormulaShare_Rule__mdt> fsRulesMap = new Map<String,FormulaShare_Rule__mdt>();
        
        FormulaShare_Rule__mdt rule = new FormulaShare_Rule__mdt();
        rule.Active__c = type == 'activate' ? true : false;
        fsRulesMap.put(ruleName, rule);

        Id asyncJobId = FormulaShareRulesMetadataDMLService.construct().submitForDml(fsRulesMap, type);
        system.debug('Metadata deployment job ID : '+asyncJobId);
    }


    // Query and cache whether the job is scheduled
    static Boolean jobScheduled;
    private static Boolean jobScheduled() {
        if(jobScheduled == null) {
            List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob 
            WHERE Status!='Aborted' AND Status!='Completed' AND Status!='Failed'
            AND ApexClass.Name = 'FormulaShareProcessSchedulable'];
            jobScheduled = !jobs.isEmpty();
        }

        return jobScheduled;
    }

    
    public class ObjectRulesWrapper {
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
    }

    public class RuleWrapper {
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
        public String batchShareIcon {get;set;}
        @AuraEnabled
        public String batchShareText {get;set;}
        @AuraEnabled
        public String batchShareUrl {get;set;}
        @AuraEnabled
        public String batchShareUrlLabel {get;set;}
        @AuraEnabled
        public String triggerShareIcon {get;set;}
        @AuraEnabled
        public String triggerShareText {get;set;}
        @AuraEnabled
        public String triggerShareUrl {get;set;}
        @AuraEnabled
        public String triggerShareUrlLabel {get;set;}

        private final String successIcon = 'standard:task2';
        private final String pendingIcon = 'standard:today';   // custom:custom25
        private final String warningIcon = 'utility:warning';
        private final String noSharesIcon = 'utility:success';
        
        public void setSharingAttributes(Map<String,FormulaShare_Metrics__c> metricsMap) {
            String triggerContext = FormulaShareProcessedShareEventService.triggerContext;
            String batchContext = FormulaShareProcessedShareEventService.batchContext;
            FormulaShare_Metrics__c triggerMetrics = metricsMap.get(developerName + triggerContext);
            FormulaShare_Metrics__c batchMetrics = metricsMap.get(developerName + batchContext);

            batchShareIcon = getIcon(batchMetrics);
            batchShareText = getText(batchMetrics);
            batchShareUrl = getUrl(batchMetrics);
            batchShareUrlLabel = getUrlLabel(batchMetrics);
            triggerShareIcon = getIcon(triggerMetrics);
            triggerShareText = getText(triggerMetrics);
            triggerShareUrl = getUrl(triggerMetrics);
            triggerShareUrlLabel = getUrlLabel(triggerMetrics);

            // If job isn't scheduled, set icon and link
            if(!jobScheduled()) {
                batchShareIcon = warningIcon;
                batchShareText = '';
                batchShareUrlLabel = 'Schedule job';

                String domainName = FormulaShareUtilities.getLightningDomain();
                String apexClassesSetup = domainName + '/lightning/setup/ApexClasses/home';
                batchShareUrl = apexClassesSetup;
            }

            // Set batch to pending if not run yet
            else if(batchMetrics == null) {
                batchShareIcon = pendingIcon;
                batchShareText = 'Pending';
            }
        }

        private String getIcon(FormulaShare_Metrics__c metrics) {
            switch on metricsStatus(metrics) {
                when 'No metrics' {
                    return null;
                }
                when 'No shares yet' {
                    return noSharesIcon;
                }
                when 'Last operation failed' {
                    return warningIcon;
                }
                when else {
                    return successIcon;
                }
            }
        }

        private String getText(FormulaShare_Metrics__c metrics) {
            switch on metricsStatus(metrics) {
                when 'No metrics', 'Last operation failed' {
                    return null;
                }
                when else {
                    String text = String.valueOf(metrics.Successful_Inserts__c);
                    return text;
                }
            }
        }

        private String getUrl(FormulaShare_Metrics__c metrics) {
            switch on metricsStatus(metrics) {
                when 'Last operation failed' {
                    return 'url for monitor tab';
                }
                when else {
                    return null;
                }
            }
        }

        private String getUrlLabel(FormulaShare_Metrics__c metrics) {
            switch on metricsStatus(metrics) {
                when 'Last operation failed' {
                    return 'Check errors';
                }
                when else {
                    return null;
                }
            }
        }

        private String metricsStatus(FormulaShare_Metrics__c metrics) {
            if(metrics == null) {
                return 'No metrics';
            }
            else if(
                metrics.Last_Failed_Operation__c != null 
                && (metrics.Last_Successful_Operation__c == null
                    || metrics.Last_Failed_Operation__c > metrics.Last_Successful_Operation__c)
            ) {
                return 'Last operation failed';
            }
            else if(metrics.Successful_Inserts__c == 0) {
                return 'No shares yet';
            }
            else {
                return 'Success';
            }
        }
    }
}
