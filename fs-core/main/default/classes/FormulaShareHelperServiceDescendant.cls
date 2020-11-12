public inherited sharing class FormulaShareHelperServiceDescendant extends FormulaShareHelperServiceRuleType {

    public List<FormulaShareRuleDescendant> rules = new List<FormulaShareRuleDescendant>();

    public FormulaShareHelperServiceDescendant(List<FormulaShareRule> rules) {
		for(FormulaShareRule rule : rules) {
			if(rule.isValid() && rule.active && rule.type == 'descendant') {
                this.rules.add((FormulaShareRuleDescendant) rule);
			}
		}
    }


	public void processInsert(SObject newRecord) {
		System.debug('Descendant process insert');
		for(FormulaShareRuleDescendant rule : rules) {
			System.debug('Checking record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));

			// If lookup towards shared on a descendant rule is populated, we might need to assess sharing for the shared object
			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null 
				&& newRecord.get(rule.controllingObjectSharedToFieldAPIName) != null) {
				System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));
				addToSets(newRecord, rule);
			}
		}
    }
    

	public void processUpdate(SObject newRecord, SObject oldRecord) {
		for(FormulaShareRuleDescendant rule : rules) {

			// Only progress if lookup and shared to field are populated
			if(newRecord.get(rule.controllingObjectSharedToFieldAPIName) != null
				&& newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null) {
				
				// If lookup towards shared object has changed, we might need to assess for the new parent
				if(oldRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != newRecord.get(rule.lookupFromBottomObjTowardsSharedObj)) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. Lookup change(' + rule.lookupFromBottomObjTowardsSharedObj + '): '+newRecord.get(rule.lookupFromBottomObjTowardsSharedObj));
					addToSets(newRecord, rule);
				}

				// For descendant rules, if shared to field has changed, might need to assess
				else if(oldRecord.get(rule.controllingObjectSharedToFieldAPIName) != newRecord.get(rule.controllingObjectSharedToFieldAPIName)) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));
					addToSets(newRecord, rule);
				}
			}
		}
    }

}