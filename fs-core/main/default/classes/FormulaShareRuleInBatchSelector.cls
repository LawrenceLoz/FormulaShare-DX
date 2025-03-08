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

public inherited sharing class FormulaShareRuleInBatchSelector extends fflib_SObjectSelector {

    private final Integer QUERY_LIMIT = 10000;

    public List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

    public FormulaShareRuleInBatchSelector(Boolean enforceObjectAndFieldSecurity) {
        super(false // Do not include FieldSet fields
            , enforceObjectAndFieldSecurity // Enforce field security if requested
            , enforceObjectAndFieldSecurity // Enforce object security if requested
            );
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return fields;
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Rule_in_Batch__c.sObjectType;
    }

    public List<FormulaShare_Rule_in_Batch__c> getLogsForRules(List<String> ruleNames) {
        return Database.query(
            newQueryFactory(false).
            selectField(FormulaShare_Rule_in_Batch__c.FormulaShare_Rule_Name__c).
            selectField(FormulaShare_Rule_in_Batch__c.Rule_Active_for_Batch_Run__c).
            selectField(FormulaShare_Rule_in_Batch__c.Records_Shared_in_This_Batch__c).
            selectField(FormulaShare_Rule_in_Batch__c.Record_Errors_in_This_Batch__c).
            selectField(FormulaShare_Rule_in_Batch__c.Total_Records_Shared_by_Rule__c).
            selectField('FormulaShare_Log__r.Processing_Started__c').
            selectField('FormulaShare_Log__r.Processing_Finished__c').
            selectField('FormulaShare_Log__r.Batch_Finish_Complete__c').
            setCondition('FormulaShare_Rule_Name__c IN :ruleNames').
            setLimit(QUERY_LIMIT).
            toSOQL());
    }

    public List<RuleRunDetail> getRuleRuns(List<String> ruleNames) {
        List<RuleRunDetail> rrDetails = new List<RuleRunDetail>();
        for(FormulaShare_Rule_in_Batch__c rib : getLogsForRules(ruleNames)) {
            rrDetails.add(new RuleRunDetail(rib));
        }
        
        return rrDetails;
    }

    public inherited sharing class RuleRunDetail {
        public FormulaShare_Rule_in_Batch__c rib;
        public RuleRunDetail(FormulaShare_Rule_in_Batch__c rib) { this.rib = rib; }
        public String developerName { get { return rib.FormulaShare_Rule_Name__c; } }
        public Boolean ruleActive { get { return rib.Rule_Active_for_Batch_Run__c; } }
        public Datetime processingStarted { get { return rib.FormulaShare_Log__r.Processing_Started__c; } }
        public Datetime processingFinished { get { return rib.FormulaShare_Log__r.Processing_Finished__c; } }
        public Boolean batchFinishComplete { get { return rib.FormulaShare_Log__r.Batch_Finish_Complete__c; } }
    }

}