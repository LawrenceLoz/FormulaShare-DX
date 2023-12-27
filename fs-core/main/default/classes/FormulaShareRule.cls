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

// Class is virtual only to allow construction of concrete object from string for metadata deployment 
// (via JSON.deserialize() in FormulaShareMetadataControllerRules.ruleStringToRule)
public virtual inherited sharing class FormulaShareRule {

	public class FormulaShareException extends Exception{}

    // Basic rule details
    @AuraEnabled public Id ruleId;
    @AuraEnabled public String label;
    @AuraEnabled public String developerName;
    @AuraEnabled public String description;
	@AuraEnabled public Boolean active;

    // Sharing configuration
    @AuraEnabled public String shareWith;
	@AuraEnabled public String accessLevel;
    @AuraEnabled public String sharingReason;
    @AuraEnabled public String contactAccess;
    @AuraEnabled public String caseAccess;
    @AuraEnabled public String opportunityAccess;

    // Object to share, and relationship path to object with controlling field (if not shared object)
    @AuraEnabled public String objectSharedAPIName;
    @AuraEnabled public String objectSharedLabel;

    // Name of the rule type (standard, ancestor, inlaw etc)
    @AuraEnabled public String type;

    // Details of controlling object and field
    // This will be on the shared object if no relationships
    // Or the last entry of the relationship tree if populated
    @AuraEnabled public String controllingObjectApiName;
    @AuraEnabled public String controllingObjectLabel;
    @AuraEnabled public String controllingObjectSharedToFieldAPIName;
    @AuraEnabled public String controllingObjectSharedToFieldLabel;
    @AuraEnabled public String controllingObjectSharedToFieldToken;
    @AuraEnabled public String controllingObjectSharedToFieldType;

    @AuraEnabled public String accessForTeam;
    @AuraEnabled public String accessForOwnerOfTeamsUserIsOn;
    @AuraEnabled public String accessForTeamComembers;

    // **************** Variables to support trigger assessment ************** //

    // Populates with the field which might be relevant to a sharing change for a trigger
    // Set to:
    // - Shared to field for standard rule
    // - Path from shared object to first parent for ancestor rule
    // - Path from bottom object to first object towards shared object for descendant / inlaw
    public String firstQueryStepApiName;

    // The full relationship from the queried object to shared to field
    // - Shared to field on controlling object for standard, sibling and descendant
    // - Path from shared object to shared to field on top object for ancestor
    // - Path from bottom object to shared to field on top object for inlaw
    public String pathToSharedToField;
    
    // Full relationship from the queried object to shared object
    // - null for standard, sibling and ancestor
    // - Path from bottom object to shared object for descendant and inlaw
    public String pathToSharedObject;

    // Full relationship from the shared object to fields relevant to finding shared to value
    // - Shared to field for standard
    // - Path to shared to field for ancestor
    // - Path to top object for sibling
    // - null for descendant and inlaw
    public String pathFromSharedObject;

    // Full relationship from the queried object to owner on shared object
    // - OwnerId for standard and ancestor
    // - Path from bottom object to OwnerId on shared object for descendant and inlaw
    public String pathToOwnerIdOnShared;

    // *********************************************************************** //

    // Map to rule object from rule metadata
    // Note this doesn't set relationship or controllingObject variables - these need to be set directly
    public void setRuleFromMetadata(FormulaShare_Rule__mdt rule) {

        // Basic rule details
        ruleId = rule.Id;
        label = rule.MasterLabel;
        developerName = rule.DeveloperName;
        description = rule.Description__c;
        active = rule.Active__c;
        
        // Sharing configuration
        shareWith = rule.Share_With__c;
        accessLevel = rule.Access_Level__c;
        sharingReason = rule.Sharing_Reason__c;
        contactAccess = rule.Contact_Access__c;
        caseAccess = rule.Case_Access__c;
        opportunityAccess = rule.Opportunity_Access__c;

        // Access levels for default team sharing
        accessForTeam = rule.Access_For_Team__c;
        accessForOwnerOfTeamsUserIsOn = rule.Access_For_Owner_Of_Teams_User_Is_On__c;
        accessForTeamComembers = rule.Access_For_Team_Comembers__c;

        // Object to share
        objectSharedAPIName = rule.Object_Shared__r.QualifiedApiName;
        objectSharedLabel = rule.Object_Shared__r.MasterLabel;
    }

    
    // Implement in subclasses to set variables specific to rule type (generally called after variables are set from metadata)
    public virtual void setVars() {}


    // For most rule types, the record with details for sharing has these details directly in a field on the record
    // For inlaw and ancestor rules though, we need to override to traverse lookups
    public virtual String getSharedToValueFromRecord(SObject recordWithSharedToDetails) {
        return (String) recordWithSharedToDetails.get(controllingObjectSharedToFieldAPIName);
    }


    // Overriden and referenced for non-standard implementations
    public virtual Boolean isValid() {
        if(objectSharedAPIName != null
            && controllingObjectSharedToFieldAPIName != null
            && controllingObjectSharedToFieldType != null
            && shareWith != null
            && accessLevel != null
            && (!sharedObjectIsCustom || sharingReason != null)) {
            return true;
        }

        else {
            System.debug('isValid() fail: One or more of the following is null: '
            + 'objectSharedAPIName: '+objectSharedAPIName
            + ', controllingObjectSharedToFieldAPIName: '+controllingObjectSharedToFieldAPIName
            + ', controllingObjectSharedToFieldType: '+controllingObjectSharedToFieldType
            + ', shareWith: '+shareWith
            + ', accessLevel: '+accessLevel
            + ', sharingReason: '+sharingReason);
            return false;
        }
    }

    // Returns list of all objects where trigger assessment could result in changes to shared object sharing
    public virtual List<String> getTriggeringObectNames() {
        return new List<String>();
    }

    // Used to create a share at the access levels of the rule, and appropriate values for the record and shared to entity
    public SObject getShareWithRuleDefaults(Schema.SObjectType type, Id recordId, Id sharedTo, String targetAccessLevel, Boolean contactIsControlledByAccount) {

		// Set access level names according to whether custom or standard
		Map<String,String> objectAccessLevels = new Map<String,String>();
        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        objectAccessLevels.put(objectUtils.accessLevelFieldName(), targetAccessLevel);

        // For accounts, also set related access according to rule
        if(objectUtils.objectName == 'Account') {
            objectAccessLevels.put('CaseAccessLevel', caseAccess);
            objectAccessLevels.put('OpportunityAccessLevel', opportunityAccess);
    
            if(!contactIsControlledByAccount) {
                objectAccessLevels.put('ContactAccessLevel', contactAccess);
            }
        }

        return getShareRecordAtAccessLevels(objectUtils, recordId, sharedTo, objectAccessLevels);
    }


    // Check if all share levels in a share object are equal to the rule
    public Boolean shareEqualToRule(Schema.SObjectType type, SOBject share, String targetAccessLevel, Boolean contactIsControlledByAccount) {

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

        if(targetAccessLevel != objectAccess) {
            return false;
        }

        // If object is account need to check related objects
        if(objectUtils.objectName == 'Account') {

            // If case or opportunity access is different, return false
            if(caseAccess != (String) share.get('CaseAccessLevel')) {
                return false;
            }
            else if(opportunityAccess != (String) share.get('OpportunityAccessLevel')) {
                return false;
            }

            // If contact is NOT controlled by account and contact access is different, return false
            else if(!contactIsControlledByAccount && contactAccess != (String) share.get('ContactAccessLevel')) {
                return false;
            }
            return true;
        }
        return true;        
    }


    // Check if all share levels in a share object are equal to or provide wider access than the rule
    public Boolean shareEqualOrMorePermissiveThanRule(Schema.SObjectType type, SOBject share, String targetAccessLevel, Boolean contactIsControlledByAccount) {

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

        if(FormulaShareUtilities.accessLevelIsHigher(targetAccessLevel, objectAccess)) {
            return false;
        }

        // If object is account need to check related objects
        if(objectUtils.objectName == 'Account') {

            // If case or opportunity access is different, return false
            if(FormulaShareUtilities.accessLevelIsHigher(caseAccess, (String) share.get('CaseAccessLevel'))) {
                return false;
            }
            else if(FormulaShareUtilities.accessLevelIsHigher(opportunityAccess, (String) share.get('OpportunityAccessLevel'))) {
                return false;
            }

            // If contact is NOT controlled by account and contact access is different, return false
            else if(!contactIsControlledByAccount && FormulaShareUtilities.accessLevelIsHigher(contactAccess, (String) share.get('ContactAccessLevel'))) {
                return false;
            }
            return true;
        }
        return true;
    }

    // Used to create a share with the highest permissions of the rule and an existing provided share
    public SObject getMostPermissiveShare(Schema.SObjectType type, Id recordId, Id sharedTo, String targetAccessLevel, SObject currentShare, Boolean contactIsControlledByAccount) {

        Map<String,String> objectAccessLevels = new Map<String,String>();

        // Get highest level of access for object, and add to map
        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String accessLevelFieldName = objectUtils.accessLevelFieldName();
        String currentShareObjectAccess = (String) currentShare.get(accessLevelFieldName);
        String targetObjectAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentShareObjectAccess, targetAccessLevel});

        objectAccessLevels.put(accessLevelFieldName, targetObjectAccess);

        // For account, also add case, opportunity and (if not controlled by account) contact access
        if(objectUtils.objectName == 'Account') {
            String currentCaseAccess = (String) currentShare.get('CaseAccessLevel');
            String currentOpportunityAccess = (String) currentShare.get('OpportunityAccessLevel');
            String targetCaseAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentCaseAccess, caseAccess});
            String targetOpportunityAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentOpportunityAccess, opportunityAccess});
            objectAccessLevels.put('CaseAccessLevel', targetCaseAccess);
            objectAccessLevels.put('OpportunityAccessLevel', targetOpportunityAccess);

            // Set contact sharing if contact is not controlled by account
            if(!contactIsControlledByAccount) {
                String currentContactAccess = (String) currentShare.get('ContactAccessLevel');
                String targetContactAccess = FormulaShareUtilities.getHighestAccess(new List<String>{currentContactAccess, contactAccess});
                objectAccessLevels.put('ContactAccessLevel', targetContactAccess);
            }
        }

        return getShareRecordAtAccessLevels(objectUtils, recordId, sharedTo, objectAccessLevels);
    }

    
    // Return a populated share record with access levels supplied and appropriate values for the record and shared to entity
    private SObject getShareRecordAtAccessLevels(FormulaShareSObjectUtilities objectUtils, Id recordId, Id sharedTo, Map<String,String> objectAccessLevels) {

        // Get a share record with access level (or levels) set
		SObject newShare = getShareAccessOnly(objectUtils.type, objectAccessLevels);

        // Populate lookup to parent (either ParentId or ObjectNameId) and entity to get access
        newShare.put(objectUtils.parentIdFieldName(), recordId);
        newShare.put('UserOrGroupId', sharedTo);

        // Populate row cause if object is custom (manual is set by default for standard objects)
        if(objectUtils.type.getDescribe().isCustom()) {
            newShare.put('RowCause', sharingReason);
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

}