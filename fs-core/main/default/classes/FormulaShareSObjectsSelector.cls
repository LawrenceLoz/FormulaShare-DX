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

public inherited sharing class FormulaShareSObjectsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
    Set<String> fieldStrings = new Set<String>();

    public static FormulaShareSObjectsSelector construct(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type) {
        return new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity, type);
    }
    
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

    public void addField(Schema.SObjectField field) {
        fieldsSet.add(field);
    }

    // Can be used to populate based on field API name, or a lookup path to a parent object
    public void addFieldString(String fieldString) {
        System.debug('Adding field in selector: '+fieldString);
        fieldStrings.add(fieldString);
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


    public List<SObject> selectPopulatedRecordsBasedOnParentPath(String parentFieldPath, Set<Id> parentIdSet) {
        fields.addAll(fieldsSet);
        
        fflib_QueryFactory controllingObjQueryFactory = newQueryFactory();

        // Add parent path to select
        System.debug('Adding field: '+parentFieldPath+' to selector for type: '+type.getDescribe().getName());
        controllingObjQueryFactory.selectField(parentFieldPath);

        // Restrict to specific shared records in scope 
        String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(parentIdSet);
        String queryCondition = parentFieldPath + ' IN (' + parentIdsString + ')';

        // If fields are supplied, we'll select these and restrict to records with one or more populated
        if(!fieldStrings.isEmpty()) {
            queryCondition += ' AND (';

            // Add fields provided as strings (this would be all fields controlling sharing)
            Boolean firstField = true;
            for(String fieldString : fieldStrings) {
                System.debug('|SOQL Adding query field: '+fieldString);

                controllingObjQueryFactory.selectField(fieldString);
                if(firstField) {
                    firstField = false;
                }
                else {
                    queryCondition += ' OR ';
                }
                // Restrict to only records with a share field popualted
                queryCondition += fieldString + ' != NULL';
            }

            queryCondition += ')';
        }

        System.debug('Full query condition: '+queryCondition);
        controllingObjQueryFactory.setCondition(queryCondition);

        system.debug('SOQL with condition: '+controllingObjQueryFactory.toSOQL());
        return Database.query(controllingObjQueryFactory.toSOQL());
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


    public class RelatedObjectDetails {
        public SObjectType type;
        public Set<Schema.SObjectField> fields;
        public String relationshipName;
    }

}