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

public inherited sharing class FormulaShareMetricsSelector extends fflib_SObjectSelector {

    public static FormulaShareMetricsSelector mock;
    public static FormulaShareMetricsSelector thisSelector;
    public static FormulaShareMetricsSelector construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else if(thisSelector == null) {
            thisSelector = new FormulaShareMetricsSelector();
        }
        return thisSelector;
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Metrics__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Metrics__c.Id,
            FormulaShare_Metrics__c.CreatedDate,
            FormulaShare_Metrics__c.Failed_Inserts__c,
            FormulaShare_Metrics__c.Last_Failed_Operation__c,
            FormulaShare_Metrics__c.Last_Successful_Operation__c,
            FormulaShare_Metrics__c.Last_Failed_Batch__c,
            FormulaShare_Metrics__c.Last_Successful_Batch__c,
            FormulaShare_Metrics__c.Successful_Inserts__c,
            FormulaShare_Metrics__c.Context__c,
            FormulaShare_Metrics__c.FormulaShare_Rule_Name__c,
            FormulaShare_Metrics__c.Last_Batch_Run__c
        };
    }

    public override String getOrderBy() {
        return 'CreatedDate';
    }

    public List<FormulaShare_Metrics__c> getAllMetricsForRules(Set<String> ruleNames) {
        List<FormulaShare_Metrics__c> metrics = (List<FormulaShare_Metrics__c>) Database.query(
            newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames')
            .toSOQL());
        return metrics;
    }

    public List<FormulaShare_Metrics__c> getMetricsForRulesAndContext(Set<String> ruleNames, String context) {
        List<FormulaShare_Metrics__c> metrics = (List<FormulaShare_Metrics__c>) Database.query(
            newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames AND Context__c = :context')
            .toSOQL());
            String query = newQueryFactory()
            .setCondition('FormulaShare_Rule_Name__c IN :ruleNames AND Context__c = :context')
            .toSOQL();
            system.debug('Query is: '+query);
        return metrics;
    }

}