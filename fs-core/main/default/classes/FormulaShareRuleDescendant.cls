public inherited sharing class FormulaShareRuleDescendant extends FormulaShareRuleRelatedObject {

    public FormulaShareRuleDescendant(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'sibling';
        pathToSharedToField = mdRule.Shared_To__r.QualifiedApiName;
    }

    public String pathFromBottomObjToSharedObj;
    public String lookupFromBottomObjTowardsSharedObj;

}