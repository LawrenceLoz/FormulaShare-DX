public with sharing class FormulaShareSObjectsRetrievalService {
    
    Schema.SObjectType type;
    List<FormulaShareRule> rules;
    Set<Id> sharedObjIdSet;
    List<SObject> sharedRecords = new List<SObject>();
    
    List<FormulaShareRuleSibling> siblingRules = new List<FormulaShareRuleSibling>();
    List<FormulaShareRuleDescendant> descendantRules = new List<FormulaShareRuleDescendant>();
    List<FormulaShareRuleInlaw> inlawRules = new List<FormulaShareRuleInlaw>();

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

        // Retrieve sibling and bottom level records involved in sharing
        if(!siblingRules.isEmpty()) {
            FormulaShareSObjectsRetrievalSibling siblingService = new FormulaShareSObjectsRetrievalSibling(siblingRules, sharedRecords);
            Map<Id,Map<String,List<SObject>>> siblingRecords = siblingService.getControllingRecordsMap();
            addControllingRecordsToMap(siblingRecords);
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
                when 'descendant' {
                    descendantRules.add((FormulaShareRuleDescendant) rule);
                }
                when 'inlaw' {
                    inlawRules.add((FormulaShareRuleInlaw) rule);
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