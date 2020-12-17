public inherited sharing class FormulaShareSObjectsRetrievalBottomObj {

    List<FormulaShareRuleBottomObject> bottomObjectRules = new List<FormulaShareRuleBottomObject>();
    List<SObject> sharedRecords;

    public FormulaShareSObjectsRetrievalBottomObj(List<FormulaShareRuleBottomObject> bottomObjectRules, List<SObject> sharedRecords) {
        this.bottomObjectRules = bottomObjectRules;
        this.sharedRecords = sharedRecords;
    }


    public Map<Id,Map<String,List<SObject>>> getControllingRecordsMap() {

        // Populate bottom object map with all unique paths between shared object and bottom objects
        Map<String,BottomObjectDetails> boMap = new Map<String,BottomObjectDetails>();
        for(FormulaShareRuleBottomObject rule : bottomObjectRules) {

            // Key includes queried object, the path from shared object to the 
            // top object, and path from the controlling object to the top object
            String key = rule.bottomObjectApiName + rule.pathFromBottomObjToSharedObj;

            // Add field name for this rule to bottom object map (and create bod if needed)
            BottomObjectDetails bod;
            if(boMap.containsKey(key)) {
                bod = boMap.get(key);
            }
            else {
                // It doesn't matter which rule we create with since all with this key have the same paths to controlling & shared objects
                bod = new BottomObjectDetails(rule);
            }

            // Add path to shared field
            System.debug('Processing rule: '+bod.rule.DeveloperName+' | Adding field: '+rule.pathFromBottomObjToSharedObj);
            bod.fieldsToQuery.add(rule.pathFromBottomObjToSharedObj);

            // Add controlling field from bottom object or inlaw object (TODO - add this to inlaw check)
            System.debug('Processing rule: '+bod.rule.DeveloperName+' | Adding field: '+rule.pathToSharedToField);
            bod.fieldsToQuery.add(rule.pathToSharedToField);

            boMap.put(key, bod);
        }

        // Query and populate bottom object records
        for(String key : boMap.keySet()) {
            BottomObjectDetails bod = boMap.get(key);
            List<SObject> records = retrieveBottomObjects(bod, sharedRecords);
            bod.bottomRecords = records;
        }

        // Construct and return map of records associated to rules for each shared record
        Map<Id,Map<String,List<SObject>>> returnMap = getControllingRecordsForRuleForSharedRecord(boMap);

        return returnMap;
    }


    private List<SObject> retrieveBottomObjects(BottomObjectDetails bod, List<SObject> sharedRecords) {

        // Get set of shared object ids from shared object query
        Set<Id> sharedObjIds = new Set<Id>();
        for(SObject record : sharedRecords) {
            sharedObjIds.add(record.Id);
        }

        // Create selector for the bottom object
        System.debug('bod.rule: '+ bod.rule);
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(bod.rule.bottomObjectApiName);
        FormulaShareSObjectsSelector selector = new FormulaShareSObjectsSelector(true, type);

        // Add paths for lookup fields to shared object
        for(String fieldPath : bod.fieldsToQuery) {
            System.debug('Looking for: '+fieldPath);
            selector.addFieldString(fieldPath);
        }

        // Add owner id from shared object
        System.debug('Owner id path: '+bod.rule.pathFromBottomObjToOwnerIdOnSharedObj);
        selector.addFieldString(bod.rule.pathFromBottomObjToOwnerIdOnSharedObj);

        // Select filters on top object ids
        List<SObject> bottomRecords = selector.selectPopulatedRecordsBasedOnParentPath(bod.rule.pathFromBottomObjToSharedObj, sharedObjIds);
        return bottomRecords;
    }


    private Map<Id,Map<String,List<SObject>>> getControllingRecordsForRuleForSharedRecord(Map<String,BottomObjectDetails> boMap) {
        Map<Id,Map<String,List<SObject>>> bottomRecordsForRuleForSharedRecord = new Map<Id,Map<String,List<SObject>>>();

        Map<String, Map<Id, List<SObject>>> recordsForSharedObjForBottomsMap = recordsForSharedObjForBottomsMap(boMap);

        for(SObject record : sharedRecords) {
            System.debug('Shared record: '+record);
            System.debug('Shared recordId: '+record.Id);
            
            Map<String,List<SObject>> bottomRecordsForRulesMap = new Map<String,List<SObject>>();

            for(FormulaShareRuleBottomObject rule : bottomObjectRules) {

                //(Id) record.get(rule.pathFromBottomObjToSharedObj);
        
                // Get records map for relevant bottom object relationship
                String key = rule.bottomObjectApiName + rule.pathFromBottomObjToSharedObj;
                Map<Id,List<SObject>> bottomRecordsForSharedObjMap = recordsForSharedObjForBottomsMap.get(key);

                // Get records for this top object and add to inner list to return
                List<SObject> bottomRecords = bottomRecordsForSharedObjMap.containsKey(record.Id) ? bottomRecordsForSharedObjMap.get(record.Id) : new List<SObject>();

                bottomRecordsForRulesMap.put(rule.developerName, bottomRecords);
            }
            System.debug('Shared recordId: '+record.Id);
            System.debug('records for rules: '+bottomRecordsForRulesMap);
            bottomRecordsForRuleForSharedRecord.put(record.Id, bottomRecordsForRulesMap);
            System.debug('here: ');
        }

        return bottomRecordsForRuleForSharedRecord;        
    }


    private Map<String, Map<Id, List<SObject>>> recordsForSharedObjForBottomsMap(Map<String,BottomObjectDetails> boMap) {

        Map<String,Map<Id,List<SObject>>> returnMap = new Map<String,Map<Id,List<SObject>>>();
        for(String key : boMap.keySet()) {

            // Create or get internal map
            Map<Id,List<SObject>> recordsForSharedObjIdsMap;
            if(returnMap.containsKey(key)) {
                recordsForSharedObjIdsMap = returnMap.get(key);
            }
            else {
                recordsForSharedObjIdsMap = new Map<Id,List<SObject>>();
            }

            // For each record, add it to a list assigned to the relevant shared object id
            BottomObjectDetails bod = boMap.get(key);
            for(SObject record : bod.bottomRecords) {

                Id sharedId = bod.rule.getSharedObjectIdFromBottomRecord(record);

                // Create or get internal records list for this sharedId
                List<SObject> records;
                if(recordsForSharedObjIdsMap.containsKey(sharedId)) {
                    records = recordsForSharedObjIdsMap.get(sharedId);
                }
                else {
                    records = new List<SObject>();
                }
                records.add(record);
                recordsForSharedObjIdsMap.put(sharedId, records);
            }

            returnMap.put(key, recordsForSharedObjIdsMap);
        }

        return returnMap;
    }



    private class BottomObjectDetails {

        BottomObjectDetails(FormulaShareRuleBottomObject rule) {
            this.rule = rule;
        }

        FormulaShareRuleBottomObject rule;
        Set<String> fieldsToQuery = new Set<String>();
        List<SObject> bottomRecords;
    }

}
