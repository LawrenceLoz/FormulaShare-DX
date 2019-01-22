public inherited sharing class FormulaShareSObjectsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

    public FormulaShareSObjectsSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Set<Schema.SObjectField> fieldsSet) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
        this.type = type;
        this.fields.addAll(fieldsSet);
    }

    public Schema.SObjectType getSObjectType() {
        return type;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return fields;
    }

    public Database.QueryLocator selectAllLocator() {
        return Database.getQueryLocator(
            newQueryFactory().toSOQL()
        );
    }

}