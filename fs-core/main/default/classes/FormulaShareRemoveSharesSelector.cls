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

public virtual inherited sharing class FormulaShareRemoveSharesSelector {

    public static FormulaShareRemoveSharesSelector construct() {
        return new FormulaShareRemoveSharesSelector();
    }

    // fflib selector pattern isn't used because it fails for metadata relationship fields.
    // Custom metadata query results only used in apex assessment and not surfaced to users, so no need to enforce security
    private static Map<String,FormulaShare_Std_Object_to_Remove_Shares__mdt> settingsForTypeMap = new Map<String,FormulaShare_Std_Object_to_Remove_Shares__mdt>();
    public FormulaShare_Std_Object_to_Remove_Shares__mdt getSettingsForType(Schema.sObjectType type) {
        FormulaShare_Std_Object_to_Remove_Shares__mdt objSettings;
        
        // Get settings from cache if we've queried already
        String objectName = type.getDescribe().getName();
        if(settingsForTypeMap.containsKey(objectName)) {
            objSettings = settingsForTypeMap.get(objectName);
        }

        // Otherwise query, and add to cache if a settings record exists
        else {
            List<FormulaShare_Std_Object_to_Remove_Shares__mdt> settingsList = getSettingsList(objectName);
            
            if(!settingsList.isEmpty()) {
                objSettings = settingsList[0];
                settingsForTypeMap.put(objectName, objSettings);
            }
        }

        return objSettings;
    }

    // Can be overridden to return additional fields
    // Custom metadata query results only used in apex assessment and not surfaced to users, so no need to enforce security
    public virtual List<FormulaShare_Std_Object_to_Remove_Shares__mdt> getSettingsList(String objectName) {
        return [     //NOPMD - Query is on custom metadata and results only used in apex so security check not required
            SELECT Id, Retain_Sharing_After_Record_Changes__c
            FROM FormulaShare_Std_Object_to_Remove_Shares__mdt
            WHERE Standard_Object_to_Remove_Sharing__r.QualifiedApiName = :objectName
            LIMIT 1];
    }

    public virtual Set<String> getObjectsWhereFullBatchUnsupported() {
        return new Set<String>();
    }

}
