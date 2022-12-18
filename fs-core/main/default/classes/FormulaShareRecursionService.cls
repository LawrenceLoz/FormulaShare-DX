/**
*Copyright 2022 Lawrence Newcombe
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

public virtual inherited sharing class FormulaShareRecursionService {

    private FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
	private static Set<Id> processedIds = new Set<Id>();

    public class RecordsToProcess {
        public RecordsToProcess(Map<Id,SObject> oldMap, Map<Id,SObject> newMap) {
            this.oldMap = oldMap;
            this.newMap = newMap;
        }

        public Map<Id,SObject> oldMap;
        public Map<Id,SObject> newMap;
    }


    public virtual RecordsToProcess getRecordsToProcess(Schema.SObjectType type, Map<Id,SObject> oldRecordsMap, Map<Id,SObject> newRecordsMap) {

        // If recursion allowed don't bother maintaining processed list for performance
        if(this.settings.Allow_Recursive_Reassessment__c) {
            return new RecordsToProcess(oldRecordsMap, newRecordsMap);
        }

        // Otherwise remove any records previously processed
        else {
            Map<Id,SObject> oldStripped = stripProcessed(oldRecordsMap);
            Map<Id,SObject> newStripped = stripProcessed(newRecordsMap);
            processedIds.addAll(newRecordsMap.keySet());
            return new RecordsToProcess(oldStripped, newStripped);
        }
    }

	// Returns a map with records processed this transaction removed
    private Map<Id,SObject> stripProcessed(Map<Id,SObject> recordsMap) {

        if(recordsMap == null) {
            return null;
        }

        Map<Id,SObject> unprocessedMap;

        // First time only save a loop by returning map as is
        if(processedIds.isEmpty()) {
            unprocessedMap = recordsMap;
        }

        // Otherwise, create a new map with records not yet processed
        else {
            unprocessedMap = new Map<Id,SObject>();
            for(Id thisId : recordsMap.keySet()) {
                if(!processedIds.contains(thisId)) {
                    unprocessedMap.put(thisId, recordsMap.get(thisId));
                }
            }
        }

        return unprocessedMap;
    }

}
