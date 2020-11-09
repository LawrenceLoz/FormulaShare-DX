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


    public void processInsert(SObject newRecord) {
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


	public void processUpdate(SObject newRecord, SObject oldRecord) {

		for(FormulaShareRule rule : rules) {

			if(rule.isValid() && rule.active) {

				// If sharing field specified on a standard rule has changed, we might need to assess sharing for this record
				if(oldRecord.get(rule.firstQueryStepApiName) != newRecord.get(rule.firstQueryStepApiName)) {
					addToSets(newRecord, rule);
					addToFullSets(rule);
				}

				// If owner of shared standard object has changed we might need to check if this owner still requires sharing
				else if(oldRecord.get('OwnerId') != newRecord.get('OwnerId') && !rule.sharedObjectIsCustom) {
					addToSets(newRecord, rule);
					addToFullSets(rule);
				}

				// And also add to full set of rules if relevant sharing might already be in place
				// (this may need to be assessed for deletions)
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