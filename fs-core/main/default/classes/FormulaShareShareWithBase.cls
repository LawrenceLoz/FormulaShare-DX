public abstract inherited sharing class FormulaShareShareWithBase {

    protected FormulaShareService service;

    Schema.SObjectType cachedSharedToType;
    protected Schema.SObjectType sharedToType {
        get {
            if(cachedSharedToType == null) {
                cachedSharedToType = getSharedToType();
            }
            return cachedSharedToType;
        }
    }
    public abstract Schema.SObjectType getSharedToType();
    
    protected Set<Id> queryIdSet = new Set<Id>();
    protected Set<FormulaShareService.RecordRule> recordRules = new Set<FormulaShareService.RecordRule>();

    public abstract void checkAndAdd(String sharedToString, FormulaShareService.RecordRule recRule);
    public abstract void assess();


    // Adds fallbackShareToFieldMismatch to nameSet argument if Share With Default
    private Set<String> rulesWithShareToFallbackNameAdded = new Set<String>();
    protected void addShareToFallbackNameToCollection(Set<String> namesSet, FormulaShareService.RecordRule recRule) {
        if(!rulesWithShareToFallbackNameAdded.contains(recRule.rule.developerName)) {
            if(recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') { namesSet.add(recRule.rule.fallbackShareToFieldMismatch); }
            rulesWithShareToFallbackNameAdded.add(recRule.rule.developerName);
        }
    }

    // Adds fallbackShareToFieldMismatch to idsSet argument if Share With Default
    protected Map<String,Boolean> rulesWithShareToFallbackIdValidity = new Map<String,Boolean>();
    protected void addShareToFallbackIdsToCollection(Set<Id> idsSet, FormulaShareService.RecordRule recRule) {
        if(!rulesWithShareToFallbackIdValidity.containsKey(recRule.rule.developerName) && recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
            if(FormulaShareIdUtilities.construct().isValidIdType(recRule.rule.fallbackShareToFieldMismatch, sharedToType)) {
                idsSet.add((Id) recRule.rule.fallbackShareToFieldMismatch);
                rulesWithShareToFallbackIdValidity.put(recRule.rule.developerName, true);
            }
            else {
                rulesWithShareToFallbackIdValidity.put(recRule.rule.developerName, false);
            }
        }
    }

    // Adds fallbackMdMatchFieldMismatch to namesSet argument if Share With Default
    private Set<String> rulesWithMdMatchFallbackNameAdded = new Set<String>();
    protected void addMdMatchFallbackToCollection(Set<String> namesSet, FormulaShareService.RecordRule recRule) {
        if(!rulesWithMdMatchFallbackNameAdded.contains(recRule.rule.developerName)) {
            if(recRule.rule.behaviourMdMatchFieldMismatch == 'Share With Default') { namesSet.add(recRule.rule.fallbackMdMatchFieldMismatch); }
            rulesWithMdMatchFallbackNameAdded.add(recRule.rule.developerName);
        }
    }

}