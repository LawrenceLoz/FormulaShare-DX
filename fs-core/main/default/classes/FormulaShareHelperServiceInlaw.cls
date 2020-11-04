public inherited sharing class FormulaShareHelperServiceInlaw extends FormulaShareHelperServiceRuleType {

    public List<FormulaShareRuleInlaw> rules = new List<FormulaShareRuleInlaw>();

    public FormulaShareHelperServiceInlaw(List<FormulaShareRule> rules) {
		for(FormulaShareRule rule : rules) {
			if(rule.isValid() && rule.active && rule.type == 'inlaw') {
                this.rules.add((FormulaShareRuleInlaw) rule);
			}
		}
    }


	public void processInsert(SObject newRecord) {
		for(FormulaShareRuleInlaw rule : rules) {

			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null 
				&& newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != null) {
				addToSets(newRecord, rule);
			}
		}
	}


	public void processUpdate(SObject newRecord, SObject oldRecord) {
		for(FormulaShareRuleInlaw rule : rules) {

			// Only progress if both lookups on bottom object are populated
			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null
				&& newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != null) {
				
				// If lookup towards shared object has changed, check sharing
				if(oldRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != newRecord.get(rule.lookupFromBottomObjTowardsSharedObj)) {
					addToSets(newRecord, rule);
				}

				// If lookup towards controlling object has changed, check sharing
				else if(newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != newRecord.get(rule.lookupFromBottomObjTowardsControllingObj)) {
					addToSets(newRecord, rule);
				}
			}
		}
    }

}