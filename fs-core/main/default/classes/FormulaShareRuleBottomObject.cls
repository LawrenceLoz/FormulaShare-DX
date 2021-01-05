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

public virtual inherited sharing class FormulaShareRuleBottomObject extends FormulaShareRuleRelatedObject {

    // Allow direct construction from test context only
    @TestVisible
    protected FormulaShareRuleBottomObject() {}

    public FormulaShareRuleBottomObject(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {
        super(mdRule, rel, tacf);
        setVarsBottom();
        firstQueryStepApiName = lookupFromBottomObjTowardsSharedObj;
    }

    public String bottomObjectApiName;
    public String pathFromBottomObjToSharedObj;
    public String pathFromBottomObjToOwnerIdOnSharedObj; // Ends with the relationship of the
    public String lookupFromBottomObjTowardsSharedObj;
    protected FormulaShareSObjectRelationship bottomObjectRelationship;

    // Sequence of lookup fields needed to get from shared object to top object
    @TestVisible
    protected List<Schema.SObjectField> lookupFromBottomObjToSharedObjFieldList = new List<Schema.SObjectField>();

    @TestVisible
    private void setVarsBottom() {

        // Start from the first related object and field
        FormulaShareSObjectRelationship rel = relationship.nextRelationship;
        pathFromBottomObjToSharedObj = rel.lookupToPrevObjectApiName;
        List<Schema.SobjectField> lookupFieldListReverse = new List<Schema.SobjectField>();

        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
        Schema.sObjectField field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
        lookupFieldListReverse.add(field);

        String relationshipPathFromBottomObjToSharedObj = field.getDescribe().getRelationshipName();

        // Iterate until we're on the bottom object and add the relationship name (__r) of each lookup
        while(rel.nextRelationship?.lookupToPrevObjectApiName != null) {
            System.debug('Bottom rel intermediate rel towards bottom obj. Object: '+rel.thisObjectApiName+'. Rel: '+rel.nextRelationship);

            rel = rel.nextRelationship;

            // Add field to sequence of lookups
            type = FormulaShareUtilities.getSObjectTypeFromName(rel.thisObjectApiName);
            field = FormulaShareUtilities.getSObjectFieldFromName(rel.lookupToPrevObjectApiName, type);
            lookupFieldListReverse.add(field);

            // Add to path to shared object
            String relationshipName = field.getDescribe().getRelationshipName();
            pathFromBottomObjToSharedObj             = relationshipName + '.' + pathFromBottomObjToSharedObj;
            relationshipPathFromBottomObjToSharedObj = relationshipName + '.' + relationshipPathFromBottomObjToSharedObj;
        }

        // Populate object name and lookup field from final relationship, and set full path to ownerId
        bottomObjectRelationship = rel;
        bottomObjectApiName = rel.thisObjectApiName;
        lookupFromBottomObjTowardsSharedObj = rel.lookupToPrevObjectApiName;
        pathFromBottomObjToOwnerIdOnSharedObj = relationshipPathFromBottomObjToSharedObj + '.OwnerId';

        // Reverse lookup field list to be in correct order
        for(Integer i=0; i<lookupFieldListReverse.size(); i++) {
            lookupFromBottomObjToSharedObjFieldList.add(lookupFieldListReverse[lookupFieldListReverse.size() - 1 - i]);
        }
    }


    // Dynamically gets the value through in a set of lookups from a supplied record
    // Required because simple Contact__r.Account.Name style notation isn't supported for dyanmic checks
    public Id getOwnerOfSharedObjectFromBottomObject(SObject record) {

        FormulaShareRecordUtilities recordUtils = new FormulaShareRecordUtilities(record);
        SObject sharedRecord = recordUtils.getTopRecordFromLookup(lookupFromBottomObjToSharedObjFieldList);

        // Return the shared to field from this object
        return (Id) sharedRecord?.get('OwnerId');
    }

    public Id getSharedObjectIdFromBottomRecord(SObject record) {
        return FormulaShareRecordUtilities.getTopRecordIdFromFieldList(lookupFromBottomObjToSharedObjFieldList, record);
    }

}