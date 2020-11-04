public with sharing class FormulaShareSObjectsRetrievalSibling {

    List<FormulaShareRuleSibling> siblingRules;
    List<SObject> sharedRecords;

    public FormulaShareSObjectsRetrievalSibling(List<FormulaShareRuleSibling> siblingRules, List<SObject> sharedRecords) {
        this.siblingRules = siblingRules;
        this.sharedRecords = sharedRecords;
    }


    public Map<Id,Map<String,List<SObject>>> getControllingRecordsMap() {

        // Populate sibling map with all unique paths between shared object and siblings
        Map<String,SiblingObjectDetails> siblingsMap = new Map<String,SiblingObjectDetails>();
        for(FormulaShareRuleSibling rule : siblingRules) {

            // Key includes queried object, the path from shared object to the 
            // top object, and path from the controlling object to the top object
            String key = rule.controllingObjectApiName + rule.pathFromSharedObjToTopObj + rule.pathFromControllingObjToTopObj;

            // Add field name for this rule to sibling map (and create sod if needed)
            SiblingObjectDetails sod;
            if(siblingsMap.containsKey(key)) {
                sod = siblingsMap.get(key);
            }
            else {
                sod = new SiblingObjectDetails(rule);
            }
            sod.fieldApiNames.add(rule.controllingObjectSharedToFieldAPIName);
            siblingsMap.put(key, sod);
        }

        // Query and populate sibling detail objects with records
        for(String key : siblingsMap.keySet()) {
            SiblingObjectDetails sod = siblingsMap.get(key);
            List<SObject> records = retrieveSiblings(sod, sharedRecords);
            sod.siblingRecords = records;
        }

        // Construct and return map of records associated to rules for each shared record
        Map<Id,Map<String,List<SObject>>> returnMap = getSiblingRecordsForRuleForSharedRecord(siblingsMap);

        return returnMap;
    }


    private Map<Id,Map<String,List<SObject>>> getSiblingRecordsForRuleForSharedRecord(Map<String,SiblingObjectDetails> siblingsMap) {
        Map<Id,Map<String,List<SObject>>> siblingRecordsForRuleForSharedRecord = new Map<Id,Map<String,List<SObject>>>();

        Map<String,Map<Id,List<SObject>>> recordsForTopObjIdsForSiblingsMap = getRecordsForTopObjIdsForSiblingsMap(siblingsMap);
        for(SObject record : sharedRecords) {
            System.debug('Shared record: '+record);
            System.debug('Shared recordId: '+record.Id);
            
            Map<String,List<SObject>> siblingRecordsForRulesMap = new Map<String,List<SObject>>();

            for(FormulaShareRuleSibling rule : siblingRules) {

                Id topObjId = (Id) record.get(rule.pathFromSharedObjToTopObj);
                if(topObjId != null) {
        
                    // Get records map for relevant sibling relationship
                    String key = rule.controllingObjectApiName + rule.pathFromSharedObjToTopObj + rule.pathFromControllingObjToTopObj;
                    Map<Id,List<SObject>> recordsForTopObjIdsMap = recordsForTopObjIdsForSiblingsMap.get(key);

                    // Get records for this top object and add to inner list to return
                    List<SObject> sibilngRecords = recordsForTopObjIdsMap.containsKey(topObjId) ? recordsForTopObjIdsMap.get(topObjId) : new List<SObject>();

                    siblingRecordsForRulesMap.put(rule.developerName, sibilngRecords);
                }
            }
            System.debug('Shared recordId: '+record.Id);
            System.debug('records for rules: '+siblingRecordsForRulesMap);
            siblingRecordsForRuleForSharedRecord.put(record.Id, siblingRecordsForRulesMap);
            System.debug('here: ');
        }

        return siblingRecordsForRuleForSharedRecord;        
    }


    private Map<String,Map<Id,List<SObject>>> getRecordsForTopObjIdsForSiblingsMap(Map<String,SiblingObjectDetails> siblingsMap) {
        Map<String,Map<Id,List<SObject>>> returnMap = new Map<String,Map<Id,List<SObject>>>();
        for(String key : siblingsMap.keySet()) {

            // Create or get internal map
            Map<Id,List<SObject>> recordsForTopObjIdsMap;
            if(returnMap.containsKey(key)) {
                recordsForTopObjIdsMap = returnMap.get(key);
            }
            else {
                recordsForTopObjIdsMap = new Map<Id,List<SObject>>();
            }

            // For each record, add it to a list assigned to the relevant top object id
            SiblingObjectDetails sod = siblingsMap.get(key);
            for(SObject record : sod.siblingRecords) {

                Id topId = (Id) record.get(sod.pathFromControllingObjToTopObj);

                // Create or get internal records list for this topId
                List<SObject> records;
                if(recordsForTopObjIdsMap.containsKey(topId)) {
                    records = recordsForTopObjIdsMap.get(topId);
                }
                else {
                    records = new List<SObject>();
                }
                records.add(record);
                recordsForTopObjIdsMap.put(topId, records);
            }

            returnMap.put(key, recordsForTopObjIdsMap);
        }

        return returnMap;
    }


    private List<SObject> retrieveSiblings(SiblingObjectDetails sod, List<SObject> sharedRecords) {

        // Get set of top object ids from shared object query
        Set<Id> topObjIds = new Set<Id>();
        for(SObject record : sharedRecords) {

            System.debug('path from shared to top: '+ sod.pathFromSharedObjToTopObj);
            System.debug('path from record: '+record.get(sod.pathFromSharedObjToTopObj));

            if(record.get(sod.pathFromSharedObjToTopObj) != null) {
                Id topObjId = (Id) record.get(sod.pathFromSharedObjToTopObj);
                topObjIds.add(topObjId);
            }
        }

        // If no ids populated for top objects (i.e. empty lookups), no need to query
        if(topObjIds.isEmpty()) {
            return new List<SObject>();
        }

        // Create selector for the sibling object
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(sod.controllingObjectApiName);
        FormulaShareSObjectsSelector selector = new FormulaShareSObjectsSelector(true, type);

        // Add fields from sibling
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(sod.controllingObjectApiName);
        for(String fieldName : sod.fieldApiNames) {
            System.debug('Looking for: '+fieldName);
            selector.addFieldString(fieldName);
        }

        // Select filters on top object ids
        List<SObject> siblingRecords = selector.selectPopulatedRecordsBasedOnParentPath(sod.pathFromControllingObjToTopObj, topObjIds);
        return siblingRecords;
    }    


    private class SiblingObjectDetails {

        SiblingObjectDetails(FormulaShareRuleSibling rule) {
            controllingObjectApiName = rule.controllingObjectApiName;
            pathFromSharedObjToTopObj = rule.pathFromSharedObjToTopObj;
            pathFromControllingObjToTopObj = rule.pathFromControllingObjToTopObj;
//            fieldApiNames = new Set<String>({rule.pathFromControllingObjToTopObj});
       }
 
        String controllingObjectApiName;
        String pathFromSharedObjToTopObj;
        String pathFromControllingObjToTopObj;
        Set<String> fieldApiNames = new Set<String>();
        List<SObject> siblingRecords;
    }

}