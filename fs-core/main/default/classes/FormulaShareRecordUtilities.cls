public with sharing class FormulaShareRecordUtilities {

    SObject record;

    public FormulaShareRecordUtilities(SObject record) {
        this.record = record;
    }


    public SObject getTopRecordFromLookup(List<Schema.SObjectField> lookupFieldList) {

        // Iterate through fields until we're at the top object
        for(Schema.SObjectField field : lookupFieldList) {
            System.debug('Checking for field: '+field.getDescribe().getName()+' in record: '+record);
            record = record.getSObject(field);
            System.debug('record now: '+ record);

            // Return null if no record returned for this lookup. This could be the case if
            // relationship wasn't queried because lookup was cleared
            if(record == null) {
                return null;
            }
        }

        return record;
    }

}
