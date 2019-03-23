public inherited sharing class FormulaShareSObjectSharesStdSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    public String objectName;

    public FormulaShareSObjectSharesStdSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Schema.SObjectType parentType) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
        this.type = type;

        objectName = parentType.getDescribe().getName();
        Map<String, SObjectField> fieldMap = type.getDescribe().fields.getMap();
        this.fields.add(fieldMap.get('Id'));
        this.fields.add(fieldMap.get('UserOrGroupId'));
        this.fields.add(fieldMap.get(objectName + 'Id'));
        this.fields.add(fieldMap.get(objectName + 'AccessLevel'));
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

    // Query by Ids of shared records
    public List<SObject> selectByParentIds(String parentIdsString) {
        return Database.query(
            newQueryFactory().
            setCondition(objectName + 'Id IN (' + parentIdsString + ') AND RowCause = \'Manual\'').
            toSOQL());
    }

}