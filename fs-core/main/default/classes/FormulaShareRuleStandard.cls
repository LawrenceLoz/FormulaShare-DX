public inherited sharing class FormulaShareRuleStandard extends FormulaShareRule {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleStandard() {}

    public FormulaShareRuleStandard(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'standard';

        // Shared to type is in the field relating to a standard rule
        controllingObjectSharedToFieldType = mdRule.Shared_To_Field_Type__c;

        // Share field will be queried from controlling/shared object, so add without relationship
        pathToSharedToField = controllingObjectSharedToFieldAPIName;
        firstQueryStepApiName = controllingObjectSharedToFieldAPIName;
    }

}