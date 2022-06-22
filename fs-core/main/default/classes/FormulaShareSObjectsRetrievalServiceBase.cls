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

public abstract inherited sharing class FormulaShareSObjectsRetrievalServiceBase {

    protected Schema.SObjectType type;
    protected List<FormulaShareRule> rules;
    protected List<SObject> sharedRecords = new List<SObject>();
    protected List<FormulaShareRetrievedRecordDetails> sharedRecordWithControllingDetails = new List<FormulaShareRetrievedRecordDetails>();
    private Boolean requery = false;  // Set to true if we should requery records

    public abstract List<FormulaShareRetrievedRecordDetails> getDetailsForSharing();

    public void setDetails(Schema.SObjectType type, List<FormulaShareRule> rules, List<SObject> sharedRecords) {
        this.type = type;
        this.rules = rules;
        this.sharedRecords = sharedRecords;
    }

    public void setRequery() {
        this.requery = true;
    }

    // Records are requeried when calling from batch context, or when querying fields on related objects 
    // via lookups and related syntax from shared record might be necessary
    protected void requeryIfNeeded() {

        if(requery) {

            // Build id set so we can re-query for lookup fields
            Set<Id> sharedObjIdSet = new Set<Id> (new Map<Id,SObject>(sharedRecords).keySet());
    
            // Query for shared object records and establish map
            if(sharedObjIdSet != null && !sharedObjIdSet.isEmpty()) {
                sharedRecords.clear();
                FormulaShareSObjectsRetrievalShared sharedService = new FormulaShareSObjectsRetrievalShared();
                System.debug('Selector type: '+type.getDescribe().getName());
                List<SObject> queriedRecords = sharedService.retrieveSharedObjects(type, rules, sharedObjIdSet);
                sharedRecords.addAll(queriedRecords);
            }
        }
    }

    // Add details of all shared records into map (to be augmented with controlling object details)
    protected void setRecordsAndControllingDetailsMap(List<SObject> sharedRecords) {
        for(SObject record : sharedRecords) {
            FormulaShareRetrievedRecordDetails srwcr = new FormulaShareRetrievedRecordDetails();
            srwcr.sharedRecord = record;
            sharedRecordWithControllingDetails.add(srwcr);
        }
    }

}
