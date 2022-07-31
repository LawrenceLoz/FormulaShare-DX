public inherited sharing class FormulaShareRuleConverterStandard extends FormulaShareRuleConverterBase {

    // Returns a rule of the approriate object
    public override FormulaShareRule getRule(FormulaShare_Rule__mdt mdRule) {
        
        // Construct a rule from the appropriate subclass
        FormulaShareRule rule = new FormulaShareRuleStandard();

        rule.setRuleFromMetadata(mdRule);
        
        // Set controlling object fields
        rule.controllingObjectApiName = mdRule.Object_Shared__r.QualifiedApiName;
        rule.controllingObjectLabel = mdRule.Object_Shared__r.MasterLabel;
        rule.controllingObjectSharedToFieldAPIName = mdRule.Shared_To__r.QualifiedApiName;
        rule.controllingObjectSharedToFieldLabel = mdRule.Shared_To__r.QualifiedApiName;
        rule.controllingObjectSharedToFieldToken = mdRule.Shared_To__c;
        rule.controllingObjectSharedToFieldType = mdrule.Shared_To_Field_Type__c;

        rule.setVars();

        return rule;        
    }

    // Called during conversion to deploy custom metadata records
    public override FormulaShare_Rule__mdt getMetadataRuleFromString(String fsRuleString) {
        FormulaShareRule rule = (FormulaShareRule) JSON.deserialize(fsRuleString, FormulaShareRule.class);
        return getMetadataRule(rule);
    }

    // Map fields back to a metadata record and return this
    public override FormulaShare_Rule__mdt getMetadataRule(FormulaShareRule rule) {

        FormulaShare_Rule__mdt mdRule = super.getBasicMetadataRule(rule);

        mdRule.Shared_To__c = rule.controllingObjectSharedToFieldAPIName;
        mdRule.Shared_To_Field_Type__c = rule.controllingObjectSharedToFieldType;

        return mdRule;
    }

}
