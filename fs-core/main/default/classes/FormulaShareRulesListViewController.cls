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
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectRulesWrapper> getTreeGridData(){

        List<FormulaShareRule> rules = FormulaShareRulesSelector.construct().getAllRules();

        Map<String, List<RuleWrapper>> objectsWithRulesMap = new Map<String, List<RuleWrapper>>();
        for(FormulaShareRule rule : rules){
            system.debug('Shared_To__c: '+rule.sharedToFieldToken);

            String objectName = rule.objectSharedLabel;
            List<RuleWrapper> rwList;

            if(objectsWithRulesMap.containsKey(objectName)) {
                rwList = objectsWithRulesMap.get(objectName);
            }
            else {
                rwList = new List<RuleWrapper>();
            }

            RuleWrapper rw = new RuleWrapper();
            rw.name = rule.objectSharedLabel;
            rw.controllingObject = rule.controllingObjectLabelForRuleType;
            rw.label = rule.label;
            rw.shareWith = rule.shareWith;
            rw.sharingReason = rule.sharingReason;
            rw.accessLevel = rule.accessLevel;
            rw.active = rule.active;

            // Set URL for shared to field if populated
            if(!String.isBlank(rule.sharedToTokenForRuleType) && rule.sharedToTokenForRuleType.contains('.')) {
                Integer sharedToPoint = rule.sharedToTokenForRuleType.indexOf('.');
                String sharedToSplit = rule.sharedToTokenForRuleType.mid(sharedToPoint + 1, 15);
                rw.sharedToLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sharedToSplit;
                rw.sharedToLinkLabel = rule.sharedToLabelRuleType;
            }

            rwList.add(rw);

            objectsWithRulesMap.put(objectName, rwList);
        }

        List<ObjectRulesWrapper> orwList = new List<ObjectRulesWrapper>();
        for(String objectName : objectsWithRulesMap.keySet()) {
            ObjectRulesWrapper orw = new ObjectRulesWrapper();
            List<RuleWrapper> rwList = objectsWithRulesMap.get(objectName);
            orw.name = objectName + ' (' + rwList.size() + ')';
            orw.items = rwList;
            orwList.add(orw);
        }

        return orwList;
    }

    public Class ObjectRulesWrapper{
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public List<RuleWrapper> items {get;set;}
    }

    public Class RuleWrapper{
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String controllingObject {get;set;}
        @AuraEnabled
        public String label {get;set;}
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
        public List<RuleWrapper> items {get;set;}
    }
}
