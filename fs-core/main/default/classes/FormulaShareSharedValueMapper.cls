public virtual inherited sharing class FormulaShareSharedValueMapper {

    public virtual void setRules(List<FormulaShareRule> rules, List<FormulaShareRetrievedRecordDetails> recordDetails) {}

    public virtual String getSharedToValue(FormulaShareRule rule, SObject controllingObj) {
        return rule.getSharedToValueFromRecord(controllingObj);
    }
}