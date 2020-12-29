/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

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
        System.debug('query : '+query);

        List<SObject> results = Database.query(query);
        system.debug('results: '+results);
        return results;
    }

}