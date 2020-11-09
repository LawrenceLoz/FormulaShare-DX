public inherited sharing class FormulaShareRuleDescendant extends FormulaShareRuleBottomObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleDescendant() {}

    public FormulaShareRuleDescendant(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'descendant';
        pathToSharedToField = mdRule.Shared_To__r.QualifiedApiName;
    }
}