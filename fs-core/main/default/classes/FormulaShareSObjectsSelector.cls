public inherited sharing class FormulaShareSObjectsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    Set<Schema.SObjectField> fieldsSet = new Set<Schema.SObjectField>();
    Set<String> fieldStrings = new Set<String>();

    //    public static FormulaShareSObjectsSelector mock;
    public static FormulaShareSObjectsSelector construct(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type) {
//        if(Test.isRunningTest()) {
//            return mock;
//        }
//        else {
        return new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity, type);
//        }
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
        fieldStrings.add(fieldString);
    }


////    public static FormulaShareSObjectsSelector mock;
//    public static FormulaShareSObjectsSelector construct(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Set<Schema.SObjectField> fieldsSet) {
////        if(Test.isRunningTest()) {
////            return mock;
////        }
////        else {
//            return new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity, type, fieldsSet);
////        }
//    }
//
//    public FormulaShareSObjectsSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Set<Schema.SObjectField> fieldsSet) {
//        super(false // Do not include FieldSet fields
//            , enforceObjectAndFieldSecurity // Enforce field security if requested
//            , enforceObjectAndFieldSecurity // Enforce object security if requested
//            );
//        this.type = type;
//        this.fields.addAll(fieldsSet);
//    }

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

        controllingObjQueryFactory.setCondition(queryCondition);

        system.debug('SOQL with condition: '+controllingObjQueryFactory.toSOQL());

        return Database.query(controllingObjQueryFactory.toSOQL());
    }


    // Used to query for a set of records with specific ids
    // ----- replace method below with this ------------
    public List<SObject> selectWithFields(Set<Id> recordIdSet) {

        // Set fields provided as tokens
        fields.addAll(fieldsSet);

        fflib_QueryFactory factory = newQueryFactory();
        system.debug('*SOQL before loop: '+factory.toSOQL());

        // Add fields provided as strings (lookups would be added this way)
        for(String fieldString : fieldStrings) {
            factory.selectField(fieldString);
            System.debug('Adding field: '+fieldString);
        }

        // Restrict to specific records in scope
        String recordIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordIdSet);
        factory.setCondition('Id IN (' + recordIdsString + ')');
        system.debug('SOQL with condition: '+factory.toSOQL());

        return Database.query(factory.toSOQL());
    }


    // Called directly 
//    public List<SObject> selectWithFieldsForObjectList(List<RelatedObjectDetails> rodList, Set<Id> sharedObjIdSet) {
//        fields.addAll(fieldsSet);
//
//        fflib_QueryFactory sharedObjQueryFactory = newQueryFactory();
//        system.debug('*SOQL before loop: '+sharedObjQueryFactory.toSOQL());
//
//        // If child object sharing is required, add relationship sub-selects for fields on related objects
//        for(RelatedObjectDetails rod : rodList) {
//            system.debug('rod.relationshipName '+rod.relationshipName);
//
//            try {
//                FormulaShareSObjectsSelector relatedObjSelector = new FormulaShareSObjectsSelector(true, rod.type);
//                relatedObjSelector.setFields(rod.fields);
//                fflib_QueryFactory relatedObjQueryFactory = relatedObjSelector.addQueryFactorySubselect(sharedObjQueryFactory, rod.relationshipName);
//            }
//            catch(Exception e) {
//                e.setMessage('Issue constructing related object subquery for rule sharing object '
//                    + type.getDescribe().getName() + ' based on field in object '
//                    + rod.type.getDescribe().getName() + '. This could be due to an invalid FormulaShare rule configuration '
//                    + '(Exception: '+e.getMessage()+')');
//                throw e;
//            }
//
//            // Exclude records which don't have any shared to field populated - commented out as not possible to 
//            // add conditions to subselects with current fflibs version
////            String condition = '';
////            for(Schema.SObjectField field : rod.fields) {
////                String fieldName = field.getDescribe().getName();
////                if(String.isBlank(condition)) {
////                    condition = fieldName + ' != null';
////                }
////                else {
////                    condition = condition + ' OR ' + fieldName + ' != null';
////                }
////            }
////            relatedObjQueryFactory.setCondition(condition);
//        }
//
//        // Add parent fields if included
//        for(String fieldString : fieldStrings) {
//            sharedObjQueryFactory.selectField(fieldString);
//        }
//
//        // Restrict to specific shared records in scope
//        String sharedObjIdsString = FormulaShareUtilities.buildStringFromSetQuotes(sharedObjIdSet);
//        sharedObjQueryFactory.setCondition('Id IN (' + sharedObjIdsString + ')');
//        system.debug('SOQL with condition: '+sharedObjQueryFactory.toSOQL());
//
//        return Database.query(sharedObjQueryFactory.toSOQL());
//    }


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


//    public Database.QueryLocator selectAllSharedObjectsLocator() {
//        fields.addAll(fieldsSet);
//        fflib_QueryFactory sharedObjQueryFactory = newQueryFactory();
//        return Database.getQueryLocator(
//            sharedObjQueryFactory.toSOQL()
//        );
//    }

    public class RelatedObjectDetails {
        public SObjectType type;
        public Set<Schema.SObjectField> fields;
        public String relationshipName;
    }

}