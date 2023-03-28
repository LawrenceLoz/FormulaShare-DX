public abstract inherited sharing class FormulaShareShareWithBase {

    protected FormulaShareService service;
    protected Set<Id> queryIdSet = new Set<Id>();
    protected Set<FormulaShareService.RecordRule> recordRules = new Set<FormulaShareService.RecordRule>();

    public abstract void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule);
    public abstract void assess();

}