public virtual inherited sharing class FormulaShareRuleRelatedObject extends FormulaShareRule {

    public FormulaShareRuleRelatedObject(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        controllingObjectSharedToFieldType = mdRule.Child_Object_Shared_To_Field_Type__c;
    }

    public virtual override Boolean isValid() {
        // Validate basic checks and all relationships (beyond the shared object itself)
        return super.isValid() && relationship.nextRelationship.isValid();
    }
    
}
