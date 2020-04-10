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

	// Cache global describe for performance
	public static Map<String, SObjectType> globalDescribe {
		get {
			if(globalDescribe == null) {
				globalDescribe = Schema.getGlobalDescribe();
			}
			return globalDescribe;
		}
	}

	public static Map<String,DescribeSObjectResult> cachedDescribes = new Map<String,DescribeSObjectResult>();
	public static Map<String,Map<String, SObjectField>> cachedFieldMaps = new Map<String,Map<String, SObjectField>>();

	// Get describe result and maintain cache
	public static DescribeSObjectResult describe(String objectAPIName) {
		if(cachedDescribes.containsKey(objectAPIName)) {
			return cachedDescribes.get(objectAPIName);
		}
		else {
			SObjectType objType = globalDescribe.get(objectAPIName);
			DescribeSObjectResult describe = objType.getDescribe();
			cachedDescribes.put(objectAPIName, describe);
			return describe;
		}
	}


	// Return SObjectType token from API name
	public static Schema.SObjectType getSObjectTypeFromName(String objectAPIName) {
		Schema.SObjectType type = describe(objectAPIName).getSobjectType();
		return type;
	}

	
	// Get an object's field map and maintain cache
	public static Map<String,SObjectField> getFieldMap(String objectAPIName) {
		if(cachedFieldMaps.containsKey(objectAPIName)) {
			return cachedFieldMaps.get(objectAPIName);
		}
		else {
			Map<String,SObjectField> fieldMap = describe(objectAPIName).fields.getMap();
			cachedFieldMaps.put(objectAPIName, fieldMap);
			return fieldMap;
		}
	}

	public static Map<String,SObjectField> getFieldMap(Schema.SObjectType type) {
		String objectAPIName = type.getDescribe().getName();
		return getFieldMap(objectAPIName);
	}


	public static Schema.sObjectField getSObjectFieldFromName(String fieldNameString, SOBjectType type) {
		Map<String, SObjectField> fieldsMapByName = type.getDescribe().fields.getMap();
		SObjectField sObjField = fieldsMapByName.get(fieldNameString.toLowerCase());
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
	

	public static SObjectType getShareObject(SObjectType type) {
		SObjectType shareObject;
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
		else return null;
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

	public static String getShareRecordKeyStandard(SOBjectType type, SObject shareRecord) {
		Id parentId = (Id) shareRecord.get(type + 'Id');
		Id userOrGroupId = (Id) shareRecord.get('UserOrGroupId');
		String parentId15 = get15CharacterId(parentId);
		String userOrGroupId15 = get15CharacterId(userOrGroupId);
		String accessLevel = (String) shareRecord.get(type + 'AccessLevel');
		String shareKey = parentId15 + userOrGroupId15 + accessLevel;
		return shareKey;
	}


	public static String getShareRecordKeyCustom(SObject shareRecord) {
		Id parentId = (Id) shareRecord.get('ParentId');
		Id userOrGroupId = (Id) shareRecord.get('UserOrGroupId');
		String parentId15 = get15CharacterId(parentId);
		String userOrGroupId15 = get15CharacterId(userOrGroupId);
		String accessLevel = (String) shareRecord.get('AccessLevel');
		String rowCause = (String) shareRecord.get('RowCause');
		String shareKey = parentId15 + userOrGroupId15 + accessLevel + rowCause;
		return shareKey;
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
	public static String getLightningDomain(){
        return getMyDomain() + '.lightning.force.com';
    }

    public static String getMyDomain(){
        return URL.getOrgDomainUrl().getHost().split('\\.')[0].toLowerCase();
    }
}