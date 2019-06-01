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


// Interface implementation is used to enable dynamic routing to relevant class
global with sharing class FormulaShareHelper implements FormulaShareIHelper {

	private class FormulaShareException extends Exception{}
    @TestVisible private FormulaShareIHelper iHelper;
    private static FormulaShare_Settings__mdt settings;

    global FormulaShareHelper() {

        // Check that helper is called in a supported context
        if((!Trigger.isExecuting || (!Trigger.isAfter || (!Trigger.isInsert && !Trigger.isUpdate))) && !System.Test.isRunningTest()) {
			throw new FormulaShareException('Helper can only be called from an after insert or update trigger');
        }

        // Get the default class type to use
        Type impl = Type.forName('FormulaShareTriggerHelper');

        // If settings specify an override, use this instead
        if(settings == null) {
    		settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        }
		String helperOverrideClass = settings.Trigger_Helper_Class_Override__c;
        if(!String.isBlank(helperOverrideClass)) {
            Type overrideImpl = Type.forName(helperOverrideClass);
            if(overrideImpl != null) {
                impl = overrideImpl;
            }
        }

        // Dynamically instatiate the right implementation
        iHelper = (FormulaShareIHelper) impl.newInstance();
    }

    // Call relevant implementing class methods
    global List<SObject> getSharesToInsert() {
        return iHelper.getSharesToInsert();
    }

    global List<SObject> getSharesToDelete() {
        return iHelper.getSharesToDelete();
    }

}
