public inherited sharing class FormulaShareRulesSelector extends fflib_SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Rule__mdt.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Rule__mdt.Id,
            FormulaShare_Rule__mdt.Share_With__c
            };
    }

    // Return all rules with fields through join
    public List<FormulaShare_Rule__mdt> selectRules(String objectName) {

//        List<FSRulesInfo> ruleInfos = new List<FSRulesInfo>();

        List<FormulaShare_Rule__mdt> rules = (List<FormulaShare_Rule__mdt>) Database.query(
            newQueryFactory(false).
            selectField(FormulaShare_Rule__mdt.Id).
            selectField(FormulaShare_Rule__mdt.Share_With__c).
            selectField(FormulaShare_Rule__mdt.Sharing_Reason__c).
            selectField(FormulaShare_Rule__mdt.Active__c).
            selectField(FormulaShare_Rule__mdt.Shared_To_Field_Type__c).
            selectField('Object_Shared__r.QualifiedApiName').
            selectField('Shared_To__r.QualifiedApiName').
            setCondition('Object_Shared__r.QualifiedApiName = ' + objectName).
            toSOQL());
        
        return rules;
    }

    public List<FormulaShare_Rule__mdt> selectAllRules() {

        List<FormulaShare_Rule__mdt> rules = (List<FormulaShare_Rule__mdt>) Database.query(
            newQueryFactory(false).
            selectField('Object_Shared__r.QualifiedApiName').
            toSOQL());

		return rules;
    }

/*
    public class FSRulesInfo {
        private FormulaShare_Rule__mdt rule;
        public Id Id { get { return FormulaShare_Rule__mdt.Id; } }     
        public String Share_With__c { get { return FormulaShare_Rule__mdt.Share_With__c; } }        
        public String Sharing_Reason__c { get { return FormulaShare_Rule__mdt.Sharing_Reason__c; } }       
        public Boolean Active__c { get { return FormulaShare_Rule__mdt.Active__c; } }      
        public String Shared_To_Field_Type__c { get { return FormulaShare_Rule__mdt.Shared_To_Field_Type__c; } }       
        public String ObjectSharedQualifiedApiName { get { return FormulaShare_Rule__mdt.Object_Shared__r.QualifiedApiName; } }
        public String SharedToQualifiedApiName { get { return FormulaShare_Rule__mdt.Shared_To__r.QualifiedApiName; } }
        private FSRulesInfo(FormulaShare_Rule__mdt rule) { this.rule = rule; }         
    }

    */
}
