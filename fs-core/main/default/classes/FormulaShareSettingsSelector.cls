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

public inherited sharing class FormulaShareSettingsSelector extends fflib_SObjectSelector {

	public class FormulaShareSettingsSelectorException extends Exception{}

    public static FormulaShareSettingsSelector mock;
    public static FormulaShareSettingsSelector thisSelector;
    public static FormulaShareSettingsSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else if(thisSelector == null) {
            thisSelector = new FormulaShareSettingsSelector();
        }
        return thisSelector;
    }

    private FormulaShare_Settings__mdt cachedSettings;
    
    public List<Schema.SObjectField> getSObjectFieldList() {

        List<Schema.SObjectField> fields = new List<Schema.SObjectField> {
            FormulaShare_Settings__mdt.DeveloperName,
            FormulaShare_Settings__mdt.Recalculation_Batch_Size__c,
            FormulaShare_Settings__mdt.Trigger_Helper_Class_Override__c,
            FormulaShare_Settings__mdt.Log_Processing_Events__c,
            FormulaShare_Settings__mdt.Logs_Removal_Batch_Size__c,
            FormulaShare_Settings__mdt.Recalculation_Batch_Size__c,
            FormulaShare_Settings__mdt.Days_to_Retain_Batch_Logs__c,
            FormulaShare_Settings__mdt.Days_to_Retain_Record_Logs__c,
            FormulaShare_Settings__mdt.All_Record_Logs_Report_Name__c,
            FormulaShare_Settings__mdt.Record_Logs_Since_Last_Batch_Report_Name__c,
            FormulaShare_Settings__mdt.All_Record_Errors_Report_Name__c,
            FormulaShare_Settings__mdt.Rec_Errors_Since_Last_Batch_Report_Name__c,
            FormulaShare_Settings__mdt.Batch_Errors_Report_Name__c,
            FormulaShare_Settings__mdt.Allow_Recursive_Reassessment__c
        };

        fields.addAll(new FormulaShareInjectionService().getExtraSettingsFields());
        return fields;
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Settings__mdt.sObjectType;
    }


    // Cache and return the single active setting
    public FormulaShare_Settings__mdt selectActiveSettings() {

        if(cachedSettings == null) {
            FormulaShare_Settings__mdt settings = getSettingsForCache();
            
            if(settings == null) {
                throw new FormulaShareSettingsSelectorException();
            }
            else {
                cachedSettings = settings;
            }
        }

        return cachedSettings;
    }


    private FormulaShare_Settings__mdt getSettingsForCache() {
        
        // Query for settings set to active
        List<FormulaShare_Settings__mdt> activeSettings = selectActiveSettingsNoCache();

        system.debug(activeSettings.size());

        // If only the default setting is found, return this
        if(activeSettings.size() == 1 && activeSettings[0].DeveloperName == 'Default') {
            system.debug(activeSettings[0]);
            return activeSettings[0];
        }

        // Otherwise, use the first active settings which isn't the default
        FormulaShare_Settings__mdt settingsToReturn;
        for(FormulaShare_Settings__mdt settings : activeSettings) {
            if(settings.DeveloperName != 'Default') {
                settingsToReturn = settings;
                system.debug('User defined active settings: ' + settingsToReturn);
                break;
            }
        }

        // Check whether any settings are blank
        Boolean queryForDefaultSettings;
        for(Schema.SObjectField field : getSObjectFieldList()) {
            if(settingsToReturn.get(field) == null) {
                queryForDefaultSettings = true;
            }
        }

        // If so, query for the default settings
        if(queryForDefaultSettings) {
            FormulaShare_Settings__mdt defaultSettings = selectDefaultSettings()[0];

            // Set default values for blank fields
            for(Schema.SObjectField field : getSObjectFieldList()) {
                if(settingsToReturn.get(field) == null) {
                    settingsToReturn.put(field, defaultSettings.get(field));
                    system.debug('field: '+field);
                    system.debug('active setting new value = '+settingsToReturn.get(field));
                }
            }
        }

        return settingsToReturn;
    }


    private List<FormulaShare_Settings__mdt> selectActiveSettingsNoCache() {
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(
            newQueryFactory().
            setCondition('Active__c = true').
            toSOQL());
        return settings;
    }

    private List<FormulaShare_Settings__mdt> selectDefaultSettings() {
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(
            newQueryFactory().
            setCondition('DeveloperName = \'Default\'').
            setLimit(1).
            toSOQL());
        return settings;
    }

}