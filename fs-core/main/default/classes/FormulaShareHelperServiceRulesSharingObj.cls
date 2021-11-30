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

public inherited sharing class FormulaShareHelperServiceRulesSharingObj extends FormulaShareHelperServiceRuleType {

    public List<FormulaShareRule> rules = new List<FormulaShareRule>();
	public Set<SObject> recordsSharedByStandardRules = new Set<SObject>();
	public Set<Id> recordIdsSharedByAncestorRules = new Set<Id>();
	public Set<FormulaShareRuleStandard> relevantStandardRulesSet = new Set<FormulaShareRuleStandard>();
	public Set<FormulaShareRuleAncestor> relevantAncestorRulesSet = new Set<FormulaShareRuleAncestor>();
	public Set<FormulaShareRuleStandard> fullStandardRulesSet = new Set<FormulaShareRuleStandard>();
	public Set<FormulaShareRuleAncestor> fullAncestorRulesSet = new Set<FormulaShareRuleAncestor>();
	public Set<FormulaShareRule> fullRules = new Set<FormulaShareRule>();

    public FormulaShareHelperServiceRulesSharingObj(List<FormulaShareRule> rules) {
        this.rules = rules;
    }


    public override void processInsert(SObject newRecord) {
        for(FormulaShareRule rule : rules) {
			System.debug('processInsert for rule: ' + rule.developerName);
                    
            // If path to top field (the shared to field for a standard rule or lookup for ancestor)
            // is populated, we might need to check
            if(rule.isValid() && rule.active 
                && newRecord.get(rule.firstQueryStepApiName) != null) {
				System.debug('Adding record ' + newRecord.get('Id') + ' for processing for rule: ' + rule.developerName + '. First query step(' + rule.firstQueryStepApiName + '): '+newRecord.get(rule.firstQueryStepApiName));
				addToSets(newRecord, rule);
				addToFullSets(rule);
            }
        }
    }


	public override void processUpdate(SObject newRecord, SObject oldRecord) {

		for(FormulaShareRule rule : rules) {

			if(rule.isValid() && rule.active) {

				// If sharing field specified on a standard rule has changed, we might need to assess sharing for this record
				if(oldRecord.get(rule.firstQueryStepApiName) != newRecord.get(rule.firstQueryStepApiName)) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for standard or ancestor rule: ' + rule.developerName + '. firstQueryStepApiName(' + rule.firstQueryStepApiName + '): '+newRecord.get(rule.firstQueryStepApiName));
					addToSets(newRecord, rule);
					addToFullSets(rule);
				}

				// If owner has changed we might need to check if the old owner still requires sharing
				else if(oldRecord.get('OwnerId') != newRecord.get('OwnerId')) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for standard or ancestor rule: ' + rule.developerName + '. OwnerId: '+newRecord.get('OwnerId'));
					addToSets(newRecord, rule);
					addToFullSets(rule);
				}

				// And also add to full set of rules if relevant sharing might already be in place
				// (this may need to be assessed to ensure sharing isn't removed if deletion allowed)
				else if(newRecord.get(rule.firstQueryStepApiName) != null) {
					addToFullSets(rule);
				}
			}
		}
    }
    

	protected override void addToSets(SObject record, FormulaShareRule rule) {
		// Assign rule to relevant set
		switch on rule.type {
			when 'standard' {
				recordsSharedByStandardRules.add(record);
				relevantStandardRulesSet.add((FormulaShareRuleStandard) rule);
			}
			when 'ancestor' {
                recordIdsSharedByAncestorRules.add(record.Id);
				relevantAncestorRulesSet.add((FormulaShareRuleAncestor) rule);
				recordsToQuery.add(record.Id);  // Add to id list to query all relevant fields
            }
        }
        
        // And also add to full set of rules
        relevantRules.add(rule);
	}


	void addToFullSets(FormulaShareRule rule) {
		// Assign rule to relevant set
		switch on rule.type {
			when 'standard' {
				fullStandardRulesSet.add((FormulaShareRuleStandard) rule);
			}
			when 'ancestor' {
				fullAncestorRulesSet.add((FormulaShareRuleAncestor) rule);
            }
		}
		fullRules.add(rule);
	}

}