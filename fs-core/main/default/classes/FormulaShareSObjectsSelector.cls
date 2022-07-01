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

public virtual inherited sharing class FormulaShareSObjectsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    protected Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
    protected Set<String> fieldStrings = new Set<String>();

    public FormulaShareSObjectsSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
        this.type = type;
    }

    public void setFields(Set<Schema.SObjectField> suppliedFieldsSet) {
        fieldsSet = suppliedFieldsSet;
    }

    // Can be used to populate based on field API name, or a lookup path to a parent object
    public void addFieldString(String fieldString) {
        System.debug('Adding field in selector: '+fieldString);

        if(fieldString != null) {
            fieldStrings.add(fieldString);
        }
    }
    

    public Schema.SObjectType getSObjectType() {
        return type;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return fields;
    }

    public Database.QueryLocator selectAllLocator() {
        fields.addAll(fieldsSet);
        return Database.getQueryLocator(
            newQueryFactory().toSOQL()
        );
    }   


    // Used to query for a set of records with specific ids
    public List<SObject> selectWithFields(Set<Id> recordIdSet) {

        // Set fields provided as tokens
        fields.addAll(fieldsSet);

        fflib_QueryFactory factory = newQueryFactory();
        system.debug('*SOQL before loop: '+factory.toSOQL());

        // Add fields provided as strings (lookups would be added this way)
        for(String fieldString : fieldStrings) {
            factory.selectField(fieldString);
            System.debug('Added field in selector: '+fieldString);
        }

        // Restrict to specific records in scope
        String recordIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordIdSet);

        System.debug('recordIdsString: '+ recordIdsString);

        factory.setCondition('Id IN (' + recordIdsString + ')');
        System.debug('SOQL with condition: '+factory.toSOQL());

        List<SObject> queriedRecords = Database.query(factory.toSOQL());
        System.debug('Result: '+queriedRecords);

        return queriedRecords;
    }


    // Returns values for first few records with non-blank field values
    public List<String> selectSampleData(Integer queryLimit) {
        fields.addAll(fieldsSet);

        Schema.SObjectField queryField = fields[0];
        String queryFieldName = queryField.getDescribe().getName();

        fflib_QueryFactory sampleQueryFactory = newQueryFactory();
        List<SObject> results = Database.query(
            sampleQueryFactory
            .setCondition(queryFieldName + ' != null')
            .setLimit(queryLimit)
            .toSOQL()
        );

        List<String> returnList = new List<String>();
        for(SObject so : results) {
            String value = String.valueOf(so.get(queryFieldName));
            returnList.add(value);
        }
        return returnList;
    }


}