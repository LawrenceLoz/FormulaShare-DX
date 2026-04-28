public inherited sharing class FormulaShareApexClassSelector extends fflib_SObjectSelector {

    // ApexClass is a setup object — WITH USER_MODE throws QueryException for users lacking "View Setup and Configuration".
    public FormulaShareApexClassSelector() {
        super(false, DataAccess.SYSTEM_MODE);
    }

    public Schema.SObjectType getSObjectType() {
        return ApexClass.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            ApexClass.Id,
            ApexClass.Name,
            ApexClass.NamespacePrefix
        };
    }

    /**
     * Returns the Ids of ApexClass records that match the provided names and namespace.
     * If namespace is null or empty, it will look for classes with a null NamespacePrefix. 
     */
    public Set<Id> getIdsByNamesAndNamespace(Set<String> names, String namespace) {
        if (names == null || names.isEmpty()) {
            return new Set<Id>();
        }
        fflib_QueryFactory qf = newQueryFactory()
            .selectField(ApexClass.Id)
            .setCondition('Name IN :names AND NamespacePrefix ' + (String.isBlank(namespace) ? '= NULL' : '= :namespace'));
        String soql = qf.toSOQL();
        List<ApexClass> rows = (List<ApexClass>) Database.query(soql);
        return new Map<Id, ApexClass>(rows).keySet();
    }
}