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

public virtual inherited sharing class FormulaShareRule {

	public class FormulaShareException extends Exception{}

    // Basic rule details
    public Id ruleId;
    public String label;
    public String developerName;
    public String description;
	public Boolean active;

    // Sharing configuration
    public String shareWith;
	public String accessLevel;
    public String sharingReason;
    public String contactAccess;
    public String caseAccess;
    public String opportunityAccess;

    // Object to share, and relationship path to object with controlling field (if not shared object)
    public String objectSharedAPIName;
    public String objectSharedLabel;
    public FormulaShareSObjectRelationship relationship;
    public String type;

    // Details of controlling object and field
    // This will be on the shared object if no relationships
    // Or the last entry of the relationship tree if populated
    public String controllingObjectApiName;
    public String controllingObjectLabel;
    public String controllingObjectSharedToFieldAPIName;
    public String controllingObjectSharedToFieldLabel;
    public String controllingObjectSharedToFieldToken;
    public String controllingObjectSharedToFieldType;

    // Populates with the field which might be relevant to a sharing change for a trigger
    // Set to:
    // - Shared to field for standard rule
    // - Path from shared object to first parent for ancestor rule
    // - Path from bottom object to first object towards shared object for descendant / inlaw
    public String firstQueryStepApiName;

    // Populates with the path from the queried object to shared to field
    // Set to:
    // - Shared to field for standard, sibling and descendant
    // - Path from shared object to shared to field on top object for ancestor rule
    // - Path from bottom object to shared to field on top object for inlaw rule
    public String pathToSharedToField;

    // Allow direct construction from test context only
    @TestVisible
    protected FormulaShareRule() {}

    // Constructor manages mapping from rule metadata
    public FormulaShareRule(FormulaShare_Rule__mdt rule, FormulaShareSObjectRelationship rel, TypeAndControllingFields tacf) {

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

        // Object to share
        objectSharedAPIName = rule.Object_Shared__r.QualifiedApiName;
        objectSharedLabel = rule.Object_Shared__r.MasterLabel;
        relationship = rel;

        // Controlling type and fields
        controllingObjectApiName = tacf.controllingObjectApiName;
        controllingObjectLabel = tacf.controllingObjectLabel;
        controllingObjectSharedToFieldAPIName = tacf.controllingObjectSharedToFieldAPIName;
        controllingObjectSharedToFieldLabel = tacf.controllingObjectSharedToFieldLabel;
        controllingObjectSharedToFieldToken = tacf.controllingObjectSharedToFieldToken;
    }


    // Returns a rule of the approriate object
    public static FormulaShareRule getRule(FormulaShare_Rule__mdt mdRule) {
        
        // Establish relationship object, and get the controlling fields and rule type
        FormulaShareSObjectRelationship rel = getrelationship(mdRule);
        TypeAndControllingFields tacf = getControllingFieldsAndType(rel);

        // Instantiate rule of appropriate type (constructors populate type specific variables)
        FormulaShareRule rule;
        switch on tacf.ruleType {
            when 'standard' {
                rule = new FormulaShareRuleStandard(mdRule, rel, tacf);
            }
            when 'descendant' {
                rule = new FormulaShareRuleDescendant(mdRule, rel, tacf);
            }
            when 'ancestor' {
                rule = new FormulaShareRuleAncestor(mdRule, rel, tacf);
            }
            when 'sibling' {
                rule = new FormulaShareRuleSibling(mdRule, rel, tacf);
            }
            when 'inlaw' {
                rule = new FormulaShareRuleInlaw(mdRule, rel, tacf);
            }
        }

        return rule;
    }


    public class TypeAndControllingFields {
        String ruleType;
        String controllingObjectApiName;
        String controllingObjectLabel;
        String controllingObjectSharedToFieldAPIName;
        String controllingObjectSharedToFieldLabel;
        String controllingObjectSharedToFieldToken;
    }


    // Set controlling field details - find deepest relationship and set shared to details from this
    private static TypeAndControllingFields getControllingFieldsAndType(FormulaShareSObjectRelationship relationship) {
        TypeAndControllingFields tacf = new TypeAndControllingFields();
        tacf.ruleType = 'standard';
        FormulaShareSObjectRelationship rel = relationship;
        Boolean previousObjectIsChild = false;
        Boolean previousObjectIsParent = false;
        while(rel.nextRelationship != null) {
            rel = rel.nextRelationship;

            // If this object is a parent of the previous one...
            if(rel.lookupFromPrevObjectToken != null) {

                // ...if the previous one was a child, then sibling
                if(previousObjectIsParent) {
                    tacf.ruleType = 'inlaw';
                    break;
                }
                // ...otherwise ancestor
                else {
                    tacf.ruleType = 'ancestor';
                }
                previousObjectIsChild = true;
                previousObjectIsParent = false;
            }

            // If this object is a child of the previous one...
            else if(rel.lookupToPrevObjectToken != null) {

                // ...if the previous one was a parent, then sibling
                if(previousObjectIsChild) {
                    tacf.ruleType = 'sibling';
                    break;
                }
                // ...otherwise descendant
                else {
                    tacf.ruleType = 'descendant';
                }
                previousObjectIsParent = true;
                previousObjectIsChild = false;
            }
        }
        tacf.controllingObjectApiName = rel.thisObjectApiName;
        tacf.controllingObjectLabel = rel.thisObjectLabel;
        tacf.controllingObjectSharedToFieldAPIName = rel.sharedToFieldAPIName;
        tacf.controllingObjectSharedToFieldLabel = rel.sharedToFieldLabel;
        tacf.controllingObjectSharedToFieldToken = rel.sharedToFieldToken;

        return tacf;
    }

    
    // Populate nested relationship object. Need retrieve fields individually from api names
    // Because attributes of field / object definitions can't be refrerenced with dynamic map notation
    private static FormulaShareSObjectRelationship getrelationship(FormulaShare_Rule__mdt rule) {

        FormulaShareSObjectRelationship relationship = new FormulaShareSObjectRelationship();

        relationship.thisObjectToken           = rule.Object_Shared__c;
        relationship.thisObjectApiName         = rule.Object_Shared__r.QualifiedApiName;
        relationship.thisObjectLabel           = rule.Object_Shared__r.MasterLabel;
        if(rule.Child_Object_with_Shared_To_Field__c == null) {
            relationship.sharedToFieldToken        = rule.Shared_To__c;
            relationship.sharedToFieldApiName      = rule.Shared_To__r.QualifiedApiName;
            relationship.sharedToFieldLabel        = rule.Shared_To__r.MasterLabel;
            return relationship;
        }

        FormulaShareSObjectRelationship rfc1 = new FormulaShareSObjectRelationship();
        rfc1.thisObjectToken            = rule.Child_Object_with_Shared_To_Field__c;
        rfc1.thisObjectApiName          = rule.Child_Object_with_Shared_To_Field__r.QualifiedApiName;
        rfc1.thisObjectLabel            = rule.Child_Object_with_Shared_To_Field__r.MasterLabel;
        rfc1.lookupFromPrevObjectToken  = rule.Related_Object_1_Lookup_from_Shared_Obj__c;
        rfc1.lookupFromPrevObjectApiName= rule.Related_Object_1_Lookup_from_Shared_Obj__r.QualifiedApiName;
        rfc1.lookupToPrevObjectToken    = rule.Child_Object_Lookup_Field__c;
        rfc1.lookupToPrevObjectApiName  = rule.Child_Object_Lookup_Field__r.QualifiedApiName;
        relationship.nextRelationship = rfc1;
        if(rule.Related_Object_2__c == null) {
            rfc1.sharedToFieldToken         = rule.Child_Object_Shared_To_Field__c;
            rfc1.sharedToFieldApiName       = rule.Child_Object_Shared_To_Field__r.QualifiedApiName;
            rfc1.sharedToFieldLabel         = rule.Child_Object_Shared_To_Field__r.MasterLabel;
            return relationship;
        }

        FormulaShareSObjectRelationship rfc2 = new FormulaShareSObjectRelationship();
        rfc2.thisObjectToken            = rule.Related_Object_2__c;
        rfc2.thisObjectApiName          = rule.Related_Object_2__r.QualifiedApiName;
        rfc2.thisObjectLabel            = rule.Related_Object_2__r.MasterLabel;
        rfc2.lookupFromPrevObjectToken  = rule.Related_Object_2_Lookup_from_RO1__c;
        rfc2.lookupFromPrevObjectApiName= rule.Related_Object_2_Lookup_from_RO1__r.QualifiedApiName;
        rfc2.lookupToPrevObjectToken    = rule.Related_Object_2_Lookup_to_RO1__c;
        rfc2.lookupToPrevObjectApiName  = rule.Related_Object_2_Lookup_to_RO1__r.QualifiedApiName;
        rfc1.nextRelationship = rfc2;
        if(rule.Related_Object_3__c == null) {
            rfc2.sharedToFieldToken         = rule.Related_Object_2_Shared_To_Field__c;
            rfc2.sharedToFieldApiName       = rule.Related_Object_2_Shared_To_Field__r.QualifiedApiName;
            rfc2.sharedToFieldLabel         = rule.Related_Object_2_Shared_To_Field__r.MasterLabel;
            return relationship;
        }
        
        FormulaShareSObjectRelationship rfc3 = new FormulaShareSObjectRelationship();
        rfc3.thisObjectToken            = rule.Related_Object_3__c;
        rfc3.thisObjectApiName          = rule.Related_Object_3__r.QualifiedApiName;
        rfc3.thisObjectLabel            = rule.Related_Object_3__r.MasterLabel;
        rfc3.lookupFromPrevObjectToken  = rule.Related_Object_3_Lookup_from_RO2__c;
        rfc3.lookupFromPrevObjectApiName= rule.Related_Object_3_Lookup_from_RO2__r.QualifiedApiName;
        rfc3.lookupToPrevObjectToken    = rule.Related_Object_3_Lookup_to_RO2__c;
        rfc3.lookupToPrevObjectApiName  = rule.Related_Object_3_Lookup_to_RO2__r.QualifiedApiName;
        rfc2.nextRelationship = rfc3;
        if(rule.Related_Object_4__c == null) {
            rfc3.sharedToFieldToken         = rule.Related_Object_3_Shared_To_Field__c;
            rfc3.sharedToFieldApiName       = rule.Related_Object_3_Shared_To_Field__r.QualifiedApiName;
            rfc3.sharedToFieldLabel         = rule.Related_Object_3_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc4 = new FormulaShareSObjectRelationship();
        rfc4.thisObjectToken            = rule.Related_Object_4__c;
        rfc4.thisObjectApiName          = rule.Related_Object_4__r.QualifiedApiName;
        rfc4.thisObjectLabel            = rule.Related_Object_4__r.MasterLabel;
        rfc4.lookupFromPrevObjectToken  = rule.Related_Object_4_Lookup_from_RO3__c;
        rfc4.lookupFromPrevObjectApiName= rule.Related_Object_4_Lookup_from_RO3__r.QualifiedApiName;
        rfc4.lookupToPrevObjectToken    = rule.Related_Object_4_Lookup_to_RO3__c;
        rfc4.lookupToPrevObjectApiName  = rule.Related_Object_4_Lookup_to_RO3__r.QualifiedApiName;
        rfc3.nextRelationship = rfc4;
        if(rule.Related_Object_5__c == null) {
            rfc4.sharedToFieldToken         = rule.Related_Object_4_Shared_To_Field__c;
            rfc4.sharedToFieldApiName       = rule.Related_Object_4_Shared_To_Field__r.QualifiedApiName;
            rfc4.sharedToFieldLabel         = rule.Related_Object_4_Shared_To_Field__r.MasterLabel;
            return relationship;
        }

        FormulaShareSObjectRelationship rfc5 = new FormulaShareSObjectRelationship();
        rfc5.thisObjectToken            = rule.Related_Object_5__c;
        rfc5.thisObjectApiName          = rule.Related_Object_5__r.QualifiedApiName;
        rfc5.thisObjectLabel            = rule.Related_Object_5__r.MasterLabel;
        rfc5.lookupFromPrevObjectToken  = rule.Related_Object_5_Lookup_from_RO4__c;
        rfc5.lookupFromPrevObjectApiName= rule.Related_Object_5_Lookup_from_RO4__r.QualifiedApiName;
        rfc5.lookupToPrevObjectToken    = rule.Related_Object_5_Lookup_to_RO4__c;
        rfc5.lookupToPrevObjectApiName  = rule.Related_Object_5_Lookup_to_RO4__r.QualifiedApiName;
        rfc4.nextRelationship = rfc5;
        if(rule.Related_Object_6__c == null) {
            rfc5.sharedToFieldToken         = rule.Related_Object_5_Shared_To_Field__c;
            rfc5.sharedToFieldApiName       = rule.Related_Object_5_Shared_To_Field__r.QualifiedApiName;
            rfc5.sharedToFieldLabel         = rule.Related_Object_5_Shared_To_Field__r.MasterLabel;
            return relationship;
        }

        FormulaShareSObjectRelationship rfc6 = new FormulaShareSObjectRelationship();
        rfc6.thisObjectToken            = rule.Related_Object_6__c;
        rfc6.thisObjectApiName          = rule.Related_Object_6__r.QualifiedApiName;
        rfc6.thisObjectLabel            = rule.Related_Object_6__r.MasterLabel;
        rfc6.lookupFromPrevObjectToken  = rule.Related_Object_6_Lookup_from_RO5__c;
        rfc6.lookupFromPrevObjectApiName= rule.Related_Object_6_Lookup_from_RO5__r.QualifiedApiName;
        rfc6.lookupToPrevObjectToken    = rule.Related_Object_6_Lookup_to_RO5__c;
        rfc6.lookupToPrevObjectApiName  = rule.Related_Object_6_Lookup_to_RO5__r.QualifiedApiName;
        rfc5.nextRelationship = rfc6;
        if(rule.Related_Object_7__c == null) {
            rfc6.sharedToFieldToken         = rule.Related_Object_6_Shared_To_Field__c;
            rfc6.sharedToFieldApiName       = rule.Related_Object_6_Shared_To_Field__r.QualifiedApiName;
            rfc6.sharedToFieldLabel         = rule.Related_Object_6_Shared_To_Field__r.MasterLabel;
            return relationship;
        }

        FormulaShareSObjectRelationship rfc7 = new FormulaShareSObjectRelationship();
        rfc7.thisObjectToken            = rule.Related_Object_7__c;
        rfc7.thisObjectApiName          = rule.Related_Object_7__r.QualifiedApiName;
        rfc7.thisObjectLabel            = rule.Related_Object_7__r.MasterLabel;
        rfc7.lookupFromPrevObjectToken  = rule.Related_Object_7_Lookup_from_RO6__c;
        rfc7.lookupFromPrevObjectApiName= rule.Related_Object_7_Lookup_from_RO6__r.QualifiedApiName;
        rfc7.lookupToPrevObjectToken    = rule.Related_Object_7_Lookup_to_RO6__c;
        rfc7.lookupToPrevObjectApiName  = rule.Related_Object_7_Lookup_to_RO6__r.QualifiedApiName;
        rfc6.nextRelationship = rfc7;
        if(rule.Related_Object_8__c == null) {
            rfc7.sharedToFieldToken         = rule.Related_Object_7_Shared_To_Field__c;
            rfc7.sharedToFieldApiName       = rule.Related_Object_7_Shared_To_Field__r.QualifiedApiName;
            rfc7.sharedToFieldLabel         = rule.Related_Object_7_Shared_To_Field__r.MasterLabel;
            return relationship;
        }
        
        FormulaShareSObjectRelationship rfc8 = new FormulaShareSObjectRelationship();
        rfc8.thisObjectToken            = rule.Related_Object_8__c;
        rfc8.thisObjectApiName          = rule.Related_Object_8__r.QualifiedApiName;
        rfc8.thisObjectLabel            = rule.Related_Object_8__r.MasterLabel;
        rfc8.lookupFromPrevObjectToken  = rule.Related_Object_8_Lookup_from_RO7__c;
        rfc8.lookupFromPrevObjectApiName= rule.Related_Object_8_Lookup_from_RO7__r.QualifiedApiName;
        rfc8.lookupToPrevObjectToken    = rule.Related_Object_8_Lookup_to_RO7__c;
        rfc8.lookupToPrevObjectApiName  = rule.Related_Object_8_Lookup_to_RO7__r.QualifiedApiName;
        rfc7.nextRelationship = rfc8;

        rfc8.sharedToFieldToken         = rule.Related_Object_8_Shared_To_Field__c;
        rfc8.sharedToFieldApiName       = rule.Related_Object_8_Shared_To_Field__r.QualifiedApiName;
        rfc8.sharedToFieldLabel         = rule.Related_Object_8_Shared_To_Field__r.MasterLabel;

        return relationship;
    }

    
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


    // Check if all share levels in a share object are equal to the rule
    public Boolean shareEqualToRule(Schema.SObjectType type, SOBject share, Boolean contactIsControlledByAccount) {

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

        if(accessLevel != objectAccess) {
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
    public Boolean shareEqualOrMorePermissiveThanRule(Schema.SObjectType type, SOBject share, Boolean contactIsControlledByAccount) {

        FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
        String objectAccess = (String) share.get(objectUtils.accessLevelFieldName());

        if(FormulaShareUtilities.accessLevelIsHigher(accessLevel, objectAccess)) {
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

}