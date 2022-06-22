/**
*Copyright 2022 Lawrence Newcombe
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

public inherited sharing class FormulaShareMetadataDMLRulesAccount extends FormulaShareMetadataDMLRules {

    public FormulaShareMetadataDMLRulesAccount() {
        super();
        configureBase();
    }
    @TestVisible
    private FormulaShareMetadataDMLRulesAccount(FormulaShareMetadataBroker broker) {
        super(broker);
        configureBase();
    }

    private void configureBase() {

        this.fieldsToSet = new Set<String> {
            namespacePrefix + 'Active__c',
            namespacePrefix + 'Description__c',
            namespacePrefix + 'Object_Shared__c',
            namespacePrefix + 'Share_With__c',
            namespacePrefix + 'Access_Level__c',
            namespacePrefix + 'Sharing_Reason__c',

            // Only difference to FormulaShareMetadataDMLRules is that Contact, Case 
            // and Opp Access are set rather than cleared
            namespacePrefix + 'Contact_Access__c',
            namespacePrefix + 'Case_Access__c',
            namespacePrefix + 'Opportunity_Access__c'
        };

        this.fieldsToClear = new Set<String>();

        this.fieldsToSetOrClear = new Set<String> {
            namespacePrefix + 'Shared_To_Field_Type__c',
            namespacePrefix + 'Shared_To__c'
        };
        this.fieldsToSetOrClear.addAll(new FormulaShareInjectionService().getExtraRelationshipFields());

        this.mdNamePrefix = 'FormulaShare_Rule.';
    }
}
