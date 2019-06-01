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
    public static FormulaShareSettingsSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareSettingsSelector();
        }
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Settings__mdt.DeveloperName,
            FormulaShare_Settings__mdt.Recalculation_Batch_Size__c,
            FormulaShare_Settings__mdt.Trigger_Helper_Class_Override__c};
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Settings__mdt.sObjectType;
    }

    // Return the single active setting
    public FormulaShare_Settings__mdt selectActiveSettings() {
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(
            newQueryFactory().
            setCondition('Active__c = true').
            setLimit(1).
            toSOQL());
        
        if(settings.isEmpty()) {
            throw new FormulaShareSettingsSelectorException();
        }

        else return settings[0];
    }

}