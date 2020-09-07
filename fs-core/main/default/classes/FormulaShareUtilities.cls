/**
*Copyright 2018 Lawrence Newcombe
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

public with sharing class FormulaShareUtilities {

    public static FormulaShareUtilities mock;
    public static FormulaShareUtilities construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareUtilities();
        }
    }

    // Method returns the namespace of the package with underscores appended
    // Used to determine what to add to object and field names
    static String classInPackage = 'FormulaShareService';
    static String namespacePrefix = '';
	static Boolean namespaceSet = false;
	@AuraEnabled(cacheable=true)
    public static String getNamespacePrefix() {
        if(!namespaceSet) {
            ApexClass cs = [SELECT NamespacePrefix from ApexClass where Name = :classInPackage LIMIT 1][0];
            if(!String.isBlank(cs.NamespacePrefix)) {
                namespacePrefix = cs.NamespacePrefix + '__';
            }
            namespaceSet = true;
        }
        return namespacePrefix;
    }

	// Cache global describe for performance
	public static Map<String, Schema.SObjectType> globalDescribe {
		get {
			if(globalDescribe == null) {
				globalDescribe = Schema.getGlobalDescribe();
			}
			return globalDescribe;
		}
	}

	public static Map<String,Schema.DescribeSObjectResult> cachedDescribes = new Map<String,Schema.DescribeSObjectResult>();
	public static Map<String,Map<String, Schema.SObjectField>> cachedFieldMaps = new Map<String,Map<String, Schema.SObjectField>>();

	// Get describe result and maintain cache
	public static Schema.DescribeSObjectResult describe(String objectAPIName) {
		if(cachedDescribes.containsKey(objectAPIName)) {
			return cachedDescribes.get(objectAPIName);
		}
		else {
			if(globalDescribe.containsKey(objectAPIName)) {
				Schema.SObjectType objType = globalDescribe.get(objectAPIName);
				Schema.DescribeSObjectResult describe = objType.getDescribe();
				cachedDescribes.put(objectAPIName, describe);
				return describe;
			}
			else {
				return null;
			}
		}
	}


	// Return SObjectType token from API name
	public static Schema.SObjectType getSObjectTypeFromName(String objectAPIName) {
		Schema.SObjectType type = describe(objectAPIName).getSobjectType();
		return type;
	}

	
	// Get an object's field map and maintain cache
	public static Map<String,Schema.SObjectField> getFieldMap(String objectAPIName) {
		if(cachedFieldMaps.containsKey(objectAPIName)) {
			return cachedFieldMaps.get(objectAPIName);
		}
		else {
			Map<String,Schema.SObjectField> fieldMap = describe(objectAPIName).fields.getMap();
			cachedFieldMaps.put(objectAPIName, fieldMap);
			return fieldMap;
		}
	}

	public static Map<String,Schema.SObjectField> getFieldMap(Schema.SObjectType type) {
		String objectAPIName = type.getDescribe().getName();
		return getFieldMap(objectAPIName);
	}


	public static Schema.sObjectField getSObjectFieldFromName(String fieldNameString, Schema.SOBjectType type) {
		Map<String, Schema.SObjectField> fieldsMapByName = type.getDescribe().fields.getMap();
		Schema.SObjectField sObjField = fieldsMapByName.get(fieldNameString.toLowerCase());
		return sObjField;
	}


	public static Schema.sObjectField getSObjectFieldFromRelatedName(String fieldRelatedNameString, SOBjectType type) {
		// Get a map of all fields for the current object, and loop through each to find the next object to lookup
		Map<String, Schema.SObjectField> fieldsForObject = type.getDescribe().fields.getMap();
		for(Schema.SObjectField field : fieldsForObject.values()) {

			// For joining objects, check whether relationship name of this field is the same as the portion of the lookup we're evaluating
			if(field.getDescribe().getRelationshipName() == fieldRelatedNameString) {
				return field;
			}
		}
		return null;	// We should have found a field with this relationship name, but return null if not
	}


	public static String getRelationshipName(String parentObjectAPIName, String childObjectAPIName, String lookupFieldAPIName) {
		String relationshipName;

		// Find the relationship name for the lookup field
		Schema.SObjectField lookupField = getFieldMap(childObjectAPIName).get(lookupFieldAPIName);

		// Iterate through relationships on the parent object to check which one matches the lookup field
		Schema.DescribeSObjectResult parentObjDescribe = describe(parentObjectAPIName);
		for(Schema.ChildRelationship cr : parentObjDescribe.getChildRelationships()) {
			if(cr.getField() == lookupField) {
				relationshipName = cr.getRelationshipName();
				break;
			}
		}

		return relationshipName;
	}


	public static List<ChildRelationshipDetails> getChildRelationships(String parentObjectAPIName) {
		List<ChildRelationshipDetails> crdList = new List<ChildRelationshipDetails>();
		Schema.DescribeSObjectResult parentObjDesc = describe(parentObjectAPIName);

		List<Schema.ChildRelationship> allChildRelationships = parentObjDesc.getChildRelationships();

		// build CRD objects
		List<ChildRelationshipDetails> allCrds = new List<ChildRelationshipDetails>();
		List<String> childObjApiNames = new List<String>();
		for(Schema.ChildRelationship cr : allChildRelationships) {

			// Exclude child relationships with a null relationship name (these can't be processed by FormulaShareService)
			if(cr.getRelationshipName() != null) {
				ChildRelationshipDetails crd = convertToChildRelationshipDetails(cr);
				allCrds.add(crd);
				childObjApiNames.add(crd.childObjectApiName);
			}
		}

		// Build map of entity definitions
		List<EntityDefinition> edList = FormulaShareEntityDefinitionSelector.construct().getEntitiesForApiNames(childObjApiNames);
		Map<String, EntityDefinition> edMap = new Map<String, EntityDefinition>();
		for(EntityDefinition ed : edList) {
			edMap.put(ed.QualifiedApiName, ed);
		}

		// Build list of crds which are valid for use as child objects
		// Objects aren't included unless they're triggerable and customisable 
		// (these don't seem to be acceptable entity definitions for custom metadata)
		List<ChildRelationshipDetails> eligibleCrds = new List<ChildRelationshipDetails>();
		for(ChildRelationshipDetails crd : allCrds) {
			if(edMap.containsKey(crd.childObjectApiName)) {
				EntityDefinition ed = edMap.get(crd.childObjectApiName);
				if(ed.IsApexTriggerable && ed.IsCustomizable) {
					eligibleCrds.add(crd);
				}
			}
		}

		List<ChildRelationshipDetails> customChildRelationships = new List<ChildRelationshipDetails>();
		List<ChildRelationshipDetails> standardChildRelationships = new List<ChildRelationshipDetails>();

		// Build lists of custom and standard child relationship details
		for(ChildRelationshipDetails crd : eligibleCrds) {
//			if(cr.getRelationshipName() != null) {
			if(crd.childObjDesc.isCustom()) {
				customChildRelationships.add(crd);
			}
			else if(crd.childObjDesc.isQueryable()) {
				standardChildRelationships.add(crd);
			}
		}

		// Add all child relationships for custom objects
		for(ChildRelationshipDetails crd : customChildRelationships) {
			crdList.add(crd);
		}

		// Then add all child relationships for queryable standard objects (ensures shows custom then standard)
		for(ChildRelationshipDetails crd : standardChildRelationships) {
			crdList.add(crd);
		}

		return crdList;
	}

	
	private static ChildRelationshipDetails convertToChildRelationshipDetails(Schema.ChildRelationship cr) {

		ChildRelationshipDetails crd = new ChildRelationshipDetails();
		crd.childObjFieldDesc = cr.getField().getDescribe();
		crd.childObjDesc = cr.getChildSObject().getDescribe();
		crd.childObjectLabel = crd.childObjFieldDesc.getLabel();
		crd.childFieldApiName = crd.childObjFieldDesc.getName();
		crd.childObjectApiName = crd.childObjDesc.getName();
		crd.childObjectLabel = crd.childObjDesc.getLabel();

		return crd;
	}


	public static List<Schema.SObjectField> getShareFields(String objectApiName) {
		List<Schema.SObjectField> shareFields = new List<Schema.SObjectField>();
		
		Map<String,Schema.SObjectField> allFieldsMap = getFieldMap(objectAPIName);
		for(Schema.SObjectField field : allFieldsMap.values()) {
			Schema.DescribeFieldResult fieldDesc = field.getDescribe();
			Schema.DisplayType fieldType = fieldDesc.getType();
			
			// Check whether field could contain information for sharing 
			if(fieldType == Schema.DisplayType.STRING
				|| fieldType == Schema.DisplayType.PICKLIST) {

				// Include only non-compound fields
				if(isSupportedFieldForCustomMetadata(objectApiName, fieldDesc)) {
					shareFields.add(field);
				}
			}

			// If it's a lookup field, check whether the lookup object is user (only lookup type which could control sharing)
			else if(fieldType == Schema.DisplayType.REFERENCE) {
				for(SObjectType parentObjType : fieldDesc.getReferenceTo()) {
					String parentObj = parentObjType.getDescribe().getName();
					if(parentObj == 'User') {
						shareFields.add(field);
					}
				}
			}

			// Only return record ID if object is User
			else if(objectApiName == 'User' && fieldType == Schema.DisplayType.ID) {
				shareFields.add(field);
			}
		}

		return shareFields;
	}


	// Checks and excludes compound fields
	private static Boolean isSupportedFieldForCustomMetadata(String objectApiName, Schema.DescribeFieldResult fieldDesc) {

		// Include all custom fields
		if(fieldDesc.isCustom()) {
			return true;
		}

		String fieldName = fieldDesc.getName();

		// Return false for any fields which are not supported by custom metadata
		// This is needed because it's not efficient to programmatically check for compound fields
		switch on objectApiName {
			when 'Account', 'Order', 'Contract' {
				switch on fieldName.left(7) {
					// Exclude compound address fields
					when 'Billing', 'Shippin' {
						return false;
					}
				}
			}
			when 'Contact', 'Lead' {
				switch on fieldName.left(5) {
					// Exclude compound address fields
					when 'Maili', 'Other' {
						return false;
					}
				}
				switch on fieldName {
					// Exclude compound name and specific address fields
					when 'LastName', 'FirstName', 'City', 'State', 'PostalCode', 'Country', 'GeocodeAccuracy' {
						return false;
					}
				}
			}
		}

		return true;
	}


	// Some standard objects can't be used in custom metadata relationship fields
	public static Boolean isSupportedObjectForCustomMetadata(String objectApiName) {
		switch on objectApiName {
			when 'Event', 'Task', 'User' {
				return false;
			}
		}
		return true;
	}


	public static Schema.SObjectType getShareObject(Schema.SObjectType type) {
		Schema.SObjectType shareObject;
		String typeName = type.getDescribe().getName();
		
		// For custom objects, remove the final "c" from the __c suffix
		if(type.getDescribe().isCustom()) {
			typeName = typeName.left(typeName.length()-1);
		}

		// Append "Share" to get the right object share name
		shareObject = Schema.getGlobalDescribe().get(typeName+'Share');
		
		return shareObject;
	}


	public static String get15CharacterId(Id longId) {
		if(longId != null) {
			String shortId = ((String) longId).left(15);
			return shortId;
		}
		else {
			return null;
		}
	}
	
	// Instance implementation for mocking
	public String get15CharacterIdInstance(Id longId) {
		return get15CharacterId(longId);
	}


	public static Boolean isValidIdType(String candidateId, Schema.SObjectType shareWithType) {
		
		// Accetable if null
		if(candidateId == null) {
			return true;
		}

		else {
			
			// Check Id is valid
			Id idValueToCheck;
			if(isValidIdType(candidateId)) {
				idValueToCheck = (Id) candidateId;
			}
			else {
				return false;
			}

			// Check that Id is the expected type
			if(idValueToCheck.getSObjectType() == shareWithType) {
				return true;
			}
			else {
				return false;
			}
		}
	}

	public static Boolean isValidIdType(String candidateId) {
		
		// Check we can cast to an Id
		Id idValueToCheck;
		try {
			idValueToCheck = (Id) candidateId;
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}


	public static String getHighestAccess(List<String> accessLevels) {
		String highestLevel = 'None';
		for(String level : accessLevels) {
			if(accessLevelIsHigher(level, highestLevel)) {
				highestLevel = level;
			}
		}
		return highestLevel;
	}


	public static Boolean accessLevelIsHigher(String candidateLevel, String baseLevel) {
		switch on candidateLevel {
			when 'Read' {
				if(baseLevel == 'None') {
					return true;
				}
			}
			when 'Edit' {
				if(baseLevel == 'None' || baseLevel == 'Read') {
					return true;
				}
			}
			when 'All' {
				if(baseLevel == 'None' || baseLevel == 'Read' || baseLevel == 'Edit') {
					return true;
				}
			}
		}
		return false;
	}


    public static String buildStringFromSetQuotes(Set<Id> idSet) {
        String queryString = '';
        for (Id value : idSet) {
            queryString += '\'' + get15CharacterId(value) + '\',';
        }
        queryString = queryString.substringBeforeLast(',');
        return queryString;
    }


    public static String buildStringFromSetQuotes(Set<String> stringSet) {
        String queryString = '';
        for (String value : stringSet) {
            queryString += '\'' + value + '\',';
        }
        queryString = queryString.substringBeforeLast(',');
        return queryString;
    }

	// Used by controller to build links to setup menu items
	@AuraEnabled(cacheable=true)
	public static String getLightningDomain(){
        return getMyDomain() + '.lightning.force.com';
    }

	@AuraEnabled(cacheable=true)
	public static String getClassicDomain(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }

    public static String getMyDomain(){
        return URL.getOrgDomainUrl().getHost().split('\\.')[0].toLowerCase();
	}


	// Return a map of all sharing reasons for a particular object
	@AuraEnabled(cacheable=true)
	public static Map<String,String> getSharingReasons(String objectApiName) {
		Map<String,String> reasons = new Map<String,String>();

		// Get the SOBjectField corresponding to RowCause on the share object
		Schema.SObjectType objectType = getSObjectTypeFromName(objectApiName);
		Schema.SObjectType shareObjectType = getShareObject(objectType);
		Schema.SObjectField rowCauseField = getSObjectFieldFromName('RowCause', shareObjectType);

		for(PicklistEntry entry : rowCauseField.getDescribe().getPicklistValues()) {

			// Only add custom reasons (ones ending in __c)
			if(entry.getValue().right(3) == '__c') {
				reasons.put(entry.getValue(), entry.getLabel());
			}
		}

		return reasons;
	}


	@AuraEnabled(cacheable=true)
	public static Boolean isContactSharingControlledByAccount() {
		Schema.SObjectType accountShareType = getSObjectTypeFromName('AccountShare');
		SObject share = accountShareType.newSObject();
		try {
			share.put('ContactAccessLevel', 'Read');
		}
		catch(Exception e) {
			return true;	// If exception assigning contact access level, sharing is controlled by account
		}
		return false;
	}


    public class ChildRelationshipDetails {
		private Schema.DescribeFieldResult childObjFieldDesc;
		private Schema.DescribeSObjectResult childObjDesc;
        @AuraEnabled
        public String childObjectLabel {get;set;}
        @AuraEnabled
        public String childObjectApiName {get;set;}
        @AuraEnabled
        public String childObjectId {get;set;}
        @AuraEnabled
        public String childFieldLabel {get;set;}
        @AuraEnabled
        public String childFieldApiName {get;set;}
        @AuraEnabled
		public String childFieldId {get;set;}
    }

}