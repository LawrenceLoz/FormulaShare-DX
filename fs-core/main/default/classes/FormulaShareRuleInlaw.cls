public inherited sharing class FormulaShareRuleInlaw extends FormulaShareRuleRelatedObject {

    public FormulaShareRuleInlaw(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'sibling';
    }

    public String bottomObject;
    // Set pathToSharedToField to path from bottom object to shared to field on top object for inlaw rule
    public String pathFromBottomObjToSharedObj;
    public String lookupFromBottomObjTowardsSharedObj;
    public String lookupFromBottomObjTowardsControllingObj;

}