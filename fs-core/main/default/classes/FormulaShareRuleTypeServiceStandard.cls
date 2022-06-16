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

public inherited sharing class FormulaShareRuleTypeServiceStandard extends FormulaShareRuleTypeServiceBase {

	public override Boolean sharesProcessedObject() {
		return true;
	}

    public override void setRules(String sharedObjectName) {
		this.sharedObjectName = sharedObjectName;
        FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();
		List<FormulaShareRule> allRules = rulesSelector.getStandardAndAncestorRulesSharingObject(sharedObjectName);
    }	

    public override void processInsert(SObject newRecord) {

		for(FormulaShareRule baseRule : allRules) {
			if(baseRule.isValid() && baseRule.active && baseRule.type == 'standard') {
				FormulaShareRuleStandard rule = (FormulaShareRuleStandard) baseRule;
			
				// If path to top field (the shared to field for a standard rule or lookup for ancestor)
				// is populated, we might need to check
				if(newRecord.get(rule.firstQueryStepApiName) != null) {
					System.debug('Adding record ' + newRecord.get('Id') 
						+ ' for processing for rule: ' + rule.developerName 
						+ '. First query step(' + rule.firstQueryStepApiName 
						+ '): '+newRecord.get(rule.firstQueryStepApiName));
					
					addToSets(newRecord, rule);
				}
			}
        }
    }


	public override void processUpdate(SObject newRecord, SObject oldRecord) {

		for(FormulaShareRule baseRule : allRules) {
			if(baseRule.isValid() && baseRule.active && baseRule.type == 'standard') {
				FormulaShareRuleStandard rule = (FormulaShareRuleStandard) baseRule;

				// If sharing field specified on a standard rule has changed, we might need to assess sharing for this record
				if(oldRecord.get(rule.firstQueryStepApiName) != newRecord.get(rule.firstQueryStepApiName)) {
					System.debug('Adding record ' + newRecord.get('Id') 
						+ ' for processing for standard rule: ' + rule.developerName 
						+ '. firstQueryStepApiName(' + rule.firstQueryStepApiName 
						+ '): '+newRecord.get(rule.firstQueryStepApiName));
					
					addToSets(newRecord, rule);
				}

				// If owner has changed we might need to check if the old owner still requires sharing
				else if(oldRecord.get('OwnerId') != newRecord.get('OwnerId')) {
					System.debug('Adding record ' + newRecord.get('Id') 
						+ ' for processing for standard rule: ' + rule.developerName 
						+ '. OwnerId: '+newRecord.get('OwnerId'));
					
					addToSets(newRecord, rule);
				}

				// And also add to full set of rules if sharing for this rule should already be in place
				// (this may need to be assessed to ensure sharing isn't removed if deletion allowed)
				else if(newRecord.get(rule.firstQueryStepApiName) != null) {
					this.fullRules.add(rule);
				}
			}
		}
    }
    

	private void addToSets(SObject record, FormulaShareRule rule) {
		this.recordsShared.add(record);
        this.relevantRules.add(rule);
		this.fullRules.add(rule);
	}


	public override Map<String,FormulaShareServiceDetailsForType> makeUpdatedDetailsMap(Map<String,FormulaShareServiceDetailsForType> detailsMap, Map<Id,SObject> fullQueriedRecords, String processedObjectKey) {
		for(SObject record : recordsShared) {

			// If we'd re-queried this record, use the queried version with extra fields instead
			if(fullQueriedRecords != null && fullQueriedRecords.containsKey(record.Id)) {
				record = fullQueriedRecords.get(record.Id);
			}

			// Because rules share the object being processed by trigger, use the key from the helper service 
			// which includes indication of whether sharing is removed
			FormulaShareServiceDetailsForType details = detailsMap.get(processedObjectKey);

			details.setSharedObjectRetrievedRecord(sharedObjectName, record);
			detailsMap.put(processedObjectKey, details);
		}

		return detailsMap;
	}

}