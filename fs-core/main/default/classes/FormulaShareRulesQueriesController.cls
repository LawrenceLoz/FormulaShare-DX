public with sharing class FormulaShareRulesQueriesController {

    // Returns details of a single rule matching a supplied id
    // Used by FormulaShareRuleDetail LWC
    @AuraEnabled(cacheable=false)
    public static FormulaShareRule getSpecificRule(Id ruleId) {
        FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
        return selector.getSpecificRule(ruleId);
    }

}
