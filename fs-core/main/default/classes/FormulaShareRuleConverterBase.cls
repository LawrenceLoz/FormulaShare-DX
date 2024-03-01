public abstract inherited sharing class FormulaShareRuleConverterBase {

    // Returns a rule of the approriate object
    public abstract FormulaShareRule getRule(FormulaShare_Rule__mdt mdRule);
    public abstract FormulaShare_Rule__mdt getMetadataRuleFromString(String fsRuleString);
    public abstract FormulaShare_Rule__mdt getMetadataRule(FormulaShareRule rule);

    
    // Maps fields which are common to all implementations from Rule to MD Rule
    protected FormulaShare_Rule__mdt getBasicMetadataRule(FormulaShareRule rule) {
        FormulaShare_Rule__mdt mdRule = new FormulaShare_Rule__mdt();
        mdRule.DeveloperName = rule.developerName;
        mdRule.MasterLabel = rule.label;
        mdRule.Description__c = rule.description;

        mdRule.Object_Shared__c = rule.objectSharedAPIName;

        mdRule.Share_With__c = rule.shareWith;
        mdRule.Access_Level__c = rule.accessLevel;
        mdRule.Contact_Access__c = rule.contactAccess;
        mdRule.Case_Access__c = rule.caseAccess;
        mdRule.Opportunity_Access__c = rule.opportunityAccess;
        mdRule.Sharing_Reason__c = rule.sharingReason;

        mdRule.Metadata_Mapping_Type__c = rule.mdMappingType;
        mdRule.Metadata_Mapping_Match_Field__c = rule.mdMappingMatchField;
        mdRule.Metadata_Mapping_Shared_To_Field__c = rule.mdMappingSharedToField;

        mdRule.Access_For_Team__c = rule.accessForTeam;
        mdRule.Access_For_Owner_Of_Teams_User_Is_On__c = rule.accessForOwnerOfTeamsUserIsOn;
        mdRule.Access_For_Team_Comembers__c = rule.accessForTeamComembers;

        return mdRule;
    }

}
