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

public inherited sharing class FormulaShareSObjectUtilities {

    public Schema.SObjectType type;
    public Schema.DescribeSObjectResult typeDescribe;
    public Boolean isCustom;
    public String objectName;
    private Boolean removeSharesForObject;

    public FormulaShareSObjectUtilities(Schema.SObjectType type) {
        this.type = type;
        this.typeDescribe = type.getDescribe();
        this.isCustom = typeDescribe.isCustom();
        this.objectName = typeDescribe.getName();
    }

	public String accessLevelFieldName() {

        // Custom objects will always include AccessLevel
        if(isCustom) {
            return 'AccessLevel';
        }

        // Most standard objects have a field called "ObjectNameAccessLevel"
        else if(shareObjectHasField(objectName + 'AccessLevel')) {
            return objectName + 'AccessLevel';
        }

        // But for some (e.g. Work Order) this is just called "AccessLevel"
        else if(shareObjectHasField('AccessLevel')) {
            return 'AccessLevel';
        }

        else {
            throw new FormulaShareRule.FormulaShareException('Share object for '+objectName+' does not include field with expected format ('+objectName+'AccessLevel or AccessLevel)');
        }
    }

	public String parentIdFieldName() {

        // Custom objects will always include ParentId
        if(isCustom) {
            return 'ParentId';
        }

        // Most standard objects have a field called "ObjectNameAccessLevel"
        else if(shareObjectHasField(objectName + 'Id')) {
            return objectName + 'Id';
        }

        // But for some (e.g. Work Order) this is just called "ParentId"
        else if(shareObjectHasField('ParentId')) {
            return 'ParentId';
        }

        else {
            throw new FormulaShareRule.FormulaShareException('Share object for '+objectName+' does not include access level rule with expected format ('+objectName+'Id or ParentId)');
        }
    }

    private Boolean shareObjectHasField(String fieldName) {
        Schema.SObjectType shareObj = FormulaShareUtilities.getShareObject(type);
        return FormulaShareUtilities.getSObjectFieldFromName(fieldName, shareObj) != null;
    }

	public String getShareKey(SObject share) {
        String shareKeyBase = getShareKeyBase(share);

        // Only custom objects allow for a custom RowCause (apex sharing reason)
        if(isCustom) {
            String rowCause = (String) share.get('RowCause');
            String shareKey = shareKeyBase + rowCause;
            return shareKey;
        }
        else {
            return shareKeyBase;
        }
    }
    
    private String getShareKeyBase(SObject share) {
        System.debug('share base: '+share);
		Id parentId = (Id) share.get(parentIdFieldName());
		Id userOrGroupId = (Id) share.get('UserOrGroupId');
        System.debug('share parentId: '+parentId);
		String parentId15 = FormulaShareIdUtilities.get15CharacterId(parentId);
        System.debug('share parentId15: '+parentId15);
		String userOrGroupId15 = FormulaShareIdUtilities.get15CharacterId(userOrGroupId);
        String shareKeyBase = parentId15 + userOrGroupId15;
        return shareKeyBase;
    }

    public Boolean removeSharesForObject() {
        if(removeSharesForObject == null) {

            FormulaShareRemoveSharesSelector selector = FormulaShareRemoveSharesSelector.construct();
            List<FormulaShare_Std_Object_to_Remove_Shares__mdt> objSettings = selector.getSettingsForType(type);

            // If explicit settings, default to:
            //  - Remove for custom objects, as we distinguish FS sharing by row cause
            //  - Do not remove for standard objects, as we can't distinguish FS sharing from other apex/manual sharing
            if(objSettings.isEmpty()) {
                removeSharesForObject = isCustom;
            }

            // If settings exist, determing whether to remove based on the retain setting (we assume only a single settings record per object)
            else {
                removeSharesForObject = !objSettings[0].Retain_Sharing_After_Record_Changes__c;
            }
        }
        return removeSharesForObject;
    }
}