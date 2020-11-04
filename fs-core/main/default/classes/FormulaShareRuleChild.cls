public inherited sharing class FormulaShareRuleChild extends FormulaShareRuleRelatedObject {

    public FormulaShareRuleChild(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'child';
        setVars();
    }

    public String pathFromBottomObjToSharedObj;

    private void setVars() {
        pathFromBottomObjToSharedObj = relationship.nextRelationship.lookupToPrevObjectApiName;
    }

}