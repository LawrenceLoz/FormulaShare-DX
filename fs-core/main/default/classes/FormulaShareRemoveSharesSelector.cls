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

public inherited sharing class FormulaShareRemoveSharesSelector {

    public static FormulaShareRemoveSharesSelector construct() {
        return new FormulaShareRemoveSharesSelector();
    }

    // fflib selector pattern isn't used because it fails for metadata relationship fields.
    // The basic query below is sufficient - FLS and sharing checks aren't needed 
    // since custom metadata does not support either.
    public List<FormulaShare_Std_Object_to_Remove_Shares__mdt> getSettingsForType(Schema.sObjectType type) {

		String objectName = type.getDescribe().getName();

		List<FormulaShare_Std_Object_to_Remove_Shares__mdt> removalLinesToReturn = 
            [SELECT Id, Retain_Sharing_After_Record_Changes__c
			FROM FormulaShare_Std_Object_to_Remove_Shares__mdt
			WHERE Standard_Object_to_Remove_Sharing__r.QualifiedApiName = :objectName];

        return removalLinesToReturn;
    }

    public List<FormulaShare_Std_Object_to_Remove_Shares__mdt> getAllSettings() {
        return [
            SELECT Id, Standard_Object_to_Remove_Sharing__r.QualifiedApiName, Retain_Sharing_After_Record_Changes__c
            FROM FormulaShare_Std_Object_to_Remove_Shares__mdt
        ];
    }
}
