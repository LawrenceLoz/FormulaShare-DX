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


    public List<SObject> selectWithFieldsForObjectList(List<RelatedObjectDetails> rodList, List<SObject> sharedObjList) {
        fflib_QueryFactory sharedObjQueryFactory = newQueryFactory();

        // If child object sharing is required, add relationship sub-selects for fields on related objects
        for(RelatedObjectDetails rod : rodList) {
            FormulaShareSObjectsSelector relatedObjSelector = new FormulaShareSObjectsSelector(true, rod.type, rod.fields);

            
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

            fflib_QueryFactory relatedObjQueryFactory = relatedObjSelector.addQueryFactorySubselect(sharedObjQueryFactory, rod.relationshipName);
//            relatedObjQueryFactory.setCondition(condition);
        }
        
        Set<Id> sharedObjIdSet = new Set<Id>();
        for(SObject obj : sharedObjList) {
            sharedObjIdSet.add((Id) obj.get('Id'));
        }
        String sharedObjIdsString = FormulaShareUtilities.buildStringFromSetQuotes(sharedObjIdSet);

        system.debug('query as soql: '+sharedObjQueryFactory.setCondition('Id IN (' + sharedObjIdsString + ')').toSOQL());

        return Database.query(
            sharedObjQueryFactory
            .setCondition('Id IN (' + sharedObjIdsString + ')')
            .toSOQL()
        );
    }
ó

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