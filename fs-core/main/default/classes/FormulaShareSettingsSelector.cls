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

public inherited sharing class FormulaShareSettingsSelector {

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
    
    public List<String> getSObjectFieldList() {

        List<String> fields = new List<String> {
            'DeveloperName',
            'Trigger_Helper_Class_Override__c',
            'Log_Processing_Events__c',
            'Logs_Removal_Batch_Size__c',
            'Recalculation_Batch_Size__c',
            'Days_to_Retain_Batch_Logs__c',
            'Days_to_Retain_Record_Logs__c',
            'All_Record_Logs_Report_Name__c',
            'Record_Logs_Since_Last_Batch_Report_Name__c',
            'All_Record_Errors_Report_Name__c',
            'Rec_Errors_Since_Last_Batch_Report_Name__c',
            'Batch_Errors_Report_Name__c',
            'Allow_Recursive_Reassessment__c'
        };

        fields.addAll(new FormulaShareInjectionService().getExtraSettingsFields());
        return fields;
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
        for(String field : getSObjectFieldList()) {
            if(settingsToReturn.get(field) == null) {
                queryForDefaultSettings = true;
            }
        }

        // If so, query for the default settings
        if(queryForDefaultSettings) {
            FormulaShare_Settings__mdt defaultSettings = selectDefaultSettings()[0];

            // Set default values for blank fields
            for(String field : getSObjectFieldList()) {
                if(settingsToReturn.get(field) == null) {
                    settingsToReturn.put(field, defaultSettings.get(field));
                    system.debug('field: '+field);
                    system.debug('active setting new value = '+settingsToReturn.get(field));
                }
            }
        }

        return settingsToReturn;
    }


    // Custom metadata query results only used in apex assessment and not surfaced to users, so no need to enforce security
    private List<FormulaShare_Settings__mdt> selectActiveSettingsNoCache() {
        List<String> fields = getSObjectFieldList();
        String query = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ','))
            + ' FROM FormulaShare_Settings__mdt WHERE Active__c = true';
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(query);
        return settings;
    }

    // Custom metadata query results only used in apex assessment and not surfaced to users, so no need to enforce security
    private List<FormulaShare_Settings__mdt> selectDefaultSettings() {
        List<String> fields = getSObjectFieldList();
        String query = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ',')) 
            + ' FROM FormulaShare_Settings__mdt WHERE DeveloperName = \'Default\' LIMIT 1';
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(query);
        return settings;
    }

}