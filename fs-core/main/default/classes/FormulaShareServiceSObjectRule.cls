public with sharing class FormulaShareServiceSObjectRule {

    // Holds details of a record and a rule sharing this record
    public SObject recordToShare;
    public SObject recordWithSharedToDetails;
    public String sharedToString;
    public FormulaShareRule rule;


    // Constructor for standard and ancestor rules
    public FormulaShareServiceSObjectRule(SObject recordToShare, FormulaShareRule rule) {
        this.recordToShare = recordToShare;
        this.recordWithSharedToDetails = recordToShare;
        this.rule = rule;
        if(rule.type == 'ancestor') {
            FormulaShareRuleAncestor ancestorRule = (FormulaShareRuleAncestor) rule;
            sharedToString = ancestorRule.getSharedToValueFromRecord(recordWithSharedToDetails);
            System.debug('sharedToString set from sibling object: '+ sharedToString + ' for rule: '+ rule.developerName +' and record with details: '+recordWithSharedToDetails);
        }
        else {
            sharedToString = (String) recordWithSharedToDetails.get(rule.controllingObjectSharedToFieldAPIName);
        }
    }


    // Constructor for sibling, descendant and inlaw rules (where we need to use details from a related record)
    public FormulaShareServiceSObjectRule(SObject recordToShare, SObject recordWithSharedToDetails, FormulaShareRule rule) {
        this.recordToShare = recordToShare;
        this.recordWithSharedToDetails = recordWithSharedToDetails;
        this.rule = rule;
        System.debug('Constructing SObjectRule for rule: '+rule.developerName);

        // For an inlaw rule, we need to dynamically traverse to the controlling object using tokens to get the shared field
        if(rule.type == 'inlaw') {
            FormulaShareRuleInlaw inlawRule = (FormulaShareRuleInlaw) rule;
            sharedToString = inlawRule.getSharedToValueFromRecord(recordWithSharedToDetails);
            System.debug('sharedToString set from inlaw object: '+ sharedToString + ' for rule: '+ rule.developerName +' and record with details: '+recordWithSharedToDetails);
        }

        // Otherwise (for sibling and descendant rules), we can get this directly
        else {
            sharedToString = (String) recordWithSharedToDetails.get(rule.controllingObjectSharedToFieldAPIName);
        }
    }

}
