/**
*Copyright 2019 Lawrence Newcombe
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


// Class variables are primitive types representing the FormulaShareRule custom metadata
// fields. This is required because mocking of custom metadata relationships isn't possible

public inherited sharing class FormulaShareRule {

	public class FormulaShareException extends Exception{}

    public Id ruleId;
    public String objectSharedAPIName;
    public String objectSharedLabel;
	public String sharedToAPIName;
	public String sharedToLabel;
	public String sharedToFieldToken;
	public String sharedToFieldType;
	public String shareWith;
	public String accessLevel;
	public Boolean active;
	public String sharingReason;
    public String childObjectWithSharedToFieldAPIName;
    public String childObjectWithSharedToFieldLabel;
    public String childObjectLookupFieldAPIName;
    public String childObjectSharedToFieldAPIName;
    public String childObjectSharedToFieldLabel;
    public String childObjectSharedToFieldToken;
    public String childObjectSharedToFieldType;
    public String label;
    public String developerName;
    public String description;
    public String contactAccess;
    public String caseAccess;
    public String opportunityAccess;


    
    // Used to create a share at the access levels of the rule, and appropriate values for the record and shared to entity
    public SObject getShareWithRuleDefaults(Schema.SObjectType type, Id recordId, Id sharedTo, Boolean contactIsControlledByAccount) {

		// Set access level names according to whether custom or standard
		Map<String,String> objectAccessLevels = new Map<String,String>();
        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        objectAccessLevels.put(objectUtils.accessLevelFieldName(), accessLevel);

        // For accounts, also set related access according to rule
        if(objectUtils.objectName == 'Account') {
            objectAccessLevels.put('CaseAccessLevel', caseAccess);
            objectAccessLevels.put('OpportunityAccessLevel', opportunityAccess);
    
            if(!contactIsControlledByAccount) {
                objectAccessLevels.put('ContactAccessLevel', contactAccess);
            }
        }

        return getShareRecordAtAccessLevels(type, recordId, sharedTo, objectAccessLevels);
    }


    public Boolean shareMatchesRulePermissions(Schema.SObjectType type, SOBject share, Boolean contactIsControlledByAccount) {

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

        // If object access doesn't match, return false
        if(accessLevel != objectAccess) {
            return false;
        }

        // If object is account need to check related objects
        if(objectUtils.objectName == 'Account') {
            AccountShare accShare = (AccountShare) share;

            // If case or opportunity access is different, return false
            if(caseAccess != accShare.CaseAccessLevel || opportunityAccess != accShare.OpportunityAccessLevel) {
                return false;
            }

            // If contact is controlled by account and contact access is different, return false
            else if(contactIsControlledByAccount && contactAccess != accShare.ContactAccessLevel) {
                return false;
            }
            return true;
        }
        return true;
    }


    // Used to create a share with the highest permissions of the rule and an existing provided share
    public SObject getMostPermissiveShare(Schema.SObjectType type, Id recordId, Id sharedTo, SObject currentShare, Boolean contactIsControlledByAccount) {

        Map<String,String> objectAccessLevels = new Map<String,String>();

        // Get highest level of access for object, and add to map
        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String accessLevelFieldName = objectUtils.accessLevelFieldName();
        String currentShareObjectAccess = (String) currentShare.get(accessLevelFieldName);
        String targetObjectAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentShareObjectAccess, accessLevel});

        objectAccessLevels.put(accessLevelFieldName, targetObjectAccess);

        // For account, also add case, opportunity and (if not controlled by account) contact access
        if(objectUtils.objectName == 'Account') {
            AccountShare currentAccShare = (AccountShare) currentShare;
            String targetCaseAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentAccShare.CaseAccessLevel, caseAccess});
            String targetOpportunityAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentAccShare.OpportunityAccessLevel, opportunityAccess});
            objectAccessLevels.put('CaseAccessLevel', targetCaseAccess);
            objectAccessLevels.put('OpportunityAccessLevel', targetOpportunityAccess);

            // Set contact sharing if contact is not controlled by account
            if(!contactIsControlledByAccount) {
                String targetContactAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentAccShare.ContactAccessLevel, contactAccess});
                objectAccessLevels.put('ContactAccessLevel', targetContactAccess);
            }
        }

        return getShareRecordAtAccessLevels(type, recordId, sharedTo, objectAccessLevels);
    }

    
    // Return a populated share record with access levels supplied and appropriate values for the record and shared to entity
    private SObject getShareRecordAtAccessLevels(Schema.SObjectType type, Id recordId, Id sharedTo, Map<String,String> objectAccessLevels) {

		SObject newShare = getShareAccessOnly(type, objectAccessLevels);

        // Populate values if object is custom
        if(type.getDescribe().isCustom()) {
            newShare.put('ParentId', recordId);
            newShare.put('UserOrGroupId', sharedTo);
            newShare.put('RowCause', sharingReason);
        }

        // Populate values if object is standard (format of share records is a bit different)
        else {
            newShare.put(type + 'Id', recordId);
            newShare.put('UserOrGroupId', sharedTo);
    //		newShare.put('RowCause','Manual');		// Only reason supported for standard objects is manual (set by default)
        }

		return newShare;
    }


	// Returns a share with only access levels populated. Relevant custom exceptions thrown if share can't be constructed
    private static SObject getShareAccessOnly(Schema.SObjectType type, Map<String,String> objectAccessLevels) {

		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);

		// Check share object exists
		if(shareType == null) {
			throw new FormulaShareException('No share object exists for '+type.getDescribe().getName()+'. This might be because org-wide defaults do not allow sharing');
		}

		// Check share can be constructed
        SObject newShare;
        try {
			newShare = shareType.newSObject();
		}
		catch(Exception e) {
			throw new FormulaShareException('Can\'t construct a share record of type '+shareType.getDescribe().getName());
		}

		// Check share can have provided access levels set
		for(String accessLevelFieldName : objectAccessLevels.keySet()) {
			try {
				newShare.put(accessLevelFieldName, objectAccessLevels.get(accessLevelFieldName));
			}
			catch(System.SObjectException e) {
				throw new FormulaShareException('Can\'t set '+accessLevelFieldName+' to '+objectAccessLevels.get(accessLevelFieldName)+'. This might be because organisation-wide defaults do not allow sharing at this level');
			}
		}

		return newShare;
	}


    public String type {
        get {
            if(childObjectWithSharedToFieldAPIName != null) {
                return 'child';
            }
            else {
                return 'standard';
            }
        }
    }

    public Boolean sharedObjectIsCustom {
        get {
            if(FormulaShareUtilities.describe(objectSharedAPIName).isCustom()) {
                return true;
            }
            else {
                return false;
            }
        }
    }

    public String sharedToAPINameForType {
        get {
            if(type == 'child') {
                return childObjectSharedToFieldAPIName;
            }
            else {
                return sharedToAPIName;
            }
        }
    }

    public String controllingObjectLabelForRuleType {
        get {
            if(type == 'child') {
                return childObjectWithSharedToFieldLabel;
            }
            else {
                return objectSharedLabel;
            }
        }
    }
    public String sharedToTokenForRuleType {
        get {
            return type == 'child' ? childObjectSharedToFieldToken : sharedToFieldToken;
        }
    }
    public String sharedToLabelRuleType {
        get {
            return type == 'child' ? childObjectSharedToFieldLabel : sharedToLabel;
        }
    }

    public String sharedToFieldTypeForRuleType {
        get {
            if(type == 'child') {
                return childObjectSharedToFieldType;
            }
            else {
                return sharedToFieldType;
            }
        }
    }

    public Boolean isValid {
        get {
            if(type == 'child'
                && childObjectWithSharedToFieldAPIName != null
                && childObjectLookupFieldAPIName != null
                && childObjectSharedToFieldAPIName != null
                && childObjectSharedToFieldType != null
                && passesBasicValidation()) {
                return true;
            }

            else if(type == 'standard'
                && sharedToAPIName != null
                && sharedToFieldType != null) {
                return true;
            }

            else return false;
        }
    }

    private Boolean passesBasicValidation() {
        if(objectSharedAPIName != null
            && shareWith != null
            && accessLevel != null
            && (!sharedObjectIsCustom || sharingReason != null)) {
            return true;
        }
        else return false;
    }

}