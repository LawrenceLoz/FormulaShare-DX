public with sharing class FormulaShareRuleDetailController {

    public static List<ShareableObject> shareableObjects = new List<ShareableObject>();

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getObjectApiNames(List<String> objectEntityIds) {
        List<EntityDefinition> entityDefs = [
            SELECT QualifiedApiName, DurableId
            FROM EntityDefinition
            WHERE DurableId IN :objectEntityIds
            WITH SECURITY_ENFORCED];
        
        Map<String,String> objectApiNamesMap = new Map<String,String>();
        for(EntityDefinition ed : entityDefs) {
            objectApiNamesMap.put(ed.DurableId, ed.QualifiedApiName);
        }

        return objectApiNamesMap;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getFieldApiNames(List<String> fieldEntityIds){
        List<FieldDefinition> fieldDefs = [
            SELECT QualifiedApiName, DurableId
            FROM FieldDefinition
            WHERE DurableId IN :fieldEntityIds
            WITH SECURITY_ENFORCED];
        
        Map<String,String> fieldApiNamesMap = new Map<String,String>();
        for(FieldDefinition fd : fieldDefs) {
            fieldApiNamesMap.put(fd.DurableId, fd.QualifiedApiName);
        }

        return fieldApiNamesMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<ShareableObject> getShareableObjects() {
        system.debug('getting all objects');

        List<EntityDefinition> entityDefs = [
            SELECT QualifiedApiName, Label, PluralLabel
            , InternalSharingModel, ExternalSharingModel 
            , DetailUrl, DurableId
            FROM EntityDefinition
            WHERE 
            IsCustomSetting = FALSE
            AND IsApexTriggerable = TRUE
            AND IsCustomizable = TRUE
            WITH SECURITY_ENFORCED
            ORDER BY Label
        ];

        List<ShareableObject> soListStandard = new List<ShareableObject>();
        List<ShareableObject> soListCustom = new List<ShareableObject>();

        for(EntityDefinition ed : entityDefs) {
            if(ed.InternalSharingModel == 'Private' || ed.InternalSharingModel == 'Read') {
                ShareableObject so = new ShareableObject();
                so.objectApiName = ed.QualifiedApiName;
                so.objectLabel = ed.Label;
                so.objectId = ed.DurableId;
                so.detailUrl = ed.DetailUrl;
                so.pluralLabel = ed.PluralLabel;

                Schema.DescribeSObjectResult objType = FormulaShareUtilities.describe(ed.QualifiedApiName);
                if(objType != null && objType.isSearchable()) {
                    if(objType.isCustom()) {
                        soListCustom.add(so);
                    }
                    else {
                        soListStandard.add(so);
                    }
                }
            }
        }

        List<ShareableObject> soList = new List<ShareableObject>();
        soList.addAll(soListCustom);
        soList.addAll(soListStandard);

        system.debug('soList '+ soList);
        return soList;
    }


    @AuraEnabled(cacheable=true)
    public static List<FormulaShareUtilities.ChildRelationshipDetails> getChildRelationships(String parentObjectAPIName) {
        return FormulaShareUtilities.getChildRelationships(parentObjectAPIName);
    }

    @AuraEnabled(cacheable=true)
    public static List<ShareFieldOption> getShareFieldOptions(String objectApiName){
        List<Schema.SObjectField> shareFieldTypes = FormulaShareUtilities.getShareFields(objectApiName);

        List<ShareFieldOption> sfoList = new List<ShareFieldOption>();
        for(Schema.SObjectField field : shareFieldTypes){
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            ShareFieldOption sfo = new shareFieldOption();
            sfo.fieldApiName = fieldDesc.getName();
            sfo.fieldLabel = fieldDesc.getLabel();

            // If field is a lookup or a record id, set isIdType
            Schema.DisplayType fieldType = fieldDesc.getType();
            if(fieldType == Schema.DisplayType.ID || fieldType == Schema.DisplayType.REFERENCE) {
                sfo.isIdType = true;
            }
            sfoList.add(sfo);
        }

        return sfoList;
    }

    public class ShareableObject {
        @AuraEnabled
        public String objectApiName {get;set;}
        @AuraEnabled
        public String objectLabel {get;set;}
        @AuraEnabled
        public String pluralLabel {get;set;}
        @AuraEnabled
        public String objectId {get;set;}
        @AuraEnabled
        public String detailUrl {get;set;}
        @AuraEnabled
        public List<FormulaShareUtilities.ChildRelationshipDetails> childRelationships {get;set;}
    }

    public class ShareFieldOption {
        @AuraEnabled
        public String fieldApiName {get;set;}
        @AuraEnabled
        public String fieldLabel {get;set;}
        @AuraEnabled
        public Boolean isIdType {get;set;}
    }

}
