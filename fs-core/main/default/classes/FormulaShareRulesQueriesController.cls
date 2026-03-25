public with sharing class FormulaShareRulesQueriesController {

    // Returns details of a single rule matching a supplied id
    // Used by FormulaShareRuleDetail LWC
    @AuraEnabled(cacheable=false)
    public static FormulaShareRule getSpecificRule(Id ruleId) {
        FormulaShareRulesSelector selector = new FormulaShareInjectionService().getRulesSelector();
        return selector.getSpecificRule(ruleId);
    }

    // Returns filterable fields for a given SObject type, for use in sharing condition filter pickers
    // Excludes field types that cannot be used in SOQL WHERE clauses (compound, binary, geography, long text area)
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getFilterableFieldsForObject(String objectApiName) {
        List<Map<String,String>> result = new List<Map<String,String>>();
        if(String.isBlank(objectApiName)) {
            return result;
        }

        Set<Schema.DisplayType> excludedTypes = new Set<Schema.DisplayType>{
            Schema.DisplayType.BASE64,
            Schema.DisplayType.ENCRYPTEDSTRING,
            Schema.DisplayType.ADDRESS,
            Schema.DisplayType.LOCATION,
            Schema.DisplayType.DATACATEGORYGROUPREFERENCE,
            Schema.DisplayType.COMBOBOX,
            Schema.DisplayType.TEXTAREA        // Long text area and rich text — not filterable in SOQL
        };

        try {
            Schema.SObjectType sot = FormulaShareUtilities.getSObjectTypeFromName(objectApiName);
            Map<String, Schema.SObjectField> fieldMap = sot.getDescribe().fields.getMap();
            for(String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                if(!excludedTypes.contains(dfr.getType()) && dfr.isAccessible()) {
                    Map<String,String> option = new Map<String,String>();
                    option.put('label', dfr.getLabel() + ' (' + dfr.getName() + ')');
                    option.put('value', dfr.getName());
                    result.add(option);
                }
            }
            }
        catch(Exception e) {
            System.debug('getFilterableFieldsForObject error for ' + objectApiName + ': ' + e.getMessage());
        }

        return result;
    }

}
