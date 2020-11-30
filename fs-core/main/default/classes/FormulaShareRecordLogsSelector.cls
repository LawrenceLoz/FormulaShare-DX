public inherited sharing class FormulaShareRecordLogsSelector extends fflib_SObjectSelector {
    public FormulaShareRecordLogsSelector() {

    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Record_Log__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Record_Log__c.Id,
            FormulaShare_Record_Log__c.CreatedDate };
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