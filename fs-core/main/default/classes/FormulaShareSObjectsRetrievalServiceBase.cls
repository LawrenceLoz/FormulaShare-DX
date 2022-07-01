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
    private List<SObject> rawSharedRecords = new List<SObject>();
    protected List<FormulaShareRetrievedRecordDetails> sharedRecordWithControllingDetails = new List<FormulaShareRetrievedRecordDetails>();
    protected Boolean requery = false;  // Set to true if we should requery records

    public abstract List<FormulaShareRetrievedRecordDetails> getDetailsForSharing();

    public void setDetails(Schema.SObjectType type, List<FormulaShareRule> rules, List<SObject> rawSharedRecords) {
        this.type = type;
        this.rules = rules;
        this.rawSharedRecords = rawSharedRecords;
    }

    // Records are requeried when calling from batch context, or when querying fields on related objects 
    // via lookups and related syntax from shared record might be necessary
    public void setRequery() {
        this.requery = true;
    }

    protected List<SObject> getSharedRecords() {
        System.debug('sharedRecords before requery: ' + rawSharedRecords);

        List<SObject> sharedRecords = new List<SObject>(); // Augmented with related fields if needed

        // If needed, requery shared records to get extra lookups
        if(requery) {

            Set<Id> sharedObjIdSet = new Set<Id> (new Map<Id,SObject>(rawSharedRecords).keySet());
    
            if(sharedObjIdSet != null && !sharedObjIdSet.isEmpty()) {
                FormulaShareSObjectsRetrievalShared sharedService = new FormulaShareSObjectsRetrievalShared();
                sharedRecords = sharedService.retrieveSharedObjects(type, rules, sharedObjIdSet);
            }
        }

        // Otherwise use supplied versions
        else {
            sharedRecords = rawSharedRecords;
        }

        System.debug('sharedRecords after requery: ' + sharedRecords);
        return sharedRecords;
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
