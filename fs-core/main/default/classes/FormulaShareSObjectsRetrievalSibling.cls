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

public inherited sharing class FormulaShareSObjectsRetrievalSibling {

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
                // It doesn't matter which rule we create with since all with this key have the same paths to controlling & shared objects
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
//            siblingsMap.put(key, sod);
        }

        // Construct and return map of records associated to rules for each shared record
        Map<Id,Map<String,List<SObject>>> returnMap = getSiblingRecordsForRuleForSharedRecord(siblingsMap);

        return returnMap;
    }


    private List<SObject> retrieveSiblings(SiblingObjectDetails sod, List<SObject> sharedRecords) {

        // Get set of top object ids from shared object query
        Set<Id> topObjIds = new Set<Id>();
        for(SObject record : sharedRecords) {

            Id topId = sod.rule.getTopObjectIdFromSharedRecord(record);

            if(topId != null) {
                topObjIds.add(topId);
            }
        }

        // If no ids populated for top objects (i.e. empty lookups), no need to query
        if(topObjIds.isEmpty()) {
            return new List<SObject>();
        }

        // Create selector for the sibling object
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(sod.rule.controllingObjectApiName);
        FormulaShareSObjectsSelector selector = new FormulaShareSObjectsSelector(true, type);

        // Add fields from sibling
        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(sod.rule.controllingObjectApiName);
        for(String fieldName : sod.fieldApiNames) {
            System.debug('Looking for: '+fieldName);
            selector.addFieldString(fieldName);
        }

        // Select filters on top object ids
        List<SObject> siblingRecords = selector.selectPopulatedRecordsBasedOnParentPath(sod.rule.pathFromControllingObjToTopObj, topObjIds);
        System.debug('siblings from selector: '+siblingRecords);
        return siblingRecords;
    }
        

    private Map<Id,Map<String,List<SObject>>> getSiblingRecordsForRuleForSharedRecord(Map<String,SiblingObjectDetails> siblingsMap) {
        Map<Id,Map<String,List<SObject>>> siblingRecordsForRuleForSharedRecord = new Map<Id,Map<String,List<SObject>>>();

        Map<String,Map<Id,List<SObject>>> recordsForTopObjIdsForSiblingsMap = getRecordsForTopObjIdsForSiblingsMap(siblingsMap);
        for(SObject record : sharedRecords) {
            System.debug('Shared record: '+record);
            
            Map<String,List<SObject>> siblingRecordsForRulesMap = new Map<String,List<SObject>>();

            for(FormulaShareRuleSibling rule : siblingRules) {

                Id topObjId = rule.getTopObjectIdFromSharedRecord(record);
                
                if(topObjId != null) {
        
                    // Get records map for relevant sibling relationship
                    String key = rule.controllingObjectApiName + rule.pathFromSharedObjToTopObj + rule.pathFromControllingObjToTopObj;
                    Map<Id,List<SObject>> recordsForTopObjIdsMap = recordsForTopObjIdsForSiblingsMap.get(key);

                    // Get records for this top object and add to inner list to return
                    List<SObject> sibilngRecords = recordsForTopObjIdsMap.containsKey(topObjId) ? recordsForTopObjIdsMap.get(topObjId) : new List<SObject>();

                    siblingRecordsForRulesMap.put(rule.developerName, sibilngRecords);
                }
            }

            siblingRecordsForRuleForSharedRecord.put(record.Id, siblingRecordsForRulesMap);
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

                Id topId = sod.rule.getTopObjectIdFromSiblingRecord(record);

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


    private class SiblingObjectDetails {

        SiblingObjectDetails(FormulaShareRuleSibling rule) {
            this.rule = rule;
        }
 
        FormulaShareRuleSibling rule;
        Set<String> fieldApiNames = new Set<String>();
        List<SObject> siblingRecords;
    }

}