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
    public static List<ObjectRulesWrapper> getTreeGridData(){

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

        for(FormulaShareRule rule : rules){
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
                rw.lastCalcStatus = runDetail.batchFinishComplete ? runDetail.processingFinished.format() : 'In Progress';
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
            orw.isParentRow = true;
//            orw.icon = 'utility:success';
            orwList.add(orw);
        }

        return orwList;
    }


    @AuraEnabled
    public static void recalculateSharing(String objectApiName) {
        system.debug(objectApiName);

        // Set batch size according to settings
        FormulaShare_Settings__mdt settings = getFormulaShareSettings();
        Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();

        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(objectApiName);
        List<Schema.SObjectType> typesList = new List<Schema.SObjectType>();
        typesList.add(type);

        // Submit batch
        Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(typesList, batchSize), batchSize);
    }


    @AuraEnabled
    public static void activateDeactivate(String ruleName, String action) {

        FormulaShareRule rule = new FormulaShareRule();
        rule.developerName = ruleName;
        
        switch on action {
            when 'activate' {
                rule.active = true;
            }
            when 'deactivate' {
                rule.active = false;
            }
        }
        
        Map<String,FormulaShareRule> rulesToUpdate = new Map<String,FormulaShareRule>();
        rulesToUpdate.put(rule.developerName, rule);

        Id asyncJobId = FormulaShareRulesMetadataDMLService.updateRules(rulesToUpdate, action);
    }

    static FormulaShare_Settings__mdt settings;
    private static FormulaShare_Settings__mdt getFormulaShareSettings() {

		if(settings == null) {
			settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
		}

		return settings;
    }
    
    
    public class ObjectRulesWrapper {
        @AuraEnabled
        public String key {get;set;}
        @AuraEnabled
        public String tableLabel {get;set;}
        @AuraEnabled
        public Boolean isParentRow {get;set;}
        @AuraEnabled
        public String objectApiName {get;set;}
        @AuraEnabled
        public Boolean batchIsProcessing {get;set;}
        @AuraEnabled
        public List<RuleWrapper> items {get;set;}
        @AuraEnabled
        public String icon {get;set;}
    }
/*
    public class iconInfo {
        @AuraEnabled
        public String icon = 'utility:clock';
    }
*/
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
        public Boolean isParentRow {get;set;}
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
        public List<RuleWrapper> items {get;set;}
    }
}
