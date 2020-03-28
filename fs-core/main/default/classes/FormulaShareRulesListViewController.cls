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
        List<FormulaShare_Rule__mdt> rules = [SELECT Id, Object_Shared__c, Shared_To__c, Object_Shared__r.QualifiedAPIName, Object_Shared__r.MasterLabel, Active__c, MasterLabel, 
            Share_With__c, Shared_To__r.QualifiedAPIName, Shared_To__r.MasterLabel, Sharing_Reason__c, Access_Level__c 
            FROM FormulaShare_Rule__mdt];


        Map<String, List<RuleWrapper>> objectsWithRulesMap = new Map<String, List<RuleWrapper>>();
        for(FormulaShare_Rule__mdt rule : rules){
            system.debug('Object_Shared__c: '+rule.Object_Shared__c);
            system.debug('Shared_To__c: '+rule.Shared_To__c);

            String objectName = rule.Object_Shared__r.MasterLabel;
            List<RuleWrapper> rwList;

            if(objectsWithRulesMap.containsKey(objectName)) {
                rwList = objectsWithRulesMap.get(objectName);
            }
            else {
                rwList = new List<RuleWrapper>();
            }

            RuleWrapper rw = new RuleWrapper();
            rw.name = rule.Object_Shared__r.MasterLabel;
            rw.label = rule.MasterLabel;
            rw.shareWith = rule.Share_With__c;
            rw.sharingReason = rule.Sharing_Reason__c;
            rw.accessLevel = rule.Access_Level__c;
            rw.active = rule.Active__c;

            // Set URL for shared to field if populated
            if(!String.isBlank(rule.Shared_To__c) && rule.Shared_To__c.contains('.')) {
                Integer sharedToPoint = rule.Shared_To__c.indexOf('.');
                String sharedToSplit = rule.Shared_To__c.mid(sharedToPoint + 1, 15);
                rw.sharedToLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sharedToSplit;
                rw.sharedToLinkLabel = rule.Shared_To__r.MasterLabel;
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
