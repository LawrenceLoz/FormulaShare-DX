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

public inherited sharing class FormulaShareRetrievedRecordDetails {
    public SObject sharedRecord;
    public Map<String,List<SObject>> controllingRecordsForRulesMap;

    public FormulaShareRetrievedRecordDetails() {
        controllingRecordsForRulesMap = new Map<String,List<SObject>>();
    }

    public List<SObject> getControllingObjectsForRule(FormulaShareRule rule) {
        List<SObject> controllingObjectsForRule;

        System.debug('** getControllingObjectsForRule| Rule requested: '+rule.developerName);
        for(String ruleNAme: controllingRecordsForRulesMap.keySet()) {
            System.debug('** getControllingObjectsForRule| Rule in map: '+ruleNAme);
        }

        // When we KNOW related records are always required, we should never pass back records from the shared
        // object (fix in Aug 2024 to ensure multiple bottom object rules are processed correctly)
        if(rule.requiresRelatedRecords()) {
            if(controllingRecordsForRulesMap.containsKey(rule.developerName)) {
                controllingObjectsForRule = controllingRecordsForRulesMap.get(rule.developerName);
            }

            // If we don't have the rule represented in this controllingRecordsForRulesMap, pass back an empty list
            // This rule may be represented in another map processed at a different point
            else {
                controllingObjectsForRule = new List<SObject>();
            }
        }

        else {
            // If controlling records map doesn't include this rule (e.g. standard rule)
            // then controlling records are the shared records
            if(!controllingRecordsForRulesMap.containsKey(rule.developerName)) {
                controllingObjectsForRule = new List<SObject>{sharedRecord};
            }

            // Otherwise, controlling records should be set in map
            else {
                controllingObjectsForRule = controllingRecordsForRulesMap.get(rule.developerName);
            }
        }
        
        return controllingObjectsForRule;
    }
}