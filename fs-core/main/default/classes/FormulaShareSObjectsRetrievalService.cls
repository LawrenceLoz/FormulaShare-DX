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

public inherited sharing class FormulaShareSObjectsRetrievalService {
    
    Schema.SObjectType type;
    List<FormulaShareRule> rules;
    Set<Id> sharedObjIdSet;
    List<SObject> sharedRecords = new List<SObject>();
    
    List<FormulaShareRuleSibling> siblingRules = new List<FormulaShareRuleSibling>();
    List<FormulaShareRuleBottomObject> bottomObjRules = new List<FormulaShareRuleBottomObject>();
//    List<FormulaShareRuleDescendant> descendantRules = new List<FormulaShareRuleDescendant>();
//    List<FormulaShareRuleInlaw> inlawRules = new List<FormulaShareRuleInlaw>();

    List<FormulaShareRetrievedRecordDetails> sharedRecordWithControllingDetails = new List<FormulaShareRetrievedRecordDetails>();
    
    public FormulaShareSObjectsRetrievalService(Schema.SObjectType type, List<FormulaShareRule> rules) {
        this.type = type;
        this.rules = rules;
    }

    // Used by batch and when parent lookups need to be populated. Records are re-queried
    public void setRecordIds(Set<Id> sharedObjIdSet) {
        this.sharedObjIdSet = sharedObjIdSet;
    }

    // Used by trigger when there's no need to requery
    public void setRecords(List<SObject> sharedRecords) {
        this.sharedRecords = sharedRecords;
    }

    public List<FormulaShareRetrievedRecordDetails> getDetailsForSharing() {

        // Query for shared object records and establish map
        if(sharedObjIdSet != null && !sharedObjIdSet.isEmpty()) {
            FormulaShareSObjectsRetrievalShared sharedService = new FormulaShareSObjectsRetrievalShared(type, rules, sharedObjIdSet);
            System.debug('Selector type: '+type.getDescribe().getName());
            List<SObject> queriedRecords = sharedService.retrieveSharedObjects();
            sharedRecords.addAll(queriedRecords);
        }

        setRecordsAndControllingDetailsMap(sharedRecords);

        populateRelatedRulesLists();

        // Retrieve sibling and bottom level records involved in sharing and add these to record maps
        if(!siblingRules.isEmpty()) {
            FormulaShareSObjectsRetrievalSibling siblingService = new FormulaShareSObjectsRetrievalSibling(siblingRules, sharedRecords);
            Map<Id,Map<String,List<SObject>>> siblingRecords = siblingService.getControllingRecordsMap();
            addControllingRecordsToMap(siblingRecords);
        }
        if(!bottomObjRules.isEmpty()) {
            FormulaShareSObjectsRetrievalBottomObj bottomObjService = new FormulaShareSObjectsRetrievalBottomObj(bottomObjRules, sharedRecords);
            Map<Id,Map<String,List<SObject>>> bottomObjRecords = bottomObjService.getControllingRecordsMap();
            addControllingRecordsToMap(bottomObjRecords);
        }

        System.debug('All shared record detais: ' + sharedRecordWithControllingDetails);

        return sharedRecordWithControllingDetails;
    }


    private void populateRelatedRulesLists() {
        for(FormulaShareRule rule : rules) {
            switch on rule.type {
                when 'sibling' {
                    siblingRules.add((FormulaShareRuleSibling) rule);
                }
//                when 'descendant', 'inlaw' {
//                    bottomObjRules.add((FormulaShareRuleBottomObject) rule);
//                }
                when 'descendant' {
                    bottomObjRules.add((FormulaShareRuleDescendant) rule);
                }
                when 'inlaw' {
                    bottomObjRules.add((FormulaShareRuleInlaw) rule);
                }
            }
        }
    }


    // Add details of all shared records into map (to be augmented with controlling object details)
    private void setRecordsAndControllingDetailsMap(List<SObject> sharedRecords) {
        for(SObject record : sharedRecords) {
            FormulaShareRetrievedRecordDetails srwcr = new FormulaShareRetrievedRecordDetails();
            srwcr.sharedRecord = record;
            sharedRecordWithControllingDetails.add(srwcr);
        }
    }


    // Augment rule and related object maps for each shared record
    private void addControllingRecordsToMap(Map<Id,Map<String,List<SObject>>> controllingRecordsMap) {
        for(FormulaShareRetrievedRecordDetails srwcr : sharedRecordWithControllingDetails) {
            Map<String,List<SObject>> controllingRecordsForRules = srwcr.controllingRecordsForRulesMap;
            Map<String,List<SObject>> newControllingRecordsForRules = controllingRecordsMap.get(srwcr.sharedRecord.Id);
            if(newControllingRecordsForRules != null) {
                controllingRecordsForRules.putAll(newControllingRecordsForRules);
            }
            srwcr.controllingRecordsForRulesMap = controllingRecordsForRules;
        }
    }

}