public inherited sharing class FormulaShareBatchLogsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Log__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Log__c.Id,
            FormulaShare_Log__c.CreatedDate };
    }

    public override String getOrderBy() {
        return 'CreatedDate';
    }

    public Database.QueryLocator selectLogsOlderThanDate(DateTime newestLogTime) {
        String query = newQueryFactory()
            .setCondition('CreatedDate < :newestLogTime')
            .toSOQL();
        return Database.getQueryLocator(query);
    }
}