public inherited sharing class FormulaShareSObjectSharesCustomSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

    public FormulaShareSObjectSharesCustomSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
        this.type = type;

        // Populate selected fields depending on whether custom or standard
        Map<String, SObjectField> fieldMap = type.getDescribe().fields.getMap();
        this.fields.add(fieldMap.get('Id'));
        this.fields.add(fieldMap.get('UserOrGroupId'));
        this.fields.add(fieldMap.get('ParentId'));
        this.fields.add(fieldMap.get('AccessLevel'));
        this.fields.add(fieldMap.get('RowCause'));
    }

    public Schema.SObjectType getSObjectType() {
        return type;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return fields;
    }

    public override String getOrderBy() {
        return 'Id';
    }

    // Query by Ids of shared records and row causes (apex sharing reasons)
    public List<SObject> selectByParentIdsAndRowCauses(String parentIdsString, String rowCausesString) {
        String condition = 'RowCause IN (' + rowCausesString 
            + ') AND ParentId IN (' + parentIdsString + ')';
        String query = newQueryFactory().setCondition(condition).toSOQL();
        system.debug('query : '+query);

        List<SObject> results = Database.query(query);
        system.debug('results: '+results);
        return results;
    }

}