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


    public static Id getTopRecordIdFromFieldList(List<Schema.SObjectField> fieldList, SObject record) {
        Integer lastIndex = fieldList.size() - 1;

        // Get the final field from this list - we'll need to check for this lookup on the penultimate record
        Schema.SObjectField finalLookup = fieldList[lastIndex];
        String finalLookupApiName = finalLookup.getDescribe().getName();

        // Make a copy of the field list with this field removed
        List<Schema.SObjectField> fieldsOneFromTop = fieldList.clone();
        fieldsOneFromTop.remove(lastIndex);

        // Get the object which is one away from the top object (this will contain the queried lookup)
        SObject penultimateRecord;
        if(fieldsOneFromTop.isEmpty()) {
            penultimateRecord = record;
        }
        else {
            FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
            penultimateRecord = recordUtils.getTopRecordFromLookup(fieldsOneFromTop);
        }

        // Return the Id in the lookup to the top object
        return (Id) penultimateRecord?.get(finalLookupApiName);
    }    

}
