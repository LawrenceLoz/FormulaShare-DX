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

public inherited sharing class FormulaShareRulesSelector {

// fflib selector patter isn't used because it fails for metadata relationship fields.
// The basic queries below are sufficient for now - FLS and sharing checks aren't needed 
// since custom metadata does not support either.

    public List<FormulaShare_Rule__mdt> selectRules(String objectName) {

        List<FormulaShare_Rule__mdt> rules = [SELECT Id, Access_Level__c, 
			Object_Shared__r.QualifiedApiName, Shared_To__r.QualifiedApiName, 
			Share_With__c, Sharing_Reason__c, Active__c, Shared_To_Field_Type__c
			FROM FormulaShare_Rule__mdt
			WHERE Object_Shared__r.QualifiedApiName = :objectName];
        return rules;
    }

    public List<FormulaShare_Rule__mdt> selectAllRules() {
        List<FormulaShare_Rule__mdt> rules  = [SELECT Object_Shared__r.QualifiedApiName FROM FormulaShare_Rule__mdt];
        return rules;
    }

}
