public with sharing class FormulaShareRuleStandard extends FormulaShareRule {

    public FormulaShareRuleStandard(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'standard';
        controllingObjectSharedToFieldType = mdRule.Shared_To_Field_Type__c;
        firstQueryStepApiName = mdRule.Shared_To__r.QualifiedApiName;
        pathToSharedToField = mdRule.Shared_To__r.QualifiedApiName;
    }

}