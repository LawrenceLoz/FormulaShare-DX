public inherited sharing class FormulaShareRetrievedRecordDetails {
    public SObject sharedRecord;
    public Map<String,List<SObject>> controllingRecordsForRulesMap;

    public FormulaShareRetrievedRecordDetails() {
        controllingRecordsForRulesMap = new Map<String,List<SObject>>();
    }
}