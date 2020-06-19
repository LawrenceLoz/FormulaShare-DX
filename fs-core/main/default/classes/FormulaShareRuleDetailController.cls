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


public with sharing class FormulaShareRuleDetailController {

    public static List<ShareableObject> shareableObjects = new List<ShareableObject>();

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getObjectApiNames(List<String> objectEntityIds) {

        List<EntityDefinition> entityDefs = FormulaShareEntityDefinitionSelector.construct().getEntitiesForIds(objectEntityIds);
        
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

        List<EntityDefinition> entityDefs = FormulaShareEntityDefinitionSelector.construct().getAllShareable();

        List<ShareableObject> soListStandard = new List<ShareableObject>();
        List<ShareableObject> soListCustom = new List<ShareableObject>();

        for(EntityDefinition ed : entityDefs) {
            if(ed.InternalSharingModel == 'Private' || ed.InternalSharingModel == 'Read'
                || ed.ExternalSharingModel == 'Private' || ed.ExternalSharingModel == 'Read') {
                ShareableObject so = new ShareableObject();
                so.objectApiName = ed.QualifiedApiName;
                so.objectLabel = ed.Label;
                so.objectId = ed.DurableId;
                so.detailUrl = ed.DetailUrl;
                so.pluralLabel = ed.PluralLabel;
                so.internalSharingModel = ed.InternalSharingModel;
                so.externalSharingModel = ed.ExternalSharingModel;

                // Identify custom objects from API name
                if(ed.QualifiedApiName.right(3) == '__c') {
                    so.isCustom = true;
                }

                Schema.DescribeSObjectResult objType = FormulaShareUtilities.describe(ed.QualifiedApiName);
                if(objType != null) {
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
        public String internalSharingModel {get;set;}
        @AuraEnabled
        public String externalSharingModel {get;set;}
        @AuraEnabled
        public Boolean isCustom {get;set;}
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
