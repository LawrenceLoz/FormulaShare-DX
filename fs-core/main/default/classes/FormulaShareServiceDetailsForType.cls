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

    // Sets standard and ancestor rules in core retrieveRecordDetails
	public void setSharedObjectRetrievedRecord(String sharedObjectApiName, SObject sharedRecord) {

        FormulaShareRetrievedRecordDetails details = getRetrievedRecordDetails(retrieveRecordDetails, sharedRecord.Id);

		// Set the shared record in this details map. Note that this will replace any shared record already
		// set (which could have included id only if set by setRetrievedRecordWithRelatedDetails())
		details.sharedRecord = sharedRecord;

		// Update map with details
		retrieveRecordDetails.put(sharedRecord.Id, details);
	}
    

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