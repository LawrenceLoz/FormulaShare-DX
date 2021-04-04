/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public inherited sharing class FormulaShareServiceSObjectRule {

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
