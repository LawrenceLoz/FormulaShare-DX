public inherited sharing class FormulaShareSObjectSharesSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public Schema.SObjectType parentType;
    public String parentIdFieldName;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

    public FormulaShareSObjectSharesSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Schema.SObjectType parentType) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
        this.type = type;
        this.parentType = parentType;

        // Add core fields
        Map<String, SObjectField> fieldMap = type.getDescribe().fields.getMap();
        this.fields.add(fieldMap.get('Id'));
        this.fields.add(fieldMap.get('UserOrGroupId'));
        this.fields.add(fieldMap.get('RowCause'));

        // Add access and parent id fields depending on whether custom or standard
        FormulaShareSObjectUtilities objUtils = new FormulaShareSObjectUtilities(parentType);
        parentIdFieldName = objUtils.parentIdFieldName();   // We'll also use in query
        this.fields.add(fieldMap.get(parentIdFieldName));
        this.fields.add(fieldMap.get(objUtils.accessLevelFieldName()));

        // Add related object sharing fields for account sharing
        if(parentType.getDescribe().getName() == 'Account') {
            this.fields.add(fieldMap.get('ContactAccessLevel'));
            this.fields.add(fieldMap.get('CaseAccessLevel'));
            this.fields.add(fieldMap.get('OpportunityAccessLevel'));
        }        
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

    public List<SObject> selectByParentIds(String parentIdsString) {
        return selectByParentIdsAndRowCauses(parentIdsString, '\'Manual\'');
    }

    // Query by Ids of shared records and row causes. Called directly for custom objects
    public List<SObject> selectByParentIdsAndRowCauses(String parentIdsString, String rowCausesString) {
        
        String condition = 'RowCause IN (' + rowCausesString 
            + ') AND '+parentIdFieldName+' IN (' + parentIdsString + ')';
        String query = newQueryFactory().setCondition(condition).toSOQL();
        system.debug('query : '+query);

        List<SObject> results = Database.query(query);
        system.debug('results: '+results);
        return results;
    }

}