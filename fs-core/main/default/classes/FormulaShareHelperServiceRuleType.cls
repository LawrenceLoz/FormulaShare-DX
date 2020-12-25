public abstract inherited sharing class FormulaShareHelperServiceRuleType {

	public Set<FormulaShareRule> relevantRules = new Set<FormulaShareRule>();
	public Set<Id> recordsToQuery = new Set<Id>();
	public List<BottomObjectRecordRule> recordRules = new List<BottomObjectRecordRule>();

    // Methods must be implemented
    public abstract void processInsert(SObject newRecord);
    public abstract void processUpdate(SObject newRecord, SObject oldRecord);


    // Populates record id to be queried, and sets record rules to be matched after query
    protected virtual void addToSets(SObject record, FormulaShareRule rule) {
		relevantRules.add(rule);
		recordsToQuery.add(record.Id);

		BottomObjectRecordRule details = new BottomObjectRecordRule();
		details.bottomObjectRecordId = record.Id;
		details.rule = rule;
		recordRules.add(details);
    }

	public class BottomObjectRecordRule {
		public Id bottomObjectRecordId;
		public FormulaShareRule rule;
	}
}
