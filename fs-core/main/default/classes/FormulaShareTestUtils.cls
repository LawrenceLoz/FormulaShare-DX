/**
*Copyright 2019 Lawrence Newcombe
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

@IsTest
public inherited sharing class FormulaShareTestUtils {

    public static String getNamespacePrefix() {
        return FormulaShareUtilities.getNamespacePrefix();
    }

    public static String batchLogRowCause  = getNamespacePrefix() + 'FormulaShare_Log_Share__c';
    public static String recordLogRowCause = getNamespacePrefix() + 'FormulaShare_Record_Log_Share__c';

    public static String sharedGroupName = 'AllInternalUsers';

    static Id groupId;
    public static Id getSharedGroupId() {
        if(groupId == null) {
            Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = :sharedGroupName][0];
            groupId = publicGroup.Id;
        }
        return groupId;
    }

    public static String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();
    public static String mdNamePrefix = 'FormulaShare_Rule.';


    //--------------------  Methods below assist simulating Metadata DML operations --------------- //

    public static Map<String,SObject> cmdtToCmdtMap(FormulaShare_Rule__mdt rule) {
        Map<String,SObject> mdMap = new Map<String,SObject>();
        mdMap.put(rule.DeveloperName, rule);
        return mdMap;
    }

    public static List<Metadata.Metadata> cmdtToMetadataList(FormulaShare_Rule__mdt rule) {
        // Get list of metadata type populated with object for the original rule for the mock
        Metadata.CustomMetadata md = cmdtToMetadata(rule, FormulaShare_Rule__mdt.SObjectType);
        List<Metadata.Metadata> mdList = new List<Metadata.Metadata>{ md };
        return mdList;
    }

    private static Metadata.CustomMetadata cmdtToMetadata(SObject cmdtRecord, Schema.SObjectType type) {

        Map<String, Schema.SObjectField> fieldsMap = type.getDescribe().fields.getMap();

        Metadata.CustomMetadata cmdt = new Metadata.CustomMetadata();
        cmdt.fullName = namespacePrefix + mdNamePrefix + cmdtRecord.get('DeveloperName');
        cmdt.label = (String) cmdtRecord.get('MasterLabel');
        
        for(String fieldName : fieldsMap.keySet()) {
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = fieldName;
            customField.value = cmdtRecord.get(fieldName);
            cmdt.values.add(customField);
        }

        return cmdt;
    }

}