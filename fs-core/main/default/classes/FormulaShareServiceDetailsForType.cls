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

public inherited sharing class FormulaShareServiceDetailsForType {

	// Variables are sufficient to call an instance of FormulaShareService for this set of rules
	public Schema.SObjectType sharedType;
	public Boolean removeExistingShares;
	public List<FormulaShareRule> rules = new List<FormulaShareRule>();
	public Map<Id,FormulaShareRetrievedRecordDetails> retrieveRecordDetails = new Map<Id,FormulaShareRetrievedRecordDetails>();

	public FormulaShareServiceDetailsForType(Schema.SObjectType type, Boolean removeExistingShares) {
		this.sharedType = type;
		this.removeExistingShares = removeExistingShares;
	}

	// Sets the shared record in object structure
    // Used when application of sharing depends on a single record (e.g. standard and ancestor rules for triggers ops)
	public void setSharedObjectRetrievedRecord(String sharedObjectApiName, SObject sharedRecord) {

        FormulaShareRetrievedRecordDetails details = getRetrievedRecordDetails(retrieveRecordDetails, sharedRecord.Id);

		// Set the shared record in this details map. Note that this will replace any shared record already
		// set (which could have included id only if set by setRetrievedRecordWithRelatedDetails())
		details.sharedRecord = sharedRecord;

		// Update map with details
		retrieveRecordDetails.put(sharedRecord.Id, details);
	}
    

	// Sets a related record for the shared record in object structure
	// Used when application of sharing depends on a set of related records (e.g. descendant and inlaw rules in trigger op)
	public void setRetrievedRecordWithRelatedDetails(SObject relatedRecord, Id sharedObjectId, Id sharedObjectOwnerId, FormulaShareRule rule) {

		FormulaShareRetrievedRecordDetails details = getRetrievedRecordDetails(retrieveRecordDetails, sharedObjectId);

        // Set shared record if it isn't already set
        if(details.sharedRecord == null) {
			SObject sharedRecord = FormulaShareUtilities.getSObjectTypeFromName(rule.objectSharedAPIName).newSObject();
			sharedRecord.Id = sharedObjectId;
			sharedRecord.put('OwnerId', sharedObjectOwnerId);
			details.sharedRecord = sharedRecord;
        }

        List<SObject> relatedRecords = getRelatedRecords(details, rule.developerName);

		// Add details to related records map
		relatedRecords.add(relatedRecord);

		System.debug('relatedRecords: '+relatedRecords);

		// Set all the map items
		details.controllingRecordsForRulesMap.put(rule.developerName, relatedRecords);
		retrieveRecordDetails.put(sharedObjectId, details);
	}


    // Get or create details map
    private FormulaShareRetrievedRecordDetails getRetrievedRecordDetails(Map<Id,FormulaShareRetrievedRecordDetails> sharedRecordMap, Id sharedRecordId) {
		FormulaShareRetrievedRecordDetails details;
		if(sharedRecordMap.containsKey(sharedRecordId)) {
			details = sharedRecordMap.get(sharedRecordId);
		}
		else {
			details = new FormulaShareRetrievedRecordDetails();
        }
        return details;
    }

    // Get or create the related records map
    private List<SObject> getRelatedRecords(FormulaShareRetrievedRecordDetails details, String ruleName) {
		List<SObject> relatedRecords;
		if(details.controllingRecordsForRulesMap.containsKey(ruleName)) {
			relatedRecords = details.controllingRecordsForRulesMap.get(ruleName);
		}
		else {
			relatedRecords = new List<SObject>();
        }
        return relatedRecords;
    }
    
}