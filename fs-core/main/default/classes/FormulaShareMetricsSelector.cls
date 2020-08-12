public inherited sharing class FormulaShareMetricsSelector extends fflib_SObjectSelector {

    public static FormulaShareMetricsSelector construct() {
        return new FormulaShareMetricsSelector();
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Metrics__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Metrics__c.Id,
            FormulaShare_Metrics__c.CreatedDate,
            FormulaShare_Metrics__c.Failed_Inserts__c,
            FormulaShare_Metrics__c.Last_Failed_Operation__c,
            FormulaShare_Metrics__c.Last_Successful_Operation__c,
            FormulaShare_Metrics__c.Successful_Inserts__c,
            FormulaShare_Metrics__c.Context__c,
            FormulaShare_Metrics__c.FormulaShare_Rule_Name__c
        };
    }

    public override String getOrderBy() {
        return 'CreatedDate';
    }

    public List<FormulaShare_Metrics__c> getAllMetricsForRules(Set<String> ruleNames) {
        List<FormulaShare_Metrics__c> metrics = (List<FormulaShare_Metrics__c>) Database.query(
            newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames')
            .toSOQL());
        return metrics;
    }

    public List<FormulaShare_Metrics__c> getMetricsForRulesAndContext(Set<String> ruleNames, String context) {
        List<FormulaShare_Metrics__c> metrics = (List<FormulaShare_Metrics__c>) Database.query(
            newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames AND Context__c = :context')
            .toSOQL());
            String query = newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames AND Context__c = :context')
            .toSOQL();
            system.debug('Query is: '+query);
        return metrics;
    }

}