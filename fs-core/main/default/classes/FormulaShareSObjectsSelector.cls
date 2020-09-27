public inherited sharing class FormulaShareSObjectsSelector extends fflib_SObjectSelector {

    public Schema.SObjectType type;
    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

//    public static FormulaShareSObjectsSelector mock;
    public static FormulaShareSObjectsSelector construct(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type, Set<Schema.SObjectField> fieldsSet) {
//        if(Test.isRunningTest()) {
//            return mock;
//        }
//        else {
            return new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity, type, fieldsSet);
//        }
    }


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


    public List<SObject> selectWithFieldsForObjectList(List<RelatedObjectDetails> rodList, Set<Id> sharedObjIdSet) {

        fflib_QueryFactory sharedObjQueryFactory = newQueryFactory();
        system.debug('*SOQL before loop: '+sharedObjQueryFactory.toSOQL());

        // If child object sharing is required, add relationship sub-selects for fields on related objects
        for(RelatedObjectDetails rod : rodList) {
            system.debug('rod.relationshipName '+rod.relationshipName);

            try {
                FormulaShareSObjectsSelector relatedObjSelector = new FormulaShareSObjectsSelector(true, rod.type, rod.fields);
                fflib_QueryFactory relatedObjQueryFactory = relatedObjSelector.addQueryFactorySubselect(sharedObjQueryFactory, rod.relationshipName);
            }
            catch(Exception e) {
                e.setMessage('Issue constructing related object subquery for rule sharing object '
                    + type.getDescribe().getName() + ' based on field in object '
                    + rod.type.getDescribe().getName() + '. This could be due to an invalid FormulaShare rule configuration '
                    + '(Exception: '+e.getMessage()+')');
                throw e;
            }

            // Exclude records which don't have any shared to field populated - commented out as not possible to 
            // add conditions to subselects with current fflibs version
//            String condition = '';
//            for(Schema.SObjectField field : rod.fields) {
//                String fieldName = field.getDescribe().getName();
//                if(String.isBlank(condition)) {
//                    condition = fieldName + ' != null';
//                }
//                else {
//                    condition = condition + ' OR ' + fieldName + ' != null';
//                }
//            }
//            relatedObjQueryFactory.setCondition(condition);
        }

        // Restrict to specific shared records in scope
        String sharedObjIdsString = FormulaShareUtilities.buildStringFromSetQuotes(sharedObjIdSet);
        sharedObjQueryFactory.setCondition('Id IN (' + sharedObjIdsString + ')');
        system.debug('SOQL with condition: '+sharedObjQueryFactory.toSOQL());

        return Database.query(sharedObjQueryFactory.toSOQL());
    }


    // Returns values for first few records with non-blank field values
    public List<String> selectSampleData(Integer queryLimit) {
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


    public Database.QueryLocator selectAllSharedObjectsLocator() {
        fflib_QueryFactory sharedObjQueryFactory = newQueryFactory();
        return Database.getQueryLocator(
            sharedObjQueryFactory.toSOQL()
        );
    }

    public class RelatedObjectDetails {
        public SObjectType type;
        public Set<Schema.SObjectField> fields;
        public String relationshipName;
    }

}