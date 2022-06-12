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

public virtual inherited sharing class FormulaShareRuleAncestor extends FormulaShareRuleRelatedObject {

    // Allow direct construction from test context only
    @TestVisible
    private FormulaShareRuleAncestor() {}
        
    public FormulaShareRuleAncestor(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        type = 'ancestor';
        setVars();
    }

    // Sequence of lookup fields needed to get from shared object to top object
    // pathToObjectWithSharedToField set to relationship between shared object and top object
    @TestVisible
    private List<Schema.SObjectField> lookupFromSharedObjToControllingObjFieldList = new List<Schema.SObjectField>();

    private void setVars() {

        // Field to check in queries (lookup from shared obj to next obj) is indicated in the second element of the relationship list
        firstQueryStepApiName = relationship.nextRelationship.lookupFromPrevObjectApiName;
        pathToOwnerIdOnShared = 'OwnerId';

        String prevObjApiName = objectSharedAPIName;
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        String pathToObjectWithSharedToField = '';

        // Iterate until we're at the top (no further relationships, or next relationship isn't a lookup from last)
        while(rel.nextRelationship != null) {
    
            // Concatenate field path
            if(rel.lookupFromPrevObjectApiName != null) {
                Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
                Schema.SObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
                lookupFromSharedObjToControllingObjFieldList.add(field);
                pathToObjectWithSharedToField += field.getDescribe().getRelationshipName() + '.';
            }
    
            prevObjApiName = rel.thisObjectApiName;
            rel = rel.nextRelationship;
        }

        // Add relationship and shared to field from final relationship
        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(prevObjApiName);
        Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupFromPrevObjectApiName, type);
        lookupFromSharedObjToControllingObjFieldList.add(field);
        pathToObjectWithSharedToField += field.getDescribe().getRelationshipName() + '.';

        // Shared to field will be queried from shared object, so add with relationship prefix
        pathToSharedToField = pathToObjectWithSharedToField + controllingObjectSharedToFieldAPIName;
    }


    // Dynamically gets the value through in a set of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public String getSharedToValueFromRecord(SObject record) {

        FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
        SObject topRecord = recordUtils.getTopRecordFromLookup(lookupFromSharedObjToControllingObjFieldList);

        // Return the shared to field from this object
        return (String) topRecord?.get(controllingObjectSharedToFieldAPIName);
    }

}