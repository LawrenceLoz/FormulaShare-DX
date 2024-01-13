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

public inherited sharing class FormulaShareUtilities {

	// If app is expected to be used within a namespace, check whether a class exists with this namespace
	// and if so then assume we're operating within a NS, otherwise assume we're not in a namespace.
	// Approach allows same version of FormulaShare to be run within a namespace and outside of
	// a namespace (e.g. metadata deployment to sandbox for testing)
    static String namespacePrefix = '';
	static Boolean namespaceSet = false;
    public static String getNamespacePrefix() {
        if(!namespaceSet) {

			// Refactored to avoid query
			String uowClassName = FormulaShareUnitOfWorkDML.class.getName();
			if(uowClassName.contains('.')) {
				namespacePrefix = uowClassName.split('\\.')[0] + '__';	// Escape required
			}

			// Previous approach (replaced to avoid need to query system object)
			// This approach would have allowed for separate installed packages with the same class names
			// However this isn't required with new Lite/Enterprise/Unlimited approach
			//
//			String expectedNamespace = FormulaShareNamespaceInfo.getExpectedNamespace();
//			if(expectedNamespace != null) {
//				List<ApexClass> nsClassList = [
//					SELECT Id from ApexClass 
//					WHERE Name = :classInPackage 
//					AND NamespacePrefix = :expectedNamespace
//					WITH SECURITY_ENFORCED];
//				if(!nsClassList.isEmpty()) {
//					namespacePrefix = expectedNamespace + '__';
//				}
//			}

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
		private set;
	}

	public static Map<String,Schema.DescribeSObjectResult> cachedDescribes = new Map<String,Schema.DescribeSObjectResult>();
	public static Map<String,Map<String, Schema.SObjectField>> cachedFieldMaps = new Map<String,Map<String, Schema.SObjectField>>();

	// Get describe result and maintain cache
	public static Schema.DescribeSObjectResult describe(String objectAPIName) {
		if(cachedDescribes.containsKey(objectAPIName)) {
			System.debug('Describe: Returning from cache: '+cachedDescribes.get(objectAPIName));
			return cachedDescribes.get(objectAPIName);
		}
		else {
			if(globalDescribe.containsKey(objectAPIName)) {
				Schema.SObjectType objType = globalDescribe.get(objectAPIName);
				Schema.DescribeSObjectResult describe = objType.getDescribe();
				cachedDescribes.put(objectAPIName, describe);
				System.debug('Describe: Returning from global: '+describe);
				return describe;
			}
			else {
				System.debug('Describe: Couldnt find');
				return null;
			}
		}
	}


	// Return SObjectType token from API name
	public static Schema.SObjectType getSObjectTypeFromName(String objectAPIName) {
		System.debug('Checking describe for object: '+objectAPIName);
		System.debug('Describe: '+describe(objectAPIName));
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
//		Schema.SObjectField sObjField;
//		try {
			Map<String, Schema.SObjectField> fieldsMapByName = type.getDescribe().fields.getMap();
			Schema.SObjectField sObjField = fieldsMapByName.get(fieldNameString.toLowerCase());
//		}
//		catch(Exception e) {
//			System.debug('exception type: '+type);
//			System.debug('exception fieldNameString: '+fieldNameString);
//			System.debug('exception field map: '+ type.getDescribe().fields.getMap());
//		}
		return sObjField;
	}


	// Deprecate?
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


	// Deprecate?
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


	// Some standard objects can't be used in any custom metadata relationship fields
	public static Set<String> excludedFromCustomMetadata = new Set<String>{
		'User',						// Can't be used in entity relationship field on metadata
		'Event',					// Can't be used in entity relationship field on metadata
		'Task',						// Can't be used in entity relationship field on metadata
		'RecordAction'				// Can't be used in entity relationship field on metadata
	};

	// Some objects are not supported by the features or processes used in FormulaShare
	static Set<String> excludedFromRelatedObjects = new Set<String> {
		'DuplicateRecordItem',		// Fails as a child in cross-object query
		'ContactRequest',			// Generic WhatId field not permitted in queries
		'ProcessException'			// Access not permitted in query
	};


	// Returns details of all objects associated through a lookup
	// Used by LWC formulaShareRelationshipButtons component
	public static List<RelationshipDetails> getParentRelationships(String childObjectAPIName) {
		List<RelationshipDetails> crdList = new List<RelationshipDetails>();

		Map<String,Schema.SObjectField> allFieldsMap = getFieldMap(childObjectAPIName);
		for(Schema.SObjectField field : allFieldsMap.values()) {
			Schema.DescribeFieldResult fieldDesc = field.getDescribe();
			Schema.DisplayType fieldType = fieldDesc.getType();

			// If it's a lookup field, check whether the lookup object is user (only lookup type which could control sharing)
			if(fieldType == Schema.DisplayType.REFERENCE) {
				List<Schema.SObjectType> parentObjTypes = fieldDesc.getReferenceTo();

				// Only consider fields which can reference a single object
				if(parentObjTypes.size() == 1) {
					Schema.DescribeSObjectResult parentObjDesc = parentObjTypes[0].getDescribe();
					String parentObjApiName = parentObjDesc.getName();

					// Continue if object is supported on custom metadata records
					if(!excludedFromCustomMetadata.contains(parentObjApiName)) {
						RelationshipDetails rd = new RelationshipDetails();
						rd.relatedObjDesc = parentObjDesc;
						rd.relatedObjectApiName = parentObjApiName;
						rd.relatedObjectLabel = parentObjDesc.getLabel();
						rd.relatedFieldApiName = fieldDesc.getName();
						crdList.add(rd);
					}
				}
			}
		}

		crdList.sort();
		return crdList;
	}


	// Used by LWC formulaShareRelationshipButtons component
	public static List<RelationshipDetails> getChildRelationships(String parentObjectAPIName) {
		List<RelationshipDetails> crdList = new List<RelationshipDetails>();
		Schema.DescribeSObjectResult parentObjDesc = describe(parentObjectAPIName);

		List<Schema.ChildRelationship> allChildRelationships = parentObjDesc.getChildRelationships();

		// build CRD objects
		List<RelationshipDetails> allCrds = new List<RelationshipDetails>();
		List<String> childObjApiNames = new List<String>();
		for(Schema.ChildRelationship cr : allChildRelationships) {

			// Exclude child relationships with a null relationship name (these can't be processed by FormulaShareService)
			if(cr.getRelationshipName() != null) {
				RelationshipDetails crd = convertToRelationshipDetails(cr);

				// Exclude any which aren't supported for metadata lists, cross-object queries or other complications
				if(!excludedFromCustomMetadata.contains(crd.relatedObjectApiName) 
					&& !excludedFromRelatedObjects.contains(crd.relatedObjectApiName)) {
					allCrds.add(crd);
					childObjApiNames.add(crd.relatedObjectApiName);
				}
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
		List<RelationshipDetails> eligibleCrds = new List<RelationshipDetails>();
		for(RelationshipDetails crd : allCrds) {
			if(edMap.containsKey(crd.relatedObjectApiName)) {
				EntityDefinition ed = edMap.get(crd.relatedObjectApiName);
				if(ed.IsApexTriggerable && ed.IsCustomizable) {
					eligibleCrds.add(crd);
				}
			}
		}

		List<RelationshipDetails> customChildRelationships = new List<RelationshipDetails>();
		List<RelationshipDetails> standardChildRelationships = new List<RelationshipDetails>();

		// Build lists of custom and standard child relationship details
		for(RelationshipDetails crd : eligibleCrds) {
			if(crd.relatedObjDesc.isCustom()) {
				customChildRelationships.add(crd);
			}
			else if(crd.relatedObjDesc.isQueryable()) {
				standardChildRelationships.add(crd);
			}
		}

		// Add all child relationships for custom objects
		for(RelationshipDetails crd : customChildRelationships) {
			crdList.add(crd);
		}

		// Then add all child relationships for queryable standard objects (ensures shows custom then standard)
		for(RelationshipDetails crd : standardChildRelationships) {
			crdList.add(crd);
		}

		crdList.sort();
		return crdList;
	}

	
	private static RelationshipDetails convertToRelationshipDetails(Schema.ChildRelationship cr) {

		RelationshipDetails crd = new RelationshipDetails();
		crd.relatedObjFieldDesc = cr.getField().getDescribe();
		crd.relatedObjDesc = cr.getChildSObject().getDescribe();
		crd.relatedObjectLabel = crd.relatedObjFieldDesc.getLabel();
		crd.relatedFieldApiName = crd.relatedObjFieldDesc.getName();
		crd.relatedObjectApiName = crd.relatedObjDesc.getName();
		crd.relatedObjectLabel = crd.relatedObjDesc.getLabel();

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


	public static List<Schema.SObjectField> getBooleanFields(String objectApiName) {
		List<Schema.SObjectField> booleanFields = new List<Schema.SObjectField>();
		
		Map<String,Schema.SObjectField> allFieldsMap = getFieldMap(objectAPIName);
		for(Schema.SObjectField field : allFieldsMap.values()) {
			Schema.DescribeFieldResult fieldDesc = field.getDescribe();
			Schema.DisplayType fieldType = fieldDesc.getType();
			
			// Check whether field could contain information for sharing 
			if(fieldType == Schema.DisplayType.BOOLEAN) {
				booleanFields.add(field);
			}
		}

		return booleanFields;
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

	// -------------------- SObject and share type and name conversion methods -------------------- //

	private static String getShareObjectNameFromSObject(Schema.SObjectType type) {
		Schema.SObjectType shareObject;
		String typeName = type.getDescribe().getName();
		
		// For custom objects, remove the final "c" from the __c suffix
		if(type.getDescribe().isCustom()) {
			typeName = typeName.left(typeName.length()-1);
		}

		return typeName + 'Share';
	}

	public static String getShareObjectNameFromSObjectName(String sObjectName) {
		Schema.SObjectType type = getSObjectTypeFromName(sObjectName);
		return getShareObjectNameFromSObject(type);
	}

	public static Schema.SObjectType getShareObject(Schema.SObjectType type) {
		String shareObjectName = getShareObjectNameFromSObject(type);
		Schema.SObjectType shareObject = globalDescribe.get(shareObjectName);
		return shareObject;
	}


	private static String getSObjectNameFromShareObjectName(String shareObjectName) {
		String sObjectName = '';

		// For custom objects, remove "__Share" and append "__c"
		if(shareObjectName.right(7) == '__Share') {
			sObjectName = shareObjectName.left(shareObjectName.length()-7) + '__c';
		}
		// For standard objects, remove "Share"
		else {
			sObjectName = shareObjectName.left(shareObjectName.length()-5);
		}

		return sObjectName;		
	}

	public static Schema.SObjectType getSObjectFromShareObjectName(String shareObjectName) {
		String sObjectName = getSObjectNameFromShareObjectName(shareObjectName);
		Schema.SObjectType sharedObject = globalDescribe.get(sObjectName);
		return sharedObject;
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
            queryString += '\'' + FormulaShareIdUtilities.get15CharacterId(value) + '\',';
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


	// Return a map of all sharing reasons for a particular object
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


	private static Boolean contactSharingControlledByAccount;
	public static Boolean isContactSharingControlledByAccount() {
		if(contactSharingControlledByAccount == null) {
			Schema.SObjectType accountShareType = getSObjectTypeFromName('AccountShare');
			SObject share = accountShareType.newSObject();	// This will be possible even if account is Read/Write access
			try {
				share.put('ContactAccessLevel', 'Read');
			}
			catch(Exception e) {
				contactSharingControlledByAccount = true;	// If exception assigning contact access level, sharing is controlled by account
				return true;
			}
			contactSharingControlledByAccount = false;
		}
		return contactSharingControlledByAccount;
	}

	public static Map<String,SObject> cmdtToCmdtMap(FormulaShare_Rule__mdt rule) {
        Map<String,SObject> mdMap = new Map<String,SObject>();
        mdMap.put(rule.DeveloperName, rule);
        return mdMap;
    }


    public class RelationshipDetails implements Comparable {
		
		private Schema.DescribeFieldResult relatedObjFieldDesc;
		private Schema.DescribeSObjectResult relatedObjDesc;
        @AuraEnabled
        public String relatedObjectLabel {get;set;}
        @AuraEnabled
        public String relatedObjectApiName {get;set;}
        @AuraEnabled
        public String relatedFieldApiName {get;set;}
		
		// Comparable interface allows us to call sort on the list of relationships
        public Integer compareTo(Object compareTo) {
			RelationshipDetails compareToRel = (RelationshipDetails) compareTo;
			
			// Sort on related object labels if they're different
            if (relatedObjectLabel < compareToRel.relatedObjectLabel) {
                return -1;
            }
            else if (relatedObjectLabel > compareToRel.relatedObjectLabel) {
                return 1;
			}
			
			// Otherwise, sort on related fields
            else {
				if(relatedFieldApiName < compareToRel.relatedFieldApiName) {
					return -1;
				}
				else if(relatedFieldApiName > compareToRel.relatedFieldApiName) {
					return 1;
				}
				else {
					return 0;
				}
            }
        }
    }

}